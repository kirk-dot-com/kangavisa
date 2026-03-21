-- admin_rbac_v1.sql
-- RBAC foundation for Admin Console + GovData client management.
-- Sprint 33 | admin_console_prd.md
--
-- ⚠️  Apply in Supabase SQL Editor.
-- After applying, set your own role:
--   UPDATE profiles SET role = 'super_admin' WHERE id = '<your-auth-user-id>';

-- ── profiles ──────────────────────────────────────────────────────────────────
-- One row per auth user. role defaults to 'user'.
-- Roles: user | analyst | product_admin | super_admin | govdata_client

CREATE TABLE IF NOT EXISTS profiles (
    id          uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role        text NOT NULL DEFAULT 'user'
                    CHECK (role IN ('user', 'analyst', 'product_admin', 'super_admin', 'govdata_client')),
    display_name text,
    created_at  timestamptz NOT NULL DEFAULT now()
);

-- Auto-create a profile row when a new auth user signs up
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id)
    VALUES (NEW.id)
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Users can read their own profile
CREATE POLICY "profiles: own read"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

-- Super admins can read all profiles
CREATE POLICY "profiles: super_admin read all"
    ON profiles FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid() AND p.role = 'super_admin'
        )
    );

-- ── admin_roles ───────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS admin_roles (
    role        text PRIMARY KEY,
    permissions jsonb NOT NULL DEFAULT '{}',
    description text,
    created_at  timestamptz NOT NULL DEFAULT now()
);

INSERT INTO admin_roles (role, permissions, description) VALUES
    ('super_admin',   '{"all": true}',                                                    'Full system access'),
    ('analyst',       '{"read_analytics": true, "read_govdata": true}',                   'Read analytics, create reports'),
    ('product_admin', '{"manage_visas": true, "manage_flags": true}',                     'Manage visa configs and flags'),
    ('govdata_client','{"read_govdata_dashboard": true}',                                  'Read-only GovData dashboard access'),
    ('user',          '{}',                                                                'Standard user — no admin access')
ON CONFLICT (role) DO NOTHING;

-- No RLS needed — read-only reference table, no PII

-- ── client_accounts ───────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS client_accounts (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name        text NOT NULL,
    tier        text NOT NULL DEFAULT 'basic'
                    CHECK (tier IN ('basic', 'advanced', 'enterprise')),
    contact_email text,
    notes       text,
    active      boolean NOT NULL DEFAULT true,
    created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE client_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "client_accounts: super_admin only"
    ON client_accounts FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid() AND p.role = 'super_admin'
        )
    );

-- ── client_permissions ────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS client_permissions (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id   uuid NOT NULL REFERENCES client_accounts(id) ON DELETE CASCADE,
    dataset     text NOT NULL,   -- e.g. 'visitor_intake', 'risk_flags'
    access_level text NOT NULL DEFAULT 'read'
                    CHECK (access_level IN ('read', 'export', 'api')),
    created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE client_permissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "client_permissions: super_admin only"
    ON client_permissions FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid() AND p.role = 'super_admin'
        )
    );

-- ── audit_logs ────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS audit_logs (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    action      text NOT NULL,
    user_id     uuid REFERENCES auth.users(id),
    metadata    jsonb DEFAULT '{}',
    created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "audit_logs: super_admin read"
    ON audit_logs FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid() AND p.role = 'super_admin'
        )
    );

-- Service role can always insert (used by API routes)
CREATE POLICY "audit_logs: service insert"
    ON audit_logs FOR INSERT
    WITH CHECK (true);
