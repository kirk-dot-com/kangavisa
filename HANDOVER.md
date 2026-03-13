# KangaVisa — Session Handover

---

## Standing Design References

These documents should be consulted when designing any new feature.

| Document | Purpose |
|---|---|
| [`kb/strategy/visitor_visa_data_strategy.md`](kb/strategy/visitor_visa_data_strategy.md) | How to use visitor visa volume data across the platform — onboarding copy, GovData datasets, funnel strategy, rules engine calibration, responsible UI patterns, investor storytelling. |

---

## Session: 2026-02-23

### What we achieved

#### 1. Sprint 0 — complete and pushed to GitHub

**Repo:** `git@github.com:kirk-dot-com/kangavisa.git`

| Area | Status |
|---|---|
| Monorepo structure (`app/`, `workers/`, `kb/`, `.github/`) | ✅ |
| Next.js 14 (App Router + TypeScript) in `app/` | ✅ |
| KB artefacts moved from root → `kb/` | ✅ |
| Python worker package (`pyproject.toml`, `kangavisa_workers/`) | ✅ |
| FRL "hello world" watcher (`frl_watcher.py`) | ✅ |
| JSON Schema validator (`schema_validator.py`) | ✅ |
| **29 pytest tests — all passing** (fixture-based, no live network) | ✅ |
| KB seed: 2 Requirements + 2 EvidenceItems for visa 500 | ✅ |
| `.github/workflows/ci.yml` (pytest + ESLint + tsc) | ✅ |
| `README.md`, `.gitignore`, `app/.env.local.example` | ✅ |
| **Pushed to GitHub** (`main` branch, SSH remote) | ✅ |

#### 2. Decisions made this session

- Remote URL is **SSH** (`git@github.com:kirk-dot-com/kangavisa.git`) — HTTPS had no stored credentials
- `app/` is a monorepo subfolder (not root) — clean separation of concerns
- System Python 3.9 used locally; CI targets Python 3.12 (no action needed locally)

---

## Session: 2026-03-01

### What we achieved

#### 1. Supabase project wired up (Sprint 0 remainder — complete)

| Area | Status |
|---|---|
| Supabase project created (AU region, RLS enabled by default) | ✅ |
| `kb/schema.sql` fixed (COALESCE in UNIQUE → unique index) + applied | ✅ |
| All KB tables confirmed live (`source_document`, `instrument`, `visa_subclass`, `requirement`, `evidence_item`, `change_event`, `flag_template`, `kb_release`) | ✅ |
| `app/.env.local` populated (URL + publishable key + secret key) | ✅ |
| `@supabase/supabase-js` installed | ✅ |
| `app/lib/supabase.ts` — browser client (publishable key, RLS enforced) | ✅ |
| `app/lib/supabase-admin.ts` — server client (secret key, bypasses RLS) | ✅ |
| `tsc --noEmit` — zero errors | ✅ |
| Smoke test: all tables reachable via live Supabase connection | ✅ |

#### 2. Decisions made this session

- Supabase now uses new key naming: **Publishable key** (≈ anon) and **Secret key** (≈ service_role)
- `supabase-admin.ts` is server-only — must never be imported in Client Components

---

### Next session — where to pick up

**Priority 1 — Sprint 1: Real ingestion lanes**
- Upgrade FRL watcher: write `change_event` rows to Supabase (not just stub dicts)
  - Add `SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY` to workers environment
  - Update `frl_watcher.py` to use `httpx` + Supabase REST/client to insert rows
- Add Home Affairs weekly watcher (fetch pages + PDFs, section-level diff)
- Add data.gov.au weekly watcher (dataset metadata + CSV snapshot)
- Impact scoring heuristic (per `kb/architecture.md` §6)

**Priority 2 — CI green on GitHub**
- Verify GitHub Actions CI ran green (check Actions tab on GitHub)
- Fix any lint/tsc issues surfaced by CI

---

## Session: 2026-03-01 (day 2)

### What we achieved — Sprints 3–8

