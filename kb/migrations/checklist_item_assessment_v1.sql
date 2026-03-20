-- Sprint 27 P2: Create checklist_item_state table + AI assessment columns
-- Applied: 2026-03-20
-- The table did not exist yet — this creates it from scratch with all required columns.
-- Idempotent (CREATE TABLE IF NOT EXISTS).

CREATE TABLE IF NOT EXISTS public.checklist_item_state (
    state_id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      uuid NOT NULL,
    evidence_id     uuid NOT NULL,
    status          text NOT NULL DEFAULT 'not_started'
                        CHECK (status IN ('not_started', 'in_progress', 'done', 'na')),
    note            text,
    -- Sprint 27 P2 — AI assessment
    draft_content   text,
    assessment_json jsonb,
    assessed_at     timestamptz,
    updated_at      timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT checklist_item_state_session_evidence_uk
        UNIQUE (session_id, evidence_id)
);

CREATE INDEX IF NOT EXISTS idx_checklist_item_state_session
    ON public.checklist_item_state (session_id);

-- Enable RLS
ALTER TABLE public.checklist_item_state ENABLE ROW LEVEL SECURITY;

-- Users may read/write their own item states (via session ownership)
-- The API enforces session ownership before any DB call, so we use service_role bypass.
-- Add a permissive policy so the service_role key can operate freely:
CREATE POLICY "service_role_all_checklist_item_state"
    ON public.checklist_item_state
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);
