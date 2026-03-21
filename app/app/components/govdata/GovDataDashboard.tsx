"use client";
// GovDataDashboard.tsx — 4-screen intelligence dashboard
// Sprint 32 | govdata_dashboard_spec.md

import { useState, useEffect, useCallback } from "react";
import KpiCard from "./KpiCard";
import TrendLineChart from "./TrendLineChart";
import HorizontalBarChart from "./HorizontalBarChart";
import StackedRiskChart from "./StackedRiskChart";
import FlagsTable from "./FlagsTable";
import styles from "./GovDataDashboard.module.css";

// ─── Types ────────────────────────────────────────────────────────────────────

interface SummaryData {
    total: number;
    financial_risk_rate: number;
    doc_gap_rate: number;
    intent_risk_rate: number;
    strong_profile_rate: number;
    top_countries: { name: string; users: number }[];
    top_flags: { flag: string; frequency: number; rate: number }[];
    trend: { month: string; users: number; risk_rate: number }[];
    travel_behaviour: { label: string; count: number }[];
    trip_duration: { label: string; count: number }[];
}

interface CountryData {
    country: string;
    total: number;
    financial_risk_rate: number;
    doc_gap_rate: number;
    intent_risk_rate: number;
    top_risk: string;
    risk_breakdown: { name: string; rate: number }[];
    cohort_table: { age_band: string; users: number; risk_rate: number }[];
    trend: { month: string; users: number; risk_rate: number }[];
}

type Screen = "summary" | "country" | "risk" | "demand";

const COUNTRIES = [
    "India", "China", "Philippines", "United Kingdom", "United States",
    "Nepal", "Vietnam", "Bangladesh", "Indonesia", "South Korea",
    "Japan", "Thailand", "Malaysia", "New Zealand", "Germany",
];

const DAYS_OPTIONS = [
    { label: "7 days", value: 7 },
    { label: "30 days", value: 30 },
    { label: "90 days", value: 90 },
];

// ─── Label helpers ────────────────────────────────────────────────────────────

const TRAVEL_LABELS: Record<string, string> = {
    first_time_traveller: "First-time",
    some_travel: "Some travel",
    frequent_traveller: "Frequent traveller",
};

// ─── Main component ───────────────────────────────────────────────────────────

