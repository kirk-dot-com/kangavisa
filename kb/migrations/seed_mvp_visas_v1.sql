-- =====================================================================
-- KangaVisa Knowledge Base — Sprint 16 MVP Seed
-- seed_mvp_visas_v1.sql
-- =====================================================================
-- Seeds requirements, evidence items, and flag_templates for:
--   485 (Temporary Graduate), 189 (Skilled Independent),
--   190 (Skilled Nominated), 491 (Skilled Work Regional),
--   820 (Partner Onshore)
--
-- Safe to run multiple times — all inserts use ON CONFLICT DO NOTHING.
-- Wrapped in a transaction for atomicity.
-- =====================================================================

BEGIN;

-- ─────────────────────────────────────────────────────────────────────
-- 1. VISA SUBCLASS ROWS
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO visa_subclass (subclass_code, stream, audience, canonical_info_url, last_verified_at)
VALUES
    ('485', NULL, 'B2C',
     'https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485',
     '2025-02-01T00:00:00Z'),
    ('189', NULL, 'B2C',
     'https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-independent-189',
     '2025-02-01T00:00:00Z'),
    ('190', NULL, 'B2C',
     'https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-nominated-190',
     '2025-02-01T00:00:00Z'),
    ('491', NULL, 'B2C',
     'https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-work-regional-491',
     '2025-02-01T00:00:00Z'),
    ('820', NULL, 'B2C',
     'https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-onshore-820-801',
     '2025-02-01T00:00:00Z')
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 2. SUBCLASS 485 — TEMPORARY GRADUATE
-- ─────────────────────────────────────────────────────────────────────

-- Requirements
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
        'Genuine Temporary Entrant',
        'You must intend to stay temporarily in Australia. Decision makers assess your circumstances including home-country ties, economic situation, immigration history, and compliance record.',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clause 485.213","frl_title_id":"F2022C00125","series":"Migration Regulations 1994"}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485","title":"Temporary Graduate visa (subclass 485)","last_checked":"2025-02-01"}]',
        '2013-11-16', NULL,
        '{"inputs":["home_country_ties","immigration_history","compliance_record","economic_circumstances"],"outputs":["FLAG-485-GTE-WEAK-TIES","FLAG-485-GTE-COMPLIANCE"]}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'other',
        'Australian Qualification Requirement',
        'You must have completed a qualification requiring at least 2 years of full-time study in Australia at a CRICOS-registered institution, within 6 months of lodging your 485 application.',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clause 485.211; clause 485.212","frl_title_id":"F2022C00125","series":"Migration Regulations 1994"}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485/graduate-stream","title":"Temporary Graduate visa 485 — Graduate stream","last_checked":"2025-02-01"}]',
        '2013-11-16', NULL,
        '{"inputs":["course_cricos_registered","study_duration_years","completion_date","lodgement_date"],"outputs":["FLAG-485-QUAL-TIMING","FLAG-485-QUAL-DURATION"]}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'english',
        'English Language Proficiency',
        'You must demonstrate competent English. Acceptable tests include IELTS (minimum 6.0 each band), TOEFL iBT, PTE Academic, Cambridge C1/C2, or OET. Exemptions may apply for citizens of certain countries.',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clause 485.221","frl_title_id":"F2022C00125","series":"Migration Regulations 1994"}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485","title":"Temporary Graduate visa 485 — English requirements","last_checked":"2025-02-01"}]',
        '2020-07-01', NULL,
        '{"inputs":["english_test_type","english_test_score","english_test_date","citizenship_country"],"outputs":["FLAG-485-ENG-SCORE","FLAG-485-ENG-EXPIRED","FLAG-485-ENG-EXEMPT"]}',
        'high', '2025-02-01T00:00:00Z'
    )
) AS r(req_type, title, plain_english, legal_basis, operational_basis, effective_from, effective_to, rule_logic, confidence, last_reviewed_at)
WHERE vs.subclass_code = '485' AND vs.stream IS NULL
ON CONFLICT DO NOTHING;

