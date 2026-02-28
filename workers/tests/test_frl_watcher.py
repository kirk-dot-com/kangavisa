"""
Tests for frl_watcher.py — uses fixtures only, no live network.
"""

from __future__ import annotations

import hashlib
from pathlib import Path

import pytest

from kangavisa_workers.frl_watcher import (
    create_change_event,
    hash_content,
    snapshot,
)

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

FRL_FIXTURE_HTML = b"""
<!DOCTYPE html>
<html>
<head><title>Federal Register of Legislation</title></head>
<body>
  <h1>Migration Act 1958</h1>
  <p>Current as at 2024-07-01</p>
</body>
</html>
"""

FRL_FIXTURE_HTML_CHANGED = b"""
<!DOCTYPE html>
<html>
<head><title>Federal Register of Legislation</title></head>
<body>
  <h1>Migration Act 1958</h1>
  <p>Current as at 2024-10-15</p>  <!-- changed -->
</body>
</html>
"""


# ---------------------------------------------------------------------------
# hash_content tests
# ---------------------------------------------------------------------------

class TestHashContent:
    def test_hash_is_stable(self):
        """Same bytes must produce the same hash every time."""
        h1 = hash_content(FRL_FIXTURE_HTML)
        h2 = hash_content(FRL_FIXTURE_HTML)
        assert h1 == h2

    def test_hash_is_sha256(self):
        """Hash length should be 64 hex chars (SHA-256)."""
        h = hash_content(FRL_FIXTURE_HTML)
        assert len(h) == 64
        assert all(c in "0123456789abcdef" for c in h)

    def test_different_content_different_hash(self):
        """Different content must produce different hashes."""
        h1 = hash_content(FRL_FIXTURE_HTML)
        h2 = hash_content(FRL_FIXTURE_HTML_CHANGED)
        assert h1 != h2

    def test_empty_bytes(self):
        """Empty bytes should hash without error (known SHA-256 value)."""
        h = hash_content(b"")
        expected = hashlib.sha256(b"").hexdigest()
        assert h == expected


# ---------------------------------------------------------------------------
# snapshot tests
# ---------------------------------------------------------------------------

class TestSnapshot:
    def test_snapshot_creates_file(self, tmp_path):
        """snapshot() must write content to disk."""
        meta = snapshot(FRL_FIXTURE_HTML, "frl_migration_act", snapshots_dir=tmp_path)
        assert Path(meta["snapshot_path"]).exists()

    def test_snapshot_metadata_keys(self, tmp_path):
        """Returned dict must contain required keys."""
        meta = snapshot(FRL_FIXTURE_HTML, "frl_migration_act", snapshots_dir=tmp_path)
        for key in ("source_id", "snapshot_path", "content_hash", "byte_size", "captured_at"):
            assert key in meta, f"Missing key: {key}"

    def test_snapshot_hash_matches_content(self, tmp_path):
        """Hash in metadata must match actual content hash."""
        meta = snapshot(FRL_FIXTURE_HTML, "frl_migration_act", snapshots_dir=tmp_path)
        assert meta["content_hash"] == hash_content(FRL_FIXTURE_HTML)

    def test_snapshot_byte_size(self, tmp_path):
        """byte_size must equal actual content length."""
        meta = snapshot(FRL_FIXTURE_HTML, "frl_test", snapshots_dir=tmp_path)
        assert meta["byte_size"] == len(FRL_FIXTURE_HTML)

    def test_snapshot_file_content_intact(self, tmp_path):
        """Written file bytes must be identical to input."""
        meta = snapshot(FRL_FIXTURE_HTML, "frl_test", snapshots_dir=tmp_path)
        on_disk = Path(meta["snapshot_path"]).read_bytes()
        assert on_disk == FRL_FIXTURE_HTML


# ---------------------------------------------------------------------------
# create_change_event tests
# ---------------------------------------------------------------------------

class TestCreateChangeEvent:
    def test_returns_none_on_same_hash(self):
        """No change_event when hashes are identical."""
        h = hash_content(FRL_FIXTURE_HTML)
        event = create_change_event("frl_act", prev_hash=h, curr_hash=h, snapshot_path="/tmp/snap.bin")
        assert event is None

    def test_change_detected_on_diff(self):
        """change_event returned when hashes differ."""
        h1 = hash_content(FRL_FIXTURE_HTML)
        h2 = hash_content(FRL_FIXTURE_HTML_CHANGED)
        event = create_change_event("frl_act", prev_hash=h1, curr_hash=h2, snapshot_path="/tmp/snap.bin")
        assert event is not None
        assert event["event_type"] == "change_detected"

    def test_initial_snapshot_event_type(self):
        """First snapshot (prev_hash=None) → event_type is 'initial_snapshot'."""
        h = hash_content(FRL_FIXTURE_HTML)
        event = create_change_event("frl_act", prev_hash=None, curr_hash=h, snapshot_path="/tmp/snap.bin")
        assert event is not None
        assert event["event_type"] == "initial_snapshot"

    def test_change_event_contains_required_keys(self):
        """change_event dict must have all required fields."""
        h1 = hash_content(FRL_FIXTURE_HTML)
        h2 = hash_content(FRL_FIXTURE_HTML_CHANGED)
        event = create_change_event("frl_act", prev_hash=h1, curr_hash=h2, snapshot_path="/snap.bin")
        for key in ("event_type", "source_id", "prev_hash", "curr_hash",
                    "snapshot_path", "requires_review", "impact_score", "detected_at"):
            assert key in event, f"Missing key: {key}"

    def test_requires_review_is_a_bool(self):
        """Sprint 1: requires_review is now set by impact scoring (bool, not always False)."""
        h1 = hash_content(FRL_FIXTURE_HTML)
        h2 = hash_content(FRL_FIXTURE_HTML_CHANGED)
        event = create_change_event("frl_act", prev_hash=h1, curr_hash=h2, snapshot_path="/snap.bin")
        assert isinstance(event["requires_review"], bool)

    def test_impact_score_is_none_in_base_change_event(self):
        """create_change_event() is a pure struct builder; impact_score stays None here.
        Scoring is done by impact_scorer.score() in run_frl_watch_and_persist()."""
        h1 = hash_content(FRL_FIXTURE_HTML)
        h2 = hash_content(FRL_FIXTURE_HTML_CHANGED)
        event = create_change_event("frl_act", prev_hash=h1, curr_hash=h2, snapshot_path="/snap.bin")
        assert event["impact_score"] is None
