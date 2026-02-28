# KangaVisa — Sprint Walkthroughs

This file is updated at the end of every sprint. It records what was built, what was tested, and how to verify it.

---

## Sprint 0 — Scaffold
**Completed:** 2026-02-23  
**Commits:** `3331e5b`, `3fc308e` on `main`

### What was built

| Area | Detail |
|---|---|
| Monorepo structure | `app/` (Next.js 14), `workers/` (Python), `kb/` (schema + seed), `.github/` |
| Next.js 14 app | App Router + TypeScript, Vercel-ready, `npm run dev` works locally |
| KB schema | `kb/schema.sql` — 8 Postgres tables with UUID PKs, RLS-ready, effective-dating first-class |
| KB seed | `kb/seed/` — 2 Requirements + 2 EvidenceItems for visa subclass 500 |
| Python worker package | `pyproject.toml` + `kangavisa_workers/` package with `frl_watcher.py` + `schema_validator.py` |
| FRL watcher skeleton | `fetch_frl()`, `hash_content()`, `snapshot()`, `create_change_event()` — no DB writes yet |
| JSON Schema validator | Validates `requirement` and `evidence_item` structures against `kb/schemas/*.json` |
| GitHub CI | `.github/workflows/ci.yml` — pytest + ESLint + tsc on every push to `main` |
| Supabase wiring | Project created (AU Sydney), `kb/schema.sql` applied, all 8 tables live |
| Next.js Supabase client | `app/lib/supabase.ts` (browser/anon) + `app/lib/supabase-admin.ts` (server/service role) |

### Tests
```
29 pytest tests — all passing
Platform: Python 3.9.6, pytest 8.4.2
```

### How to verify

```bash
# Python workers
cd workers && pip3 install -e ".[dev]"
python3 -m pytest tests/ -v
# → 29 passed

# Next.js TypeScript check
cd app && npx tsc --noEmit
# → 0 errors

# Supabase smoke test (requires .env.local)
node --input-type=module < /tmp/supabase_smoke_test.mjs
# → source_document ✅, visa_subclass ✅, change_event ✅
```

### Key decisions
- Supabase new key format: **Publishable key** (≈ anon) and **Secret key** (≈ service_role)
- `supabase-admin.ts` is server-only — never import in Client Components
- `kb/schema.sql` UNIQUE constraint on `visa_subclass` uses a **unique index** (not inline constraint) due to Postgres restriction on `COALESCE()` in constraints

---

## Sprint 1 — KB Ingestion Lanes + Consent/Analytics Foundation
**Completed:** 2026-03-01  
**Commits:** `3fc308e`, `9eadce4` on `main`

### User stories delivered

| Story | Description | Status |
|---|---|---|
| US-G1 | Ingestion writes `source_document` with provenance | ✅ |
| US-G2 | `change_event` generation with impact scoring + review gating | ✅ |
| US-E1 | Consent toggles (granular + revocable) — schema foundation | ✅ migration authored |
| US-E2 | Consent event ledger (append-only) — schema foundation | ✅ migration authored |
| US-E3 | PII vault vs analytics store separation — schema foundation | ✅ migration authored |

### What was built

#### `workers/kangavisa_workers/db.py`
Supabase REST client for workers (uses `SUPABASE_SERVICE_ROLE_KEY`, bypasses RLS):
- `get_latest_source_doc(canonical_url)` — retrieves previous hash for diff
- `insert_source_document(meta)` → `source_doc_id` (UUID)
- `insert_change_event(event)` → `change_event_id` (UUID)

#### `workers/kangavisa_workers/impact_scorer.py`
Deterministic 0–100 heuristic (US-G2 AC):

| Signal | Points |
|---|---|
| Base (any change) | +10 |
| Initial snapshot (no prev) | +20 |
| Content diff > 5% of document | +40 |
| Keyword match (`visa`, `requirement`, `criterion`, `repeal`, `schedule`, `regulation`, `english`, `financial`, `occupation`, `specified work`, `exemption`) | +30 |
| Source type `FRL_ACT` or `FRL_REGS` | +20 |

Score ≥ 70 → `requires_review = True`

#### `workers/kangavisa_workers/frl_watcher.py` (upgraded)
Added `run_frl_watch_and_persist()` — full pipeline:
1. `db.get_latest_source_doc()` → prev hash
2. `fetch_frl()` + `snapshot()` (pure functions unchanged)
3. `impact_scorer.score()` → score + signals
4. `db.insert_source_document()` → `source_doc_id`
5. `db.insert_change_event()` → `change_event_id`

Returns `{source_doc_id, change_event_id, impact_score, requires_review, signals, snapshot}`.

#### `workers/kangavisa_workers/homeaffairs_watcher.py`
Weekly watcher for `immi.homeaffairs.gov.au`. Uses BeautifulSoup to extract `<main>` section text as the diff unit. Same persist pipeline as FRL.

#### `workers/kangavisa_workers/datagov_watcher.py`
Weekly watcher for `data.gov.au` CKAN API. Hashes `metadata_modified` field. Stores `dataset_id` + `metadata_modified` + `resource_count` in `metadata_json` (US-G4 provenance requirement).

#### `migrations_20260301_daas_consent_and_analytics.sql`
> ⚠️ **Manual step:** Run in Supabase SQL Editor to apply.

Creates:
- `consent_state` — one row per user, `govdata_research_enabled DEFAULT false`
- `consent_event` — append-only ledger (4 event types)
- `analytics_event` — pseudonymous journey telemetry; RLS insert requires `product_analytics_enabled = true`

All three tables have RLS enabled with user-scoped policies.

### Tests
```
48 pytest tests — all passing (up from 29)
Platform: Python 3.9.6, pytest 8.4.2, pytest-httpx 0.35.0

New tests:
  test_db.py            6 tests  (mocked Supabase REST via pytest-httpx)
  test_impact_scorer.py 13 tests (all scoring branches, no network)
  test_frl_watcher.py   +2 updated, reflecting Sprint 1 scoring behaviour
```

### How to verify

```bash
# All 48 tests
cd workers && python3 -m pytest tests/ -v
# → 48 passed in ~0.5s

# Live smoke test (requires env vars set)
export SUPABASE_URL=https://vlenxqrneowhirzmjxkn.supabase.co
export SUPABASE_SERVICE_ROLE_KEY=<your secret key>
python3 -c "
from kangavisa_workers.frl_watcher import run_frl_watch_and_persist
result = run_frl_watch_and_persist(
    url='https://www.legislation.gov.au/Details/C2024C00075',
    source_id='frl_migration_act_1958',
    source_type='FRL_ACT',
    canonical_url='https://www.legislation.gov.au/Details/C2024C00075',
)
print(result)
"
# Expected: {source_doc_id: <UUID>, change_event_id: <UUID>, impact_score: int, ...}
# Verify rows in: Supabase → Table Editor → source_document, change_event
```

### Key decisions
- Workers use `httpx` directly against Supabase REST API — no Python Supabase SDK dependency
- `pyproject.toml` build backend changed from `setuptools.backends.legacy` → `setuptools.build_meta` (Python 3.9 compatibility); `requires-python` relaxed to `>=3.9` locally (CI still validates on 3.12)
- `run_frl_watch_and_persist()` uses a deferred import of `db` and `impact_scorer` so all pure functions remain testable without env vars

---

*Next sprint walkthrough will be added here when Sprint 2 completes.*
