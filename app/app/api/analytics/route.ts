// POST /api/analytics — inserts analytics_event if consent enabled
// US-E2 | migrations_20260301_daas_consent_and_analytics.sql

import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";

function adminClient() {
    return createClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.SUPABASE_SERVICE_ROLE_KEY!,
        { auth: { persistSession: false } }
    );
}

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();
        const { event_name, visa_group, stage, properties } = body;

        if (!event_name) {
            return NextResponse.json({ error: "event_name required" }, { status: 400 });
        }

        // Resolve user from bearer token if present
        const token = req.headers.get("authorization")?.replace("Bearer ", "");
        let userId: string | null = null;
        if (token) {
            const { data } = await adminClient().auth.getUser(token);
            userId = data.user?.id ?? null;
        }

        if (!userId) {
            // No user — no event stored (analytics requires an authenticated user)
            return NextResponse.json({ ok: true, stored: false });
        }

        // Check consent_state — only insert if product_analytics_enabled
        const { data: consent } = await adminClient()
            .from("consent_state")
            .select("product_analytics_enabled")
            .eq("user_id", userId)
            .maybeSingle();

        if (!consent?.product_analytics_enabled) {
            return NextResponse.json({ ok: true, stored: false, reason: "analytics_disabled" });
        }

        // Insert event
        const { error } = await adminClient().from("analytics_event").insert({
            user_id: userId,
            event_name,
            visa_group: visa_group ?? null,
            stage: stage ?? null,
            properties: properties ?? {},
        });

        if (error) {
            console.error("analytics insert error:", error.message);
            return NextResponse.json({ ok: false, error: error.message }, { status: 500 });
        }

        return NextResponse.json({ ok: true, stored: true });
    } catch (err: unknown) {
        console.error("analytics route error:", err);
        return NextResponse.json({ error: "Internal server error" }, { status: 500 });
    }
}
