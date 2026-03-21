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

---

## Sprint 2 — KB Content Seed + Runtime Retrieval + Safety Lint
**Completed:** 2026-03-01  
**Commits:** `31a4071`, `03f7602`, `f2c1f04` on `main`

### User stories delivered

| Story | Description | Status |
|---|---|---|
| US-F6 | Structured-first retrieval — requirements, evidence, flags | ✅ |
| US-C3 | Safety lint — forbidden phrases + fraud/evasion refusal | ✅ |
| FR-K1 | Requirement objects for all 5 visa groups | ✅ |
| FR-K2 | Evidence items for all 5 visa groups | ✅ |
| FR-K3 | Flag templates for visa 500 | ✅ |
| FR-K5 | Citation enforcement + staleness warnings | ✅ |

### What was built

#### KB Seed (`kb/seed/`)

| File | Visa | Content |
|---|---|---|
| `visa_500_requirements_extra.json` | 500 | Financial, health, character requirements |
| `visa_500_flags.json` | 500 | 3 flag templates (GS-TIES, COURSE-MISMATCH, ENG-SCORE-LOW) |
| `visa_485_requirements.json` + `evidence_items.json` | 485 | GTE, qualification 6-month rule, English |
| `visa_482_requirements.json` + `evidence_items.json` | 482 SID | Nomination (TSMIT), sponsorship (SAF levy), occupation (ANZSCO list) |
| `visa_417_requirements.json` + `evidence_items.json` | 417 | Genuine intention, specified work (88/179 days), financial |
| `visa_820_requirements.json` + `evidence_items.json` | 820/309 | Relationship (4 pillars), sponsor, health, character |

All seed objects carry `effective_from`, `legal_basis` (Tier 0/1), and `rule_logic`.
**Totals:** 15 requirements · 20 evidence items · 3 flag templates

#### `workers/kangavisa_workers/seed_loader.py`
Idempotent upsert: `visa_subclass → requirement → evidence_item → flag_template`. Supports `--dry-run`.

#### `app/lib/kb-service.ts`
TypeScript retrieval service with architecture.md §4.2 effective-date selection.
`getRequirements()` · `getEvidenceItems()` · `getFlagTemplates()` · `getKBPackage()`

#### `app/lib/safety-lint.ts`
- **Forbidden phrases:** 15 patterns (no determinative/guarantee language)
- **Fraud/evasion:** 13 patterns → returns `FRAUD_REFUSAL_TEXT` (S-01, S-02)
- **Citation enforcement:** criteria statements must have non-empty citation

#### `app/lib/staleness-checker.ts`
FRL = 14 days · Home Affairs / data.gov.au = 30 days → `StalenessWarning[]` for UI banners.

### Tests
```
Python (pytest):   62 / 62  (+14 test_seed_loader.py)
Jest (TypeScript): 19 / 19  (__tests__/safety-lint.test.ts)
tsc --noEmit:       0 errors
```

### How to verify
```bash
cd workers && python3 -m pytest tests/ -v            # 62 passed
cd app    && npx tsc --noEmit                        # 0 errors
cd app    && npm test                                # 19 passed

# Dry-run seed loader (no Supabase needed)
cd workers && python3 -m kangavisa_workers.seed_loader --dry-run
```

### Key decisions
- **`_extra` suffix** for supplementary visa 500 requirements — preserves existing seed files already validated by schema tests
- **`__tests__/` excluded from tsconfig** — ts-jest handles typing at Jest runtime; avoids Next.js tsconfig conflicts with Jest globals
- **`kb-service.ts` is server-only** — service role key; never import in Client Components
- **`staleness-checker.ts` is pure** — no DB calls; takes `SourceDocumentStub[]` for easy unit testing

---

*Next sprint walkthrough will be added here when Sprint 3 completes.*

---

## Sprint 3 — Next.js UI: Design System + Core Screens + Auth
**Completed:** 2026-03-01  
**Commits:** `d90f749`, `c7154d1`, `d86d14f` on `main`

### User stories delivered

| Story | Description | Status |
|---|---|---|
| US-A1 | Pathway Finder — 5 visa group cards | ✅ |
| US-A2 | Checklist driven by getKBPackage() | ✅ |
| US-B1 | Evidence Checklist + ReadinessScorecard | ✅ |
| US-B2 | Evidence items with citations and common gaps | ✅ |
| US-C1 | Flag Cards with brand §9.2 structure | ✅ |
| US-C3 | Safety lint applied (server-side, Sprint 2) | ✅ |
| US-E1 | consent_state row created on sign-up | ✅ |

### What was built

#### Design system (`app/globals.css`)
Full CSS token layer:
- Colours: `--color-navy` / `--color-gold` / `--color-teal` + semantic status + neutrals
- Typography: Inter (body) + JetBrains Mono (data fields) via Google Fonts
- 8pt spacing grid (`--sp-1` → `--sp-24`), border radii, shadows, transitions
- Utility classes: `.h1–h3`, `.body`, `.caption`, `.mono`, `.container`, `.card`, `.btn`, `.badge`, `.alert`, `.next-actions`, `.form-input`

#### Components (`app/app/components/`)
| Component | Purpose |
|---|---|
| `AppHeader.tsx` | Sticky navy nav, gold KV logo mark, auth CTAs |
| `Disclaimer.tsx` | Mandatory MARA disclaimer (brand §3) — onboarding + flags |
| `StalenessAlert.tsx` | Dismissible amber banner for stale sources |
| `FlagCard.tsx` | Brand §9.2 — severity badge (icon + text, WCAG), numbered actions |
| `ReadinessScorecard.tsx` | Coverage %, items, open flags; no approval language (§9.1) |

#### Pages
| Route | Type | Description |
|---|---|---|
| `/` | Server | Hero (navy gradient, gold CTA) + 4 value pillar cards |
| `/pathway` | Server | 5 visa cards, complexity badges, assumptions block, next actions |
| `/checklist/[subclass]` | Server | Calls `getKBPackage()`, accordion per requirement, evidence items with citations |
| `/flags/[subclass]` | Server | Calls `getFlagTemplates()`, `FlagCard` grid, empty state, disclaimer |
| `/auth/signup` | Client | Supabase sign-up + consent toggles (both default off) |
| `/auth/login` | Client | Supabase sign-in → redirect `/pathway` |
| `POST /api/auth/create-consent` | API route | Upserts `consent_state` row (service role) |

