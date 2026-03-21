// /api/govdata/country — country deep dive: risk breakdown + age cohort table
// Admin client (service role). Sprint 32.

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
        const country = searchParams.get("country");
        const days = parseInt(searchParams.get("days") ?? "90");

        if (!country) return NextResponse.json({ error: "country required" }, { status: 400 });

        const supabase = adminClient();
        const { data, error } = await supabase
            .from("visitor_intake")
            .select("age_band,travel_history,financial_confidence,documentation_readiness,derived_signals,created_at")
            .eq("passport_country", country)
            .gte("created_at", daysAgo(days));

        if (error) throw error;

        const rows = data ?? [];
        const total = rows.length;

        const financial_risk = rows.filter(r => r.derived_signals?.financial_risk_flag).length;
        const doc_gap = rows.filter(r => r.derived_signals?.documentation_gap_flag).length;
        const intent_risk = rows.filter(r => r.derived_signals?.intent_risk_proxy).length;

        // Risk breakdown for stacked bar
        const risk_breakdown = [
            { name: "Financial", rate: total ? Math.round(100 * financial_risk / total) : 0 },
            { name: "Documentation", rate: total ? Math.round(100 * doc_gap / total) : 0 },
            { name: "Intent / Ties", rate: total ? Math.round(100 * intent_risk / total) : 0 },
        ];

        // Age cohort table
        const ageBands = ["18-24", "25-34", "35-44", "45-54", "55+"];
        const cohort_table = ageBands.map(band => {
            const subset = rows.filter(r => r.age_band === band);
            const riskCount = subset.filter(r => r.derived_signals?.financial_risk_flag).length;
            return {
                age_band: band,
                users: subset.length,
                risk_rate: subset.length ? Math.round(100 * riskCount / subset.length) : 0,
            };
        }).filter(r => r.users > 0);

        // Trend by month
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

        const top_risk = risk_breakdown.sort((a, b) => b.rate - a.rate)[0]?.name ?? "—";

        return NextResponse.json({
            country,
            total,
            financial_risk_rate: total ? Math.round(100 * financial_risk / total) : 0,
            doc_gap_rate: total ? Math.round(100 * doc_gap / total) : 0,
            intent_risk_rate: total ? Math.round(100 * intent_risk / total) : 0,
            top_risk,
            risk_breakdown,
            cohort_table,
            trend,
        });
    } catch (err) {
        console.error("[GET /api/govdata/country]", err);
        return NextResponse.json({ error: "internal" }, { status: 500 });
    }
}