| Sprint | Theme | Status |
|---|---|---|
| 3 | Supabase DaaS consent + analytics schema migration | ✅ |
| 4 | Checklist persistence (sessions API, ChecklistController, timeline view) | ✅ |
| 5 | Flags page, safety-lint, golden-test suite | ✅ |
| 6 | Seed migration SQL, data seeding for Subclass 500 demo, requirement rows | ✅ |
| 7 | LLM AskBar activation, mobile nav, onboarding modal, DaaS consent banner | ✅ |
| 8 | PathwayQuiz (3-step eligibility pre-filter), brand icons, landing page copy | ✅ |

---

### Key deliverables

#### LLM AskBar (Sprint 7 — US-F1)
- `lib/llm-service.ts` — empty-KB guard (returns readable message without calling OpenAI when KB not seeded)
- `app/api/ask/route.ts` — SSE `done` event now includes `model` + `kbEmpty`
- `app/components/AskBar.tsx` — prompt chips (3 per subclass), model badge footer (`gpt-4o-mini · KB-grounded`)

#### Mobile Nav (Sprint 7 — US-A2)
- `app/components/MobileNav.tsx` — slide-out drawer (Escape/backdrop dismiss, scroll lock, focus trap)
- `app/components/AppHeaderClient.tsx` — client island that keeps AppHeader as a Server Component
- Hamburger hidden on desktop (`<768px` only)

#### Onboarding Modal (Sprint 7 — US-E1)
- `app/components/OnboardingModal.tsx` — 4-slide welcome from `narrative_scaffolding_pack.md`, localStorage-guarded

#### DaaS Consent Banner (Sprint 7 — US-C1)
- `app/components/DaaSConsentBanner.tsx` — amber prompt, calls `POST /api/auth/create-consent` on opt-in

#### PathwayQuiz (Sprint 8 — US-A1)
- `app/components/PathwayQuiz.tsx` — 3-step quiz: purpose → location (partner only) → confirm + CTA
- Sits above the existing visa card grid on `/pathway`; "I'm not sure" scrolls to `#browse-all`

#### Brand icons
- Actual KangaVisa logo assets used (from Desktop PNGs)
- `app/public/logo-mark.png` — transparent mark (PIL-extracted, white bg removed)
- `app/public/icon.png`, `apple-icon.png`, `icon-192/48/32/16.png` — navy bg variants
- `AppHeader` uses transparent mark + "KangaVisa" text; `filter: saturate(1.6) brightness(1.2) drop-shadow(gold)`

#### Landing page copy
- Hero: "Prepare a decision-ready / **Australian visa application pack**"
- Subhead and all 4 tiles rewritten with Australian visa keywords (Australian Government, subclass-specific, plain English, no AI em-dashes)
- SEO `generateMetadata()` confirmed on checklist, flags, and timeline pages

---

### Current test status
```
tsc --noEmit:  0 errors
Jest:         28 / 28
Branch:       main (up to date with origin)
```


---

## Session: 2026-03-02

### What we achieved — Sprint 9

#### 1. AskBar verification + critical KB bug fix

| Item | Status |
|---|---|
| `kb-service.ts`: `getRequirements` + `getFlagTemplates` queried non-existent `subclass_code` column | Fixed ✅ |
| Added `resolveVisaId()` helper — looks up `visa_id` UUID from `visa_subclass` first | ✅ |
| AskBar on `/checklist/500`: 5 requirements loaded, KB-grounded response with clause 500.212, LIN 19/051, LIN 18/036 + `gpt-4o-mini · KB-grounded` badge | Verified ✅ |
| SEO tab title confirmed on checklist, flags, timeline pages | Verified ✅ |

#### 2. Sprint 9 deliverables

