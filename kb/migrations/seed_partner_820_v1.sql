-- =====================================================================
-- KangaVisa Knowledge Base — Sprint 19
-- seed_partner_820_v1.sql
-- =====================================================================
-- Seeds requirements, evidence items, and flag templates for:
--   820 (Partner Visa — Onshore Temporary → 801 Permanent)
--
-- Source JSON files:
--   kb/seed/visa_820_requirements.json   (4 requirements)
--   kb/seed/visa_820_evidence_items.json (5 evidence items)
--   kb/seed/visa_820_flags.json          (5 flag templates)
--
-- Safe to run multiple times:
--   • visa_subclass  — ON CONFLICT DO NOTHING
--   • requirement    — ON CONFLICT (visa_id, title) DO NOTHING
--   • evidence_item  — ON CONFLICT DO NOTHING
--   • flag_template  — ON CONFLICT DO NOTHING
--
-- Notes:
--   • visa_820 was seeded in seed_mvp_visas_v1.sql, so ON CONFLICT
--     DO NOTHING on visa_subclass is correct.
--   • flag severity mapping: "critical" → "risk", "high" → "warning",
--     "medium" → "warning" (kb_flag_severity enum: info/warning/risk)
--
-- Wrapped in a transaction for atomicity.
-- =====================================================================

BEGIN;

