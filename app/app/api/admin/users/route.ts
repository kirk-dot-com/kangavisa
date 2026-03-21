// /api/admin/users — list all auth users + their profiles roles
// PATCH to update a single user's role.
// Service role only. Sprint 33.

import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";

export const dynamic = "force-dynamic";

function adminClient() {
    const url = process.env.NEXT_PUBLIC_SUPABASE_URL!;
    const key = process.env.SUPABASE_SERVICE_ROLE_KEY!;
    return createClient(url, key, { auth: { persistSession: false } });
}

export async function GET() {
    try {
        const supabase = adminClient();

        // List all auth users (service role can access auth.admin)
        const { data: { users }, error: authError } = await supabase.auth.admin.listUsers();
        if (authError) throw authError;

        // Get all profiles
        const { data: profiles } = await supabase
            .from("profiles")
            .select("id, role");

        const profileMap = Object.fromEntries((profiles ?? []).map(p => [p.id, p.role]));

        const result = users.map(u => ({
            id: u.id,
            email: u.email,
            role: profileMap[u.id] ?? "user",
            created_at: u.created_at,
            last_sign_in: u.last_sign_in_at,
        }));

        return NextResponse.json({ users: result });
    } catch (err) {
        console.error("[GET /api/admin/users]", err);
        return NextResponse.json({ error: "internal" }, { status: 500 });
    }
}

export async function PATCH(req: NextRequest) {
    try {
        const { user_id, role } = await req.json();

        const VALID_ROLES = ["user", "analyst", "product_admin", "super_admin", "govdata_client"];
        if (!user_id || !role || !VALID_ROLES.includes(role)) {
            return NextResponse.json({ error: "invalid user_id or role" }, { status: 400 });
        }

        const supabase = adminClient();

        // Upsert profile row
        const { error } = await supabase
            .from("profiles")
            .upsert({ id: user_id, role }, { onConflict: "id" });

        if (error) throw error;

        // Audit log
        await supabase.from("audit_logs").insert({
            action: "role_updated",
            metadata: { user_id, new_role: role },
        });

        return NextResponse.json({ ok: true });
    } catch (err) {
        console.error("[PATCH /api/admin/users]", err);
        return NextResponse.json({ error: "internal" }, { status: 500 });
    }
}
