// /api/admin/debug-role — TEMPORARY diagnostic endpoint
// Returns the current auth user's ID and their profiles row as seen by service role.
// DELETE after confirming admin access works.

import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { createSupabaseServerClient } from "../../../../lib/supabase-server";

export const dynamic = "force-dynamic";

export async function GET() {
    try {
        // 1. Get auth user via cookie
        const supabase = createSupabaseServerClient();
        const { data: { user }, error: authError } = await supabase.auth.getUser();

        if (!user) {
            return NextResponse.json({ error: "no auth user", authError });
        }

        // 2. Check profiles via service role
        const service = createClient(
            process.env.NEXT_PUBLIC_SUPABASE_URL!,
            process.env.SUPABASE_SERVICE_ROLE_KEY!,
            { auth: { persistSession: false } }
        );

        const { data: profile, error: profileError } = await service
            .from("profiles")
            .select("id, role")
            .eq("id", user.id)
            .single();

        // 3. Count all profiles
        const { count } = await service
            .from("profiles")
            .select("id", { count: "exact", head: true });

        return NextResponse.json({
            user_id: user.id,
            user_email: user.email,
            profile,
            profile_error: profileError?.message ?? null,
            total_profiles: count,
            service_role_key_set: !!process.env.SUPABASE_SERVICE_ROLE_KEY,
        });
    } catch (err) {
        return NextResponse.json({ error: String(err) }, { status: 500 });
    }
}
