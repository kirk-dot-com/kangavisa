# Unofficial Snapshot — GovData (DaaS) Metric Hypotheses (Design Input)

**Status:** SEC=UNOFFICIAL (working draft)  
**Last updated:** 2026-03-01  
**Use in KangaVisa:** Allowed as internal hypotheses to design GovData datasets and dashboards.  
**Hard rule:** GovData outputs are aggregate-only, consented, and disclosure-controlled (no profiling).

---

## 1) Hypothesis set A — Friction occurs at predictable stages
**Hypothesis:** Users most commonly stall at:
- evidence upload
- resolving inconsistencies (flags)
- completing a coherent narrative (where “satisfaction” criteria apply)

**Design implications**
- instrument “journey stages” in the app
- publish aggregated drop-off by stage and time-to-readiness

**Candidate metrics**
- Drop-off rate by stage (7/14/30-day windows)
- Median time-to-readiness
- Evidence gap rate (missing high-priority items)
- Flag density distribution (median, p90)

---

## 2) Hypothesis set B — Policy changes cause measurable “confusion spikes”
**Hypothesis:** After policy/instrument changes, users see:
- increased edits
- increased help/FAQ usage
- higher flag counts in impacted requirement categories

**Design implications**
- tie app analytics to KB `change_event` and KB release tags
- publish aggregated “change impact” counts

**Candidate metrics**
- Users impacted by a KB change (aggregate)
- Checklist churn per KB release (added/changed items)
- Help events per user after change windows
- Re-run readiness check frequency after alerts

---

## 3) Hypothesis set C — Evidence quality is the dominant avoidable risk
**Hypothesis:** The highest yield improvements come from:
- completeness (missing categories)
- consistency (date mismatches/gaps)
- coherence (alignment between claims and evidence)

**Design implications**
- track evidence coverage and flag resolution rates
- publish aggregated top gap categories (by broad visa stream)

**Candidate metrics**
- Top 10 evidence gap categories (aggregate)
- Flag resolution rate (by category)
- Exported packs with unresolved high-severity flags (proxy for RFI risk)

---

## 4) Hypothesis set D — “Surge signals” are detectable
**Hypothesis:** Demand spikes can be detected by:
- intake velocity changes
- congestion in specific stages
- increased unresolved flags

**Candidate metrics**
- Week-on-week intake velocity
- Stage congestion index (users stuck > N days)
- Unresolved high-severity flag ratio

---

## 5) Integrity indicators (strictly aggregate)
**Hypothesis:** Certain inconsistency patterns rise/fall with policy settings and cohort changes.

**Constraints**
- No individual-level outputs
- Minimum cell size (e.g., k>=20) + suppression
- Publish methodology + caveats

**Candidate metrics**
- Date mismatch flag rate (aggregate)
- Identity mismatch flag rate (aggregate)
- “Unusual pattern” heuristic rate (binned; aggregate)

---

## 6) Required metadata for every GovData release
- Time window + cohort definitions
- KB release tag used
- Suppression thresholds
- Data dictionary and limitations
