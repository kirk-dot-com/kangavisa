// POST /api/auth/create-consent
// US-E1 — Creates consent_state row on sign-up using service role key.
// Must only be called server-side (from sign-up flow via fetch).

import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();
        const { product_analytics_enabled, govdata_research_enabled, user_id: bodyUserId } = body;

        const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
        const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

        if (!supabaseUrl || !serviceRoleKey) {
            return NextResponse.json(
                { error: "Supabase environment variables not configured" },
                { status: 500 }
            );
        }

        const supabase = createClient(supabaseUrl, serviceRoleKey, {
            auth: { persistSession: false },
        });

        // Prefer JWT from Authorization header; fall back to body user_id (sign-up flow)
        let userId: string | undefined = bodyUserId;
        const authHeader = req.headers.get("authorization");
        if (authHeader?.startsWith("Bearer ")) {
            const jwt = authHeader.slice(7);
            const { data } = await supabase.auth.getUser(jwt);
            if (data.user) userId = data.user.id;
        }

        if (!userId) {
            return NextResponse.json({ error: "user_id is required" }, { status: 400 });
        }

        const { error } = await supabase.from("consent_state").upsert(
            {
                user_id: userId,
                product_analytics_enabled: product_analytics_enabled ?? true,
                govdata_research_enabled: govdata_research_enabled ?? false,
            },
            { onConflict: "user_id" }
        );

        if (error) {
            console.error("consent_state upsert error:", error.message);
            return NextResponse.json({ error: error.message }, { status: 500 });
        }

        return NextResponse.json({ ok: true }, { status: 201 });
    } catch (err: unknown) {
        console.error("create-consent route error:", err);
        return NextResponse.json({ error: "Internal server error" }, { status: 500 });
    }
}