-- ─────────────────────────────────────────────────────────────────────
-- 1. VISA SUBCLASS ROW  (already exists from seed_mvp_visas_v1.sql)
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO visa_subclass (subclass_code, stream, audience, canonical_info_url, last_verified_at)
VALUES (
    '820', NULL, 'B2C',
    'https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-onshore-820-801',
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
        'relationship',
        'Genuine and Continuing Relationship',
        'You must be in a genuine and continuing relationship with an Australian citizen, permanent resident, or eligible New Zealand citizen. The relationship is assessed across four evidence pillars: financial aspects, nature of household, social aspects, and commitment to each other. There is no single type of evidence that is sufficient on its own.',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clauses 820.211–820.221; reg 1.15A","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"Definition of de facto and married relationships. Regulation 1.15A defines de facto relationships."},{"authority":"FRL_ACT","citation":"Section 5F (spouse); Section 5CB (de facto partner)","frl_title_id":"C2024C00195","series":"Migration Act 1958","notes":"Statutory definitions of spouse and de facto partner."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-onshore-820-801","title":"Partner visa (820/801) — relationship evidence","last_checked":"2025-02-01"}]',
        '2009-07-01', NULL,
        '{"inputs":["relationship_type","cohabitation_duration","financial_pillar_evidence","household_pillar_evidence","social_pillar_evidence","commitment_pillar_evidence"],"outputs":["FLAG-820-REL-PILLAR-WEAK","FLAG-820-REL-TIMELINE-GAP","FLAG-820-REL-ADDRESS-MISMATCH","FLAG-820-REL-SEPARATION"],"logic_notes":"Relationship must have existed for 12 months (de facto) unless registered. Evidence must span all four pillars. Imbalanced pillar coverage is a primary risk indicator."}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'sponsorship',
        'Eligible Sponsor',
        'Your sponsoring partner must be an Australian citizen, Australian permanent resident, or eligible New Zealand citizen, and must not have previously sponsored two partners for a partner visa. The sponsor must also meet any character requirements.',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clause 820.211(c); reg 1.20J","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"Sponsor eligibility including the 2-sponsor limit."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-onshore-820-801","title":"Partner visa (820/801) — sponsor requirements","last_checked":"2025-02-01"}]',
        '2009-07-01', NULL,
        '{"inputs":["sponsor_citizenship_status","sponsor_prior_sponsorships","sponsor_character"],"outputs":["FLAG-820-SPONS-INELIGIBLE","FLAG-820-SPONS-LIMIT"],"logic_notes":"If sponsor has already sponsored 2 partner visa holders, they are generally ineligible unless granted a waiver. Sponsor character issues are separately assessed."}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'health',
        'Health Requirement',
        'You and any dependent children included in the application must meet the health requirement (PIC 4005). This typically requires an immigration medical examination with an approved panel physician. Results are lodged electronically by the physician.',
        '[{"authority":"FRL_REGS","citation":"Schedule 4, Public Interest Criterion 4005","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"PIC 4005 applies to partner visa onshore (820/801)."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/entering-and-leaving-australia/entering-australia/health-examinations","title":"Health examinations","last_checked":"2025-02-01"}]',
        '2009-07-01', NULL,
        '{"inputs":["medical_exam_completed","medical_exam_date"],"outputs":["FLAG-820-HLTH-REQUIRED","FLAG-820-HLTH-EXPIRED"],"logic_notes":"Medicals expire 12 months after completion. If processing is long, a second medical may be required."}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'character',
        'Character Requirement',
        'You must satisfy the character requirement (PIC 4001 — s.501 Migration Act 1958). This generally requires providing police clearance certificates from all countries where you have lived for 12+ months in the past 10 years (from age 16). Family violence provisions may be relevant in some circumstances.',
        '[{"authority":"FRL_ACT","citation":"Section 501; Schedule 4, PIC 4001","frl_title_id":"C2024C00195","series":"Migration Act 1958","notes":"Character test provisions. Family violence provisions under s.501A-s.501G also relevant."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-onshore-820-801","title":"Partner visa (820/801) — character requirement","last_checked":"2025-02-01"}]',
        '2009-07-01', NULL,
        '{"inputs":["criminal_history","countries_lived_12mo","police_clearance_obtained"],"outputs":["FLAG-820-CHAR-POLICE-MISSING","FLAG-820-CHAR-HISTORY"],"logic_notes":"Family violence provisions may exempt domestic violence victims from certain character requirements — specialist RMA advice warranted."}',
        'high', '2025-02-01T00:00:00Z'
    )
) AS r(req_type, title, plain_english, legal_basis, operational_basis, effective_from, effective_to, rule_logic, confidence, last_reviewed_at)
WHERE vs.subclass_code = '820' AND vs.stream IS NULL
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
    -- Genuine and Continuing Relationship
    ('Genuine and Continuing Relationship',
     'Joint bank account statements',
     'Demonstrates the financial pillar of relationship evidence — shared finances and financial interdependence.',
     '["3–12 months of statements from a joint bank account","Highlighted recurring shared expenses (rent, bills, groceries)","Supplementary joint loans, joint insurance, or co-signed leases"]',
     '["Account opened recently — only a few months of statements","Both names on account but only one person using it","No regularity of shared expenses"]',
     1, '2009-07-01', NULL),
    ('Genuine and Continuing Relationship',
     'Shared lease or property documents',
     'Demonstrates the household pillar — cohabitation and shared domestic arrangements.',
     '["Rental agreement or mortgage documents listing both partners as co-tenants or co-owners","Any lease renewals showing continuity"]',
     '["Only one partner''s name on the lease","Multiple addresses with unexplained cohabitation gaps","Lease exists but partner not formally listed as tenant"]',
     1, '2009-07-01', NULL),
    ('Genuine and Continuing Relationship',
     'Photographs together across multiple events and dates',
     'Contributes to the social pillar — demonstrates a genuine shared life and ongoing relationship.',
     '["Curated chronological set of dated photographs","Photos across different events, locations, and time periods","Photos with friends or family who can corroborate the relationship"]',
     '["All photos from a single event — lacks temporal spread","Screenshots without metadata or dates","No photos with shared social contacts"]',
     2, '2009-07-01', NULL),
    ('Genuine and Continuing Relationship',
     'Statutory declarations from third parties',
     'Contributes to both social and commitment pillars — third-party corroboration is a strong indicator of genuine relationship.',
     '["Statutory declarations from people who know both partners","Each declarant confirming duration and genuine nature of the relationship","Declarant contact details, relationship to the couple, and how long they have known both partners"]',
     '["Declarations are identical in wording — suggests a template was copied","Declarants have only met one partner","Declaration not properly witnessed or signed"]',
     1, '2009-07-01', NULL),
    -- Eligible Sponsor
    ('Eligible Sponsor',
     'Sponsor''s citizenship or residency evidence',
     'Confirms the sponsoring partner is an eligible Australian citizen, permanent resident, or eligible NZ citizen.',
     '["Australian passport or citizenship certificate","ImmiCard or permanent visa grant letter","VEVO confirmation (for permanent visa holders)"]',
     '["Sponsor''s permanent visa has expired or been cancelled","NZ citizen sponsor may not qualify — specific eligibility must be checked"]',
     1, '2009-07-01', NULL)
) AS ev(req_title, label, what_it_proves, examples, common_gaps, priority, effective_from, effective_to)
WHERE vs.subclass_code = '820' AND vs.stream IS NULL
  AND req.title = ev.req_title
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 4. FLAG TEMPLATES
-- Note: kb_flag_severity enum is info/warning/risk.
--   "critical" in source → "risk" here (most severe)
--   "high"     in source → "warning"
--   "medium"   in source → "warning"
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
        'Relationship evidence is limited across the four pillars',
        '{"field":"relationship_pillars_present","operator":"<","value":3}',
        'Home Affairs assesses partner visa applications across four pillars of shared life: financial, household, social, and commitment. Weak evidence in any pillar — especially if the relationship is recent — raises credibility concerns.',
        '["Gather evidence across all four pillars: financial, household, social, and commitment","Include joint documents, not just statements from each person individually","Where evidence is thin in one area, provide a written explanation supported by other documents"]',
        '["Joint bank account statements or shared bills (financial)","Shared lease agreement or utility bills at same address (household)","Photos, event invitations, messages showing shared social life (social)","Statutory declarations from friends/family (commitment)","Evidence of future plans — travel bookings, property enquiries"]',
        'risk', '2009-07-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Clause 820.211, Reg 1.15A","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-820-801/partner-evidence"}'
    ),
    (
        'Relationship timeline appears inconsistent across documents',
        '{"field":"relationship_timeline_consistent","operator":"==","value":false}',
        'If statements, photos, and documents tell different stories about when or how the relationship started or progressed, the application''s credibility is undermined.',
        '["Write a consistent relationship history that both partners agree on","Ensure dates of key events (first meeting, cohabitation, engagement, marriage) match across all documents","Review both partners'' statements for discrepancies before lodging"]',
        '["Consistent relationship history statement from both partners","Supporting documents matching key dates cited in statements"]',
        'warning', '2009-07-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Clause 820.211","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-820-801"}'
    ),
    (
        'Sponsor eligibility may not have been confirmed',
        '{"field":"sponsor_approved","operator":"==","value":false}',
        'The Australian partner (sponsor) must be approved before the visa can be granted. Sponsors with certain criminal history, prior sponsorship history, or who don''t meet residency criteria may be ineligible.',
        '["Confirm the sponsor meets citizenship or permanent residency requirements","Check if the sponsor has sponsored a previous partner visa within the last 5 years","Review whether the sponsor has any relevant criminal history that could affect eligibility"]',
        '["Australian citizenship certificate or permanent visa grant notice","Statutory declaration regarding prior sponsorships"]',
        'warning', '2009-07-01', NULL,
        '{"legislation":"Migration Act 1958 — Section 84; Migration Regulations 1994 — Clause 820.710","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-820-801/who-can-sponsor"}'
    ),
    (
        'Cohabitation history not clearly documented',
        '{"field":"cohabitation_evidence_present","operator":"==","value":false}',
        'Living together is one of the strongest indicators of a genuine relationship. If shared address history is absent or inconsistent, the household pillar of evidence is weakened.',
        '["Provide a joint lease, mortgage, or utility bill showing shared address","If you have not always lived together, explain the circumstances and periods apart","Include statutory declaration from landlord or neighbours if formal documents are limited"]',
        '["Lease agreement showing both names at same address","Utility bills addressed to both partners","Bank statements showing same residential address"]',
        'warning', '2009-07-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Reg 1.15A(3)(b)","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-820-801/partner-evidence"}'
    ),
    (
        'Third-party statutory declarations not included',
        '{"field":"statutory_declarations_present","operator":"==","value":false}',
        'Statutory declarations from friends, family, or colleagues who know the couple are a standard and expected part of a partner visa application. Their absence is notable.',
        '["Obtain at least 2 statutory declarations from people who can attest to the genuineness of the relationship","Declarations should describe how long they have known the couple and what they have observed","Include a mix of people who know each partner individually and as a couple"]',
        '["Statutory declaration from a family member of either partner","Statutory declaration from a friend or colleague who knows the couple","Form 888 (Supporting statement for partner visa)"]',
        'warning', '2009-07-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Reg 1.15A","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-820-801/documents"}'
    )
) AS f(title, trigger_schema, why_it_matters, actions, evidence_examples, severity, effective_from, effective_to, sources)
WHERE vs.subclass_code = '820' AND vs.stream IS NULL
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 5. KB RELEASE TAG
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO kb_release (release_tag, created_at)
VALUES ('kb-v20260314-partner-820', NOW())
ON CONFLICT DO NOTHING;


COMMIT;

-- ─────────────────────────────────────────────────────────────────────
-- VERIFICATION QUERIES (run after applying)
-- ─────────────────────────────────────────────────────────────────────
-- SELECT COUNT(*) FROM requirement
--   WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '820');
-- Expected: 4
--
-- SELECT COUNT(*) FROM evidence_item
--   WHERE requirement_id IN (
--     SELECT requirement_id FROM requirement
--     WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '820')
--   );
-- Expected: 5
--
-- SELECT COUNT(*) FROM flag_template
--   WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '820');
-- Expected: 5
--
-- SELECT release_tag, created_at FROM kb_release ORDER BY created_at DESC LIMIT 3;
