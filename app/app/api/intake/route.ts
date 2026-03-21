// /api/intake — persists visitor intake response to Supabase
// No auth required. Uses admin client (service role) to bypass RLS.
// All fields are bands/categories — no PII.
// Sprint 31

import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";

function adminClient() {
    const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
    if (!url || !key) throw new Error("Supabase env vars missing");
    return createClient(url, key, { auth: { persistSession: false } });
}

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();

        const {
            session_id,
            passport_country,
            country_of_residence,
            age_band,
            trip_duration_band,
            travel_history,
            financial_confidence,
            employment_status,
            documentation_readiness,
            accommodation_type,
            return_travel_booked,
            travel_companions,
            derived_signals,
        } = body;

        if (!session_id) {
            return NextResponse.json({ error: "session_id required" }, { status: 400 });
        }

        const supabase = adminClient();
        const { error } = await supabase.from("visitor_intake").insert({
            session_id,
            passport_country: passport_country || null,
            country_of_residence: country_of_residence || null,
            age_band: age_band || null,
            trip_duration_band: trip_duration_band || null,
            travel_history: travel_history || null,
            financial_confidence: financial_confidence || null,
            employment_status: employment_status || null,
            documentation_readiness: documentation_readiness || null,
            accommodation_type: accommodation_type || null,
            return_travel_booked: return_travel_booked ?? null,
            travel_companions: travel_companions || null,
            derived_signals: derived_signals ?? {},
        });

        if (error) throw error;

        return NextResponse.json({ ok: true });
    } catch (err) {
        console.error("[POST /api/intake]", err);
        return NextResponse.json({ error: "internal" }, { status: 500 });
    }
}
