-- kb/schema.sql
-- Postgres DDL for KangaVisa Knowledge Base (KB) v0.1
-- Notes:
--  - Uses UUID primary keys (gen_random_uuid requires pgcrypto)
--  - Stores raw source snapshots + structured requirements/evidence/flags + change events
--  - Effective dating is first-class to support legal/versioned rules

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Enums
DO $$ BEGIN
  CREATE TYPE kb_source_type AS ENUM (
    'FRL_ACT','FRL_REGS','FRL_INSTRUMENT',
    'HOMEAFFAIRS_PAGE','HOMEAFFAIRS_REPORT',
    'DATAGOV_DATASET','DATAGOV_RESOURCE'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE kb_source_status AS ENUM ('current','superseded','repealed','archived');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE kb_instrument_status AS ENUM ('in_force','repealed','superseded');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE kb_audience AS ENUM ('B2C','B2B','Both');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE kb_requirement_type AS ENUM (
    'identity','genuine','financial','english','health','character',
    'sponsorship','work_history','relationship','occupation','nomination','other'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE kb_confidence AS ENUM ('high','medium','low');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE kb_flag_severity AS ENUM ('info','warning','risk');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE kb_change_type AS ENUM (
    'text_change','new_version','repeal','new_instrument','dataset_update'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Source document snapshots (canonical store)
CREATE TABLE IF NOT EXISTS source_document (
  source_doc_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_type          kb_source_type NOT NULL,
  title                TEXT NOT NULL,
  canonical_url        TEXT NOT NULL,
  content_hash         TEXT NOT NULL,
  retrieved_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  published_at         TIMESTAMPTZ NULL,
  effective_from       DATE NULL,
  effective_to         DATE NULL,
  status               kb_source_status NOT NULL DEFAULT 'current',
  raw_blob_uri         TEXT NOT NULL,
  parsed_text_uri      TEXT NULL,
  metadata_json        JSONB NOT NULL DEFAULT '{}'::jsonb,

  CONSTRAINT source_document_canonical_url_uk UNIQUE (canonical_url, content_hash)
);

CREATE INDEX IF NOT EXISTS idx_source_document_type ON source_document(source_type);
CREATE INDEX IF NOT EXISTS idx_source_document_retrieved_at ON source_document(retrieved_at);
CREATE INDEX IF NOT EXISTS idx_source_document_effective ON source_document(effective_from, effective_to);

-- Instruments (FRL legislative instruments), linked to the latest snapshot
CREATE TABLE IF NOT EXISTS instrument (
  instrument_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  frl_title_id               TEXT NOT NULL,
  series                     TEXT NULL,        -- e.g., LIN 24/022
  name                       TEXT NOT NULL,
  enabling_authority         TEXT NULL,        -- e.g., Migration Regulations 1994
  effective_from             DATE NOT NULL,
  effective_to               DATE NULL,
  status                     kb_instrument_status NOT NULL DEFAULT 'in_force',
  latest_source_doc_id       UUID NOT NULL REFERENCES source_document(source_doc_id),
  supersedes_instrument_id   UUID NULL REFERENCES instrument(instrument_id),
  repealed_by_instrument_id  UUID NULL REFERENCES instrument(instrument_id),

  CONSTRAINT instrument_frl_title_id_uk UNIQUE (frl_title_id, effective_from)
);

CREATE INDEX IF NOT EXISTS idx_instrument_status ON instrument(status);
CREATE INDEX IF NOT EXISTS idx_instrument_effective ON instrument(effective_from, effective_to);

-- Visa subclasses supported by the KB
CREATE TABLE IF NOT EXISTS visa_subclass (
  visa_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subclass_code        TEXT NOT NULL,          -- 500, 485, 482, 417, 462, 820, 801, 309, 100
  stream               TEXT NULL,
  audience             kb_audience NOT NULL DEFAULT 'B2C',
  canonical_info_url   TEXT NULL,
  last_verified_at     TIMESTAMPTZ NULL,

  CONSTRAINT visa_subclass_code_stream_uk UNIQUE (subclass_code, COALESCE(stream,''))
);

CREATE INDEX IF NOT EXISTS idx_visa_subclass_code ON visa_subclass(subclass_code);

-- Requirements: atomic nodes for structured-first retrieval
CREATE TABLE IF NOT EXISTS requirement (
  requirement_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  visa_id            UUID NOT NULL REFERENCES visa_subclass(visa_id) ON DELETE CASCADE,
  requirement_type   kb_requirement_type NOT NULL,
  title              TEXT NOT NULL,
  plain_english      TEXT NOT NULL,
  legal_basis        JSONB NOT NULL DEFAULT '[]'::jsonb,        -- citations to Act/Regs/Instrument
  operational_basis  JSONB NOT NULL DEFAULT '[]'::jsonb,        -- guidance pages/reports
  effective_from     DATE NOT NULL,
  effective_to       DATE NULL,
  rule_logic         JSONB NOT NULL DEFAULT '{}'::jsonb,        -- structured logic: inputs -> flag_ids
  confidence         kb_confidence NOT NULL DEFAULT 'medium',
  last_reviewed_at   TIMESTAMPTZ NULL,

  CONSTRAINT requirement_effective_ck CHECK (effective_to IS NULL OR effective_to >= effective_from)
);

CREATE INDEX IF NOT EXISTS idx_requirement_visa_type ON requirement(visa_id, requirement_type);
CREATE INDEX IF NOT EXISTS idx_requirement_effective ON requirement(effective_from, effective_to);

-- Evidence items: checklist entries mapped to requirements
CREATE TABLE IF NOT EXISTS evidence_item (
  evidence_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requirement_id     UUID NOT NULL REFERENCES requirement(requirement_id) ON DELETE CASCADE,
  label              TEXT NOT NULL,
  what_it_proves     TEXT NOT NULL,
  examples           JSONB NOT NULL DEFAULT '[]'::jsonb,
  common_gaps        JSONB NOT NULL DEFAULT '[]'::jsonb,
  priority           INT NOT NULL DEFAULT 3,   -- 1=high
  effective_from     DATE NOT NULL,
  effective_to       DATE NULL,
  legal_basis        JSONB NOT NULL DEFAULT '[]'::jsonb,

  CONSTRAINT evidence_effective_ck CHECK (effective_to IS NULL OR effective_to >= effective_from)
);

CREATE INDEX IF NOT EXISTS idx_evidence_requirement ON evidence_item(requirement_id);
CREATE INDEX IF NOT EXISTS idx_evidence_priority ON evidence_item(priority);

-- Flag templates: reusable Flag Cards (trigger/why/actions/evidence)
CREATE TABLE IF NOT EXISTS flag_template (
  flag_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  visa_id           UUID NOT NULL REFERENCES visa_subclass(visa_id) ON DELETE CASCADE,
  title             TEXT NOT NULL,
  trigger_schema    JSONB NOT NULL DEFAULT '{}'::jsonb,
  why_it_matters    TEXT NOT NULL,
  actions           JSONB NOT NULL DEFAULT '[]'::jsonb,
  evidence_examples JSONB NOT NULL DEFAULT '[]'::jsonb,
  severity          kb_flag_severity NOT NULL DEFAULT 'warning',
  effective_from    DATE NOT NULL,
  effective_to      DATE NULL,
  sources           JSONB NOT NULL DEFAULT '{}'::jsonb,

  CONSTRAINT flag_effective_ck CHECK (effective_to IS NULL OR effective_to >= effective_from)
);

CREATE INDEX IF NOT EXISTS idx_flag_visa_severity ON flag_template(visa_id, severity);

-- Change events: outputs from diffing (feeds review gates + release notes)
CREATE TABLE IF NOT EXISTS change_event (
  change_event_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  detected_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  source_doc_id_old   UUID NULL REFERENCES source_document(source_doc_id),
  source_doc_id_new   UUID NOT NULL REFERENCES source_document(source_doc_id),
  change_type         kb_change_type NOT NULL,
  impact_score        INT NOT NULL DEFAULT 0,
  affected_visa_ids   UUID[] NOT NULL DEFAULT '{}'::uuid[],
  summary             TEXT NOT NULL,
  requires_review     BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_change_event_detected_at ON change_event(detected_at);
CREATE INDEX IF NOT EXISTS idx_change_event_requires_review ON change_event(requires_review);

-- Optional: a simple KB release table (for governance + traceability)
CREATE TABLE IF NOT EXISTS kb_release (
  release_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  release_tag         TEXT NOT NULL,                -- e.g., kb-2026-02-22 or v0.3.0
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by          TEXT NULL,
  notes              TEXT NOT NULL DEFAULT '',
  source_doc_ids      UUID[] NOT NULL DEFAULT '{}'::uuid[],
  change_event_ids    UUID[] NOT NULL DEFAULT '{}'::uuid[],

  CONSTRAINT kb_release_tag_uk UNIQUE (release_tag)
);
