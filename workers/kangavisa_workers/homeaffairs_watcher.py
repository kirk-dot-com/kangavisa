"""
homeaffairs_watcher.py — Home Affairs weekly ingestion watcher.

US-G1 | FR-K4: Snapshot immi.homeaffairs.gov.au pages with provenance.
US-G2 | FR-K4: change_event generation with impact scoring.

Sprint 1 scope: fetch → section-level diff (BeautifulSoup) →
                source_document insert + change_event.
Sprint 2: Structured requirement/flag extraction from parsed sections.
"""

from __future__ import annotations

import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

import httpx
from bs4 import BeautifulSoup

from kangavisa_workers import db, impact_scorer
from kangavisa_workers.frl_watcher import hash_content, snapshot

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
HOMEAFFAIRS_BASE = "https://immi.homeaffairs.gov.au"
SNAPSHOTS_DIR = Path(os.getenv("KANGAVISA_SNAPSHOTS_DIR", "kb/snapshots"))
DEFAULT_TIMEOUT = 30


# ---------------------------------------------------------------------------
# Fetch + section extraction
# ---------------------------------------------------------------------------

def fetch_homeaffairs(url: str, timeout: int = DEFAULT_TIMEOUT) -> bytes:
    """Fetch *url* and return raw HTML bytes."""
    with httpx.Client(timeout=timeout, follow_redirects=True) as client:
        resp = client.get(url, headers={"User-Agent": "KangaVisaBot/1.0"})
        resp.raise_for_status()
        return resp.content


def extract_sections(html: bytes) -> str:
    """
    Return a normalised text representation of page sections.
    Extracts <h2>, <h3>, and <p> text inside <main> or <article>.
    Used as the unit of comparison for diff scoring.
    """
    soup = BeautifulSoup(html, "html.parser")
    main = soup.find("main") or soup.find("article") or soup.body
    if not main:
        return soup.get_text(separator="\n", strip=True)
    return main.get_text(separator="\n", strip=True)


# ---------------------------------------------------------------------------
# Full pipeline
# ---------------------------------------------------------------------------

def run_homeaffairs_watch_and_persist(
    url: str,
    source_id: str,
    canonical_url: str,
    title: Optional[str] = None,
) -> dict:
    """
    US-G1 | US-G2: Full Home Affairs ingestion pipeline.

    1. Retrieve previous source_document hash from Supabase (if any)
    2. Fetch page + extract sections
    3. Score impact
    4. Insert source_document → source_doc_id
    5. If changed: insert change_event → change_event_id

    Returns result dict (same shape as run_frl_watch_and_persist).
    """
    prev_doc = db.get_latest_source_doc(canonical_url)
    prev_hash = prev_doc["content_hash"] if prev_doc else None
    prev_doc_id = prev_doc["source_doc_id"] if prev_doc else None

    html = fetch_homeaffairs(url)
    section_text = extract_sections(html)
    section_bytes = section_text.encode("utf-8")
    curr_hash = hash_content(section_bytes)

    if prev_hash == curr_hash:
        snap_meta = snapshot(section_bytes, source_id, SNAPSHOTS_DIR)
        return {
            "source_doc_id": prev_doc_id,
            "change_event_id": None,
            "impact_score": 0,
            "requires_review": False,
            "signals": ["no change detected — identical section hash"],
            "snapshot": snap_meta,
        }

    snap_meta = snapshot(section_bytes, source_id, SNAPSHOTS_DIR)
    score_result = impact_scorer.score(None, section_bytes, "HOMEAFFAIRS_PAGE")

    now_iso = datetime.now(timezone.utc).isoformat()
    source_doc_id = db.insert_source_document({
        "source_type": "HOMEAFFAIRS_PAGE",
        "title": title or f"Home Affairs page: {source_id}",
        "canonical_url": canonical_url,
        "content_hash": curr_hash,
        "raw_blob_uri": snap_meta["snapshot_path"],
        "retrieved_at": now_iso,
        "metadata_json": {"source_id": source_id, "byte_size": snap_meta["byte_size"]},
    })

    event_type = "initial_snapshot" if prev_hash is None else "text_change"
    change_event_id = db.insert_change_event({
        "source_doc_id_new": source_doc_id,
        "source_doc_id_old": prev_doc_id,
        "change_type": event_type,
        "impact_score": score_result["impact_score"],
        "requires_review": score_result["requires_review"],
        "summary": (
            f"Home Affairs change detected for {source_id}. "
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
