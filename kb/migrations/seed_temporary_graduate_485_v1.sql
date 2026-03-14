-- =====================================================================
-- KangaVisa Knowledge Base — Sprint 22
-- seed_temporary_graduate_485_v1.sql
-- =====================================================================
-- Seeds requirements, evidence items, and flag templates for:
--   485 (Temporary Graduate visa — Graduate Work + Post-Study Work streams)
--
-- Source JSON files:
--   kb/seed/visa_485_requirements.json   (3 requirements)
--   kb/seed/visa_485_evidence_items.json (4 evidence items)
--   kb/seed/visa_485_flags.json          (5 flag templates, wrapped format)
--
-- Key 485 characteristics:
--   • Two streams: Graduate Work (skilled occupation) and Post-Study Work (degree level)
--   • Must lodge within 6 months of completing the qualifying Australian course
--   • CRICOS-registered course required; minimum 2 years full-time study
--   • English requirement: competent English (IELTS 6.0 each band or equivalent)
--   • Exemptions for citizens of UK, USA, Canada, NZ, Ireland
--
-- Flag severity mapping:
--   "critical" → "risk" | "high" → "warning" | "medium" → "warning"
--
-- Safe to run multiple times (ON CONFLICT DO NOTHING throughout).
-- =====================================================================

BEGIN;

