-- migrations/20260301_daas_consent_and_analytics.sql
-- Supabase/Postgres migration: Consent + Analytics event scaffolding (GovData-ready)
-- Notes:
--  - Uses auth.uid() for RLS policies (Supabase auth)
--  - Keep analytics de-identified: do not store names/DOB/passport/etc.
--  - Consider using separate schemas: app, analytics, govdata (optional). This snippet uses public for simplicity.

BEGIN;

-- Ensure UUID generator exists
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1) Consent current state (one row per user)
CREATE TABLE IF NOT EXISTS consent_state (
  user_id UUID PRIMARY KEY,
  product_analytics_enabled BOOLEAN NOT NULL DEFAULT true,
  govdata_research_enabled  BOOLEAN NOT NULL DEFAULT false,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_by TEXT NULL
);

-- 2) Consent event ledger (append-only)
CREATE TABLE IF NOT EXISTS consent_event (
  consent_event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  event_type TEXT NOT NULL CHECK (event_type IN ('ENABLE_PRODUCT_ANALYTICS','DISABLE_PRODUCT_ANALYTICS','ENABLE_GOVDATA','DISABLE_GOVDATA')),
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  client_meta JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_consent_event_user_time ON consent_event(user_id, occurred_at DESC);

-- 3) Analytics events (de-identified journey telemetry)
-- Store only pseudonymous user_id + coarse dimensions.
-- If you want stricter separation, store a hashed/pseudonymous id here instead of auth user_id.
CREATE TABLE IF NOT EXISTS analytics_event (
  analytics_event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  event_name TEXT NOT NULL, -- e.g., INTAKE_STARTED, CHECKLIST_VIEWED, DOC_UPLOADED, FLAG_RESOLVED, PACK_EXPORTED
  visa_group TEXT NULL,     -- e.g., '500', '485', '482', '417/462', 'PARTNER'
  stage TEXT NULL,          -- e.g., 'intake','checklist','upload','flags','export'
  properties JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_analytics_event_time ON analytics_event(occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_event_user_time ON analytics_event(user_id, occurred_at DESC);

-- =========================
-- RLS RECOMMENDATIONS
-- =========================
ALTER TABLE consent_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE consent_event ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_event ENABLE ROW LEVEL SECURITY;

-- Consent: users can read/update their own consent state; events are append-only (insert only).
DO $$ BEGIN
  CREATE POLICY "consent_state_select_own"
    ON consent_state FOR SELECT
    USING (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "consent_state_update_own"
    ON consent_state FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "consent_state_insert_own"
    ON consent_state FOR INSERT
    WITH CHECK (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "consent_event_insert_own"
    ON consent_event FOR INSERT
    WITH CHECK (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Optional: allow users to view their own consent history
DO $$ BEGIN
  CREATE POLICY "consent_event_select_own"
    ON consent_event FOR SELECT
    USING (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Analytics: allow insert only if product analytics enabled.
DO $$ BEGIN
  CREATE POLICY "analytics_event_insert_if_enabled"
    ON analytics_event FOR INSERT
    WITH CHECK (
      user_id = auth.uid()
      AND EXISTS (
        SELECT 1 FROM consent_state cs
        WHERE cs.user_id = auth.uid()
          AND cs.product_analytics_enabled = true
      )
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Optional: allow users to read their own analytics events (can be disabled)
DO $$ BEGIN
  CREATE POLICY "analytics_event_select_own"
    ON analytics_event FOR SELECT
    USING (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

COMMIT;

-- Post-migration recommendation:
-- Ensure every new user gets a consent_state row (via auth trigger, edge function, or app init step).
--
-- GovData exports must be served from aggregated views/tables with their own RLS rules.
