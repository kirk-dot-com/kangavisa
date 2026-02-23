# Product Requirements Document (PRD) — KangaVisa (KangaPath AI + GovData)

**Version:** v1.2 (Investor + Gov-ready)  
**Product name:** KangaVisa  
**Data Product Line:** GovData for Migration (DaaS)  
**Vision:** Become the “readiness + transparency layer” for Australian migration: help applicants/sponsors produce **decision-ready packs**, and generate **privacy-safe operational intelligence** that helps government reduce bottlenecks, integrity risks, and user confusion.  
**Positioning:** *Readiness, not advice.*

---

## 1) Problem & Opportunity

The Australian visa system exhibits complexity, opacity, and high administrative load, producing avoidable errors, delays, and user stress. Applicants often rely on fragmented forums and outdated guidance; employers and agents spend heavy time on admin; government faces triage backlogs and integrity challenges.

**Opportunity:** a compliance-first system that:
- Improves application readiness via validation layers and evidence mapping
- Improves transparency (status dashboards, plain-language explanations)
- Improves integrity and risk triage via anomaly detection and consistency checks (aggregate / privacy-safe)
- Produces aggregated, de-identified insights as a monetisable DaaS offering to government/policy stakeholders (privacy-law + consent aligned)

---

## 2) Product Scope

### 2.0 MVP Visa Scope (explicit)

KangaVisa MVP supports **5 high-impact visa groups**:
1) **Student (500)**
2) **Temporary Graduate (485)**
3) **Skills in Demand / TSS settings (482)**
4) **Working Holiday Maker (417/462)**
5) **Partner (820/801 + 309/100)**

> This scope is mandatory because it bounds the KB corpus, ingestion watch-list, and testing suite.

### 2.1 Core App (B2C + B2B)

Core modules (MVP → Phase 2):
- Pathway Finder (dynamic questionnaire + pathway shortlist)
- Evidence Checklist Engine (personalised docs + coverage tracking)
- Consistency & Completeness Validation (flags + fix actions)
- Risk Indicators (flag categories + explainable reasons)
- Policy Change Alerting (monitor + translate changes into impact)
- Export Pack Generator (structured bundle + JSON-ready future format)
- Audit Trail + Version Stamps (actions + pack/KB versioning)

### 2.2 Knowledge System (KB) (MVP-critical)

A first-class product capability that ensures accuracy, freshness, and auditability:
- Tiered source authority model (FRL + Home Affairs + datasets)
- Structured knowledge objects (Requirement/Evidence/Flag/Instrument)
- Effective-dated versioning (no overwriting; history preserved)
- Ingestion + diff + review gates + release tags
- Citation enforcement and staleness warnings at runtime

### 2.3 Data-as-a-Service (GovData) (separate product line)

De-identified, aggregated, statistically safe datasets and insights derived from:
- consented user interactions
- readiness patterns and evidence gap signals
- aggregated inconsistency/risk-flag patterns
- policy change impact signals
- aggregated surge signals

---

## 3) Target Users & Buyers

### App users
- Applicants: student, skilled, partner, onshore transitions
- Sponsors: partner sponsor, employer sponsor
- Migration agents (RMA): structured packs reduce admin burden
- Employers/HR: nomination readiness, compliance support

### DaaS buyers (government + public sector)
- Home Affairs policy/ops teams (triage, comms, integrity)
- State migration units (nomination insights)
- Regional migration bodies (uptake/retention signals)
- Oversight/audit stakeholders (transparency and contestability)

---

## 4) Use Cases (App + DaaS)

UC1 — Pathway Discovery (Applicant)  
UC2 — Readiness & Completeness (Applicant/Sponsor)  
UC3 — Consistency Validation (Applicant)  
UC4 — Risk Indicator Explanations (Applicant)  
UC5 — Policy Change Impacts (All)  
UC6 — Employer Sponsorship Readiness (Employer)  
UC7 — Government Ops Intelligence (GovData)  
UC8 — Integrity Patterns (GovData, aggregate only; no dossiers)

