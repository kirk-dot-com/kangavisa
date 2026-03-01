-- ============================================================
-- KangaVisa KB Seed — v1
-- Generated: 2026-03-01 01:37 UTC
-- US-F6 | FR-K1, FR-K2, FR-K3
-- Idempotent: safe to re-run (ON CONFLICT DO NOTHING)
-- ============================================================

-- ---- 1. Visa subclasses ----
INSERT INTO visa_subclass (visa_id, subclass_code, stream, audience, canonical_info_url, last_verified_at)
  VALUES ('7f342e2f-ddb0-5990-8d88-fe1a001011d8'::uuid, '500', NULL, 'B2C'::kb_audience, 'https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/student-500', '2026-03-01T01:37:20.902993Z')
  ON CONFLICT DO NOTHING;

INSERT INTO visa_subclass (visa_id, subclass_code, stream, audience, canonical_info_url, last_verified_at)
  VALUES ('58ee7773-cf74-5ac6-a889-17f2ac82136f'::uuid, '485', NULL, 'B2C'::kb_audience, 'https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485', '2026-03-01T01:37:20.903023Z')
  ON CONFLICT DO NOTHING;

INSERT INTO visa_subclass (visa_id, subclass_code, stream, audience, canonical_info_url, last_verified_at)
  VALUES ('c8e0b614-d7c3-5ec5-ae43-34ba8c9f1942'::uuid, '482', NULL, 'Both'::kb_audience, 'https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-skill-shortage-482', '2026-03-01T01:37:20.903040Z')
  ON CONFLICT DO NOTHING;

INSERT INTO visa_subclass (visa_id, subclass_code, stream, audience, canonical_info_url, last_verified_at)
  VALUES ('c31dbb82-8012-57f6-9cdc-606bbc3590c0'::uuid, '417', NULL, 'B2C'::kb_audience, 'https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/work-holiday-417', '2026-03-01T01:37:20.903054Z')
  ON CONFLICT DO NOTHING;

INSERT INTO visa_subclass (visa_id, subclass_code, stream, audience, canonical_info_url, last_verified_at)
  VALUES ('7eca8282-3da9-5aca-b66b-21c39ad551c5'::uuid, '820', NULL, 'B2C'::kb_audience, 'https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-onshore-820-801', '2026-03-01T01:37:20.903067Z')
  ON CONFLICT DO NOTHING;


-- ---- 2. Requirements ----
-- Subclass 500 requirements
INSERT INTO requirement
  (requirement_id, visa_id, requirement_type, title, plain_english,
   legal_basis, operational_basis, rule_logic, effective_from, effective_to,
   confidence, last_reviewed_at)
VALUES (
  'ec222e1d-b21d-53fb-a218-711ebdec6d8e'::uuid,
  '7f342e2f-ddb0-5990-8d88-fe1a001011d8'::uuid,
  'genuine'::kb_requirement_type,
  'Genuine Student Requirement',
  'You must intend to stay in Australia temporarily and genuinely engage with your studies. Decision makers assess this by weighing your circumstances, including your immigration and compliance history, ties to home country, economic situation, and course consistency with your future plans.',
  '[{"authority": "FRL_REGS", "citation": "Schedule 2, clause 500.212", "frl_title_id": "F2022C00125", "series": "Migration Regulations 1994", "notes": "Genuine Student condition introduced 2016. Previously ''Genuine Temporary Entrant'' (GTE)."}, {"authority": "FRL_ACT", "citation": null, "frl_title_id": "C2024C00195", "series": "Migration Act 1958", "notes": null}]'::jsonb,
  '[{"authority": "HOMEAFFAIRS_PAGE", "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/student-500/temporary-student", "title": "Student visa (subclass 500) — applying from outside Australia", "last_checked": "2025-02-01"}]'::jsonb,
  '{"inputs": ["immigration_history", "compliance_record", "home_country_ties", "financial_circumstances", "course_relevance_to_career", "previous_study_completed"], "outputs": ["FLAG-500-GS-TIES", "FLAG-500-GS-COURSE-MISMATCH", "FLAG-500-GS-COMPLIANCE"], "logic_notes": "Balance-of-factors test. No single factor is determinative. Officers must consider the totality. KangaVisa must NOT frame this as a pass/fail threshold."}'::jsonb,
  '2016-11-19',
  NULL,
  'high'::kb_confidence,
  '2025-02-01T00:00:00Z'
) ON CONFLICT (requirement_id) DO NOTHING;

INSERT INTO requirement
  (requirement_id, visa_id, requirement_type, title, plain_english,
   legal_basis, operational_basis, rule_logic, effective_from, effective_to,
   confidence, last_reviewed_at)
VALUES (
  'a86d3e75-39bb-5b4c-8c23-29f0e51ae70e'::uuid,
  '7f342e2f-ddb0-5990-8d88-fe1a001011d8'::uuid,
  'english'::kb_requirement_type,
  'English Language Proficiency',
  'You must demonstrate sufficient English language ability to undertake your chosen course. Acceptable evidence includes an approved English test (IELTS, TOEFL iBT, PTE Academic, Cambridge C1/C2, OET), or study in an approved English-speaking country within the last two years. Minimum scores vary by course and provider type.',
  '[{"authority": "FRL_REGS", "citation": "Schedule 2, clause 500.213; Schedule 8, clause 8517", "frl_title_id": "F2022C00125", "series": "Migration Regulations 1994", "notes": "Score thresholds set by instrument. Instrument details captured in instrument.jsonschema objects."}, {"authority": "FRL_INSTRUMENT", "citation": "LIN 19/051", "frl_title_id": "F2019L01030", "series": "Migration (LIN 19/051 — English Language Requirements for the Student Visa) Instrument 2019", "notes": null}]'::jsonb,
  '[{"authority": "HOMEAFFAIRS_PAGE", "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/student-500/temporary-student#Eligibility", "title": "Student visa 500 — Eligibility — English language", "last_checked": "2025-02-01"}]'::jsonb,
  '{"inputs": ["english_test_type", "english_test_score", "english_test_date", "course_type", "provider_type", "previous_study_english_country"], "outputs": ["FLAG-500-ENG-SCORE-LOW", "FLAG-500-ENG-EXPIRED", "FLAG-500-ENG-EXEMPTION"], "logic_notes": "Test results must be no more than 3 years old at time of decision. Minimum band scores vary by provider and course level — see Instrument LIN 19/051."}'::jsonb,
  '2019-07-01',
  NULL,
  'high'::kb_confidence,
  '2025-02-01T00:00:00Z'
) ON CONFLICT (requirement_id) DO NOTHING;

INSERT INTO requirement
  (requirement_id, visa_id, requirement_type, title, plain_english,
   legal_basis, operational_basis, rule_logic, effective_from, effective_to,
   confidence, last_reviewed_at)
