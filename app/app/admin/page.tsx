// /admin — System Overview screen
// Sprint 33 | admin_console_prd.md § 4.1

import type { Metadata } from "next";
import { createClient } from "@supabase/supabase-js";
import KpiCard from "../components/govdata/KpiCard";
import HorizontalBarChart from "../components/govdata/HorizontalBarChart";
import styles from "./admin-layout.module.css";

export const metadata: Metadata = { title: "Admin — System Overview | KangaVisa" };
export const dynamic = "force-dynamic";

function adminSupabase() {
    return createClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.SUPABASE_SERVICE_ROLE_KEY!,
        { auth: { persistSession: false } }
    );
}

export default async function AdminOverviewPage() {
    const supabase = adminSupabase();

    const { data: rows } = await supabase
        .from("visitor_intake")
        .select("passport_country,derived_signals,created_at");

    const intake = rows ?? [];
    const total = intake.length;
    const financial_risk = intake.filter(r => r.derived_signals?.financial_risk_flag).length;
    const doc_gap = intake.filter(r => r.derived_signals?.documentation_gap_flag).length;
    const strong = intake.filter(r => r.derived_signals?.strong_profile_indicator).length;

    const countryMap: Record<string, number> = {};
    intake.forEach(r => {
        if (r.passport_country) countryMap[r.passport_country] = (countryMap[r.passport_country] ?? 0) + 1;
    });
    const by_country = Object.entries(countryMap)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 8)
        .map(([name, users]) => ({ name, users }));

    const { count: client_count } = await supabase
        .from("client_accounts")
        .select("id", { count: "exact", head: true })
        .eq("active", true);

    const top_flags = [
        { flag: "Financial evidence gap",    count: financial_risk, rate: total ? Math.round(100 * financial_risk / total) : 0 },
        { flag: "Documentation not started", count: doc_gap,        rate: total ? Math.round(100 * doc_gap / total) : 0 },
        { flag: "Strong profile",            count: strong,         rate: total ? Math.round(100 * strong / total) : 0 },
    ].sort((a, b) => b.count - a.count);

    return (
        <>
            <div className={styles.screen_header}>
                <h1 className={styles.screen_title}>System Overview</h1>
                <p className={styles.screen_subtitle}>Real-time health and intelligence signals across the platform.</p>
            </div>

            <div className={styles.kpi_row}>
                <KpiCard label="Total intake users" value={total.toLocaleString()} icon="👥" />
                <KpiCard label="Financial risk rate" value={`${total ? Math.round(100 * financial_risk / total) : 0}%`} icon="💰" variant={financial_risk / total > 0.25 ? "risk" : "neutral"} />
                <KpiCard label="Doc gap rate" value={`${total ? Math.round(100 * doc_gap / total) : 0}%`} icon="📄" variant={doc_gap / total > 0.2 ? "warning" : "neutral"} />
                <KpiCard label="Active GovData clients" value={String(client_count ?? 0)} icon="🏛️" variant="success" />
            </div>

            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "var(--sp-5)" }}>
                <div className="card" style={{ padding: "var(--sp-5)" }}>
                    <p className={styles.section_title}>Top source countries</p>
                    <HorizontalBarChart data={by_country} dataKey="users" nameKey="name" color="var(--color-teal)" />
                </div>

                <div className="card" style={{ padding: "var(--sp-5)" }}>
                    <p className={styles.section_title}>Top risk flags</p>
                    <table className={styles.admin_table} style={{ marginTop: "var(--sp-2)" }}>
                        <thead>
                            <tr>
                                <th>Flag</th>
                                <th style={{ textAlign: "right" }}>Count</th>
                                <th style={{ textAlign: "right" }}>Rate</th>
                            </tr>
                        </thead>
                        <tbody>
                            {top_flags.map((f, i) => (
                                <tr key={i}>
                                    <td style={{ fontWeight: i === 0 ? "var(--fw-semibold)" : undefined }}>{f.flag}</td>
                                    <td style={{ textAlign: "right" }}>{f.count}</td>
                                    <td style={{ textAlign: "right" }}>
                                        <span className={f.rate > 25 ? styles.badge_risk : styles.badge_ok}>{f.rate}%</span>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </div>
        </>
    );
}
