#!/usr/bin/env python3
"""
run_frl_watch.py — Run the FRL watcher pipeline for a set of target instruments.

Usage:
    cd workers/
    python3 run_frl_watch.py

Reads SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY from .env.
Writes source_document + change_event rows to Supabase if content changed.
Snapshots saved to kb/snapshots/.
"""

from __future__ import annotations

import os
from pathlib import Path

from dotenv import load_dotenv

# Load workers/.env (relative to this script)
load_dotenv(Path(__file__).parent / ".env")

from kangavisa_workers.frl_watcher import run_frl_watch_and_persist  # noqa: E402

# ---------------------------------------------------------------------------
# FRL targets — expand as new instruments are identified
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


def main() -> None:
    print("=== KangaVisa FRL Watcher ===\n")
    results = []

    for target in FRL_TARGETS:
        print(f"[{target['source_id']}] Fetching {target['url']} ...")
        try:
            result = run_frl_watch_and_persist(
                url=target["url"],
                source_id=target["source_id"],
                source_type=target["source_type"],
                canonical_url=target["canonical_url"],
                title=target["title"],
            )
            status = "CHANGED" if result["change_event_id"] else "no change"
            print(
                f"  → {status} | score={result['impact_score']} "
                f"| review={'YES' if result['requires_review'] else 'no'} "
                f"| source_doc_id={result['source_doc_id']}"
            )
            results.append({"source_id": target["source_id"], "ok": True, **result})
        except Exception as exc:
            print(f"  ✗ ERROR: {exc}")
            results.append({"source_id": target["source_id"], "ok": False, "error": str(exc)})

    ok = sum(1 for r in results if r["ok"])
    changed = sum(1 for r in results if r.get("change_event_id"))
    print(f"\nDone. {ok}/{len(results)} targets OK · {changed} change events written.")


if __name__ == "__main__":
    main()
