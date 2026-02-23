# kb/architecture.md — KangaVisa Knowledge System Architecture v0.1

**Last updated:** 2026-02-22  
**Scope:** MVP knowledge system for visa subclasses/streams: **500, 485, 482 (SID/TSS settings), 417/462, 820/801 + 309/100**.

This document describes how KangaVisa sources, structures, versions, and serves authoritative immigration knowledge for:
- **App experiences** (Pathway Finder, Evidence Checklist, Flags, Export Pack)
- **GovData (DaaS)** (privacy-safe aggregated metrics)

> Principle: **Structured-first** retrieval. The LLM renders outputs from versioned `Requirement` / `EvidenceItem` / `FlagTemplate` objects, and only falls back to document snippets for edge cases.

---

## 1) Architecture overview

### Planes
1) **Knowledge Plane (KB)**
- Structured objects (Requirements, Evidence Items, Flag Templates)
- Source snapshots + provenance (FRL, Home Affairs, data.gov.au)
- Versioning + effective dating

2) **Ingestion Plane**
- Watchers (FRL, Home Affairs, data.gov.au)
- Snapshotting + parsing
- Diff detection + impact scoring
- Review gates (human approval)

3) **Runtime Plane**
- Structured retrieval (DB)
- Document retrieval (vector index / full-text)
- Response composer (enforces citations + safe language)

4) **Governance Plane**
- Release management
- Audit logs
- Security & privacy controls
- Disclosure controls for GovData

---

## 2) Data stores

### 2.1 Postgres (KB Core)
Use `kb/schema.sql` tables:
- `source_document`
- `instrument`
- `visa_subclass`
- `requirement`
- `evidence_item`
- `flag_template`
- `change_event`
- `kb_release` (optional but recommended)

**Why Postgres:** strong relational integrity, effective dating, audit-friendly queries.

### 2.2 Object storage (raw snapshots)
Store raw HTML/PDF/CSV and parsed versions:
- `raw_blob_uri`: exact snapshot bytes
- `parsed_text_uri`: normalized text (for indexing)

### 2.3 Indexes for retrieval
- **Structured-first:** Postgres queries by `visa_id`, `requirement_type`, effective dates.
- **Document fallback:** vector index (or Postgres full-text) over `parsed_text_uri` content to fetch short citations/snippets.

> Rule: the LLM must prefer the structured layer; doc snippets are supporting evidence or for “open-ended” queries.

---

## 3) Source hierarchy (authority model)

### Tier 0 — Authoritative legal sources (controlling)
- Federal Register of Legislation (FRL): Act, Regs, Instruments

### Tier 1 — Operational guidance
- Home Affairs pages and official reports (evidence examples, how-to guidance)

### Tier 2/3 — Optional later (not MVP)
- Review bodies, professional commentary (pattern awareness only)

**Conflict resolution:** Tier 0 overrides Tier 1. The system must say so when conflicts arise.

---

## 4) Effective dating and versioning

### 4.1 Effective dating rules
Every object that changes with law/policy must have:
- `effective_from` (required)
- `effective_to` (nullable)

### 4.2 Runtime selection rule
Given a user “case date” (default = today):
- Select the object with `effective_from <= case_date` AND (`effective_to` is null OR `effective_to >= case_date`)
- If multiple match, choose the most recently reviewed/released version.

### 4.3 No overwrites
Never overwrite structured objects. Create a new version with a new effective range.

---

## 5) Ingestion design (high level)

### 5.1 Watch lists
All watched URLs live in `kb/sources.yml`, grouped by tier and lane.

### 5.2 Lanes
1) **FRL lane (daily)**
- Fetch latest/details pages
- Parse: status, effective dates, title ID, series (LIN), repeal/supersede chains
- Diff: metadata + text
- Create `change_event` and (optionally) auto-create stub `instrument` records

2) **Home Affairs lane (weekly)**
- Fetch pages + PDFs
- Diff: section-level changes, evidence lists, report refreshes
- Update operational basis and evidence examples (Tier 1)

3) **data.gov.au lane (weekly)**
- Check dataset metadata + resources
- Snapshot resources (CSV/XLSX), validate schema drift
- Append time-series into analytics store (separate from KB core)

---

## 6) Change detection and impact scoring

### 6.1 Change types
- `new_instrument`, `repeal`, `new_version` (high impact)
- `text_change` (medium)
- `dataset_update` (medium)

### 6.2 Impact scoring heuristic (suggested)
Start at 0; add points:
- FRL status changed (repealed/superseded): +80
- Effective dates changed: +70
- Keywords: english/financial/occupation/specified work/exemptions: +60
- Requirements directly referenced by MVP visas: +40
- Home Affairs evidence list changed: +30
- Dataset schema drift: +50

`impact_score >= 70` => **requires review**.

---

## 7) Runtime retrieval and response composition

### 7.1 Structured retrieval flow (preferred)
1) Identify relevant visa(s) and requirement types from user query.
2) Load active `Requirement` objects by effective date.
3) Load associated `EvidenceItem`s and relevant `FlagTemplate`s.
4) Render response using the KangaVisa output standards (checklist, flags, next actions).

### 7.2 Document fallback flow
If structured objects are missing or user asks “show source text”:
1) Query the document index for supporting passages
2) Present short snippets + citations
3) Add a **staleness warning** if the source has not been updated recently

### 7.3 Safety constraints enforced at runtime
- Never output determinations (“approved/eligible/guaranteed”)
- Always include: assumptions + next actions
- Enforce disclaimer placement on high-stakes screens/exports
- Refuse disallowed requests (fraud/evasion)

---

## 8) GovData (DaaS) integration

### 8.1 Separation of stores (mandatory)
- **PII Vault** (user files, sensitive details): isolated storage + strict RBAC
- **Analytics Warehouse** (de-identified telemetry): no direct identifiers
- **GovData outputs**: aggregated metrics with disclosure controls

### 8.2 Disclosure controls
- Minimum cell sizes (e.g., k>=20)
- Suppress small cells and high-risk dimensions
- Publish methodology + data dictionary with every dataset

---

## 9) Observability and auditability

### Metrics
- Crawl success rate per lane
- Diff events per week
- Review queue size + age
- KB release frequency
- Staleness warnings triggered (by source type)
- Schema drift incidents (data.gov.au resources)

### Audit logs
- KB object changes tracked via Git + `kb_release` table
- Source snapshots immutable (content hash)

---

## 10) Implementation checklist
- [ ] Deploy Postgres schema from `kb/schema.sql`
- [ ] Stand up object storage and snapshot naming convention
- [ ] Implement watchers per lane using `kb/sources.yml`
- [ ] Implement diff + impact scoring -> `change_event`
- [ ] Build reviewer workflow (UI or lightweight CLI)
- [ ] Implement release tagging and promotion controls
- [ ] Add runtime “structured-first” retrieval with citations + safety lint
