# KangaVisa — Session Handover

---

## Session: 2026-02-23

### What we achieved

#### 1. Sprint 0 — fully scaffolded

**Repo:** `https://github.com/kirk-dot-com/kangavisa.git`

| Area | Status |
|---|---|
| Monorepo structure (`app/`, `workers/`, `kb/`, `.github/`) | ✅ done |
| Next.js 14 (App Router + TypeScript) in `app/` | ✅ done |
| KB artefacts moved from root → `kb/` | ✅ done |
| Python worker package (`pyproject.toml`, `kangavisa_workers/`) | ✅ done |
| FRL "hello world" watcher (`frl_watcher.py`) | ✅ done |
| JSON Schema validator (`schema_validator.py`) | ✅ done |
| **29 pytest tests — all passing** (no live network) | ✅ done |
| KB seed: 2 Requirements + 2 EvidenceItems for visa 500 | ✅ done |
| JSON Schema validation of seed objects | ✅ done |
| `.github/workflows/ci.yml` (pytest + lint + tsc) | ✅ done |
| `README.md`, `.gitignore`, `app/.env.local.example` | ✅ done |
| Git repo initialised, remote wired, all files committed | ✅ done |
| **Push to GitHub** | ⚠️ needs your credentials (see below) |

#### 2. Key implementation decisions made this session

- `implementation_plan.md.resolved` (existing file in root) left in place — not deleted
- `app/` nested inside monorepo root (Option A from plan)
- Using `pip3` / system Python 3.9 for local dev; CI specifies Python 3.12
- create-next-app auto-inited a `.git` in `app/` — removed and re-inited at monorepo root

---

### Next session — where to pick up

**Priority 1 — Supabase wiring (Sprint 0 remainder)**
1. Create Supabase project (AU region): Auth, Postgres, Storage
2. Copy `.env.local.example` → `.env.local` with real keys
3. Run `kb/schema.sql` against dev Postgres (via Supabase SQL editor)
4. Wire `@supabase/supabase-js` in `app/` — confirm auth flow works

**Priority 2 — Sprint 1: Ingestion lanes**
- Upgrade FRL watcher from skeleton → real Supabase writes (`change_event` table)
- Add Home Affairs and data.gov.au watchers
- Impact scoring heuristic

**Priority 3 — Sprint 0 CI finalize**
- Push to GitHub (needs auth — see below)
- Confirm GitHub Actions CI runs green on first push

---

### Open items / pending decisions

1. **GitHub push** — `git push -u origin main` failed with "Device not configured" (no HTTPS credentials stored in terminal session). To push:
   - Option A: `gh auth login` if GitHub CLI is installed
   - Option B: Use a Personal Access Token: `git remote set-url origin https://YOUR_PAT@github.com/kirk-dot-com/kangavisa.git && git push -u origin main`
   - Option C: Push via GitHub Desktop / VS Code Git panel

2. **Supabase project** — not yet created. Needs to happen before Sprint 1 DB writes.

3. **Python version** — system has Python 3.9. Plan targets 3.12 for production (CI uses 3.12). No action needed locally, but worth noting.

---

### How to use this file
At the end of each working session, update this file:
1. Replace the date header with today's date
2. Update "What we achieved" with session outcomes
3. Update "Next session — where to pick up" with revised priorities
4. Note any new open questions or decisions made