| Item | File | Status |
|---|---|---|
| `EvidenceItem` interface: renamed `description` + `format_notes` → `what_it_proves` (matches DB column) | `lib/kb-service.ts` | ✅ |
| Dashboard: real `hasConsent` from `consent_state` table + real JWT `authToken` from SSR session | `app/dashboard/page.tsx` | ✅ |
| `DaaSConsentBanner` POST payload: `govdata_research_enabled: true` (was `consent_type: "daas_research"`) | `components/DaaSConsentBanner.tsx` | ✅ |
| `create-consent` route: extracts user from JWT `Authorization` header (no longer trusts body `user_id`) | `api/auth/create-consent/route.ts` | ✅ |
| Export page coverage: `ReadinessScorecard` when signed in; Sign-in prompt when not (was hardcoded 0%) | `export/[subclass]/page.tsx` | ✅ |

---

### Current test status
```
tsc --noEmit:  0 errors
Jest:         28 / 28
Branch:       main (up to date with origin)
```

---

### Next session — where to pick up

**Priority 1 — Auth email templates**
- Customise Supabase signup/confirmation/password-reset emails with KangaVisa branding (logo, gold CTAs, plain-English copy)

**Priority 2 — Dashboard readiness score**
- Surface `ReadinessScorecard` on dashboard for authenticated users with an active session
- Currently renders 0/0 because no `case_session` rows exist for unauthenticated visitors

**Priority 3 — PDF export route**
- Wire `/api/export/pdf` using existing `ExportPDFDocument.tsx` + `export-builder.ts`
- Add "Download PDF" button to export page

**Priority 4 — PWA manifest**
- `app/manifest.ts` → offline support + "Add to home screen" for mobile users

---

### Open questions / decisions pending
- Export format: PDF only, or also include DOCX/CSV?
- Dashboard readiness score: simple % complete, or weighted by requirement criticality?


At the end of each working session, update this file:
1. Add a new session block with today's date
2. Update "What we achieved" with session outcomes
3. Update "Next session — where to pick up" with revised priorities
4. Note any new open questions or decisions made

---

## Session: 2026-03-02 (evening)

### What we achieved — Sprint 10

#### Auth email templates (Sprint 10 P1)

| File | Supabase template | Status |
|---|---|---|
| `app/email-templates/signup-confirm.html` | Confirm signup | ✅ |
| `app/email-templates/reset-password.html` | Reset password | ✅ |
| `app/email-templates/email-change.html` | Change email address | ✅ |
| `app/email-templates/README.md` | Deploy instructions | ✅ |

All templates: navy `#0B1F3B` header · gold `#c9902a` KV badge · gold CTA button · "Not legal advice" footer · email-client-safe inline styles · Supabase `{{ .ConfirmationURL }}` variable.

---

### ⚠️ Action required before next session

> **Paste email templates into Supabase dashboard.**
> Go to: Supabase → Authentication → Email Templates
> Paste each HTML file per the instructions in `app/email-templates/README.md`.
> Subject lines and which template slot to use are documented there.

---

### Current test status
```
tsc --noEmit:  0 errors
Jest:         28 / 28
Branch:       main (committed: Sprint 10 email templates)
```

---

### Next session — where to pick up

**Sprint 10 — remaining items (P1 email templates ✅ done)**

**Priority 1 — Dashboard readiness score (~1h)**
- Surface `ReadinessScorecard` on `/dashboard` for authenticated users with an active session
- Data-fetch pattern already established on the export page — pipe `done_items` / `total_items` counts from `checklist_item_state` into the existing component

**Priority 2 — PDF export route (~2h)**
- Wire `/api/export/pdf` using the already-built `ExportPDFDocument.tsx` + `export-builder.ts`
- Add "Download PDF" button to the export page
- Route already scaffolded in Sprint 5; needs session data wired in

**Priority 3 — PWA manifest (~30m)**
- `app/manifest.ts` → `apple-touch-icon`, `theme_color`, `display: standalone`
- Offline support + "Add to home screen" for mobile users

---

## Session: 2026-03-03 (evening)

### What we achieved — Sprint 12

#### CI fixed
All 7 ESLint errors resolved — CI green on run #64 after 8 consecutive failures.

