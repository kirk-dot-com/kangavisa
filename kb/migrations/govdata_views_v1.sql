-- govdata_views_v1.sql
-- Aggregation views for GovData dashboard, sourced from visitor_intake.
-- Sprint 32 | govdata_dashboard_spec.md

-- ── Summary view ──────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW vw_govdata_summary AS
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

-- ── Country breakdown view ────────────────────────────────────────────────────

CREATE OR REPLACE VIEW vw_govdata_country AS
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
HAVING COUNT(*) >= 5  -- minimum cohort threshold
ORDER BY total_users DESC;

-- ── Flag frequency view ───────────────────────────────────────────────────────

CREATE OR REPLACE VIEW vw_govdata_flags AS
SELECT
    'financial_risk'    AS flag,
    'Financial evidence gap'  AS label,
    COUNT(*) FILTER (WHERE (derived_signals->>'financial_risk_flag')::boolean = true) AS frequency,
    COUNT(*) AS total
FROM visitor_intake
UNION ALL
SELECT
    'documentation_gap',
    'Documentation not started',
    COUNT(*) FILTER (WHERE (derived_signals->>'documentation_gap_flag')::boolean = true),
    COUNT(*)
FROM visitor_intake
UNION ALL
SELECT
    'intent_risk',
    'Intent / ties risk',
    COUNT(*) FILTER (WHERE (derived_signals->>'intent_risk_proxy')::boolean = true),
    COUNT(*)
FROM visitor_intake
UNION ALL
SELECT
    'strong_profile',
    'Strong applicant profile',
    COUNT(*) FILTER (WHERE (derived_signals->>'strong_profile_indicator')::boolean = true),
    COUNT(*)
FROM visitor_intake;

-- ── Age band cohort view ──────────────────────────────────────────────────────

CREATE OR REPLACE VIEW vw_govdata_age_cohort AS
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

-- ── Monthly trend view ────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW vw_govdata_monthly_trend AS
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

-- ── Travel behaviour view ─────────────────────────────────────────────────────

CREATE OR REPLACE VIEW vw_govdata_travel_behaviour AS
SELECT
    travel_history,
    COUNT(*) AS total_users
FROM visitor_intake
WHERE travel_history IS NOT NULL
GROUP BY travel_history
ORDER BY total_users DESC;

-- ── Trip duration view ────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW vw_govdata_trip_duration AS
SELECT
    trip_duration_band,
    COUNT(*) AS total_users
FROM visitor_intake
WHERE trip_duration_band IS NOT NULL
GROUP BY trip_duration_band
ORDER BY total_users DESC;