-- ─────────────────────────────────────────────────────────────────────
-- 1. VISA SUBCLASS ROW
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO visa_subclass (subclass_code, stream, audience, canonical_info_url, last_verified_at)
VALUES (
    '485', NULL, 'B2C',
    'https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485',
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
        'Genuine Temporary Entrant',
        'You must intend to stay temporarily in Australia. Decision makers assess your circumstances including home-country ties, economic situation, immigration history, and compliance record. This is a balance-of-factors test — not a simple pass/fail.',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clause 485.213","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"GTE applies to Temporary Graduate visa subclass 485."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485","title":"Temporary Graduate visa (subclass 485)","last_checked":"2025-02-01"}]',
        '2013-11-16', NULL,
        '{"inputs":["home_country_ties","immigration_history","compliance_record","economic_circumstances"],"outputs":["FLAG-485-GTE-WEAK-TIES","FLAG-485-GTE-COMPLIANCE"],"logic_notes":"Same balance-of-factors test as 500 GTE. KangaVisa must not frame as pass/fail."}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'other',
        'Australian Qualification Requirement',
        'You must have completed a qualification that required at least 2 years of full-time study in Australia. The course must have been registered with CRICOS and completed within 6 months of lodging your 485 application. The 6-month window is strict — missing it means ineligibility.',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clause 485.211; clause 485.212","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"Graduate stream — completed within 6 months of application."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485/graduate-stream","title":"Temporary Graduate visa 485 — Graduate stream","last_checked":"2025-02-01"}]',
        '2013-11-16', NULL,
        '{"inputs":["course_cricos_registered","study_duration_years","completion_date","lodgement_date"],"outputs":["FLAG-485-QUAL-TIMING","FLAG-485-QUAL-DURATION"],"logic_notes":"6-month window is strict. If completion date + 6 months < lodgement date, applicant is ineligible. Timing risk is a primary refusal cause."}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'english',
        'English Language Proficiency',
        'You must demonstrate competent English. Acceptable tests include IELTS (minimum 6.0 each band), TOEFL iBT, PTE Academic, Cambridge C1/C2, or OET. Exemptions may apply based on citizenship of certain countries (UK, USA, Canada, NZ, Ireland). Test results must not be more than 3 years old at time of decision.',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clause 485.221","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"English requirement for 485. Minimum scores may differ from 500 — check current instrument."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485","title":"Temporary Graduate visa 485 — English requirements","last_checked":"2025-02-01"}]',
        '2020-07-01', NULL,
        '{"inputs":["english_test_type","english_test_score","english_test_date","citizenship_country"],"outputs":["FLAG-485-ENG-SCORE","FLAG-485-ENG-EXPIRED","FLAG-485-ENG-EXEMPT"],"logic_notes":"Test results must not be more than 3 years old at time of decision. Exemptions exist for citizens of UK, USA, Canada, NZ, Ireland."}',
        'high', '2025-02-01T00:00:00Z'
    )
) AS r(req_type, title, plain_english, legal_basis, operational_basis, effective_from, effective_to, rule_logic, confidence, last_reviewed_at)
WHERE vs.subclass_code = '485' AND vs.stream IS NULL
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
    ('Australian Qualification Requirement',
     'Award certificate or testamur',
     'Confirms completion of an eligible CRICOS-registered qualification at an Australian institution.',
     '["Official award certificate or testamur from the Australian education provider","If not yet issued, an official completion letter with expected award date"]',
     '["Certificate not yet issued — use official completion letter","Name on certificate differs from passport name — include a name change document","Qualification not CRICOS-registered"]',
     1, '2013-11-16', NULL),
    ('Australian Qualification Requirement',
     'Official academic transcript',
     'Provides detailed evidence of course completion and study duration to meet the 2-year minimum study requirement.',
     '["Official sealed or stamped transcript from the Australian education provider","Electronic versions issued directly by the institution"]',
     '["Unofficial transcript printed from student portal — must be official sealed copy","Credits from overseas transferred — Australian study periods must be clearly shown"]',
     1, '2013-11-16', NULL),
    ('Australian Qualification Requirement',
     'eCoE (Electronic Confirmation of Enrolment)',
     'Confirms enrolment in a CRICOS-registered course — used to verify eligibility period and course duration.',
     '["eCoE from your CRICOS-registered education provider showing course details and study period","Available from student portal or education provider"]',
     '["eCoE expired or cancelled — request an updated eCoE from your provider","Course listed is not CRICOS-registered"]',
     2, '2013-11-16', NULL),
    ('English Language Proficiency',
     'English language test result',
     'Demonstrates the applicant meets the English language requirement for subclass 485.',
     '["Original test report form from IELTS, TOEFL iBT, PTE Academic, Cambridge C1/C2, or OET","Must show minimum competent English scores for each component"]',
     '["Test result more than 3 years old at time of decision","One or more band scores below the minimum threshold","Test type not approved for migration purposes"]',
     1, '2020-07-01', NULL)
) AS ev(req_title, label, what_it_proves, examples, common_gaps, priority, effective_from, effective_to)
WHERE vs.subclass_code = '485' AND vs.stream IS NULL
  AND req.title = ev.req_title
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 4. FLAG TEMPLATES
-- Source: visa_485_flags.json — wrapped {"flags": [...]} format
-- Severity mapping: critical→risk, high→warning, medium→warning
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
        'Application timing may be outside the lodgement window',
        '{"field":"days_remaining_lodgement_window","operator":"<","value":30}',
        'The Temporary Graduate visa must be lodged within 6 months of completing eligible Australian studies. Missing this window means becoming ineligible for this pathway entirely — no extension is available.',
        '["Confirm your course completion date and calculate the lodgement window precisely","Lodge as early as possible once eligible","Ensure you hold a bridging visa if your current visa expires before lodgement"]',
        '["Course completion letter confirming completion date","Academic transcript showing final semester grades","eCoE showing expected completion date"]',
        'risk', '2013-11-16', NULL,
        '{"legislation":"Migration Regulations 1994 — Schedule 2, Clause 485.212","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485"}'
    ),
    (
        'Selected visa stream may not match your circumstances',
        '{"field":"stream_profile_match","operator":"==","value":false}',
        'The 485 visa has two streams: Graduate Work (for specific skilled occupations requiring skills assessment) and Post-Study Work (for Bachelor, Masters, or Doctoral degree holders). Selecting the wrong stream results in ineligibility.',
        '["Confirm which stream applies to your qualification and occupation before lodging","Graduate Work stream — requires occupation on relevant skilled occupation list and skills assessment","Post-Study Work stream — requires Australian Bachelor, Masters, or Doctoral degree"]',
        '["Degree certificate specifying qualification level (Bachelor/Masters/Doctoral)","Skills assessment from relevant assessing authority (Graduate Work stream)","Academic transcript confirming Australian institution"]',
        'warning', '2013-11-16', NULL,
        '{"legislation":"Migration Regulations 1994 — Clauses 485.214, 485.215","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485/temporary-graduate-visa-485-streams"}'
    ),
    (
        'Police check may be missing or expired',
        '{"all":[{"field":"police_check_required","operator":"==","value":true},{"field":"police_check_present","operator":"==","value":false}]}',
        'Applicants who have spent 12 or more months in certain countries must provide a police clearance certificate. Missing or expired police checks are a common cause of processing delays and requests for further information.',
        '["Obtain police clearance certificates from all countries where you have lived 12+ months","Ensure each certificate is current — most must be obtained within 12 months of application","Include certified translations for non-English certificates"]',
        '["Australian Federal Police (AFP) check","Overseas police clearance certificate","Certified translation if non-English"]',
        'warning', '2013-11-16', NULL,
        '{"legislation":"Migration Regulations 1994 — Clause 485.225","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485/documents"}'
    ),
    (
        'English language evidence may be insufficient or expired',
        '{"field":"english_evidence_valid","operator":"==","value":false}',
        'The 485 visa requires evidence of functional English. IELTS/PTE/TOEFL scores expire after 3 years. Native English speakers or Australian degree holders may be exempt but should confirm their exemption basis with evidence.',
        '["Confirm whether your English test result is still within the 3-year validity period","Check if you qualify for an exemption (citizen of English-speaking country, or Australian degree completed in English)","Resit the English test if your scores have expired"]',
        '["IELTS, PTE, TOEFL, OET, or Cambridge test result within validity","Passport from English-speaking country (if exempt)","Letter confirming degree was delivered in English"]',
        'warning', '2013-11-16', NULL,
        '{"legislation":"Migration Regulations 1994 — Clause 485.222","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485/documents"}'
    ),
    (
        'Health examination not completed',
        '{"field":"health_exam_completed","operator":"==","value":false}',
        'All 485 applicants must meet health requirements (PIC 4005). Health examinations are conducted by approved panel physicians and results are submitted directly to Home Affairs. Results can take several weeks — arrange early.',
        '["Book a health examination with an approved panel physician as early as possible","Check if results from a recent related visa application can be reused","Allow 2–4 weeks for examination results to be submitted to Home Affairs"]',
        '["HAP ID confirming health examination is booked","Confirmation from approved panel physician"]',
        'warning', '2013-11-16', NULL,
        '{"legislation":"Migration Regulations 1994 — Clause 485.223","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485/documents"}'
    )
) AS f(title, trigger_schema, why_it_matters, actions, evidence_examples, severity, effective_from, effective_to, sources)
WHERE vs.subclass_code = '485' AND vs.stream IS NULL
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 5. KB RELEASE TAG
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO kb_release (release_tag, created_at)
VALUES ('kb-v20260314-temporary-graduate-485', NOW())
ON CONFLICT DO NOTHING;


COMMIT;

-- ─────────────────────────────────────────────────────────────────────
-- VERIFICATION QUERIES (run after applying)
-- ─────────────────────────────────────────────────────────────────────
-- SELECT COUNT(*) FROM requirement
--   WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '485');
-- Expected: 3
--
-- SELECT COUNT(*) FROM evidence_item
--   WHERE requirement_id IN (
--     SELECT requirement_id FROM requirement
--     WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '485')
--   );
-- Expected: 4
--
-- SELECT COUNT(*) FROM flag_template
--   WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '485');
-- Expected: 5
--
-- SELECT release_tag, created_at FROM kb_release ORDER BY created_at DESC LIMIT 3;
