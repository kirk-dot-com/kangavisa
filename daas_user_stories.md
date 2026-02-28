# kb/daas_user_stories.md — GovData (DaaS) Use Cases & User Stories (Backlog Import)

**Last updated:** 2026-03-01  
**Purpose:** Provide Antigravity with backlog-ready DaaS epics/stories aligned to the KangaVisa PRD (FR-D1..FR-D5) and the KB ingestion work.

> **Non-negotiable:** GovData outputs are **aggregate-only**, consented, and disclosure-controlled. No individual-level profiling.

---

## A) DaaS Use Cases (GovData)

### UC9 — Migration Friction Index (MFI)
**Primary user:** Government ops/policy analyst  
**Trigger:** “Where do applicants get stuck and what evidence gaps are most common?”  
**Outcome:** Aggregated dashboard + exports by journey stage, broad visa group, and time window (small cells suppressed).  
**Value:** Better comms and triage targeting.

### UC10 — Policy Change Impact Monitor (PCIM)
**Primary user:** Government policy/ops  
**Trigger:** “Did a policy/instrument change increase confusion or readiness gaps?”  
**Outcome:** Aggregated impact reports linked to KB change events + release tags.  
**Value:** Faster feedback loop on policy change outcomes.

### UC11 — Surge & Congestion Signals (SCS)
**Primary user:** Government ops/service design  
**Trigger:** “Are we seeing surge demand or bottlenecks building?”  
**Outcome:** Aggregated intake velocity + stage congestion indicators.  
**Value:** Proactive resourcing and targeted comms.

### UC12 — Integrity Pattern Indicators (IPI) (aggregate-only)
**Primary user:** Government integrity / oversight  
**Trigger:** “Are certain inconsistency patterns rising at cohort level?”  
**Outcome:** Aggregated anomaly indicators with methodology + suppression.  
**Value:** Integrity prioritisation without profiling.

---

## B) Epic E — Consent, Analytics Separation, and Auditability (DaaS prerequisite)

### US-E1 — Consent toggles (granular + revocable)
**As a** user, **I want** to opt in/out of data contribution clearly and granularly, **so that** I control how my data is used.  
**Acceptance criteria**
- Separate toggles for:
  - (a) Product analytics (basic)
  - (b) De-identified research / GovData
- Default: opt-out for research/GovData
- Withdrawal supported and logged; change takes effect within a defined window (e.g., 7 days)
- Consent UI includes plain-language “what this means” text

### US-E2 — Consent event ledger (append-only)
**As an** admin, **I want** an append-only consent event ledger, **so that** consent history is auditable and reversible.  
**Acceptance criteria**
- Every change creates a `consent_event` row with user_id, event_type, timestamp, client metadata
- Current state can be derived deterministically (or maintained in `consent_state`)
- Supports “who/when/what changed” reporting

### US-E3 — PII vault vs analytics store separation
**As a** privacy officer, **I want** sensitive user documents separated from analytics, **so that** GovData cannot expose personal data.  
**Acceptance criteria**
- User documents stored only in private bucket + vault metadata table
- Analytics tables contain no direct identifiers (no name, DOB, passport, etc.)
- If linking is needed, use pseudonymous ids and restrict access

### US-E4 — De-identification and suppression rules baked-in
**As a** GovData publisher, **I want** disclosure controls applied automatically, **so that** exports are privacy safe.  
**Acceptance criteria**
- Configurable minimum cell size (e.g., k>=20)
- Automatic suppression of small cells
- Export blocked when thresholds violated
- Every export includes time window + suppression rules + version metadata

---

## C) Epic F — GovData Dataset Products (MVP = internal dashboards + export-ready)

### US-F1 — Migration Friction Index dataset
**As a** government buyer, **I want** aggregated friction signals by journey stage and broad visa group, **so that** I can target guidance and triage.  
**Acceptance criteria**
- Dataset includes: stage drop-off rates, median time-to-readiness, evidence gap rates, flag density
- Dimensions are coarse (broad visa group, stage, time window)
- Small-cell suppression enforced
- Exports available as CSV/Parquet; includes methodology + dictionary

### US-F2 — Policy Change Impact dataset
**As a** government buyer, **I want** change impact summaries tied to KB releases, **so that** I can see downstream effects of policy changes.  
**Acceptance criteria**
- Joins to `change_event` and `kb_release` identifiers
- Shows deltas pre/post change window (aggregate)
- No user-level drilldown
- Includes KB release tag and time window metadata

### US-F3 — Surge & congestion signals dataset
**As an** ops team, **I want** early-warning signals for surges, **so that** I can resource proactively.  
**Acceptance criteria**
- Intake velocity (WoW), stage congestion index (stuck > N days), unresolved high-severity flag ratio
- Weekly refresh
- Suppression applied
- Includes methodology and limitations

### US-F4 — Integrity pattern indicators (aggregate-only)
**As an** integrity analyst, **I want** aggregate inconsistency rates, **so that** I can prioritise integrity work without profiling individuals.  
**Acceptance criteria**
- Outputs only binned/aggregated rates (date mismatch rate, identity mismatch rate, etc.)
- No entity-level outputs
- Strict suppression + coarsening
- Methodology notes required

---

## D) Epic G — Ingestion-to-GovData Linkage (ties directly to Sprint 1)

### US-G1 — Ingestion writes source_document with provenance
**As a** KB operator, **I want** every snapshot stored with hash + timestamps + canonical URL, **so that** diffs and citations are reliable.  
**Acceptance criteria**
- `source_document` includes canonical_url, content_hash, retrieved_at, source_type, raw_blob_uri
- metadata_json includes dataset metadata_modified where applicable

### US-G2 — change_event generation with impact scoring + review gating
**As a** reviewer, **I want** change events scored and routed to review, **so that** high-impact changes are controlled.  
**Acceptance criteria**
- impact_score 0–100
- requires_review true at threshold (>=70)
- keyword boosts for english/financial/occupation/specified work/exemptions/repeal/schedule/regulation

### US-G3 — KB release tags
**As a** publisher, **I want** to group approved KB changes into a release tag, **so that** runtime behaviour is auditable.  
**Acceptance criteria**
- kb_release record includes change_event ids + source_doc ids
- Release notes capture summary + affected visas

### US-G4 — GovData linkage to KB releases
**As a** GovData consumer, **I want** datasets to cite KB version and time window, **so that** reports are reproducible.  
**Acceptance criteria**
- Every GovData export includes KB release tag, export run id, time window, suppression threshold
