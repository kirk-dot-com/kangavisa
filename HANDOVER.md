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

### ⚠️ One action required before next session

> **KB Seed** — open Supabase SQL Editor and run `migrations/seed_kb_v1.sql` (750 lines, already generated).  
> Once done, the AskBar will answer real visa questions grounded in the KB instead of returning "not seeded".

---

### Next session — where to pick up

**Priority 1 — Verify AskBar live**
- After KB seed: `/checklist/500` → AskBar → "What documents prove genuine student intent?"
- Expect: streamed KB-grounded answer + `gpt-4o-mini · KB-grounded` badge

**Priority 2 — Sprint 9 candidates**
- Auth email templates: customise Supabase signup/confirmation/reset with KangaVisa branding
- Dashboard readiness score: surface a % readiness score based on completed checklist items
- Readiness pack export: PDF export of checklist + evidence status + AskBar citations
- PWA manifest: offline support + "Add to home screen" for mobile users

**Priority 3 — DaaS consent refinement**
- Pass real `hasConsent` server-side check and actual `authToken` to `DaaSConsentBanner` (currently placeholder `false`/`null`)

---

### Open questions / decisions pending
- Export format preference: PDF only, or also include DOCX/CSV options?
- Dashboard readiness score: simple % complete, or weighted by requirement criticality?
### How to use this file
At the end of each working session, update this file:
1. Add a new session block with today's date
2. Update "What we achieved" with session outcomes
3. Update "Next session — where to pick up" with revised priorities
4. Note any new open questions or decisions made