| File | Fix |
|---|---|
| `api/ask/route.ts` | Empty `catch {}` (unused `err` var) |
| `api/export/csv/route.ts` | Removed unused `NextResponse` import |
| `auth/reset-request/page.tsx` | Escaped `we&apos;ll` (react/no-unescaped-entities) |
| `ChecklistController.tsx` | Removed 5 unused symbols (ChecklistItem, ItemState, REQ_TYPE_ORDER, sortedReqs, handleStatusChange, useCallback) |
| `ExportPDFDocument.tsx` | `eslint-disable ban-ts-comment` + removed unused `Font` |

#### FRL watcher → Supabase (live)
All code was already implemented. Wired the environment and fixed a schema bug:

| Item | Detail |
|---|---|
| `workers/.env` | Created with SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY |
| `workers/.env.example` | Template for future operators |
| `workers/run_frl_watch.py` | Operator entrypoint — 3 FRL targets (Migration Act, Migration Regs, LIN 18/036) |
| `frl_watcher.py` + `test_db.py` | Fixed invalid `kb_change_type` enum: `initial_snapshot` → `new_instrument` |

**Live smoke test:** 3/3 sources fetched, `source_document` + `change_event` rows written to Supabase.

#### Supabase RLS performance fix ✅
`kb/migrations/rls_performance_fix.sql` applied. Wrapped all `auth.uid()` calls in scalar subqueries across `analytics_event`, `consent_event`, `consent_state`. Also dropped stale `analytics_event_insert_if_enabled` policy that was causing a duplicate permissive policy warning. **Supabase advisor: 0 performance issues.**

---

### Current test status
```
tsc --noEmit:  0 errors
Jest:         28 / 28
pytest:       62 / 62
CI:           run #64 ✅
Supabase:     0 performance issues ✅
Branch:       main (uncommitted — workers/.env excluded by .gitignore)
```

---

### Next session — where to pick up

**Priority 1 — Home Affairs + data.gov.au watchers**
- Wire `homeaffairs_watcher.py` + `datagov_watcher.py` same way as FRL
- Combine into a single `run_watchers.py` entrypoint alongside FRL

**Priority 2 — Scheduler**
- Wire weekly cron (GitHub Actions schedule or Render cron job)
- Target: every Monday 06:00 AEST

**Priority 3 — Dashboard staleness banner**
- Surface `StalenessAlert` when `kb_release.released_at` is > 7 days old
- Already has the component — needs the data hook wired in


#### P1 — Dashboard readiness score

| File | Change | Status |
|---|---|---|
| `app/app/dashboard/page.tsx` | Import `ReadinessScorecard`; add `getUnresolvedFlagsCount()` helper; fetch flag count for most-recent session's subclass; render `<ReadinessScorecard>` in a card above the sessions grid | ✅ |
| `app/app/dashboard/dashboard.module.css` | Add `.scorecard_wrap` (bottom margin) | ✅ |

Scorecard shows evidence coverage %, items addressed, and open flags for the most-recently-updated session. Gracefully shows nothing when no sessions exist (empty state unchanged).

---

#### P2 — PDF export route

| File | Change | Status |
|---|---|---|
| `app/app/api/export/pdf/route.ts` | Fixed import path (`../../` → `../../../components/ExportPDFDocument`) | ✅ |
| `app/app/api/export/pdf/route.ts` | Fixed `renderToBuffer` — switched from broken default import to named import | ✅ |

Route now returns `200 application/pdf` with proper `Content-Disposition: attachment` header. Download PDF button was already wired on the export page (Sprint 5). No UI changes needed.

---

#### P3 — PWA manifest

| File | Change | Status |
|---|---|---|
| `app/app/manifest.ts` | New — Next.js 14 manifest route. `display: standalone`, `theme_color: #0B1F3B`, `background_color: #0B1F3B`, icon-192 + icon-512 + apple-icon | ✅ |
| `app/app/layout.tsx` | Add `manifest`, `themeColor`, `appleWebApp` to root metadata | ✅ |

Manifest served at `/manifest.webmanifest` as `application/manifest+json`. Enables "Add to Home Screen" on iOS and Android.

---

### Current test status
```
tsc --noEmit:  0 errors
Jest:         28 / 28
Branch:       main (uncommitted — Sprint 11 complete, ready to commit)
```