-- Evidence items for 485
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
    -- QUAL items
    ('Australian Qualification Requirement',
     'Award certificate or testamur',
     'Confirms completion of an eligible qualification at an Australian institution.',
     '["Official award certificate","Testamur from institution"]',
     '["Certificate not yet issued — use official completion letter","Name on certificate differs from passport name","Qualification not CRICOS registered"]',
     1, '2013-11-16', NULL),
    ('Australian Qualification Requirement',
     'Official academic transcript',
     'Provides detailed evidence of course completion and study duration to meet the 2-year minimum.',
     '["Official sealed academic transcript","Electronic transcript issued directly by institution"]',
     '["Unofficial transcript printed from student portal","Credits from overseas transferred without clear Australian study periods"]',
     1, '2013-11-16', NULL),
    ('Australian Qualification Requirement',
     'eCoE (Electronic Confirmation of Enrolment)',
     'Confirms enrolment in a CRICOS-registered course — verifies eligibility period and course duration.',
     '["eCoE from student portal","Updated eCoE from education provider"]',
     '["eCoE expired or cancelled","Course listed is not CRICOS registered"]',
     2, '2013-11-16', NULL),
    -- English items
    ('English Language Proficiency',
     'English language test result',
     'Demonstrates the applicant meets the English language requirement for subclass 485.',
     '["IELTS test report form","PTE Academic score report","TOEFL iBT score report","OET result letter","Cambridge C1/C2 certificate"]',
     '["Test result more than 3 years old at time of decision","One or more band scores below the minimum threshold","Test type not approved for migration purposes"]',
     1, '2020-07-01', NULL)
) AS ev(req_title, label, what_it_proves, examples, common_gaps, priority, effective_from, effective_to)
WHERE vs.subclass_code = '485' AND vs.stream IS NULL
  AND req.title = ev.req_title
ON CONFLICT DO NOTHING;

