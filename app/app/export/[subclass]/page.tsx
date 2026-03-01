// Export Summary page — brand §9.5
// US-D1, US-D2 — shows coverage, top flags, assumptions, pack version + download buttons
// Server Component

import type { Metadata } from "next";
import Link from "next/link";
import { getKBPackage } from "../../../lib/kb-service";
import Disclaimer from "../../components/Disclaimer";
import styles from "./export.module.css";

interface ExportPageProps {
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

const SEVERITY_CONFIG = {
    risk: { label: "Risk", cls: "badge--risk", icon: "▲" },
    warning: { label: "Flag", cls: "badge--warning", icon: "◆" },
    info: { label: "Note", cls: "badge--info", icon: "●" },
} as const;

export const metadata: Metadata = {
    title: "Export Readiness Pack — KangaVisa",
};

export default async function ExportPage({ params, searchParams }: ExportPageProps) {
    const subclass = params.subclass;
    const caseDateStr = searchParams.caseDate ?? new Date().toISOString().split("T")[0];
    const visaName = VISA_NAMES[subclass] ?? `Subclass ${subclass}`;
    const exportDate = new Date().toISOString();
    const packVersion = `kb-v${exportDate.slice(0, 10).replace(/-/g, "")}`;

    let pkg;
    try {
        pkg = await getKBPackage(subclass, new Date(caseDateStr));
    } catch {
        pkg = { requirements: [], evidenceItems: [], flagTemplates: [], caseDate: caseDateStr, warnings: [] };
    }

    const topFlags = [...pkg.flagTemplates]
        .sort((a, b) => {
            const order = { risk: 0, warning: 1, info: 2 };
            return order[a.severity] - order[b.severity];
        })
        .slice(0, 5);

    const assumptions = [
        `Visa subclass: ${subclass}`,
        `Case date: ${caseDateStr}`,
        `Requirements loaded: ${pkg.requirements.length}`,
        `Evidence items: ${pkg.evidenceItems.length}`,
        "Effective date selection: as at case date above",
    ];

    const csvUrl = `/api/export/csv?subclass=${subclass}&caseDate=${caseDateStr}`;

    return (
        <div className="section">
            <div className="container container--content">

                {/* Breadcrumb */}
                <Link href={`/checklist/${subclass}`} className={`caption ${styles.breadcrumb}`}>
                    ← Back to checklist
                </Link>

                {/* Header */}
                <div className={styles.header}>
                    <div>
                        <h1 className="h2">Readiness Pack</h1>
                        <p className="body-sm" style={{ color: "var(--color-slate)", marginTop: "var(--sp-2)" }}>
                            {visaName}
                        </p>
                    </div>
                    <div className={styles.pack_meta}>
                        <span className={`caption mono ${styles.pack_version}`}>{packVersion}</span>
                        <span className={`caption ${styles.export_date}`}>
                            Generated {new Date(exportDate).toLocaleDateString("en-AU")}
                        </span>
                    </div>
                </div>

                {/* Assumptions */}
                <div className={`card ${styles.section_card}`}>
                    <h2 className={`h3 ${styles.section_title}`}>Case assumptions</h2>
                    <ul className={styles.assumptions_list}>
                        {assumptions.map((a, i) => (
                            <li key={i} className="body-sm" style={{ color: "var(--color-slate)" }}>
                                <span style={{ color: "var(--color-muted)", marginRight: "var(--sp-2)" }}>·</span>
                                {a}
                            </li>
                        ))}
                    </ul>
                </div>

                {/* Coverage (placeholder — will be real when state persistence is loaded) */}
                <div className={`card ${styles.section_card} ${styles.coverage_card}`}>
                    <h2 className={`h3 ${styles.section_title}`}>Evidence coverage</h2>
                    <p className="body-sm" style={{ color: "var(--color-muted)" }}>
                        Sign in and mark your evidence items on the checklist page to see your
                        coverage score here and in your exported pack.
                    </p>
                    <div style={{ marginTop: "var(--sp-4)" }}>
                        <div className={styles.coverage_bar__wrap}>
                            <div className={styles.coverage_bar__fill} style={{ width: "0%" }} />
                        </div>
                        <p className={`caption mono ${styles.coverage_label}`}>0% — no items saved yet</p>
                    </div>
                </div>

                {/* Top flags */}
                {topFlags.length > 0 && (
                    <div className={`card ${styles.section_card}`}>
                        <h2 className={`h3 ${styles.section_title}`}>Top risk flags</h2>
                        <div className={styles.flags_list}>
                            {topFlags.map((flag) => {
                                const cfg = SEVERITY_CONFIG[flag.severity];
                                return (
                                    <div key={flag.flag_id} className={styles.flag_row}>
                                        <span className={`badge ${cfg.cls}`}>
                                            <span aria-hidden="true">{cfg.icon}</span> {cfg.label}
                                        </span>
                                        <div>
                                            <p className="body-sm" style={{ fontWeight: 600 }}>{flag.title}</p>
                                            <p className="caption" style={{ color: "var(--color-muted)" }}>
                                                {flag.why_it_matters}
                                            </p>
                                        </div>
                                    </div>
                                );
                            })}
                        </div>
                    </div>
                )}

                {/* Download buttons */}
                <div className={`card ${styles.section_card} ${styles.download_card}`}>
                    <h2 className={`h3 ${styles.section_title}`}>Download your pack</h2>
                    <p className="body-sm" style={{ color: "var(--color-slate)", marginBottom: "var(--sp-5)" }}>
                        Export your readiness pack to share with a registered migration agent or keep as a
                        personal record.
                    </p>
                    <div className={styles.download_buttons}>
                        <a
                            href={`/api/export/pdf?subclass=${subclass}&caseDate=${caseDateStr}`}
                            download
                            className="btn btn--primary btn--lg"
                        >
                            ↓ Download PDF
                        </a>
                        <a
                            href={csvUrl}
                            download
                            className="btn btn--secondary"
                        >
                            ↓ Download CSV
                        </a>
                    </div>
                </div>

                {/* Mandatory disclaimer */}
                <div style={{ marginTop: "var(--sp-6)" }}>
                    <Disclaimer />
                </div>
            </div>
        </div>
    );
}