---

### Next session — where to pick up

**Sprint 11 is complete. Suggested Sprint 12 items:**

**Priority 1 — Commit Sprint 11 work**
- `git add -A && git commit -m "Sprint 11: dashboard scorecard, PDF route fix, PWA manifest"`
- `git push`

**Priority 2 — Dashboard readiness score: weighted scoring**
- Open question: weight by requirement criticality instead of simple % complete?

**Priority 3 — Worker: write change_events to Supabase**
- `frl_watcher.py` currently only stubs dicts — wire up `httpx` + Supabase REST to insert rows

**Priority 4 — Home Affairs + data.gov.au watchers**
- Weekly fetch + section-level diff, per `kb/architecture.md §6`

### Open questions / decisions pending (resolved)
- Export format: **PDF + DOCX + CSV** — all three live ✅
- Dashboard readiness score: **weighted by requirement criticality** ✅

---

## Session: 2026-03-09

### What we achieved — Sprint 14 (KB Architecture + MVP Pathway Scope)

#### P0 — MVP 5-Pathway Strategy Defined

Locked in the 5 visa pathways that represent ~80–90% of real KangaVisa usage:

| Subclass | Role |
|---|---|
| 600 — Visitor | Free acquisition funnel (~5M apps/year) |
| 500 — Student | Global volume, high refusal anxiety |
| 485 — Temp Graduate | Natural pipeline from 500 users |
| 189/190/491 — Skilled | High planning complexity, points engine |
| 820/801 — Partner | Highest emotional + financial stakes |

#### P1 — Subclass 600 (Visitor Visa) — full KB seed

| File | Status |
|---|---|
| `kb/seed/visa_600_evidence_items.json` | ✅ 7 evidence items |
| `kb/seed/visa_600_requirements.json` | ✅ 5 requirements (600.211, financial, identity, travel plan, host) |
| `kb/seed/visa_600_flags.json` | ✅ 6 visa-specific flags with legal citations |
| `app/app/pathway/page.tsx` | ✅ Subclass 600 card added first (🟢 Lower complexity) |

#### P2 — Rules Engine Triad

| File | Status |
|---|---|
| `kb/seed/flag_templates.json` | ✅ 22 cross-visa reusable flags across 7 refusal categories |
| `kb/seed/subclass_flag_mapping.json` | ✅ Priority + secondary categories per subclass (7 subclasses) |
| `kb/rules/flag_detection_rules.json` | ✅ 32 deterministic rules (R001–R032) |
| `kb/rules/readiness_scoring_model.json` | ✅ 4-component weighted score + score bands + safety rules |

**7 refusal categories:** intent · home_ties · financial_capacity · consistency · evidence_completeness · eligibility · integrity

**Scoring formula:** `(evidence_coverage × 0.35) + (timeline_completeness × 0.20) + (consistency × 0.20) + (risk_flags × 0.25)`

#### P3 — Canonical Case Schema + Supabase Migration

| File | Status |
|---|---|
| `kb/schema/case_schema.json` | ✅ Canonical case object (6 entities, relationships, enumerations) |
| `kb/migrations/case_schema_v1.sql` | ✅ Migration — 6 new tables + RLS policies |

New tables: `cases`, `documents`, `timeline_events`, `flag_events`, `case_scores`, `case_exports`
RLS: all policies use `(SELECT auth.uid())` scalar subquery pattern (consistent with existing performance fix).

> ⚠️ **Action required:** Apply `kb/migrations/case_schema_v1.sql` in Supabase SQL editor. Skip `analytics_events` / `consent_state` / `consent_event` blocks if those tables already exist.

---

### Current test status
```
tsc --noEmit:  0 errors
Branch:       main → e163651 (system architecture doc pushed)
Supabase:     case_schema_v1.sql pending application
```

---

### Next session — Sprint 15 priorities

**Priority 1 — `workers/run_watchers.py`** (rolled from Sprint 14)
- Combine FRL + HA + DG into a single entrypoint (replace `run_frl_watch.py`)
- `homeaffairs_watcher.py` + `datagov_watcher.py` are already implemented

