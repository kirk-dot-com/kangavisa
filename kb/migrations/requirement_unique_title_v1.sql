-- =====================================================================
-- KangaVisa Knowledge Base — Sprint 17
-- requirement_unique_title_v1.sql
-- =====================================================================
-- Adds a unique index on requirement (visa_id, title) to prevent
-- duplicate requirement rows across seed reruns.
--
-- Root cause: seed_mvp_visas_v1.sql used gen_random_uuid() for
-- requirement_id, so ON CONFLICT DO NOTHING did not fire on re-runs,
-- creating duplicate (visa_id, title) pairs for 485 and 820.
--
-- Safe to apply multiple times — uses IF NOT EXISTS.
-- =====================================================================

CREATE UNIQUE INDEX IF NOT EXISTS requirement_visa_title_uk
    ON requirement (visa_id, title);