-- Flag templates for 485
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
        'Application timing may be outside the lodgement window',
        '{"field":"days_remaining_lodgement_window","operator":"<","value":30}',
        'The Temporary Graduate visa must be lodged within a defined window after completing studies. Missing this window means becoming ineligible for this pathway.',
        '["Confirm your course completion date and calculate the lodgement window","Lodge as early as possible once eligible","Ensure you hold a bridging visa if your current visa expires before lodgement"]',
        '["Course completion letter","Academic transcript showing final semester","CoE showing expected completion date"]',
        'risk', '2013-11-16', NULL,
        '{"legislation":"Migration Regulations 1994 — Schedule 2, Clause 485.212","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485"}'
    ),
    (
        'Selected visa stream may not match your circumstances',
        '{"field":"stream_profile_match","operator":"==","value":false}',
        'The 485 visa has two streams: Graduate Work and Post-Study Work. Selecting the wrong stream can result in ineligibility.',
        '["Confirm which stream applies to your qualification and occupation","Graduate Work stream requires an occupation on the skilled occupation list","Post-Study Work stream requires an Australian degree (Bachelor, Masters or Doctoral)"]',
        '["Degree certificate specifying qualification level","Skills assessment (Graduate Work stream)","Academic transcript confirming Australian institution"]',
        'warning', '2013-11-16', NULL,
        '{"legislation":"Migration Regulations 1994 — Clauses 485.214, 485.215","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485/temporary-graduate-visa-485-streams"}'
    ),
    (
        'Police check may be missing or expired',
        '{"all":[{"field":"police_check_required","operator":"==","value":true},{"field":"police_check_present","operator":"==","value":false}]}',
        'Applicants who have spent 12 or more months in certain countries must provide a police clearance certificate. Missing or expired police checks are a common cause of processing delays.',
        '["Obtain police clearance certificates from all countries where you have lived for 12+ months","Ensure each certificate is current — most must be obtained within 12 months of application","Include certified translations for non-English certificates"]',
        '["Australian Federal Police (AFP) check","Overseas police clearance certificate","Certified translation if non-English"]',
        'warning', '2013-11-16', NULL,
        '{"legislation":"Migration Regulations 1994 — Character requirements, Clause 485.225","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485/documents"}'
    ),
    (
        'English language evidence may be insufficient or expired',
        '{"field":"english_evidence_valid","operator":"==","value":false}',
        'The 485 visa requires evidence of functional English. IELTS/PTE/TOEFL scores expire. Check exemption basis if applicable.',
        '["Confirm whether your English test result is still valid","Check if you qualify for an exemption","Resit the English test if your scores have expired"]',
        '["IELTS, PTE, TOEFL, OET, or Cambridge test result","Passport from English-speaking country (if exempt)","Letter confirming degree delivered in English"]',
        'info', '2020-07-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Clause 485.222","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485/documents"}'
    )
) AS f(title, trigger_schema, why_it_matters, actions, evidence_examples, severity, effective_from, effective_to, sources)
WHERE vs.subclass_code = '485' AND vs.stream IS NULL
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 3. SUBCLASS 189 — SKILLED INDEPENDENT
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
        'other',
        'Valid Invitation to Apply',
        'The applicant must have received a valid Invitation to Apply (ITA) through SkillSelect based on their points score.',
        '[{"authority":"FRL_REGS","citation":"Clause 189.211","frl_title_id":"F2022C00125","series":"Migration Regulations 1994"}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-independent-189","title":"Skilled Independent visa (subclass 189)","last_checked":"2025-02-01"}]',
        '2012-07-01', NULL,
        '{"inputs":["skillselect_invitation_status","invitation_date"],"outputs":["RF189_TIMING_WINDOW_RISK"]}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'occupation',
        'Positive Skills Assessment',
        'The applicant must hold a positive skills assessment from the relevant authority for their nominated occupation.',
        '[{"authority":"FRL_REGS","citation":"Clause 189.213","frl_title_id":"F2022C00125","series":"Migration Regulations 1994"}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-independent-189/who-can-apply","title":"Skilled Independent 189 — who can apply","last_checked":"2025-02-01"}]',
        '2012-07-01', NULL,
        '{"inputs":["skills_assessment_body","skills_assessment_result","skills_assessment_date"],"outputs":["RF189_SKILLS_ASSESSMENT_INVALID"]}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'other',
        'Minimum Points Score',
        'The applicant must have a points score of at least 65 at the time of invitation, with all claimed points supported by evidence.',
        '[{"authority":"FRL_REGS","citation":"Clause 189.214; Schedule 6D","frl_title_id":"F2022C00125","series":"Migration Regulations 1994"}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-independent-189/points-test","title":"Skilled Independent 189 — points test","last_checked":"2025-02-01"}]',
        '2012-07-01', NULL,
        '{"inputs":["claimed_points","evidenced_points","english_band","employment_years"],"outputs":["RF189_POINTS_MISCALCULATION"]}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'english',
        'English Language Proficiency',
        'The applicant must demonstrate at least Competent English (minimum IELTS 6.0 in each band or equivalent) and results must be current.',
        '[{"authority":"FRL_REGS","citation":"Clause 189.215","frl_title_id":"F2022C00125","series":"Migration Regulations 1994"}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-independent-189/documents","title":"Skilled Independent 189 — documents","last_checked":"2025-02-01"}]',
        '2012-07-01', NULL,
        '{"inputs":["english_test_type","english_test_score","english_test_date"],"outputs":["RF189_ENGLISH_EXPIRY"]}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'health',
        'Health Requirement',
        'The applicant and any dependants must meet the health requirement. Health examinations are conducted by approved panel physicians.',
        '[{"authority":"FRL_REGS","citation":"Clause 189.225","frl_title_id":"F2022C00125","series":"Migration Regulations 1994"}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-independent-189/documents","title":"Skilled Independent 189 — documents","last_checked":"2025-02-01"}]',
        '2012-07-01', NULL,
        '{"inputs":["health_exam_completed","health_exam_date"],"outputs":[]}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'character',
        'Character Requirement',
        'The applicant must meet the character requirements under Section 501 of the Migration Act 1958. Police clearance certificates required from all countries where lived for 12+ months.',
        '[{"authority":"FRL_ACT","citation":"Section 501","frl_title_id":"C2024C00195","series":"Migration Act 1958"}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-independent-189/documents","title":"Skilled Independent 189 — documents","last_checked":"2025-02-01"}]',
        '2012-07-01', NULL,
        '{"inputs":["criminal_history","countries_lived_12mo","police_clearance_obtained"],"outputs":["RF_UNDISCLOSED_HISTORY"]}',
        'high', '2025-02-01T00:00:00Z'
    )
) AS r(req_type, title, plain_english, legal_basis, operational_basis, effective_from, effective_to, rule_logic, confidence, last_reviewed_at)
WHERE vs.subclass_code = '189' AND vs.stream IS NULL
ON CONFLICT DO NOTHING;

