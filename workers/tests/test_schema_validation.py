"""
Tests for schema_validator.py — validates seed JSON objects against
the canonical KB JSON Schemas (requirement, evidence_item, flag_template, instrument).
"""

from __future__ import annotations

import json
from pathlib import Path

import pytest
from jsonschema import ValidationError

from kangavisa_workers.schema_validator import validate, validate_file, load_schema

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
KB_DIR = Path(__file__).parent.parent.parent / "kb"
SEED_DIR = KB_DIR / "seed"


# ---------------------------------------------------------------------------
# Seed file validation — these objects must always be schema-valid
# ---------------------------------------------------------------------------

class TestSeedFileValidation:
    def test_visa_500_requirements_are_valid(self):
        """All seed Requirements for visa 500 must pass JSON Schema validation."""
        errors = validate_file(SEED_DIR / "visa_500_requirements.json", "Requirement")
        assert errors == [], f"Schema validation errors:\n" + "\n".join(errors)

    def test_visa_500_evidence_items_are_valid(self):
        """All seed EvidenceItems for visa 500 must pass JSON Schema validation."""
        errors = validate_file(SEED_DIR / "visa_500_evidence_items.json", "EvidenceItem")
        assert errors == [], f"Schema validation errors:\n" + "\n".join(errors)


# ---------------------------------------------------------------------------
# Requirement schema — inline unit tests
# ---------------------------------------------------------------------------

class TestRequirementSchema:
    def _valid_requirement(self) -> dict:
        return {
            "requirement_id": "REQ-TEST-001",
            "visa": {"subclass": "500", "stream": None},
            "requirement_type": "genuine",
            "title": "Test Requirement",
            "plain_english": "This is a test requirement with sufficient text.",
            "effective": {"from": "2024-01-01", "to": None},
            "legal_basis": [{"authority": "FRL_ACT", "citation": None, "frl_title_id": None, "series": None, "notes": None}],
            "operational_basis": [{"authority": "HOMEAFFAIRS_PAGE", "url": "https://immi.homeaffairs.gov.au/test", "title": None, "last_checked": None}],
            "rule_logic": {"inputs": ["field_a"], "outputs": ["FLAG-001"], "logic_notes": None},
            "confidence": "high",
        }

    def test_valid_requirement_passes(self):
        validate(self._valid_requirement(), "Requirement")  # Must not raise

    def test_invalid_subclass_fails(self):
        req = self._valid_requirement()
        req["visa"]["subclass"] = "5000"  # 4 digits — invalid
        with pytest.raises(ValidationError):
            validate(req, "Requirement")

    def test_invalid_requirement_type_fails(self):
        req = self._valid_requirement()
        req["requirement_type"] = "invalid_type"
        with pytest.raises(ValidationError):
            validate(req, "Requirement")

    def test_invalid_confidence_fails(self):
        req = self._valid_requirement()
        req["confidence"] = "very_high"  # not in enum
        with pytest.raises(ValidationError):
            validate(req, "Requirement")

    def test_missing_required_field_fails(self):
        req = self._valid_requirement()
        del req["title"]
        with pytest.raises(ValidationError):
            validate(req, "Requirement")

    def test_invalid_authority_fails(self):
        req = self._valid_requirement()
        req["legal_basis"][0]["authority"] = "UNKNOWN_SOURCE"
        with pytest.raises(ValidationError):
            validate(req, "Requirement")


# ---------------------------------------------------------------------------
# EvidenceItem schema — inline unit tests
# ---------------------------------------------------------------------------

class TestEvidenceItemSchema:
    def _valid_evidence_item(self) -> dict:
        return {
            "evidence_id": "EV-TEST-001",
            "requirement_id": "REQ-TEST-001",
            "label": "Test Document",
            "what_it_proves": "This document proves the applicant meets the test requirement.",
            "examples": ["Example document A", "Example document B"],
            "common_gaps": ["Gap 1", "Gap 2"],
            "priority": 2,
            "effective": {"from": "2024-01-01", "to": None},
        }

    def test_valid_evidence_item_passes(self):
        validate(self._valid_evidence_item(), "EvidenceItem")  # Must not raise

    def test_invalid_priority_below_min_fails(self):
        item = self._valid_evidence_item()
        item["priority"] = 0  # minimum is 1
        with pytest.raises(ValidationError):
            validate(item, "EvidenceItem")

    def test_invalid_priority_above_max_fails(self):
        item = self._valid_evidence_item()
        item["priority"] = 6  # maximum is 5
        with pytest.raises(ValidationError):
            validate(item, "EvidenceItem")

    def test_missing_label_fails(self):
        item = self._valid_evidence_item()
        del item["label"]
        with pytest.raises(ValidationError):
            validate(item, "EvidenceItem")

    def test_empty_string_what_it_proves_fails(self):
        item = self._valid_evidence_item()
        item["what_it_proves"] = "short"  # minLength 10
        with pytest.raises(ValidationError):
            validate(item, "EvidenceItem")


# ---------------------------------------------------------------------------
# load_schema — error handling
# ---------------------------------------------------------------------------

class TestLoadSchema:
    def test_unknown_model_type_raises_value_error(self):
        with pytest.raises(ValueError, match="Unknown model type"):
            load_schema("UnknownType")
