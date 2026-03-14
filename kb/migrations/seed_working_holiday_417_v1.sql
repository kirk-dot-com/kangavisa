-- =====================================================================
-- KangaVisa Knowledge Base — Sprint 21
-- seed_working_holiday_417_v1.sql
-- =====================================================================
-- Seeds requirements, evidence items, and flag templates for:
--   417 (Working Holiday visa)
--
-- Source JSON files:
--   kb/seed/visa_417_requirements.json   (3 requirements)
--   kb/seed/visa_417_evidence_items.json (4 evidence items)
--
-- Key 417 characteristics:
--   • Once-in-a-lifetime for most nationalities (unless 2nd/3rd grant)
--   • 2nd grant requires 88 days specified work in a regional area
--   • 3rd grant requires 179 days (or 6 months in specified sector)
--   • Minimum savings threshold (~AUD $5,000 — verify current figure)
--   • Age limit: 18–30 (some nationalities 18–35)
--
-- Safe to run multiple times (ON CONFLICT DO NOTHING throughout).
-- =====================================================================

BEGIN;

-- ─────────────────────────────────────────────────────────────────────
-- 1. VISA SUBCLASS ROW
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO visa_subclass (subclass_code, stream, audience, canonical_info_url, last_verified_at)
VALUES (
    '417', NULL, 'B2C',
    'https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/work-holiday-417',
    '2025-02-01T00:00:00Z'
)
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 2. REQUIREMENTS
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO requirement (
    requirement_id, visa_id, requirement_type, title, plain_english,
    legal_basis, operational_basis, effective_from, effective_to,
    rule_logic, confidence, last_reviewed_at
)
SELECT
    gen_random_uuid(),
    vs.visa_id,
    r.req_type::kb_requirement_type,
    r.title,
    r.plain_english,
    r.legal_basis::jsonb,
    r.operational_basis::jsonb,
    r.effective_from::date,
    r.effective_to::date,
    r.rule_logic::jsonb,
    r.confidence::kb_confidence,
    r.last_reviewed_at::timestamptz
FROM visa_subclass vs,
LATERAL (VALUES
    (
        'genuine',
        'Genuine Working Holiday Intention',
        'You must be coming to Australia for a working holiday — primarily for tourism, with work as a secondary activity to support yourself during your stay. You must be a citizen of an eligible country and meet age requirements (typically 18–30 or 18–35 depending on country of origin).',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clause 417.212","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"Eligibility criteria for WHM 417. Age limit extended to 35 for some nationalities via instrument."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/work-holiday-417","title":"Working Holiday visa (417)","last_checked":"2025-02-01"}]',
        '2015-07-01', NULL,
        '{"inputs":["citizenship_country","age_at_application","prior_417_held"],"outputs":["FLAG-417-AGE-INELIGIBLE","FLAG-417-COUNTRY-INELIGIBLE","FLAG-417-REPEAT-APPLICATION"],"logic_notes":"417 is a once-in-a-lifetime visa for most nationalities unless second/third grant criteria fulfilled via specified work."}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'work_history',
        'Specified Work for Second/Third Grant',
        'To be eligible for a second or third Working Holiday visa (417), you must have completed a specified number of days of specified work in a regional area of Australia during your first/second visa. Specified work categories and eligible regional areas are defined by legislative instrument. The requirement is 88 days for the second grant and 179 days for the third grant.',
        '[{"authority":"FRL_INSTRUMENT","citation":"Current specified work and regional area instrument","frl_title_id":null,"series":"Migration (Specified Activities for Working Holiday) Instrument","notes":"Instrument defines eligible industries (agriculture, construction, mining, etc.) and regional postcodes. Check FRL for current in-force version."},{"authority":"FRL_REGS","citation":"Schedule 2, clause 417.211(b)","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"Second grant condition — specified work requirement."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/work-holiday-417/specified-work","title":"Working Holiday 417 — Specified work","last_checked":"2025-02-01"}]',
        '2015-07-01', NULL,
        '{"inputs":["specified_work_days_completed","work_region_eligible","employer_abn_provided","payslips_available"],"outputs":["FLAG-417-WORK-DAYS-SHORT","FLAG-417-WORK-REGION","FLAG-417-WORK-EVIDENCE-GAP"],"logic_notes":"88 days (first grant); 179 days (second grant). Days must be verifiable. Employer ABN + payslips are essential evidence. Cash-in-hand work without records is a significant risk."}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'financial',
        'Financial Threshold',
        'You must demonstrate sufficient funds to support yourself at the start of your working holiday. The minimum threshold is set by instrument (approximately AUD $5,000 — verify the current figure with the department). Having accessible savings at the time of application reduces financial risk indicators.',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clause 417.213","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"Financial capacity requirement for 417."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/work-holiday-417","title":"Working Holiday 417 — financial requirement","last_checked":"2025-02-01"}]',
        '2015-07-01', NULL,
        '{"inputs":["savings_aud","return_flight_evidence"],"outputs":["FLAG-417-FIN-INSUFFICIENT"],"logic_notes":"Minimum threshold approximately AUD $5,000 (verify current figure). Evidence of a return flight or sufficient funds for one is also expected."}',
        'medium', '2025-02-01T00:00:00Z'
    )
) AS r(req_type, title, plain_english, legal_basis, operational_basis, effective_from, effective_to, rule_logic, confidence, last_reviewed_at)
WHERE vs.subclass_code = '417' AND vs.stream IS NULL
ON CONFLICT (visa_id, title) DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 3. EVIDENCE ITEMS
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO evidence_item (
    evidence_id, requirement_id, label, what_it_proves, examples, common_gaps,
    priority, effective_from, effective_to
)
SELECT
    gen_random_uuid(),
    req.requirement_id,
    ev.label,
    ev.what_it_proves,
    ev.examples::jsonb,
    ev.common_gaps::jsonb,
    ev.priority,
    ev.effective_from::date,
    ev.effective_to::date
