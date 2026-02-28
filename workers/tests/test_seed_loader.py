"""
test_seed_loader.py — Tests for seed_loader.py

US-F6 | FR-K1, FR-K2, FR-K3

Uses pytest-httpx to mock Supabase upserts.
No live network or Supabase project required.
"""

from __future__ import annotations

import json
import os
import re
from pathlib import Path
from unittest.mock import patch

import pytest

# Set dummy env vars before importing seed_loader
os.environ["SUPABASE_URL"] = "https://test.supabase.co"
os.environ["SUPABASE_SERVICE_ROLE_KEY"] = "sb_secret_test_key"

from kangavisa_workers import seed_loader

UPSERT_URL = re.compile(r".*supabase.*")
SEED_DIR = seed_loader.SEED_DIR


class TestSeedDir:
    def test_seed_dir_exists(self):
        """Seed directory must exist in the repo."""
        assert SEED_DIR.exists(), f"Expected seed dir at {SEED_DIR}"

    def test_visa_500_files_present(self):
        """Original visa_500 seed files must exist."""
        assert (SEED_DIR / "visa_500_requirements.json").exists()
        assert (SEED_DIR / "visa_500_evidence_items.json").exists()

    def test_all_visa_groups_have_requirements(self):
        """All 4 new visa groups must have requirement seed files."""
        for visa in ["485", "482", "417", "820"]:
            path = SEED_DIR / f"visa_{visa}_requirements.json"
            assert path.exists(), f"Missing: {path.name}"

    def test_all_visa_groups_have_evidence_items(self):
        """All visa groups must have evidence item seed files."""
        for visa in ["485", "482", "417", "820"]:
            path = SEED_DIR / f"visa_{visa}_evidence_items.json"
            assert path.exists(), f"Missing: {path.name}"

    def test_flag_file_present(self):
        """visa_500_flags.json must exist."""
        assert (SEED_DIR / "visa_500_flags.json").exists()


class TestSeedJsonValidation:
    def test_all_requirements_have_required_fields(self):
        """Every requirement in every seed file must have required fields."""
        required = {"requirement_id", "visa", "requirement_type", "title", "plain_english", "effective"}
        for req_file in sorted(SEED_DIR.glob("visa_*_requirements*.json")):
            with req_file.open() as f:
                items = json.load(f)
            for item in items:
                missing = required - item.keys()
                assert not missing, f"{req_file.name}: item missing keys {missing}: {item.get('requirement_id')}"

    def test_all_requirements_have_legal_basis(self):
        """Every requirement must have at least one legal_basis citation."""
        for req_file in sorted(SEED_DIR.glob("visa_*_requirements*.json")):
            with req_file.open() as f:
                items = json.load(f)
            for item in items:
                assert item.get("legal_basis"), (
                    f"{req_file.name}: requirement {item.get('requirement_id')} has no legal_basis"
                )

    def test_all_evidence_items_have_required_fields(self):
        """Every evidence item must have required fields."""
        required = {"evidence_id", "requirement_id", "label", "what_it_proves", "effective"}
        for ev_file in sorted(SEED_DIR.glob("visa_*_evidence_items.json")):
            with ev_file.open() as f:
                items = json.load(f)
            for item in items:
                missing = required - item.keys()
                assert not missing, f"{ev_file.name}: item missing keys {missing}: {item.get('evidence_id')}"

    def test_effective_dates_are_iso_format(self):
        """All effective_from dates must be valid ISO YYYY-MM-DD strings."""
        import re
        iso_re = re.compile(r"^\d{4}-\d{2}-\d{2}$")
        for seed_file in sorted(SEED_DIR.glob("visa_*.json")):
            with seed_file.open() as f:
                items = json.load(f)
            for item in items:
                eff = item.get("effective", {})
                from_date = eff.get("from", "")
                assert iso_re.match(from_date), (
                    f"{seed_file.name}: invalid effective.from={from_date!r}"
                )

    def test_no_duplicate_requirement_ids(self):
        """requirement_id values must be unique across all seed files."""
        seen: set[str] = set()
        duplicates: list[str] = []
        for req_file in sorted(SEED_DIR.glob("visa_*_requirements*.json")):
            with req_file.open() as f:
                items = json.load(f)
            for item in items:
                rid = item.get("requirement_id", "")
                if rid in seen:
                    duplicates.append(rid)
                seen.add(rid)
        assert not duplicates, f"Duplicate requirement_ids found: {duplicates}"


class TestDryRun:
    def test_dry_run_does_not_call_http(self, httpx_mock):
        """Dry run must not make any HTTP calls."""
        # If any HTTP call were made, httpx_mock would raise an error
        counts = seed_loader.run(dry_run=True)
        # All tables must be represented
        assert "visa_subclass" in counts
        assert "requirement" in counts
        assert "evidence_item" in counts
        assert "flag_template" in counts

    def test_dry_run_returns_positive_counts(self):
        """Dry run must return non-zero counts for all tables."""
        counts = seed_loader.run(dry_run=True)
        assert counts["visa_subclass"] > 0, "No visa_subclass rows"
        assert counts["requirement"] > 0, "No requirement rows"
        assert counts["evidence_item"] > 0, "No evidence_item rows"


class TestUpsert:
    def test_upsert_sends_correct_payload(self, httpx_mock):
        """upsert() must POST a JSON array to the correct Supabase REST endpoint."""
        httpx_mock.add_response(url=UPSERT_URL, status_code=200, json=[])
        rows = [{"subclass_code": "500", "name": "Student"}]
        seed_loader.upsert("visa_subclass", rows, dry_run=False)
        requests = httpx_mock.get_requests()
        assert len(requests) == 1
        body = json.loads(requests[0].content)
        assert isinstance(body, list)
        assert body[0]["subclass_code"] == "500"

    def test_upsert_empty_rows_skipped(self, httpx_mock):
        """upsert() with empty list must not make any HTTP call."""
        seed_loader.upsert("visa_subclass", [], dry_run=False)
        assert httpx_mock.get_requests() == []
