-- visitor_intake_v1.sql
-- Stores anonymous visitor intake responses for subclass 600 funnel.
-- No PII — all fields are bands/categories. Session keyed by anon UUID.
-- Sprint 31

CREATE TABLE IF NOT EXISTS visitor_intake (
    intake_id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id                UUID NOT NULL,

    -- Stage 1: demographic + travel context
    passport_country          TEXT,
    country_of_residence      TEXT,
    age_band                  TEXT,
    trip_duration_band        TEXT,
    travel_history            TEXT,

    -- Stage 2: risk signals
    financial_confidence      TEXT,
    employment_status         TEXT,
    documentation_readiness   TEXT,

    -- Stage 3: optional enrichment
    accommodation_type        TEXT,
    return_travel_booked      BOOLEAN,
    travel_companions         TEXT,

    -- Derived signals (computed client-side, stored for analytics)
    derived_signals           JSONB DEFAULT '{}',

    created_at                TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for analytics aggregation
CREATE INDEX IF NOT EXISTS visitor_intake_created_at_idx ON visitor_intake (created_at);
CREATE INDEX IF NOT EXISTS visitor_intake_passport_country_idx ON visitor_intake (passport_country);

-- RLS: public anon INSERT, no SELECT (data is aggregate only)
ALTER TABLE visitor_intake ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "visitor_intake_anon_insert" ON visitor_intake;
CREATE POLICY "visitor_intake_anon_insert"
    ON visitor_intake
    FOR INSERT
    WITH CHECK (true);
