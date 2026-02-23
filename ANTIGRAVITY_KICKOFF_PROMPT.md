# Antigravity Kickoff Prompt — KangaVisa MVP Build (KB-first + GovData-ready)

Antigravity team — please start delivery planning and implementation for **KangaVisa** (working product name), based on:

- **PRD:** `PRD_KangaVisa_v1.2.md` (repo attachment)  
- **KB starter files:** `kb/schema.sql`, `kb/models/*.jsonschema`, `kb/sources.yml`, `kb/release_process.md`, plus `kb/architecture.md`, `kb/runbook.md`, `kb/testcases.md`, `DECISIONS.md`  
- **Business case:** KangaVisa investor + gov-ready business case (readiness layer + GovData)

---

## 1) Project goal (MVP)

Build a **compliance-first “readiness + pathway intelligence”** web application that helps users prepare **decision-ready packs** for manual upload to ImmiAccount, and establishes the **knowledge system + governance rails** required for future GovData (DaaS).

**Key constraint:** We do **not** provide legal advice, do **not** predict outcomes, and do **not** submit to ImmiAccount. The product outputs **Evidence Checklists**, **Flags**, and **Export Packs** only, with **citations** and **effective dates**.

---

## 2) MVP scope (must ship)

### A) App features (MVP 0–6 months)

1) **Pathway Finder**
   - Guided intake questionnaire → shortlist of 3–5 plausible pathways with “why/why-not”
   - Must show **assumptions** and allow user edits

2) **Evidence Checklist Engine**
   - Personalised checklist by visa type + user answers  
   - Each item includes: *what it proves* + examples + common gaps

3) **Consistency + Completeness Validation**
   - Generate a timeline view (study/work/residency/relationship as relevant)
   - Create **Flag Cards** (trigger → why → actions → evidence examples)
   - “Readiness score” = completeness + consistency + unresolved flags  
   - Must include “not a decision prediction” disclaimer

4) **Export Pack Generator**
   - PDF export: cover summary, checklist, evidence index, timeline, unresolved flags  
   - JSON export bundle (for future interoperability)  
   - User manually uploads to ImmiAccount

5) **Consent & Audit Trails**
   - Granular consent toggles:
     - (a) product analytics
     - (b) de-identified research/GovData
   - Default = opt-out for research/GovData
   - Audit log events: uploads, edits, scoring changes, exports, consent changes

### B) Knowledge System (MVP-critical, must ship)

Implement the **KB + ingestion/diff/release** flow so the app remains accurate after launch:

- Postgres KB schema from `kb/schema.sql`
- Support structured objects:
  - `Instrument`, `Requirement`, `EvidenceItem`, `FlagTemplate` (validate with JSON Schemas)
- Load initial KB content for **MVP visa scope**:
  - **500**, **485**, **482 (SID/TSS)**, **417/462**, **820/801 + 309/100**
- Implement ingestion watchers using `kb/sources.yml`:
  - FRL lane (daily)
  - Home Affairs lane (weekly)
  - data.gov.au lane (weekly)
- Diff detection + `change_event` creation with impact scoring + review gating
- KB releases tagged (e.g., `kb-YYYY-MM-DD`), with rollback/hotfix process per `kb/release_process.md`
- Runtime must enforce:
  - **citations** for criteria statements
  - **Verified on** date
  - staleness warning if Tier 1 not refreshed within threshold

---

## 3) System architecture expectations (high level)

- Web app (mobile-friendly) with secure auth
- Secure document store (AU region preferred), encryption at rest + in transit
- PII vault separated from analytics store (GovData readiness)
- Strict RBAC + least privilege; no staff access to user docs unless explicitly authorised
- LLM use is constrained to:
  - explanation generation
  - drafting assistance
  - summarisation of user-provided text
  - must be grounded in structured KB + citations (no free-form “rule invention”)

---

## 4) Deliverables requested from Antigravity (first sprint planning)

Please produce:

### (1) Implementation plan + milestones
- Sprint plan (MVP cutline) + dependency map
- Proposed team composition + roles
- Delivery timeline by module

### (2) Technical architecture pack
- Component diagram + data flows (PII vault vs analytics store)
- Storage choices + encryption + RBAC approach
- LLM guardrails approach (structured-first retrieval, citation enforcement, forbidden-phrase lint)
- KB ingestion/diff/review pipeline design (how you’ll implement it)

### (3) Backlog in engineering format
- Epics → Stories → Tasks mapped to PRD FRs (FR-1..FR-8, FR-K1..FR-K6, FR-D1..FR-D5)
- Explicit acceptance criteria per story

### (4) “Definition of Done” checklist
- Must include KB tests: run `kb/testcases.md` golden prompts pass criteria
- Must include security + privacy controls
- Must include export pack correctness and audit logging

---

## 5) Non-negotiables (quality + trust)

- No approval predictions, no “eligibility determinations”, no legal advice framing
- All criteria statements must cite Tier 0/1 sources and show “Verified on”
- Effective-dated rules only (no overwriting)
- Consent-first GovData posture (research/DaaS opt-out default)
- Disclosure control design for GovData outputs (minimum cell sizes, suppression)
- Audit trails are a core product feature (not optional)

---

## 6) MVP success criteria

- Users can complete intake → checklist → flags → export pack for at least **3** of the MVP visa groups initially  
  *(you may phase the remaining two, but KB + pipeline must support the full set)*
- KB ingestion/diff pipeline runs and generates reviewable change events
- Export pack includes KB version stamp and is reproducible
- Consent controls and deletion propagation design are implemented (at minimum for research toggle)

---

## 7) Context: business case framing (why this matters)

KangaVisa is “workflow software disguised as advice”—the product wedge is **decision-ready packs**, **explainable flags**, and **change monitoring**, positioned adjacent to ImmiAccount. The long-term moat is an **ethically obtained, privacy-safe data layer (GovData)** that helps government understand where applicants get stuck and how policy changes affect readiness—without profiling individuals.
