"""
datagov_watcher.py — data.gov.au weekly ingestion watcher.

US-G1 | FR-K4: Snapshot data.gov.au CKAN dataset metadata with provenance.
US-G2 | FR-K4: change_event generation with impact scoring.
US-G4: Dataset exports must cite KB release tag + time window (metadata_json).

Sprint 1 scope: fetch CKAN dataset JSON → hash metadata_modified →
                source_document insert + change_event.
Sprint 2: CSV snapshot + schema validation against JSON Schema.
"""

from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

import httpx

from kangavisa_workers import db, impact_scorer
from kangavisa_workers.frl_watcher import hash_content, snapshot

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
DATAGOV_CKAN_API = "https://data.gov.au/api/3/action/package_show"
SNAPSHOTS_DIR = Path(os.getenv("KANGAVISA_SNAPSHOTS_DIR", "kb/snapshots"))
DEFAULT_TIMEOUT = 30


# ---------------------------------------------------------------------------
# Fetch helpers
# ---------------------------------------------------------------------------

def fetch_dataset_metadata(dataset_id: str, timeout: int = DEFAULT_TIMEOUT) -> dict:
    """
    Fetch CKAN dataset metadata for *dataset_id*.
    Returns the `result` dict from the CKAN API response.
    Raises httpx.HTTPStatusError on 4xx/5xx.
    Raises KeyError if API returns success=false.
    """
    with httpx.Client(timeout=timeout) as client:
        resp = client.get(DATAGOV_CKAN_API, params={"id": dataset_id})
        resp.raise_for_status()
        data = resp.json()
        if not data.get("success"):
            raise KeyError(f"CKAN API returned success=false for dataset_id={dataset_id}")
        return data["result"]


# ---------------------------------------------------------------------------
# Full pipeline
# ---------------------------------------------------------------------------

def run_datagov_watch_and_persist(
    dataset_id: str,
    canonical_url: str,
    title: Optional[str] = None,
) -> dict:
    """
    US-G1 | US-G2 | US-G4: Full data.gov.au ingestion pipeline.

    1. Fetch CKAN dataset metadata
    2. Hash `metadata_modified` field for efficient change detection
    3. Snapshot full JSON to disk
    4. Score impact
    5. Insert source_document → source_doc_id (with metadata_json for US-G4)
    6. If changed: insert change_event → change_event_id

    Returns result dict (same shape as run_frl_watch_and_persist).
    """
    prev_doc = db.get_latest_source_doc(canonical_url)
    prev_hash = prev_doc["content_hash"] if prev_doc else None
    prev_doc_id = prev_doc["source_doc_id"] if prev_doc else None

    metadata = fetch_dataset_metadata(dataset_id)
    metadata_bytes = json.dumps(metadata, sort_keys=True).encode("utf-8")
    curr_hash = hash_content(metadata_bytes)

    if prev_hash == curr_hash:
        snap_meta = snapshot(metadata_bytes, f"datagov_{dataset_id}", SNAPSHOTS_DIR)
        return {
            "source_doc_id": prev_doc_id,
            "change_event_id": None,
            "impact_score": 0,
            "requires_review": False,
            "signals": ["no change detected — identical metadata hash"],
            "snapshot": snap_meta,
        }

    snap_meta = snapshot(metadata_bytes, f"datagov_{dataset_id}", SNAPSHOTS_DIR)
    score_result = impact_scorer.score(None, metadata_bytes, "DATAGOV_DATASET")

    now_iso = datetime.now(timezone.utc).isoformat()
    # US-G4: metadata_json records dataset_id + metadata_modified for reproducibility
    source_doc_id = db.insert_source_document({
        "source_type": "DATAGOV_DATASET",
        "title": title or metadata.get("title", f"data.gov.au: {dataset_id}"),
        "canonical_url": canonical_url,
        "content_hash": curr_hash,
        "raw_blob_uri": snap_meta["snapshot_path"],
        "retrieved_at": now_iso,
        "metadata_json": {
            "dataset_id": dataset_id,
            "metadata_modified": metadata.get("metadata_modified"),
            "resource_count": len(metadata.get("resources", [])),
        },
    })

    event_type = "initial_snapshot" if prev_hash is None else "dataset_update"
    change_event_id = db.insert_change_event({
        "source_doc_id_new": source_doc_id,
        "source_doc_id_old": prev_doc_id,
        "change_type": event_type,
        "impact_score": score_result["impact_score"],
        "requires_review": score_result["requires_review"],
        "summary": (
            f"data.gov.au dataset changed: {dataset_id}. "
            f"metadata_modified={metadata.get('metadata_modified')}. "
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