#### Fixes
- `lib/supabase.ts`: exported `createClient()` factory for auth Client Components
- `flags/[subclass]/page.tsx`: explicit `FlagTemplate[]` type — fixed TS7034

### Tests
```
tsc --noEmit:      0 errors
Jest:             19 / 19 (no regressions)
Dev server:       HTTP 200 on /, /pathway, /auth/login
Compile:          551 modules — no warnings
```

### Key decisions
- **All page routes are Server Components** — data fetching at render time, no client-side waterfalls
- **Checklist gracefully handles missing KB data** — shows a contextual error alert if Supabase is unreachable, rather than crashing
- **Consent toggles default OFF** — both product analytics and GovData research start unchecked (brand §10 dark-pattern ban)
- **Severity badges always icon + text** — never colour-alone (WCAG 2.1 AA, brand §9.2)
- **ReadinessScorecard has explicit non-prediction notice** — "does not indicate approval likelihood" hardcoded in component (brand §9.1)

---

*Next sprint walkthrough will be added here when Sprint 4 completes.*

---

## Sprint 4 — Checklist Persistence + LLM + Export + Analytics + Golden Tests
**Completed:** 2026-03-01  
**Commits:** `4af2ec4`, `853945a`, `ececa81`, `fda2029`, `835dee1` on `main`

### User stories delivered

| Story | Description | Status |
|---|---|---|
| US-B3 | Checklist state persistence (case_session + checklist_item_state) | ✅ |
| US-B4 | Session resume — GET existing session on checklist load | ✅ |
| US-D1 | CSV export download with evidence items + status | ✅ |
| US-D2 | Export Summary screen (brand §9.5 — coverage, flags, assumptions, pack version) | ✅ |
| US-E2 | Analytics events gated on consent_state.product_analytics_enabled | ✅ |
| US-F1 | LLM integration — KB-grounded streaming answers | ✅ |
| FR-K5 | Golden test runner validates safety lint against testcases.md prompts | ✅ |
| FR-K6 | All LLM answers grounded in structured KB (getKBPackage system prompt) | ✅ |

### What was built

#### Checklist State Persistence
| File | Description |
|---|---|
| `app/api/sessions/route.ts` | GET/POST `case_session` — get-or-create per user+visa+caseDate |
| `app/api/sessions/[sessionId]/items/route.ts` | GET all items, PATCH single item status+note |
| `app/components/ChecklistItem.tsx` | Cycles `not_started→in_progress→done→na`, optimistic update |

#### LLM Integration
| File | Description |
|---|---|
| `lib/llm-service.ts` | `buildSystemPrompt()` (KB-grounded), `askLLM()`, `askLLMStream()` |
| `app/api/ask/route.ts` | SSE streaming — pre-input fraud check, tokens, post-stream lint |
| `app/components/AskBar.tsx` | SSE consumer, blinking cursor, refusal/violation banners, citation chips |

#### Analytics
| File | Description |
|---|---|
| `lib/analytics.ts` | Fire-and-forget `track()` — never throws |
| `app/api/analytics/route.ts` | Consent-gated insert into `analytics_event` |

Events fired: `CHECKLIST_VIEWED` · `ITEM_STATUS_CHANGED` · `PACK_EXPORTED` · `ASK_SUBMITTED`

#### Export Pack
| File | Description |
|---|---|
| `lib/export-builder.ts` | `buildExportPayload()` (brand §9.5), `buildCsv()` (RFC-compliant) |
| `app/api/export/csv/route.ts` | Loads KB + saved states, returns CSV file download |
| `app/export/[subclass]/page.tsx` | Export Summary — pack version, coverage bar, top 5 flags, download buttons |

#### Safety & Tests
| File | Description |
|---|---|
| `lib/__tests__/golden-tests.test.ts` | 9 golden tests: S-01, S-02, forbidden phrases, structural checks |
| `lib/safety-lint.ts` | Extended `FRAUD_PATTERNS`: `forge my/the`, `employment gaps`, `falsify`, `cover up` |
| `.env.local` | Fixed `OPENAI_API_KEY` prefix error (removed literal `YOUR_OPENAI_API_KEY`) |

### Tests
```
tsc --noEmit:   0 errors
Jest:          28 / 28 (19 safety-lint + 9 golden — no regressions)
Dev server:    HTTP 200 on all Sprint 3 routes confirmed before commit
```

### Key decisions
- **LLM is purely server-side** — API key never on client, SSE readable stream via Next.js Route Handler
- **Fraud check runs BEFORE LLM is called** — no wasted tokens on blocked requests
- **ChecklistItem works unauthenticated** — sessionId=null → UI-only mode, no API calls
- **Analytics is fire-and-forget** — `track()` never throws, analytics must never break UX
- **Coverage % excludes N/A items** — only meaningful "applicable items" counted in denominator

---

*Next sprint walkthrough will be added here when Sprint 5 completes.*

---

## Sprint 5 — Checklist Wiring + Dashboard + PDF + Auth Reset + Timeline
**Completed:** 2026-03-01  
**Commits:** Auto-saved across 6 commits on `main` (latest: `2a2c607`)

### User stories delivered

| Story | Description | Status |
|---|---|---|
| US-B3 | Checklist wiring — ChecklistBodyStandalone loads session + persists state | ✅ |
| US-B4 | Session resume — ChecklistController loads existing session on mount | ✅ |
| US-B5 | Timeline view — effective-date vertical timeline for all KiB requirements | ✅ |
| US-D1 | PDF export — react-pdf Document rendered server-side | ✅ |
| US-E3 | Password reset — reset-request + reset-confirm auth pages | ✅ |
| US-G1 | User dashboard — session list, coverage bars, Resume + Export buttons | ✅ |

### What was built

#### Checklist Wiring (US-B3, US-B4)
| File | Description |
|---|---|
| `lib/supabase-server.ts` | Cookie-based server Supabase client via `@supabase/ssr` |
| `app/components/ChecklistController.tsx` | Sidebar Client Component — loads/creates session, fires analytics, updates ReadinessScorecard live |
| `app/components/ChecklistBodyStandalone.tsx` | Main column Client Component — loads item states independently, renders `ChecklistItem` per row |
| `app/checklist/[subclass]/page.tsx` | Rewritten Server Component — passes KB data to client components, adds AskBar + Export + Timeline links |
| `app/components/ChecklistItem.tsx` | Added `onStatusChange` callback prop |

#### Dashboard (US-G1)
| File | Description |
|---|---|
| `app/dashboard/page.tsx` | Server Component — auth-guarded (redirect to login), sessions grid with coverage bars + Resume/Export |
| `app/dashboard/dashboard.module.css` | Session card grid CSS |