VALUES (
  'd143b705-1b29-52ad-81ca-fb10d2b159a2'::uuid,
  '7f342e2f-ddb0-5990-8d88-fe1a001011d8'::uuid,
  'financial'::kb_requirement_type,
  'Financial Capacity',
  'You must demonstrate sufficient funds to cover tuition fees, living expenses, and return travel for yourself and any accompanying family members. The threshold is set by legislative instrument and is assessed at the time of application.',
  '[{"authority": "FRL_REGS", "citation": "Schedule 2, clause 500.211", "frl_title_id": "F2022C00125", "series": "Migration Regulations 1994", "notes": "Financial capacity is a Schedule 2 criterion for subclass 500."}, {"authority": "FRL_INSTRUMENT", "citation": "LIN 18/036", "frl_title_id": "F2018L00898", "series": "Migration (LIN 18/036 — Student Financial Capacity) Instrument 2018", "notes": "Sets minimum financial thresholds. Check for superseding instruments."}]'::jsonb,
  '[{"authority": "HOMEAFFAIRS_PAGE", "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/student-500/temporary-student#Eligibility", "title": "Student visa 500 — Financial capacity", "last_checked": "2025-02-01"}]'::jsonb,
  '{"inputs": ["annual_tuition_aud", "living_expenses_aud", "dependants_count", "savings_evidence_type"], "outputs": ["FLAG-500-FIN-INSUFFICIENT", "FLAG-500-FIN-SOURCE-UNCLEAR"], "logic_notes": "Funds must be accessible and genuinely available. Unexplained deposits or inconsistent account history are risk indicators."}'::jsonb,
  '2019-07-01',
  NULL,
  'high'::kb_confidence,
  '2025-02-01T00:00:00Z'
) ON CONFLICT (requirement_id) DO NOTHING;

INSERT INTO requirement
  (requirement_id, visa_id, requirement_type, title, plain_english,
   legal_basis, operational_basis, rule_logic, effective_from, effective_to,
   confidence, last_reviewed_at)
VALUES (
  '4f76e51e-e065-5443-aa13-6abf002b2e47'::uuid,
  '7f342e2f-ddb0-5990-8d88-fe1a001011d8'::uuid,
  'health'::kb_requirement_type,
  'Health Requirement',
  'You and all family members included on your application must meet the health requirement. This typically requires completing an immigration medical examination with an approved panel physician. Some applicants may be exempt based on their country of origin and length of stay.',
  '[{"authority": "FRL_REGS", "citation": "Schedule 4, Public Interest Criterion 4005", "frl_title_id": "F2022C00125", "series": "Migration Regulations 1994", "notes": "PIC 4005 — health requirement applicable to student visa."}]'::jsonb,
  '[{"authority": "HOMEAFFAIRS_PAGE", "url": "https://immi.homeaffairs.gov.au/entering-and-leaving-australia/entering-australia/health-examinations", "title": "Health examinations", "last_checked": "2025-02-01"}]'::jsonb,
  '{"inputs": ["country_of_origin", "intended_stay_months", "medical_exam_completed"], "outputs": ["FLAG-500-HLTH-EXAM-REQUIRED", "FLAG-500-HLTH-EXEMPT"], "logic_notes": "Applicants from high-risk countries or planning stays >12 months are typically required to complete a medical."}'::jsonb,
  '2016-11-19',
  NULL,
  'high'::kb_confidence,
  '2025-02-01T00:00:00Z'
) ON CONFLICT (requirement_id) DO NOTHING;

INSERT INTO requirement
  (requirement_id, visa_id, requirement_type, title, plain_english,
   legal_basis, operational_basis, rule_logic, effective_from, effective_to,
   confidence, last_reviewed_at)
VALUES (
  '7101e7d6-baa5-5108-9ffe-cd6442c6b9a1'::uuid,
  '7f342e2f-ddb0-5990-8d88-fe1a001011d8'::uuid,
  'character'::kb_requirement_type,
  'Character Requirement',
  'You must satisfy the character requirement under section 501 of the Migration Act 1958. This includes not having a substantial criminal record and not posing a risk to the Australian community. Most applicants will need to provide police clearance certificates from countries where they have lived for 12 months or more in the past 10 years (from age 16).',
  '[{"authority": "FRL_ACT", "citation": "Section 501; Schedule 4, Public Interest Criterion 4001", "frl_title_id": "C2024C00195", "series": "Migration Act 1958", "notes": "Character test provisions under s.501 apply to all visa grants."}]'::jsonb,
  '[{"authority": "HOMEAFFAIRS_PAGE", "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/student-500", "title": "Student visa 500 — character requirement", "last_checked": "2025-02-01"}]'::jsonb,
  '{"inputs": ["criminal_history", "countries_lived_12mo", "police_clearance_obtained"], "outputs": ["FLAG-500-CHAR-POLICE-MISSING", "FLAG-500-CHAR-HISTORY"], "logic_notes": "Police clearances required per country of residence. Timing: must be recent at lodgement. Character concerns are ministerial discretion — escalate with RMA."}'::jsonb,
  '2016-11-19',
  NULL,
  'high'::kb_confidence,
  '2025-02-01T00:00:00Z'
) ON CONFLICT (requirement_id) DO NOTHING;


-- Subclass 485 requirements
INSERT INTO requirement
  (requirement_id, visa_id, requirement_type, title, plain_english,
   legal_basis, operational_basis, rule_logic, effective_from, effective_to,
   confidence, last_reviewed_at)
VALUES (
  'beeb6c1e-ddea-5f18-9a49-a9bdc8c06854'::uuid,
  '58ee7773-cf74-5ac6-a889-17f2ac82136f'::uuid,
  'genuine'::kb_requirement_type,
  'Genuine Temporary Entrant',
  'You must intend to stay temporarily in Australia. Decision makers assess your circumstances including home-country ties, economic situation, immigration history, and compliance record. This is a balance-of-factors test.',
  '[{"authority": "FRL_REGS", "citation": "Schedule 2, clause 485.213", "frl_title_id": "F2022C00125", "series": "Migration Regulations 1994", "notes": "GTE applies to Temporary Graduate visa subclass 485."}]'::jsonb,
  '[{"authority": "HOMEAFFAIRS_PAGE", "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485", "title": "Temporary Graduate visa (subclass 485)", "last_checked": "2025-02-01"}]'::jsonb,
  '{"inputs": ["home_country_ties", "immigration_history", "compliance_record", "economic_circumstances"], "outputs": ["FLAG-485-GTE-WEAK-TIES", "FLAG-485-GTE-COMPLIANCE"], "logic_notes": "Same balance-of-factors test as 500 GTE. KangaVisa must not frame as pass/fail."}'::jsonb,
  '2013-11-16',
  NULL,
  'high'::kb_confidence,
  '2025-02-01T00:00:00Z'
) ON CONFLICT (requirement_id) DO NOTHING;

INSERT INTO requirement
  (requirement_id, visa_id, requirement_type, title, plain_english,
   legal_basis, operational_basis, rule_logic, effective_from, effective_to,
   confidence, last_reviewed_at)
