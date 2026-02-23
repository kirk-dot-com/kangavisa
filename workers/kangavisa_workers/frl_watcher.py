"""
FRL (Federal Register of Legislation) ingestion watcher.

Phase 0 — hello world skeleton:
  fetch_frl()          → download raw bytes from FRL URL
  hash_content()       → SHA-256 hex digest for change detection
  snapshot()           → write raw bytes to kb/snapshots/, return metadata dict
  create_change_event()→ produce a change_event dict (no DB writes yet)

Real watcher behaviour (Sprint 1):
  - compare current hash against stored prev_hash in DB
  - if changed, call create_change_event() + impact scoring
  - write change_event row to Supabase
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
# Core primitives
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

    The returned dict is a stub — in Sprint 1 this will be written to
    Supabase ``change_event`` table and run through the impact-scoring engine.

    Returns::

        {
            "event_type": "change_detected" | "initial_snapshot",
            "source_id": str,
            "prev_hash": str | None,
            "curr_hash": str,
            "snapshot_path": str,
            "requires_review": bool,   # always False in skeleton (Sprint 1 will score)
            "impact_score": None,       # Sprint 1
            "detected_at": str,         # ISO-8601 UTC
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
        "requires_review": False,  # Sprint 1: set True when impact_score >= 70
        "impact_score": None,      # Sprint 1: calculate heuristic here
        "detected_at": datetime.now(timezone.utc).isoformat(),
    }


# ---------------------------------------------------------------------------
# Top-level run helper (CLI entry point in Sprint 1)
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
