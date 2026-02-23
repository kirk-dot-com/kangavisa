# kb/release_process.md — KangaVisa Knowledge Base (KB) Release Process v0.1

This document defines **how KangaVisa sources, validates, versions, and releases** its immigration knowledge base.
It is designed for **trust**, **auditability**, and **safe behaviour** (readiness assistance, not legal advice).

---

## 1) Guiding principles (non-negotiable)

1. **Tiered authority**
   - **Tier 0 (FRL)** controls: Migration Act/Regs and legislative instruments.
   - **Tier 1 (Home Affairs)** informs operational guidance and evidence examples.
   - If Tier 1 conflicts with Tier 0, Tier 0 wins.

2. **Effective dating is first-class**
   - Every Requirement/Evidence/Flag that depends on law/instruments must have `effective_from` and `effective_to` (nullable).
   - Never overwrite rules without preserving history.

3. **Citations required**
   - Any factual criterion shown to users must be traceable to a source record (URL + citation reference).

4. **Readiness, not advice**
   - KB content must never encode “approval likelihood” or determinations.
   - Rules produce **Flags** and **Checklist items**, not pass/fail outcomes.

---

## 2) Artefacts under version control

Track these in Git:
- `kb/models/*.jsonschema` (schemas)
- `kb/requirements/**/*.json|yaml` (structured rules)
- `kb/evidence/**/*.json|yaml`
- `kb/flags/**/*.json|yaml`
- `kb/sources.yml` (watch list)
- `kb/releases/RELEASE_NOTES.md` (append-only)

Raw source snapshots (HTML/PDF/CSV) should live in object storage, referenced by `source_document.raw_blob_uri`.

---

## 3) Release tags & versioning

Use **calendar tags** for operational releases and **semver** for breaking schema/content changes.

### 3.1 KB Release Tags (recommended default)
- `kb-YYYY-MM-DD` (e.g., `kb-2026-02-22`)

### 3.2 SemVer (when needed)
- `vMAJOR.MINOR.PATCH`
  - **MAJOR**: schema breaking change (fields renamed/removed)
  - **MINOR**: new visa stream, new requirement categories, new ingest lane
  - **PATCH**: corrections, new instruments, new evidence examples, typo fixes

---

## 4) Ingestion → Diff → Review → Publish pipeline

### Step A — Ingest
Sources are fetched according to `kb/sources.yml` polling policy.

**Outputs**
- New `source_document` snapshot(s)
- Parsed metadata (FRL effective dates/status; dataset updated timestamps)

### Step B — Diff
Run diffs against the most recent snapshot per canonical URL.

**Diff types**
- **Metadata diff (high-impact)**: effective date changes, status (repealed/superseded), new version chain
- **Text diff (medium-impact)**: clause-level or section-level changes in the content body
- **Dataset diff (medium-impact)**: new rows/periods, schema drift, resource list changes

**Outputs**
- `change_event` rows with:
  - change_type
  - impact_score
  - affected visa ids
  - requires_review flag

### Step C — Review gates
A change event requires human review if any of these are true:
- FRL instrument status changed (in_force → repealed/superseded)
- Effective dates changed
- Keywords matched: english / financial / occupation / specified work / exemptions
- Dataset schema drift detected
- Impact score >= threshold (default: 70)

**Reviewer actions**
- Confirm the controlling source
- Update structured Requirements/Evidence/Flags
- Add or update citations
- Write a release note entry

### Step D — Publish (promote to production)
A KB release can be published when:
- All required reviews are completed
- Schema validations pass (JSON Schema)
- Smoke tests pass (see Section 6)
- Release notes are updated

---

## 5) Quality gates (tests)

### 5.1 Schema validation (must pass)
- Validate each `Requirement/Evidence/Flag/Instrument` against the JSON Schemas.

### 5.2 Referential integrity (must pass)
- Every EvidenceItem references a valid Requirement.
- Every FlagTemplate references a valid Visa subclass.
- Every Requirement has at least one Tier 0 or Tier 1 source.

### 5.3 Content safety lint (must pass)
Block any KB text containing determinative/unsafe language such as:
- “guarantee”, “approved”, “definitely eligible”, “certainty”
- “how to evade”, “how to fake”, “forge”, “fabricate”

### 5.4 Retrieval smoke tests (must pass)
For each supported visa subclass, run 5–10 golden prompts and verify:
- Output includes assumptions
- Output includes citations (Tier 0/1 references)
- Output uses “flag/risk indicator” language (no determinations)

---

## 6) Emergency fixes (hotfix policy)

Use hotfixes only for:
- Mis-citations
- Clear factual errors in a requirement/evidence checklist
- A new instrument that immediately changes a core requirement

Hotfix steps:
1. Create branch `hotfix/kb-YYYY-MM-DD-<short>`
2. Patch structured objects + citations
3. Run schema + lint + smoke tests
4. Publish as `kb-YYYY-MM-DDa` (or semver PATCH)

---

## 7) Audit trail expectations (gov-ready)

Each release should preserve:
- A list of changed sources (source_doc_ids)
- A list of change events included
- Summary of user-visible impact
- Effective dates and whether prior rules remain applicable

Maintain an append-only `kb/releases/RELEASE_NOTES.md` with entries:
- Release tag
- Date/time
- Summary of changes
- Affected visas
- Reviewer name/role
- Links to source documents (URLs) and internal IDs

---

## 8) Suggested thresholds (defaults)

- Home Affairs guidance staleness warning: **30 days**
- FRL staleness warning: **14 days** (in practice you ingest daily)
- Minimum cell size for GovData exports: **k >= 20** (adjust per your disclosure policy)
- High-impact diff threshold: **impact_score >= 70**

---

## 9) Definition of Done for KB release

A KB release is “done” when:
- All diffs processed and reviewed as required
- All structured content validates and passes safety lint
- All smoke tests pass
- Release notes written
- Release tag created and promoted