#### PDF Export (US-D1)
| File | Description |
|---|---|
| `app/components/ExportPDFDocument.tsx` | @react-pdf/renderer Document — brand §9.5 (header, assumptions, coverage bar, top flags, checklist, disclaimer) |
| `app/api/export/pdf/route.ts` | GET → `renderToBuffer()` → `application/pdf` download |
| `app/export/[subclass]/page.tsx` | Updated: PDF Download as primary button, CSV as secondary |

#### Password Reset (US-E3)
| File | Description |
|---|---|
| `app/auth/reset-request/page.tsx` | Email form → `resetPasswordForEmail()` + confirmation |
| `app/auth/reset-confirm/page.tsx` | PASSWORD_RECOVERY event listener → `updateUser({ password })` → redirect to /dashboard |
| `app/auth/login/page.tsx` | Added "Forgot password?" link |

#### Timeline View (US-B5)
| File | Description |
|---|---|
| `app/timeline/[subclass]/page.tsx` | Vertical timeline from full requirement history, grouped by year, active/expired/future states |
| `app/timeline/[subclass]/timeline.module.css` | Dot-track timeline CSS |

### Tests
```
tsc --noEmit:   0 errors
Jest:          28 / 28 (no regressions)
```

### Key decisions
- **Split sidebar/body into separate Client Components** — `ChecklistController` (sidebar, scorecard) and `ChecklistBodyStandalone` (main column, item list) each load session state independently. This avoids prop-drilling session data across Server/Client boundary.
- **`@supabase/ssr` for dashboard auth** — cookie-based `getUser()` in Server Components is more reliable than JWT decode. Redirects immediately on unauthenticated access.
- **`@ts-nocheck` on ExportPDFDocument** — `@react-pdf/renderer` uses a custom JSX factory incompatible with Next.js tsconfig. File is server-only and verified at runtime.
- **PDF route `runtime = "nodejs"`** — required for `renderToBuffer()` (edge runtime doesn't support canvas).
- **Timeline loads ALL requirement history** — passes `new Date("2000-01-01")` to `getRequirements()` to bypass the effective-date filter, showing the full arc of requirement changes.

---

*Next sprint walkthrough will be added here when Sprint 6 completes.*

---

## Sprint 6 — KB Seed + Auth-Aware AppHeader + Staleness Alert
**Completed:** 2026-03-01  
**Commits:** `d4969ac`, `931aafd`, `de38ad9` on `main`

### User stories delivered

| Story | Description | Status |
|---|---|---|
| US-F6 | KB seed migration — all 5 visa subclasses seeded from kb/seed/ JSON | ✅ |
| US-G1 | Auth-aware AppHeader — Dashboard nav + user pill + Sign out | ✅ |
| US-B5 | KB staleness alert — amber banner when data > 30 days old | ✅ |

### What was built

#### KB Seed (US-F6)
| File | Description |
|---|---|
| `scripts/generate_seed_sql.py` | Python generator — reads all `kb/seed/*.json`, emits idempotent `INSERT` SQL using deterministic UUID5 |
| `migrations/seed_kb_v1.sql` | Output — paste into Supabase SQL Editor to seed 5 subclasses (500, 485, 482, 417, 820) |

**Seed output:**
| Item | Count |
|---|---|
| Visa subclasses | 5 |
| Requirements | 18 |
| Evidence items | 19 |
| Flag templates | 3 |

**To unlock full demo:**
```bash
# Regenerate at any time:
python3 scripts/generate_seed_sql.py

# Then paste migrations/seed_kb_v1.sql into Supabase SQL Editor → Run
```

#### Auth-Aware AppHeader (US-G1)
| File | Description |
|---|---|
| `app/components/AppHeader.tsx` | Async Server Component — `getServerUser()` on every render. Authenticated: Dashboard nav link, teal avatar pill, Sign out. Unauthenticated: Sign in / Get started. |
| `app/components/AppHeader.module.css` | User pill, avatar, and email styles |
| `app/auth/signout/route.ts` | GET/POST handler — `supabase.auth.signOut()` → redirect `/` |

#### KB Staleness Alert (US-B5)
| File | Description |
|---|---|
| `app/components/KBStalenessAlert.tsx` | Dismissible amber banner — shows when `last_reviewed_at` > 30 days ago |
| `app/components/KBStalenessAlert.module.css` | Alert banner styles |

### Tests
```
tsc --noEmit:   0 errors
Jest:          28 / 28 (no regressions)
```

### Key decisions
- **Deterministic UUID5 in seed script** — using `uuid.uuid5(ns, "requirement:REQ-500-GS-001")` means every re-run produces the same UUIDs. Combined with `ON CONFLICT DO NOTHING`, the migration is safe to run multiple times without duplication.
- **AppHeader reads auth server-side** — `getServerUser()` uses the Supabase SSR cookie client, which means no client-side JS needed for the header auth state. No flash of unauthenticated content.
- **KBStalenessAlert receives props from Server Component** — the Server Component page passes `lastReviewedAt` as a prop; the client component only decides whether to show/dismiss the banner. This avoids any extra API calls from the browser.

---

*Next sprint walkthrough will be added here when Sprint 7 completes.*

---

## Sprint 7 — LLM AskBar Activation + Mobile Nav + Onboarding + DaaS Consent
**Completed:** 2026-03-01  
**Commits:** `55330f4` → `c43f294` on `main`

### User stories delivered

| Story | Description | Status |
|---|---|---|
| US-F1 | LLM AskBar — activated with empty-KB guard + model badge + prompt chips | ✅ |
| US-A2 | Mobile hamburger nav — slide-out drawer with auth state | ✅ |
| US-E1 | Onboarding welcome modal — 4-slide, localStorage-guarded | ✅ |
| US-C1 | DaaS consent banner — amber prompt with opt-in/decline flow | ✅ |

### What was built

#### LLM AskBar (US-F1)
| File | Change |
|---|---|
| `lib/llm-service.ts` | Empty-KB guard: returns friendly "not yet seeded" message via async generator without calling OpenAI. Exposes `model` + `kbEmpty` in result. |
| `app/api/ask/route.ts` | SSE `done` event now includes `model` and `kbEmpty` fields. |
| `app/components/AskBar.tsx` | Prompt chips (3 per subclass), model badge footer (`GPT-4o mini · KB-grounded`), model state from SSE. |
| `app/components/AskBar.module.css` | `.chips`, `.chip`, `.model_badge`, `.model_chip` styles. |

**Prompt chips per subclass:**
- 500 (Student): genuine intent docs, evidence gaps, English test validity
- 485 (Grad): lodgement docs, qualification proof, timing risks
- 482 (Employer): nomination evidence, salary threshold, work history
- 417 (WHM): specified work docs, financial capacity, regional evidence
- 820 (Partner): four pillars, financial evidence, processing timeline

#### Mobile Nav (US-A2)
| File | Description |
|---|---|
| `app/components/MobileNav.tsx` | Slide-out drawer — Escape key, backdrop dismiss, scroll lock, focus management |
| `app/components/MobileNav.module.css` | `slideIn` + `fadeIn` CSS animations, nav link hover with gold left-border |
| `app/components/AppHeaderClient.tsx` | Thin client island managing open/close state — keeps AppHeader as Server Component |
| `app/components/AppHeader.tsx` | Integrates `AppHeaderClient` island |
| `app/components/AppHeader.module.css` | Hamburger styles; `<768px` shows hamburger, hides desktop nav |

#### Onboarding Modal (US-E1)
| File | Description |
|---|---|
| `app/components/OnboardingModal.tsx` | 4-slide welcome from `narrative_scaffolding_pack.md §2`. localStorage-guarded (`kv_onboarded`). Progress dots, Back/Next/Skip. |
| `app/components/OnboardingModal.module.css` | Spring slide-up + fade-in animation |

**Slides:** (1) Two speeds of the system → (2) Documentary vs satisfaction criteria → (3) Policy changes + staleness warnings → (4) Evidence quality is the #1 avoidable risk

#### DaaS Consent Banner (US-C1)
| File | Description |
|---|---|
| `app/components/DaaSConsentBanner.tsx` | Amber prompt → calls `POST /api/auth/create-consent` on opt-in. Decline stores in localStorage. Animated success/decline states. |
| `app/components/DaaSConsentBanner.module.css` | Banner + success/muted variants |
| `app/dashboard/page.tsx` | Renders both `OnboardingModal` + `DaaSConsentBanner` at top of dashboard |

### Tests
```
tsc --noEmit:   0 errors
Jest:          28 / 28 (no regressions)
```

### Key decisions
- **Client island pattern for hamburger** — `AppHeaderClient` is a narrow client island that owns only drawer state. The outer `AppHeader` stays a Server Component, meaning auth state is read server-side with zero JS on the main thread.
- **Empty-KB guard uses async generator** — avoids calling OpenAI (and spending API credits) when no requirements exist for a subclass. Returns the same SSE shape as a real stream, so no changes needed in the route handler.
- **Prompt chips disappear on first send** — once a query is submitted, chips hide to give full width to the answer area. They reappear on component remount (new page visit).
- **Icon pack** — user provided brand icon pack (K + kangaroo + gold arrow). Actual PNG/SVG/ICO files to be placed in `app/public/` by user; `layout.tsx` will be updated once files are available.

---

*Next sprint walkthrough will be added here when Sprint 8 completes.*

---

## Sprint 8 — Pathway Finder Quiz + Brand Icons + Landing Page Copy
**Completed:** 2026-03-01  
**Commits:** `9498f89` → `42e14cd` on `main`

### User stories delivered

| Story | Description | Status |
|---|---|---|
| US-A1 | PathwayQuiz — 3-step eligibility pre-filter on Pathway Finder | ✅ |
| US-SEO-1 | Per-page SEO metadata on checklist/flags/timeline — confirmed present | ✅ |
| US-Brand | Brand icons (actual logo asset) + landing page copy polish | ✅ |

### What was built

#### PathwayQuiz (US-A1)
| File | Description |
|---|---|
| `app/components/PathwayQuiz.tsx` | 3-step quiz: (1) 6 purpose tiles → subclass mapping, (2) onshore/offshore for partner visa only, (3) confirm + `router.push` to checklist |
| `app/components/PathwayQuiz.module.css` | 3→2→1 col tile grid, gold active border, teal hover, fade-slide step animation, gold-border confirm card |
| `app/pathway/page.tsx` | Quiz renders above existing visa cards. Cards wrapped in `#browse-all` anchor section. "I'm not sure" scrolls to Browse All. |

#### Brand icons
- `logo-mark.png`: transparent PNG extracted from actual brand asset via PIL
- `filter: saturate(1.6) brightness(1.2) drop-shadow(gold)` — logo pops on navy header
- `mix-blend-mode: multiply` removed (was darkening logo colours)
- `icon.png`, `apple-icon.png`, `icon-192/48/32/16.png` all generated from brand mark

#### Landing page copy
- Hero: "Australian visa application pack"
- Tiles: "Australian Government", "Nothing forgotten. Nothing guessed.", natural-language phrasing, no AI em-dashes
- Pillar sub: "structured Australian visa readiness plan"

### KB Seed (pending — manual step)

> [!IMPORTANT]
> Run `migrations/seed_kb_v1.sql` in Supabase SQL Editor to activate the LLM AskBar. This is the only remaining Sprint 8 item.

### Tests
```
tsc --noEmit:  0 errors
Jest:         28 / 28
```

---

## Sprint 9 — AskBar Bug Fix + DaaS Consent Wiring + Export Coverage
**Completed:** 2026-03-02
**Commits:** `56cb4e2`, `a8220e2`, `2722890` on `main`

### User stories delivered

| Story | Description | Status |
|---|---|---|
| US-F1 | AskBar live — KB-grounded answers with clause citations + model badge | ✅ |
| US-E1 | DaaS consent: real `hasConsent` + JWT `authToken` wired on dashboard | ✅ |
| US-D2 | Export coverage: `ReadinessScorecard` when authenticated; sign-in prompt when not | ✅ |

### What was built / fixed

#### Critical bug fix — `kb-service.ts`
`getRequirements()` and `getFlagTemplates()` were querying by `.eq("subclass_code", subclassCode)`.
Neither table has a `subclass_code` column — they join to `visa_subclass` via `visa_id` UUID FK.
Every query silently returned 0 rows. Fix:

| File | Change |
|---|---|
| `lib/kb-service.ts` | Added `resolveVisaId(subclassCode)` helper — looks up `visa_id` from `visa_subclass` table |
| `lib/kb-service.ts` | `getRequirements()` + `getFlagTemplates()` now call `resolveVisaId()` then filter by `.eq("visa_id", visaId)` |
| `lib/kb-service.ts` | `EvidenceItem` interface: removed dead `description` + `format_notes` fields; `what_it_proves` now matches the actual DB column |

#### DaaS consent wiring

| File | Change |
|---|---|
| `app/dashboard/page.tsx` | Queries `consent_state.govdata_research_enabled` for current user; passes real `authToken` from SSR session |
| `app/components/DaaSConsentBanner.tsx` | POST body fixed: `govdata_research_enabled: true` (was `consent_type: "daas_research"`) |
| `app/api/auth/create-consent/route.ts` | Extracts user from JWT `Authorization` header — no longer trusts `user_id` in POST body |

#### Export page coverage

| File | Change |
|---|---|
| `app/export/[subclass]/page.tsx` | Fetches most recent `case_session` + `checklist_item_state` for authenticated user; renders `<ReadinessScorecard>` with real done/total counts; shows sign-in prompt when unauthenticated (was hardcoded 0%) |

### Tests
```
tsc --noEmit:  0 errors
Jest:         28 / 28 (no regressions)
AskBar:       KB-grounded on /checklist/500 — 5 reqs loaded, clause 500.212 cited, gpt-4o-mini · KB-grounded badge
```

### Key decisions
- `resolveVisaId()` makes a separate Supabase call before the main query — acceptable overhead for a Server Component; could be cached with `unstable_cache` later
- `create-consent` route now validates identity from the JWT, not the request body — prevents a user spoofing another user's `user_id`
- Export page uses admin client (service role) to fetch session items — avoids RLS complexity on an already-server-side-only page

---

## Sprint 10 — Auth Email Templates
**Completed:** 2026-03-02
**Commits:** `ffa4c6e`, `81c197c`, `c1cc974` on `main`

### What was built

Three Supabase transactional email templates with KangaVisa branding. Source HTML committed to `app/email-templates/` for version control; deployed by pasting into the Supabase dashboard.

| File | Supabase template slot | Status |
|---|---|---|
| `app/email-templates/signup-confirm.html` | Confirm signup | ✅ |
| `app/email-templates/reset-password.html` | Reset password | ✅ |
| `app/email-templates/email-change.html` | Change email address | ✅ |
| `app/email-templates/README.md` | Deploy instructions + subject lines | ✅ |

**Design:**
- Navy `#0B1F3B` header with gold `#c9902a` "KV" badge + "KangaVisa" wordmark
- White card body, gold CTA button, teal inline link colour
- Security callout (amber left-border) on reset + email-change templates
- "Not legal advice" footer on all templates
- Email-client-safe: all inline styles, no external fonts (Arial/Helvetica fallback), no images

**Supabase variable used:** `{{ .ConfirmationURL }}` — Supabase injects the one-time action URL at send time.

### ⚠️ Action required
> Paste each HTML file into **Supabase → Authentication → Email Templates**.
> Full instructions + subject lines in `app/email-templates/README.md`.

### Tests
```
tsc --noEmit:  0 errors
Jest:         28 / 28 (no regressions)
Browser preview: both templates render correctly (navy header, gold CTA, footer)
```

---

## Sprint 11 — Dashboard Scorecard + PDF Route Fix + PWA Manifest
**Completed:** 2026-03-03  
**Commits:** `2a2c607` on `main`

### What was built

| Item | File | Detail |
|---|---|---|
| Dashboard readiness scorecard | `app/dashboard/page.tsx` | Imports `ReadinessScorecard`; fetches done/total counts + open flag count for most-recently-updated session; renders scorecard above sessions grid |
| Dashboard scorecard styles | `app/dashboard/dashboard.module.css` | `.scorecard_wrap` (bottom margin) |
| PDF export route fix | `app/api/export/pdf/route.ts` | Fixed broken `renderToBuffer` import (named import, not default) |
| PWA manifest | `app/manifest.ts` | `display: standalone`, `theme_color: #0B1F3B`, icon-192 + icon-512 + apple-icon |
| Root metadata | `app/layout.tsx` | Added `manifest`, `themeColor`, `appleWebApp` fields |

Scorecard shows evidence coverage %, items addressed, and open flags. Empty state unchanged. PDF route returns `200 application/pdf` with correct `Content-Disposition: attachment` header. Manifest served at `/manifest.webmanifest`.

### Tests
```
tsc --noEmit:  0 errors
Jest:         28 / 28
```

---

## Sprint 12 — CI Green + FRL Watcher Live + RLS Performance Fix
**Completed:** 2026-03-03  
**Commits:** `run #64` on GitHub Actions

### What was built

| Item | Detail |
|---|---|
| 7 ESLint errors fixed | `api/ask/route.ts`, `api/export/csv/route.ts`, `auth/reset-request/page.tsx`, `ChecklistController.tsx`, `ExportPDFDocument.tsx` |
| FRL watcher → Supabase live | `workers/.env` + `workers/run_frl_watch.py` — 3/3 FRL targets fetch + persist |
| Enum bug fix | `kb_change_type` value `initial_snapshot` → `new_instrument` in `frl_watcher.py` + `test_db.py` |
| RLS performance migration | `kb/migrations/rls_performance_fix.sql` — wraps all `auth.uid()` calls in scalar subqueries across `analytics_event`, `consent_event`, `consent_state`; drops duplicate policy |

```
CI:        run #64 ✅ (after 8 consecutive failures)
pytest:    62 / 62
Supabase:  0 performance issues
```

---

## Sprint 13 — DOCX Export + Weighted Scorecard + RLS Fix
**Completed:** 2026-03-04  
**Commits:** `a88699f` on `main` (CI run #65/#74 ✅)

### What was built

| Item | File | Detail |
|---|---|---|
| DOCX export | `app/lib/export-docx.ts` | `buildDocx()` using `docx` npm package — branded cover, requirements/flags/evidence tables, disclaimer |
| DOCX API route | `app/api/export/docx/route.ts` | `/api/export/docx` mirroring PDF pattern |
| DOCX button | `app/export/[subclass]/page.tsx` | Added between PDF and CSV |
| Enriched CSV | `app/lib/export-builder.ts` | `buildCsv()` now populates `label`, `what_it_proves`, `requirement` columns |
| Weighted scorecard | `app/lib/export-builder.ts` | `computeWeightedCoverage()` — priority 1→3pts, 2→2pts, ≥3→1pt |
| Weighted prop | `app/components/ReadinessScorecard.tsx` | Optional `weightedPct` renders "Priority-weighted" metric with tooltip |
| RLS v2 migration | `kb/migrations/rls_analytics_event_fix_v2.sql` | Drops duplicate `analytics_event_insert_if_enabled` policy; Supabase Advisor: 0 issues |

### Tests
```
tsc --noEmit:  0 errors
Jest:         28 / 28
CI:           run #74 ✅
```

---

## Sprint 14 — MVP 5-Pathway Strategy + Subclass 600 Seed + Rules Engine + Case Schema
**Completed:** 2026-03-09  
**Commits:** `e163651` on `main`

### What was built

#### MVP Pathway strategy
Locked in the 5 visa pathways covering ~80–90% of real usage: **600** (Visitor) · **500** (Student) · **485** (Temp Graduate) · **189/190/491** (Skilled) · **820/801** (Partner)

#### Subclass 600 seed
| File | Content |
|---|---|
| `kb/seed/visa_600_requirements.json` | 5 requirements (600.211, financial, identity, travel plan, host) |
| `kb/seed/visa_600_evidence_items.json` | 7 evidence items |
| `kb/seed/visa_600_flags.json` | 6 flags with legal citations |

#### Rules Engine Triad
| File | Content |
|---|---|
| `kb/seed/flag_templates.json` | 22 cross-visa reusable flags across 7 refusal categories |
| `kb/seed/subclass_flag_mapping.json` | Priority + secondary categories per subclass (7 subclasses) |
| `kb/rules/flag_detection_rules.json` | 32 deterministic rules (R001–R032) |
| `kb/rules/readiness_scoring_model.json` | 4-component weighted score + bands + safety rules |

**Scoring formula:** `(evidence_coverage × 0.35) + (timeline_completeness × 0.20) + (consistency × 0.20) + (risk_flags × 0.25)`

#### Case Schema
| File | Content |
|---|---|
| `kb/schema/case_schema.json` | Canonical case object (6 entities) |
| `kb/migrations/case_schema_v1.sql` | 6 new tables + RLS policies (cases, documents, timeline_events, flag_events, case_scores, case_exports) |

---

## Sprint 15 — Case Schema Applied + Readiness Score + New Visa Seeds
**Completed:** 2026-03-09  
**Commits:** `e163651` on `main`

### What was built

| Item | Status |
|---|---|
| `case_schema_v1.sql` applied to Supabase | ✅ |
| `computeReadinessScore()` — 4-component formula in `export-builder.ts` | ✅ |
| `ReadinessScorecard.tsx` — displays readiness score band | ✅ |
| `kb/seed/visa_820_flags.json` — 5 flags for Partner Visa (820) | ✅ |
| `kb/seed/visa_485_flags.json` — 5 flags for Temporary Graduate (485) | ✅ |
| `kb/seed/visa_190_491_seed.json` — delta seed for 190/491 | ✅ |
| `PathwayQuiz.tsx` — Visitor (600) and Skilled Independent (189) tiles added | ✅ |
| `VISA_NAMES` map updated across all 8 files (600, 189, 190, 491) | ✅ |

---

## Sprint 16 — MVP Visa Seed SQL + AskBar Chips + Export Wiring
**Completed:** 2026-03-09  
**Commits:** on `main`

### What was built

| Item | Detail |
|---|---|
| `kb/migrations/seed_mvp_visas_v1.sql` | Idempotent seed for 485, 189, 190, 491, 820 via `ON CONFLICT DO NOTHING` |
| AskBar chips | Added 600 (3), 189 (3), 190 (3), 491 (3) prompt chips |
| Export page | `computeReadinessScore()` wired; `ReadinessScorecard` receives `readinessScore` |

```
tsc --noEmit:  0 errors
Seed applied: 189→6 reqs, 190→1, 485→3, 491→2, 820→4
```

---

## Sprint 17 — Unique Constraint + Visitor 600 Full Seed + KB Staleness
**Completed:** 2026-03-14  
**Commits:** `b3c2d5f` on `main`

### What was built

| Item | File | Detail |
|---|---|---|
| Unique constraint | `kb/migrations/requirement_unique_title_v1.sql` | `CREATE UNIQUE INDEX requirement_visa_title_uk ON requirement (visa_id, title)` — prevents seed re-run duplicates |
| Visitor 600 SQL seed | `kb/migrations/seed_visitor_600_v1.sql` | 5 requirements · 8 evidence items · 6 flag templates · 1 `kb_release` row |
| KB staleness banner | Already built — `kb_release` row inserted by 600 seed resets the 30-day clock | ✅ |

```
tsc --noEmit:  0 errors
Supabase:     requirement_unique_title_v1 ✅ · seed_visitor_600_v1 ✅
```

---

## Sprint 18 — Watcher Bug Fixes + Home Affairs + data.gov.au Tests
**Completed:** 2026-03-14  
**Commits:** `8e72227` on `main`

### What was built

#### Bug fixes
| File | Fix |
|---|---|
| `homeaffairs_watcher.py` | `"initial_snapshot"` → `"new_instrument"` enum |
| `datagov_watcher.py` | Same enum fix + first-run uses `"new_instrument"`, changes use `"dataset_update"` |
| `seed_loader.py` `load_flag_templates` | Handles both flat-list and `{"flags": [...]}` JSON formats |
| `seed_loader.py` `_seed_files_matching` | Skips SQL-seeded visa files (600, 189, 190, 491) |

#### New tests
| File | Tests |
|---|---|
| `tests/test_homeaffairs_watcher.py` | 8 tests |
| `tests/test_datagov_watcher.py` | 7 tests |

```
pytest (--ignore=tests/test_db.py):  73 passed · 0 failed
tsc --noEmit:                        0 errors
```

---

## Sprint 19 — test_db.py Isolation Fix + Partner 820 SQL Migration
**Completed:** 2026-03-14  
**Commits:** `947728c` on `main`

### What was built

#### `test_db.py` isolation
Root cause: `test_seed_loader.py` set `SUPABASE_URL` at module scope before `db.py` was imported → pytest-httpx teardown conflict. Fix: `workers/tests/conftest.py` — `autouse` fixture refreshes `db.SUPABASE_URL` / `db.SERVICE_ROLE_KEY` from `os.environ` before each test.

```
Full suite: 79 passed · 0 failed
```

#### Partner 820 SQL migration
`kb/migrations/seed_partner_820_v1.sql`:
- 4 requirements: Genuine Relationship, Eligible Sponsor, Health, Character
- 5 evidence items (joint bank statements, shared lease, photos, statutory declarations, sponsor citizenship)
- 5 flag templates
- `kb_release` tag: `kb-v20260314-partner-820`

```
Applied ✅ — 4 requirements · 11 evidence items · 8 flag templates
```

---

## Sprint 20 — E2E Browser Tests + Partner 309 Offshore Visa
**Completed:** 2026-03-14  
**Commits:** `1740f43` on `main`

### What was built

#### E2E browser tests (all PASS)
| Page | Result |
|---|---|
| `/` Home | ✅ |
| `/checklist/189` | ✅ 6 requirements, readiness 0% |
| `/checklist/600` | ✅ 5 requirements |
| `/checklist/820` | ✅ 4 requirements, 11 evidence items, 8 flags |

#### Partner 309 (offshore) migration
`kb/migrations/seed_partner_309_v1.sql`:
- 4 requirements · 6 evidence items (includes offshore-specific: ongoing contact records, boarding passes) · 5 flag templates (includes offshore ongoing contact, police clearance expiry, medical timing)
- 309 prompt chips added to `AskBar.tsx`

```
Applied ✅: 4 requirements · 6 evidence items · 5 flag templates
tsc: 0 errors | tests: 79 passed
```

---

## Sprint 21 — E2E Export Tests + Working Holiday 417 Migration
**Completed:** 2026-03-14  
**Commits:** `98aef79` on `main`

### What was built

#### E2E browser tests
| Page | Result |
|---|---|
| `/export/189` | ✅ PDF, DOCX, CSV buttons present |
| `/export/820` | ✅ 4 requirements + 11 evidence items |
| `/checklist/600` — AskBar | ✅ 3 prompt chips, KB-grounded response |
| `/flags/820` | ✅ 8 flags active |

#### Working Holiday 417 migration
`kb/migrations/seed_working_holiday_417_v1.sql`:
- 3 requirements · 4 evidence items · 4 flag templates (work days short, regional area ineligible, cash-in-hand, financial threshold)

```
Applied ✅: 3 requirements · 8 evidence items · 4 flag templates
tsc: 0 errors | tests: 79 passed
```

---

## Sprint 22 — Employer Sponsored 482 + Temporary Graduate 485 Migrations
**Completed:** 2026-03-14  
**Commits:** `805fbcb`, `5c787e5`, `b3a2674` on `main`

### What was built

#### 482 Employer Sponsored
`kb/migrations/seed_employer_sponsored_482_v1.sql`:
- 3 requirements: Approved Nomination, Standard Business Sponsor, Occupation on Eligible List
- 4 evidence items + 4 flag templates (TSMIT salary, occupation not on list, SAF levy, employment conditions)

#### 485 Temporary Graduate
`kb/migrations/seed_temporary_graduate_485_v1.sql`:
- 3 requirements: Genuine Temporary Entrant, Australian Qualification (6-month window), English
- 4 evidence items + 5 flag templates (lodgement window, stream mismatch, police check, English expired, health exam)

**AskBar chips** added for 482 (TSMIT focus) and 485 (stream/timing focus).

```
Applied 482 ✅: 3 requirements · 4 evidence items · 4 flag templates
Applied 485 ✅: 3 requirements · 8 evidence items · 9 flag templates
tsc: 0 errors | tests: 79 passed
```

---

## Sprint 23 — Student 500 SQL Migration
**Completed:** 2026-03-14  
**Commits:** `37a0935` on `main`

### What was built

`kb/migrations/seed_student_500_v1.sql`:
- 5 requirements: Genuine Student (balance-of-factors), English (LIN 19/051), Financial (LIN 18/036), Health (PIC 4005), Character (s.501)
- 2 evidence items · 3 flag templates (weak home ties, course inconsistent, English score below threshold)

```
Applied ✅: 5 requirements · 4 evidence items · 6 flag templates
tsc: 0 errors
```

---

## Sprint 24 — Skilled 189/190/491 SQL Migrations + KB Coverage Audit
**Completed:** 2026-03-14  
**Commits:** `3506c0c` on `main`

### What was built

#### Skilled Independent 189
- 6 requirements: Valid ITA, Positive Skills Assessment, Min Points (65+), English, Health (PIC 4005), Character (s.501)
- 7 evidence items + 4 flag templates (points miscalculation, skills expired, employment gaps, English expired)

#### Skilled Nominated 190
- 1 additional requirement (State/Territory Nomination) +1 evidence +2 flags

#### Skilled Work Regional 491
- 2 additional requirements (Nomination/Sponsorship, Regional Living Commitment) +1 evidence +3 flags

#### KB Coverage (all 10 subclasses seeded) ✅

| Visa | Reqs | Evidence | Flags | Applied |
|---|---|---|---|---|
| 600 Visitor | SQL-seeded | | | ✅ |
| 189 Skilled Ind. | 6 | 7 | 4 | ✅ |
| 190 Skilled Nom. | 1* | 1* | 6* | ✅ |
| 491 Skilled Reg. | 3* | 1* | 9* | ✅ |
| 820 Partner | 4 | 11 | 8 | ✅ |
| 309 Partner offshore | 4 | 6 | 5 | ✅ |
| 417 Working Holiday | 3 | 8 | 4 | ✅ |
| 482 Employer Sponsored | 3 | 4 | 4 | ✅ |
| 485 Temp Graduate | 3 | 8 | 9 | ✅ |
| 500 Student | 5 | 4 | 6 | ✅ |

*Counts include pre-existing rows from `seed_mvp_visas_v1`.

---

## Sprint 25 — Production Launch on kanga-visa.com 🚀
**Completed:** 2026-03-15

### What was shipped

| Item | Detail |
|---|---|
| Domain registered | `kanga-visa.com` |
| Vercel project | Connected to `main` branch; Framework Preset → Next.js; Root Directory → `app` |
| Env vars on Vercel | `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `OPENAI_API_KEY` |
| Site live | `https://kanga-visa.com` ✅ |
| 189 seed applied | `seed_skilled_independent_189_v1.sql` — 6 requirements ✅ |
| 190/491 seed applied | `seed_skilled_nominated_190_491_v1.sql` ✅ |
| **Full KB live** | All 10 visa subclasses seeded in production ✅ |

---

## Sprint 26 — CI KB Watcher Fixed + Sprint 27 Architecture Designed
**Completed:** 2026-03-16  
**Commits:** `765c036` on `main`

### What was built

#### CI KB Watcher fixed
Root cause: GitHub Actions secrets `SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY` were never added → `EnvironmentError` on every run, caught silently, all 13 targets failed.

| Fix | Detail |
|---|---|
| `workers/run_watchers.py` | Pre-flight secrets check at startup — exits with clear message pointing to GitHub Settings |
| `workers/run_watchers.py` | `EnvironmentError` → `fatal=True`; network/HTTP → `fatal=False` (no CI spam) |
| `workers/run_watchers.py` | `sys.exit(1)` only on fatal errors or 100% failure rate |

```
pytest:  73 passed · 0 failed | tsc: 0 errors
```

#### Sprint 27 UX Architecture designed
- Three evidence panel types: Narrative (AI-assessed), Documentary (rule-based), Quantitative (deterministic)
- Quality-weighted scoring: Not started 0% → Draft 30% → Adequate 70% → Strong 100%
- Phase 1: zero schema changes (uses existing `note` column)
- Phase 2: `assessment_json`, `assessed_at` columns on `checklist_item_state`

---

## Sprint 27 — Evidence Drafting Accordion + AI Assessment + Auth Session Fix
**Completed:** 2026-03-20  
**Commits:** `987b852` (P1) · `84cbf63` (P2) · `54d84c6` · `5ca906b` · `211fd24` · `3e83de9` · `58179bc` on `main`

### What was built

#### P1 — Evidence Drafting Accordion (no schema change)
| File | Change |
|---|---|
| `app/components/ChecklistItem.tsx` | Clickable label → accordion; `<textarea>` wired to `note`; auto-saves on blur; auto-advances `not_started → in_progress`; chevron indicator |
| `app/components/ChecklistItem.module.css` | `label_btn`, `chevron`, `accordion` (max-height transition), `draft_textarea`, `draft_footer`, `char_count`, `assess_btn` |
| `app/components/ChecklistBodyStandalone.tsx` | Loads `note` from GET items; passes `initialNote` + `onNoteChange` |
| `app/lib/export-builder.ts` | `computeReadinessScore()`: `in_progress` items with non-empty note → 0.3× draft credit |

#### P2 — AI Assessment Endpoint
| File | Change |
|---|---|
| `kb/migrations/checklist_item_assessment_v1.sql` | `ALTER TABLE checklist_item_state ADD COLUMN draft_content, assessment_json, assessed_at` |
| `app/api/sessions/[sessionId]/items/[evidenceId]/assess/route.ts` | `POST` — GPT-4o-mini structured assessment (Weak/Adequate/Strong + gaps list) |
| `app/components/AssessmentBadge.tsx` + `.module.css` | Rating badge + summary + gap bullets rendered inline |
| `app/components/ChecklistItem.tsx` | `[Assess my draft →]` button at ≥20 chars; calls assess; renders `<AssessmentBadge>` |

#### Auth session fix
Root cause: `supabase.ts` used localStorage-only `createClient` → Server Components using cookie-based SSR never saw the session.

| Fix | File |
|---|---|
| `createBrowserClient` from `@supabase/ssr` | `lib/supabase.ts` |
| Added `set`/`remove` cookie handlers | `lib/supabase-server.ts` |
| Email confirmation callback route | `auth/callback/route.ts` |
| Hard redirect after sign-in | `auth/login/page.tsx` |
| Session refresh middleware | `middleware.ts` |

**Verified on `kanga-visa.com`:** sign-in shows email initials · accordion saves on blur · "Assess my draft →" returns Weak/Adequate/Strong · Strong achieved with cross-referenced booking refs.

```
tsc: 0 errors | Commits: 987b852 · 84cbf63 → main
```

---

## Sprint 28 — React Hydration Fix + AssessmentBadge Persistence
**Completed:** 2026-03-21  
**Commits:** `a8d61a3` on `main`

### What was built

#### P1 — Hydration fix
Root cause: `expanded` state initialised as `useState(initialNote.length > 0)` — SSR renders `false` but client could differ after hydration.

**Fix in `ChecklistItem.tsx`:** always initialise `expanded` to `false`, then `useEffect` opens accordion client-side if `initialNote` is non-empty.

#### P2 — AssessmentBadge persistence on reload
`assessment_json` was already written to `checklist_item_state` by the assess route but never read back on mount.

**Fix:**
- `ChecklistBodyStandalone.tsx`: parses `assessment_json` from items GET response into `assessmentsMap`
- `ChecklistItem.tsx`: new `initialAssessment?: Assessment | null` prop; seeds `assessment` state from it

No new API routes or schema changes.

```
tsc: 0 errors | Commit: a8d61a3 → main
```

---

## Sprint 29 — Export Label Fix + Draft Notes in PDF + Home Affairs KB Source
**Completed:** 2026-03-21  
**Commits:** `b50ba3b` on `main`

### What was built

#### Export label bug fix
Both `ExportPDFDocument.tsx` and `export-docx.ts` rendered raw UUIDs (`evidence_id`) in the evidence checklist instead of the readable label.

**Fix:** pre-built `Map<evidence_id, EvidenceItem>` from `payload.evidence_items`; used `evMap.get(id)?.label ?? id` as a safe fallback in both files.

#### Draft notes in PDF
PDF checklist gained a **NOTE** column (italic, slate, `flex: 1`) showing the user's draft content. DOCX "Note" column header renamed to "Your draft notes".

#### Home Affairs "Check Twice, Submit Once" KB source
Added `ha_check_twice_visitor` to `HOMEAFFAIRS_TARGETS` in `workers/run_watchers.py`.  
URL: `https://immi.homeaffairs.gov.au/visas/help-and-support/check-twice-submit-once`

### E2E verification ✅
| Check | Result |
|---|---|
| `/checklist/500` console | No React hydration errors |
| 5 requirement cards | Loaded correctly |
| Export page download buttons | ↓ PDF ↓ DOCX ↓ CSV all present |

```
tsc: 0 errors | Commits: b50ba3b · a28bf24 → main
```

---

## Future Sprints

*Each sprint walkthrough will be appended here on completion.*

### Sprint 30 — Authenticated E2E + Export Pagination + AskBar Streaming Indicator
**Status:** Planned

| Priority | Item |
|---|---|
| P1 | Authenticated E2E: sign in → 189 checklist → notes + assess → export → verify readable labels and note content in downloaded PDF/DOCX |
| P2 | PDF pagination: page breaks between requirement groups for large checklists (10+ items overflow single A4 page) |
| P3 | AskBar streaming indicator: pulsing "Thinking…" state between submit and first SSE token |