**Priority 2 — GitHub Actions cron scheduler** (rolled from Sprint 14)
- Add `schedule: cron: '0 20 * * 0'` trigger to `.github/workflows/ci.yml`
- Job: `pip install -e '.[dev]' && python workers/run_watchers.py`

**Priority 3 — Dashboard staleness banner** (rolled from Sprint 14)
- Wire `StalenessAlert.tsx` in `dashboard/page.tsx` (component already built)
- Fetch latest `kb_release.released_at` via adminClient

**Priority 4 — Apply `case_schema_v1.sql` to Supabase**
- Run migration in Supabase SQL editor
- Verify all 6 new tables + RLS policies

**Priority 5 — Wire ReadinessScorecard to `readiness_scoring_model.json`**
- Update `computeWeightedCoverage()` in `export-builder.ts` to use 4-component formula
- Surface per-component progress bars on dashboard

**Priority 6 — Subclass 485 flags + 189 seed**
- `visa_485_flags.json` — GTE weakness, qualification timing, English expiry
- `visa_189_requirements.json` + evidence + flags (Skilled Migration)

---

## Session: 2026-03-04

### What we achieved — Sprint 13

#### P0 — RLS analytics_event fix
| File | Change | Status |
|---|---|---|
| `kb/migrations/rls_analytics_event_fix_v2.sql` | Drops duplicate `analytics_event_insert_if_enabled` + `analytics_event_insert_own`; recreates single `analytics_event_insert_own` with `(SELECT auth.uid())` | ✅ Applied in Supabase |

Supabase Advisor: 0 issues for `analytics_event` after applying.

#### P1 — DOCX export
| File | Change | Status |
|---|---|---|
| `app/lib/export-docx.ts` | New — `buildDocx(payload)` using `docx` npm package; branded cover, requirements/flags/evidence tables, disclaimer | ✅ |
| `app/app/api/export/docx/route.ts` | New — `/api/export/docx` route mirroring PDF pattern | ✅ |
| `app/app/export/[subclass]/page.tsx` | Added DOCX download button (between PDF and CSV) | ✅ |

#### P2 — Enriched CSV
| File | Change | Status |
|---|---|---|
| `app/lib/export-builder.ts` | `buildCsv()` now populates `label`, `what_it_proves`, `requirement` columns from evidenceItems in payload (previously blank) | ✅ |

#### P3 — Weighted readiness scorecard
| File | Change | Status |
|---|---|---|
| `app/lib/export-builder.ts` | `computeWeightedCoverage()` helper added — priority 1→3pts, 2→2pts, ≥3→1pt | ✅ |
| `app/app/components/ReadinessScorecard.tsx` | Optional `weightedPct` prop renders "Priority-weighted ?" metric with tooltip | ✅ |
| `app/app/dashboard/page.tsx` | Fetches evidence priorities for latest session, passes `weightedPct` | ✅ |
| `app/app/export/[subclass]/page.tsx` | Same pattern on export page scorecard | ✅ |

---

### Current test status
```
tsc --noEmit:  0 errors
Jest:         28 / 28
CI:           run #65 — pending (was failing due to caseDate bug, now fixed)
Branch:       main → a88699f (pushed)
```

> **Note:** Slow Supabase queries flagged by advisor (pg_timezone_names, PostgREST introspection, WAL backup) are Supabase-internal — no action possible.

---

### Next session — Sprint 14 priorities

**Priority 1 — Home Affairs + data.gov.au watchers (~2–3h)**
- Build `workers/kangavisa_workers/homeaffairs_watcher.py` — scrape Home Affairs visa pages + PDFs, section-level diff against previous snapshot
- Build `workers/kangavisa_workers/datagov_watcher.py` — dataset metadata + CSV snapshot from data.gov.au
- Combine FRL + HA + DG into `workers/run_watchers.py` single entrypoint (replace `run_frl_watch.py`)
- Pattern: identical to FRL watcher — fetch → diff → write `source_document` + `change_event` rows to Supabase

