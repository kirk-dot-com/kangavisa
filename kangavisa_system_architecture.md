# KangaVisa — System Architecture

> **Version:** 1.0 · **Date:** 2026-03-09  
> *Technical blueprint for product, infrastructure, and GovData pipeline.*

---

## Overview

KangaVisa is a visa readiness platform structured as a GovTech-grade decision-support system. It ingests authoritative legal sources, classifies evidence against structured requirements, runs a deterministic risk flag engine, and produces readiness scores and export packs — without predicting visa outcomes.

---

## System Layers

```
╔══════════════════════════════════════════════════════════════════╗
║                        USER (Browser)                           ║
║                                                                  ║
║   /pathway → /checklist/[subclass] → /flags → /export           ║
║   PathwayQuiz · ChecklistController · AskBar · Scorecard         ║
╚══════════════════════╦═══════════════════════════════════════════╝
                       ║ HTTPS
╔══════════════════════╩═══════════════════════════════════════════╗
║                  NEXT.JS APP (app/)                              ║
║                                                                  ║
║  Server Components + API Routes                                  ║
║  ├── /api/ask          → LLM AskBar (OpenAI gpt-4o-mini)        ║
║  ├── /api/export/pdf   → ExportPDFDocument                       ║
║  ├── /api/export/docx  → buildDocx()                             ║
║  ├── /api/export/csv   → buildCsv()                              ║
║  └── /api/auth/*       → Supabase Auth + consent                 ║
║                                                                  ║
║  Client Islands                                                  ║
║  ├── PathwayQuiz       → visa selection                          ║
║  ├── ChecklistController → evidence state                        ║
║  ├── AskBar            → SSE streaming LLM                       ║
║  ├── ReadinessScorecard → weighted score display                 ║
║  ├── FlagCard          → flag_templates.json content             ║
║  ├── OnboardingModal   → first-visit UX                          ║
║  └── DaaSConsentBanner → GovData opt-in                          ║
╚══════════════════════╦═══════════════════════════════════════════╝
                       ║ supabase-js (RLS enforced)
╔══════════════════════╩═══════════════════════════════════════════╗
║                   SUPABASE (Database + Auth + Storage)           ║
║                                                                  ║
║  KB Tables (knowledge layer)                                     ║
║  ├── visa_subclass         subclass codes + metadata             ║
║  ├── requirement           atomic requirement nodes              ║
║  ├── evidence_item         checklist entries per requirement      ║
║  ├── flag_template         visa-specific flag cards              ║
║  ├── source_document       raw legal source snapshots            ║
║  ├── instrument            FRL legislative instruments           ║
║  ├── change_event          detected diffs from watchers          ║
║  └── kb_release            tagged KB snapshot versions           ║
║                                                                  ║
║  Case Tables (user data layer)                                   ║
║  ├── cases                 one case per user per visa            ║
║  ├── documents             uploaded evidence files               ║
║  ├── timeline_events       normalised personal timeline          ║
║  ├── flag_events           triggered flags per case              ║
║  ├── case_scores           computed readiness score              ║
║  └── case_exports          generated PDF/DOCX/ZIP records        ║
║                                                                  ║
║  Analytics / DaaS          (RLS + consent-gated)                 ║
║  ├── analytics_event       product event stream                  ║
║  ├── consent_state         per-user DaaS opt-in                  ║
║  └── consent_event         consent audit log                     ║
║                                                                  ║
║  Auth: Supabase Auth (JWT) · RLS on all tables                   ║
║  Clients: supabase.ts (publishable) · supabase-admin.ts (secret) ║
╚══════════════════════╦═══════════════════════════════════════════╝
                       ║ httpx + Supabase REST API
╔══════════════════════╩═══════════════════════════════════════════╗
║                   PYTHON WORKERS (workers/)                      ║
║                                                                  ║
║  ├── frl_watcher.py        legislation.gov.au daily fetch        ║
║  ├── homeaffairs_watcher.py immi.homeaffairs.gov.au weekly       ║
║  ├── datagov_watcher.py    data.gov.au weekly                    ║
║  └── run_watchers.py       combined entrypoint                   ║
║                                                                  ║
║  Pattern: fetch → hash → diff → write source_document            ║
║           + change_event rows to Supabase                        ║
║                                                                  ║
║  Scheduled: GitHub Actions cron (Mon 06:00 AEST)                 ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## Rules Engine Pipeline

```
User Input (checklist state + timeline + documents)
              ↓
   Evidence Classifier
   (evidence_item rows → coverage ratio)
              ↓
   Timeline Builder
   (gap detection → largest_timeline_gap_days)
              ↓
   Flag Detection Engine
   ┌─────────────────────────────────────────┐
   │  kb/rules/flag_detection_rules.json     │
   │  32 deterministic rules (R001–R032)     │
   │  Input fields → flag_code triggered     │
   └─────────────────────────────────────────┘
              ↓
   Flag Lookup
   ┌─────────────────────────────────────────┐
   │  kb/seed/flag_templates.json            │
   │  22 cross-visa flags                    │
   │  why_it_matters · suggested_actions     │
   └─────────────────────────────────────────┘
              ↓
   Visa Priority Weighting
   ┌─────────────────────────────────────────┐
   │  kb/seed/subclass_flag_mapping.json     │
   │  priority_categories vs secondary       │
   │  per visa subclass                      │
   └─────────────────────────────────────────┘
              ↓
   Readiness Scoring
   ┌─────────────────────────────────────────┐
   │  kb/rules/readiness_scoring_model.json  │
   │                                         │
   │  score = (evidence_coverage × 0.35)     │
   │        + (timeline_completeness × 0.20) │
   │        + (consistency × 0.20)           │
   │        + (risk_flags × 0.25)            │
   │                                         │
   │  Bands: Excellent ≥85 · Good ≥70        │
   │         Needs work ≥50 · Early <50      │
   └─────────────────────────────────────────┘
              ↓
   ┌─────────────────┬──────────────────┐
   │   Dashboard     │   Export Pack    │
   │  Scorecard UI   │  PDF · DOCX · CSV│
   └─────────────────┴──────────────────┘
