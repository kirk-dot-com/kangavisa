# KangaVisa GovData Dashboard Specification v1.0

## 1. Purpose

Defines the UI, components, data queries, and layout for the GovData dashboard.

Audience:
- Antigravity (build)
- Product / Strategy
- Government stakeholders (demo-ready)

---

## 2. Dashboard Overview

The GovData dashboard is a **multi-panel intelligence interface** showing:

- Visitor readiness signals
- Risk indicators
- Demand trends
- Behavioural insights

Primary design principle:
**Clarity over complexity**

---

## 3. Core Dashboard Screens

## 3.1 Executive Summary (Landing)

### Components

**Header KPIs**
- Total users (selected period)
- Avg readiness score
- Financial risk rate
- Documentation gap rate

**Trend Line (Time Series)**
- Metric: total users OR readiness score
- Time: last 12 months

**Top Countries (Bar Chart)**
- Metric: user volume

**Top Risk Flags (List)**
- Ranked by frequency

---

## 3.2 Country Deep Dive

### Filters
- Country (required)
- Time range
- Visa subclass (default: 600)

### Components

**Country Snapshot**
- Users
- Readiness score
- Top risk

**Risk Breakdown (Stacked Bar)**
- Financial
- Documentation
- Intent proxy

**Trend Analysis**
- Risk rate over time

**Cohort Table**
| Age Band | Users | Risk Rate |

---

## 3.3 Risk Intelligence Screen

### Components

**Top Flags Table**
| Flag | Frequency | Trend |

**Heatmap**
- Country vs Flag

**Trend Chart**
- Flag frequency over time

---

## 3.4 Demand & Behaviour Screen

### Components

**Visitor Volume Trend**

**Travel Behaviour Breakdown**
- First-time vs repeat travellers

**Trip Duration Distribution**

---

## 3.5 Funnel View

### Components

```text
Users
↓
Completed intake
↓
Email captured
↓
Checklist generated
↓
Exported pack
```

Metrics:
- Conversion %
- Drop-off points

---

## 4. Filters (Global)

- Time range (7d / 30d / 90d / custom)
- Country
- Visa subclass
- Age band

---

## 5. Data Queries (Examples)

### Total Users
```sql
SELECT COUNT(*) FROM analytics_events WHERE event_type = 'intake_complete';
```

### Financial Risk Rate
```sql
SELECT COUNT(*) FILTER (WHERE financial_confidence IN ('no','not_sure')) / COUNT(*)
FROM intake_data;
```

### Top Flags
```sql
SELECT flag_code, COUNT(*) 
FROM flag_events 
GROUP BY flag_code 
ORDER BY COUNT(*) DESC;
```

---

## 6. UI Layout (Grid)

- 12-column grid
- Cards (modular)
- Max width: 1200px

---

## 7. Export Features

- CSV download
- PDF report
- API endpoint link

---

## 8. Access Levels

### Basic
- Summary dashboard
- Limited filters

### Advanced
- Full dashboards
- Export capability

### Enterprise
- API access
- Custom datasets

---

## 9. Design Rules

- No personal data shown
- All charts labelled clearly
- Include methodology notes
- Minimum cohort threshold (e.g. n > 50)

---

## 10. Success Criteria

- Users can identify top risks within 10 seconds
- Government users can extract insights without training
- Data is trusted and explainable

---

## 11. Future Enhancements

- Forecasting models
- Policy simulation tools
- Cross-visa comparisons

---

## 12. Summary

The GovData dashboard is designed to be:

- Fast
- Explainable
- Policy-relevant

It transforms KangaVisa into a **migration intelligence platform**, not just a product.