---

## 5) User Stories (MVP-ready)

### Epic A — Pathway Finder

**US-A1** As an applicant, I want a guided intake so the system understands my situation and goals.  
**AC:** Save/resume; explain “why we ask”; collect onshore/offshore, intent, occupation, study/work history.

**US-A2** As an applicant, I want a shortlist of pathways with plain-language rationale.  
**AC:** 3–5 options; show prerequisites and evidence categories; clearly label uncertainty and assumptions.

**US-A3** As an applicant, I want to compare pathways side-by-side.  
**AC:** Compare cost drivers, evidence burden, and key risk flags; allow user to select a preferred pathway.

### Epic B — Evidence Checklist + Upload

**US-B1** As an applicant, I want a personalised evidence checklist.  
**AC:** Checklist adapts by visa type and user answers; each item includes “what it proves” and examples.

**US-B2** As an applicant/sponsor, I want to upload documents and tag them to evidence items.  
**AC:** Auto-suggest categories; user override; store document metadata (issuer/date range/person).

**US-B3** As an applicant, I want a readiness score and prioritised action list.  
**AC:** Score = completeness + consistency + unresolved flags; disclaimer that it’s not a decision prediction.

### Epic C — Consistency + Risk Flags

**US-C1** As an applicant, I want a generated timeline so gaps are visible.  
**AC:** Employment/study/residency/relationship timeline; highlight gaps and overlaps.

**US-C2** As an applicant, I want inconsistency flags with fix instructions.  
**AC:** Each flag includes trigger → why it matters → evidence/actions; user can resolve with note + upload.

**US-C3** As an applicant, I want explainable risk indicators (e.g., GS/GTE, partner evidence weakness).  
**AC:** Risk categories align to documented themes; avoids definitive “eligible/approved” claims.

### Epic D — Export + Interoperability

**US-D1** As a user, I want a structured export pack to upload manually to ImmiAccount.  
**AC:** Generates PDF summary + evidence index + checklist + timeline + unresolved flags; also JSON export for future API use.

**US-D2** As a user, I want assisted submission mode (guidance only, no automation).  
**AC:** Side-by-side companion flow; real-time field validation; no automated submission.

### Epic E — DaaS Consent + Data Products

**US-E1** As a user, I want to opt in/out of data contribution clearly and granularly.  
**AC:** Separate toggles for (a) aggregated product analytics (b) de-identified research datasets; default = opt-out; can withdraw anytime (APP-aligned).

**US-E2** As an admin, I want a de-identification pipeline that produces safe datasets.  
**AC:** Remove direct identifiers; generalise quasi-identifiers; k-anonymity thresholds; suppress small cells; publish only aggregated outputs.

**US-E3** As a government buyer, I want dashboards and exports showing system friction signals.  
**AC:** Weekly/monthly feeds; trends by visa stream and journey stage; policy-change impact notes; ability to export CSV/Parquet/API.

**US-E4** As a government buyer, I want an “integrity signal bulletin” that is safe and explainable.  
**AC:** Only aggregated anomaly indicators; no personal dossiers; clear methodology and caveats; audit logs of transformations.

### Epic F — Knowledge System (KB) + Trust (MVP-critical)

**US-F1** As a user, I want criteria explanations to cite official sources.  
**AC:** Every criteria statement includes Tier 0/1 citations; “Verified on” date shown.

**US-F2** As a user, I want KangaVisa to warn me when guidance may be stale.  
**AC:** Staleness warning appears if Tier 1 sources not refreshed within threshold (e.g., 30 days).

**US-F3** As a KB reviewer, I want a workflow to approve high-impact changes before they go live.  
**AC:** Diff events produce a review queue; high-impact changes require approval and release tagging.

**US-F4** As an admin, I want KB releases to be versioned and auditable.  
**AC:** Every export pack contains KB release tag; release notes list source changes and impacts.

