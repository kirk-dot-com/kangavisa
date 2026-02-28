"""
seed_loader.py — Upsert all KB seed JSON into Supabase.

US-F6 | US-G1 | FR-K1, FR-K2, FR-K3: Populates structured KB objects
(visa_subclass, requirement, evidence_item, flag_template) from
`kb/seed/*.json` files using the service role key.

Usage:
    python3 -m kangavisa_workers.seed_loader [--dry-run]

All operations are UPSERT — safe to re-run. No existing rows are deleted.

Environment variables required:
    SUPABASE_URL              — e.g. https://xxxx.supabase.co
    SUPABASE_SERVICE_ROLE_KEY — secret key
"""

from __future__ import annotations

import argparse
import json
import logging
import os
import sys
from pathlib import Path

import httpx

logger = logging.getLogger("seed_loader")

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

SUPABASE_URL = os.environ.get("SUPABASE_URL", "")
SERVICE_ROLE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")
DEFAULT_TIMEOUT = 30

# Absolute path to kb/seed/ relative to this repo root.
# Workers are invoked from kangavisa/ root, so kb/ is a sibling of workers/.
SEED_DIR = Path(__file__).parent.parent.parent / "kb" / "seed"


# ---------------------------------------------------------------------------
# Visa subclass catalog (US-F6: all 5 MVP visa groups)
# ---------------------------------------------------------------------------

VISA_SUBCLASSES = [
    {"subclass_code": "500", "stream": None, "name": "Student", "description": "International student visa"},
    {"subclass_code": "485", "stream": None, "name": "Temporary Graduate", "description": "Post-study graduate visa"},
    {"subclass_code": "482", "stream": "SID", "name": "Temporary Skill Shortage (SID)", "description": "Employer-sponsored TSS — Short-term and Medium-term streams"},
    {"subclass_code": "417", "stream": None, "name": "Working Holiday", "description": "Working Holiday Maker — first, second, and third grant"},
    {"subclass_code": "820", "stream": None, "name": "Partner (onshore)", "description": "Partner visa — onshore temporary (820) → permanent (801)"},
    {"subclass_code": "309", "stream": None, "name": "Partner (offshore)", "description": "Partner visa — offshore temporary (309) → permanent (100)"},
]

# Mapping from seed filename prefix → subclass_code + stream
SEED_VISA_MAP = {
    "visa_500": {"subclass_code": "500", "stream": None},
    "visa_485": {"subclass_code": "485", "stream": None},
    "visa_482": {"subclass_code": "482", "stream": "SID"},
    "visa_417": {"subclass_code": "417", "stream": None},
    "visa_820": {"subclass_code": "820", "stream": None},
}


# ---------------------------------------------------------------------------
# HTTP helpers
# ---------------------------------------------------------------------------

def _headers() -> dict:
    if not SUPABASE_URL or not SERVICE_ROLE_KEY:
        raise EnvironmentError(
            "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set."
        )
    return {
        "apikey": SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SERVICE_ROLE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates,return=minimal",
    }


def _rest(table: str) -> str:
    return f"{SUPABASE_URL}/rest/v1/{table}"


def upsert(table: str, rows: list[dict], dry_run: bool = False) -> int:
    """
    UPSERT rows into *table* via Supabase REST API.
    Returns number of rows processed.
    If dry_run, logs what would be sent without making HTTP calls.
    """
    if not rows:
        return 0

    if dry_run:
        logger.info("[DRY RUN] Would upsert %d rows into %s", len(rows), table)
        for row in rows[:3]:
            logger.info("  Sample row: %s", json.dumps(row)[:120])
        return len(rows)

    with httpx.Client(timeout=DEFAULT_TIMEOUT) as client:
        resp = client.post(_rest(table), headers=_headers(), json=rows)
        if resp.status_code not in (200, 201):
            logger.error(
                "Upsert into %s failed: HTTP %s — %s",
                table, resp.status_code, resp.text[:300]
            )
            resp.raise_for_status()

    logger.info("  Upserted %d rows into %s", len(rows), table)
    return len(rows)


# ---------------------------------------------------------------------------
# Loaders
# ---------------------------------------------------------------------------

def load_visa_subclasses(dry_run: bool = False) -> int:
    """US-F6: Upsert all 5 MVP visa subclass rows."""
    logger.info("Loading visa_subclass rows (%d total)...", len(VISA_SUBCLASSES))
    rows = [
        {
            "subclass_code": v["subclass_code"],
            "stream": v["stream"],
            "name": v["name"],
            "description": v["description"],
        }
        for v in VISA_SUBCLASSES
    ]
    return upsert("visa_subclass", rows, dry_run)


