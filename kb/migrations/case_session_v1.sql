-- Sprint 27: Create case_session and checklist_item_state tables
-- Applied: 2026-03-20
-- Idempotent — safe to re-run (CREATE TABLE IF NOT EXISTS)
-- ============================================================

-- case_session: one row per user × visa subclass × case date
CREATE TABLE IF NOT EXISTS public.case_session (
    session_id   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      uuid NOT NULL,
    subclass_code text NOT NULL,
    case_date    date NOT NULL,
    updated_at   timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT case_session_user_subclass_date_uk
        UNIQUE (user_id, subclass_code, case_date)
);

CREATE INDEX IF NOT EXISTS idx_case_session_user
    ON public.case_session (user_id);

-- RLS: service_role has full access (API routes use service key)
ALTER TABLE public.case_session ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_role_all_case_session"
    ON public.case_session
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);
