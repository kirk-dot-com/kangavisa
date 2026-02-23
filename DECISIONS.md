# DECISIONS.md — KangaVisa Key Decisions (Snapshot)

**Last updated:** 2026-02-22

## Product scope
- MVP visas: **500, 485, 482 (SID/TSS settings), 417/462, 820/801 + 309/100**

## Core positioning
- **Readiness, not advice**
- No application submission to Home Affairs
- No approval prediction or eligibility determinations

## Knowledge model
- Tiered authority:
  - Tier 0: FRL (Act/Regs/Instruments)
  - Tier 1: Home Affairs guidance and reports
- **Structured-first retrieval** using Requirement/Evidence/Flag objects
- **Effective dating** for all structured objects; no overwrites

## KB ops
- Watch lists in `kb/sources.yml`
- Ingestion lanes: FRL daily, Home Affairs weekly, data.gov.au weekly
- Diffs create `change_event` with impact scoring
- High-impact changes require human review before release

## DaaS / GovData
- Consent-first, opt-out by default unless explicitly changed
- Strict separation: PII vault vs analytics warehouse
- Disclosure controls: minimum cell sizes + suppression
- Methodology + data dictionary with every GovData output

## Runtime safety
- Mandatory disclaimer on risk/flags/export
- Refuse fraud/evasion requests
- Citation enforcement for criteria statements
