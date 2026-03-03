-- =============================================================================
-- RLS Performance Fix — Supabase Advisor: 7 policies
-- Wraps auth.uid() in scalar subquery so Postgres evaluates it once per
-- statement rather than once per row. No behaviour change — pure performance.
--
-- HOW TO APPLY:
--   Supabase Dashboard → SQL Editor → paste and run.
--   Run all at once — each block is idempotent (DROP IF EXISTS + CREATE).
-- =============================================================================


-- ---------------------------------------------------------------------------
-- analytics_event
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS analytics_event_select_own ON public.analytics_event;
CREATE POLICY analytics_event_select_own
    ON public.analytics_event
    FOR SELECT
    TO authenticated
    USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS analytics_event_insert_own ON public.analytics_event;
CREATE POLICY analytics_event_insert_own
    ON public.analytics_event
    FOR INSERT
    TO authenticated
    WITH CHECK (user_id = (SELECT auth.uid()));


-- ---------------------------------------------------------------------------
-- case_session
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS case_session_select_own ON public.case_session;
CREATE POLICY case_session_select_own
    ON public.case_session
    FOR SELECT
    TO authenticated
    USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS case_session_insert_own ON public.case_session;
CREATE POLICY case_session_insert_own
    ON public.case_session
    FOR INSERT
    TO authenticated
    WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS case_session_update_own ON public.case_session;
CREATE POLICY case_session_update_own
    ON public.case_session
    FOR UPDATE
    TO authenticated
    USING (user_id = (SELECT auth.uid()))
    WITH CHECK (user_id = (SELECT auth.uid()));


-- ---------------------------------------------------------------------------
-- checklist_item_state  (joined through case_session; user ownership via FK)
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS checklist_item_state_select_own ON public.checklist_item_state;
CREATE POLICY checklist_item_state_select_own
    ON public.checklist_item_state
    FOR SELECT
    TO authenticated
    USING (
        session_id IN (
            SELECT session_id FROM public.case_session
            WHERE user_id = (SELECT auth.uid())
        )
    );

DROP POLICY IF EXISTS checklist_item_state_insert_own ON public.checklist_item_state;
CREATE POLICY checklist_item_state_insert_own
    ON public.checklist_item_state
    FOR INSERT
    TO authenticated
    WITH CHECK (
        session_id IN (
            SELECT session_id FROM public.case_session
            WHERE user_id = (SELECT auth.uid())
        )
    );

DROP POLICY IF EXISTS checklist_item_state_update_own ON public.checklist_item_state;
CREATE POLICY checklist_item_state_update_own
    ON public.checklist_item_state
    FOR UPDATE
    TO authenticated
    USING (
        session_id IN (
            SELECT session_id FROM public.case_session
            WHERE user_id = (SELECT auth.uid())
        )
    )
    WITH CHECK (
        session_id IN (
            SELECT session_id FROM public.case_session
            WHERE user_id = (SELECT auth.uid())
        )
    );


-- ---------------------------------------------------------------------------
-- consent_state
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
-- Supporting indexes (if not already present)
-- These ensure the WHERE user_id = ... planner path is fast.
-- ---------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_analytics_event_user
    ON public.analytics_event (user_id);

CREATE INDEX IF NOT EXISTS idx_case_session_user
    ON public.case_session (user_id);

CREATE INDEX IF NOT EXISTS idx_consent_state_user
    ON public.consent_state (user_id);

CREATE INDEX IF NOT EXISTS idx_checklist_item_state_session
    ON public.checklist_item_state (session_id);
