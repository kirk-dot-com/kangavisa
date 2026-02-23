# GovData Metric Mapping — From “System Snapshot” to DaaS Datasets (MVP Design)

**Last updated:** 2026-02-23  
**Purpose:** Turn the snapshot themes (volume, backlog proxies, evidence risk, volatility) into privacy-safe GovData (DaaS) outputs.

> GovData provides **aggregated operational intelligence**, not applicant profiling. All outputs must apply disclosure controls (e.g., minimum cell size, suppression).

---

## 1) Dataset family: Migration Friction Index (MFI)

### Core concept
Measure *where users get stuck* and *what evidence gaps are most common* by:
- visa stream (broad)
- journey stage (intake → checklist → upload → resolve flags → export)
- cohort bands (high-level only)

### Suggested tables (analytics warehouse)
- `mfi_journey_events_daily`
- `mfi_evidence_gaps_daily`
- `mfi_flags_daily`

### Key metrics
- **Drop-off rate by stage**: % of users not progressing to next stage within X days
- **Time-to-readiness**: median days from first intake to export
- **Evidence gap rate**: % of packs with ≥1 missing “high priority” evidence item
- **Flag density**: median flags per pack (by category)

---

## 2) Dataset family: Policy Change Impact Monitor (PCIM)

### Core concept
When Tier 0/1 sources change, quantify downstream product impacts:
- number of affected active users (aggregate)
- which requirement categories changed
- which checklists/flags increased after change

### Inputs
- KB `change_event` stream (from ingestion/diff)
- KB release tags
- aggregated user journeys (consented)

### Outputs
- **Change impact counts**: users impacted by rule updates (aggregate)
- **Confusion spikes**: increase in “help” events or repeated edits after change
- **Checklist churn**: evidence items added/changed per release

---

## 3) Dataset family: Triage & Surge Signals (TSS)

### Core concept
Early-warning signals for demand spikes and bottlenecks (product-side), aligned to the “high volume” system narrative:
- week-on-week changes in new intakes
- stage congestion (users stuck at upload or unresolved flags)

### Key metrics
- **Intake velocity**: new intakes/week by broad visa group
- **Congestion index**: ratio of users stuck > N days in a stage
- **RFI preparedness proxy**: % packs exported with unresolved high-severity flags

---

## 4) Dataset family: Integrity Pattern Indicators (IPI) — aggregated only

### Core concept
Publish only high-level anomaly indicators (no dossiers; no individual profiling):
- repeated inconsistencies by category
- template-like document pattern signals at aggregate level (if used)
- mismatch rates across common fields (names/dates)

### Strict constraints
- No entity-level outputs
- No small-cell releases
- Transparent methodology notes + caveats

### Key metrics
- **Inconsistency rate**: % packs with date mismatch flags
- **Identity mismatch rate**: % packs with name/DOB mismatch flags
- **Unusual pattern rate**: % packs triggering anomaly heuristics (binned; broad)

---

## 5) Disclosure controls and publication rules (must implement)
- Minimum cell size: configurable (e.g., k>=20)
- Suppress and/or coarsen dimensions to prevent re-identification
- Publish methodology + dictionary with every export
- Audit log: transformations, suppression rules, and release tag

---

## 6) Mapping to PRD requirements
- FR-D1: Consent gating, opt-out default, withdrawal propagation
- FR-D2: De-identification + disclosure controls
- FR-D3: Dictionary + lineage
- FR-D4: Delivery modes (dashboard + exports)
- FR-D5: Governance evidence (versioning + audit logs)