FROM requirement req
JOIN visa_subclass vs ON vs.visa_id = req.visa_id
CROSS JOIN LATERAL (VALUES
    -- Specified Work (second/third grant)
    ('Specified Work for Second/Third Grant',
     'Payslips from regional employer',
     'Primary evidence that specified work was performed for an eligible employer in a regional area during the required period.',
     '["Electronic payslips in PDF format showing employer name, ABN, pay period, gross pay, and work location","Keep payslips from every pay period of specified work"]',
     '["Employer ABN missing from payslip","Cash-in-hand work with no payslip — significant risk indicator","Work location cannot be verified as regional from payslip alone"]',
     1, '2015-07-01', NULL),
    ('Specified Work for Second/Third Grant',
     'Tax file number (TFN) statement or tax return',
     'Independent corroboration of specified work income and employer relationship, cross-checking payslips.',
     '["ATO income statement or payment summary (PAYG) downloaded from myGov","Income tax return showing regional employment income"]',
     '["Payments not declared to ATO — consistency risk between payslips and tax records","Multiple employers listed but work period dates overlap inconsistently"]',
     1, '2015-07-01', NULL),
    ('Specified Work for Second/Third Grant',
     'Employer reference letter',
     'Confirms details of specified work engagement including regional eligibility and work category.',
     '["Letter on company letterhead confirming dates of employment, work type, ABN, and postcode/location of work","Ideally obtained while still employed or immediately on finishing"]',
     '["Letter not on letterhead or missing ABN","Work category listed does not match eligible specified work categories","Dates conflict with other evidence"]',
     2, '2015-07-01', NULL),
    -- Financial
    ('Financial Threshold',
     'Bank statements showing minimum savings',
     'Demonstrates financial capacity to fund the initial period of the working holiday.',
     '["3 months of personal bank statements showing accessible savings","Account in the applicant''s own name showing consistent balance at or above the threshold"]',
     '["Savings balance fluctuates significantly — large deposits immediately before application may raise questions","Account is in a third party''s name — funds must be in the applicant''s name or clearly accessible"]',
     1, '2015-07-01', NULL)
) AS ev(req_title, label, what_it_proves, examples, common_gaps, priority, effective_from, effective_to)
WHERE vs.subclass_code = '417' AND vs.stream IS NULL
  AND req.title = ev.req_title
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 4. FLAG TEMPLATES
-- kb_flag_severity: info / warning / risk
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO flag_template (
    flag_id, visa_id, title, trigger_schema, why_it_matters, actions,
    evidence_examples, severity, effective_from, effective_to, sources
)
SELECT
    gen_random_uuid(),
    vs.visa_id,
    f.title,
    f.trigger_schema::jsonb,
    f.why_it_matters,
    f.actions::jsonb,
    f.evidence_examples::jsonb,
    f.severity::kb_flag_severity,
    f.effective_from::date,
    f.effective_to::date,
    f.sources::jsonb