**Priority 2 — Weekly scheduler (~30m)**
- Add `schedule:` trigger to `.github/workflows/ci.yml` (or separate `watchers.yml`)
- Target: every Monday 06:00 AEST (`cron: '0 20 * * 0'` UTC)
- Job: `pip install -e '.[dev]' && python workers/run_watchers.py`

**Priority 3 — Dashboard staleness banner (~30m)**
- `app/app/components/StalenessAlert.tsx` already built — wire data hook in `app/app/dashboard/page.tsx`
- Fetch latest `kb_release.released_at` via adminClient; pass to `<StalenessAlert>` when > 7 days old

### Verified ✅
- DOCX download working on `/export/500`
- Supabase Advisor: 0 issues for `analytics_event` (v2 migration applied)
- CI run #74 green

---

## Session: 2026-03-09

### What we achieved — Sprint 15 close

| Area | Status |
|---|---|
| `case_schema_v1.sql` applied in Supabase (cases, documents, timeline_events, flag_events, case_scores, analytics_events, consent_state, RLS) | ✅ |
| `computeReadinessScore()` function in `export-builder.ts` — 4-component score formula | ✅ |
| `ReadinessScorecard.tsx` upgraded to display readiness score band | ✅ |
| `kb/seed/visa_820_flags.json` — 5 flags for Partner Visa (820) | ✅ |
| `kb/seed/visa_485_flags.json` — 5 flags for Temporary Graduate (485) | ✅ |
| `kb/seed/visa_190_491_seed.json` — delta seed for Skilled Nominated (190) + Skilled Work Regional (491) | ✅ |
| `PathwayQuiz.tsx` — ✈️ Visitor (600) and ⭐ Skilled Independent (189) tiles added | ✅ |
| `VISA_NAMES` map in all 8 files updated to include 600, 189, 190, 491 | ✅ |

### What we achieved — Sprint 16

| Area | Status |
|---|---|
| `kb/migrations/seed_mvp_visas_v1.sql` — complete idempotent seed for 485, 189, 190, 491, 820 | ✅ |
| AskBar `PROMPT_CHIPS` — added 600 (3 chips), 189 (3), 190 (3), 491 (3) | ✅ |
| Export page — `computeReadinessScore()` wired in; `ReadinessScorecard` now receives `readinessScore` | ✅ |
| `tsc --noEmit` — 0 errors | ✅ |

### How to apply the seed SQL

1. Open Supabase → SQL Editor
2. Paste the contents of `kb/migrations/seed_mvp_visas_v1.sql`
3. Run — safe to run multiple times (idempotent via `ON CONFLICT DO NOTHING`)
4. Verify: `SELECT COUNT(*) FROM requirement WHERE visa_id IN (SELECT visa_id FROM visa_subclass WHERE subclass_code IN ('485','189','190','491','820'));`

---

### Next session — Sprint 17 priorities

**Priority 1 — ~~Apply seed SQL to Supabase~~ ✅ Done (2026-03-09)**
- `seed_mvp_visas_v1.sql` applied successfully
- 485 and 820 had pre-existing rows from an earlier seed — ran de-dup cleanup:
  ```sql
  WITH ranked AS (
    SELECT r.requirement_id,
           ROW_NUMBER() OVER (
             PARTITION BY vs.subclass_code, r.title
             ORDER BY r.requirement_id::text
           ) AS rn
    FROM requirement r
    JOIN visa_subclass vs ON vs.visa_id = r.visa_id
    WHERE vs.subclass_code IN ('485', '820')
  )
  DELETE FROM requirement
  WHERE requirement_id IN (SELECT requirement_id FROM ranked WHERE rn > 1);
  ```
- Final counts: 189 → 6, 190 → 1, 485 → 3, 491 → 2, 820 → 4 ✅

**Priority 2 — Add unique constraint on `requirement (visa_id, title)` (~15m)**
- Write `kb/migrations/requirement_unique_title_v1.sql`:
  ```sql
  CREATE UNIQUE INDEX IF NOT EXISTS requirement_visa_title_uk
    ON requirement (visa_id, title);
  ```