-- Evidence items for 189
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
    ('Positive Skills Assessment',
     'Skills assessment outcome letter',
     'Confirms a positive skills assessment from the relevant occupational assessing authority.',
     '["Engineers Australia skills assessment","VETASSESS assessment outcome letter","ACS (Australian Computer Society) assessment","AHPRA registration (health professions)"]',
     '["Assessment expired (typically 3 years)","Assessing body not correct for the occupation and visa subclass","Occupation on certificate differs from nominated occupation"]',
     1, '2012-07-01', NULL),
    ('Valid Invitation to Apply',
     'SkillSelect Invitation to Apply (ITA)',
     'Confirms a valid invitation was received through SkillSelect before lodging the application.',
     '["SkillSelect Invitation to Apply letter","EOI submission confirmation"]',
     '["ITA has expired — must lodge within 60 days","EOI submitted but ITA not yet received"]',
     1, '2012-07-01', NULL),
    ('English Language Proficiency',
     'English language test result',
     'Demonstrates the required level of English proficiency for the points score claimed.',
     '["IELTS Academic score report","PTE Academic score report","TOEFL iBT score report","OET result letter"]',
     '["Result expired (typically 3 years from test date)","Score claimed in EOI differs from actual result","Test type not accepted for skilled migration"]',
     1, '2012-07-01', NULL),
    ('Minimum Points Score',
     'Employment reference letters',
     'Supports skilled employment claims used for experience points in the points test.',
     '["Reference letters from employers on letterhead","Payslips showing role and dates of employment","Employment contracts"]',
     '["Reference letter does not specify hours worked or role clearly","Gap between reference letter period and claimed employment","Letter not on company letterhead or signed by authorised person"]',
     1, '2012-07-01', NULL),
    ('Minimum Points Score',
     'Academic qualifications',
     'Supports qualification points claimed in the EOI and points test.',
     '["Bachelor degree certificate","Masters degree certificate","Academic transcripts","Statement of attainment"]',
     '["Degree not assessed as equivalent to Australian qualification level","Transcripts not officially certified","Qualification not relevant to nominated occupation"]',
     1, '2012-07-01', NULL),
    ('Health Requirement',
     'Health examination (HAP ID)',
     'Confirms health examination booked and completed with an approved panel physician.',
     '["HAP ID confirmation","Panel physician booking confirmation","Examination results submitted to Home Affairs"]',
     '["Health examination booked but not yet completed","Results expired if processing takes longer than 12 months"]',
     2, '2012-07-01', NULL),
    ('Character Requirement',
     'Police clearance certificates',
     'Confirms the applicant meets character requirements for all countries lived in for 12+ months.',
     '["Australian Federal Police (AFP) national police check","Overseas police clearance certificates","Certified translations for non-English certificates"]',
     '["Missing clearance for a country where applicant lived for 12+ months","Clearance more than 12 months old","Non-English certificate without certified translation"]',
     1, '2012-07-01', NULL)
) AS ev(req_title, label, what_it_proves, examples, common_gaps, priority, effective_from, effective_to)
WHERE vs.subclass_code = '189' AND vs.stream IS NULL
  AND req.title = ev.req_title
ON CONFLICT DO NOTHING;

-- Flag templates for 189
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
        'Points claimed may exceed what evidence supports',
        '{"left_field":"claimed_points","operator":">","right_field":"evidenced_points"}',
        'Points claimed in your EOI must be supported by evidence at the time of invitation and application. Claiming points you cannot evidence can lead to refusal.',
        '["Recalculate your points against the official points test schedule","Confirm each point claim is backed by a document","Pay particular attention to overseas employment — reference letters must clearly state dates, role, and hours"]',
        '["Detailed reference letters from all employers","Payslips covering claimed employment period","English test result matching the points band claimed"]',
        'risk', '2012-07-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Schedule 6D","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-independent-189/points-test"}'
    ),
    (
        'Skills assessment may be invalid or expired',
        '{"all":[{"field":"skills_assessment_present","operator":"==","value":true},{"field":"skills_assessment_valid","operator":"==","value":false}]}',
        'Skills assessments have validity periods (typically 3 years). An expired or invalid assessment means the core eligibility requirement cannot be met.',
        '["Check the validity date on your assessment outcome letter","Apply for a reassessment if your assessment has expired","Confirm the assessing body is correct for your occupation and visa subclass"]',
        '["Skills assessment outcome letter (showing validity period)","Reassessment application confirmation"]',
        'risk', '2012-07-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Clause 189.213","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-independent-189/who-can-apply"}'
    ),
    (
        'Employment history has unexplained gaps',
        '{"field":"largest_timeline_gap_days","operator":">","value":90}',
        'Gaps in skilled employment can reduce points claims and raise questions about continuous skilled work experience.',
        '["Account for all gaps with a written explanation","Document any periods of study, self-employment, or travel","Ensure payslips and reference letters cover the full claimed employment period without gaps"]',
        '["Explanation letter for any gaps","Statutory declarations from supervisors","Study or travel records for gap periods"]',
        'warning', '2012-07-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Schedule 6D","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-independent-189"}'
    ),
    (
        'English test result may be expired',
        '{"field":"english_test_valid","operator":"==","value":false}',
        'English test results must be valid at the time of application. An expired test means points cannot be claimed for English proficiency.',
        '["Check the expiry date of your English test result","Book a resit if your result has or will expire before you lodge","Consider sitting a higher-band test to maximise English points while eligible"]',
        '["Current IELTS / PTE / TOEFL score report within validity period"]',
        'warning', '2012-07-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Clause 189.215","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-independent-189/documents"}'
    )
) AS f(title, trigger_schema, why_it_matters, actions, evidence_examples, severity, effective_from, effective_to, sources)
WHERE vs.subclass_code = '189' AND vs.stream IS NULL
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 4. SUBCLASS 190 — SKILLED NOMINATED
-- ─────────────────────────────────────────────────────────────────────
-- Inherits all 189 requirements. Adds the state nomination requirement.

