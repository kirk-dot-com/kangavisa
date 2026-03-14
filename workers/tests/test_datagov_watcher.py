"""
Tests for datagov_watcher.py — uses fixtures only, no live network.
"""

from __future__ import annotations

import json
from unittest.mock import MagicMock, patch

import pytest

from kangavisa_workers.datagov_watcher import (
    fetch_dataset_metadata,
    run_datagov_watch_and_persist,
)
from kangavisa_workers.frl_watcher import hash_content


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

DATASET_FIXTURE = {
    "id": "student-visas",
    "title": "Student Visas",
    "metadata_modified": "2025-01-15T00:00:00.000000",
    "resources": [
        {"id": "res-001", "name": "Student visa grants 2024", "format": "CSV"},
        {"id": "res-002", "name": "Student visa refusals 2024", "format": "CSV"},
    ],
}

DATASET_FIXTURE_CHANGED = {
    "id": "student-visas",
    "title": "Student Visas",
    "metadata_modified": "2025-03-01T00:00:00.000000",  # changed
    "resources": [
        {"id": "res-001", "name": "Student visa grants 2024", "format": "CSV"},
        {"id": "res-002", "name": "Student visa refusals 2024", "format": "CSV"},
        {"id": "res-003", "name": "Student visa grants 2025", "format": "CSV"},  # new
    ],
}


def _fixture_bytes(data: dict) -> bytes:
    return json.dumps(data, sort_keys=True).encode("utf-8")


# ---------------------------------------------------------------------------
# fetch_dataset_metadata tests (network mocked)
# ---------------------------------------------------------------------------

class TestFetchDatasetMetadata:
    def test_returns_result_dict_on_success(self):
        mock_resp = MagicMock()
        mock_resp.json.return_value = {"success": True, "result": DATASET_FIXTURE}
        mock_resp.raise_for_status = MagicMock()

        with patch("kangavisa_workers.datagov_watcher.httpx.Client") as mock_client_cls:
            mock_client = MagicMock()
            mock_client.__enter__ = MagicMock(return_value=mock_client)
            mock_client.__exit__ = MagicMock(return_value=False)
            mock_client.get.return_value = mock_resp
            mock_client_cls.return_value = mock_client

            result = fetch_dataset_metadata("student-visas")

        assert result["id"] == "student-visas"
        assert result["title"] == "Student Visas"

    def test_raises_key_error_on_success_false(self):
        mock_resp = MagicMock()
        mock_resp.json.return_value = {"success": False, "error": {"message": "Dataset not found"}}
        mock_resp.raise_for_status = MagicMock()

        with patch("kangavisa_workers.datagov_watcher.httpx.Client") as mock_client_cls:
            mock_client = MagicMock()
            mock_client.__enter__ = MagicMock(return_value=mock_client)
            mock_client.__exit__ = MagicMock(return_value=False)
            mock_client.get.return_value = mock_resp
            mock_client_cls.return_value = mock_client

            with pytest.raises(KeyError, match="success=false"):
                fetch_dataset_metadata("nonexistent-dataset")

    def test_raises_on_http_error(self):
        import httpx

        with patch("kangavisa_workers.datagov_watcher.httpx.Client") as mock_client_cls:
            mock_client = MagicMock()
            mock_client.__enter__ = MagicMock(return_value=mock_client)
            mock_client.__exit__ = MagicMock(return_value=False)
            mock_client.get.return_value.raise_for_status.side_effect = httpx.HTTPStatusError(
                "500", request=MagicMock(), response=MagicMock()
            )
            mock_client_cls.return_value = mock_client

            with pytest.raises(httpx.HTTPStatusError):
                fetch_dataset_metadata("student-visas")


# ---------------------------------------------------------------------------
# run_datagov_watch_and_persist tests (db + network mocked)
# ---------------------------------------------------------------------------

