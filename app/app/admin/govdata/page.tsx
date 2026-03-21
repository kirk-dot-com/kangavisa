// /admin/govdata — GovData Monitor screen
// Sprint 33 | admin_console_prd.md § 4.2

import type { Metadata } from "next";
import { createClient } from "@supabase/supabase-js";
import styles from "../admin-layout.module.css";

export const metadata: Metadata = { title: "Admin — GovData Monitor | KangaVisa" };
export const dynamic = "force-dynamic";

const MIN_COHORT = 10;

function adminSupabase() {
    return createClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.SUPABASE_SERVICE_ROLE_KEY!,
        { auth: { persistSession: false } }
    );
}

function formatDate(iso: string) {
    return new Date(iso).toLocaleString("en-AU", {
        day: "2-digit", month: "short", year: "numeric",
        hour: "2-digit", minute: "2-digit",
    });
}

export default async function AdminGovDataPage() {
    const supabase = adminSupabase();
    const { data: rows } = await supabase
        .from("visitor_intake")
        .select("passport_country,derived_signals,created_at");

    const intake = rows ?? [];

    const countryMap: Record<string, { count: number; last_seen: string }> = {};
    intake.forEach(r => {
        if (!r.passport_country) return;
        const ex = countryMap[r.passport_country];
        if (!ex) {
            countryMap[r.passport_country] = { count: 1, last_seen: r.created_at ?? "" };
        } else {
            ex.count++;
            if (r.created_at && r.created_at > ex.last_seen) ex.last_seen = r.created_at;
        }
    });

    const datasets = Object.entries(countryMap)
        .sort((a, b) => b[1].count - a[1].count)
        .map(([country, { count, last_seen }]) => ({ country, count, last_seen, cohort_ok: count >= MIN_COHORT }));

    const all_dates = intake.map(r => r.created_at ?? "").filter(Boolean).sort();
    const last_updated = all_dates.at(-1);

    const below_threshold = datasets.filter(d => !d.cohort_ok).length;

    return (
        <>
            <div className={styles.screen_header}>
                <h1 className={styles.screen_title}>GovData Monitor</h1>
                <p className={styles.screen_subtitle}>
                    Dataset volumes, cohort thresholds (n ≥ {MIN_COHORT}), and data freshness.
                    {last_updated && ` Last data: ${formatDate(last_updated)}.`}
                </p>
            </div>

            {below_threshold > 0 && (
                <div className="alert alert--warning" style={{ marginBottom: "var(--sp-5)" }}>
                    <span>⚠️</span>
                    <span className="body-sm">
                        {below_threshold} country dataset{below_threshold > 1 ? "s" : ""} below minimum cohort threshold (n &lt; {MIN_COHORT}). These will not be included in GovData exports.
                    </span>
                </div>
            )}

            <div className="card" style={{ padding: "var(--sp-5)" }}>
                <p className={styles.section_title}>Datasets by country</p>
                <div className={styles.table_wrap}>
                    <table className={styles.admin_table}>
                        <thead>
                            <tr>
                                <th>Country</th>
                                <th style={{ textAlign: "right" }}>Records</th>
                                <th style={{ textAlign: "center" }}>Cohort</th>
                                <th>Last updated</th>
                            </tr>
                        </thead>
                        <tbody>
                            {datasets.length === 0 ? (
                                <tr>
                                    <td colSpan={4} style={{ color: "var(--color-muted)", fontStyle: "italic" }}>
                                        No data yet. Apply migrations and seed data.
                                    </td>
                                </tr>
                            ) : datasets.map(d => (
                                <tr key={d.country}>
                                    <td style={{ fontWeight: "var(--fw-medium)", color: "var(--color-navy)" }}>{d.country}</td>
                                    <td style={{ textAlign: "right" }}>{d.count}</td>
                                    <td style={{ textAlign: "center" }}>
                                        {d.cohort_ok
                                            ? <span className={styles.badge_ok}>✓ OK</span>
                                            : <span className={styles.badge_warn}>⚠ Below threshold</span>
                                        }
                                    </td>
                                    <td style={{ fontSize: "var(--text-xs)", color: "var(--color-muted)" }}>
                                        {d.last_seen ? formatDate(d.last_seen) : "—"}
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
