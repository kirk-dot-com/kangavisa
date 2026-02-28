"""
db.py — Supabase REST client for KangaVisa workers.

US-G1 | FR-K4: Every snapshot stored with provenance in source_document.
US-G2 | FR-K4: change_event written with impact score + review gating.

Uses httpx directly against the Supabase REST API with the service role key
(bypasses RLS — appropriate for server-side ingestion workers only).

Environment variables required:
    SUPABASE_URL              — e.g. https://xxxx.supabase.co
    SUPABASE_SERVICE_ROLE_KEY — secret key (sb_secret_...)
"""

from __future__ import annotations

import os
from typing import Optional

import httpx

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
SUPABASE_URL = os.environ.get("SUPABASE_URL", "")
SERVICE_ROLE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")
DEFAULT_TIMEOUT = 20  # seconds


def _headers() -> dict:
    if not SUPABASE_URL or not SERVICE_ROLE_KEY:
        raise EnvironmentError(
            "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set."
        )
    return {
        "apikey": SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SERVICE_ROLE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "return=representation",
    }


def _rest(table: str) -> str:
    return f"{SUPABASE_URL}/rest/v1/{table}"


# ---------------------------------------------------------------------------
# source_document
# ---------------------------------------------------------------------------

def get_latest_source_doc(canonical_url: str) -> Optional[dict]:
    """
    US-G1: Retrieve the most recent source_document row for *canonical_url*.
    Returns the row dict (including content_hash) or None if not yet seen.
    """
    with httpx.Client(timeout=DEFAULT_TIMEOUT) as client:
        resp = client.get(
            _rest("source_document"),
            headers=_headers(),
            params={
                "canonical_url": f"eq.{canonical_url}",
                "order": "retrieved_at.desc",
                "limit": "1",
                "select": "source_doc_id,content_hash,retrieved_at,status",
            },
        )
        resp.raise_for_status()
        rows = resp.json()
        return rows[0] if rows else None


def insert_source_document(meta: dict) -> str:
    """
    US-G1: Insert a new source_document row.

    *meta* must include:
        source_type, title, canonical_url, content_hash,
        raw_blob_uri, retrieved_at, metadata_json (dict)

    Returns the new source_doc_id (UUID string).
    """
    payload = {
        "source_type": meta["source_type"],
        "title": meta["title"],
        "canonical_url": meta["canonical_url"],
        "content_hash": meta["content_hash"],
        "raw_blob_uri": meta["raw_blob_uri"],
        "retrieved_at": meta["retrieved_at"],
        "metadata_json": meta.get("metadata_json", {}),
        "status": meta.get("status", "current"),
    }
    if meta.get("effective_from"):
        payload["effective_from"] = meta["effective_from"]

    with httpx.Client(timeout=DEFAULT_TIMEOUT) as client:
        resp = client.post(_rest("source_document"), headers=_headers(), json=payload)
        resp.raise_for_status()
        return resp.json()[0]["source_doc_id"]


# ---------------------------------------------------------------------------
# change_event
# ---------------------------------------------------------------------------

def insert_change_event(event: dict) -> str:
    """
    US-G2: Insert a change_event row.

    *event* must include:
        source_doc_id_new (UUID str), change_type, impact_score (int),
        summary (str), requires_review (bool)

    Optional: source_doc_id_old (UUID str | None), affected_visa_ids (list[str])

    Returns the new change_event_id (UUID string).
    """
    payload = {
        "source_doc_id_new": event["source_doc_id_new"],
        "change_type": event.get("change_type", "text_change"),
        "impact_score": event["impact_score"],
        "summary": event["summary"],
        "requires_review": event["requires_review"],
        "affected_visa_ids": event.get("affected_visa_ids", []),
    }
    if event.get("source_doc_id_old"):
        payload["source_doc_id_old"] = event["source_doc_id_old"]

    with httpx.Client(timeout=DEFAULT_TIMEOUT) as client:
        resp = client.post(_rest("change_event"), headers=_headers(), json=payload)
        resp.raise_for_status()
        return resp.json()[0]["change_event_id"]
