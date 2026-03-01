// POST /api/auth/create-consent
// US-E1 — Creates consent_state row on sign-up using service role key.
// Must only be called server-side (from sign-up flow via fetch).

import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();
        const { user_id, product_analytics_enabled, govdata_research_enabled } = body;

        if (!user_id) {
            return NextResponse.json({ error: "user_id is required" }, { status: 400 });
        }

        const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
        const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

        if (!supabaseUrl || !serviceRoleKey) {
            return NextResponse.json(
                { error: "Supabase environment variables not configured" },
                { status: 500 }
            );
        }

        // Use service role to bypass RLS — server-only
        const supabase = createClient(supabaseUrl, serviceRoleKey, {
            auth: { persistSession: false },
        });

        const { error } = await supabase.from("consent_state").upsert(
            {
                user_id,
                product_analytics_enabled: product_analytics_enabled ?? false,
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