VALUES (
  'db28eff1-ff18-584f-87ba-9f9ce4a53a38'::uuid,
  '58ee7773-cf74-5ac6-a889-17f2ac82136f'::uuid,
  'other'::kb_requirement_type,
  'Australian Qualification Requirement',
  'You must have completed a qualification that required at least 2 years of full-time study in Australia. The course must have been registered with CRICOS and completed within 6 months of lodging your 485 application.',
  '[{"authority": "FRL_REGS", "citation": "Schedule 2, clause 485.211; clause 485.212", "frl_title_id": "F2022C00125", "series": "Migration Regulations 1994", "notes": "Graduate stream — completed within 6 months of application."}]'::jsonb,
  '[{"authority": "HOMEAFFAIRS_PAGE", "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485/graduate-stream", "title": "Temporary Graduate visa 485 — Graduate stream", "last_checked": "2025-02-01"}]'::jsonb,
  '{"inputs": ["course_cricos_registered", "study_duration_years", "completion_date", "lodgement_date"], "outputs": ["FLAG-485-QUAL-TIMING", "FLAG-485-QUAL-DURATION"], "logic_notes": "6-month window is strict. If completion date + 6 months < lodgement date, applicant is ineligible. Timing risk is a primary refusal cause."}'::jsonb,
  '2013-11-16',
  NULL,
  'high'::kb_confidence,
  '2025-02-01T00:00:00Z'
) ON CONFLICT (requirement_id) DO NOTHING;

INSERT INTO requirement
  (requirement_id, visa_id, requirement_type, title, plain_english,
   legal_basis, operational_basis, rule_logic, effective_from, effective_to,
   confidence, last_reviewed_at)
VALUES (
  'fef936dc-834c-53f0-9b53-91b65900171b'::uuid,
  '58ee7773-cf74-5ac6-a889-17f2ac82136f'::uuid,
  'english'::kb_requirement_type,
  'English Language Proficiency',
  'You must demonstrate competent English. Acceptable tests include IELTS (minimum 6.0 each band), TOEFL iBT, PTE Academic, Cambridge C1/C2, or OET. Exemptions may apply based on citizenship of certain countries.',
  '[{"authority": "FRL_REGS", "citation": "Schedule 2, clause 485.221", "frl_title_id": "F2022C00125", "series": "Migration Regulations 1994", "notes": "English requirement for 485. Minimum scores may differ from 500 — check current instrument."}]'::jsonb,
  '[{"authority": "HOMEAFFAIRS_PAGE", "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-graduate-485", "title": "Temporary Graduate visa 485 — English requirements", "last_checked": "2025-02-01"}]'::jsonb,
  '{"inputs": ["english_test_type", "english_test_score", "english_test_date", "citizenship_country"], "outputs": ["FLAG-485-ENG-SCORE", "FLAG-485-ENG-EXPIRED", "FLAG-485-ENG-EXEMPT"], "logic_notes": "Test results must not be more than 3 years old at time of decision. Exemptions exist for citizens of UK, USA, Canada, NZ, Ireland."}'::jsonb,
  '2020-07-01',
  NULL,
  'high'::kb_confidence,
  '2025-02-01T00:00:00Z'
) ON CONFLICT (requirement_id) DO NOTHING;


-- Subclass 482 requirements
INSERT INTO requirement
  (requirement_id, visa_id, requirement_type, title, plain_english,
   legal_basis, operational_basis, rule_logic, effective_from, effective_to,
   confidence, last_reviewed_at)
VALUES (
  '95dc0d43-df52-5513-aae2-9c0d3d7d3fbb'::uuid,
  'c8e0b614-d7c3-5ec5-ae43-34ba8c9f1942'::uuid,
  'nomination'::kb_requirement_type,
  'Approved Nomination',
  'Your employer must have an approved nomination for the position you are being sponsored for. The nomination must specify the occupation from the relevant occupation list and the terms and conditions of employment, including salary, must meet the Temporary Skilled Migration Income Threshold (TSMIT) and be no less favourable than those for Australian workers performing equivalent work.',
  '[{"authority": "FRL_REGS", "citation": "Regulation 2.72; Schedule 2, clause 482.231", "frl_title_id": "F2022C00125", "series": "Migration Regulations 1994", "notes": "Nomination criteria under reg 2.72. TSMIT is set by instrument and updated periodically."}]'::jsonb,
  '[{"authority": "HOMEAFFAIRS_PAGE", "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/temporary-skill-shortage-482", "title": "Temporary Skill Shortage visa (482)", "last_checked": "2025-02-01"}]'::jsonb,
  '{"inputs": ["nomination_approved", "tsmit_salary_met", "occupation_on_list", "employment_conditions_comparable"], "outputs": ["FLAG-482-NOM-SALARY", "FLAG-482-NOM-CONDITIONS", "FLAG-482-NOM-OCC"], "logic_notes": "TSMIT threshold changes periodically — always verify current instrument. Salary must be at or above TSMIT and market rate."}'::jsonb,
  '2018-03-18',
  NULL,
  'high'::kb_confidence,
  '2025-02-01T00:00:00Z'
) ON CONFLICT (requirement_id) DO NOTHING;

INSERT INTO requirement
  (requirement_id, visa_id, requirement_type, title, plain_english,
   legal_basis, operational_basis, rule_logic, effective_from, effective_to,
   confidence, last_reviewed_at)
VALUES (
  '15bbe5f9-3cf0-5ccf-abcd-ecd71f1a37aa'::uuid,
  'c8e0b614-d7c3-5ec5-ae43-34ba8c9f1942'::uuid,
  'sponsorship'::kb_requirement_type,
  'Approved Standard Business Sponsor',
  'Your employer must be an approved standard business sponsor (or be seeking approval as part of the nomination). Standard business sponsors must demonstrate a genuine need for the position, meet training obligations, and not have any relevant adverse information.',
  '[{"authority": "FRL_REGS", "citation": "Regulation 2.67A; Schedule 2, clause 482.211", "frl_title_id": "F2022C00125", "series": "Migration Regulations 1994", "notes": "Sponsorship approval criteria. Training levy obligations apply."}]'::jsonb,
  '[{"authority": "HOMEAFFAIRS_PAGE", "url": "https://immi.homeaffairs.gov.au/visas/working-in-australia/temporary-skill-shortage-visa/standard-business-sponsorship", "title": "Standard Business Sponsorship", "last_checked": "2025-02-01"}]'::jsonb,
  '{"inputs": ["sponsor_approval_status", "sponsor_adverse_info", "training_levy_paid"], "outputs": ["FLAG-482-SPONS-APPROVAL", "FLAG-482-SPONS-LEVY"], "logic_notes": "Employer must pay the Skilling Australians Fund (SAF) levy as part of nomination. Amount depends on employer size and visa period."}'::jsonb,
  '2018-03-18',
  NULL,
  'high'::kb_confidence,
  '2025-02-01T00:00:00Z'
) ON CONFLICT (requirement_id) DO NOTHING;

INSERT INTO requirement
  (requirement_id, visa_id, requirement_type, title, plain_english,
   legal_basis, operational_basis, rule_logic, effective_from, effective_to,
   confidence, last_reviewed_at)