INSERT INTO requirement (
    requirement_id, visa_id, requirement_type, title, plain_english,
    legal_basis, operational_basis, effective_from, effective_to,
    rule_logic, confidence, last_reviewed_at
)
SELECT
    gen_random_uuid(),
    vs.visa_id,
    'nomination'::kb_requirement_type,
    'State or Territory Nomination',
    'The applicant must hold a valid nomination from an Australian state or territory government for their nominated occupation. Nomination provides 5 bonus points in the points test.',
    '[{"authority":"FRL_REGS","citation":"Clause 190.211","frl_title_id":"F2022C00125","series":"Migration Regulations 1994"}]'::jsonb,
    '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-nominated-190","title":"Skilled Nominated visa (subclass 190)","last_checked":"2025-02-01"}]'::jsonb,
    '2012-07-01'::date,
    NULL::date,
    '{"inputs":["nomination_status","nominating_state","nominated_occupation"],"outputs":["RF190_NOMINATION_MISSING"]}'::jsonb,
    'high'::kb_confidence,
    '2025-02-01T00:00:00Z'::timestamptz
FROM visa_subclass vs
WHERE vs.subclass_code = '190' AND vs.stream IS NULL
ON CONFLICT DO NOTHING;

INSERT INTO evidence_item (
    evidence_id, requirement_id, label, what_it_proves, examples, common_gaps,
    priority, effective_from, effective_to
)
SELECT
    gen_random_uuid(),
    req.requirement_id,
    'State or territory nomination letter',
    'Confirms a valid nomination from an Australian state or territory government for the nominated occupation.',
    '["Nomination outcome letter from state/territory migration program","Confirmatory email from state/territory skills migration program"]'::jsonb,
    '["Nomination has expired — not yet visa-linked","Nominated occupation differs from skills assessment occupation","State nomination program was closed at time of application"]'::jsonb,
    1,
    '2012-07-01'::date,
    NULL::date
FROM requirement req
JOIN visa_subclass vs ON vs.visa_id = req.visa_id
WHERE vs.subclass_code = '190' AND vs.stream IS NULL
  AND req.title = 'State or Territory Nomination'
