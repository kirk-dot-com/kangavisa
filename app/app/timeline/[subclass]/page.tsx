// Timeline view — effective-date vertical timeline from KB requirements
// US-B5 | Brand Guidelines §9.4
// Server Component

import type { Metadata } from "next";
import Link from "next/link";
import { getRequirements } from "../../../lib/kb-service";
import Disclaimer from "../../components/Disclaimer";
import styles from "./timeline.module.css";

interface TimelinePageProps {
    params: { subclass: string };
    searchParams: { caseDate?: string };
}

const VISA_NAMES: Record<string, string> = {
    "500": "Student visa (subclass 500)",
    "485": "Temporary Graduate (subclass 485)",
    "482": "Employer Sponsored (subclass 482 / SID)",
    "417": "Working Holiday (subclass 417)",
    "820": "Partner visa (subclass 820 / 309)",
};

const REQ_TYPE_COLOUR: Record<string, string> = {
    genuine: "var(--color-teal)",
    english: "var(--color-gold)",
    financial: "var(--color-navy)",
    occupation: "var(--color-teal)",
    work_history: "var(--color-slate)",
    health: "var(--color-slate)",
    character: "var(--color-slate)",
    other: "var(--color-muted)",
};

export async function generateMetadata({ params }: TimelinePageProps): Promise<Metadata> {
    const name = VISA_NAMES[params.subclass] ?? `Subclass ${params.subclass}`;
    return {
        title: `Requirement Timeline — ${name} — KangaVisa`,
        description: `Effective-date timeline of visa requirements for ${name}.`,
    };
}

export default async function TimelinePage({ params, searchParams }: TimelinePageProps) {
    const subclass = params.subclass;
    const caseDateStr = searchParams.caseDate ?? new Date().toISOString().split("T")[0];
    const caseDate = new Date(caseDateStr);
    const visaName = VISA_NAMES[subclass] ?? `Subclass ${subclass}`;

    let requirements = [];
    try {
        // Fetch ALL requirements (not filtered by caseDate) to show full history
        requirements = await getRequirements(subclass, new Date("2000-01-01"));
    } catch {
        requirements = [];
    }

    // Sort chronologically by effective_from
    const sorted = [...requirements].sort(
        (a, b) => new Date(a.effective_from).getTime() - new Date(b.effective_from).getTime()
    );

    // Group by year of effective_from
    const byYear = sorted.reduce<Record<string, typeof sorted>>((acc, req) => {
        const year = req.effective_from.slice(0, 4);
        if (!acc[year]) acc[year] = [];
        acc[year].push(req);
        return acc;
    }, {});

    const years = Object.keys(byYear).sort();

    function isActive(req: (typeof sorted)[0]) {
        const from = new Date(req.effective_from);
        const to = req.effective_to ? new Date(req.effective_to) : null;
        return from <= caseDate && (to === null || to >= caseDate);
    }

    function isExpired(req: (typeof sorted)[0]) {
        return req.effective_to !== null && new Date(req.effective_to) < caseDate;
    }

    return (
        <div className="section">
            <div className="container container--content">

                {/* Breadcrumb + header */}
                <div className={styles.page_header}>
                    <Link href={`/checklist/${subclass}`} className={`caption ${styles.breadcrumb}`}>
                        ← Back to checklist
                    </Link>
                    <h1 className="h2">Requirement timeline</h1>
                    <p className="body-sm" style={{ color: "var(--color-slate)", marginTop: "var(--sp-2)" }}>
                        {visaName} · Case date: <span className="mono">{caseDateStr}</span>
                    </p>
                </div>

                {/* Legend */}
                <div className={styles.legend}>
                    <span className={`caption ${styles.legend_item} ${styles.legend__active}`}>
                        ● Active (on case date)
                    </span>
                    <span className={`caption ${styles.legend_item} ${styles.legend__expired}`}>
                        ● Expired / superseded
                    </span>
                    <span className={`caption ${styles.legend_item} ${styles.legend__future}`}>
                        ● Not yet effective
                    </span>
                </div>

                {requirements.length === 0 ? (
                    <div className="card" style={{ textAlign: "center", padding: "var(--sp-10)" }}>
                        <p className="body-sm" style={{ color: "var(--color-muted)" }}>
                            No requirement history found for subclass {subclass}. Seed the KB to populate timeline data.
                        </p>
                    </div>
                ) : (
                    <div className={styles.timeline}>
                        {years.map((year) => (
                            <div key={year} className={styles.year_group}>
                                <div className={styles.year_label}>{year}</div>
                                <div className={styles.year_entries}>
                                    {byYear[year].map((req) => {
                                        const active = isActive(req);
                                        const expired = isExpired(req);
                                        const nodeClass = active
                                            ? styles.node__active
                                            : expired
                                                ? styles.node__expired
                                                : styles.node__future;
                                        const colour = REQ_TYPE_COLOUR[req.requirement_type] ?? "var(--color-muted)";

                                        return (
                                            <div key={req.requirement_id} className={`${styles.node} ${nodeClass}`}>
                                                <div className={styles.node__dot} style={{ background: colour }} />
                                                <div className={styles.node__content}>
                                                    <div className={styles.node__header}>
                                                        <span
                                                            className={`badge ${styles.type_badge}`}
                                                            style={{ borderColor: colour, color: colour }}
                                                        >
                                                            {req.requirement_type.replace(/_/g, " ")}
                                                        </span>
                                                        <span className={`caption mono ${styles.node__date}`}>
                                                            {req.effective_from}
                                                            {req.effective_to ? ` → ${req.effective_to}` : " → ongoing"}
                                                        </span>
                                                    </div>
                                                    <p className={styles.node__title}>{req.title}</p>
                                                    <p className={`caption ${styles.node__plain}`}>
                                                        {req.plain_english}
                                                    </p>
                                                    {req.legal_basis.length > 0 && (
                                                        <span className={`caption mono ${styles.node__citation}`}>
                                                            {req.legal_basis[0].citation ?? req.legal_basis[0].authority}
                                                        </span>
                                                    )}
                                                    {expired && (
                                                        <span className={`badge badge--muted ${styles.expired_badge}`}>
                                                            Superseded
                                                        </span>
                                                    )}
                                                </div>
                                            </div>
                                        );
                                    })}
                                </div>
                            </div>
                        ))}
                    </div>
                )}

                {requirements.length > 0 && (
                    <div className="next-actions" style={{ marginTop: "var(--sp-8)" }}>
                        <p className="next-actions__title">Next actions</p>
                        <ul className="next-actions__list">
                            <li className="next-actions__item">
                                <Link href={`/checklist/${subclass}?caseDate=${caseDateStr}`} style={{ color: "var(--color-gold)" }}>
                                    View evidence checklist →
                                </Link>
                            </li>
                            <li className="next-actions__item">
                                <Link href={`/flags/${subclass}?caseDate=${caseDateStr}`} style={{ color: "var(--color-gold)" }}>
                                    View risk flags →
                                </Link>
                            </li>
                        </ul>
                    </div>
                )}

                <div style={{ marginTop: "var(--sp-8)" }}>
                    <Disclaimer compact />
                </div>
            </div>
        </div>
    );
}
