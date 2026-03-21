# KangaVisa GovData Product PRD v1.0

## 1. Overview

**Product Name:** KangaVisa GovData  
**Type:** Migration Readiness Intelligence Platform (B2G / B2B)  
**Positioning:** De-identified, pre-lodgement behavioural intelligence for Australian visa systems  

KangaVisa GovData transforms aggregated user readiness signals into actionable insights for government departments, embassies, and policy stakeholders.

---

## 2. Problem Statement

Government stakeholders lack visibility into:

- Pre-application behaviour
- Evidence gaps before lodgement
- Early indicators of refusal risk
- Real-time shifts in traveller readiness

Existing datasets are:

- Lagging (post-decision)
- Administrative (not behavioural)
- Non-explanatory

---

## 3. Solution

KangaVisa GovData provides:

- Real-time readiness signals
- Aggregated behavioural insights
- Explainable risk patterns
- Policy-relevant analytics

All data is:

- De-identified
- Aggregated
- Consent-based

---

## 4. Target Users

### Primary
- Australian Government departments
- Policy analysts
- Immigration program managers

### Secondary
- Embassies & High Commissions
- Tourism bodies
- Aviation planners

---

## 5. Product Tiers

### Tier 1 — GovData Dashboard (Self-Serve)

Features:
- Country-level dashboards
- Visa subclass filtering
- Trend visualisations
- Export (CSV)

Pricing:
- $500–$1,500/month (Basic)
- $3k–$10k/month (Advanced)

---

### Tier 2 — Intelligence Reports

Features:
- Monthly briefings
- Country deep dives
- Policy impact analysis
- Risk pattern summaries

Pricing:
- $20k–$100k/year

---

### Tier 3 — GovData API

Features:
- Programmatic access
- Real-time metrics
- Integration-ready endpoints

Pricing:
- Enterprise ($50k–$250k+)

---

## 6. Core Datasets

### 6.1 Visitor Readiness Dataset

Fields:
- country
- age_band
- travel_history
- financial_confidence
- documentation_readiness
- top_flag
- readiness_score

---

### 6.2 Risk Indicator Dataset

Fields:
- visa_subclass
- flag_code
- frequency
- trend
- cohort breakdown

---

### 6.3 Demand & Behaviour Dataset

Fields:
- country
- user_volume
- growth_rate
- travel_pattern
- repeat_usage

---

## 7. Key Metrics

- Financial risk rate
- Documentation gap rate
- Intent risk proxy
- Readiness score (avg)
- Flag frequency

---

## 8. Core Features

### Dashboards
- Time-series trends
- Country comparison
- Risk heatmaps
- Funnel analysis

### Filtering
- Country
- Visa subclass
- Time window
- Demographics

### Export
- CSV
- API
- Scheduled reports

---

## 9. Privacy & Compliance

- No PII stored in GovData outputs
- Age stored as bands only
- Minimum cohort threshold enforced
- Explicit user consent required
- Full audit logging

---

## 10. Architecture

```text
User Intake
↓
visitor_intake_schema.json
↓
Supabase (cases + analytics_events)
↓
Aggregation layer
↓
GovData datasets
↓
Dashboards / API / Reports
```

---

## 11. Go-To-Market Strategy

### Phase 1 — Pilot
- 1–2 embassies
- 1 government department
- Free 90-day trial

### Phase 2 — Subscription
- Convert to dashboard access
- Introduce reporting

### Phase 3 — Expansion
- API integration
- Multi-visa datasets
- Cross-agency adoption

---

## 12. Success Metrics

- Number of government clients
- Dataset usage frequency
- API calls per client
- Report renewals
- Conversion from pilot → paid

---

## 13. Risks

| Risk | Mitigation |
|------|-----------|
| Privacy concerns | Strict aggregation + consent |
| Misinterpretation | Methodology transparency |
| Data bias | Large sample sizes + disclaimers |

---

## 14. Future Enhancements

- Predictive trend modelling
- Policy simulation tools
- Cross-visa lifecycle tracking
- Global expansion datasets

---

## 15. Core Value Proposition

KangaVisa GovData provides:

- Earlier signals than government data
- Behavioural insights, not just outcomes
- Explainable migration readiness intelligence

This enables better:

- Policy decisions
- Resource allocation
- Risk management

---

## 16. Strategic Position

KangaVisa GovData is not a reporting tool.

It is a:

**Migration Intelligence Layer sitting upstream of the visa system.**

---

## 17. What Government Actually Wants

Departments and embassies don't just want "data". They want:

| Need | Description |
|---|---|
| **Early signals** | Where are problems emerging before they show up in official stats? |
| **Explainability** | Why are applicants struggling? |
| **Actionability** | What should we do about it? |

Government already has visa applications, grant/refusal data, and processing times.

**They don't have:**

```text
Pre-application behaviour
Evidence gaps BEFORE lodgement
User confusion patterns
```

> This is KangaVisa's moat: **pre-lodgement intelligence.**

---

## 18. Example "Killer Dataset"

This is what sells the product:

```text
Visitor Visa Readiness Dataset — India (last 90 days)

Users: 12,430
Financial confidence: 62%
Documentation readiness: 48%
First-time travellers: 55%

Top flags:
  1. Financial evidence gap         28%
  2. No return travel booked        19%
  3. Weak travel purpose narrative  17%

Trend: financial risk ↑ increasing
```

This insight is **not available anywhere else.**

---

## 19. GovData API — Example Endpoints (Tier 3)

```text
GET /visitor/readiness?country=India
GET /flags/top?visa=600
GET /trend/financial-risk?window=90d
GET /cohort/first-time-travellers?country=PH
```

---

## 20. Two-Product Reinforcement Model

KangaVisa operates as two aligned products:

```text
Layer 1: Visa readiness tool (B2C)
         — generates data + user value

Layer 2: Migration intelligence platform (B2G)
         — monetises the signal layer
```

They reinforce each other. More users → richer data → more valuable GovData → better product → more users.

---

## 21. Recommended Rollout Path

### Phase 1 — Self-serve base (Sprint 31+)
Build aggregation from `visitor_intake` table. Internal dashboard only.

### Phase 2 — Pilot outreach
Offer free 90-day access to 1–2 embassies + 1 department.

### Phase 3 — Subscription conversion
Annual GovData dashboard subscriptions ($500–$10k/month).

### Phase 4 — Intelligence reports
Quarterly briefings for policy units ($20k–$100k/year).

### Phase 5 — API access
Enterprise contracts ($50k–$250k+), integrated into government analytics platforms.

---

## 22. Next Artefact → `govdata_dashboard_spec.md`

Defines:
- Exact dashboard screens
- Charts (5 core visualisations)
- Filters (country, visa subclass, time window)
- Data queries (against `visitor_intake` + future tables)
- UI layout (Antigravity-ready)

This is the piece that turns concept → buildable product UI.
