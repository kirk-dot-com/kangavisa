-- =====================================================================
-- KangaVisa Knowledge Base — Sprint 24
-- seed_skilled_nominated_190_491_v1.sql
-- =====================================================================
-- Seeds requirements, evidence items, and flag templates for:
--   190 (Skilled Nominated visa)
--   491 (Skilled Work Regional (Provisional) visa)
--
-- Source JSON files:
--   kb/seed/visa_190_491_seed.json
--
-- Both visas share the 189 core requirements (points, skills assessment,
-- English, health, character) plus visa-specific nomination/sponsorship
-- requirements seeded here.
--
-- Key differences from 189:
--   190 — State/territory government nomination required (5 bonus points)
--   491 — State/territory nomination OR eligible relative regional
--          sponsorship required (15 bonus points); provisional visa with
--          3-year regional commitment before 191 PR pathway
--
-- Both 190 and 491 visa_subclass rows created here if not present.
-- Run seed_skilled_independent_189_v1.sql FIRST to ensure shared
-- requirement patterns are established.
--
-- Flag severity: critical→risk | medium→warning
-- Safe to run multiple times (ON CONFLICT DO NOTHING throughout).
-- =====================================================================

BEGIN;

-- ─────────────────────────────────────────────────────────────────────
-- 1. VISA SUBCLASS ROWS
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO visa_subclass (subclass_code, stream, audience, canonical_info_url, last_verified_at)
VALUES
    (
        '190', NULL, 'B2C',
        'https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-nominated-190',
        '2025-02-01T00:00:00Z'
    ),
    (
        '491', NULL, 'B2C',
        'https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-work-regional-491',
        '2025-02-01T00:00:00Z'
    )
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 2. REQUIREMENTS — 190 (Skilled Nominated)
-- ─────────────────────────────────────────────────────────────────────

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
    'You must hold a valid nomination from an Australian state or territory government for your nominated occupation. The nomination is assessed separately by the state/territory and must be approved before or concurrent with your 190 visa application. Nomination provides 5 bonus points in the points test.',
    '[{"authority":"FRL_REGS","citation":"Schedule 2, clause 190.211","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"Valid state/territory nomination required for 190 eligibility."}]'::jsonb,
    '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-nominated-190","title":"Skilled Nominated visa (subclass 190)","last_checked":"2025-02-01"}]'::jsonb,
    '2012-07-01'::date,
    NULL::date,
    '{"inputs":["nomination_required","nomination_present","nomination_state","nominated_occupation"],"outputs":["FLAG-190-NOMINATION-MISSING"],"logic_notes":"Nomination must be from an approved state/territory. Occupation must match nominated ANZSCO code. 5 bonus points awarded automatically on nomination."}'::jsonb,
    'high'::kb_confidence,
    '2025-02-01T00:00:00Z'::timestamptz