VALUES (
  '08313c19-d60b-5eda-b5ed-b1e01e7181e3'::uuid,
  'c8e0b614-d7c3-5ec5-ae43-34ba8c9f1942'::uuid,
  'occupation'::kb_requirement_type,
  'Occupation on Eligible List',
  'The nominated occupation must appear on the Medium and Long-term Strategic Skills List (MLTSSL) or Short-term Skilled Occupation List (STSOL) for the stream being applied under. Occupation lists are set by legislative instrument and updated periodically.',
  '[{"authority": "FRL_INSTRUMENT", "citation": "IMMI 19/051 (or current superseding instrument)", "frl_title_id": null, "series": "Migration (Skilling Australians Fund) Amendment Act + relevant occupation list instrument", "notes": "Check FRL for the current in-force occupation list instrument — updated periodically. frl_title_id must be verified against current instrument."}]'::jsonb,
  '[{"authority": "HOMEAFFAIRS_PAGE", "url": "https://immi.homeaffairs.gov.au/visas/working-in-australia/skill-occupation-list", "title": "Skilled occupation list", "last_checked": "2025-02-01"}]'::jsonb,
  '{"inputs": ["nominated_occupation_anzsco", "stream_applied"], "outputs": ["FLAG-482-OCC-NOT-LISTED", "FLAG-482-OCC-STREAM-MISMATCH"], "logic_notes": "ANZSCO code must match a current list entry for the stream. List changes frequently — always check the current in-force instrument."}'::jsonb,
  '2018-03-18',
  NULL,
  'medium'::kb_confidence,
  '2025-02-01T00:00:00Z'
) ON CONFLICT (requirement_id) DO NOTHING;


-- Subclass 417 requirements
INSERT INTO requirement
  (requirement_id, visa_id, requirement_type, title, plain_english,
   legal_basis, operational_basis, rule_logic, effective_from, effective_to,
   confidence, last_reviewed_at)
VALUES (
  '2ccee554-e3ed-5977-91cb-7b6b7732be08'::uuid,
  'c31dbb82-8012-57f6-9cdc-606bbc3590c0'::uuid,
  'genuine'::kb_requirement_type,
  'Genuine Working Holiday Intention',
  'You must be coming to Australia for a working holiday — primarily for tourism, with work as a secondary activity to support yourself during your stay. You must be a citizen of an eligible country and meet age requirements (typically 18–30 or 18–35 depending on country of origin).',
  '[{"authority": "FRL_REGS", "citation": "Schedule 2, clause 417.212", "frl_title_id": "F2022C00125", "series": "Migration Regulations 1994", "notes": "Eligibility criteria for WHM 417. Age limit extended to 35 for some nationalities via instrument."}]'::jsonb,
  '[{"authority": "HOMEAFFAIRS_PAGE", "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/work-holiday-417", "title": "Working Holiday visa (417)", "last_checked": "2025-02-01"}]'::jsonb,
  '{"inputs": ["citizenship_country", "age_at_application", "prior_417_held"], "outputs": ["FLAG-417-AGE-INELIGIBLE", "FLAG-417-COUNTRY-INELIGIBLE", "FLAG-417-REPEAT-APPLICATION"], "logic_notes": "417 is a once-in-a-lifetime visa for most nationalities unless second/third grant criteria fulfilled via specified work."}'::jsonb,
  '2015-07-01',
  NULL,
  'high'::kb_confidence,
  '2025-02-01T00:00:00Z'
) ON CONFLICT (requirement_id) DO NOTHING;

INSERT INTO requirement
  (requirement_id, visa_id, requirement_type, title, plain_english,
   legal_basis, operational_basis, rule_logic, effective_from, effective_to,
   confidence, last_reviewed_at)
VALUES (
  'cd7c8b28-3e18-5dec-9945-ae559b9c901c'::uuid,
  'c31dbb82-8012-57f6-9cdc-606bbc3590c0'::uuid,
  'work_history'::kb_requirement_type,
  'Specified Work for Second/Third Grant',
  'To be eligible for a second or third Working Holiday visa (417), you must have completed a specified number of days of specified work in a regional area of Australia during your first/second visa. Specified work categories and eligible regional areas are defined by legislative instrument.',
  '[{"authority": "FRL_INSTRUMENT", "citation": "Current specified work and regional area instrument", "frl_title_id": null, "series": "Migration (Specified Activities for Working Holiday) Instrument", "notes": "Instrument defines eligible industries (agriculture, construction, mining, etc.) and regional postcodes. Check FRL for current in-force version."}, {"authority": "FRL_REGS", "citation": "Schedule 2, clause 417.211(b)", "frl_title_id": "F2022C00125", "series": "Migration Regulations 1994", "notes": "Second grant condition — specified work requirement."}]'::jsonb,
  '[{"authority": "HOMEAFFAIRS_PAGE", "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/work-holiday-417/specified-work", "title": "Working Holiday 417 — Specified work", "last_checked": "2025-02-01"}]'::jsonb,
  '{"inputs": ["specified_work_days_completed", "work_region_eligible", "employer_abn_provided", "payslips_available"], "outputs": ["FLAG-417-WORK-DAYS-SHORT", "FLAG-417-WORK-REGION", "FLAG-417-WORK-EVIDENCE-GAP"], "logic_notes": "88 days (first grant); 179 days (second grant). Days must be verifiable. Employer ABN + payslips are essential evidence. Cash-in-hand work without records is a significant risk."}'::jsonb,
  '2015-07-01',
  NULL,
  'high'::kb_confidence,
  '2025-02-01T00:00:00Z'
) ON CONFLICT (requirement_id) DO NOTHING;

INSERT INTO requirement
  (requirement_id, visa_id, requirement_type, title, plain_english,
   legal_basis, operational_basis, rule_logic, effective_from, effective_to,
   confidence, last_reviewed_at)
VALUES (
  '37d8bc58-29ae-546a-9f46-a030ca9aa0c3'::uuid,
  'c31dbb82-8012-57f6-9cdc-606bbc3590c0'::uuid,
  'financial'::kb_requirement_type,
  'Financial Threshold',
  'You must demonstrate sufficient funds to support yourself at the start of your working holiday. The minimum threshold is set by instrument. Having evidence of accessible savings at the time of application reduces financial risk indicators.',
  '[{"authority": "FRL_REGS", "citation": "Schedule 2, clause 417.213", "frl_title_id": "F2022C00125", "series": "Migration Regulations 1994", "notes": "Financial capacity requirement for 417."}]'::jsonb,
  '[{"authority": "HOMEAFFAIRS_PAGE", "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/work-holiday-417", "title": "Working Holiday 417 — financial requirement", "last_checked": "2025-02-01"}]'::jsonb,
  '{"inputs": ["savings_aud", "return_flight_evidence"], "outputs": ["FLAG-417-FIN-INSUFFICIENT"], "logic_notes": "Minimum threshold is approximately AUD $5,000 (verify current figure). Evidence of a return flight or sufficient funds for one is also expected."}'::jsonb,
  '2015-07-01',
  NULL,
  'medium'::kb_confidence,
  '2025-02-01T00:00:00Z'
) ON CONFLICT (requirement_id) DO NOTHING;


-- Subclass 820 requirements
INSERT INTO requirement
  (requirement_id, visa_id, requirement_type, title, plain_english,
   legal_basis, operational_basis, rule_logic, effective_from, effective_to,
   confidence, last_reviewed_at)