def _load_json_seed(filename: str) -> list[dict]:
    path = SEED_DIR / filename
    if not path.exists():
        logger.warning("Seed file not found, skipping: %s", path)
        return []
    with path.open() as f:
        return json.load(f)


def _seed_files_matching(pattern: str) -> list[Path]:
    return sorted(SEED_DIR.glob(pattern))


def load_requirements(dry_run: bool = False) -> int:
    """US-F6 | FR-K1: Upsert all requirements from all visa seed files."""
    total = 0
    for seed_file in _seed_files_matching("visa_*_requirements*.json"):
        items = _load_json_seed(seed_file.name)
        if not items:
            continue

        rows = []
        for item in items:
            row = {
                "requirement_id": item["requirement_id"],
                "subclass_code": item["visa"]["subclass"],
                "requirement_type": item["requirement_type"],
                "title": item["title"],
                "plain_english": item["plain_english"],
                "effective_from": item["effective"]["from"],
                "effective_to": item["effective"].get("to"),
                "legal_basis": item.get("legal_basis", []),
                "operational_basis": item.get("operational_basis", []),
                "rule_logic": item.get("rule_logic", {}),
                "confidence": item.get("confidence", "medium"),
                "last_reviewed_at": item.get("last_reviewed_at"),
            }
            rows.append(row)

        logger.info("Loading %d requirements from %s...", len(rows), seed_file.name)
        total += upsert("requirement", rows, dry_run)

    return total


def load_evidence_items(dry_run: bool = False) -> int:
    """US-F6 | FR-K2: Upsert all evidence items from all visa seed files."""
    total = 0
    for seed_file in _seed_files_matching("visa_*_evidence_items.json"):
        items = _load_json_seed(seed_file.name)
        if not items:
            continue

        rows = []
        for item in items:
            row = {
                "evidence_id": item["evidence_id"],
                "requirement_id": item["requirement_id"],
                "label": item["label"],
                "description": item.get("description", ""),
                "priority": item.get("priority", 2),
                "what_it_proves": item.get("what_it_proves", ""),
                "common_gaps": item.get("common_gaps", []),
                "format_notes": item.get("format_notes", ""),
                "effective_from": item["effective"]["from"],
                "effective_to": item["effective"].get("to"),
            }
            rows.append(row)

        logger.info("Loading %d evidence items from %s...", len(rows), seed_file.name)
        total += upsert("evidence_item", rows, dry_run)

    return total


def load_flag_templates(dry_run: bool = False) -> int:
    """US-F6 | FR-K3: Upsert all flag templates from all visa seed files."""
    total = 0
    for seed_file in _seed_files_matching("visa_*_flags.json"):
        items = _load_json_seed(seed_file.name)
        if not items:
            continue

        rows = []
        for item in items:
            row = {
                "flag_id": item["flag_id"],
                "subclass_code": item["visa"]["subclass"],
                "title": item["title"],
                "trigger_schema": item.get("trigger_schema", {}),
                "why_it_matters": item.get("why_it_matters", ""),
                "actions": item.get("actions", []),
                "evidence_examples": item.get("evidence_examples", []),
                "severity": item.get("severity", "warning"),
                "effective_from": item["effective"]["from"],
                "effective_to": item["effective"].get("to"),
                "sources": item.get("sources", {}),
            }
            rows.append(row)

        logger.info("Loading %d flag templates from %s...", len(rows), seed_file.name)
        total += upsert("flag_template", rows, dry_run)

    return total


# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

def run(dry_run: bool = False) -> dict:
    """Run the full seed load. Returns counts by table."""
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s — %(message)s",
    )

    logger.info("=== KangaVisa KB Seed Loader ===")
    if dry_run:
        logger.info("DRY RUN mode — no writes to Supabase")

    counts = {
        "visa_subclass": load_visa_subclasses(dry_run),
        "requirement": load_requirements(dry_run),
        "evidence_item": load_evidence_items(dry_run),
        "flag_template": load_flag_templates(dry_run),
    }

    logger.info("=== Seed load complete ===")
    for table, count in counts.items():
        logger.info("  %-20s %d rows", table, count)

    return counts


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="KangaVisa KB seed loader")
    parser.add_argument("--dry-run", action="store_true", help="Log what would be upserted without writing to Supabase")
    args = parser.parse_args()
    result = run(dry_run=args.dry_run)
    total = sum(result.values())
    print(f"Done. {total} rows processed across {len(result)} tables.")
    sys.exit(0)
