// /api/admin/overview — System Overview KPIs for admin dashboard
// Service role only. Sprint 33.

import { NextResponse } from "next/server";
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

        // Intake totals
        const { data: rows } = await supabase
            .from("visitor_intake")
            .select("passport_country,derived_signals,created_at");

        const intake = rows ?? [];
        const total = intake.length;

        const financial_risk = intake.filter(r => r.derived_signals?.financial_risk_flag).length;
        const doc_gap = intake.filter(r => r.derived_signals?.documentation_gap_flag).length;
        const strong = intake.filter(r => r.derived_signals?.strong_profile_indicator).length;

        // By country
        const countryMap: Record<string, number> = {};
        intake.forEach(r => {
            if (r.passport_country) countryMap[r.passport_country] = (countryMap[r.passport_country] ?? 0) + 1;
        });
        const by_country = Object.entries(countryMap)
            .sort((a, b) => b[1] - a[1])
            .slice(0, 8)
            .map(([name, users]) => ({ name, users }));

        // Top flags
        const top_flags = [
            { flag: "Financial evidence gap",     rate: total ? Math.round(100 * financial_risk / total) : 0, count: financial_risk },
            { flag: "Documentation not started",  rate: total ? Math.round(100 * doc_gap / total) : 0,       count: doc_gap },
            { flag: "Strong profile",             rate: total ? Math.round(100 * strong / total) : 0,        count: strong },
        ].sort((a, b) => b.count - a.count);

        // Client count
        const { count: client_count } = await supabase
            .from("client_accounts")
            .select("id", { count: "exact", head: true })
            .eq("active", true);

        return NextResponse.json({
            total_users: total,
            financial_risk_rate: total ? Math.round(100 * financial_risk / total) : 0,
            doc_gap_rate: total ? Math.round(100 * doc_gap / total) : 0,
            strong_profile_rate: total ? Math.round(100 * strong / total) : 0,
            active_clients: client_count ?? 0,
            by_country,
            top_flags,
        });
    } catch (err) {
        console.error("[GET /api/admin/overview]", err);
        return NextResponse.json({ error: "internal" }, { status: 500 });
    }
}
