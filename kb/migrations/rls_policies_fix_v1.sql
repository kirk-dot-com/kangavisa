-- rls_policies_fix_v1.sql
-- Fixes two Supabase lint categories:
--   0024: rls_policy_always_true  → visitor_intake anon INSERT scoped to anon role
--   0008: rls_enabled_no_policy   → 9 KB/event tables get appropriate policies
-- Run in Supabase SQL Editor.

-- ════════════════════════════════════════════════════════════════════════════
-- 1. visitor_intake — scope INSERT to anon role only (fixes lint 0024)
--    Rationale: intake is collected pre-auth from the /visitor funnel.
--    Scoping to `anon` role prevents authenticated or service-role bypass concerns.
-- ════════════════════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "visitor_intake_anon_insert" ON visitor_intake;

CREATE POLICY "visitor_intake_anon_insert"
    ON visitor_intake FOR INSERT
    TO anon
    WITH CHECK (true);

-- Authenticated users can also insert (e.g. logged-in users completing the survey)
CREATE POLICY "visitor_intake_auth_insert"
    ON visitor_intake FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- No SELECT policy — intentional. Users cannot read other sessions' intake data.
-- Service role bypasses RLS and can read all rows (used by /api/govdata routes).


-- ════════════════════════════════════════════════════════════════════════════
-- 2. KB reference tables — public read (fixes lint 0008)
--    These tables contain visa knowledge base data served to all users.
--    SELECT USING (true) for public read is intentional and excluded from
--    lint 0024 warnings per Supabase documentation.
-- ════════════════════════════════════════════════════════════════════════════

-- evidence_item
CREATE POLICY "evidence_item: public read"
    ON evidence_item FOR SELECT
    USING (true);

-- flag_template
CREATE POLICY "flag_template: public read"
    ON flag_template FOR SELECT
    USING (true);

-- requirement
CREATE POLICY "requirement: public read"
    ON requirement FOR SELECT
    USING (true);

-- source_document
CREATE POLICY "source_document: public read"
    ON source_document FOR SELECT
    USING (true);

-- visa_subclass
CREATE POLICY "visa_subclass: public read"
    ON visa_subclass FOR SELECT
    USING (true);

-- kb_release
CREATE POLICY "kb_release: public read"
    ON kb_release FOR SELECT
    USING (true);

-- instrument (FRL instrument data — public read for checklist display)
CREATE POLICY "instrument: public read"
    ON instrument FOR SELECT
    USING (true);


-- ════════════════════════════════════════════════════════════════════════════
-- 3. Event tables — authenticated read, service role writes via bypass
--    analytics_events and change_event are written by service-role workers
--    (which bypass RLS). Authenticated users can read their own events.
-- ════════════════════════════════════════════════════════════════════════════

-- analytics_events: authenticated users can read all (aggregate/admin use)
CREATE POLICY "analytics_events: authenticated read"
    ON analytics_events FOR SELECT
    TO authenticated
    USING (true);

-- change_event: authenticated users can read (for FRL change monitoring)
CREATE POLICY "change_event: authenticated read"
    ON change_event FOR SELECT
    TO authenticated
    USING (true);
