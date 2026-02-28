"""
Tests for db.py — US-G1, US-G2 | FR-K4

Uses pytest-httpx to mock Supabase REST responses.
No live network or real Supabase project required.
"""

from __future__ import annotations

import os
import pytest

# Set dummy env vars before importing db so the module doesn't raise on import
os.environ.setdefault("SUPABASE_URL", "https://test.supabase.co")
os.environ.setdefault("SUPABASE_SERVICE_ROLE_KEY", "sb_secret_test_key")

import kangavisa_workers.db as db_module
from kangavisa_workers import db

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

FAKE_SOURCE_DOC_ID = "11111111-1111-1111-1111-111111111111"
FAKE_CHANGE_EVENT_ID = "22222222-2222-2222-2222-222222222222"

SAMPLE_SOURCE_DOC_META = {
    "source_type": "FRL_ACT",
    "title": "Migration Act 1958",
    "canonical_url": "https://www.legislation.gov.au/Details/C2024C00075",
    "content_hash": "abc123",
    "raw_blob_uri": "/tmp/snap.bin",
    "retrieved_at": "2026-03-01T00:00:00+00:00",
    "metadata_json": {"source_id": "frl_migration_act"},
}

SAMPLE_CHANGE_EVENT = {
    "source_doc_id_new": FAKE_SOURCE_DOC_ID,
    "source_doc_id_old": None,
    "change_type": "initial_snapshot",
    "impact_score": 60,
    "requires_review": False,
    "summary": "Initial snapshot of Migration Act 1958",
}


# ---------------------------------------------------------------------------
# get_latest_source_doc
# ---------------------------------------------------------------------------

class TestGetLatestSourceDoc:
    def test_returns_none_when_no_rows(self, httpx_mock):
        """US-G1: Returns None when no previous source_document for this URL."""
        httpx_mock.add_response(
            url__regex=r".*source_document.*",
            json=[],
        )
        result = db.get_latest_source_doc("https://example.com/page")
        assert result is None

    def test_returns_row_when_found(self, httpx_mock):
        """US-G1: Returns the most recent row when present."""
        row = {
            "source_doc_id": FAKE_SOURCE_DOC_ID,
            "content_hash": "abc123",
            "retrieved_at": "2026-03-01T00:00:00+00:00",
            "status": "current",
        }
        httpx_mock.add_response(
            url__regex=r".*source_document.*",
            json=[row],
        )
        result = db.get_latest_source_doc("https://example.com/page")
        assert result is not None
        assert result["content_hash"] == "abc123"
        assert result["source_doc_id"] == FAKE_SOURCE_DOC_ID


# ---------------------------------------------------------------------------
# insert_source_document
# ---------------------------------------------------------------------------

class TestInsertSourceDocument:
    def test_returns_source_doc_id(self, httpx_mock):
        """US-G1: Returns UUID of inserted source_document."""
        httpx_mock.add_response(
            url__regex=r".*source_document.*",
            json=[{"source_doc_id": FAKE_SOURCE_DOC_ID}],
            status_code=201,
        )
        result = db.insert_source_document(SAMPLE_SOURCE_DOC_META)
        assert result == FAKE_SOURCE_DOC_ID

    def test_raises_on_4xx(self, httpx_mock):
        """US-G1: Raises on Supabase error response."""
        import httpx as _httpx
        httpx_mock.add_response(
            url__regex=r".*source_document.*",
            status_code=400,
            json={"message": "bad request"},
        )
        with pytest.raises(_httpx.HTTPStatusError):
            db.insert_source_document(SAMPLE_SOURCE_DOC_META)


# ---------------------------------------------------------------------------
# insert_change_event
# ---------------------------------------------------------------------------

class TestInsertChangeEvent:
    def test_returns_change_event_id(self, httpx_mock):
        """US-G2: Returns UUID of inserted change_event."""
        httpx_mock.add_response(
            url__regex=r".*change_event.*",
            json=[{"change_event_id": FAKE_CHANGE_EVENT_ID}],
            status_code=201,
        )
        result = db.insert_change_event(SAMPLE_CHANGE_EVENT)
        assert result == FAKE_CHANGE_EVENT_ID

    def test_raises_on_5xx(self, httpx_mock):
        """US-G2: Raises on Supabase server error."""
        import httpx as _httpx
        httpx_mock.add_response(
            url__regex=r".*change_event.*",
            status_code=500,
        )
        with pytest.raises(_httpx.HTTPStatusError):
            db.insert_change_event(SAMPLE_CHANGE_EVENT)
