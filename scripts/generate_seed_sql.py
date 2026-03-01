#!/usr/bin/env python3
"""
scripts/generate_seed_sql.py
============================
KangaVisa KB Seed SQL Generator — Sprint 6
US-F6 | FR-K1, FR-K2, FR-K3

Reads all kb/seed/visa_NNN_*.json files and emits a single idempotent
SQL migration to migrations/seed_kb_v1.sql, ready to paste into the
Supabase SQL Editor.

Usage:
    python3 scripts/generate_seed_sql.py

Output:
    migrations/seed_kb_v1.sql
"""

import json
import os
import sys
import uuid
from pathlib import Path
from datetime import datetime

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
REPO_ROOT = Path(__file__).parent.parent
SEED_DIR  = REPO_ROOT / "kb" / "seed"
MIGRATIONS_DIR = REPO_ROOT / "migrations"
OUTPUT_FILE = MIGRATIONS_DIR / "seed_kb_v1.sql"

# ---------------------------------------------------------------------------
# Visa subclasses to seed (order matters — all references must exist)
# ---------------------------------------------------------------------------
VISA_SUBCLASSES = [
    {"code": "500", "stream": None,  "audience": "B2C", "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/student-500"},
    {"code": "485", "stream": None,  "audience": "B2C", "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485"},
    {"code": "482", "stream": None,  "audience": "Both","url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-skill-shortage-482"},
    {"code": "417", "stream": None,  "audience": "B2C", "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/work-holiday-417"},
    {"code": "820", "stream": None,  "audience": "B2C", "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-onshore-820-801"},
]

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def sql_str(v):
    """Escape a Python string for SQL single-quoted literal."""
    if v is None:
        return "NULL"
    return "'" + str(v).replace("'", "''") + "'"

def sql_json(v):
    """Serialize Python value to SQL jsonb literal."""
    return sql_str(json.dumps(v, ensure_ascii=False))

def sql_date(v):
    if v is None:
        return "NULL"
    return f"'{v}'"

def deterministic_uuid(namespace: str, name: str) -> str:
    """Generate a stable UUID5 from a namespace + name so re-runs are idempotent."""
    ns = uuid.UUID("6ba7b810-9dad-11d1-80b4-00c04fd430c8")  # UUID namespace URL
    return str(uuid.uuid5(ns, f"{namespace}:{name}"))

def load_json(path: Path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)

# ---------------------------------------------------------------------------
# SQL generators
# ---------------------------------------------------------------------------
def gen_visa_subclass(subclass: dict, visa_uuid: str) -> str:
    code     = subclass["code"]
    stream   = sql_str(subclass.get("stream"))
    audience = subclass["audience"]
    url      = sql_str(subclass.get("url"))
    now      = f"'{datetime.utcnow().isoformat()}Z'"
    return (
        f"INSERT INTO visa_subclass (visa_id, subclass_code, stream, audience, canonical_info_url, last_verified_at)\n"
        f"  VALUES ('{visa_uuid}':uuid, {sql_str(code)}, {stream}, '{audience}':kb_audience, {url}, {now})\n"
        f"  ON CONFLICT DO NOTHING;\n"
    )

def gen_requirement(req: dict, req_uuid: str, visa_uuid: str) -> str:
    eff = req.get("effective", {})
    return (
        f"INSERT INTO requirement\n"
        f"  (requirement_id, visa_id, requirement_type, title, plain_english,\n"
        f"   legal_basis, operational_basis, rule_logic, effective_from, effective_to,\n"
        f"   confidence, last_reviewed_at)\n"
        f"VALUES (\n"
        f"  '{req_uuid}'::uuid,\n"
        f"  '{visa_uuid}'::uuid,\n"
        f"  {sql_str(req['requirement_type'])}::kb_requirement_type,\n"
        f"  {sql_str(req['title'])},\n"
        f"  {sql_str(req['plain_english'])},\n"
        f"  {sql_json(req.get('legal_basis', []))}::jsonb,\n"
        f"  {sql_json(req.get('operational_basis', []))}::jsonb,\n"
        f"  {sql_json(req.get('rule_logic', {}))}::jsonb,\n"
        f"  {sql_date(eff.get('from'))},\n"
        f"  {sql_date(eff.get('to'))},\n"
        f"  {sql_str(req.get('confidence', 'medium'))}::kb_confidence,\n"
        f"  {sql_str(req.get('last_reviewed_at'))}\n"
        f") ON CONFLICT (requirement_id) DO NOTHING;\n"
    )