FROM visa_subclass vs
WHERE vs.subclass_code = '190' AND vs.stream IS NULL
ON CONFLICT (visa_id, title) DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 3. REQUIREMENTS — 491 (Skilled Work Regional)
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
        'You must hold either a valid nomination from an Australian state or territory government, OR sponsorship by an eligible relative who lives and works in a designated regional area of Australia. The 491 is a points-tested visa — nomination or sponsorship provides 15 bonus points.',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clause 491.211","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"Nomination or relative sponsorship required for 491."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-work-regional-491","title":"Skilled Work Regional (Provisional) visa (subclass 491)","last_checked":"2025-02-01"}]',
        '2019-11-16', NULL,
        '{"inputs":["nomination_or_sponsorship_required","nomination_or_sponsorship_present","sponsor_relative_type","regional_area_confirmed"],"outputs":["FLAG-491-NOMINATION-SPONSORSHIP-MISSING"],"logic_notes":"Either state/territory nomination or eligible relative (blood relative or step/adoptive) sponsorship is acceptable. Relative must live and work in a designated regional area. 15 bonus points awarded."}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'other',
        'Live and Work in Designated Regional Area',
        'As a 491 visa holder, you must live and work (or study) in a designated regional area of Australia for at least 3 years. This is a visa condition — not just a requirement at the time of grant. Non-compliance with this condition affects your eligibility for the permanent Subclass 191 visa pathway.',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clause 491.612","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"Regional living and working condition is a visa condition for 491."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-work-regional-491/living-and-working-regionally","title":"Skilled Work Regional 491 — Living and working regionally","last_checked":"2025-02-01"}]',
        '2019-11-16', NULL,
        '{"inputs":["intended_regional_area","regional_area_on_approved_list","regional_commitment_acknowledged"],"outputs":["FLAG-491-REGIONAL-REQUIREMENT-UNCLEAR"],"logic_notes":"Must live and work in a designated area throughout the 491 period. 3 years of compliance required before Subclass 191 PR application."}',
        'high', '2025-02-01T00:00:00Z'
    )
) AS r(req_type, title, plain_english, legal_basis, operational_basis, effective_from, effective_to, rule_logic, confidence, last_reviewed_at)
WHERE vs.subclass_code = '491' AND vs.stream IS NULL
ON CONFLICT (visa_id, title) DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 4. EVIDENCE ITEMS — 190
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO evidence_item (
    evidence_id, requirement_id, label, what_it_proves, examples, common_gaps,
    priority, effective_from, effective_to
)
SELECT
    gen_random_uuid(),
    req.requirement_id,
    'State or territory government nomination letter',
    'Confirms a valid state/territory nomination has been approved — a mandatory eligibility criterion and source of the 5 bonus points.',
    '["Nomination outcome letter from state/territory migration program","Confirmatory email from state/territory skills migration authority"]'::jsonb,
    '["Nomination not yet granted — cannot lodge 190 without approved nomination","Occupation on nomination letter does not match visa application","Nomination from one state/territory used to lodge with intention to reside in another"]'::jsonb,
    1, '2012-07-01'::date, NULL::date
FROM requirement req
JOIN visa_subclass vs ON vs.visa_id = req.visa_id
WHERE vs.subclass_code = '190' AND vs.stream IS NULL
  AND req.title = 'State or Territory Nomination'
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 5. EVIDENCE ITEMS — 491
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO evidence_item (
    evidence_id, requirement_id, label, what_it_proves, examples, common_gaps,
    priority, effective_from, effective_to
)
SELECT
    gen_random_uuid(),
    req.requirement_id,
    'State/territory nomination OR eligible relative sponsorship',
    'Confirms either a state/territory nomination or eligible relative sponsorship has been approved — mandatory to proceed and provides 15 bonus points.',
    '["Nomination outcome letter from state/territory government","Eligible relative sponsorship approval from Home Affairs","Evidence that sponsoring relative lives and works in a designated regional area (lease, payslips, utilities)"]'::jsonb,
    '["Neither nomination nor approved sponsorship in place before applying","Relative not confirmed as living in a designated regional area","Sponsoring relative relationship not documented (birth certificate, statutory declaration)"]'::jsonb,
    1, '2019-11-16'::date, NULL::date
