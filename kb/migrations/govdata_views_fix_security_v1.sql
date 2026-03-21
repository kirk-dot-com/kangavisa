-- govdata_views_fix_security_v1.sql
-- Recreates all vw_govdata_* views with security_invoker = on.
-- Fixes Supabase lint: security_definer_view (0010)
-- Run in Supabase SQL Editor after govdata_views_v1.sql has been applied.

-- Drop existing views (order matters — dependent views last)
DROP VIEW IF EXISTS vw_govdata_summary;
DROP VIEW IF EXISTS vw_govdata_country;
DROP VIEW IF EXISTS vw_govdata_flags;
DROP VIEW IF EXISTS vw_govdata_age_cohort;
DROP VIEW IF EXISTS vw_govdata_monthly_trend;
DROP VIEW IF EXISTS vw_govdata_travel_behaviour;
DROP VIEW IF EXISTS vw_govdata_trip_duration;

-- Recreate with security_invoker = on
-- (view runs as the querying user, respecting their RLS policies)

CREATE VIEW vw_govdata_summary
WITH (security_invoker = on) AS
SELECT
    COUNT(*)                                                         AS total_users,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE (derived_signals->>'financial_risk_flag')::boolean = true
        ) / NULLIF(COUNT(*), 0), 1)                                  AS financial_risk_rate,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE (derived_signals->>'documentation_gap_flag')::boolean = true
        ) / NULLIF(COUNT(*), 0), 1)                                  AS doc_gap_rate,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE (derived_signals->>'intent_risk_proxy')::boolean = true
        ) / NULLIF(COUNT(*), 0), 1)                                  AS intent_risk_rate,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE (derived_signals->>'strong_profile_indicator')::boolean = true
        ) / NULLIF(COUNT(*), 0), 1)                                  AS strong_profile_rate
FROM visitor_intake;

CREATE VIEW vw_govdata_country
WITH (security_invoker = on) AS
SELECT
    passport_country                                                  AS country,
    COUNT(*)                                                          AS total_users,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE (derived_signals->>'financial_risk_flag')::boolean = true
        ) / NULLIF(COUNT(*), 0), 1)                                   AS financial_risk_rate,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE (derived_signals->>'documentation_gap_flag')::boolean = true
        ) / NULLIF(COUNT(*), 0), 1)                                   AS doc_gap_rate,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE (derived_signals->>'intent_risk_proxy')::boolean = true
        ) / NULLIF(COUNT(*), 0), 1)                                   AS intent_risk_rate,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE travel_history = 'first_time_traveller'
        ) / NULLIF(COUNT(*), 0), 1)                                   AS first_time_rate
FROM visitor_intake
WHERE passport_country IS NOT NULL
GROUP BY passport_country
HAVING COUNT(*) >= 5
ORDER BY total_users DESC;

CREATE VIEW vw_govdata_flags
WITH (security_invoker = on) AS
SELECT 'financial_risk' AS flag, 'Financial evidence gap' AS label,
    COUNT(*) FILTER (WHERE (derived_signals->>'financial_risk_flag')::boolean = true) AS frequency,
    COUNT(*) AS total
FROM visitor_intake
UNION ALL
SELECT 'documentation_gap', 'Documentation not started',
    COUNT(*) FILTER (WHERE (derived_signals->>'documentation_gap_flag')::boolean = true),
    COUNT(*) FROM visitor_intake
UNION ALL
SELECT 'intent_risk', 'Intent / ties risk',
    COUNT(*) FILTER (WHERE (derived_signals->>'intent_risk_proxy')::boolean = true),
    COUNT(*) FROM visitor_intake
UNION ALL
SELECT 'strong_profile', 'Strong applicant profile',
    COUNT(*) FILTER (WHERE (derived_signals->>'strong_profile_indicator')::boolean = true),
    COUNT(*) FROM visitor_intake;

CREATE VIEW vw_govdata_age_cohort
WITH (security_invoker = on) AS
SELECT
    age_band,
    COUNT(*)                                                          AS total_users,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE (derived_signals->>'financial_risk_flag')::boolean = true
        ) / NULLIF(COUNT(*), 0), 1)                                   AS financial_risk_rate
FROM visitor_intake
WHERE age_band IS NOT NULL
GROUP BY age_band
ORDER BY age_band;

CREATE VIEW vw_govdata_monthly_trend
WITH (security_invoker = on) AS
SELECT
    DATE_TRUNC('month', created_at)   AS month,
    COUNT(*)                          AS total_users,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE (derived_signals->>'financial_risk_flag')::boolean = true
        ) / NULLIF(COUNT(*), 0), 1)   AS financial_risk_rate
FROM visitor_intake
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month;

CREATE VIEW vw_govdata_travel_behaviour
WITH (security_invoker = on) AS
SELECT travel_history, COUNT(*) AS total_users
FROM visitor_intake
WHERE travel_history IS NOT NULL
GROUP BY travel_history
ORDER BY total_users DESC;

CREATE VIEW vw_govdata_trip_duration
WITH (security_invoker = on) AS
SELECT trip_duration_band, COUNT(*) AS total_users
FROM visitor_intake
WHERE trip_duration_band IS NOT NULL
GROUP BY trip_duration_band
ORDER BY total_users DESC;