- Apply in Supabase SQL Editor
- Prevents future seed reruns creating duplicate content rows (root cause of the 485/820 doubling)

**Priority 3 — Visitor (600) seed data (~1h)**
- Create `kb/seed/visa_600_requirements.json` + evidence items (Genuine Temporary Entrant, financial capacity, health)
- Extend `seed_mvp_visas_v1.sql` or write `seed_v2.sql`

**Priority 4 — Supabase KB staleness banner**
- `kb_release.released_at` is now populated — `StalenessAlert` should activate on the dashboard

**Priority 5 — End-to-end test on a fresh session**
- Sign in as a real user, create a 189 case, tick items, open Export page
- Verify readiness band shows (not just weighted %)

---

## Session: 2026-03-14

### What we achieved — Sprint 17

#### P1 — Unique constraint on `requirement (visa_id, title)`

| File | Status |
|---|---|
| `kb/migrations/requirement_unique_title_v1.sql` | ✅ Created |

Adds `CREATE UNIQUE INDEX IF NOT EXISTS requirement_visa_title_uk ON requirement (visa_id, title)` — prevents future seed re-runs from creating duplicate requirement rows (root cause of the 485/820 doubling in Sprint 16).

> ⚠️ **Action required:** Apply in Supabase → SQL Editor before running any other seed scripts this sprint.

---

#### P2 — Visitor (600) full KB seed

| File | Status |
|---|---|
| `kb/migrations/seed_visitor_600_v1.sql` | ✅ Created |

Idempotent seed (`ON CONFLICT DO NOTHING`) covering:
- **5 requirements:** Genuine Visitor, Financial Capacity, Identity Confirmation, Clear Travel Plan, Invitation Support (Visiting Family or Friends)
- **8 evidence items** mapped to each requirement
- **6 flag templates** (warning/risk) with legal citations and actionable guidance
- **1 `kb_release` row** (`kb-v20260314-visitor-600`) → resets the staleness banner

Uses `ON CONFLICT ON CONSTRAINT requirement_visa_title_uk DO NOTHING` — requires P1 applied first.

> ⚠️ **Action required (in order):**
> 1. Apply `requirement_unique_title_v1.sql` first
> 2. Then apply `seed_visitor_600_v1.sql`
> 3. Verify with queries at the bottom of the seed file (expect: 5 requirements, 8 evidence items, 6 flags)

---

#### P3 — KB staleness banner

Already fully implemented from Sprint 12 — `KBStalenessAlert.tsx` component + data hook wired in `dashboard/page.tsx`. The `kb_release` row inserted by the 600 seed will reset the 30-day staleness clock.

---

### Current test status
```
tsc --noEmit:  0 errors
Branch:       main (uncommitted — Sprint 17 migrations ready to commit)
```

---

### Next session — Sprint 18 priorities

**Priority 1 — Apply Sprint 17 migrations to Supabase (~20m)**
1. Apply `requirement_unique_title_v1.sql` in Supabase SQL Editor
2. Apply `seed_visitor_600_v1.sql` in Supabase SQL Editor
3. Verify counts (queries embedded at bottom of seed file)

**Priority 2 — Commit Sprint 17 work (~5m)**
- `git add -A && git commit -m "Sprint 17: unique constraint migration + Visitor 600 seed"`
- `git push`

**Priority 3 — End-to-end test on a fresh 189 session**
- Sign in as a real/test user
- Navigate to `/pathway` → select 189 Skilled Independent
- Create a new case session, tick 3–4 items
- Open `/export/189` — verify readiness band shows (not just weighted %)
- Download PDF and DOCX — confirm files open correctly
- Test AskBar on `/checklist/189` — verify KB-grounded response

**Priority 4 — End-to-end test on Visitor 600**
- Once seed is applied, navigate to `/checklist/600`
- Verify 5 requirements and 8 evidence items load
- Confirm AskBar prompt chips for 600 appear and return a KB-grounded answer

