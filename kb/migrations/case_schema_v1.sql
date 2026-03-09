-- =====================================================
-- KangaVisa Core Database Schema
-- Version: 1.0
-- Migration: case_schema_v1
-- Applied: 2026-03-09
-- =====================================================
-- NOTE: analytics_events and consent_state/consent_event tables below
-- may already exist (as analytics_event singular, consent_state, consent_event)
-- from earlier migrations. Review before applying.
-- The 5 NEW tables are: cases, documents, timeline_events, flag_events,
-- case_scores, case_exports.
-- =====================================================

-- Enable UUID support
create extension if not exists "uuid-ossp";

-- =====================================================
-- CASES
-- =====================================================

create table public.cases (
    case_id uuid primary key default uuid_generate_v4(),
    user_id uuid not null,
    visa_subclass text not null,
    case_status text default 'draft',

    country_of_passport text,
    lodgement_location text,
    goal_summary text,

    created_at timestamptz default now(),
    updated_at timestamptz default now(),
    last_activity_at timestamptz default now()
);

create index idx_cases_user on public.cases(user_id);
create index idx_cases_subclass on public.cases(visa_subclass);


-- =====================================================
-- DOCUMENTS
-- =====================================================

create table public.documents (
    document_id uuid primary key default uuid_generate_v4(),
    case_id uuid not null references public.cases(case_id) on delete cascade,

    uploaded_by uuid not null,

    document_type text,
    file_name text,
    file_storage_path text,

    issuer text,
    issue_date date,
    valid_until date,

    language text,
    translation_present boolean default false,

    created_at timestamptz default now()
);

create index idx_documents_case on public.documents(case_id);


-- =====================================================
-- TIMELINE EVENTS
-- =====================================================

create table public.timeline_events (
    timeline_event_id uuid primary key default uuid_generate_v4(),
    case_id uuid not null references public.cases(case_id) on delete cascade,

    event_type text,
    title text,

    start_date date,
    end_date date,

    country text,
    description text,

    created_at timestamptz default now()
);

create index idx_timeline_case on public.timeline_events(case_id);


-- =====================================================
-- FLAG EVENTS
-- =====================================================

create table public.flag_events (
    flag_event_id uuid primary key default uuid_generate_v4(),
    case_id uuid not null references public.cases(case_id) on delete cascade,

    flag_code text not null,
    rule_id text not null,

    severity text,
    status text default 'unresolved',

    trigger_value jsonb,

    resolved_by_user boolean default false,
    resolution_note text,

    created_at timestamptz default now(),
    resolved_at timestamptz
);

create index idx_flags_case on public.flag_events(case_id);
create index idx_flags_code on public.flag_events(flag_code);


-- =====================================================
-- CASE SCORES
-- =====================================================

create table public.case_scores (
    case_id uuid primary key references public.cases(case_id) on delete cascade,

    readiness_score numeric,
    evidence_coverage numeric,
    timeline_completeness numeric,
    consistency_score numeric,
    risk_indicator_score numeric,

    unresolved_flags_count integer,
    timeline_gap_count integer,

    last_scored_at timestamptz default now()
);


-- =====================================================
-- EXPORTS
-- =====================================================

create table public.case_exports (
    export_id uuid primary key default uuid_generate_v4(),
    case_id uuid not null references public.cases(case_id) on delete cascade,

    export_type text,
    export_version text,

    file_path text,

    generated_at timestamptz default now(),
    generated_by uuid
);

create index idx_exports_case on public.case_exports(case_id);


-- =====================================================
-- ANALYTICS EVENTS (for GovData & product analytics)
-- SKIP IF analytics_event (singular) already exists from rls_performance_fix.sql
-- =====================================================

create table if not exists public.analytics_events (
    event_id uuid primary key default uuid_generate_v4(),

    user_id uuid,
    case_id uuid,

    event_type text,
    event_payload jsonb,

    created_at timestamptz default now()
);

create index if not exists idx_analytics_case on public.analytics_events(case_id);
create index if not exists idx_analytics_type on public.analytics_events(event_type);


-- =====================================================
-- CONSENT STATE (for DaaS / GovData compliance)
-- SKIP IF consent_state / consent_event already exist
-- =====================================================

create table if not exists public.consent_state (
    user_id uuid primary key,

    analytics_consent boolean default false,
    research_consent boolean default false,

    updated_at timestamptz default now()
);

create table if not exists public.consent_event (
    consent_event_id uuid primary key default uuid_generate_v4(),

    user_id uuid,
    consent_type text,
    consent_value boolean,

    recorded_at timestamptz default now()
);


-- =====================================================
-- ROW LEVEL SECURITY
-- =====================================================

alter table public.cases enable row level security;
alter table public.documents enable row level security;
alter table public.timeline_events enable row level security;
alter table public.flag_events enable row level security;
alter table public.case_scores enable row level security;
alter table public.case_exports enable row level security;

-- Users can access only their own cases
create policy "Users access own cases"
on public.cases
for all
using ((select auth.uid()) = user_id);

-- Documents
create policy "Users access own documents"
on public.documents
for all
using (
    case_id in (
        select case_id from public.cases
        where user_id = (select auth.uid())
    )
);

-- Timeline
create policy "Users access own timeline"
on public.timeline_events
for all
using (
    case_id in (
        select case_id from public.cases
        where user_id = (select auth.uid())
    )
);

-- Flags
create policy "Users access own flags"
on public.flag_events
for all
using (
    case_id in (
        select case_id from public.cases
        where user_id = (select auth.uid())
    )
);

-- Scores
create policy "Users access own scores"
on public.case_scores
for select
using (
    case_id in (
        select case_id from public.cases
        where user_id = (select auth.uid())
    )
);

-- Exports
create policy "Users access own exports"
on public.case_exports
for select
using (
    case_id in (
        select case_id from public.cases
        where user_id = (select auth.uid())
    )
);