VALUES (
  'ccc92746-1cc7-5d19-9b86-f2e3962c17ae'::uuid,
  '7eca8282-3da9-5aca-b66b-21c39ad551c5'::uuid,
  'relationship'::kb_requirement_type,
  'Genuine and Continuing Relationship',
  'You must be in a genuine and continuing relationship with an Australian citizen, permanent resident, or eligible New Zealand citizen. The relationship is assessed across four evidence pillars: financial aspects, nature of household, social aspects, and commitment to each other. There is no single type of evidence that is sufficient on its own.',
  '[{"authority": "FRL_REGS", "citation": "Schedule 2, clauses 820.211–820.221; reg 1.15A", "frl_title_id": "F2022C00125", "series": "Migration Regulations 1994", "notes": "Definition of de facto and married relationships. Regulation 1.15A defines de facto relationships."}, {"authority": "FRL_ACT", "citation": "Section 5F (spouse); Section 5CB (de facto partner)", "frl_title_id": "C2024C00195", "series": "Migration Act 1958", "notes": "Statutory definitions of spouse and de facto partner."}]'::jsonb,
  '[{"authority": "HOMEAFFAIRS_PAGE", "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-onshore-820-801", "title": "Partner visa (820/801) — relationship evidence", "last_checked": "2025-02-01"}]'::jsonb,
  '{"inputs": ["relationship_type", "cohabitation_duration", "financial_pillar_evidence", "household_pillar_evidence", "social_pillar_evidence", "commitment_pillar_evidence"], "outputs": ["FLAG-820-REL-PILLAR-WEAK", "FLAG-820-REL-TIMELINE-GAP", "FLAG-820-REL-ADDRESS-MISMATCH", "FLAG-820-REL-SEPARATION"], "logic_notes": "Relationship must have existed for 12 months (de facto) unless registered. Evidence must span all four pillars. Imbalanced pillar coverage is a primary risk indicator."}'::jsonb,
  '2009-07-01',
  NULL,
  'high'::kb_confidence,
  '2025-02-01T00:00:00Z'
) ON CONFLICT (requirement_id) DO NOTHING;

INSERT INTO requirement
  (requirement_id, visa_id, requirement_type, title, plain_english,
   legal_basis, operational_basis, rule_logic, effective_from, effective_to,
   confidence, last_reviewed_at)
VALUES (
  '424545dd-027b-5db0-afb5-f14f6c7f6c89'::uuid,
  '7eca8282-3da9-5aca-b66b-21c39ad551c5'::uuid,
  'sponsorship'::kb_requirement_type,
  'Eligible Sponsor',
  'Your sponsoring partner must be an Australian citizen, Australian permanent resident, or eligible New Zealand citizen, and must not have previously sponsored two partners for a partner visa. The sponsor must also meet any character requirements.',
  '[{"authority": "FRL_REGS", "citation": "Schedule 2, clause 820.211(c); reg 1.20J", "frl_title_id": "F2022C00125", "series": "Migration Regulations 1994", "notes": "Sponsor eligibility including the 2-sponsor limit."}]'::jsonb,
  '[{"authority": "HOMEAFFAIRS_PAGE", "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-onshore-820-801", "title": "Partner visa (820/801) — sponsor requirements", "last_checked": "2025-02-01"}]'::jsonb,
  '{"inputs": ["sponsor_citizenship_status", "sponsor_prior_sponsorships", "sponsor_character"], "outputs": ["FLAG-820-SPONS-INELIGIBLE", "FLAG-820-SPONS-LIMIT"], "logic_notes": "If sponsor has already sponsored 2 partner visa holders, they are generally ineligible unless granted a waiver. Sponsor character issues are separately assessed."}'::jsonb,
  '2009-07-01',
  NULL,
  'high'::kb_confidence,
  '2025-02-01T00:00:00Z'
) ON CONFLICT (requirement_id) DO NOTHING;

INSERT INTO requirement
  (requirement_id, visa_id, requirement_type, title, plain_english,
   legal_basis, operational_basis, rule_logic, effective_from, effective_to,
   confidence, last_reviewed_at)
VALUES (
  'c7a0f191-0c82-58ce-9cab-7aa61ae46f98'::uuid,
  '7eca8282-3da9-5aca-b66b-21c39ad551c5'::uuid,
  'health'::kb_requirement_type,
  'Health Requirement',
  'You and any dependent children included in the application must meet the health requirement (PIC 4005). This typically requires an immigration medical examination with an approved panel physician. Results are lodged electronically by the physician.',
  '[{"authority": "FRL_REGS", "citation": "Schedule 4, Public Interest Criterion 4005", "frl_title_id": "F2022C00125", "series": "Migration Regulations 1994", "notes": "PIC 4005 applies to partner visa onshore (820/801)."}]'::jsonb,
  '[{"authority": "HOMEAFFAIRS_PAGE", "url": "https://immi.homeaffairs.gov.au/entering-and-leaving-australia/entering-australia/health-examinations", "title": "Health examinations", "last_checked": "2025-02-01"}]'::jsonb,
  '{"inputs": ["medical_exam_completed", "medical_exam_date"], "outputs": ["FLAG-820-HLTH-REQUIRED", "FLAG-820-HLTH-EXPIRED"], "logic_notes": "Medicals expire 12 months after completion. If processing is long, a second medical may be required."}'::jsonb,
  '2009-07-01',
  NULL,
  'high'::kb_confidence,
  '2025-02-01T00:00:00Z'
) ON CONFLICT (requirement_id) DO NOTHING;

INSERT INTO requirement
  (requirement_id, visa_id, requirement_type, title, plain_english,
   legal_basis, operational_basis, rule_logic, effective_from, effective_to,
   confidence, last_reviewed_at)
VALUES (
  '1477cc2e-3df8-5134-8b0d-12c8f8958413'::uuid,
  '7eca8282-3da9-5aca-b66b-21c39ad551c5'::uuid,
  'character'::kb_requirement_type,
  'Character Requirement',
  'You must satisfy the character requirement (PIC 4001 — s.501 Migration Act 1958). This generally requires providing police clearance certificates from all countries where you have lived for 12+ months in the past 10 years (from age 16). Family violence provisions may be relevant in some circumstances.',
  '[{"authority": "FRL_ACT", "citation": "Section 501; Schedule 4, PIC 4001", "frl_title_id": "C2024C00195", "series": "Migration Act 1958", "notes": "Character test provisions. Family violence provisions under s.501A-s.501G also relevant."}]'::jsonb,
  '[{"authority": "HOMEAFFAIRS_PAGE", "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-onshore-820-801", "title": "Partner visa (820/801) — character requirement", "last_checked": "2025-02-01"}]'::jsonb,
  '{"inputs": ["criminal_history", "countries_lived_12mo", "police_clearance_obtained"], "outputs": ["FLAG-820-CHAR-POLICE-MISSING", "FLAG-820-CHAR-HISTORY"], "logic_notes": "Family violence provisions may exempt domestic violence victims from certain character requirements — specialist RMA advice warranted."}'::jsonb,
  '2009-07-01',
  NULL,
  'high'::kb_confidence,
  '2025-02-01T00:00:00Z'
) ON CONFLICT (requirement_id) DO NOTHING;


-- ---- 3. Evidence items ----
-- Subclass 500 evidence items
INSERT INTO evidence_item
  (evidence_id, requirement_id, label, what_it_proves, examples,
   common_gaps, priority, effective_from, effective_to, legal_basis)