FROM requirement req
JOIN visa_subclass vs ON vs.visa_id = req.visa_id
WHERE vs.subclass_code = '491' AND vs.stream IS NULL
  AND req.title = 'State Nomination or Eligible Relative Sponsorship'
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 6. FLAG TEMPLATES — 190
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
        'State or territory nomination not confirmed',
        '{"all":[{"field":"nomination_required","operator":"==","value":true},{"field":"nomination_present","operator":"==","value":false}]}',
        'The 190 visa requires a valid state/territory nomination. Without it, the application cannot proceed regardless of the applicant''s points score. The 5 bonus points cannot be claimed without a confirmed nomination.',
        '["Confirm your nomination application has been submitted to the state/territory program","Upload the nomination outcome letter once received","Ensure your occupation and skills assessment match the state''s requirements at time of nomination"]',
        '["Nomination outcome letter from state migration program","Skills assessment matching the nominated occupation"]',
        'risk', '2012-07-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Clause 190.211","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-nominated-190"}'
    ),
    (
        'Points claimed may exceed what evidence supports',
        '{"left_field":"claimed_points","operator":">","right_field":"evidenced_points"}',
        'The 190 uses the same points test as the 189. The 5-point nomination bonus is automatically awarded, but all other claimed points must be evidenced at time of lodgement.',
        '["Recalculate points including the 5-point nomination bonus","Verify each remaining point claim against supporting documents"]',
        '["Nomination letter (confirms 5-point bonus)","Employment reference letters covering claimed experience period","English test result matching bandwidth claimed"]',
        'risk', '2012-07-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Schedule 6D","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-nominated-190/points-test"}'
    )
) AS f(title, trigger_schema, why_it_matters, actions, evidence_examples, severity, effective_from, effective_to, sources)
WHERE vs.subclass_code = '190' AND vs.stream IS NULL
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 7. FLAG TEMPLATES — 491
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
        'Nomination or relative sponsorship not confirmed',
        '{"all":[{"field":"nomination_or_sponsorship_required","operator":"==","value":true},{"field":"nomination_or_sponsorship_present","operator":"==","value":false}]}',
        'The 491 requires either state/territory nomination or sponsorship by an eligible relative in a regional area. Without one of these, the application cannot proceed. The 15 bonus points cannot be claimed without a confirmed nomination or sponsorship.',
        '["Confirm whether you are applying via state nomination or relative sponsorship","Upload the nomination or sponsorship approval letter once received","Ensure your relative''s regional address is documented if applying via sponsorship"]',
        '["Nomination outcome letter","Eligible relative sponsorship confirmation","Proof of relative''s residence in a designated regional area"]',
        'risk', '2019-11-16', NULL,
        '{"legislation":"Migration Regulations 1994 — Clause 491.211","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-work-regional-491"}'
    ),
    (
        'Understanding of regional living requirement unclear',
        '{"field":"regional_requirement_acknowledged","operator":"==","value":false}',
        'The 491 is a provisional visa — to become eligible for permanent residency (Subclass 191), holders must live and work in a designated regional area for at least 3 years. Not understanding this requirement can lead to unmet visa conditions and consequences for future visa options.',
        '["Confirm the intended regional area is on the designated regional area list","Plan employment and accommodation in a qualifying regional area","Understand the pathway from 491 to Subclass 191 Permanent Residence and the 3-year requirement"]',
        '["Job offer in a designated regional area","Lease agreement or accommodation confirmation in a designated regional area","Evidence of intended relocation to the regional area"]',
        'warning', '2019-11-16', NULL,
        '{"legislation":"Migration Regulations 1994 — Clause 491.612","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-work-regional-491/living-and-working-regionally"}'
    ),
    (
        'Points claimed may exceed what evidence supports',
        '{"left_field":"claimed_points","operator":">","right_field":"evidenced_points"}',
        'The 491 uses the same points test as 189/190. Nomination or sponsorship provides 15 bonus points, but all other claimed points must still be evidenced at time of lodgement.',
        '["Recalculate points including the 15-point regional nomination/sponsorship bonus","Verify each remaining point claim with supporting documents"]',
        '["Nomination or sponsorship letter (confirms 15-point bonus)","Employment references covering claimed experience","English test result matching the band claimed"]',
        'risk', '2019-11-16', NULL,
        '{"legislation":"Migration Regulations 1994 — Schedule 6D","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/skilled-work-regional-491/points-test"}'
    )
) AS f(title, trigger_schema, why_it_matters, actions, evidence_examples, severity, effective_from, effective_to, sources)
WHERE vs.subclass_code = '491' AND vs.stream IS NULL
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 8. KB RELEASE TAGS
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO kb_release (release_tag, created_at)
VALUES
    ('kb-v20260314-skilled-nominated-190', NOW()),
    ('kb-v20260314-skilled-regional-491', NOW())
ON CONFLICT DO NOTHING;


COMMIT;

-- ─────────────────────────────────────────────────────────────────────
-- VERIFICATION QUERIES (run after applying)
-- ─────────────────────────────────────────────────────────────────────
-- SELECT COUNT(*) FROM requirement
--   WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '190');
-- Expected: 1
--
-- SELECT COUNT(*) FROM evidence_item
--   WHERE requirement_id IN (
--     SELECT requirement_id FROM requirement
--     WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '190')
--   );
-- Expected: 1
--
-- SELECT COUNT(*) FROM flag_template
--   WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '190');
-- Expected: 2
--
-- SELECT COUNT(*) FROM requirement
--   WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '491');
-- Expected: 2
--
-- SELECT COUNT(*) FROM evidence_item
--   WHERE requirement_id IN (
--     SELECT requirement_id FROM requirement
--     WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '491')
--   );
-- Expected: 1
--
-- SELECT COUNT(*) FROM flag_template
--   WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '491');
-- Expected: 3
