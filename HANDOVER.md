# KangaVisa — Session Handover

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

## Session: 2026-03-03

### What we achieved — Sprint 11

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

### Current test status
```
tsc --noEmit:  0 errors
Jest:         28 / 28
Branch:       main (uncommitted — commit after P3)
```

---

### Next session — where to pick up

**Priority 1 — PWA manifest (~30m)**
- `app/manifest.ts` → `apple-touch-icon`, `theme_color`, `display: standalone`
- Offline support + "Add to home screen" for mobile users

### Open questions / decisions pending
- Export format: PDF only, or also include DOCX/CSV? (CSV already exists at `/api/export/csv`)