VALUES (
  '880f9ba6-5a00-5832-8dd6-df8e4168c1ab'::uuid,
  'ec222e1d-b21d-53fb-a218-711ebdec6d8e'::uuid,
  'Confirmation of Enrolment (CoE)',
  'Demonstrates that you are enrolled in a registered course with a current CRICOS-registered provider, which is a pre-condition for the Student visa and supports your genuine student intent by anchoring you to a specific, approved course.',
  '["CoE letter issued by the university or college listing your course name, CRICOS code, commencement date, and duration", "CoE from PRISMS portal (government-issued confirmation)"]'::jsonb,
  '["CoE issued before course has been formally confirmed — reissue required if course details change", "CoE for a different course than the one being applied for", "CoE issued more than 12 months before application submission without explanation", "No CRICOS code visible on the document"]'::jsonb,
  1,
  '2016-11-19',
  NULL,
  '[{"frl_title_id": "F2022C00125", "series": "Migration Regulations 1994", "citation": "Schedule 2, clause 500.215 — ESOS Act enrolment requirement"}]'::jsonb
) ON CONFLICT (evidence_id) DO NOTHING;

INSERT INTO evidence_item
  (evidence_id, requirement_id, label, what_it_proves, examples,
   common_gaps, priority, effective_from, effective_to, legal_basis)
VALUES (
  'd160ae20-24e2-566f-af75-67b2d85318a0'::uuid,
  'a86d3e75-39bb-5b4c-8c23-29f0e51ae70e'::uuid,
  'Approved English Language Test Result',
  'Demonstrates you meet the English proficiency threshold for your course type and provider. Accepted tests include IELTS Academic, TOEFL iBT, PTE Academic, Cambridge C1 Advanced / C2 Proficiency, and OET.',
  '["IELTS Academic Test Report Form (TRF) with overall band score and all sub-scores visible", "TOEFL iBT score report from ETS with My Best Scores or single-sitting scores", "PTE Academic Score Report from Pearson", "Cambridge C1 Advanced or C2 Proficiency Certificate of Results", "OET Result Letter (for health professions pathway)"]'::jsonb,
  '["Test result more than 3 years old at the expected date of decision — rebook required", "Using IELTS General Training instead of IELTS Academic", "Sub-band score below minimum even when overall score passes — all bands must individually meet threshold", "No test booking made yet — creates timeline risk if result takes 2–4 weeks", "PTE or TOEFL scores not meeting all sub-score minimums (listening, reading, writing, speaking treated separately)"]'::jsonb,
  1,
  '2019-07-01',
  NULL,
  '[{"frl_title_id": "F2019L01030", "series": "Migration (LIN 19/051 — English Language Requirements for the Student Visa) Instrument 2019", "citation": "LIN 19/051 — approved test types and minimum scores"}]'::jsonb
) ON CONFLICT (evidence_id) DO NOTHING;


-- Subclass 485 evidence items
INSERT INTO evidence_item
  (evidence_id, requirement_id, label, what_it_proves, examples,
   common_gaps, priority, effective_from, effective_to, legal_basis)
VALUES (
  '297ee2b4-db77-5c06-b2b3-92461e21407b'::uuid,
  'db28eff1-ff18-584f-87ba-9f9ce4a53a38'::uuid,
  'Award certificate or testamur',
  'Confirms completion of an eligible qualification at an Australian institution.',
  '[]'::jsonb,
  '["Certificate not yet issued — use official completion letter with expected award date", "Name on certificate differs from passport name", "Qualification not CRICOS registered"]'::jsonb,
  1,
  '2013-11-16',
  NULL,
  '[]'::jsonb
) ON CONFLICT (evidence_id) DO NOTHING;

INSERT INTO evidence_item
  (evidence_id, requirement_id, label, what_it_proves, examples,
   common_gaps, priority, effective_from, effective_to, legal_basis)
VALUES (
  '36b097c9-c44e-52c4-9023-428b29dbd188'::uuid,
  'db28eff1-ff18-584f-87ba-9f9ce4a53a38'::uuid,
  'Official academic transcript',
  'Provides detailed evidence of course completion and study duration to meet the 2-year minimum study requirement.',
  '[]'::jsonb,
  '["Unofficial transcript printed from student portal — must be official sealed copy", "Credits from overseas transferred — must show Australian study periods clearly"]'::jsonb,
  1,
  '2013-11-16',
  NULL,
  '[]'::jsonb
) ON CONFLICT (evidence_id) DO NOTHING;

INSERT INTO evidence_item
  (evidence_id, requirement_id, label, what_it_proves, examples,
   common_gaps, priority, effective_from, effective_to, legal_basis)
VALUES (
  '26ca80e2-0bf2-512d-b403-00e5c3d5ab04'::uuid,
  'fef936dc-834c-53f0-9b53-91b65900171b'::uuid,
  'English language test result',
  'Demonstrates the applicant meets the English language requirement for subclass 485.',
  '[]'::jsonb,
  '["Test result more than 3 years old at time of decision", "One or more band scores below the minimum threshold", "Test type not approved for migration purposes"]'::jsonb,
  1,
  '2020-07-01',
  NULL,
  '[]'::jsonb
) ON CONFLICT (evidence_id) DO NOTHING;

INSERT INTO evidence_item
  (evidence_id, requirement_id, label, what_it_proves, examples,
   common_gaps, priority, effective_from, effective_to, legal_basis)
VALUES (
  '595af9fe-d8a0-5e50-b27b-af2e6e963f5c'::uuid,
  'db28eff1-ff18-584f-87ba-9f9ce4a53a38'::uuid,
  'eCoE (Electronic Confirmation of Enrolment)',
  'Confirms your enrolment in a CRICOS-registered course — used to verify eligibility period and course duration.',
  '[]'::jsonb,
  '["eCoE expired or cancelled — request an updated eCoE from your provider", "Course listed on eCoE is not CRICOS registered"]'::jsonb,
  2,
  '2013-11-16',
  NULL,
  '[]'::jsonb
) ON CONFLICT (evidence_id) DO NOTHING;


-- Subclass 482 evidence items
INSERT INTO evidence_item
  (evidence_id, requirement_id, label, what_it_proves, examples,
   common_gaps, priority, effective_from, effective_to, legal_basis)
VALUES (
  '41701360-d331-5f7b-b80e-a98b42d9c18d'::uuid,
  '95dc0d43-df52-5513-aae2-9c0d3d7d3fbb'::uuid,
  'Signed employment contract',
  'Demonstrates the employment offer is genuine and terms (including salary) meet TSMIT and are no less favourable than Australian workers.',
  '[]'::jsonb,
  '["Salary stated is below current TSMIT — check current threshold before lodging", "ANZSCO code on contract differs from nomination", "Contract not signed by both parties"]'::jsonb,
  1,
  '2018-03-18',
  NULL,
  '[]'::jsonb
) ON CONFLICT (evidence_id) DO NOTHING;

INSERT INTO evidence_item
  (evidence_id, requirement_id, label, what_it_proves, examples,
   common_gaps, priority, effective_from, effective_to, legal_basis)
VALUES (
  'd6f53248-ce75-5cd0-8e25-a1728c7a7277'::uuid,
  '95dc0d43-df52-5513-aae2-9c0d3d7d3fbb'::uuid,
  'Market salary rate evidence',
  'Confirms the nominee is not being paid below market rate, meeting the ''equivalent terms'' requirement for nomination.',
  '[]'::jsonb,
  '["Market rate evidence not location-specific (cost of living varies by state/city)", "Data source more than 12 months old", "No comparison with Australian workers in equivalent roles"]'::jsonb,
  1,
  '2018-03-18',
  NULL,
  '[]'::jsonb
) ON CONFLICT (evidence_id) DO NOTHING;

