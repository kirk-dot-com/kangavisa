-- Sprint 27 P2: AI assessment columns on checklist_item_state
-- Apply in Supabase SQL Editor — idempotent (IF NOT EXISTS)

ALTER TABLE checklist_item_state
    ADD COLUMN IF NOT EXISTS draft_content   text,
    ADD COLUMN IF NOT EXISTS assessment_json jsonb,
    ADD COLUMN IF NOT EXISTS assessed_at     timestamptz;
