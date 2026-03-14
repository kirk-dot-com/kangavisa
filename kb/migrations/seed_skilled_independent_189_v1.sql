-- =====================================================================
-- KangaVisa Knowledge Base — Sprint 24
-- seed_skilled_independent_189_v1.sql
-- =====================================================================
-- Seeds requirements, evidence items, and flag templates for:
--   189 (Skilled Independent visa)
--
-- Source JSON file:
--   kb/seed/visa_189_seed.json
--     6 evidence items
--     6 requirements
--     4 flag templates
--
-- Key 189 characteristics:
--   • Points-tested — minimum 65 points at time of invitation
--   • Invitation to Apply (ITA) required from SkillSelect EOI
--   • Skills assessment required from relevant assessing authority
--   • No sponsorship requirement — fully independent pathway
--   • Permanent residency visa
--
-- Flag severity mapping: critical→risk, high→warning, medium→warning
--
-- Safe to run multiple times (ON CONFLICT DO NOTHING throughout).
-- =====================================================================

BEGIN;

-- ─────────────────────────────────────────────────────────────────────
-- 1. VISA SUBCLASS ROW
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO visa_subclass (subclass_code, stream, audience, canonical_info_url, last_verified_at)
VALUES (
    '189', NULL, 'B2C',
    'https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-independent-189',
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
        'other',
        'Valid Invitation to Apply',
        'You must have received a valid Invitation to Apply (ITA) through SkillSelect based on your Expression of Interest (EOI) and points score. Invitations are issued by the government at periodic rounds — you cannot lodge a 189 application without a valid ITA.',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clause 189.211","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"Valid ITA is a mandatory criterion for the 189 visa."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-independent-189","title":"Skilled Independent visa (subclass 189)","last_checked":"2025-02-01"}]',
        '2012-07-01', NULL,
        '{"inputs":["ita_received","ita_valid","ita_expiry_date"],"outputs":["FLAG-189-ITA-EXPIRED","FLAG-189-ITA-MISSING"],"logic_notes":"ITA must be current at time of lodgement. ITA is typically valid for 60 days. Applications lodged after ITA expiry will be invalid."}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'other',
        'Positive Skills Assessment',
        'You must hold a positive skills assessment from the relevant occupational assessing authority for your nominated occupation. The assessment must be valid at time of invitation and confirm that your qualifications and experience are suitable for the occupation.',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clause 189.213","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"Skills assessment from approved assessing authority required."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-independent-189/who-can-apply","title":"Skilled Independent visa 189 — Who can apply","last_checked":"2025-02-01"}]',
        '2012-07-01', NULL,
        '{"inputs":["skills_assessment_present","skills_assessment_valid","skills_assessment_authority","nominated_occupation"],"outputs":["FLAG-189-SKILLS-ASSESSMENT-INVALID","FLAG-189-SKILLS-ASSESSMENT-MISSING"],"logic_notes":"Assessment must be from the correct authority for the ANZSCO occupation. Validity periods vary by assessing body (typically 3 years). Expired assessments require reassessment application."}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'other',
        'Minimum Points Score',
        'You must have achieved a points score of at least 65 (the minimum threshold) at the time of invitation. Points are claimed for age, English proficiency, skilled employment, qualifications, partner skills, Australian study, community language, and regional study. All points claims must be supported by evidence.',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clause 189.214; Schedule 6D","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"Points test Schedule 6D sets out claims and evidence requirements."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-independent-189/points-test","title":"Skilled Independent visa 189 — Points test","last_checked":"2025-02-01"}]',
        '2012-07-01', NULL,
        '{"inputs":["claimed_points","evidenced_points","age_at_invitation","english_band_score","skilled_employment_years","qualification_level","partner_skills"],"outputs":["FLAG-189-POINTS-MISCALCULATION","FLAG-189-EMPLOYMENT-GAP"],"logic_notes":"Claimed points must be supported by evidence at time of lodgement. Points for overseas employment require employer reference letters clearly stating dates, role, and hours."}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'english',
        'English Language Proficiency',
        'You must demonstrate at least Competent English (minimum IELTS 6.0 in each band, or equivalent). Higher English scores attract more points (Superior English = IELTS 8.0+). The test must be from an approved provider and results must be valid (within 3 years of test date) at time of application.',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clause 189.215","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"Minimum competent English required. Higher levels attract points."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-independent-189/documents","title":"Skilled Independent visa 189 — Documents","last_checked":"2025-02-01"}]',
        '2012-07-01', NULL,
        '{"inputs":["english_test_type","english_test_score","english_test_date"],"outputs":["FLAG-189-ENGLISH-EXPIRY","FLAG-189-ENGLISH-BAND-LOW"],"logic_notes":"Test results must not be more than 3 years old at time of decision. IELTS Academic (not General) required. All four bands must meet minimum independently."}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'health',
        'Health Requirement',
        'You and all family members included on your application must meet the health requirement (PIC 4005). Health examinations are conducted by approved panel physicians and submitted to Home Affairs via the HAP system. Results can take several weeks — complete early.',
        '[{"authority":"FRL_REGS","citation":"Schedule 4, Public Interest Criterion 4005","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"PIC 4005 health requirement applies to 189 visa."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/entering-and-leaving-australia/entering-australia/health-examinations","title":"Health examinations","last_checked":"2025-02-01"}]',
        '2012-07-01', NULL,
        '{"inputs":["medical_exam_completed","hap_id_issued"],"outputs":["FLAG-189-HEALTH-EXAM-PENDING"],"logic_notes":"Book health examination early — results typically take 2-4 weeks. HAP ID is issued by Home Affairs."}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'character',
        'Character Requirement',
        'You must satisfy the character requirement under section 501 of the Migration Act 1958. Police clearance certificates are required from Australia and all countries in which you have lived for 12 months or more in the past 10 years (from age 16). Certificates must be current at time of lodgement.',
        '[{"authority":"FRL_ACT","citation":"Section 501; Schedule 4, Public Interest Criterion 4001","frl_title_id":"C2024C00195","series":"Migration Act 1958","notes":"Character test under s.501 applies to all permanent visa grants."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-independent-189/documents","title":"Skilled Independent visa 189 — Documents","last_checked":"2025-02-01"}]',
        '2012-07-01', NULL,
        '{"inputs":["criminal_history","countries_lived_12mo","police_clearance_obtained"],"outputs":["FLAG-189-POLICE-MISSING","FLAG-189-CHAR-HISTORY"],"logic_notes":"Police clearances required per country of residence. Must be current at lodgement. Character concerns escalate to RMA."}',
        'high', '2025-02-01T00:00:00Z'
    )
) AS r(req_type, title, plain_english, legal_basis, operational_basis, effective_from, effective_to, rule_logic, confidence, last_reviewed_at)
WHERE vs.subclass_code = '189' AND vs.stream IS NULL
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
    ('Positive Skills Assessment',
     'Skills assessment from relevant assessing body',
     'Confirms qualifications and experience are suitable for the nominated occupation — a mandatory eligibility requirement for the 189 visa.',
     '["Engineers Australia assessment outcome letter","VETASSESS assessment outcome","ACS (Australian Computer Society) assessment","AHPRA registration (health professions)"]',
     '["Assessment from wrong authority for the ANZSCO code","Assessment expired — validity periods typically 3 years","Occupation on assessment differs from nominated occupation","Assessment does not cover the claimed work experience period"]',
     1, '2012-07-01', NULL),
    ('Valid Invitation to Apply',
     'Invitation to Apply (ITA) from SkillSelect',
     'Confirms the applicant was lawfully invited to apply for the 189 visa through their SkillSelect EOI — a mandatory precondition for lodgement.',
     '["SkillSelect Invitation to Apply letter received by email","Expression of Interest (EOI) submission confirmation from SkillSelect"]',
     '["ITA has expired — typically 60 days from issue date","ITA details (occupation, points) do not match final application","No ITA received — application cannot proceed"]',
     1, '2012-07-01', NULL),
    ('English Language Proficiency',
     'English language test result',
     'Demonstrates competent English proficiency and supports points claimed for English ability.',
     '["IELTS Academic - minimum 6.0 each band for 10 points, 7.0 for 20 points","PTE Academic score report from Pearson","TOEFL iBT score report from ETS","OET result letter (health professions)"]',
     '["Using IELTS General Training instead of IELTS Academic","Test result more than 3 years old at expected decision date","Single sub-band below minimum even when overall score passes","Points claimed for English level not matched by test scores"]',
     1, '2012-07-01', NULL),
    ('Minimum Points Score',
     'Employment history evidence',
     'Supports points claimed for skilled employment experience in the nominated occupation.',
     '["Reference letters from all employers on company letterhead stating role, dates, hours, and duties","Payslips matching the claimed employment period","Employment contracts for each role","Statutory declarations from supervisors for roles where letters are unavailable"]',
     '["Reference letters lack dates, hours, or duty descriptions","Gaps in employment timeline not explained","Payslips do not cover the full period claimed","Overseas employer letters not translated into English"]',
     1, '2012-07-01', NULL),
    ('Minimum Points Score',
     'Academic qualifications',
     'Supports points claimed for educational qualifications in the points test.',
     '["Bachelor degree certificate and academic transcript","Masters degree certificate and academic transcript","Statement of attainment for relevant qualifications"]',
     '["Degree not from a recognised institution","Qualification level claimed differs from actual qualification","Transcripts missing or only partial"]',
     1, '2012-07-01', NULL),
    ('Health Requirement',
     'Health examination (HAP ID)',
     'Confirms health examination has been booked and completed through an approved panel physician for Home Affairs review.',
     '["HAP ID confirmation email from Home Affairs","Panel physician booking confirmation","Completed health examination submitted via the HAP system"]',
     '["Health examination not booked — can take 2-4 weeks for results","HAP ID not yet issued — apply as early as possible","Results from previous visa application may have expired"]',
     1, '2012-07-01', NULL),
    ('Character Requirement',
     'Police clearance certificate',
     'Confirms the applicant meets character requirements by disclosing and clearing their criminal history across all countries of residence.',
     '["Australian Federal Police (AFP) national police check","Overseas police clearance certificates from all countries lived in 12+ months","Certified translations for non-English police certificates"]',
     '["AFP check is more than 12 months old at lodgement","Police certificates not obtained for all required countries","Non-English certificates submitted without certified translation","Certificates from overseas take longer than anticipated — allow 4-8 weeks"]',
     1, '2012-07-01', NULL)
) AS ev(req_title, label, what_it_proves, examples, common_gaps, priority, effective_from, effective_to)
WHERE vs.subclass_code = '189' AND vs.stream IS NULL
  AND req.title = ev.req_title
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 4. FLAG TEMPLATES
-- Severity: critical→risk | high→warning
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
        'Points claimed may exceed what evidence supports',
        '{"left_field":"claimed_points","operator":">","right_field":"evidenced_points"}',
        'Points claimed in your EOI must be supported by evidence at the time of invitation and application. Claiming points you cannot evidence — for experience, qualifications, or English — can lead to refusal.',
        '["Recalculate your points against the official points test schedule","Confirm each point claim is backed by a document","Pay particular attention to overseas employment — reference letters must clearly state dates, role, and hours"]',
        '["Detailed reference letters from all employers","Payslips covering claimed employment period","English test result matching the points band claimed","Degree certificates matching qualification points claimed"]',
        'risk', '2012-07-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Schedule 6D (Points test)","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-independent-189/points-test"}'
    ),
    (
        'Skills assessment may be invalid or expired',
        '{"all":[{"field":"skills_assessment_present","operator":"==","value":true},{"field":"skills_assessment_valid","operator":"==","value":false}]}',
        'Skills assessments have validity periods (typically 3 years from assessment date). An expired or invalid assessment means the core eligibility requirement cannot be met — the application will be refused.',
        '["Check the validity date on your assessment outcome letter","Apply for a reassessment if your assessment has expired","Confirm the assessing body is correct for your occupation and visa subclass"]',
        '["Skills assessment outcome letter showing validity period","Reassessment application confirmation if reassessment required"]',
        'risk', '2012-07-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Clause 189.213","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-independent-189/who-can-apply"}'
    ),
    (
        'Employment history has unexplained gaps',
        '{"field":"largest_timeline_gap_days","operator":">","value":90}',
        'Gaps in skilled employment can reduce points claims and raise questions about the continuity and authenticity of claimed skilled work experience. Unexplained gaps are a common reason for reduced points or additional document requests.',
        '["Account for all gaps in employment with a written explanation","Document any periods of study, self-employment, or travel","Ensure payslips and reference letters cover the full claimed employment period without gaps"]',
        '["Explanation letter addressing employment gaps","Statutory declarations from supervisors","Study or travel records covering gap periods"]',
        'warning', '2012-07-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Schedule 6D","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-independent-189"}'
    ),
    (
        'English test result may be expired',
        '{"field":"english_test_valid","operator":"==","value":false}',
        'English test results must be valid (within 3 years of the test date) at the time of application. An expired test means English points cannot be claimed and competent English cannot be demonstrated — a mandatory requirement.',
        '["Check the expiry date of your English test result","Book a resit if your result has or will expire before you expect to lodge","Consider sitting a higher-band test to maximise English points while eligible"]',
        '["Current IELTS / PTE / TOEFL score report within validity period"]',
        'warning', '2012-07-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Clause 189.215","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-independent-189/documents"}'
    )
) AS f(title, trigger_schema, why_it_matters, actions, evidence_examples, severity, effective_from, effective_to, sources)
WHERE vs.subclass_code = '189' AND vs.stream IS NULL
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 5. KB RELEASE TAG
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO kb_release (release_tag, created_at)
VALUES ('kb-v20260314-skilled-independent-189', NOW())
ON CONFLICT DO NOTHING;


COMMIT;

-- ─────────────────────────────────────────────────────────────────────
-- VERIFICATION QUERIES (run after applying)
-- ─────────────────────────────────────────────────────────────────────
-- SELECT COUNT(*) FROM requirement
--   WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '189');
-- Expected: 6
--
-- SELECT COUNT(*) FROM evidence_item
--   WHERE requirement_id IN (
--     SELECT requirement_id FROM requirement
--     WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '189')
--   );
-- Expected: 7
--
-- SELECT COUNT(*) FROM flag_template
--   WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '189');
-- Expected: 4
--
-- SELECT release_tag, created_at FROM kb_release ORDER BY created_at DESC LIMIT 3;
