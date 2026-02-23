# KangaVisa — Session Handover

---

## Session: 2026-02-22

### What we achieved

#### 1. Knowledge base (KB) starter files — complete
All KB artefacts are committed to `/Users/kirkjohnstone/Downloads/kangavisa/`:

| File | Purpose |
|---|---|
| `schema.sql` | Postgres DDL — full KB schema with effective dating, enums, indexes |
| `architecture.md` | KB architecture: planes, data stores, tier model, ingestion + retrieval design |
| `sources.yml` | Ingestion watch list (FRL daily / Home Affairs weekly / data.gov.au weekly) |
| `release_process.md` | KB release pipeline: ingest → diff → review → publish; hotfix + rollback procedures |
| `runbook.md` | Ops runbook: daily/weekly ops, alert categories, staleness thresholds |
| `testcases.md` | Golden prompt test suite + automated check criteria |
| `DECISIONS.md` | Key product + technical decisions snapshot |
| `skills.md` | Product skill definition (AI behaviour, guardrails, output standards) |
| `requirement.jsonschema` | JSON Schema for Requirement objects |
| `evidence_item.jsonschema` | JSON Schema for EvidenceItem objects |
| `flag_template.jsonschema` | JSON Schema for FlagTemplate objects |
| `instrument.jsonschema` | JSON Schema for Instrument objects |

#### 2. Planning artefacts — complete
Two master planning documents created in the Antigravity brain directory:

- **`implementation_plan.md`** — master document (all future changes tracked here):
  - Sprint plan (Sprint 0–6, 0–6 months)
  - Technical architecture: component diagram, PII vault ↔ analytics store separation, LLM adapter interface, KB ingestion pipeline, RBAC roles
  - Full engineering backlog mapped to FR-1..FR-K6..FR-D5 (Epics A–G, User Stories, Tasks, AC)
  - Definition of Done checklist (KB tests, security/privacy, export pack, KB release)
  - Verification plan (automated tests + golden prompts + manual browser + security spot checks)

- **`task.md`** — execution checklist (Phase 0–5, tracks in-progress/done)

#### 3. Tech stack locked
| Decision | Choice |
|---|---|
| Frontend | Next.js 14 (App Router) + TypeScript → Vercel |
| API | Next.js API routes + TypeScript |
| Ingestion workers | Python 3.12 (httpx + BeautifulSoup) — separate scheduled service |
| LLM | Provider-agnostic adapter → OpenAI default |
| Auth | Supabase Auth |
| Postgres | Supabase Postgres (AU region) |
| Storage | Supabase Storage (AU), fallback AWS S3 Sydney |

#### 4. Key constraints confirmed (non-negotiable)
- PII Vault ↔ Analytics Store separation from day one
- Citation enforcement + effective-date selection are MVP acceptance criteria (not deferred)
- `implementation_plan.md` is the master — all subsequent changes documented there

---

### Next session — where to pick up

**Priority 1 — Begin Sprint 0 (repo scaffold)**

1. Initialise Next.js 14 (App Router + TypeScript) project in `/Users/kirkjohnstone/Downloads/kangavisa/` (or a `app/` subdirectory)
2. Set up Supabase project (dev env): Auth, Postgres, Storage
3. Run KB schema migration (`schema.sql` → Supabase dev Postgres)
4. Wire JSON Schema validators for all 4 model types
5. Create Python ingestion worker skeleton (`workers/` directory) with:
   - FRL lane "hello world" watcher (fetch + snapshot + content hash → `change_event` stub)
   - Basic test fixture so CI doesn't need live network access

**Priority 2 — CI/CD baseline**
- GitHub Actions pipeline: lint + type-check + schema validation on push
- Vercel project linked to repo (Next.js auto-deploy on `main`)

**Priority 3 — First KB content seed**
- Draft initial Requirement + EvidenceItem JSON objects for Student visa (500) — enough to unblock the Pathway Finder screen

---

### Open questions / decisions pending
- None — all stack decisions resolved. Implementation plan is the source of truth.

---

### How to use this file
At the end of each working session, update this file:
1. Replace the date header with today's date
2. Update "What we achieved" with session outcomes
3. Update "Next session — where to pick up" with revised priorities
4. Note any new open questions or decisions made
