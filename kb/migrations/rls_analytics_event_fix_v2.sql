-- =============================================================================
-- RLS Fix v2 — analytics_event duplicate INSERT policy
-- Supabase Advisor issues:
--   1. Multiple permissive INSERT policies for role "authenticated"
--      (analytics_event_insert_if_enabled + analytics_event_insert_own)
--   2. auth.uid() re-evaluated per row in analytics_event_insert_if_enabled
--
-- RESOLUTION:
--   Drop both INSERT policies, recreate only analytics_event_insert_own
--   with (SELECT auth.uid()) scalar subquery (evaluated once per statement).
--
-- SAFE TO RUN MULTIPLE TIMES — all statements are idempotent.
--
-- HOW TO APPLY:
--   Supabase Dashboard → SQL Editor → paste and run.
--   Then go to Advisors → Performance → should show 0 issues for analytics_event.
-- =============================================================================

-- Drop both INSERT policies (stale and canonical) before recreating
DROP POLICY IF EXISTS analytics_event_insert_if_enabled ON public.analytics_event;
DROP POLICY IF EXISTS analytics_event_insert_own        ON public.analytics_event;

-- Single consolidated INSERT policy — (SELECT auth.uid()) evaluated once per statement
CREATE POLICY analytics_event_insert_own
    ON public.analytics_event
    FOR INSERT
    TO authenticated
    WITH CHECK (user_id = (SELECT auth.uid()));

-- Ensure SELECT policy also uses scalar subquery (harmless if already correct)
DROP POLICY IF EXISTS analytics_event_select_own ON public.analytics_event;
CREATE POLICY analytics_event_select_own
    ON public.analytics_event
    FOR SELECT
    TO authenticated
    USING (user_id = (SELECT auth.uid()));

-- Supporting index (safe to run multiple times)
CREATE INDEX IF NOT EXISTS idx_analytics_event_user
    ON public.analytics_event (user_id);
