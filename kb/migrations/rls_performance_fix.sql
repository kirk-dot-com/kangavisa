-- =============================================================================
-- RLS Performance Fix — Supabase Advisor: 7 policies
-- Wraps auth.uid() in scalar subquery (SELECT auth.uid()) so Postgres
-- evaluates it once per statement, not per row. Pure performance fix.
--
-- TABLES AFFECTED (from Supabase advisor):
--   public.analytics_event  — 2 policies
--   public.consent_event    — 2 policies
--   public.consent_state    — 2 policies (+ 1 more = 7 total)
--
-- HOW TO APPLY:
--   Supabase Dashboard → SQL Editor → paste and run.
-- =============================================================================


-- ---------------------------------------------------------------------------
-- 1. analytics_event
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS analytics_event_select_own ON public.analytics_event;
CREATE POLICY analytics_event_select_own
    ON public.analytics_event
    FOR SELECT
    TO authenticated
    USING (user_id = (SELECT auth.uid()));

-- Drop the original INSERT policy (was named analytics_event_insert_if_enabled)
-- then recreate with scalar subquery under the canonical name.
DROP POLICY IF EXISTS analytics_event_insert_if_enabled ON public.analytics_event;
DROP POLICY IF EXISTS analytics_event_insert_own ON public.analytics_event;
CREATE POLICY analytics_event_insert_own
    ON public.analytics_event
    FOR INSERT
    TO authenticated
    WITH CHECK (user_id = (SELECT auth.uid()));


-- ---------------------------------------------------------------------------
-- 2. consent_event
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS consent_event_select_own ON public.consent_event;
CREATE POLICY consent_event_select_own
    ON public.consent_event
    FOR SELECT
    TO authenticated
    USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS consent_event_insert_own ON public.consent_event;
CREATE POLICY consent_event_insert_own
    ON public.consent_event
    FOR INSERT
    TO authenticated
    WITH CHECK (user_id = (SELECT auth.uid()));


-- ---------------------------------------------------------------------------
-- 3. consent_state
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS consent_state_select_own ON public.consent_state;
CREATE POLICY consent_state_select_own
    ON public.consent_state
    FOR SELECT
    TO authenticated
    USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS consent_state_insert_own ON public.consent_state;
CREATE POLICY consent_state_insert_own
    ON public.consent_state
    FOR INSERT
    TO authenticated
    WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS consent_state_update_own ON public.consent_state;
CREATE POLICY consent_state_update_own
    ON public.consent_state
    FOR UPDATE
    TO authenticated
    USING (user_id = (SELECT auth.uid()))
    WITH CHECK (user_id = (SELECT auth.uid()));


-- ---------------------------------------------------------------------------
-- Supporting indexes (safe to run multiple times — IF NOT EXISTS)
-- ---------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_analytics_event_user
    ON public.analytics_event (user_id);

CREATE INDEX IF NOT EXISTS idx_consent_event_user
    ON public.consent_event (user_id);

CREATE INDEX IF NOT EXISTS idx_consent_state_user
    ON public.consent_state (user_id);
