// Evidence Checklist — KB-driven checklist
// US-B1, US-B2 | FR-K1, FR-K2 | Brand Guidelines §9.3
// Server Component — calls getKBPackage at render time

import type { Metadata } from "next";
import Link from "next/link";
import { getKBPackage, type Requirement, type EvidenceItem } from "../../../lib/kb-service";
import ReadinessScorecard from "../../components/ReadinessScorecard";
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

const REQ_TYPE_ORDER = ["genuine", "english", "financial", "occupation", "nomination", "sponsorship", "work_history", "health", "character", "other"];

function sortRequirements(reqs: Requirement[]): Requirement[] {
    return [...reqs].sort(
        (a, b) =>
            (REQ_TYPE_ORDER.indexOf(a.requirement_type) + 1 || 99) -
            (REQ_TYPE_ORDER.indexOf(b.requirement_type) + 1 || 99)
    );
}

function groupEvidenceByRequirement(
    items: EvidenceItem[],
    requirementId: string
): EvidenceItem[] {
    return items
        .filter((e) => e.requirement_id === requirementId)
        .sort((a, b) => a.priority - b.priority);
}

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
        // If KB service is unavailable (e.g. no env vars in dev), show fallback
        kbPackage = { requirements: [], evidenceItems: [], flagTemplates: [], caseDate: caseDateStr, warnings: ["KB service unavailable — check SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY environment variables."] };
    }

    const { requirements, evidenceItems, flagTemplates, warnings } = kbPackage;
    const sortedReqs = sortRequirements(requirements);

    return (
        <div className="section">
            <div className={`container ${styles.layout}`}>

                {/* Sidebar */}
                <aside className={styles.sidebar}>
                    <ReadinessScorecard
                        totalItems={evidenceItems.length}
                        doneItems={0} // client-side state in future Sprint 4
                        unresolvedFlags={flagTemplates.length}
                        visaName={visaName}
                    />

                    {/* Assumptions */}
                    <div className={`card ${styles.assumptions}`}>
                        <h3 className={`caption ${styles.assumptions__title}`}>Assumptions</h3>
                        <ul className={styles.assumptions__list}>
                            <li className="body-sm">
                                <strong>Visa:</strong> {visaName}
                            </li>
                            <li className="body-sm">
                                <strong>Case date:</strong>{" "}
                                <span className="mono">{caseDateStr}</span>
                            </li>
                            <li className="body-sm">
                                <strong>Structured requirements:</strong>{" "}
                                <span className="mono">{requirements.length}</span> loaded
                            </li>
                        </ul>
                        <p className="caption" style={{ color: "var(--color-muted)", marginTop: "var(--sp-3)" }}>
                            Change these in the URL or via Pathway Finder to update the checklist.
                        </p>
                    </div>

                    <Link href={`/flags/${subclass}`} className="btn btn--secondary">
                        View risk flags →
                    </Link>
                    <Link href="/pathway" className="btn btn--ghost">
                        ← Change visa
                    </Link>
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

                    {/* Warnings (KB warnings if no data) */}
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
                                Run the seed loader to populate the KB, or check that your Supabase connection is configured.
                            </p>
                            <Link href="/pathway" className="btn btn--secondary" style={{ marginTop: "var(--sp-4)" }}>
                                ← Back to Pathway Finder
                            </Link>
                        </div>
                    )}

                    {/* Requirements accordion */}
                    {sortedReqs.map((req) => {
                        const items = groupEvidenceByRequirement(evidenceItems, req.requirement_id);
                        return (
                            <details key={req.requirement_id} className={styles.req_section} open>
                                <summary className={styles.req_summary}>
                                    <span className={styles.req_type_badge}>
                                        {req.requirement_type.replace(/_/g, " ")}
                                    </span>
                                    <span className={styles.req_title}>{req.title}</span>
                                    <span className={`caption mono ${styles.req_count}`}>
                                        {items.length} items
                                    </span>
                                </summary>

                                {/* Plain English */}
                                <div className={styles.req_body}>
                                    <p className="body-sm" style={{ color: "var(--color-slate)" }}>
                                        {req.plain_english}
                                    </p>

                                    {/* Legal citation */}
                                    {req.legal_basis.length > 0 && (
                                        <div className={styles.citations}>
                                            <span className="caption" style={{ color: "var(--color-muted)", fontWeight: 600 }}>
                                                Legal basis:
                                            </span>
                                            {req.legal_basis.map((lb, i) => (
                                                <span key={i} className={`caption mono ${styles.citation}`}>
                                                    {lb.authority} · {lb.citation ?? lb.series}
                                                </span>
                                            ))}
                                        </div>
                                    )}

                                    {/* Evidence items */}
                                    {items.length > 0 ? (
                                        <ul className={styles.evidence_list}>
                                            {items.map((item) => (
                                                <li key={item.evidence_id} className={styles.evidence_item}>
                                                    <div className={styles.evidence_item__check}>
                                                        <input
                                                            type="checkbox"
                                                            id={item.evidence_id}
                                                            aria-label={`Mark "${item.label}" as done`}
                                                        />
                                                    </div>
                                                    <div className={styles.evidence_item__content}>
                                                        <label
                                                            htmlFor={item.evidence_id}
                                                            className={styles.evidence_item__label}
                                                        >
                                                            {item.label}
                                                        </label>
                                                        <p className={`caption ${styles.evidence_item__proves}`}>
                                                            <em>Proves:</em> {item.what_it_proves}
                                                        </p>
                                                        {item.common_gaps.length > 0 && (
                                                            <details className={styles.gaps}>
                                                                <summary className="caption" style={{ cursor: "pointer", color: "var(--color-warning)" }}>
                                                                    ⚠ Common gaps ({item.common_gaps.length})
                                                                </summary>
                                                                <ul className={styles.gaps__list}>
                                                                    {item.common_gaps.map((g, i) => (
                                                                        <li key={i} className="caption" style={{ color: "var(--color-slate)" }}>
                                                                            • {g}
                                                                        </li>
                                                                    ))}
                                                                </ul>
                                                            </details>
                                                        )}
                                                    </div>
                                                    <span className={`badge badge--muted ${styles.evidence_item__status}`}>
                                                        Not started
                                                    </span>
                                                </li>
                                            ))}
                                        </ul>
                                    ) : (
                                        <p className="caption" style={{ color: "var(--color-muted)", fontStyle: "italic", marginTop: "var(--sp-3)" }}>
                                            No evidence items loaded for this requirement.
                                        </p>
                                    )}
                                </div>
                            </details>
                        );
                    })}

                    {/* Next actions */}
                    {requirements.length > 0 && (
                        <div className="next-actions" style={{ marginTop: "var(--sp-8)" }}>
                            <p className="next-actions__title">Next actions</p>
                            <ul className="next-actions__list">
                                <li className="next-actions__item">Work through the checklist above and mark items as done</li>
                                <li className="next-actions__item">Review open flags at <Link href={`/flags/${subclass}`} style={{ color: "var(--color-gold)" }}>flags/{subclass}</Link></li>
                                <li className="next-actions__item">Create an account to save progress and export your readiness pack</li>
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
