-- =====================================================================
-- KangaVisa Knowledge Base — Sprint 17
-- seed_visitor_600_v1.sql
-- =====================================================================
-- Seeds requirements, evidence items, and flag templates for:
--   600 (Visitor Visa — Tourist / Business / Sponsored Family streams)
--
-- Source JSON files:
--   kb/seed/visa_600_requirements.json   (5 requirements)
--   kb/seed/visa_600_evidence_items.json (7 evidence items)
--   kb/seed/visa_600_flags.json          (6 flag templates)
--
-- Safe to run multiple times:
--   • visa_subclass    — ON CONFLICT DO NOTHING
--   • requirement      — ON CONFLICT ON CONSTRAINT requirement_visa_title_uk DO NOTHING
--                        (requires requirement_unique_title_v1.sql applied first)
--   • evidence_item    — ON CONFLICT DO NOTHING
--   • flag_template    — ON CONFLICT DO NOTHING
--
-- Wrapped in a transaction for atomicity.
-- =====================================================================

BEGIN;

-- ─────────────────────────────────────────────────────────────────────
-- 1. VISA SUBCLASS ROW  (already exists from Sprint 0 seed, safe to re-insert)
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO visa_subclass (subclass_code, stream, audience, canonical_info_url, last_verified_at)
VALUES (
    '600', NULL, 'B2C',
    'https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/visitor-600',
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
        'Genuine Visitor',
        'The applicant must demonstrate an intention to stay temporarily in Australia and comply with visa conditions. Decision makers assess travel purpose, home-country ties, travel history, immigration compliance record, and economic circumstances. This is a balance-of-factors test.',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clause 600.211","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"Primary genuine visitor requirement for Subclass 600."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/visitor-600","title":"Visitor visa (subclass 600)","last_checked":"2025-02-01"}]',
        '1994-09-01', NULL,
        '{"inputs":["travel_purpose","home_country_ties","travel_history","immigration_compliance_record","economic_circumstances"],"outputs":["RF600_WEAK_TRAVEL_PURPOSE","RF600_INSUFFICIENT_HOME_TIES","RF600_POOR_TRAVEL_HISTORY"]}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'financial',
        'Financial Capacity',
        'The applicant must demonstrate the ability to financially support their travel and stay in Australia without recourse to public funds. Evidence should show sufficient funds relative to the planned length of stay.',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clause 600.211; Public Interest Criterion 4011","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"Financial capacity assessed as part of the overall genuine visitor and public interest criteria."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/visitor-600","title":"Visitor visa (subclass 600) — financial requirements","last_checked":"2025-02-01"}]',
        '1994-09-01', NULL,
        '{"inputs":["bank_statement_balance","income_evidence","sponsor_financial_support"],"outputs":["RF600_INSUFFICIENT_FUNDS","RF600_UNVERIFIABLE_FINANCIAL_RECORDS"]}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'identity',
        'Identity Confirmation',
        'The applicant must provide documents confirming their identity. A valid passport is the primary identity document. National ID or birth certificate may be required in some circumstances.',
        '[{"authority":"FRL_ACT","citation":"Migration Act 1958, s 256","frl_title_id":"C2004A01381","series":"Migration Act 1958","notes":"Identity requirements apply broadly across all visa classes."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/visitor-600","title":"Visitor visa (subclass 600) — identity","last_checked":"2025-02-01"}]',
        '1994-09-01', NULL,
        '{"inputs":["passport_valid","name_consistency"],"outputs":["RF600_IDENTITY_MISMATCH"]}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'other',
        'Clear Travel Plan',
        'The applicant should provide a reasonable explanation of their intended travel activities in Australia, including proposed dates, accommodation, and activities. A credible travel plan supports the genuine visitor assessment.',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clause 600.211","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"Assessed as part of the overall genuine visitor determination. No separate standalone clause — departmental evidentiary practice."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/visitor-600","title":"Visitor visa (subclass 600) — travel plans","last_checked":"2025-02-01"}]',
        '1994-09-01', NULL,
        '{"inputs":["itinerary_provided","accommodation_confirmed","activity_plan_credible"],"outputs":["RF600_UNCLEAR_TRAVEL_PLAN"]}',
        'medium', '2025-02-01T00:00:00Z'
    ),
    (
        'other',
        'Invitation Support (Visiting Family or Friends)',
        'If the applicant is visiting an Australian resident, evidence from the host may be required. This includes an invitation letter and proof of the host''s status in Australia. Not required for all applicants — only when the primary travel purpose is to visit a host.',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clause 600.211","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"Assessed as part of genuine visitor determination. Departmental evidentiary guidance applies."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/visitor-600","title":"Visitor visa (subclass 600) — visiting family or friends","last_checked":"2025-02-01"}]',
        '1994-09-01', NULL,
        '{"inputs":["travel_purpose_type","host_invitation_provided","host_status_in_australia"],"outputs":["RF600_WEAK_HOST_EVIDENCE"]}',
        'medium', '2025-02-01T00:00:00Z'
    )
) AS r(req_type, title, plain_english, legal_basis, operational_basis, effective_from, effective_to, rule_logic, confidence, last_reviewed_at)
WHERE vs.subclass_code = '600' AND vs.stream IS NULL
ON CONFLICT ON CONSTRAINT requirement_visa_title_uk DO NOTHING;


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
    -- Genuine Visitor evidence
    ('Genuine Visitor',
     'Travel purpose statement',
     'A written explanation of why the applicant intends to visit Australia, supporting the genuine visitor assessment under clause 600.211.',
     '["Personal statement explaining travel purpose","Tour or activity booking confirmations","Conference or event registration","Business meeting schedule or invitation letter"]',
     '["No written explanation provided","Purpose is vague — does not specify activities or dates","Statement contradicts other documents (e.g., planned stay longer than return flight)"]',
     1, '1994-09-01', NULL),
    ('Genuine Visitor',
     'Evidence of ties to home country',
     'Demonstrates the applicant has strong incentives to return home after the visit, supporting the genuine visitor test.',
     '["Employment contract and approved leave letter","Property title or mortgage in home country","University enrolment documents","Business registration documents (for self-employed applicants)"]',
     '["No stable employment or property documented","Only informal or handwritten letters from employer","Self-employed with no business registration evidence"]',
     1, '1994-09-01', NULL),
    ('Genuine Visitor',
     'Previous international travel history',
     'Demonstrates a pattern of compliance with visa conditions in other countries, reducing refusal risk under the genuine visitor test.',
     '["Passport pages showing prior entry and exit stamps","Previous visa labels or approval letters","Travel history record or immigration clearance certificate"]',
     '["No prior international travel history — provide additional home-country ties evidence","Prior overstay record not addressed in a covering statement","Passport not submitted with prior stamps"]',
     2, '1994-09-01', NULL),
    -- Financial Capacity evidence
    ('Financial Capacity',
     'Bank statements (3–6 months)',
     'Demonstrates the applicant has sufficient funds to support their visit without recourse to public funds.',
     '["3–6 months of bank statements from a regulated financial institution","Statements showing consistent balance and regular income deposits"]',
     '["Statements from only the past 1 month","Large unexplained deposits immediately before the application","Balance insufficient relative to the proposed stay duration"]',
     1, '1994-09-01', NULL),
    ('Financial Capacity',
     'Income evidence (payslips, tax returns, or sponsor letter)',
     'Supports the source of funds and confirms the financial capacity evidence is genuine and verifiable.',
     '["Recent payslips (past 2–3 months)","Tax return or assessment notice from home country"],["Sponsor financial support letter with supporting financial documents (if a sponsor is paying)"]',
     '["Income stated on application does not match payslips","No tax records to corroborate self-employment income","Sponsor letter not accompanied by the sponsor''s own financial evidence"]',
     1, '1994-09-01', NULL),
    -- Identity Confirmation evidence
    ('Identity Confirmation',
     'Valid passport (bio page)',
     'Primary identity document confirming the applicant''s identity and travel document validity.',
     '["Passport bio page scan (clear, complete)","All passport pages if requested"]',
     '["Passport expiring within 6 months of proposed travel","Name on application differs from passport","Passport pages damaged or illegible"]',
     1, '1994-09-01', NULL),
    -- Clear Travel Plan evidence
    ('Clear Travel Plan',
     'Travel itinerary (flights, accommodation, activities)',
     'Demonstrates a credible, specific plan for the visit, supporting the genuine visitor assessment.',
     '["Return flight booking confirmations","Hotel or accommodation reservations","Tour or attraction bookings","Event or conference schedules"]',
     '["One-way flight only with no explanation of return arrangements","No accommodation plan for the full proposed stay","Itinerary for only a portion of the proposed trip length"]',
     1, '1994-09-01', NULL),
    -- Invitation Support evidence
    ('Invitation Support (Visiting Family or Friends)',
     'Invitation letter from Australian host',
     'Confirms the purpose of visiting a host and supports the genuine visitor assessment when the travel purpose is to see family or friends.',
     '["Signed invitation letter from the Australian host","Host''s Australian passport or permanent visa copy","Photos or correspondence demonstrating the ongoing relationship"]',
     '["Invitation letter does not state the relationship or length of intended stay","Host''s Australian status not confirmed with a document","Letter is informal and not signed"]',
     1, '1994-09-01', NULL)
) AS ev(req_title, label, what_it_proves, examples, common_gaps, priority, effective_from, effective_to)
WHERE vs.subclass_code = '600' AND vs.stream IS NULL
  AND req.title = ev.req_title
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 4. FLAG TEMPLATES
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
        'Weak or vague travel purpose',
        '{"conditions":["travel_purpose_statement = none OR vague","itinerary_provided = false"]}',
        'Under clause 600.211, decision makers assess whether the applicant genuinely intends to visit Australia temporarily. A vague or missing travel purpose is one of the most common reasons for Visitor Visa refusal.',
        '["Write a clear travel purpose statement describing your reason for visiting Australia","Provide a day-by-day or week-by-week itinerary of planned activities","Attach supporting documents such as tour bookings, event registrations, or a conference invitation","If visiting for business, include meeting schedules or a letter from your Australian business contact"]',
        '["Personal statement explaining travel purpose","Flight and hotel booking confirmations","Tour or activity bookings","Conference registration or business meeting schedule"]',
        'warning', '1994-09-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Schedule 2, clause 600.211","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/visitor-600"}'
    ),
    (
        'Insufficient evidence of ties to home country',
        '{"conditions":["home_country_ties_evidence = none OR weak","employment_letter_provided = false","property_evidence_provided = false"]}',
        'Decision makers assess whether the applicant is likely to return home after their visit. Weak ties to the home country — such as no stable employment, no property, no family dependants, or a history of overstaying visas — significantly increase refusal risk under clause 600.211.',
        '["Provide an employment contract or letter from your employer confirming your role and approved leave","Include evidence of property ownership, mortgage, or long-term lease in your home country","Document family responsibilities such as dependant children or elderly relatives in your care","If self-employed, provide business registration documents and evidence of ongoing operations"]',
        '["Employment contract and leave approval letter","Property title or mortgage statement","Business registration or tax filing showing ongoing business","Family relationship documents (birth certificates, dependant declarations)"]',
        'warning', '1994-09-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Schedule 2, clause 600.211","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/visitor-600"}'
    ),
    (
        'Limited or concerning travel history',
        '{"conditions":["previous_international_travel = none","prior_visa_overstay = true"]}',
        'Travel history is a key factor in genuine visitor assessments. Applicants with no international travel history may face greater scrutiny. Any prior visa overstay or immigration non-compliance significantly increases the risk of refusal under clause 600.211 and PIC 4013.',
        '["Include all passport pages showing entry and exit stamps from previous international travel","If you have no prior travel history, provide additional evidence of home-country ties and financial stability","If you have a prior overstay, address it directly in a statement explaining the circumstances","Obtain a travel history record or immigration clearance letter from relevant authorities if available"]',
        '["Passport scans showing entry and exit stamps","Previous visa labels or approval letters","Travel history record or immigration clearance certificate","Statutory declaration addressing any prior non-compliance (if applicable)"]',
        'risk', '1994-09-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Schedule 2, clause 600.211; Public Interest Criterion 4013","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/visitor-600"}'
    ),
    (
        'Insufficient funds for intended length of stay',
        '{"conditions":["bank_statement_balance = low OR absent","income_evidence_provided = false"]}',
        'While there is no fixed statutory dollar threshold, decision makers assess whether the applicant can genuinely support themselves during the proposed visit without working unlawfully or relying on social support. Low balances relative to the proposed stay or an inability to explain income sources increases refusal risk.',
        '["Provide at least 3 months of recent bank statements showing consistent balance","Include evidence of income: payslips, tax returns, or business revenue statements","If a sponsor is supporting the trip, obtain a signed financial support letter and their own bank statements","Ensure the financial evidence is consistent with the stated length of stay"]',
        '["Three to six months of bank statements with explanatory notes for large movements","Recent payslips (last 2–3 months)","Tax return or assessment notice from home country revenue authority","Sponsor financial support letter with evidence of sponsor capacity"]',
        'warning', '1994-09-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Schedule 2, clause 600.211; Public Interest Criterion 4011","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/visitor-600"}'
    ),
    (
        'Financial records appear inconsistent or unverifiable',
        '{"conditions":["bank_statement_large_unexplained_deposits = true","income_does_not_match_stated_employment = true"]}',
        'Decision makers flag financial evidence that is inconsistent or hard to verify — for example, large recent deposits that do not match stated income. This can indicate borrowed funds or fabricated records, which may be treated as evidence of deception under s109 of the Migration Act.',
        '["Explain any large or unusual deposits with a covering note or supporting documentation","Use statements from regulated, named financial institutions wherever possible","Ensure your stated employment and income are consistent with the financial records you submit","If you received a gift or loan, document it with a letter and the source party''s own financials"]',
        '["Bank statements with annotated explanation of large deposits","Gift or loan letter with supporting evidence of the source party''s capacity","Payslips and employer confirmation consistent with bank deposits","Tax records matching stated income"]',
        'risk', '1994-09-01', NULL,
        '{"legislation":"Migration Act 1958, s 109 (incorrect information); Migration Regulations 1994 — Public Interest Criterion 4011","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/visitor-600"}'
    ),
    (
        'Weak or missing host invitation evidence',
        '{"conditions":["travel_purpose_type = visiting_family_or_friends","host_invitation_provided = false"]}',
        'When the stated purpose of the visit is to see an Australian resident (family or friends), decision makers look for corroborating evidence from the host. Without an invitation letter or proof of the host''s Australian status, the travel purpose is harder to verify.',
        '["Ask your Australian host to provide a signed invitation letter explaining the relationship and the purpose of the visit","Include a copy of the host''s Australian passport, visa, or citizenship documentation","Provide evidence of the relationship: photos, correspondence history, or family documents","If the host is sponsoring costs, include their financial evidence too"]',
        '["Signed invitation letter from the Australian host","Copy of host''s Australian passport or permanent residency visa","Photos or correspondence demonstrating the ongoing relationship","Birth certificate or marriage certificate (for family visits)"]',
        'warning', '1994-09-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Schedule 2, clause 600.211","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/visitor-600"}'
    )
) AS f(title, trigger_schema, why_it_matters, actions, evidence_examples, severity, effective_from, effective_to, sources)
WHERE vs.subclass_code = '600' AND vs.stream IS NULL
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 5. KB RELEASE TAG
-- ─────────────────────────────────────────────────────────────────────
-- Records this seed run as a KB release so the staleness banner resets.

INSERT INTO kb_release (release_tag, created_at)
VALUES ('kb-v20260314-visitor-600', NOW())
ON CONFLICT DO NOTHING;


COMMIT;

-- ─────────────────────────────────────────────────────────────────────
-- VERIFICATION QUERIES (run after applying)
-- ─────────────────────────────────────────────────────────────────────
-- SELECT COUNT(*) FROM requirement
--   WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '600');
-- Expected: 5
--
-- SELECT COUNT(*) FROM evidence_item
--   WHERE requirement_id IN (
--     SELECT requirement_id FROM requirement
--     WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '600')
--   );
-- Expected: 8
--
-- SELECT COUNT(*) FROM flag_template
--   WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '600');
-- Expected: 6
--
-- SELECT release_tag, created_at FROM kb_release ORDER BY created_at DESC LIMIT 3;
