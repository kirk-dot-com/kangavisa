# Australian Visa System — 2024–25 Consolidated Data Snapshot (Unofficial Draft)

**Status:** SEC=UNOFFICIAL (internal working notes)  
**Prepared for:** KangaVisa KB + Product Context  
**Last updated:** 2026-02-23  
**Purpose:** Provide a structured, product-ready summary of high-level volume, pathway, complexity, and risk patterns to inform:
- Onboarding context cards (“How the system works”)
- Prioritised MVP visa scope rationale
- GovData (DaaS) metric design (friction, backlog proxies, policy volatility)
- Content/KB seed flags (non-determinative, readiness-focused)

> **Important:** Figures below are **as provided in internal notes** and must be verified against authoritative sources before publication. In KangaVisa, treat them as **context**, not “criteria”.

---

## 1) System-wide volume overview (program year 2024–25)

| Metric | Figure (as noted) | Notes / Use in product |
|---|---:|---|
| Total visa lodgements (all categories) | ~9.5 million | Context only; drives “why readiness matters” messaging |
| Final quarter lodgements (Apr–Jun 2025) | ~2.25 million | Indicates seasonal surges; use for GovData surge signals |
| Applications on hand (30 Jun 2025) | ~768,000 pending | Backlog proxy; supports “limbo” narrative |
| Permanent Migration Program cap (2025–26) | 185,000 places | Highlights capped permanent intake vs high-volume temporary |

### Structural observation (product-ready)
- Australia operates a **high-volume temporary** system with a **capped permanent** intake.
- Temporary visas dominate by scale.
- Permanent visas are quota-managed and competitive.

---

## 2) High-volume visa pathways (applications/holders)

> The Department does not publish a single consolidated subclass lodgement table in one view; rankings may mix lodgements, grants, and holder counts.

### 2.1 Top pathways (as noted)

1) **Visitor (600 and related)**
- ~5.27M applications (2023–24 reference year; note: not 2024–25)
- System role: tourism, business travel, family visits
- Typical risk theme: “genuine temporary intent” (readiness messaging only)

2) **Student (500)**
- ~261,368 lodgements (Jul 2024 – Feb 2025 partial year)
- ~736,000 holders (Sep 2025 peak reference)
- System role: international education export industry
- Typical risk theme: “genuine student” satisfaction

3) **Working Holiday Maker (417/462)**
- ~225,000 holders
- System role: youth mobility + regional labour support
- Complexity: lower eligibility complexity; documentation still matters

4) **Temporary Graduate (485)**
- ~225,000 holders
- System role: post-study transition pipeline
- Risk theme: timing + sequencing of documents (e.g., police checks at lodgement)

5) **Temporary Skilled (482 / SID/TSS settings)**
- ~238,000 holders (broad category)
- System role: employer-driven pathway
- Risk theme: nomination compliance + salary threshold alignment

6) **Bridging visas (various)**
- ~400,000+ holders
- System insight: transitional demand + processing delays proxy

7) **Skilled Independent (189)**
- 22,973 invitations issued (2024–25)
- Risk theme: points miscalculation + skills assessment

8) **Skilled Nominated (190)**

9) **Skilled Work Regional (491)**
- Skill stream total: 141,803 lodgements (2024–25)
- State nomination dependent; competitive thresholds

10) **Family & Partner (820/801 + 309/100)**
- ~93,241 Family visa lodgements (2024–25)
- ~68,105 Partner visa applications
- Risk theme: relationship evidence strength; persistent backlog

**Other notable:** **Protection (866)**
- 30,465 finalised (2024–25)
- 4,010 grants (13%)
- 25,018 refusals (82%)
- Insight: high refusal ratio vs other categories (context only)

---

## 3) Complexity classification matrix (product lens)

| Complexity | Examples | Structural features |
|---|---|---|
| 🟢 Simple | 600, 417 | Checklist-based, documentary, “genuine” satisfaction still key |
| 🟡 Moderate | 482, 485 | Employer / nomination or strict timing dependencies |
| 🔴 Complex | 189, 190, 491 | Points test + invitation + caps + external assessments |

**Key insight:** complexity increases where:
- points apply
- external assessments are required
- state nomination is involved
- caps restrict supply

---

## 4) Enduring systemic challenges (cross-category)

1) **Processing delays**  
Backlogs especially affect partner visas, skilled permanent visas, and protection visas.

2) **Policy volatility**  
Occupation lists, student caps, English/financial thresholds, priority directions.

3) **Discretionary assessments (“genuine” satisfaction)**  
Common in student, visitor, and partner.

4) **Evidence quality risk**  
Incomplete docs, financial inconsistency, skills assessment deficiencies, weak relationship evidence, false/misleading info.

---

## 5) Refusal landscape — common patterns (readiness framing)

### Student (500)
- Common refusal trigger theme: genuine student satisfaction
- Typical pattern: generic statements, weak career alignment, weak ties explanation

### Skilled (189/190/491/485)
- Common causes: points shortfall, invalid skills assessment, expired English results, sequencing errors
- Legal framework references appear in Tier 0 sources (Schedule 2 + Act powers)

### Partner (820/309)
- Common causes: insufficient evidence across four “pillars”: financial, household, social, commitment
- Also: sponsor ineligibility, character concerns

### Protection (866)
- Strict statutory criteria; high refusal ratio noted (context only)

---

## 6) Frequently cited legal concepts (KB pointers only)

> KangaVisa should not hard-code legal claims here. These are **pointers** for the KB team to map into Tier 0 citations (FRL).

- Act refusal power: “delegate not satisfied criteria met”
- Character test provisions
- “Genuine” criteria clauses (student/visitor themes)
- Employer nomination requirements themes
- Public Interest Criteria (health, character, false information)

---

## 7) Processing speed hierarchy (generalised)

- **Fastest:** Visitor (often days–weeks)
- **Mid-range:** Student (weeks–months)
- **Longer:** Skilled permanent (months–1+ year), Partner (> 1 year often)
- **Longest:** Appeals (multi-year)

> Use as a UX expectation-setting card; avoid promising timeframes.

---

## 8) Structural pattern summary (UI-ready)

Australia operates a:
- High-volume temporary entry system  
+ a highly competitive, capped permanent program  
+ a discretion-heavy satisfaction model

Outcomes depend less on “meeting a checklist” and more on:
- evidence quality
- timing/sequence
- competitiveness (points/caps)
- policy environment
- discretionary satisfaction

---

## 9) Risk-mitigation patterns (safe guidance, non-advice)

- Over-document rather than under-document (within reason)
- Align narrative logic tightly (e.g., study/career coherence)
- Triple-check objective claims (points, dates, work history)
- Use structured relationship evidence (partner)
- Respond quickly to RFIs
- Address health/character proactively
- Seek professional review for complex categories

---

## 10) Verification checklist (before public use)

For each metric above, store:
- `source_url`
- `publisher`
- `published_at`
- `retrieved_at`
- `method_notes` (lodgements vs grants vs holders)

In KangaVisa, these belong in:
- `source_document` snapshots (Tier 0/1/Datagov)
- KB release notes for changes affecting user-facing content