ON CONFLICT DO NOTHING;

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
        'State or territory nomination not confirmed',
        '{"all":[{"field":"nomination_required","operator":"==","value":true},{"field":"nomination_present","operator":"==","value":false}]}',
        'The Subclass 190 visa requires a valid state/territory nomination. Without it, the application cannot proceed regardless of points score.',
        '["Confirm your nomination application has been submitted and approved","Upload the nomination outcome letter","Ensure your occupation and skills assessment match the state''s requirements at time of nomination"]',
        '["Nomination outcome letter from state migration program","Skills assessment matching the nominated occupation"]',
        'risk', '2012-07-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Clause 190.211","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-nominated-190"}'
    ),
    (
        'Points claimed may exceed what evidence supports',
        '{"left_field":"claimed_points","operator":">","right_field":"evidenced_points"}',
        'Nominated applicants receive 5 bonus points from nomination, but all other claimed points must still be evidenced.',
        '["Recalculate points including the 5-point nomination bonus","Verify each point claim against supporting documents"]',
        '["Nomination letter (provides 5 points)","Employment reference letters covering claimed experience period","English test result matching bandwidth claimed"]',
        'risk', '2012-07-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Schedule 6D","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-nominated-190/points-test"}'
    )
) AS f(title, trigger_schema, why_it_matters, actions, evidence_examples, severity, effective_from, effective_to, sources)
WHERE vs.subclass_code = '190' AND vs.stream IS NULL
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 5. SUBCLASS 491 — SKILLED WORK REGIONAL (PROVISIONAL)
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
        'State Nomination or Eligible Relative Sponsorship',
        'Either a valid nomination from an Australian state or territory government, or sponsorship by an eligible relative living and working in a designated regional area. Provides 15 bonus points.',
        '[{"authority":"FRL_REGS","citation":"Clause 491.211","frl_title_id":"F2022C00125","series":"Migration Regulations 1994"}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-work-regional-491","title":"Skilled Work Regional (Provisional) visa (subclass 491)","last_checked":"2025-02-01"}]',
        '2019-11-16', NULL,
        '{"inputs":["nomination_or_sponsorship_status","nominating_state_or_relative","regional_area_confirmation"],"outputs":["RF491_NOMINATION_SPONSORSHIP_MISSING"]}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'other',
        'Regional Living Commitment',
        '491 holders must live and work (or study) in a designated regional area of Australia for at least 3 years to become eligible for the permanent Subclass 191 pathway.',
        '[{"authority":"FRL_REGS","citation":"Clause 491.612","frl_title_id":"F2022C00125","series":"Migration Regulations 1994"}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-work-regional-491/living-and-working-regionally","title":"491 — living and working regionally","last_checked":"2025-02-01"}]',
        '2019-11-16', NULL,
        '{"inputs":["regional_area_designated","employment_in_regional_area","lodgement_plan"],"outputs":["RF491_REGIONAL_REQUIREMENT_UNCLEAR"]}',
        'high', '2025-02-01T00:00:00Z'
    )
) AS r(req_type, title, plain_english, legal_basis, operational_basis, effective_from, effective_to, rule_logic, confidence, last_reviewed_at)
WHERE vs.subclass_code = '491' AND vs.stream IS NULL
ON CONFLICT DO NOTHING;

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
    ('State Nomination or Eligible Relative Sponsorship',
     'Nomination or sponsorship approval letter',
     'Confirms either state/territory nomination or eligble relative sponsorship for the 491.',
     '["Nomination outcome letter from state/territory government","Eligible relative sponsorship approval","Proof of relative s residence in designated regional area"]',
     '["Nomination expired before visa lodgement","Relative s regional area not on designated list","Sponsorship not yet approved"]',
     1, '2019-11-16', NULL),
    ('Regional Living Commitment',
     'Evidence of intended regional employment or accommodation',
     'Supports the applicant s commitment to living in a designated regional area.',
     '["Job offer in designated regional area","Lease or accommodation confirmation in regional area","Evidence of intended relocation"]',
     '["Job offer location is not in designated regional area","No concrete plan for regional relocation"]',
     2, '2019-11-16', NULL)
) AS ev(req_title, label, what_it_proves, examples, common_gaps, priority, effective_from, effective_to)
WHERE vs.subclass_code = '491' AND vs.stream IS NULL
  AND req.title = ev.req_title
