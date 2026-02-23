# KangaVisa

Compliance-first Australian immigration readiness + pathway intelligence app.

> **Not legal advice.** KangaVisa produces decision-ready packs for manual upload to ImmiAccount. It does not predict outcomes, determine eligibility, or submit applications.

---

## Repo structure

```
kangavisa/
  app/           ← Next.js 14 (App Router + TypeScript) — Vercel deploy
  workers/       ← Python ingestion workers (FRL, Home Affairs, data.gov.au)
  kb/            ← Knowledge base artefacts (schema, JSON schemas, sources, seed)
  .github/
    workflows/ci.yml   ← CI: pytest + Next.js lint + tsc
```

---

## Quick start

### Next.js app (local dev)

```bash
cd app
npm install
cp .env.local.example .env.local   # fill in Supabase + OpenAI keys
npm run dev
# → http://localhost:3000
```

### Python workers

Requires Python 3.9+ (3.12 recommended for production).

```bash
cd workers
pip install -e ".[dev]"
python -m pytest tests/ -v
```

---

## CI

GitHub Actions runs on every push/PR to `main`:

1. **Python tests** — `pytest workers/tests/` (schema validation + FRL watcher)
2. **Next.js lint** — `npm run lint`
3. **TypeScript** — `npx tsc --noEmit`

---

## KB schema

The Postgres KB schema is at [`kb/schema.sql`](kb/schema.sql). Run against a Supabase dev instance:

```bash
# From Supabase dashboard → SQL Editor, paste and run kb/schema.sql
# Or via psql:
psql "$DATABASE_URL" -f kb/schema.sql
```

---

## Key documents

| Document | Purpose |
|---|---|
| [`kb/architecture.md`](kb/architecture.md) | KB planes, data tiers, ingestion + retrieval design |
| [`kb/sources.yml`](kb/sources.yml) | Ingestion watch list (FRL / Home Affairs / data.gov.au) |
| [`kb/release_process.md`](kb/release_process.md) | KB release pipeline and rollback procedures |
| [`kb/testcases.md`](kb/testcases.md) | Golden prompt test suite |
| [`DECISIONS.md`](DECISIONS.md) | Key product + technical decisions |
| [`HANDOVER.md`](HANDOVER.md) | Session handover log |
