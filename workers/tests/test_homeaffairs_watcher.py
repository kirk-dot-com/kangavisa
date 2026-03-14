"""
Tests for homeaffairs_watcher.py — uses fixtures only, no live network.
"""

from __future__ import annotations

from unittest.mock import MagicMock, patch

import pytest

from kangavisa_workers.homeaffairs_watcher import (
    extract_sections,
    fetch_homeaffairs,
    run_homeaffairs_watch_and_persist,
)
from kangavisa_workers.frl_watcher import hash_content


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

HA_FIXTURE_HTML = b"""
<!DOCTYPE html>
<html>
<head><title>Visitor Visa 600 - Home Affairs</title></head>
<body>
  <main>
    <h2>Who can apply</h2>
    <p>You can apply if you want to visit Australia temporarily for tourism or business.</p>
    <h2>How long you can stay</h2>
    <p>Usually 3, 6 or 12 months.</p>
  </main>
</body>
</html>
"""

HA_FIXTURE_HTML_CHANGED = b"""
<!DOCTYPE html>
<html>
<head><title>Visitor Visa 600 - Home Affairs</title></head>
<body>
  <main>
    <h2>Who can apply</h2>
    <p>You can apply if you want to visit Australia temporarily for tourism or business.</p>
    <h2>How long you can stay</h2>
    <p>Usually 3, 6, 9 or 12 months.</p>  <!-- changed -->
  </main>
</body>
</html>
"""

HA_FIXTURE_HTML_NO_MAIN = b"""
<!DOCTYPE html>
<html>
<body>
  <p>No main tag here.</p>
</body>
</html>
"""


# ---------------------------------------------------------------------------
# extract_sections tests
# ---------------------------------------------------------------------------

class TestExtractSections:
    def test_returns_string(self):
        text = extract_sections(HA_FIXTURE_HTML)
        assert isinstance(text, str)

    def test_extracts_main_content(self):
        text = extract_sections(HA_FIXTURE_HTML)
        assert "Who can apply" in text
        assert "How long you can stay" in text

    def test_changed_content_produces_different_text(self):
        t1 = extract_sections(HA_FIXTURE_HTML)
        t2 = extract_sections(HA_FIXTURE_HTML_CHANGED)
        assert t1 != t2

    def test_falls_back_without_main_tag(self):
        """When there is no <main>, falls back to body text — should not raise."""
        text = extract_sections(HA_FIXTURE_HTML_NO_MAIN)
        assert "No main tag here" in text

    def test_hash_changes_on_content_change(self):
        t1 = extract_sections(HA_FIXTURE_HTML).encode("utf-8")
        t2 = extract_sections(HA_FIXTURE_HTML_CHANGED).encode("utf-8")
        assert hash_content(t1) != hash_content(t2)


# ---------------------------------------------------------------------------
# fetch_homeaffairs tests (network mocked)
# ---------------------------------------------------------------------------

class TestFetchHomeaffairs:
    def test_returns_bytes_on_success(self):
        mock_resp = MagicMock()
        mock_resp.content = HA_FIXTURE_HTML
        mock_resp.raise_for_status = MagicMock()

        with patch("kangavisa_workers.homeaffairs_watcher.httpx.Client") as mock_client_cls:
            mock_client = MagicMock()
            mock_client.__enter__ = MagicMock(return_value=mock_client)
            mock_client.__exit__ = MagicMock(return_value=False)
            mock_client.get.return_value = mock_resp
            mock_client_cls.return_value = mock_client

            result = fetch_homeaffairs("https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/visitor-600")

        assert result == HA_FIXTURE_HTML

    def test_raises_on_http_error(self):
        import httpx

        with patch("kangavisa_workers.homeaffairs_watcher.httpx.Client") as mock_client_cls:
            mock_client = MagicMock()
            mock_client.__enter__ = MagicMock(return_value=mock_client)
            mock_client.__exit__ = MagicMock(return_value=False)
            mock_client.get.return_value.raise_for_status.side_effect = httpx.HTTPStatusError(
                "404", request=MagicMock(), response=MagicMock()
            )
            mock_client_cls.return_value = mock_client

            with pytest.raises(httpx.HTTPStatusError):
                fetch_homeaffairs("https://immi.homeaffairs.gov.au/bad-url")