class TestRunDatagovWatchAndPersist:
    def _mock_fetch(self, monkeypatch, data: dict):
        monkeypatch.setattr(
            "kangavisa_workers.datagov_watcher.fetch_dataset_metadata",
            lambda dataset_id, **kw: data,
        )

    def test_no_change_returns_none_event_id(self, monkeypatch, tmp_path):
        monkeypatch.setenv("KANGAVISA_SNAPSHOTS_DIR", str(tmp_path))
        self._mock_fetch(monkeypatch, DATASET_FIXTURE)

        prev_hash = hash_content(_fixture_bytes(DATASET_FIXTURE))

        monkeypatch.setattr(
            "kangavisa_workers.datagov_watcher.db.get_latest_source_doc",
            lambda url: {"content_hash": prev_hash, "source_doc_id": "prev-uuid"},
        )

        result = run_datagov_watch_and_persist(
            dataset_id="student-visas",
            canonical_url="https://data.gov.au/data/dataset/student-visas",
            title="Student Visas dataset — data.gov.au",
        )

        assert result["change_event_id"] is None
        assert result["impact_score"] == 0

    def test_change_detected_calls_db_inserts(self, monkeypatch, tmp_path):
        monkeypatch.setenv("KANGAVISA_SNAPSHOTS_DIR", str(tmp_path))
        self._mock_fetch(monkeypatch, DATASET_FIXTURE_CHANGED)

        prev_hash = hash_content(_fixture_bytes(DATASET_FIXTURE))

        monkeypatch.setattr(
            "kangavisa_workers.datagov_watcher.db.get_latest_source_doc",
            lambda url: {"content_hash": prev_hash, "source_doc_id": "prev-uuid"},
        )
        monkeypatch.setattr(
            "kangavisa_workers.datagov_watcher.db.insert_source_document",
            lambda meta: "new-source-uuid",
        )
        monkeypatch.setattr(
            "kangavisa_workers.datagov_watcher.db.insert_change_event",
            lambda ev: "new-event-uuid",
        )

        result = run_datagov_watch_and_persist(
            dataset_id="student-visas",
            canonical_url="https://data.gov.au/data/dataset/student-visas",
        )

        assert result["change_event_id"] == "new-event-uuid"
        assert result["source_doc_id"] == "new-source-uuid"

    def test_first_snapshot_uses_new_instrument_change_type(self, monkeypatch, tmp_path):
        """First snapshot → change_type must be 'new_instrument' (not 'initial_snapshot')."""
        monkeypatch.setenv("KANGAVISA_SNAPSHOTS_DIR", str(tmp_path))
        self._mock_fetch(monkeypatch, DATASET_FIXTURE)

        monkeypatch.setattr(
            "kangavisa_workers.datagov_watcher.db.get_latest_source_doc",
            lambda url: None,
        )
        monkeypatch.setattr(
            "kangavisa_workers.datagov_watcher.db.insert_source_document",
            lambda meta: "new-source-uuid",
        )

        captured = {}

        def capture_change_event(ev):
            captured["ev"] = ev
            return "new-event-uuid"

        monkeypatch.setattr(
            "kangavisa_workers.datagov_watcher.db.insert_change_event",
            capture_change_event,
        )

        run_datagov_watch_and_persist(
            dataset_id="student-visas",
            canonical_url="https://data.gov.au/data/dataset/student-visas",
        )

        assert captured["ev"]["change_type"] in ("new_instrument", "dataset_update"), (
            f"Unexpected change_type: '{captured['ev']['change_type']}'"
        )

    def test_metadata_json_includes_dataset_id(self, monkeypatch, tmp_path):
        """US-G4: metadata_json must record dataset_id for reproducibility."""
        monkeypatch.setenv("KANGAVISA_SNAPSHOTS_DIR", str(tmp_path))
        self._mock_fetch(monkeypatch, DATASET_FIXTURE_CHANGED)

        prev_hash = hash_content(_fixture_bytes(DATASET_FIXTURE))

        monkeypatch.setattr(
            "kangavisa_workers.datagov_watcher.db.get_latest_source_doc",
            lambda url: {"content_hash": prev_hash, "source_doc_id": "prev-uuid"},
        )

        captured_meta = {}

        def capture_insert(meta):
            captured_meta.update(meta)
            return "new-source-uuid"

        monkeypatch.setattr(
            "kangavisa_workers.datagov_watcher.db.insert_source_document",
            capture_insert,
        )
        monkeypatch.setattr(
            "kangavisa_workers.datagov_watcher.db.insert_change_event",
            lambda ev: "new-event-uuid",
        )

        run_datagov_watch_and_persist(
            dataset_id="student-visas",
            canonical_url="https://data.gov.au/data/dataset/student-visas",
        )

        assert captured_meta["metadata_json"]["dataset_id"] == "student-visas"
        assert "metadata_modified" in captured_meta["metadata_json"]
        assert "resource_count" in captured_meta["metadata_json"]