INSERT INTO evidence_item
  (evidence_id, requirement_id, label, what_it_proves, examples,
   common_gaps, priority, effective_from, effective_to, legal_basis)
VALUES (
  'bc248d20-0873-553d-a8ff-593680368ea2'::uuid,
  '15bbe5f9-3cf0-5ccf-abcd-ecd71f1a37aa'::uuid,
  'Business registration documents',
  'Confirms the employer is an eligible and lawfully operating business for standard business sponsorship purposes.',
  '[]'::jsonb,
  '["Business structure changed since sponsorship approval", "ABN cancelled or not active", "ASIC registration expired"]'::jsonb,
  1,
  '2018-03-18',
  NULL,
  '[]'::jsonb
) ON CONFLICT (evidence_id) DO NOTHING;

INSERT INTO evidence_item
  (evidence_id, requirement_id, label, what_it_proves, examples,
   common_gaps, priority, effective_from, effective_to, legal_basis)
VALUES (
  'df7629f8-d41b-54d2-a11d-8dc9ed043a27'::uuid,
  '08313c19-d60b-5eda-b5ed-b1e01e7181e3'::uuid,
  'Detailed position description',
  'Demonstrates the nominated position genuinely corresponds to the claimed ANZSCO occupation on the eligible list.',
  '[]'::jsonb,
  '["Duties listed are generic — must match ANZSCO unit group specifics", "Position is multi-occupation — primary occupation must be the dominant activity", "ANZSCO code does not appear on the current eligible occupation list"]'::jsonb,
  1,
  '2018-03-18',
  NULL,
  '[]'::jsonb
) ON CONFLICT (evidence_id) DO NOTHING;


-- Subclass 417 evidence items
INSERT INTO evidence_item
  (evidence_id, requirement_id, label, what_it_proves, examples,
   common_gaps, priority, effective_from, effective_to, legal_basis)
VALUES (
  'c595d9ee-b617-5210-b85b-7c30275ab342'::uuid,
  'cd7c8b28-3e18-5dec-9945-ae559b9c901c'::uuid,
  'Payslips from regional employer',
  'Primary evidence that specified work was performed for an eligible employer in a regional area during the required period.',
  '[]'::jsonb,
  '["Employer ABN missing from payslip", "Cash-in-hand work with no payslip — significant risk indicator", "Work location cannot be verified as regional from payslip alone"]'::jsonb,
  1,
  '2015-07-01',
  NULL,
  '[]'::jsonb
) ON CONFLICT (evidence_id) DO NOTHING;

INSERT INTO evidence_item
  (evidence_id, requirement_id, label, what_it_proves, examples,
   common_gaps, priority, effective_from, effective_to, legal_basis)
VALUES (
  '0989e7cd-74dc-5062-9f41-55647df46544'::uuid,
  'cd7c8b28-3e18-5dec-9945-ae559b9c901c'::uuid,
  'Tax file number (TFN) statement or tax return',
  'Independent corroboration of specified work income and employer relationship, cross-checking payslips.',
  '[]'::jsonb,
  '["Payments not declared to ATO — consistency risk between payslips and tax records", "Multiple employers listed but work period dates overlap inconsistently"]'::jsonb,
  1,
  '2015-07-01',
  NULL,
  '[]'::jsonb
) ON CONFLICT (evidence_id) DO NOTHING;

INSERT INTO evidence_item
  (evidence_id, requirement_id, label, what_it_proves, examples,
   common_gaps, priority, effective_from, effective_to, legal_basis)
VALUES (
  '57e7ed74-4733-5c2d-bbbc-b7222a769362'::uuid,
  'cd7c8b28-3e18-5dec-9945-ae559b9c901c'::uuid,
  'Employer reference letter',
  'Confirms details of specified work engagement including regional eligibility and work category.',
  '[]'::jsonb,
  '["Letter not on letterhead or missing ABN", "Work category listed does not match eligible specified work categories", "Dates conflict with other evidence"]'::jsonb,
  2,
  '2015-07-01',
  NULL,
  '[]'::jsonb
) ON CONFLICT (evidence_id) DO NOTHING;

INSERT INTO evidence_item
  (evidence_id, requirement_id, label, what_it_proves, examples,
   common_gaps, priority, effective_from, effective_to, legal_basis)
VALUES (
  '73bbcc33-5b96-56e0-ade2-c3a20e9f1843'::uuid,
  '37d8bc58-29ae-546a-9f46-a030ca9aa0c3'::uuid,
  'Bank statements showing minimum savings',
  'Demonstrates financial capacity to fund the initial period of the working holiday.',
  '[]'::jsonb,
  '["Savings balance fluctuates significantly — large deposits immediately before application may raise questions", "Account is in a third party''s name — funds must be in the applicant''s name or clearly accessible"]'::jsonb,
  1,
  '2015-07-01',
  NULL,
  '[]'::jsonb
) ON CONFLICT (evidence_id) DO NOTHING;


-- Subclass 820 evidence items
INSERT INTO evidence_item
  (evidence_id, requirement_id, label, what_it_proves, examples,
   common_gaps, priority, effective_from, effective_to, legal_basis)
VALUES (
  'c51901c4-7f1d-5daa-924a-2fd93814b0f7'::uuid,
  'ccc92746-1cc7-5d19-9b86-f2e3962c17ae'::uuid,
  'Joint bank account statements',
  'Demonstrates the financial pillar of relationship evidence — shared finances and financial interdependence.',
  '[]'::jsonb,
  '["Account opened recently — only a few months of statements", "Both names on account but transactions show only one person using it", "No regularity of shared expenses (rent, bills, groceries)"]'::jsonb,
  1,
  '2009-07-01',
  NULL,
  '[]'::jsonb
) ON CONFLICT (evidence_id) DO NOTHING;

INSERT INTO evidence_item
  (evidence_id, requirement_id, label, what_it_proves, examples,
   common_gaps, priority, effective_from, effective_to, legal_basis)
VALUES (
  '76f41b33-864d-5ce3-a92d-b26ff064047a'::uuid,
  'ccc92746-1cc7-5d19-9b86-f2e3962c17ae'::uuid,
  'Shared lease or property documents',
  'Demonstrates the household pillar — cohabitation and shared domestic arrangements.',
  '[]'::jsonb,
  '["Only one partner''s name on the lease", "Multiple addresses during relationship with unexplained gaps in cohabitation", "Lease for a property where both partners are not listed as tenants"]'::jsonb,
  1,
  '2009-07-01',
  NULL,
  '[]'::jsonb
) ON CONFLICT (evidence_id) DO NOTHING;

INSERT INTO evidence_item
  (evidence_id, requirement_id, label, what_it_proves, examples,
   common_gaps, priority, effective_from, effective_to, legal_basis)
