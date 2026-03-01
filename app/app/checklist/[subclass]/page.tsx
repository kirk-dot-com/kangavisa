// Evidence Checklist — KB-driven, now wired to ChecklistController for persistence
// US-B1, US-B2, US-B3, US-B4 | FR-K1, FR-K2 | Brand Guidelines §9.3
// Server Component — fetches KB data, passes to ChecklistController (Client)

import type { Metadata } from "next";
import Link from "next/link";
import { getKBPackage } from "../../../lib/kb-service";
import ChecklistController from "../../components/ChecklistController";
import AskBar from "../../components/AskBar";
import Disclaimer from "../../components/Disclaimer";
import styles from "./checklist.module.css";

interface ChecklistPageProps {
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

export async function generateMetadata({ params }: ChecklistPageProps): Promise<Metadata> {
    const name = VISA_NAMES[params.subclass] ?? `Subclass ${params.subclass}`;
    return {
        title: `${name} Checklist — KangaVisa`,
        description: `Evidence checklist for ${name} — structured, citation-grounded, effective-date aware.`,
    };
}

export default async function ChecklistPage({ params, searchParams }: ChecklistPageProps) {
    const subclass = params.subclass;
    const caseDateStr = searchParams.caseDate ?? new Date().toISOString().split("T")[0];
    const caseDate = new Date(caseDateStr);
    const visaName = VISA_NAMES[subclass] ?? `Subclass ${subclass}`;

    let kbPackage;
    try {
        kbPackage = await getKBPackage(subclass, caseDate);
    } catch {
        kbPackage = {
            requirements: [],
            evidenceItems: [],
            flagTemplates: [],
            caseDate: caseDateStr,
            warnings: ["KB service unavailable — check SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY."],
        };
    }

    const { requirements, evidenceItems, flagTemplates, warnings } = kbPackage;

    return (
        <div className="section">
            <div className={`container ${styles.layout}`}>

                {/* Sidebar — rendered by ChecklistController (Client Component) */}
                <aside className={styles.sidebar}>
                    <ChecklistController
                        subclass={subclass}
                        caseDateStr={caseDateStr}
                        visaName={visaName}
                        requirements={requirements}
                        evidenceItems={evidenceItems}
                        flagTemplates={flagTemplates}
                    />
                </aside>

                {/* Main content */}
                <main className={styles.main} id="main-content">

                    {/* Page header */}
                    <div className={styles.page_header}>
                        <Link href="/pathway" className={`caption ${styles.breadcrumb}`}>
                            ← Pathway Finder
                        </Link>
                        <h1 className="h2">{visaName}</h1>
                        <p className="body-sm" style={{ color: "var(--color-slate)", marginTop: "var(--sp-2)" }}>
                            Evidence checklist — as at <span className="mono">{caseDateStr}</span>.
                            All requirements are sourced from current Australian migration law.
                        </p>
                    </div>

                    {/* Warnings */}
                    {warnings.map((w, i) => (
                        <div key={i} className="alert alert--warning" style={{ marginBottom: "var(--sp-4)" }}>
                            <span aria-hidden="true">⚠️</span>
                            <span className="body-sm">{w}</span>
                        </div>
                    ))}

                    {/* Empty state */}
                    {requirements.length === 0 && warnings.length === 0 && (
                        <div className={`card ${styles.empty}`}>
                            <p className="body">
                                No requirements found for subclass {subclass} as at {caseDateStr}.
                                Run the seed loader to populate the KB.
                            </p>
                            <Link href="/pathway" className="btn btn--secondary" style={{ marginTop: "var(--sp-4)" }}>
                                ← Back to Pathway Finder
                            </Link>
                        </div>
                    )}

                    {/* Requirements accordion — driven by ChecklistController's ChecklistBody */}
                    {requirements.length > 0 && (
                        <ChecklistBody
                            subclass={subclass}
                            caseDateStr={caseDateStr}
                            requirements={requirements}
                            evidenceItems={evidenceItems}
                        />
                    )}

                    {/* Ask KangaVisa bar */}
                    {requirements.length > 0 && (
                        <div style={{ marginTop: "var(--sp-10)" }}>
                            <AskBar subclass={subclass} caseDate={caseDateStr} />
                        </div>
                    )}

                    {/* Next actions */}
                    {requirements.length > 0 && (
                        <div className="next-actions" style={{ marginTop: "var(--sp-8)" }}>
                            <p className="next-actions__title">Next actions</p>
                            <ul className="next-actions__list">
                                <li className="next-actions__item">Tick each evidence item as done — progress saves automatically</li>
                                <li className="next-actions__item">Review open flags at <Link href={`/flags/${subclass}`} style={{ color: "var(--color-gold)" }}>flags/{subclass}</Link></li>
                                <li className="next-actions__item"><Link href={`/export/${subclass}?caseDate=${caseDateStr}`} style={{ color: "var(--color-gold)" }}>Export your readiness pack</Link> as CSV</li>
                                <li className="next-actions__item">See the <Link href={`/timeline/${subclass}?caseDate=${caseDateStr}`} style={{ color: "var(--color-gold)" }}>requirement timeline →</Link></li>
                            </ul>
                        </div>
                    )}

                    {/* Mandatory disclaimer */}
                    <div style={{ marginTop: "var(--sp-8)" }}>
                        <Disclaimer />
                    </div>
                </main>
            </div>
        </div>
    );
}

// ---------------------------------------------------------------------------
// ChecklistBody — thin client wrapper that reads controller state
// Rendered inline in main column. State is managed by ChecklistController (sidebar).
// For simplicity, we make this a separate standalone client component below.
// ---------------------------------------------------------------------------
import { ChecklistBodyStandalone } from "../../components/ChecklistBodyStandalone";
const ChecklistBody = ChecklistBodyStandalone;
