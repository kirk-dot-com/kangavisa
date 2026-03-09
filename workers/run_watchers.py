#!/usr/bin/env python3
"""
run_watchers.py — Combined KangaVisa ingestion watcher entrypoint.

Runs all three watcher pipelines in sequence:
  1. FRL (legislation.gov.au)     — daily cadence, run on every invocation
  2. Home Affairs (immi.homeaffairs.gov.au) — weekly, all MVP visa pages
  3. data.gov.au (CKAN API)       — weekly, all relevant datasets

Usage:
    cd workers/
    python3 run_watchers.py

Reads SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY from .env.
Writes source_document + change_event rows to Supabase if content changed.
Snapshots saved to kb/snapshots/.

Replaces: run_frl_watch.py
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

from dotenv import load_dotenv

# Load workers/.env (relative to this script)
load_dotenv(Path(__file__).parent / ".env")

from kangavisa_workers.frl_watcher import run_frl_watch_and_persist          # noqa: E402
from kangavisa_workers.homeaffairs_watcher import run_homeaffairs_watch_and_persist  # noqa: E402
from kangavisa_workers.datagov_watcher import run_datagov_watch_and_persist   # noqa: E402


# ---------------------------------------------------------------------------
# FRL targets — authoritative legal sources (legislation.gov.au)
# ---------------------------------------------------------------------------
FRL_TARGETS = [
    {
        "url": "https://www.legislation.gov.au/Details/C2024C00075",
        "source_id": "frl_migration_act",
        "source_type": "FRL_ACT",
        "canonical_url": "https://www.legislation.gov.au/Details/C2024C00075",
        "title": "Migration Act 1958 (current compilation)",
    },
    {
        "url": "https://www.legislation.gov.au/Details/F2024L00481",
        "source_id": "frl_migration_regs",
        "source_type": "FRL_REGS",
        "canonical_url": "https://www.legislation.gov.au/Details/F2024L00481",
        "title": "Migration Regulations 1994 (current compilation)",
    },
    {
        "url": "https://www.legislation.gov.au/Details/F2016L00610",
        "source_id": "frl_lin_18_036",
        "source_type": "FRL_INSTRUMENT",
        "canonical_url": "https://www.legislation.gov.au/Details/F2016L00610",
        "title": "LIN 18/036 — Student visa English exemptions",
    },
]

# ---------------------------------------------------------------------------
# Home Affairs targets — MVP 5 pathways (immi.homeaffairs.gov.au)
# ---------------------------------------------------------------------------
HOMEAFFAIRS_TARGETS = [
    {
        "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/visitor-600",
        "source_id": "ha_visitor_600",
        "canonical_url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/visitor-600",
        "title": "Visitor visa (subclass 600) — Home Affairs",
    },
    {
        "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/student-500",
        "source_id": "ha_student_500",
        "canonical_url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/student-500",
        "title": "Student visa (subclass 500) — Home Affairs",
    },
    {
        "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485",
        "source_id": "ha_temp_graduate_485",
        "canonical_url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485",
        "title": "Temporary Graduate visa (subclass 485) — Home Affairs",
    },
    {
        "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-independent-189",
        "source_id": "ha_skilled_189",
        "canonical_url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-independent-189",
        "title": "Skilled Independent visa (subclass 189) — Home Affairs",
    },
    {
        "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-nominated-190",
        "source_id": "ha_skilled_190",
        "canonical_url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-nominated-190",
        "title": "Skilled Nominated visa (subclass 190) — Home Affairs",
    },
    {
        "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-work-regional-491",
        "source_id": "ha_skilled_491",
        "canonical_url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-work-regional-491",
        "title": "Skilled Work Regional visa (subclass 491) — Home Affairs",
    },
    {
        "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-820-801",
        "source_id": "ha_partner_820",
        "canonical_url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-820-801",
        "title": "Partner visa (subclass 820/801) — Home Affairs",
    },
]

# ---------------------------------------------------------------------------
# data.gov.au targets — CKAN dataset IDs for GovData pipeline
# ---------------------------------------------------------------------------
DATAGOV_TARGETS = [
    {
        "dataset_id": "student-visas",
        "canonical_url": "https://data.gov.au/data/dataset/student-visas",
        "title": "Student Visas dataset — data.gov.au",
    },
    {
        "dataset_id": "temporary-graduate-visas",
        "canonical_url": "https://data.gov.au/data/en/dataset/temporary-graduate-visas",
        "title": "Temporary Graduate Visas dataset — data.gov.au",
    },
    {
        "dataset_id": "visa-working-holiday-maker",
        "canonical_url": "https://www.data.gov.au/data/dataset/visa-working-holiday-maker",
        "title": "Working Holiday Maker Visas dataset — data.gov.au",
    },
]


# ---------------------------------------------------------------------------
# Runner helpers
# ---------------------------------------------------------------------------

def _print_result(source_id: str, result: dict) -> None:
    status = "CHANGED" if result.get("change_event_id") else "no change"
    print(
        f"  → {status} | score={result.get('impact_score', 0)} "
        f"| review={'YES' if result.get('requires_review') else 'no'} "
        f"| source_doc_id={result.get('source_doc_id')}"
    )


def run_frl(results: list) -> None:
    print("\n=== FRL Watcher (legislation.gov.au) ===\n")
    for target in FRL_TARGETS:
        print(f"[{target['source_id']}] {target['url']}")
        try:
            result = run_frl_watch_and_persist(
                url=target["url"],
                source_id=target["source_id"],
                source_type=target["source_type"],
                canonical_url=target["canonical_url"],
                title=target["title"],
            )
            _print_result(target["source_id"], result)
            results.append({"source_id": target["source_id"], "ok": True, **result})
        except Exception as exc:
            print(f"  ✗ ERROR: {exc}")
            results.append({"source_id": target["source_id"], "ok": False, "error": str(exc)})


def run_homeaffairs(results: list) -> None:
    print("\n=== Home Affairs Watcher (immi.homeaffairs.gov.au) ===\n")
    for target in HOMEAFFAIRS_TARGETS:
        print(f"[{target['source_id']}] {target['url']}")
        try:
            result = run_homeaffairs_watch_and_persist(
                url=target["url"],
                source_id=target["source_id"],
                canonical_url=target["canonical_url"],
                title=target["title"],
            )
            _print_result(target["source_id"], result)
            results.append({"source_id": target["source_id"], "ok": True, **result})
        except Exception as exc:
            print(f"  ✗ ERROR: {exc}")
            results.append({"source_id": target["source_id"], "ok": False, "error": str(exc)})


def run_datagov(results: list) -> None:
    print("\n=== data.gov.au Watcher (CKAN API) ===\n")
    for target in DATAGOV_TARGETS:
        print(f"[{target['dataset_id']}] {target['canonical_url']}")
        try:
            result = run_datagov_watch_and_persist(
                dataset_id=target["dataset_id"],
                canonical_url=target["canonical_url"],
                title=target["title"],
            )
            _print_result(target["dataset_id"], result)
            results.append({"source_id": target["dataset_id"], "ok": True, **result})
        except Exception as exc:
            print(f"  ✗ ERROR: {exc}")
            results.append({"source_id": target["dataset_id"], "ok": False, "error": str(exc)})


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    print("=" * 60)
    print("KangaVisa — Combined Ingestion Watcher")
    print("=" * 60)

    results: list = []

    run_frl(results)
    run_homeaffairs(results)
    run_datagov(results)

    ok = sum(1 for r in results if r["ok"])
    changed = sum(1 for r in results if r.get("change_event_id"))
    errors = len(results) - ok

    print("\n" + "=" * 60)
    print(f"Complete: {ok}/{len(results)} OK · {changed} change events · {errors} errors")
    print("=" * 60)

    if errors:
        sys.exit(1)


if __name__ == "__main__":
    main()