def gen_evidence_item(ev: dict, ev_uuid: str, req_uuid: str) -> str:
    eff = ev.get("effective", {})
    return (
        f"INSERT INTO evidence_item\n"
        f"  (evidence_id, requirement_id, label, what_it_proves, examples,\n"
        f"   common_gaps, priority, effective_from, effective_to, legal_basis)\n"
        f"VALUES (\n"
        f"  '{ev_uuid}'::uuid,\n"
        f"  '{req_uuid}'::uuid,\n"
        f"  {sql_str(ev['label'])},\n"
        f"  {sql_str(ev['what_it_proves'])},\n"
        f"  {sql_json(ev.get('examples', []))}::jsonb,\n"
        f"  {sql_json(ev.get('common_gaps', []))}::jsonb,\n"
        f"  {ev.get('priority', 3)},\n"
        f"  {sql_date(eff.get('from'))},\n"
        f"  {sql_date(eff.get('to'))},\n"
        f"  {sql_json(ev.get('legal_basis', []))}::jsonb\n"
        f") ON CONFLICT (evidence_id) DO NOTHING;\n"
    )

def gen_flag_template(flag: dict, flag_uuid: str, visa_uuid: str) -> str:
    eff = flag.get("effective", {})
    return (
        f"INSERT INTO flag_template\n"
        f"  (flag_id, visa_id, title, trigger_schema, why_it_matters,\n"
        f"   actions, evidence_examples, severity, effective_from, effective_to, sources)\n"
        f"VALUES (\n"
        f"  '{flag_uuid}'::uuid,\n"
        f"  '{visa_uuid}'::uuid,\n"
        f"  {sql_str(flag['title'])},\n"
        f"  {sql_json(flag.get('trigger_schema', {}))}::jsonb,\n"
        f"  {sql_str(flag['why_it_matters'])},\n"
        f"  {sql_json(flag.get('actions', []))}::jsonb,\n"
        f"  {sql_json(flag.get('evidence_examples', []))}::jsonb,\n"
        f"  {sql_str(flag.get('severity', 'warning'))}::kb_flag_severity,\n"
        f"  {sql_date(eff.get('from'))},\n"
        f"  {sql_date(eff.get('to'))},\n"
        f"  {sql_json(flag.get('sources', {}))}::jsonb\n"
        f") ON CONFLICT (flag_id) DO NOTHING;\n"
    )

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    MIGRATIONS_DIR.mkdir(exist_ok=True)

    lines = []
    lines.append("-- ============================================================")
    lines.append("-- KangaVisa KB Seed — v1")
    lines.append(f"-- Generated: {datetime.utcnow().strftime('%Y-%m-%d %H:%M UTC')}")
    lines.append("-- US-F6 | FR-K1, FR-K2, FR-K3")
    lines.append("-- Idempotent: safe to re-run (ON CONFLICT DO NOTHING)")
    lines.append("-- ============================================================")
    lines.append("")

    # ------------------------------------------------------------------
    # 1. visa_subclass rows
    # ------------------------------------------------------------------
    lines.append("-- ---- 1. Visa subclasses ----")
    visa_uuid_map: dict[str, str] = {}  # code → uuid
    for vs in VISA_SUBCLASSES:
        code = vs["code"]
        visa_uuid = deterministic_uuid("visa_subclass", code)
        visa_uuid_map[code] = visa_uuid
        lines.append(gen_visa_subclass(vs, visa_uuid))
    lines.append("")

    # ------------------------------------------------------------------
    # 2. Requirements
    # ------------------------------------------------------------------
    lines.append("-- ---- 2. Requirements ----")
    req_uuid_map: dict[str, str] = {}  # requirement_id string → uuid

    for vs in VISA_SUBCLASSES:
        code = vs["code"]
        visa_uuid = visa_uuid_map[code]

        req_files = sorted(SEED_DIR.glob(f"visa_{code}_requirements*.json"))
        if not req_files:
            print(f"  [WARN] No requirements JSON for subclass {code}", file=sys.stderr)
            continue

        lines.append(f"-- Subclass {code} requirements")
        for req_file in req_files:
            reqs = load_json(req_file)
            for req in reqs:
                rid = req["requirement_id"]
                req_uuid = deterministic_uuid("requirement", rid)
                req_uuid_map[rid] = req_uuid
                lines.append(gen_requirement(req, req_uuid, visa_uuid))
        lines.append("")

    # ------------------------------------------------------------------
    # 3. Evidence items
    # ------------------------------------------------------------------
    lines.append("-- ---- 3. Evidence items ----")
    for vs in VISA_SUBCLASSES:
        code = vs["code"]
        ev_file = SEED_DIR / f"visa_{code}_evidence_items.json"
        if not ev_file.exists():
            print(f"  [WARN] No evidence_items JSON for subclass {code}", file=sys.stderr)
            continue

        lines.append(f"-- Subclass {code} evidence items")
        evidence_items = load_json(ev_file)
        for ev in evidence_items:
            eid = ev["evidence_id"]
            rid = ev["requirement_id"]
            req_uuid = req_uuid_map.get(rid)
            if not req_uuid:
                print(f"  [WARN] evidence {eid} references unknown requirement {rid} — skipping", file=sys.stderr)
                continue
            ev_uuid = deterministic_uuid("evidence_item", eid)
            lines.append(gen_evidence_item(ev, ev_uuid, req_uuid))
        lines.append("")

    # ------------------------------------------------------------------
    # 4. Flag templates (500 only for now — other subclasses TBD)
    # ------------------------------------------------------------------
    lines.append("-- ---- 4. Flag templates ----")
    for vs in VISA_SUBCLASSES:
        code = vs["code"]
        visa_uuid = visa_uuid_map[code]
        flags_file = SEED_DIR / f"visa_{code}_flags.json"
        if not flags_file.exists():
            continue

        lines.append(f"-- Subclass {code} flag templates")
        flags = load_json(flags_file)
        for flag in flags:
            fid = flag["flag_id"]
            flag_uuid = deterministic_uuid("flag_template", fid)
            lines.append(gen_flag_template(flag, flag_uuid, visa_uuid))
        lines.append("")

    # ------------------------------------------------------------------
    # Write output
    # ------------------------------------------------------------------
    sql_content = "\n".join(lines)
    OUTPUT_FILE.write_text(sql_content, encoding="utf-8")

    # Summary
    req_count  = len(req_uuid_map)
    ev_count   = sum(len(load_json(f)) for f in SEED_DIR.glob("visa_*_evidence_items.json") if f.exists())
    flag_count = sum(len(load_json(f)) for f in SEED_DIR.glob("visa_*_flags.json") if f.exists())
    print(f"\n✅  Seed SQL written to: {OUTPUT_FILE.relative_to(REPO_ROOT)}")
    print(f"   Visa subclasses : {len(VISA_SUBCLASSES)}")
    print(f"   Requirements    : {req_count}")
    print(f"   Evidence items  : {ev_count}")
    print(f"   Flag templates  : {flag_count}")
    print(f"\nNext: Paste {OUTPUT_FILE.name} into your Supabase SQL Editor and run it.\n")

if __name__ == "__main__":
    main()
