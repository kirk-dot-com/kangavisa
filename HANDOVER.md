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

### Open questions / decisions pending
- None — Supabase fully wired. Sprint 1 is next.

---

### How to use this file
At the end of each working session, update this file:
1. Add a new session block with today's date
2. Update "What we achieved" with session outcomes
3. Update "Next session — where to pick up" with revised priorities
4. Note any new open questions or decisions made
