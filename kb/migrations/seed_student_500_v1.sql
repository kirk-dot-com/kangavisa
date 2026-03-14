-- =====================================================================
-- KangaVisa Knowledge Base — Sprint 23
-- seed_student_500_v1.sql
-- =====================================================================
-- Seeds requirements, evidence items, and flag templates for:
--   500 (Student visa)
--
-- Source JSON files:
--   kb/seed/visa_500_requirements.json        (2 requirements)
--   kb/seed/visa_500_requirements_extra.json  (3 additional requirements)
--   kb/seed/visa_500_evidence_items.json      (2 evidence items)
--   kb/seed/visa_500_flags.json               (3 flag templates, array format)
--
-- Key 500 characteristics:
--   • Genuine Student requirement (replaced GTE in 2016) — balance-of-factors
--   • English proficiency set by LIN 19/051 — varies by provider/course type
--   • Financial capacity set by LIN 18/036 — tuition + living + travel
--   • Health examination required for most applicants
--   • Character requirement under s.501 Migration Act 1958
--
-- Flag severity mapping (from source):
--   "warning" → "warning" | "risk" → "risk" (already mapped in source)
--
-- Safe to run multiple times (ON CONFLICT DO NOTHING throughout).
-- =====================================================================

BEGIN;

-- ─────────────────────────────────────────────────────────────────────
-- 1. VISA SUBCLASS ROW
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO visa_subclass (subclass_code, stream, audience, canonical_info_url, last_verified_at)
VALUES (
    '500', NULL, 'B2C',
    'https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/student-500',
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
        'Genuine Student Requirement',
        'You must intend to stay in Australia temporarily and genuinely engage with your studies. Decision makers assess this by weighing your circumstances — including immigration and compliance history, ties to home country, economic situation, and whether the course is consistent with your future plans. This is a balance-of-factors test, not a pass/fail threshold.',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clause 500.212","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"Genuine Student condition introduced November 2016. Previously GTE."},{"authority":"FRL_ACT","citation":null,"frl_title_id":"C2024C00195","series":"Migration Act 1958","notes":null}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/student-500/temporary-student","title":"Student visa (subclass 500) — applying from outside Australia","last_checked":"2025-02-01"}]',
        '2016-11-19', NULL,
        '{"inputs":["immigration_history","compliance_record","home_country_ties","financial_circumstances","course_relevance_to_career","previous_study_completed"],"outputs":["FLAG-500-GS-TIES","FLAG-500-GS-COURSE-MISMATCH","FLAG-500-GS-COMPLIANCE"],"logic_notes":"Balance-of-factors test. No single factor is determinative. Officers must consider the totality. KangaVisa must NOT frame this as a pass/fail threshold."}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'english',
        'English Language Proficiency',
        'You must demonstrate sufficient English language ability to undertake your chosen course. Acceptable evidence includes an approved English test (IELTS, TOEFL iBT, PTE Academic, Cambridge C1/C2, OET), or prior study in an approved English-speaking country within the last two years. Minimum scores vary by course type and provider — check the current LIN 19/051 instrument.',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clause 500.213; Schedule 8, clause 8517","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"Score thresholds set by instrument."},{"authority":"FRL_INSTRUMENT","citation":"LIN 19/051","frl_title_id":"F2019L01030","series":"Migration (LIN 19/051 — English Language Requirements for the Student Visa) Instrument 2019","notes":null}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/student-500/temporary-student#Eligibility","title":"Student visa 500 — Eligibility — English language","last_checked":"2025-02-01"}]',
        '2019-07-01', NULL,
        '{"inputs":["english_test_type","english_test_score","english_test_date","course_type","provider_type","previous_study_english_country"],"outputs":["FLAG-500-ENG-SCORE-LOW","FLAG-500-ENG-EXPIRED","FLAG-500-ENG-EXEMPTION"],"logic_notes":"Test results must be no more than 3 years old at time of decision. Minimum band scores vary by provider and course level — see Instrument LIN 19/051."}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'financial',
        'Financial Capacity',
        'You must demonstrate sufficient funds to cover tuition fees, living expenses, and return travel for yourself and any accompanying family members. The minimum threshold is set by legislative instrument (LIN 18/036) and assessed at the time of application. Funds must be accessible and genuine — unexplained deposits or inconsistent account history are risk indicators.',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clause 500.211","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"Financial capacity is a Schedule 2 criterion for subclass 500."},{"authority":"FRL_INSTRUMENT","citation":"LIN 18/036","frl_title_id":"F2018L00898","series":"Migration (LIN 18/036 — Student Financial Capacity) Instrument 2018","notes":"Sets minimum financial thresholds. Check for superseding instruments."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/student-500/temporary-student#Eligibility","title":"Student visa 500 — Financial capacity","last_checked":"2025-02-01"}]',
        '2019-07-01', NULL,
        '{"inputs":["annual_tuition_aud","living_expenses_aud","dependants_count","savings_evidence_type"],"outputs":["FLAG-500-FIN-INSUFFICIENT","FLAG-500-FIN-SOURCE-UNCLEAR"],"logic_notes":"Funds must be accessible and genuinely available. Unexplained deposits or inconsistent account history are risk indicators."}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'health',
        'Health Requirement',
        'You and all family members included on your application must meet the health requirement (PIC 4005). This typically requires completing an immigration medical examination with an approved panel physician. Some applicants may be exempt based on their country of origin and intended length of stay.',
        '[{"authority":"FRL_REGS","citation":"Schedule 4, Public Interest Criterion 4005","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"PIC 4005 — health requirement applicable to student visa."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/entering-and-leaving-australia/entering-australia/health-examinations","title":"Health examinations","last_checked":"2025-02-01"}]',
        '2016-11-19', NULL,
        '{"inputs":["country_of_origin","intended_stay_months","medical_exam_completed"],"outputs":["FLAG-500-HLTH-EXAM-REQUIRED","FLAG-500-HLTH-EXEMPT"],"logic_notes":"Applicants from high-risk countries or planning stays >12 months are typically required to complete a medical."}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'character',
        'Character Requirement',
        'You must satisfy the character requirement under section 501 of the Migration Act 1958. This includes not having a substantial criminal record and not posing a risk to the Australian community. Police clearance certificates are required from all countries where you have lived for 12 or more months in the past 10 years (from age 16).',
        '[{"authority":"FRL_ACT","citation":"Section 501; Schedule 4, Public Interest Criterion 4001","frl_title_id":"C2024C00195","series":"Migration Act 1958","notes":"Character test provisions under s.501 apply to all visa grants."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/student-500","title":"Student visa 500 — character requirement","last_checked":"2025-02-01"}]',
        '2016-11-19', NULL,
        '{"inputs":["criminal_history","countries_lived_12mo","police_clearance_obtained"],"outputs":["FLAG-500-CHAR-POLICE-MISSING","FLAG-500-CHAR-HISTORY"],"logic_notes":"Police clearances required per country of residence. Timing: must be recent at lodgement. Character concerns are ministerial discretion — escalate with RMA."}',
        'high', '2025-02-01T00:00:00Z'
    )
) AS r(req_type, title, plain_english, legal_basis, operational_basis, effective_from, effective_to, rule_logic, confidence, last_reviewed_at)
WHERE vs.subclass_code = '500' AND vs.stream IS NULL
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
    ('Genuine Student Requirement',
     'Confirmation of Enrolment (CoE)',
     'Demonstrates enrolment in a registered CRICOS course, anchoring the applicant to a specific approved course and supporting genuine student intent.',
     '["CoE letter from the university or college listing course name, CRICOS code, commencement date, and duration","CoE from PRISMS portal (government-issued confirmation)"]',
     '["CoE issued before course was formally confirmed — reissue required if course details change","CoE for a different course than the one being applied for","CoE issued more than 12 months before application without explanation","No CRICOS code visible on the document"]',
     1, '2016-11-19', NULL),
    ('English Language Proficiency',
     'Approved English Language Test Result',
     'Demonstrates the applicant meets the English proficiency threshold for their course type and provider. Accepted tests: IELTS Academic, TOEFL iBT, PTE Academic, Cambridge C1/C2, OET.',
     '["IELTS Academic Test Report Form (TRF) with overall band and all sub-scores visible","TOEFL iBT score report from ETS (My Best Scores or single-sitting)","PTE Academic Score Report from Pearson","Cambridge C1 Advanced or C2 Proficiency Certificate of Results","OET Result Letter (for health professions pathway)"]',
     '["Test result more than 3 years old at expected date of decision — rebook required","Using IELTS General Training instead of IELTS Academic","One or more sub-band scores below the minimum even when overall passes — all bands must individually meet threshold","No test booking made yet — creates timeline risk if result takes 2–4 weeks"]',
     1, '2019-07-01', NULL)
) AS ev(req_title, label, what_it_proves, examples, common_gaps, priority, effective_from, effective_to)
WHERE vs.subclass_code = '500' AND vs.stream IS NULL
  AND req.title = ev.req_title
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 4. FLAG TEMPLATES
-- Source: visa_500_flags.json — flat array format
-- Severities sourced directly (warning, risk) — no mapping needed
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
        'Weak ties to home country',
        '{"conditions":["home_country_ties_evidence = none OR weak","immigration_history_concerns = true"]}',
        'Decision makers assess genuine student intention by weighing circumstances including ties to home country (property, family, employment prospects). Weak or unexplained ties may indicate the applicant does not intend to return, which is a risk indicator under clause 500.212.',
        '["Document family members, assets, or employment prospects in home country","Explain how the study aligns with your career goals at home","Provide a personal statement addressing your intention to return","Gather any supporting evidence: property, family responsibilities, business interests"]',
        '["Bank statements or property ownership documents in home country","Family situation statement (dependants, spouse, parents)","Employer letter from home country confirming re-employment post-study","Career plan showing connection between course and home-country goals"]',
        'warning', '2016-11-19', NULL,
        '{"legislation":"Migration Regulations 1994 — Schedule 2, clause 500.212","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/student-500/temporary-student"}'
    ),
    (
        'Course inconsistent with prior study or career path',
        '{"conditions":["course_relevance_to_career = low OR none","previous_study_unrelated = true"]}',
        'The Genuine Student test includes an assessment of whether the course is consistent with the applicant''s stated career goals. A mismatch between academic background, work experience, and enrolled course is a known risk indicator.',
        '["Write a clear course choice statement explaining why this course suits your goals","Highlight any transferable skills or prior learning connecting past and present study","Obtain a letter from your education provider if course counselling was involved","If changing fields, document your career pivoting rationale clearly"]',
        '["Personal statement linking course to career plan","Letter from current or prospective employer in target field","Transcript or certificate showing relevant prior knowledge","Skills assessment or industry report supporting field transition"]',
        'warning', '2016-11-19', NULL,
        '{"legislation":"Migration Regulations 1994 — Schedule 2, clause 500.212","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/student-500/temporary-student"}'
    ),
    (
        'English test score below typical threshold for course type',
        '{"conditions":["english_test_score < minimum_for_course_level"]}',
        'Minimum English scores are set by LIN 19/051 and vary by provider type and course level. Submitting a score below the required threshold will result in the application being refused. Sub-band scores below the minimum are also grounds for refusal even if the overall score passes.',
        '["Check the exact minimum score for your course provider type (ELICOS, higher ed, VET, school)","Retake the English test if your score is below the required minimum","Ensure your test result is not more than 3 years old at the time of decision","Confirm if an exemption applies (e.g., prior study in an approved English-speaking country)"]',
        '["IELTS, TOEFL iBT, PTE Academic, Cambridge C1/C2, or OET test report form","Evidence of prior study in an approved English-speaking country (transcripts + enrolment confirmation)","Confirmation of exemption from education provider if applicable"]',
        'risk', '2019-07-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Schedule 2, clause 500.213; LIN 19/051 (F2019L01030)","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/student-500/temporary-student#Eligibility"}'
    )
) AS f(title, trigger_schema, why_it_matters, actions, evidence_examples, severity, effective_from, effective_to, sources)
WHERE vs.subclass_code = '500' AND vs.stream IS NULL
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 5. KB RELEASE TAG
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO kb_release (release_tag, created_at)
VALUES ('kb-v20260314-student-500', NOW())
ON CONFLICT DO NOTHING;


COMMIT;

-- ─────────────────────────────────────────────────────────────────────
-- VERIFICATION QUERIES (run after applying)
-- ─────────────────────────────────────────────────────────────────────
-- SELECT COUNT(*) FROM requirement
--   WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '500');
-- Expected: 5
--
-- SELECT COUNT(*) FROM evidence_item
--   WHERE requirement_id IN (
--     SELECT requirement_id FROM requirement
--     WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '500')
--   );
-- Expected: 2
--
-- SELECT COUNT(*) FROM flag_template
--   WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '500');
-- Expected: 3
--
-- SELECT release_tag, created_at FROM kb_release ORDER BY created_at DESC LIMIT 3;
