// /api/govdata/summary — aggregate KPIs + top countries + top flags + monthly trend
// Admin client (service role). No user auth required server-side.
// Sprint 32 | govdata_dashboard_spec.md

import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";

// Required: this route reads searchParams dynamically at request time
export const dynamic = "force-dynamic";

function adminClient() {
    const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
    if (!url || !key) throw new Error("Supabase env vars missing");
    return createClient(url, key, { auth: { persistSession: false } });
}

function daysAgo(days: number): string {
    const d = new Date();
    d.setDate(d.getDate() - days);
    return d.toISOString();
}

export async function GET(req: NextRequest) {
    try {
        const { searchParams } = req.nextUrl;
        const days = parseInt(searchParams.get("days") ?? "30");
        const country = searchParams.get("country") ?? null;
        const since = daysAgo(days);

        const supabase = adminClient();

        // Build filter
        let q = supabase
            .from("visitor_intake")
            .select("passport_country,age_band,travel_history,trip_duration_band,financial_confidence,documentation_readiness,derived_signals,created_at")
            .gte("created_at", since);

        if (country) q = q.eq("passport_country", country);

        const { data, error } = await q;
        if (error) throw error;

        const rows = data ?? [];
        const total = rows.length;

        // KPIs
        const financial_risk_count = rows.filter(r => r.derived_signals?.financial_risk_flag).length;
        const doc_gap_count = rows.filter(r => r.derived_signals?.documentation_gap_flag).length;
        const intent_risk_count = rows.filter(r => r.derived_signals?.intent_risk_proxy).length;
        const strong_count = rows.filter(r => r.derived_signals?.strong_profile_indicator).length;

        // Top countries
        const countryCounts: Record<string, number> = {};
        rows.forEach(r => {
            if (r.passport_country) countryCounts[r.passport_country] = (countryCounts[r.passport_country] ?? 0) + 1;
        });
        const top_countries = Object.entries(countryCounts)
            .sort((a, b) => b[1] - a[1])
            .slice(0, 8)
            .map(([name, users]) => ({ name, users }));

        // Top flags
        const top_flags = [
            { flag: "Financial evidence gap", frequency: financial_risk_count, rate: total ? Math.round(100 * financial_risk_count / total) : 0 },
            { flag: "Documentation not started", frequency: doc_gap_count, rate: total ? Math.round(100 * doc_gap_count / total) : 0 },
            { flag: "Intent / ties risk", frequency: intent_risk_count, rate: total ? Math.round(100 * intent_risk_count / total) : 0 },
            { flag: "Strong applicant profile", frequency: strong_count, rate: total ? Math.round(100 * strong_count / total) : 0 },
        ].sort((a, b) => b.frequency - a.frequency);

        // Monthly trend (group by YYYY-MM)
        const monthMap: Record<string, { users: number; risk: number }> = {};
        rows.forEach(r => {
            const key = r.created_at?.slice(0, 7) ?? "unknown";
            if (!monthMap[key]) monthMap[key] = { users: 0, risk: 0 };
            monthMap[key].users++;
            if (r.derived_signals?.financial_risk_flag) monthMap[key].risk++;
        });
        const trend = Object.entries(monthMap)
            .sort((a, b) => a[0].localeCompare(b[0]))
            .map(([month, { users, risk }]) => ({
                month,
                users,
                risk_rate: users ? Math.round(100 * risk / users) : 0,
            }));

        // Travel behaviour
        const behaviourMap: Record<string, number> = {};
        rows.forEach(r => {
            if (r.travel_history) behaviourMap[r.travel_history] = (behaviourMap[r.travel_history] ?? 0) + 1;
        });
        const travel_behaviour = Object.entries(behaviourMap).map(([label, count]) => ({ label, count }));

        // Trip duration
        const durationMap: Record<string, number> = {};
        rows.forEach(r => {
            if (r.trip_duration_band) durationMap[r.trip_duration_band] = (durationMap[r.trip_duration_band] ?? 0) + 1;
        });
        const trip_duration = Object.entries(durationMap).map(([label, count]) => ({ label, count }));

        return NextResponse.json({
            total,
            financial_risk_rate: total ? Math.round(100 * financial_risk_count / total) : 0,
            doc_gap_rate: total ? Math.round(100 * doc_gap_count / total) : 0,
            intent_risk_rate: total ? Math.round(100 * intent_risk_count / total) : 0,
            strong_profile_rate: total ? Math.round(100 * strong_count / total) : 0,
            top_countries,
            top_flags,
            trend,
            travel_behaviour,
            trip_duration,
        });
    } catch (err) {
        console.error("[GET /api/govdata/summary]", err);
        return NextResponse.json({ error: "internal" }, { status: 500 });
    }
}
