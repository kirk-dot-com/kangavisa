// Dashboard page — authenticated user's saved case sessions
// US-G1 — list of sessions + coverage + resume links
// Server Component — redirects to login if unauthenticated

import type { Metadata } from "next";
import { redirect } from "next/navigation";
import Link from "next/link";
import { getServerUser } from "../../lib/supabase-server";
import { createClient } from "@supabase/supabase-js";
import Disclaimer from "../components/Disclaimer";
import { OnboardingModal } from "../components/OnboardingModal";
import { DaaSConsentBanner } from "../components/DaaSConsentBanner";
import styles from "./dashboard.module.css";

export const metadata: Metadata = {
    title: "Dashboard — KangaVisa",
    description: "Your saved visa readiness sessions.",
};

function adminClient() {
    return createClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.SUPABASE_SERVICE_ROLE_KEY!,
        { auth: { persistSession: false } }
    );
}

const VISA_NAMES: Record<string, string> = {
    "500": "Student visa (subclass 500)",
    "485": "Temporary Graduate (subclass 485)",
    "482": "Employer Sponsored (subclass 482 / SID)",
    "417": "Working Holiday (subclass 417)",
    "820": "Partner visa (subclass 820 / 309)",
};

interface SessionRow {
    session_id: string;
    subclass_code: string;
    case_date: string;
    updated_at: string;
    item_count: number;
    done_count: number;
}

export default async function DashboardPage() {
    const user = await getServerUser();
    if (!user) redirect("/auth/login?from=/dashboard");

    const supabase = adminClient();

    // Fetch all sessions for this user
    const { data: sessions } = await supabase
        .from("case_session")
        .select("session_id, subclass_code, case_date, updated_at")
        .eq("user_id", user.id)
        .order("updated_at", { ascending: false });

    // For each session, calculate coverage
    const sessionRows: SessionRow[] = await Promise.all(
        (sessions ?? []).map(async (s) => {
            const { data: items } = await supabase
                .from("checklist_item_state")
                .select("status")
                .eq("session_id", s.session_id);
            const itemCount = items?.length ?? 0;
            const doneCount = items?.filter((i) => i.status === "done").length ?? 0;
            return { ...s, item_count: itemCount, done_count: doneCount };
        })
    );

    const coveragePct = (row: SessionRow) =>
        row.item_count > 0 ? Math.round((row.done_count / row.item_count) * 100) : 0;

    return (
        <div className="section">
            <div className="container container--content">

                {/* First-visit onboarding modal (localStorage-guarded, client-side) */}
                <OnboardingModal isAuthenticated={true} />

                {/* DaaS consent banner (shown if no prior consent) */}
                <DaaSConsentBanner hasConsent={false} authToken={null} />

                <div className={styles.header}>
                    <div>
                        <h1 className="h2">Dashboard</h1>
                        <p className="body-sm" style={{ color: "var(--color-slate)", marginTop: "var(--sp-2)" }}>
                            Your saved visa readiness sessions.
                        </p>
                    </div>
                    <Link href="/pathway" className="btn btn--primary">
                        + New session
                    </Link>
                </div>

                {sessionRows.length === 0 ? (
                    <div className={`card ${styles.empty}`}>
                        <span className={styles.empty__icon} aria-hidden="true">📋</span>
                        <h2 className="h3" style={{ color: "var(--color-navy)" }}>No sessions yet</h2>
                        <p className="body-sm" style={{ color: "var(--color-slate)", marginTop: "var(--sp-2)" }}>
                            Visit the Pathway Finder to start your first readiness session. Progress
                            saves automatically as you tick evidence items.
                        </p>
                        <Link href="/pathway" className="btn btn--secondary" style={{ marginTop: "var(--sp-5)" }}>
                            Start now →
                        </Link>
                    </div>
                ) : (
                    <div className={styles.sessions_grid}>
                        {sessionRows.map((row) => {
                            const pct = coveragePct(row);
                            const visaName = VISA_NAMES[row.subclass_code] ?? `Subclass ${row.subclass_code}`;
                            const updatedDate = new Date(row.updated_at).toLocaleDateString("en-AU");
                            return (
                                <div key={row.session_id} className={`card ${styles.session_card}`}>
                                    <div className={styles.session_card__header}>
                                        <div>
                                            <p className={`caption ${styles.session_subclass}`}>
                                                Subclass {row.subclass_code}
                                            </p>
                                            <h2 className={`h3 ${styles.session_visa}`}>{visaName}</h2>
                                        </div>
                                        <span className={`badge ${pct === 100 ? "badge--success" : "badge--info"}`}>
                                            {pct}%
                                        </span>
                                    </div>

                                    <p className="caption" style={{ color: "var(--color-muted)" }}>
                                        Case date: <span className="mono">{row.case_date}</span> · Last updated: {updatedDate}
                                    </p>

                                    {/* Coverage bar */}
                                    <div className={styles.coverage_bar__wrap}>
                                        <div
                                            className={styles.coverage_bar__fill}
                                            style={{ width: `${pct}%` }}
                                            role="progressbar"
                                            aria-valuenow={pct}
                                            aria-valuemin={0}
                                            aria-valuemax={100}
                                            aria-label={`${pct}% evidence coverage`}
                                        />
                                    </div>
                                    <p className="caption" style={{ color: "var(--color-muted)" }}>
                                        {row.done_count} of {row.item_count} items done
                                    </p>

                                    <div className={styles.session_card__actions}>
                                        <Link
                                            href={`/checklist/${row.subclass_code}?caseDate=${row.case_date}`}
                                            className="btn btn--primary"
                                        >
                                            Resume →
                                        </Link>
                                        <Link
                                            href={`/export/${row.subclass_code}?caseDate=${row.case_date}`}
                                            className="btn btn--ghost"
                                        >
                                            Export
                                        </Link>
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                )}

                <div style={{ marginTop: "var(--sp-8)" }}>
                    <Disclaimer compact />
                </div>
            </div>
        </div>
    );
}