VALUES (
  '62673f81-404f-569f-a6d8-cb9d67fc4fed'::uuid,
  'ccc92746-1cc7-5d19-9b86-f2e3962c17ae'::uuid,
  'Photographs together across multiple events and dates',
  'Contributes to the social pillar — demonstrates a genuine shared life and ongoing relationship.',
  '[]'::jsonb,
  '["All photos from a single event or period — lacks temporal spread", "Photos are screenshots without metadata or dates", "No photos with friends or family who can corroborate the relationship"]'::jsonb,
  2,
  '2009-07-01',
  NULL,
  '[]'::jsonb
) ON CONFLICT (evidence_id) DO NOTHING;

INSERT INTO evidence_item
  (evidence_id, requirement_id, label, what_it_proves, examples,
   common_gaps, priority, effective_from, effective_to, legal_basis)
VALUES (
  'da75c574-67dc-58ab-b8bd-ac3e0efd2012'::uuid,
  'ccc92746-1cc7-5d19-9b86-f2e3962c17ae'::uuid,
  'Statutory declarations from third parties',
  'Contributes to both social and commitment pillars — third-party corroboration is a strong indicator of genuine relationship.',
  '[]'::jsonb,
  '["Statutory declarations are identical in wording — suggests template was used by multiple declarants", "Declarants have only met one partner — must know both", "Declaration not properly witnessed or signed"]'::jsonb,
  1,
  '2009-07-01',
  NULL,
  '[]'::jsonb
) ON CONFLICT (evidence_id) DO NOTHING;

INSERT INTO evidence_item
  (evidence_id, requirement_id, label, what_it_proves, examples,
   common_gaps, priority, effective_from, effective_to, legal_basis)
VALUES (
  '0d9441a6-66f5-587f-9804-c343b3278322'::uuid,
  '424545dd-027b-5db0-afb5-f14f6c7f6c89'::uuid,
  'Sponsor''s citizenship or residency evidence',
  'Confirms the sponsoring partner is an eligible Australian citizen, permanent resident, or eligible NZ citizen.',
  '[]'::jsonb,
  '["Sponsor''s permanent visa has expired or been cancelled", "NZ citizen sponsor may need to check specific eligibility — not all NZ citizens qualify"]'::jsonb,
  1,
  '2009-07-01',
  NULL,
  '[]'::jsonb
) ON CONFLICT (evidence_id) DO NOTHING;


-- ---- 4. Flag templates ----
-- Subclass 500 flag templates
INSERT INTO flag_template
  (flag_id, visa_id, title, trigger_schema, why_it_matters,
   actions, evidence_examples, severity, effective_from, effective_to, sources)
VALUES (
  'a31f6058-1c33-5cca-90b8-8f74c14fe5a1'::uuid,
  '7f342e2f-ddb0-5990-8d88-fe1a001011d8'::uuid,
  'Weak ties to home country',
  '{"conditions": ["home_country_ties_evidence = none OR weak", "immigration_history_concerns = true"]}'::jsonb,
  'Decision makers assess genuine student intention by weighing circumstances including ties to home country (property, family, employment prospects). Weak or unexplained ties may indicate the applicant does not intend to return, which is a risk indicator under the Genuine Student requirement (clause 500.212).',
  '["Document family members, assets, or employment prospects in home country", "Explain how the study aligns with your career goals at home", "Provide a personal statement addressing your intention to return", "Gather any supporting evidence: property, family responsibilities, business interests"]'::jsonb,
  '["Bank statements or property ownership documents in home country", "Family situation statement (dependants, spouse, parents)", "Employer letter from home country confirming re-employment post-study", "Career plan showing connection between course and home-country goals"]'::jsonb,
  'warning'::kb_flag_severity,
  '2016-11-19',
  NULL,
  '{"legal": [{"authority": "FRL_REGS", "citation": "Schedule 2, clause 500.212", "frl_title_id": "F2022C00125"}], "operational": [{"authority": "HOMEAFFAIRS_PAGE", "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/student-500/temporary-student"}]}'::jsonb
) ON CONFLICT (flag_id) DO NOTHING;

INSERT INTO flag_template
  (flag_id, visa_id, title, trigger_schema, why_it_matters,
   actions, evidence_examples, severity, effective_from, effective_to, sources)
VALUES (
  '912c80bd-4ef5-5dc1-83a5-0e831b624115'::uuid,
  '7f342e2f-ddb0-5990-8d88-fe1a001011d8'::uuid,
  'Course inconsistent with prior study or career path',
  '{"conditions": ["course_relevance_to_career = low OR none", "previous_study_unrelated = true"]}'::jsonb,
  'The Genuine Student test includes an assessment of whether the course is consistent with your stated career goals. A mismatch between your academic background, work experience, and enrolled course is a known risk indicator.',
  '["Write a clear course choice statement explaining why this course suits your goals", "Highlight any transferable skills or prior learning connecting past and present study", "Obtain a letter from your education provider if course counselling was involved", "If changing fields, document your career pivoting rationale clearly"]'::jsonb,
  '["Personal statement linking course to career plan", "Letter from current or prospective employer in target field", "Transcript or certificate showing relevant prior knowledge", "Skills assessment or industry report supporting field transition"]'::jsonb,
  'warning'::kb_flag_severity,
  '2016-11-19',
  NULL,
  '{"legal": [{"authority": "FRL_REGS", "citation": "Schedule 2, clause 500.212", "frl_title_id": "F2022C00125"}], "operational": [{"authority": "HOMEAFFAIRS_PAGE", "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/student-500/temporary-student"}]}'::jsonb
) ON CONFLICT (flag_id) DO NOTHING;

INSERT INTO flag_template
  (flag_id, visa_id, title, trigger_schema, why_it_matters,
   actions, evidence_examples, severity, effective_from, effective_to, sources)
VALUES (
  '9cac791e-c617-5cdc-a36b-2a1ee20a38ce'::uuid,
  '7f342e2f-ddb0-5990-8d88-fe1a001011d8'::uuid,
  'English test score below typical threshold for course type',
  '{"conditions": ["english_test_score < minimum_for_course_level"]}'::jsonb,
  'The Migration Regulations require English proficiency suited to your enrolled course. Minimum scores are set by instrument (LIN 19/051) and vary by provider type and course level. Submitting a score below the required threshold will result in the application being refused.',
  '["Check the exact minimum score for your course provider type (ELICOS, higher ed, VET, school)", "Retake the English test if your score is below the required minimum", "Ensure your test result is not more than 3 years old at the time of decision", "Confirm if an exemption applies (e.g., prior study in an approved English-speaking country)"]'::jsonb,
  '["IELTS, TOEFL iBT, PTE Academic, Cambridge C1/C2, or OET test report form", "Evidence of prior study in an approved English-speaking country (transcripts + enrolment confirmation)", "Confirmation of exemption from education provider if applicable"]'::jsonb,
  'risk'::kb_flag_severity,
  '2019-07-01',
  NULL,
  '{"legal": [{"authority": "FRL_REGS", "citation": "Schedule 2, clause 500.213; Schedule 8, clause 8517", "frl_title_id": "F2022C00125"}, {"authority": "FRL_INSTRUMENT", "citation": "LIN 19/051", "frl_title_id": "F2019L01030"}], "operational": [{"authority": "HOMEAFFAIRS_PAGE", "url": "https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/student-500/temporary-student#Eligibility"}]}'::jsonb
) ON CONFLICT (flag_id) DO NOTHING;

