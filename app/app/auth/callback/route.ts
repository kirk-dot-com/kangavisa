// /auth/callback/route.ts — exchanges Supabase auth code for a cookie session
// Called automatically after email confirmation links (signup, password reset)

import { NextRequest, NextResponse } from "next/server";
import { createSupabaseServerClient } from "../../../lib/supabase-server";

export async function GET(req: NextRequest) {
    const { searchParams, origin } = new URL(req.url);
    const code = searchParams.get("code");
    const next = searchParams.get("next") ?? "/pathway";

    if (code) {
        const supabase = createSupabaseServerClient();
        const { error } = await supabase.auth.exchangeCodeForSession(code);
        if (!error) {
            return NextResponse.redirect(`${origin}${next}`);
        }
    }

    // Auth failed — redirect to login with error param
    return NextResponse.redirect(`${origin}/auth/login?error=auth_callback_failed`);
}
