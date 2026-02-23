"""
JSON Schema validator for KangaVisa KB model objects.

Validates Requirement, EvidenceItem, FlagTemplate, Instrument
against the canonical JSON Schemas in kb/*.jsonschema.

Used in:
  - workers/tests/test_schema_validation.py (automated)
  - CI pipeline (python -m pytest workers/tests/)
  - Future: pre-publish gate in KB release process
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import jsonschema
from jsonschema import ValidationError

# ---------------------------------------------------------------------------
# Schema paths
# ---------------------------------------------------------------------------
KB_DIR = Path(__file__).parent.parent.parent / "kb"

SCHEMA_PATHS: dict[str, Path] = {
    "Requirement":  KB_DIR / "requirement.jsonschema",
    "EvidenceItem": KB_DIR / "evidence_item.jsonschema",
    "FlagTemplate": KB_DIR / "flag_template.jsonschema",
    "Instrument":   KB_DIR / "instrument.jsonschema",
}


def load_schema(model_type: str) -> dict:
    """Load and return the JSON Schema dict for *model_type*."""
    path = SCHEMA_PATHS.get(model_type)
    if path is None:
        raise ValueError(
            f"Unknown model type '{model_type}'. "
            f"Expected one of: {list(SCHEMA_PATHS)}"
        )
    return json.loads(path.read_text(encoding="utf-8"))


def validate(obj: dict[str, Any], model_type: str) -> None:
    """
    Validate *obj* against the JSON Schema for *model_type*.

    Raises ``jsonschema.ValidationError`` on failure.
    Raises ``ValueError`` for unknown model_type.
    """
    schema = load_schema(model_type)
    jsonschema.validate(instance=obj, schema=schema)


def validate_file(file_path: Path, model_type: str) -> list[str]:
    """
    Load a JSON file (single object or list) and validate each item.

    Returns a list of error strings (empty = all valid).
    """
    data = json.loads(file_path.read_text(encoding="utf-8"))
    items = data if isinstance(data, list) else [data]

    errors: list[str] = []
    for i, item in enumerate(items):
        try:
            validate(item, model_type)
        except ValidationError as exc:
            errors.append(f"[{i}] {exc.message} (path: {list(exc.absolute_path)})")
    return errors
