-- =====================================================================
-- KangaVisa Knowledge Base — Sprint 20
-- seed_partner_309_v1.sql
-- =====================================================================
-- Seeds requirements, evidence items, and flag templates for:
--   309 (Partner Visa — Offshore Temporary → 100 Permanent)
--
-- The 309/100 pathway is mirror-requirements to 820/801 (onshore),
-- with the key differences:
--   • Applied offshore (outside Australia at time of lodgement)
--   • No Bridging visa — applicant lives abroad during processing
--   • Temporary visa (309) → Permanent (100) on approval of stage 2
--   • Same 4 relationship pillars + sponsor eligibility + health + character
--
-- Source: Migration Regulations 1994 — Schedule 2, Part 309/100
--
-- Safe to run multiple times (ON CONFLICT DO NOTHING throughout).
-- Wrapped in a transaction for atomicity.
-- =====================================================================

BEGIN;

-- ─────────────────────────────────────────────────────────────────────
-- 1. VISA SUBCLASS ROW
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO visa_subclass (subclass_code, stream, audience, canonical_info_url, last_verified_at)
VALUES (
    '309', NULL, 'B2C',
    'https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-offshore-309-100',
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
        'You must be in a genuine and continuing relationship with an Australian citizen, permanent resident, or eligible New Zealand citizen at time of application AND at time of decision. The 309 is lodged from outside Australia; the relationship must be maintained throughout the processing period. Relationship evidence must span four pillars: financial aspects, nature of household, social aspects, and commitment to each other.',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clauses 309.211–309.221; reg 1.15A","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"Clause 309.211 sets out the relationship requirement at time of application. Reg 1.15A defines de facto relationships."},{"authority":"FRL_ACT","citation":"Section 5F (spouse); Section 5CB (de facto partner)","frl_title_id":"C2024C00195","series":"Migration Act 1958","notes":"Statutory definitions of spouse and de facto partner."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-offshore-309-100","title":"Partner visa (309/100) — relationship evidence","last_checked":"2025-02-01"}]',
        '1994-09-01', NULL,
        '{"inputs":["relationship_type","cohabitation_duration","financial_pillar_evidence","household_pillar_evidence","social_pillar_evidence","commitment_pillar_evidence","relationship_continuing_at_decision"],"outputs":["FLAG-309-REL-PILLAR-WEAK","FLAG-309-REL-TIMELINE-GAP","FLAG-309-SEPARATION-LENGTHY"],"logic_notes":"Must be in relationship at both application and decision dates. Long separations during processing can undermine relationship genuineness — ongoing contact evidence (messages, calls, visits) is important."}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'sponsorship',
        'Eligible Sponsor',
        'Your sponsoring partner must be an Australian citizen, Australian permanent resident, or eligible New Zealand citizen, and must not have previously sponsored two partners for a partner visa. The sponsor must also meet character requirements. Sponsorship approval may be granted before or at the same time as the visa application.',
        '[{"authority":"FRL_REGS","citation":"Schedule 2, clause 309.211(c); reg 1.20J","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"Sponsor eligibility including the 2-sponsor limit."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-offshore-309-100","title":"Partner visa (309/100) — sponsor requirements","last_checked":"2025-02-01"}]',
        '1994-09-01', NULL,
        '{"inputs":["sponsor_citizenship_status","sponsor_prior_sponsorships","sponsor_character"],"outputs":["FLAG-309-SPONS-INELIGIBLE","FLAG-309-SPONS-LIMIT"],"logic_notes":"If sponsor has already sponsored 2 partner visa holders, generally ineligible without waiver."}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'health',
        'Health Requirement',
        'You and any dependent children included in the application must meet the health requirement (PIC 4005). This requires an immigration medical examination with an approved panel physician in your country of residence. Results are lodged electronically by the physician. Medicals are valid for 12 months; if processing is long a repeat examination may be required.',
        '[{"authority":"FRL_REGS","citation":"Schedule 4, Public Interest Criterion 4005","frl_title_id":"F2022C00125","series":"Migration Regulations 1994","notes":"PIC 4005 applies to offshore partner visa (309/100)."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/entering-and-leaving-australia/entering-australia/health-examinations","title":"Health examinations — panel physicians offshore","last_checked":"2025-02-01"}]',
        '1994-09-01', NULL,
        '{"inputs":["medical_exam_completed","medical_exam_date","panel_physician_country"],"outputs":["FLAG-309-HLTH-EXPIRED","FLAG-309-HLTH-REQUIRED"],"logic_notes":"Must use an approved panel physician in your country. Australia does not have panel physicians everywhere — some applicants must travel to the nearest country with a panel physician."}',
        'high', '2025-02-01T00:00:00Z'
    ),
    (
        'character',
        'Character Requirement',
        'You must satisfy the character requirement (PIC 4001 — s.501 Migration Act 1958). Police clearance certificates are required from all countries where you have lived for 12 or more months in the past 10 years (from age 16). Clearances must generally be less than 12 months old at grant.',
        '[{"authority":"FRL_ACT","citation":"Section 501; Schedule 4, PIC 4001","frl_title_id":"C2024C00195","series":"Migration Act 1958","notes":"Character test provisions. Family violence provisions may also be relevant."}]',
        '[{"authority":"HOMEAFFAIRS_PAGE","url":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-offshore-309-100","title":"Partner visa (309/100) — character requirement","last_checked":"2025-02-01"}]',
        '1994-09-01', NULL,
        '{"inputs":["criminal_history","countries_lived_12mo","police_clearance_obtained","clearance_date"],"outputs":["FLAG-309-CHAR-POLICE-MISSING","FLAG-309-CHAR-CLEARANCE-EXPIRED"],"logic_notes":"Clearances from some countries (e.g. USA FBI check) can take months to obtain. Obtain early. If clearance expires before decision, a fresh one will be needed."}',
        'high', '2025-02-01T00:00:00Z'
    )
) AS r(req_type, title, plain_english, legal_basis, operational_basis, effective_from, effective_to, rule_logic, confidence, last_reviewed_at)
WHERE vs.subclass_code = '309' AND vs.stream IS NULL
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
     'Joint bank account statements or shared financial records',
     'Demonstrates the financial pillar — shared finances and financial interdependence across two countries.',
     '["Joint account statements (3–12 months)","Evidence of regular international money transfers between partners","Joint insurance policies, loans, or property ownership"]',
     '["Account only recently opened","One partner does all the transacting — no evidence of shared use","No cross-border financial interdependence despite living in different countries"]',
     1, '1994-09-01', NULL),
    ('Genuine and Continuing Relationship',
     'Communication records showing ongoing contact',
     'For offshore applications, ongoing contact evidence is especially important — the couple is living in different countries. Proves the relationship is genuine and continuing during the separation.',
     '["Phone records or messaging logs (WhatsApp, Facetime, email) showing regular contact","Dated call logs over several months","Screenshots of video calls with timestamps"]',
     '["Gaps in contact evidence during the processing period","Only showing contact in one direction","No context for why contact is remote rather than in-person"]',
     1, '1994-09-01', NULL),
    ('Genuine and Continuing Relationship',
     'Statutory declarations from third parties',
     'Contributes to social and commitment pillars. Third-party witnesses must know both partners and the relationship.',
     '["Statutory declarations from family and friends of both partners","Form 888 (Supporting statement for partner visa)","Each declarant''s contact details, how long they have known the couple, what they have observed"]',
     '["Declarants only know one partner","Declarations are word-for-word identical (template)","Not properly witnessed or signed"]',
     1, '1994-09-01', NULL),
    ('Genuine and Continuing Relationship',
     'Evidence of visits between partners',
     'Demonstrates physical commitment to the relationship despite living in different countries.',
     '["Passport stamps and boarding passes showing travel between countries","Photos together taken during visits with dates and locations","Hotel or accommodation bookings showing joint stays"]',
     '["No physical visits at all during the relationship","Visit evidence only from very early in the relationship","Boarding passes without accompanying photos or context"]',
     2, '1994-09-01', NULL),
    -- Eligible Sponsor
    ('Eligible Sponsor',
     'Sponsor''s citizenship or residency evidence',
     'Confirms the sponsoring partner is an eligible Australian citizen, permanent resident, or eligible NZ citizen.',
     '["Australian passport or citizenship certificate","ImmiCard or permanent visa grant letter","VEVO confirmation for permanent residents"]',
     '["Sponsor''s permanent visa has expired","NZ citizen — not all NZ citizens are eligible, must verify specific eligibility"]',
     1, '1994-09-01', NULL),
    -- Character
    ('Character Requirement',
     'Police clearance certificates from all relevant countries',
     'Satisfies PIC 4001 character requirement — evidence of no disqualifying criminal history.',
     '["Police clearance from your country of citizenship","Police clearance from any country where you lived for 12+ months in the past 10 years (since age 16)","Certified translation if not in English"]',
     '["Missing clearance from a country of prior residence (e.g. where you studied or worked)","Clearance more than 12 months old at grant","Uncertified translation"]',
     1, '1994-09-01', NULL)
) AS ev(req_title, label, what_it_proves, examples, common_gaps, priority, effective_from, effective_to)
WHERE vs.subclass_code = '309' AND vs.stream IS NULL
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
        'Relationship evidence is limited across the four pillars',
        '{"field":"relationship_pillars_present","operator":"<","value":3}',
        'For an offshore partner visa, Home Affairs assesses the four pillars of relationship evidence regardless of living arrangements. Weak evidence in any pillar — especially if the couple is living separately — makes it harder to establish the relationship is genuine and continuing.',
        '["Gather evidence in all four pillars: financial, household, social, commitment","Provide documented evidence of how you maintain the relationship across distance","Explain why you are living apart and when you plan to reunite in Australia"]',
        '["Joint bank account statements or cross-border financial transfers","Communication logs (messages, calls) showing regular contact","Photos together across multiple visits and dates","Statutory declarations from people who know both partners"]',
        'risk', '1994-09-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Clause 309.211, Reg 1.15A","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-offshore-309-100"}'
    ),
    (
        'Ongoing contact evidence is insufficient for an offshore application',
        '{"field":"ongoing_contact_evidence_present","operator":"==","value":false}',
        'Unlike onshore partners, offshore applicants are living in a different country. Home Affairs expects to see evidence that the relationship is being actively maintained despite the physical separation — phone records, messages, video calls, and visits.',
        '["Collect call and message logs across several months","Document visits with photos, boarding passes, and accommodation records","Provide a narrative explaining the separation and plans to reunite"]',
        '["Facetime/WhatsApp call logs with regular contact shown","Dated international boarding passes","Photos from visits together with captions and dates"]',
        'warning', '1994-09-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Clause 309.211","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-offshore-309-100"}'
    ),
    (
        'Police clearance certificates may expire before decision',
        '{"field":"police_clearance_age_months","operator":">","value":9}',
        'Offshore partner visa processing can take 12–24+ months. If police clearance certificates are obtained at lodgement, they may expire (12 months) before the visa is decided, requiring the applicant to obtain fresh clearances — sometimes from overseas.',
        '["Obtain police clearances as late as possible before lodgement","Monitor clearance expiry dates during processing","Be prepared to obtain updated clearances if requested by the department"]',
        '["Fresh police clearance (within 3 months of lodgement)","Record of clearance date to track expiry"]',
        'warning', '1994-09-01', NULL,
        '{"legislation":"Migration Act 1958 — Section 501; PIC 4001","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-offshore-309-100"}'
    ),
    (
        'Sponsor eligibility may not have been confirmed',
        '{"field":"sponsor_approved","operator":"==","value":false}',
        'The Australian sponsor must be approved before the visa can be granted. For the 309, sponsors can apply for approval separately before or concurrent with the visa application. Unconfirmed sponsor eligibility can delay processing.',
        '["Lodge sponsor approval (form 40SP) as early as possible","Confirm sponsor has not already sponsored two previous partners","Review any character issues with the sponsor before lodging"]',
        '["Australian citizenship certificate or permanent visa grant","Completed Form 40SP — sponsorship for a partner to migrate to Australia","Statutory declaration regarding prior sponsorships"]',
        'warning', '1994-09-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Clause 309.211(c); Reg 1.20J","homeaffairs":"https://immi.homeaffairs.gov.au/visas/getting-a-visa/visa-listing/partner-offshore-309-100"}'
    ),
    (
        'Medical examination not yet completed',
        '{"field":"medical_exam_completed","operator":"==","value":false}',
        'Offshore applicants must use an approved panel physician in their country, which may require travel. Medicals expire after 12 months. With 309 processing times of 12–24+ months, the medical may need to be redone during processing.',
        '["Book with an approved panel physician as soon as the application is lodged","Track the expiry date (12 months from examination)","Build in time for travel to a panel physician if one is not available locally"]',
        '["Medical examination certificate from approved panel physician","Evidence of panel physician appointment and results lodged electronically"]',
        'warning', '1994-09-01', NULL,
        '{"legislation":"Migration Regulations 1994 — Schedule 4, PIC 4005","homeaffairs":"https://immi.homeaffairs.gov.au/entering-and-leaving-australia/entering-australia/health-examinations"}'
    )
) AS f(title, trigger_schema, why_it_matters, actions, evidence_examples, severity, effective_from, effective_to, sources)
WHERE vs.subclass_code = '309' AND vs.stream IS NULL
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────
-- 5. ADD PROMPT CHIPS FOR 309 TO HANDOVER NOTE
-- (no DB action needed — chips are in AskBar.tsx PROMPT_CHIPS constant)
-- ─────────────────────────────────────────────────────────────────────


-- ─────────────────────────────────────────────────────────────────────
-- 6. KB RELEASE TAG
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO kb_release (release_tag, created_at)
VALUES ('kb-v20260314-partner-309', NOW())
ON CONFLICT DO NOTHING;


COMMIT;

-- ─────────────────────────────────────────────────────────────────────
-- VERIFICATION QUERIES (run after applying)
-- ─────────────────────────────────────────────────────────────────────
-- SELECT COUNT(*) FROM requirement
--   WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '309');
-- Expected: 4
--
-- SELECT COUNT(*) FROM evidence_item
--   WHERE requirement_id IN (
--     SELECT requirement_id FROM requirement
--     WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '309')
--   );
-- Expected: 6
--
-- SELECT COUNT(*) FROM flag_template
--   WHERE visa_id = (SELECT visa_id FROM visa_subclass WHERE subclass_code = '309');
-- Expected: 5
--
-- SELECT release_tag, created_at FROM kb_release ORDER BY created_at DESC LIMIT 3;