# ---------------------------------------------------------------------------
# run_homeaffairs_watch_and_persist tests (db + network mocked)
# ---------------------------------------------------------------------------

class TestRunHomeaffairsWatchAndPersist:
    def _mock_fetch(self, monkeypatch, html: bytes):
        monkeypatch.setattr(
            "kangavisa_workers.homeaffairs_watcher.fetch_homeaffairs",
            lambda url, **kw: html,
        )

    def test_no_change_returns_none_event_id(self, monkeypatch, tmp_path):
        monkeypatch.setenv("KANGAVISA_SNAPSHOTS_DIR", str(tmp_path))
        self._mock_fetch(monkeypatch, HA_FIXTURE_HTML)

        section_text = extract_sections(HA_FIXTURE_HTML)
        prev_hash = hash_content(section_text.encode("utf-8"))

        monkeypatch.setattr(
            "kangavisa_workers.homeaffairs_watcher.db.get_latest_source_doc",
            lambda url: {"content_hash": prev_hash, "source_doc_id": "prev-uuid"},
        )

        result = run_homeaffairs_watch_and_persist(
            url="https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/visitor-600",
            source_id="ha_visitor_600",
            canonical_url="https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/visitor-600",
            title="Visitor visa (subclass 600) — Home Affairs",
        )

        assert result["change_event_id"] is None
        assert result["impact_score"] == 0

    def test_change_detected_calls_db_inserts(self, monkeypatch, tmp_path):
        monkeypatch.setenv("KANGAVISA_SNAPSHOTS_DIR", str(tmp_path))
        self._mock_fetch(monkeypatch, HA_FIXTURE_HTML_CHANGED)

        # Prev hash matches original (so changed content triggers an event)
        section_text = extract_sections(HA_FIXTURE_HTML)
        prev_hash = hash_content(section_text.encode("utf-8"))

        monkeypatch.setattr(
            "kangavisa_workers.homeaffairs_watcher.db.get_latest_source_doc",
            lambda url: {"content_hash": prev_hash, "source_doc_id": "prev-uuid"},
        )
        monkeypatch.setattr(
            "kangavisa_workers.homeaffairs_watcher.db.insert_source_document",
            lambda meta: "new-source-uuid",
        )
        monkeypatch.setattr(
            "kangavisa_workers.homeaffairs_watcher.db.insert_change_event",
            lambda ev: "new-event-uuid",
        )

        result = run_homeaffairs_watch_and_persist(
            url="https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/visitor-600",
            source_id="ha_visitor_600",
            canonical_url="https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/visitor-600",
        )

        assert result["change_event_id"] == "new-event-uuid"
        assert result["source_doc_id"] == "new-source-uuid"

    def test_first_snapshot_uses_new_instrument_change_type(self, monkeypatch, tmp_path):
        """
        Verifies the Sprint 12 enum fix: first snapshot must use 'new_instrument',
        NOT 'initial_snapshot' (which is not a valid kb_change_type enum value).
        """
        monkeypatch.setenv("KANGAVISA_SNAPSHOTS_DIR", str(tmp_path))
        self._mock_fetch(monkeypatch, HA_FIXTURE_HTML)

        monkeypatch.setattr(
            "kangavisa_workers.homeaffairs_watcher.db.get_latest_source_doc",
            lambda url: None,  # no previous doc → first snapshot
        )
        monkeypatch.setattr(
            "kangavisa_workers.homeaffairs_watcher.db.insert_source_document",
            lambda meta: "new-source-uuid",
        )

        captured = {}

        def capture_change_event(ev):
            captured["ev"] = ev
            return "new-event-uuid"

        monkeypatch.setattr(
            "kangavisa_workers.homeaffairs_watcher.db.insert_change_event",
            capture_change_event,
        )

        run_homeaffairs_watch_and_persist(
            url="https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/visitor-600",
            source_id="ha_visitor_600",
            canonical_url="https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/visitor-600",
        )

        assert captured["ev"]["change_type"] == "new_instrument", (
            f"Expected 'new_instrument' but got '{captured['ev']['change_type']}'. "
            "The kb_change_type enum does not include 'initial_snapshot'."
        )