ON CONFLICT DO NOTHING;

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
        'Nomination or relative sponsorship not confirmed',
        '{"all":[{"field":"nomination_or_sponsorship_required","operator":"==","value":true},{"field":"nomination_or_sponsorship_present","operator":"==","value":false}]}',
        'The 491 requires either state/territory nomination or sponsorship by an eligible relative in a regional area. Without one of these, the application cannot proceed.',
        '["Confirm whether you are applying via state nomination or relative sponsorship","Upload the nomination or sponsorship approval letter","Ensure your relative s regional address is documented if applying via sponsorship"]',
        '["Nomination outcome letter","Eligible relative sponsorship confirmation","Proof of relative s residence in designated regional area"]',
        'risk', '2019-11-16', NULL,
        '{"legislation":"Migration Regulations 1994 — Clause 491.211","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-work-regional-491"}'
    ),
    (
        'Understanding of regional living requirement unclear',
        '{"field":"regional_requirement_acknowledged","operator":"==","value":false}',
        'To become eligible for permanent residency (Subclass 191), 491 holders must live and work in a designated regional area for at least 3 years. Not understanding this requirement can create future visa problems.',
        '["Confirm the intended regional area is on the designated list","Plan employment and accommodation in a qualifying regional area","Understand the pathway from 491 to 191 Permanent Residence"]',
        '["Job offer in designated regional area","Lease or accommodation in designated regional area","Evidence of intended relocation"]',
        'info', '2019-11-16', NULL,
        '{"legislation":"Migration Regulations 1994 — Clause 491.612","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-work-regional-491/living-and-working-regionally"}'
    ),
    (
        'Points claimed may exceed what evidence supports',
        '{"left_field":"claimed_points","operator":">","right_field":"evidenced_points"}',
        'The 491 uses the same points test as 189/190. Nomination or sponsorship provides 15 bonus points, but all other claimed points must still be evidenced.',
        '["Recalculate points including the 15-point regional nomination/sponsorship bonus","Verify each point claim with supporting documents"]',
        '["Nomination/sponsorship letter (provides 15 points)","Employment references covering claimed experience","English test result"]',
        'risk', '2019-11-16', NULL,
        '{"legislation":"Migration Regulations 1994 — Schedule 6D","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-work-regional-491/points-test"}'
    )
) AS f(title, trigger_schema, why_it_matters, actions, evidence_examples, severity, effective_from, effective_to, sources)
WHERE vs.subclass_code = '491' AND vs.stream IS NULL
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 6. SUBCLASS 820 — PARTNER ONSHORE
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
        'relationship',
        'Genuine and Continuing Relationship',
        'You must be in a genuine and continuing relationship with an Australian citizen, permanent resident, or eligible NZ citizen. Assessed across four pillars: financial aspects, nature of household, social aspects, and commitment to each other.',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clauses 820.211–820.221; reg 1.15A","frl_title_id":"F2022C00125","series":"Migration Regulations 1994"},{"authority":"FRL_ACT","citation":"Section 5F (spouse); Section 5CB (de facto partner)","frl_title_id":"C2024C00195","series":"Migration Act 1958"}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-onshore-820-801","title":"Partner visa (820/801) — relationship evidence","last_checked":"2025-02-01"}]',
        '2009-07-01', NULL,
        '{"inputs":["relationship_type","cohabitation_duration","financial_pillar_evidence","household_pillar_evidence","social_pillar_evidence","commitment_pillar_evidence"],"outputs":["FLAG-820-REL-PILLAR-WEAK","FLAG-820-REL-TIMELINE-GAP"]}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'sponsorship',
        'Eligible Sponsor',
        'Your sponsoring partner must be an Australian citizen, Australian permanent resident, or eligible NZ citizen, and must not have previously sponsored two partners for a partner visa.',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clause 820.211(c); reg 1.20J","frl_title_id":"F2022C00125","series":"Migration Regulations 1994"}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-onshore-820-801","title":"Partner visa (820/801) — sponsor requirements","last_checked":"2025-02-01"}]',
        '2009-07-01', NULL,
        '{"inputs":["sponsor_citizenship_status","sponsor_prior_sponsorships","sponsor_character"],"outputs":["FLAG-820-SPONS-INELIGIBLE","FLAG-820-SPONS-LIMIT"]}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'health',
        'Health Requirement',
        'You and any dependent children included in the application must meet the health requirement (PIC 4005). Requires an immigration medical examination with an approved panel physician.',
        '[{"authority":"FRL_REGS","citation":"Schedule 4, Public Interest Criterion 4005","frl_title_id":"F2022C00125","series":"Migration Regulations 1994"}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/entering-and-leaving-australia/entering-australia/health-examinations","title":"Health examinations","last_checked":"2025-02-01"}]',
        '2009-07-01', NULL,
        '{"inputs":["medical_exam_completed","medical_exam_date"],"outputs":["FLAG-820-HLTH-REQUIRED","FLAG-820-HLTH-EXPIRED"]}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'character',
        'Character Requirement',
        'You must satisfy the character requirement (PIC 4001 — s.501 Migration Act 1958). Generally requires police clearance certificates from all countries where you have lived for 12+ months in the past 10 years (from age 16).',
        '[{"authority":"FRL_ACT","citation":"Section 501; Schedule 4, PIC 4001","frl_title_id":"C2024C00195","series":"Migration Act 1958"}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-onshore-820-801","title":"Partner visa (820/801) — character requirement","last_checked":"2025-02-01"}]',
        '2009-07-01', NULL,
        '{"inputs":["criminal_history","countries_lived_12mo","police_clearance_obtained"],"outputs":["FLAG-820-CHAR-POLICE-MISSING","FLAG-820-CHAR-HISTORY"]}',
        'high', '2025-02-01T00:00:00Z'
    )
) AS r(req_type, title, plain_english, legal_basis, operational_basis, effective_from, effective_to, rule_logic, confidence, last_reviewed_at)
WHERE vs.subclass_code = '820' AND vs.stream IS NULL
ON CONFLICT DO NOTHING;