```

---

## KB Knowledge Layer

```
legislation.gov.au          immi.homeaffairs.gov.au      data.gov.au
      ↓ (daily)                   ↓ (weekly)               ↓ (weekly)
  frl_watcher              homeaffairs_watcher          datagov_watcher
      ↓                           ↓                           ↓
                     source_document (snapshot + hash)
                              ↓ diff
                         change_event
                              ↓ review gate
                     KB Team review + sign-off
                              ↓
                     kb_release (tagged snapshot)
                              ↓
              requirement · evidence_item · flag_template
                    (effective-dated, citation-backed)
```

---

## Canonical Case Object

Defined in `kb/schema/case_schema.json`. Every system component reads/writes to this shape:

| Entity | Key fields |
|---|---|
| `case` | case_id, user_id, visa_subclass, case_status |
| `documents` | document_type, file_storage_path, language, translation_present |
| `timeline` | event_type, start_date, end_date, country |
| `flags` | flag_code, rule_id, severity, status, resolved_by_user |
| `score` | readiness_score, evidence_coverage, unresolved_flags_count |
| `exports` | export_type, file_path, generated_at |

---

## MVP Visa Pathways

| Subclass | Role | Primary risk categories |
|---|---|---|
| 600 — Visitor | Free acquisition funnel | intent · home_ties · financial_capacity |
| 500 — Student | Global volume | intent · financial_capacity · consistency |
| 485 — Temp Graduate | Pipeline from 500 | eligibility · timing · evidence_completeness |
| 189/190/491 — Skilled | High complexity | eligibility · evidence_completeness · consistency |
| 820/801 — Partner | Highest stakes | evidence_completeness · consistency · integrity |

---

## GovData (DaaS) Pipeline

```
analytics_event (flag_triggered, checklist_viewed, score_computed)
              ↓ consent_state check (opt-in required)
              ↓ de-identification
   Aggregated insights dataset:
   ├── visa_subclass
   ├── average_readiness_score
   ├── top_flag_by_frequency
   ├── financial_flag_rate
   └── timeline_gap_rate
              ↓
   GovData API / dashboard export
   → Policy intelligence for Home Affairs, migration researchers
```

---

## Key Files Reference

| Category | File | Purpose |
|---|---|---|
| DB schema | `kb/schema.sql` | KB knowledge layer DDL |
| DB schema | `kb/migrations/case_schema_v1.sql` | Case layer DDL + RLS |
| Case model | `kb/schema/case_schema.json` | Canonical case object |
| Rules | `kb/rules/flag_detection_rules.json` | R001–R032 trigger rules |
| Rules | `kb/rules/readiness_scoring_model.json` | Score formula + bands |
| Seed | `kb/seed/flag_templates.json` | 22 cross-visa flags |
| Seed | `kb/seed/subclass_flag_mapping.json` | Per-subclass flag priority |
| Seed | `kb/seed/visa_600_*.json` | Visitor visa seed (req/ev/flags) |
| App | `app/lib/export-builder.ts` | Score + export logic |
| App | `app/app/components/ReadinessScorecard.tsx` | Score UI |
| App | `app/app/components/FlagCard.tsx` | Flag card UI |
| Workers | `workers/kangavisa_workers/frl_watcher.py` | FRL ingestion |
| Config | `kb/sources.yml` | Watcher URL priority list |
