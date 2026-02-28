# Unofficial Snapshot — Seed Patterns for Flags & Checklists (KB Input)

**Status:** SEC=UNOFFICIAL (working draft)  
**Last updated:** 2026-03-01  
**Use in KangaVisa:** Allowed as **starter themes** for `Requirement`, `EvidenceItem`, and `FlagTemplate` creation.  
**Hard rule:** No pattern becomes user-facing until it is linked to Tier 0/1 sources and effective-dated.

---

## 1) How to implement these seeds
For each seed below:
1. Create/confirm a `Requirement` object (structured rule node)
2. Create `EvidenceItem`s mapped to that requirement
3. Create a `FlagTemplate` with:
   - trigger (what is detected)
   - why it matters (plain language)
   - actions (3–5 steps)
   - evidence examples
4. Attach sources (Tier 0/1) and effective dates

---

## 2) Cross-category checklist seeds

### Evidence completeness
- **Checklist items:** identity docs, translations, consistency of names/dates
- **Flag seeds:** missing category, missing translation, missing issuer details, expired document

### Consistency & credibility
- **Checklist items:** unified timeline (study/work/residency/relationship)
- **Flag seeds:** date mismatch, unexplained gap, overlapping employment, address mismatch, name variation

### Integrity-safe guidance (non-accusatory)
- **Checklist items:** declare corrections, attach explanations, provide corroboration
- **Flag seeds:** inconsistent claims (prompt for clarification), unusual document metadata (aggregate-only, no accusations)

---

## 3) Visa-specific seeds (MVP 5)

### Student (500)
**Checklist seeds**
- Intent narrative aligned to study plan + career path
- Evidence of ties / circumstances (where relevant, and safely framed)
- Financial capacity evidence coherence

**Flag seeds**
- Generic or inconsistent intent statement
- Financial evidence inconsistency (unexplained deposits, missing account holder name)
- Timeline mismatch between education/employment and stated intent

### Temporary Graduate (485)
**Checklist seeds**
- Lodgement sequencing: completion evidence, police checks, identity docs, time windows
- English evidence currency (if required)

**Flag seeds**
- Timing risk: key doc missing at lodgement window
- Expired or mismatched evidence dates
- Identity mismatch across documents

### Employer sponsored (482 / SID/TSS settings)
**Checklist seeds**
- Nomination-ready pack: role description, contract, salary evidence, market rate rationale
- Employer compliance artefacts (as required)

**Flag seeds**
- Nomination evidence gap (role/salary/market evidence incomplete)
- Inconsistent contract details vs nomination details
- Missing employer identifiers or supporting docs

### Working Holiday Maker (417/462)
**Checklist seeds**
- Specified work tracking (dates, locations, employer details)
- Payslips and evidence continuity

**Flag seeds**
- Missing or inconsistent specified work evidence
- Date gaps that affect eligibility windows
- Employer details incomplete

### Partner (820/801 + 309/100)
**Checklist seeds**
- Evidence map across four pillars: financial, household, social, commitment
- Relationship timeline with key milestones
- Third-party corroboration where appropriate

**Flag seeds**
- Weak coverage across pillars (imbalanced evidence)
- Timeline gaps or contradictions (cohabitation/contact)
- Address mismatch across documents without explanation

---

## 4) Phase 2 seeds (not MVP-critical)
### Skilled points-tested (189/190/491)
- Points claim evidence mapping
- Skills assessment validity checks
- English result expiry checks