-- Evidence items for 820
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
    ('Genuine and Continuing Relationship',
     'Joint bank account statements',
     'Demonstrates the financial pillar of relationship evidence — shared finances and financial interdependence.',
     '["3–12 months of joint account statements","Joint loan or mortgage documents","Shared insurance policies"]',
     '["Account opened recently — only a few months of statements","Both names on account but only one person transacting","No regularity of shared expenses"]',
     1, '2009-07-01', NULL),
    ('Genuine and Continuing Relationship',
     'Shared lease or property documents',
     'Demonstrates the household pillar — cohabitation and shared domestic arrangements.',
     '["Rental agreement listing both partners as co-tenants","Mortgage documents showing co-ownership","Utility bills at shared address listing both names"]',
     '["Only one partner s name on the lease","Multiple addresses with unexplained gaps in cohabitation","Lease for a property where both partners are not listed"]',
     1, '2009-07-01', NULL),
    ('Genuine and Continuing Relationship',
     'Statutory declarations from third parties (Form 888)',
     'Third-party corroboration — contributes to both social and commitment pillars.',
     '["Form 888 — Supporting statement for partner visa","Statutory declaration from a family member of either partner","Statutory declaration from a friend or colleague who knows the couple"]',
     '["All declarants have only met one partner","Declarations are identical in wording (template-based)","Declaration not properly witnessed or signed"]',
     1, '2009-07-01', NULL),
    ('Genuine and Continuing Relationship',
     'Photographs together across multiple events and dates',
     'Contributes to the social pillar — demonstrates a genuine shared life and ongoing relationship.',
     '["Dated photographs across different events and locations","Photographs with friends and family who know the couple"]',
     '["All photos from a single event or period","Photos are screenshots without metadata or dates","No photos with friends or family"]',
     2, '2009-07-01', NULL),
    ('Eligible Sponsor',
     'Sponsor citizenship or residency evidence',
     'Confirms the sponsoring partner is an eligible Australian citizen, permanent resident, or eligible NZ citizen.',
     '["Australian passport","Citizenship certificate","ImmiCard","Permanent visa grant letter"]',
     '["Sponsor s permanent visa has expired or been cancelled","NZ citizen sponsor eligibility not confirmed"]',
     1, '2009-07-01', NULL)
) AS ev(req_title, label, what_it_proves, examples, common_gaps, priority, effective_from, effective_to)
WHERE vs.subclass_code = '820' AND vs.stream IS NULL
  AND req.title = ev.req_title
ON CONFLICT DO NOTHING;

-- Flag templates for 820
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
        'Relationship evidence is limited across the four pillars',
        '{"field":"relationship_pillars_present","operator":"<","value":3}',
        'Home Affairs assesses partner visa applications across four pillars of shared life: financial, household, social, and commitment. Weak evidence in any pillar raises credibility concerns.',
        '["Gather evidence across all four pillars: financial, household, social, and commitment","Include joint documents, not just statements from each person individually","Where evidence is thin in one area, provide a written explanation supported by other documents"]',
        '["Joint bank account statements or shared bills (financial)","Shared lease agreement or utility bills (household)","Photos, event invitations, messages showing shared social life (social)","Form 888 statutory declarations from friends/family (commitment)"]',
        'risk', '2009-07-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Clause 820.211, Reg 1.15A","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-onshore-820-801"}'
    ),
    (
        'Relationship timeline appears inconsistent across documents',
        '{"field":"relationship_timeline_consistent","operator":"==","value":false}',
        'If statements, photos, and documents tell different stories about when or how the relationship started or progressed, the application s credibility is undermined.',
        '["Write a consistent relationship history that both partners agree on","Ensure dates of key events match across all documents","Review both partners statements for discrepancies before lodging"]',
        '["Consistent relationship history statement from both partners","Supporting documents matching key dates cited in statements"]',
        'warning', '2009-07-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Clause 820.211","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-onshore-820-801"}'
    ),
    (
        'Sponsor eligibility may not have been confirmed',
        '{"field":"sponsor_approved","operator":"==","value":false}',
        'The Australian partner (sponsor) must be approved before the visa can be granted. Sponsors with certain history or who do not meet residency criteria may be ineligible.',
        '["Confirm the sponsor meets citizenship or permanent residency requirements","Check if the sponsor has sponsored a previous partner visa within the last 5 years","Review whether the sponsor has any relevant criminal history"]',
        '["Australian citizenship certificate or permanent visa grant notice","Statutory declaration regarding prior sponsorships"]',
        'warning', '2009-07-01', NULL,
        '{"legislation":"Migration Act 1958 — Section 84; Migration Regulations 1994 — Clause 820.710","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-onshore-820-801"}'
    )
) AS f(title, trigger_schema, why_it_matters, actions, evidence_examples, severity, effective_from, effective_to, sources)
WHERE vs.subclass_code = '820' AND vs.stream IS NULL
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 7. KB RELEASE RECORD
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO kb_release (release_tag, notes)
VALUES (
    'kb-2026-03-09',
    'Sprint 16 seed: added requirements, evidence items, and flag templates for subclasses 485, 189, 190, 491, 820.'
)
ON CONFLICT (release_tag) DO NOTHING;


COMMIT;