export default function GovDataDashboard() {
    const [screen, setScreen] = useState<Screen>("summary");
    const [days, setDays] = useState(30);
    const [country, setCountry] = useState("India");
    const [summary, setSummary] = useState<SummaryData | null>(null);
    const [countryData, setCountryData] = useState<CountryData | null>(null);
    const [loading, setLoading] = useState(false);

    const fetchSummary = useCallback(async () => {
        setLoading(true);
        try {
            const res = await fetch(`/api/govdata/summary?days=${days}`);
            if (res.ok) setSummary(await res.json());
        } finally {
            setLoading(false);
        }
    }, [days]);

    const fetchCountry = useCallback(async () => {
        setLoading(true);
        try {
            const res = await fetch(`/api/govdata/country?country=${encodeURIComponent(country)}&days=${days}`);
            if (res.ok) setCountryData(await res.json());
        } finally {
            setLoading(false);
        }
    }, [country, days]);

    useEffect(() => { fetchSummary(); }, [fetchSummary]);
    useEffect(() => { if (screen === "country") fetchCountry(); }, [screen, fetchCountry]);

    const tabs: { id: Screen; label: string }[] = [
        { id: "summary", label: "Executive Summary" },
        { id: "country", label: "Country Deep Dive" },
        { id: "risk", label: "Risk Intelligence" },
        { id: "demand", label: "Demand & Behaviour" },
    ];

    return (
        <div className={styles.dashboard}>
            {/* Global filters */}
            <div className={styles.filters}>
                <div className={styles.filter_group}>
                    <label className="form-label" htmlFor="gd-days">Time range</label>
                    <select
                        id="gd-days"
                        className="form-input"
                        value={days}
                        onChange={e => setDays(Number(e.target.value))}
                        style={{ width: "auto" }}
                    >
                        {DAYS_OPTIONS.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
                    </select>
                </div>
                {(screen === "country") && (
                    <div className={styles.filter_group}>
                        <label className="form-label" htmlFor="gd-country">Country</label>
                        <select
                            id="gd-country"
                            className="form-input"
                            value={country}
                            onChange={e => setCountry(e.target.value)}
                            style={{ width: "auto" }}
                        >
                            {COUNTRIES.map(c => <option key={c} value={c}>{c}</option>)}
                        </select>
                    </div>
                )}
                {loading && <span className="caption" style={{ color: "var(--color-muted)", alignSelf: "flex-end" }}>Loading…</span>}
            </div>

            {/* Tab nav */}
            <nav className={styles.tabs} aria-label="Dashboard screens">
                {tabs.map(t => (
                    <button
                        key={t.id}
                        className={`${styles.tab} ${screen === t.id ? styles.tab_active : ""}`}
                        onClick={() => setScreen(t.id)}
                        aria-current={screen === t.id ? "page" : undefined}
                    >
                        {t.label}
                    </button>
                ))}
            </nav>

            {/* ── Screen 1: Executive Summary ── */}
            {screen === "summary" && summary && (
                <div className={styles.screen}>
                    {/* KPI row */}
                    <div className={styles.kpi_row}>
                        <KpiCard label="Total users" value={summary.total.toLocaleString()} icon="👥" />
                        <KpiCard label="Financial risk rate" value={`${summary.financial_risk_rate}%`} icon="💰" variant={summary.financial_risk_rate > 25 ? "risk" : "neutral"} />
                        <KpiCard label="Documentation gap" value={`${summary.doc_gap_rate}%`} icon="📄" variant={summary.doc_gap_rate > 20 ? "warning" : "neutral"} />
                        <KpiCard label="Strong profiles" value={`${summary.strong_profile_rate}%`} icon="✅" variant="success" />
                    </div>

                    {/* Charts row */}
                    <div className={styles.chart_row}>
                        <div className={`card ${styles.chart_card}`}>
                            <p className={styles.chart_title}>User volume trend</p>
                            <TrendLineChart data={summary.trend} dataKey="users" color="var(--color-teal)" />
                        </div>
                        <div className={`card ${styles.chart_card}`}>
                            <p className={styles.chart_title}>Financial risk rate (%)</p>
                            <TrendLineChart data={summary.trend} dataKey="risk_rate" color="var(--color-risk)" />
                        </div>
                    </div>

                    {/* Bottom row */}
                    <div className={styles.chart_row}>
                        <div className={`card ${styles.chart_card}`}>
                            <p className={styles.chart_title}>Top source countries</p>
                            <HorizontalBarChart data={summary.top_countries} dataKey="users" nameKey="name" color="var(--color-teal)" />
                        </div>
                        <div className={`card ${styles.chart_card}`}>
                            <p className={styles.chart_title}>Top risk flags</p>
                            <FlagsTable flags={summary.top_flags} />
                        </div>
                    </div>
                </div>
            )}

            {/* ── Screen 2: Country Deep Dive ── */}
            {screen === "country" && (
                <div className={styles.screen}>
                    {countryData ? (
                        <>
                            <div className={styles.kpi_row}>
                                <KpiCard label={`${countryData.country} users`} value={countryData.total.toLocaleString()} icon="👥" />
                                <KpiCard label="Financial risk" value={`${countryData.financial_risk_rate}%`} icon="💰" variant={countryData.financial_risk_rate > 25 ? "risk" : "neutral"} />
                                <KpiCard label="Doc gap" value={`${countryData.doc_gap_rate}%`} icon="📄" variant={countryData.doc_gap_rate > 20 ? "warning" : "neutral"} />
                                <KpiCard label="Top risk" value={countryData.top_risk} icon="⚠️" variant="warning" small />
                            </div>
                            <div className={styles.chart_row}>
                                <div className={`card ${styles.chart_card}`}>
                                    <p className={styles.chart_title}>Risk breakdown</p>
                                    <StackedRiskChart data={countryData.risk_breakdown} />
                                </div>
                                <div className={`card ${styles.chart_card}`}>
                                    <p className={styles.chart_title}>Financial risk trend</p>
                                    <TrendLineChart data={countryData.trend} dataKey="risk_rate" color="var(--color-risk)" />
                                </div>
                            </div>
                            {/* Cohort table */}
                            <div className={`card ${styles.table_card}`}>
                                <p className={styles.chart_title}>Risk by age band</p>
                                <table className={styles.cohort_table}>
                                    <thead>
                                        <tr>
                                            <th>Age band</th>
                                            <th>Users</th>
                                            <th>Financial risk rate</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {countryData.cohort_table.map(r => (
                                            <tr key={r.age_band}>
                                                <td>{r.age_band}</td>
                                                <td>{r.users}</td>
                                                <td>
                                                    <span className={r.risk_rate > 30 ? styles.risk_badge : styles.neutral_badge}>
                                                        {r.risk_rate}%
                                                    </span>
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        </>
                    ) : (
                        <p className="body-sm" style={{ color: "var(--color-muted)", padding: "var(--sp-6)" }}>Select a country and wait for data to load.</p>
                    )}
                </div>
            )}

            {/* ── Screen 3: Risk Intelligence ── */}
            {screen === "risk" && summary && (
                <div className={styles.screen}>
                    <div className={styles.chart_row}>
                        <div className={`card ${styles.chart_card} ${styles.chart_card_wide}`}>
                            <p className={styles.chart_title}>Top risk flags — frequency</p>
                            <FlagsTable flags={summary.top_flags} showRate />
                        </div>
                        <div className={`card ${styles.chart_card}`}>
                            <p className={styles.chart_title}>Financial risk rate over time</p>
                            <TrendLineChart data={summary.trend} dataKey="risk_rate" color="var(--color-risk)" />
                        </div>
                    </div>
                    <div className={`card ${styles.chart_card_full}`}>
                        <p className={styles.chart_title}>Risk by source country</p>
                        <HorizontalBarChart
                            data={summary.top_countries.map(c => ({ name: c.name, users: c.users }))}
                            dataKey="users"
                            nameKey="name"
                            color="var(--color-gold)"
                        />
                    </div>
                </div>
            )}

            {/* ── Screen 4: Demand & Behaviour ── */}
            {screen === "demand" && summary && (
                <div className={styles.screen}>
                    <div className={styles.chart_row}>
                        <div className={`card ${styles.chart_card}`}>
                            <p className={styles.chart_title}>Visitor volume trend</p>
                            <TrendLineChart data={summary.trend} dataKey="users" color="var(--color-teal)" />
                        </div>
                        <div className={`card ${styles.chart_card}`}>
                            <p className={styles.chart_title}>Travel history breakdown</p>
                            <HorizontalBarChart
                                data={summary.travel_behaviour.map(b => ({
                                    name: TRAVEL_LABELS[b.label] ?? b.label,
                                    users: b.count,
                                }))}
                                dataKey="users"
                                nameKey="name"
                                color="var(--color-teal)"
                            />
                        </div>
                    </div>
                    <div className={`card ${styles.chart_card_full}`}>
                        <p className={styles.chart_title}>Planned trip duration</p>
                        <HorizontalBarChart
                            data={summary.trip_duration.map(d => ({ name: d.label, users: d.count }))}
                            dataKey="users"
                            nameKey="name"
                            color="var(--color-navy)"
                        />
                    </div>
                </div>
            )}

            {!summary && !loading && (
                <div className={styles.empty}>
                    <p className="body-sm" style={{ color: "var(--color-muted)" }}>No data available for this period. Apply the Supabase migrations and seed data first.</p>
                </div>
            )}

            <p className="caption" style={{ color: "var(--color-muted)", marginTop: "var(--sp-6)", borderTop: "1px solid var(--color-border)", paddingTop: "var(--sp-4)" }}>
                All data is de-identified and aggregated. Minimum cohort threshold n ≥ 5. No individual-level data is shown.
            </p>
        </div>
    );
}