### Epic G — GovData Governance

**US-G1** As a user, I want granular consent and easy withdrawal.  
**AC:** Separate toggles for product analytics vs de-identified research/GovData; default opt-out; withdrawal propagates.

**US-G2** As a government buyer, I want methodology notes and data dictionaries for every dataset.  
**AC:** Every GovData export includes dictionary, time window, suppression rules, limitations, and version.

---

## 6) Functional Requirements (FRs)

### Core App

**FR-1** Pathway Finder dynamic questionnaire + ranked pathway output.  
**FR-2** Evidence Checklist Engine personalised evidence map + coverage grid.  
**FR-3** Document Intelligence (Phase 2) OCR extraction + validation.  
**FR-4** Consistency Checks detect contradictions (dates, employers, addresses, relationship milestones).  
**FR-5** Explainable Risk Flags per category with triggers + recommended evidence (Flag Card format).  
**FR-6** Policy Monitoring updates + user impact alerts.  
**FR-7** Export Pack PDF + structured JSON bundle; user uploads manually.  
**FR-8** Audit Trails log every action (upload, edits, scoring, export) to protect users and company.

### Knowledge System (KB)

**FR-K1** Tiered Source Authority Model  
- Tier 0: FRL (Act/Regs/Instruments) controlling  
- Tier 1: Home Affairs guidance & reports supporting  
- Conflicts: show Tier 0 as controlling with explicit note.

**FR-K2** Structured Knowledge Objects  
- `Instrument`, `Requirement`, `EvidenceItem`, `FlagTemplate` objects with effective dates.

**FR-K3** Effective-Dating Versioning  
- No overwrites; new versions created with `effective_from` / `effective_to`.

**FR-K4** Ingestion + Diff + Review Pipeline  
- FRL lane (daily), Home Affairs lane (weekly), data.gov.au lane (weekly)  
- Diff emits `change_event` with impact scoring and review gating.

**FR-K5** Citation Enforcement + Staleness Warnings  
- Runtime must attach citations to criteria statements and show “Verified on” date.

**FR-K6** KB Release Management  
- Release tags (e.g., `kb-YYYY-MM-DD`), release notes, rollback/hotfix.

### DaaS (GovData)

**FR-D1** Data Contribution Framework  
Consent gating, purpose limitation, opt-out/withdraw, deletion propagation.

**FR-D2** De-identification & Statistical Disclosure Controls  
Direct identifier stripping, tokenisation, aggregation, cell suppression, minimum thresholds.

**FR-D3** Data Catalog + Data Dictionary  
Clear schema, definitions, lineage, and limitations (investor/government credibility).

**FR-D4** Data Delivery Modes  
Gov dashboard + scheduled CSV/Parquet extracts + secure API (optional), all with versioning.

**FR-D5** Evidence of Governance  
Model/rules version stamps; methodology notes; transformation audit logs; reproducible pipelines.

---

## 7) Data Strategy (what you collect + why)

### 7.1 User-provided data domains (sensitive)
Identity, immigration history, employment/skills, relationship details, supporting documents.

### 7.2 Derived product telemetry (GovData-relevant, aggregate-only)
- Journey-stage timestamps (where users drop off)
- Evidence-gap frequencies (by visa stream, by evidence category)
- Consistency-flag patterns (types and counts)
- Policy-change alert impacts (how many users affected; what requirements changed)
- “Readiness distribution” over time (aggregate)

### 7.3 Separation of concerns (must-have)
- **PII Vault (App Ops):** encrypted, user-controlled
- **Analytics Store (De-identified):** aggregated metrics only
- **GovData Warehouse:** curated datasets with strict disclosure controls

---

## 8) DaaS Product Definition (what government buys)

**GovData Package A — “Migration Friction Index”**  
Monthly/weekly: where applicants struggle (steps, evidence categories), segmented by broad visa stream and user cohort bands.

**GovData Package B — “Policy Change Impact Monitor”**  
When instruments change: quantified downstream effects on readiness gaps and confusion spikes.