FROM visa_subclass vs,
LATERAL (VALUES
    (
        'Specified work day count may be insufficient for second grant',
        '{"field":"specified_work_days_completed","operator":"<","value":88}',
        'A second grant of the 417 visa requires exactly 88 days of specified work in an eligible regional area during the first visa. If the day count is borderline, evidence of every working day is critical. Days worked under a cash-only arrangement without records are at risk of not being counted.',
        '["Tally total days carefully from payslips and tax records BEFORE applying","Obtain employer reference letters for every employer","Do not rely on verbal confirmation alone — get written evidence"]',
        '["Complete payslips for 88+ days","Tax statement matching payslip income","Employer reference letters on letterhead with ABN and regional postcode"]',
        'risk', '2015-07-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Clause 417.211(b)","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/work-holiday-417/specified-work"}'
    ),
    (
        'Specified work location may not be in an eligible regional area',
        '{"field":"work_region_eligible","operator":"==","value":false}',
        'Work must be performed in a designated regional or low-population-growth area defined by the relevant legislative instrument (postcodes and LGAs). Urban work does not qualify. The postcode of the actual work location — not the employer''s head office — determines eligibility.',
        '["Verify that the postcode where work was actually performed is on the eligible regional areas list","Obtain a letter from the employer confirming the actual site address and postcode","Cross-check the instrument in force during the period of work (instruments change)"]',
        '["Employer letter stating actual work site address and postcode","Map or independent postcode verification showing site is in eligible area"]',
        'warning', '2015-07-01', NULL,
        '{"legislation":"Migration (Specified Activities for Working Holiday) Instrument","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/work-holiday-417/specified-work"}'
    ),
    (
        'Cash-in-hand work lacks documentary evidence',
        '{"field":"cash_work_undocumented","operator":"==","value":true}',
        'Work paid in cash without payslips, ABN on record, or tax declared is very difficult to verify. Home Affairs may not accept it toward the 88-day count without strong corroborating evidence.',
        '["Obtain a statutory declaration from the employer confirming the period and nature of work","Supplement with bank deposit records, accommodation records at the work location, and photos if available","Seek independent corroboration from third parties who can confirm the employer and location"]',
        '["Statutory declaration from employer (notarised if possible)","Bank statements showing cash deposits correlating to pay days","Accommodation receipts or lease at the regional work site"]',
        'risk', '2015-07-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Clause 417.211(b)","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/work-holiday-417/specified-work"}'
    ),
    (
        'Financial threshold may not be met',
        '{"field":"savings_aud","operator":"<","value":5000}',
        'Without sufficient accessible savings at the time of application, the 417 application is at risk. The current minimum threshold should be verified with the department — the figure in legislation is updated periodically.',
        '["Ensure savings are clearly in the applicant''s name","Avoid large lump-sum deposits immediately before application — a consistent savings history is more persuasive","If below threshold, consider delaying application until funds are adequate"]',
        '["3 months of bank statements showing consistent accessible savings","Return flight booking or funds for a return flight"]',
        'warning', '2015-07-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Clause 417.213","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/work-holiday-417"}'
    )
) AS f(title, trigger_schema, why_it_matters, actions, evidence_examples, severity, effective_from, effective_to, sources)
WHERE vs.subclass_code = '417' AND vs.stream IS NULL
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 5. KB RELEASE TAG
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO kb_release (release_tag, created_at)
VALUES ('kb-v20260314-working-holiday-417', NOW())
ON CONFLICT DO NOTHING;


COMMIT;

-- ─────────────────────────────────────────────────────────────────────
-- VERIFICATION QUERIES (run after applying)
-- ─────────────────────────────────────────────────────────────────────
-- SELECT COUNT(*) FROM requirement
--   WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '417');
-- Expected: 3
--
-- SELECT COUNT(*) FROM evidence_item
--   WHERE requirement_id IN (
--     SELECT requirement_id FROM requirement
--     WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '417')
--   );
-- Expected: 4
--
-- SELECT COUNT(*) FROM flag_template
--   WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '417');
-- Expected: 4
--
-- SELECT release_tag, created_at FROM kb_release ORDER BY created_at DESC LIMIT 3;
