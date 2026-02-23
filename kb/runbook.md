# kb/runbook.md — KangaVisa KB Operations Runbook v0.1

**Last updated:** 2026-02-22  
**Goal:** Keep the KangaVisa knowledge base accurate, versioned, and safe, with clear procedures for incidents and hotfixes.

---

## 1) Daily/Weekly Ops

### Daily (automated)
- FRL lane: fetch + snapshot + diff
- Create `change_event` records for all detected changes
- Alert if:
  - Crawl failures > 5% for Tier 0
  - Any FRL instrument status changes (repealed/superseded)
  - Any effective date changes

### Weekly (automated)
- Home Affairs pages + report links: fetch + diff
- data.gov.au datasets: metadata check + resource snapshot + schema validation

### Weekly (human)
- Triage review queue:
  - sort by `impact_score desc`
  - ensure high-impact changes are reviewed and either published or explicitly deferred

---

## 2) Alert categories and actions

### A) FRL instrument repealed/superseded (SEV-1)
**Trigger:** instrument status change detected OR successor identified  
**Immediate actions (within same day):**
1. Identify affected visas/requirements (via mapping)
2. Create updated Requirement/Evidence versions with correct effective dates
3. Run schema validation + safety lint + smoke tests
4. Publish hotfix release tag (see Section 4)

**User-facing behaviour until fixed:**
- If uncertainty exists, show warning: “A policy instrument changed recently; re-verify before lodging.”

### B) Effective date shifts (SEV-1/2)
**Trigger:** effective_from/to changed or chain updated  
**Actions:**
- Update effective ranges, never overwrite
- Ensure runtime selection chooses correct version for the user case date

### C) Home Affairs guidance changed (SEV-2)
**Trigger:** guidance page diff  
**Actions:**
- Update operational basis and evidence examples
- If it contradicts Tier 0, add a note and keep Tier 0 controlling

### D) Dataset schema drift (SEV-2)
**Trigger:** new columns, renamed columns, missing expected fields  
**Actions:**
- Pause GovData exports for affected dataset
- Update transform mappings and validation tests
- Publish dataset-specific release note

### E) Crawl failures (SEV-3)
**Trigger:** repeated timeouts, 403/429, or parsing breaks  
**Actions:**
- Backoff + retry
- Rotate user agent and respect robots policies
- Switch to alternative endpoints when available (but keep sources official)

---

## 3) Rollback procedure
If a KB release introduces incorrect structured objects:

1. Identify the bad release tag (`kb_release.release_tag`)
2. Promote the previous release tag as “current”
3. Mark the bad release as “withdrawn” in release notes
4. Add a `change_event` of type `text_change` with summary “Rollback”
5. Re-run smoke tests

---

## 4) Hotfix procedure
Hotfixes are allowed only for:
- incorrect citations
- incorrect effective dates
- urgent new/repealed instruments impacting MVP visas

Steps:
1. Create branch `hotfix/<release-tag>-<short>`
2. Patch structured objects with new versions and citations
3. Run:
   - JSON Schema validation
   - Safety lint
   - Smoke tests (kb/testcases.md)
4. Tag release:
   - `kb-YYYY-MM-DDa` or `vX.Y.(Z+1)`
5. Publish and record in `kb_release` + release notes

---

## 5) Staleness policy
- Tier 0 FRL: warning if last snapshot > 14 days old (should not happen)
- Tier 1 Home Affairs: warning if last snapshot > 30 days old
- Datasets: warning if no updates detected in expected cadence (informational)

Runtime should surface staleness as:
> “Verified on: <date>. This source may have changed since then.”

---

## 6) Security and access
- Raw user documents: restricted access, audited
- KB snapshots: immutable, read-only after ingestion
- Reviewer permissions: role-gated (content reviewer vs approver)
- GovData exports: only from de-identified warehouse with disclosure controls enforced

---

## 7) Operational metrics (minimum)
- ingestion_success_rate (by lane)
- diffs_detected_per_week
- review_queue_age_p95
- releases_per_month
- dataset_schema_drift_incidents
- staleness_warnings_triggered