**GovData Package C — “Triage & Surge Signals”**  
Leading indicators of demand spikes, common missing evidence, and time-to-readiness changes—supports proactive resourcing.

**GovData Package D — “Integrity Pattern Indicators”**  
Aggregated anomalies and “template-like” patterns (where safe) for investigation prioritisation—methodology transparent.

**Important positioning:** DaaS provides operational intelligence, not applicant profiling.

---

## 9) Knowledge Sources & Freshness (MVP requirement)

### 9.1 Source hierarchy
- Tier 0: FRL Act/Regs/Instruments (controlling)
- Tier 1: Home Affairs guidance pages + report families
- Tier 1: data.gov.au datasets for time-series program metrics

### 9.2 Ingestion cadence (baseline)
- FRL: daily
- Home Affairs: weekly
- data.gov.au: weekly

### 9.3 Review gates (high-impact)
Mandatory review before production if:
- instrument status changes (repeal/supersede)
- effective dates change
- keyword triggers: english/financial/occupation/specified work/exemptions
- dataset schema drift

---

## 10) Compliance, Safety, and Legal Posture (hard requirement)

- Must comply with Privacy Act/APPs: collect minimum data, explicit consent, access/correction/deletion, strong security.
- Data residency in Australia recommended; encryption at rest and in transit.
- Clear disclaimers: tool assists information + readiness; does not guarantee outcomes; avoids holding out as legal advice.
- Explainable AI, contestability, and bias mitigation are mandatory.
- Must refuse disallowed content (fraud/evasion/falsification) and offer safe alternatives.

**Required disclaimer snippet (short):**  
> KangaVisa provides information and application preparation assistance. It is not legal advice and does not guarantee outcomes. For advice, consult a registered migration agent or lawyer.

---

## 11) Non-Functional Requirements (NFRs)

- **Security:** Zero-trust + RBAC; no staff access to raw documents unless explicitly authorised; full audit trails.
- **Reliability:** resume later, robust uploads; support weak/spotty connections where feasible.
- **Explainability:** every risk flag shows triggers + user-editability; user can resolve with note.
- **Governance:** model/rules versioning; reproducible GovData pipelines; rollback/hotfix runbook.

---

## 12) KPIs (App + DaaS)

### App KPIs
- Time-to-readiness (median)
- Pack export rate
- Flag resolution rate
- Paid conversion rate
- NPS / Trust index

### GovData KPIs
- Number of opted-in contributors (by consent type)
- Dataset freshness (days)
- Government pilot retention / renewal
- Number of policy-change impact reports delivered

---

## 13) Roadmap

**MVP (0–6 months):** Pathway Finder, Checklist, Flags, Export Pack, Consent framework, basic aggregated dashboards, **KB ingestion/diff/release**.  
**Phase 2 (6–12 months):** OCR doc intelligence, employer module, advanced anomaly detection, curated GovData datasets.  
**Phase 3 (12–24 months):** formal partnership integrations if available; expanded GovData delivery modes.

---

## 14) Investor-quotable “hard requirements”

- Consent-first data contribution, granular and revocable.
- Strong de-identification + disclosure controls (no small cells, no re-identification risk).
- Clear data lineage and auditability of transformations (gov procurement essential).
- Separation of PII vault and analytics warehouse (security + credibility).
- Government-ready outputs: dictionary, methodology notes, versioning, and exports.
- KB releases are versioned and effective-dated; outputs cite Tier 0/1 sources.
- KangaVisa is a readiness tool, not legal advice; no outcome guarantees.

---

## 15) Engineering deliverables (explicit)

Repo artefacts are part of MVP acceptance:
- `kb/schema.sql`
- `kb/models/*.jsonschema`
- `kb/sources.yml`
- `kb/release_process.md`
- `kb/architecture.md`
- `kb/runbook.md`
- `kb/testcases.md`
- `DECISIONS.md`
