-- =====================================================================
-- KangaVisa Knowledge Base — Sprint 22
-- seed_employer_sponsored_482_v1.sql
-- =====================================================================
-- Seeds requirements, evidence items, and flag templates for:
--   482 / SID (Temporary Skill Shortage — Short-term / Medium-term stream)
--
-- Source JSON files:
--   kb/seed/visa_482_requirements.json   (3 requirements)
--   kb/seed/visa_482_evidence_items.json (4 evidence items)
--
-- Key 482 characteristics:
--   • Employer-sponsored — requires approved Standard Business Sponsor
--   • Occupation must appear on MLTSSL or STSOL (instrument-defined)
--   • Salary must meet TSMIT (Temporary Skilled Migration Income Threshold)
--   • SAF (Skilling Australians Fund) levy payable by employer
--   • stream stored as 'SID' (Short-term and Medium-term Internationally-
--     Derived) — represents the Short-term stream in seed data
--
-- Safe to run multiple times (ON CONFLICT DO NOTHING throughout).
-- =====================================================================

BEGIN;

-- ─────────────────────────────────────────────────────────────────────
-- 1. VISA SUBCLASS ROW
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO visa_subclass (subclass_code, stream, audience, canonical_info_url, last_verified_at)
VALUES (
    '482', 'SID', 'B2C',
    'https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-skill-shortage-482',
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
        'nomination',
        'Approved Nomination',
        'Your employer must have an approved nomination for the position you are being sponsored for. The nominated occupation must be on the relevant occupation list, and employment terms (including salary) must meet the Temporary Skilled Migration Income Threshold (TSMIT) and be no less favourable than those for Australian workers performing equivalent work.',
        '[{"authority":"FRL_REGS","citation":"Regulation 2.72; Schedule 2, clause 482.231","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"Nomination criteria under reg 2.72. TSMIT is set by instrument and updated periodically."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-skill-shortage-482","title":"Temporary Skill Shortage visa (482)","last_checked":"2025-02-01"}]',
        '2018-03-18', NULL,
        '{"inputs":["nomination_approved","tsmit_salary_met","occupation_on_list","employment_conditions_comparable"],"outputs":["FLAG-482-NOM-SALARY","FLAG-482-NOM-CONDITIONS","FLAG-482-NOM-OCC"],"logic_notes":"TSMIT threshold changes periodically — always verify current instrument. Salary must be at or above TSMIT and market rate."}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'sponsorship',
        'Approved Standard Business Sponsor',
        'Your employer must be an approved standard business sponsor (or be seeking approval as part of the nomination). Standard business sponsors must demonstrate a genuine need for the position, meet training levy obligations (SAF levy), and not have any relevant adverse information.',
        '[{"authority":"FRL_REGS","citation":"Regulation 2.67A; Schedule 2, clause 482.211","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"Sponsorship approval criteria. Training levy (SAF) obligations apply."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/working-in-australia/temporary-skill-shortage-visa/standard-business-sponsorship","title":"Standard Business Sponsorship","last_checked":"2025-02-01"}]',
        '2018-03-18', NULL,
        '{"inputs":["sponsor_approval_status","sponsor_adverse_info","training_levy_paid"],"outputs":["FLAG-482-SPONS-APPROVAL","FLAG-482-SPONS-LEVY"],"logic_notes":"Employer must pay the Skilling Australians Fund (SAF) levy as part of nomination. Amount depends on employer size and visa period."}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'occupation',
        'Occupation on Eligible List',
        'The nominated occupation must appear on the Medium and Long-term Strategic Skills List (MLTSSL) or Short-term Skilled Occupation List (STSOL) for the stream being applied under. Occupation lists are defined by legislative instrument and updated periodically — always check the current in-force instrument.',
        '[{"authority":"FRL_INSTRUMENT","citation":"IMMI 19/051 (or current superseding instrument)","frl_title_id":null,"series":"Migration (Skilling Australians Fund) Amendment Act + relevant occupation list instrument","notes":"Check FRL for the current in-force occupation list instrument — updated periodically."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/working-in-australia/skill-occupation-list","title":"Skilled occupation list","last_checked":"2025-02-01"}]',
        '2018-03-18', NULL,
        '{"inputs":["nominated_occupation_anzsco","stream_applied"],"outputs":["FLAG-482-OCC-NOT-LISTED","FLAG-482-OCC-STREAM-MISMATCH"],"logic_notes":"ANZSCO code must match a current list entry for the stream. List changes frequently — always check the current in-force instrument."}',
        'medium', '2025-02-01T00:00:00Z'
    )
) AS r(req_type, title, plain_english, legal_basis, operational_basis, effective_from, effective_to, rule_logic, confidence, last_reviewed_at)
WHERE vs.subclass_code = '482' AND vs.stream = 'SID'
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
    ('Approved Nomination',
     'Signed employment contract',
     'Demonstrates the employment offer is genuine and terms (including salary) meet TSMIT and are no less favourable than Australian workers.',
     '["Full signed contract including all annexures","Position title, salary, hours, employment terms, and ANZSCO code clearly stated","Confirm whether TSMIT is inclusive or exclusive of superannuation"]',
     '["Salary stated is below current TSMIT — check current threshold before lodging","ANZSCO code on contract differs from nomination","Contract not signed by both parties"]',
     1, '2018-03-18', NULL),
    ('Approved Nomination',
     'Market salary rate evidence',
     'Confirms the nominee is not being paid below market rate, meeting the ''equivalent terms'' requirement for nomination.',
     '["SEEK or LinkedIn salary comparison data with date accessed","Industry award or enterprise agreement for equivalent role","Comparable Australian employee salary data in the same location"]',
     '["Market rate evidence not location-specific — cost of living varies by state and city","Data source more than 12 months old","No comparison with Australian workers in equivalent roles"]',
     1, '2018-03-18', NULL),
    ('Approved Standard Business Sponsor',
     'Business registration documents',
     'Confirms the employer is an eligible and lawfully operating business in Australia for standard business sponsorship purposes.',
     '["Current ASIC extract (within 3 months) downloaded from ASIC Connect","ABN registration confirmation","Any required business licences for the industry"]',
     '["Business structure changed since sponsorship approval","ABN cancelled or inactive","ASIC registration expired or under a different entity"]',
     1, '2018-03-18', NULL),
    ('Occupation on Eligible List',
     'Detailed position description',
     'Demonstrates the nominated position genuinely corresponds to the claimed ANZSCO occupation on the eligible list.',
     '["Duties and responsibilities matched to the ANZSCO unit group description","Percentage of time per duty where duties span multiple categories","Confirmation that the nominated occupation is the primary and dominant activity"]',
     '["Duties listed are generic — must match ANZSCO unit group specifics","Position is multi-occupation with no dominant primary activity","ANZSCO code does not appear on the current eligible occupation list"]',
     1, '2018-03-18', NULL)
) AS ev(req_title, label, what_it_proves, examples, common_gaps, priority, effective_from, effective_to)
WHERE vs.subclass_code = '482' AND vs.stream = 'SID'
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
        'Proposed salary may not meet the TSMIT',
        '{"field":"tsmit_salary_met","operator":"==","value":false}',
        'The Temporary Skilled Migration Income Threshold (TSMIT) is a mandatory minimum salary floor for the 482 visa. If the contracted salary is below the current TSMIT, the nomination will be refused. TSMIT is updated by instrument — always verify the current figure before lodging.',
        '["Verify committed salary against the current TSMIT figure on the Home Affairs website","Determine whether TSMIT calculation is inclusive or exclusive of superannuation","Update the employment contract if salary is below TSMIT before nomination lodgement"]',
        '["Signed employment contract showing salary at or above TSMIT","Confirmation of superannuation treatment (inclusive vs exclusive)"]',
        'risk', '2018-03-18', NULL,
        '{"legislation":"Migration Regulations 1994 — Regulation 2.72","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-skill-shortage-482"}'
    ),
    (
        'Occupation may not appear on the eligible occupation list',
        '{"field":"occupation_on_list","operator":"==","value":false}',
        'The nominated occupation''s ANZSCO code must appear on the current in-force eligible occupation list for the stream applied under. Lists are updated regularly — an occupation on the list at time of intent may have been removed by time of lodgement.',
        '["Check the current in-force occupation list instrument on FRL before finalising the nomination","Confirm the ANZSCO code matches the primary duties of the role","If the occupation has moved between MLTSSL and STSOL, confirm the correct stream is being used"]',
        '["Current occupation list instrument extract showing the ANZSCO code","Position description cross-referencing ANZSCO unit group duties"]',
        'risk', '2018-03-18', NULL,
        '{"legislation":"Current eligible occupation list instrument","homeaffairs":"https://immi.homeaffairs.gov.au/visas/working-in-australia/skill-occupation-list"}'
    ),
    (
        'SAF levy payment may not be confirmed',
        '{"field":"training_levy_paid","operator":"==","value":false}',
        'The Skilling Australians Fund (SAF) levy must be paid at nomination lodgement. If unpaid, the nomination cannot proceed. The levy amount depends on employer turnover and the length of the visa period.',
        '["Confirm SAF levy amount with the employer before lodgement","Include payment receipt in the nomination application","If employer is a small business, verify applicable levy rate"]',
        '["SAF levy payment receipt or transaction record","Employer confirmation of levy payment at lodgement"]',
        'warning', '2018-03-18', NULL,
        '{"legislation":"Migration (Skilling Australians Fund) Amendment Act; Migration Regulations 1994 — Regulation 2.72","homeaffairs":"https://immi.homeaffairs.gov.au/visas/working-in-australia/temporary-skill-shortage-visa/standard-business-sponsorship"}'
    ),
    (
        'Employment conditions may not be equivalent to Australian workers',
        '{"field":"employment_conditions_comparable","operator":"==","value":false}',
        'The sponsored worker must receive terms and conditions of employment that are no less favourable than those that apply, or would apply, to Australian workers performing equivalent work. This covers salary, leave entitlements, penalty rates, allowances, and other conditions.',
        '["Compare contracted conditions against the applicable modern award or enterprise agreement","Confirm leave entitlements, overtime, and penalty rates are not less favourable","Obtain a statement from the employer confirming terms are no less favourable"]',
        '["Modern award extract showing applicable conditions for equivalent role","Employer letter confirming conditions are no less favourable than Australian workers"]',
        'warning', '2018-03-18', NULL,
        '{"legislation":"Migration Regulations 1994 — Regulation 2.72(10)","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-skill-shortage-482"}'
    )
) AS f(title, trigger_schema, why_it_matters, actions, evidence_examples, severity, effective_from, effective_to, sources)
WHERE vs.subclass_code = '482' AND vs.stream = 'SID'
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 5. KB RELEASE TAG
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO kb_release (release_tag, created_at)
VALUES ('kb-v20260314-employer-sponsored-482', NOW())
ON CONFLICT DO NOTHING;


COMMIT;

-- ─────────────────────────────────────────────────────────────────────
-- VERIFICATION QUERIES (run after applying)
-- ─────────────────────────────────────────────────────────────────────
-- SELECT COUNT(*) FROM requirement
--   WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '482' AND stream = 'SID');
-- Expected: 3
--
-- SELECT COUNT(*) FROM evidence_item
--   WHERE requirement_id IN (
--     SELECT requirement_id FROM requirement
--     WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '482' AND stream = 'SID')
--   );
-- Expected: 4
--
-- SELECT COUNT(*) FROM flag_template
--   WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '482' AND stream = 'SID');
-- Expected: 4
--
-- SELECT release_tag, created_at FROM kb_release ORDER BY created_at DESC LIMIT 3;
