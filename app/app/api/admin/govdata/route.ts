// /api/admin/govdata — GovData Monitor: volumes, cohort checks, freshness
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

        const { data: rows } = await supabase
            .from("visitor_intake")
            .select("passport_country,derived_signals,created_at");

        const intake = rows ?? [];

        // Aggregate by country
        const countryMap: Record<string, { count: number; last_seen: string }> = {};
        intake.forEach(r => {
            if (!r.passport_country) return;
            const existing = countryMap[r.passport_country];
            if (!existing) {
                countryMap[r.passport_country] = { count: 1, last_seen: r.created_at ?? "" };
            } else {
                existing.count++;
                if (r.created_at && r.created_at > existing.last_seen) {
                    existing.last_seen = r.created_at;
                }
            }
        });

        const MIN_COHORT = 10;
        const datasets = Object.entries(countryMap)
            .sort((a, b) => b[1].count - a[1].count)
            .map(([country, { count, last_seen }]) => ({
                country,
                count,
                last_seen,
                cohort_ok: count >= MIN_COHORT,
            }));

        // Overall freshness
        const all_dates = intake.map(r => r.created_at ?? "").filter(Boolean).sort();
        const last_updated = all_dates.at(-1) ?? null;

        return NextResponse.json({
            total: intake.length,
            datasets,
            last_updated,
            min_cohort: MIN_COHORT,
        });
    } catch (err) {
        console.error("[GET /api/admin/govdata]", err);
        return NextResponse.json({ error: "internal" }, { status: 500 });
    }
}
