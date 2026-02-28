"""
FRL (Federal Register of Legislation) ingestion watcher.

US-G1 | FR-K4: Every snapshot stored with hash + timestamps + canonical URL.
US-G2 | FR-K4: change_event generated with impact score + review gating.

Phase 0 — hello world skeleton (Sprint 0):
  fetch_frl()          → download raw bytes from FRL URL
  hash_content()       → SHA-256 hex digest for change detection
  snapshot()           → write raw bytes to kb/snapshots/, return metadata dict
  create_change_event()→ produce a change_event dict (no DB writes)

Sprint 1 (this file):
  run_frl_watch_and_persist() → full pipeline: fetch → diff → score → write to Supabase
"""

from __future__ import annotations

import hashlib
import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

import httpx

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
FRL_BASE_URL = "https://www.legislation.gov.au"
# Root path for raw KB snapshots on disk.  CI tests override via env var.
SNAPSHOTS_DIR = Path(os.getenv("KANGAVISA_SNAPSHOTS_DIR", "kb/snapshots"))
DEFAULT_TIMEOUT = 30  # seconds


# ---------------------------------------------------------------------------
# Core primitives (unchanged from Sprint 0 — all existing tests pass)
# ---------------------------------------------------------------------------

def hash_content(content: bytes) -> str:
    """Return SHA-256 hex digest of *content* bytes."""
    return hashlib.sha256(content).hexdigest()


def fetch_frl(url: str, timeout: int = DEFAULT_TIMEOUT) -> bytes:
    """
    Fetch *url* and return raw response bytes.

    Raises httpx.HTTPStatusError on 4xx/5xx.
    Raises httpx.TimeoutException on timeout.
    """
    with httpx.Client(timeout=timeout, follow_redirects=True) as client:
        resp = client.get(url)
        resp.raise_for_status()
        return resp.content


def snapshot(
    content: bytes,
    source_id: str,
    snapshots_dir: Optional[Path] = None,
) -> dict:
    """
    Write *content* to disk and return a snapshot metadata dict.

    File name: ``{source_id}_{iso_timestamp}.bin``

    Returns::

        {
            "source_id": str,
            "snapshot_path": str,        # relative path to snapshot file
            "content_hash": str,         # SHA-256 hex
            "byte_size": int,
            "captured_at": str,          # ISO-8601 UTC
        }
    """
    dir_ = snapshots_dir or SNAPSHOTS_DIR
    dir_.mkdir(parents=True, exist_ok=True)

    ts = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    filename = f"{source_id}_{ts}.bin"
    file_path = dir_ / filename

    file_path.write_bytes(content)

    return {
        "source_id": source_id,
        "snapshot_path": str(file_path),
        "content_hash": hash_content(content),
        "byte_size": len(content),
        "captured_at": datetime.now(timezone.utc).isoformat(),
    }


def create_change_event(
    source_id: str,
    prev_hash: Optional[str],
    curr_hash: str,
    snapshot_path: str,
) -> Optional[dict]:
    """
    Return a ``change_event`` dict if *curr_hash* differs from *prev_hash*,
    else return ``None`` (no change detected).

    Returns::

        {
            "event_type": "change_detected" | "initial_snapshot",
            "source_id": str,
            "prev_hash": str | None,
            "curr_hash": str,
            "snapshot_path": str,
            "requires_review": bool,
            "impact_score": int | None,
            "detected_at": str,          # ISO-8601 UTC
        }
    """
    if prev_hash == curr_hash:
        return None  # identical content — no event

    event_type = "initial_snapshot" if prev_hash is None else "change_detected"

    return {
        "event_type": event_type,
        "source_id": source_id,
        "prev_hash": prev_hash,
        "curr_hash": curr_hash,
        "snapshot_path": snapshot_path,
        "requires_review": False,
        "impact_score": None,
        "detected_at": datetime.now(timezone.utc).isoformat(),
    }


# ---------------------------------------------------------------------------
# Top-level run helper (Sprint 0 — no DB writes)
# ---------------------------------------------------------------------------

def run_frl_watch(url: str, source_id: str, prev_hash: Optional[str] = None) -> dict:
    """
    Fetch *url*, snapshot to disk, and return a result dict containing:
    - snapshot metadata
    - change_event (or None if no change)

    Example::

        result = run_frl_watch(
            url="https://www.legislation.gov.au/Details/F2024L00001",
            source_id="frl_migration_act",
            prev_hash=stored_hash_from_db,
        )
    """
    content = fetch_frl(url)
    snap_meta = snapshot(content, source_id)
    change_event = create_change_event(
        source_id=source_id,
        prev_hash=prev_hash,
        curr_hash=snap_meta["content_hash"],
        snapshot_path=snap_meta["snapshot_path"],
    )
    return {
        "snapshot": snap_meta,
        "change_event": change_event,
    }


# ---------------------------------------------------------------------------
# Sprint 1 — full pipeline with Supabase persistence
# ---------------------------------------------------------------------------

def run_frl_watch_and_persist(
    url: str,
    source_id: str,
    source_type: str,
    canonical_url: str,
    title: Optional[str] = None,
) -> dict:
    """
    US-G1 | US-G2 | FR-K4: Full FRL ingestion pipeline.

    1. Retrieve previous source_document hash from Supabase (if any)
    2. Fetch + snapshot current content
    3. Score impact vs prev content
    4. Insert source_document row → source_doc_id
    5. If changed: insert change_event row → change_event_id

    Returns::

        {
            "source_doc_id": str (UUID),
            "change_event_id": str (UUID) | None,
            "impact_score": int,
            "requires_review": bool,
            "signals": list[str],
            "snapshot": dict,
        }

    Raises EnvironmentError if SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY not set.
    Raises httpx.HTTPStatusError on network/Supabase errors.
    """
    # Import here to keep pure functions testable without env vars
    from kangavisa_workers import db, impact_scorer

    # 1. Get previous state
    prev_doc = db.get_latest_source_doc(canonical_url)
    prev_hash = prev_doc["content_hash"] if prev_doc else None
    prev_doc_id = prev_doc["source_doc_id"] if prev_doc else None

    # 2. Fetch + snapshot
    content = fetch_frl(url)
    snap_meta = snapshot(content, source_id)
    curr_hash = snap_meta["content_hash"]

    # If content unchanged, skip DB writes
    if prev_hash == curr_hash:
        return {
            "source_doc_id": prev_doc_id,
            "change_event_id": None,
            "impact_score": 0,
            "requires_review": False,
            "signals": ["no change detected — identical hash"],
            "snapshot": snap_meta,
        }

    # 3. Score impact
    prev_content: Optional[bytes] = None  # byte diff requires re-fetch; hash match guards above
    score_result = impact_scorer.score(prev_content, content, source_type)

    # 4. Insert source_document
    now_iso = datetime.now(timezone.utc).isoformat()
    source_doc_id = db.insert_source_document({
        "source_type": source_type,
        "title": title or f"FRL snapshot: {source_id}",
        "canonical_url": canonical_url,
        "content_hash": curr_hash,
        "raw_blob_uri": snap_meta["snapshot_path"],
        "retrieved_at": now_iso,
        "metadata_json": {"source_id": source_id, "byte_size": snap_meta["byte_size"]},
    })

    # 5. Insert change_event
    event_type = "initial_snapshot" if prev_hash is None else "text_change"
    change_event_id = db.insert_change_event({
        "source_doc_id_new": source_doc_id,
        "source_doc_id_old": prev_doc_id,
        "change_type": event_type,
        "impact_score": score_result["impact_score"],
        "requires_review": score_result["requires_review"],
        "summary": (
            f"FRL change detected for {source_id}. "
            f"Signals: {'; '.join(score_result['signals'])}"
        ),
    })

    return {
        "source_doc_id": source_doc_id,
        "change_event_id": change_event_id,
        "impact_score": score_result["impact_score"],
        "requires_review": score_result["requires_review"],
        "signals": score_result["signals"],
        "snapshot": snap_meta,
    }

