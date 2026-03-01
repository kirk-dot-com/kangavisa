// Pathway Finder — eligibility quiz + visa selector
// US-A1 | Brand Guidelines §4, §9 | Sprint 8
// Server Component (quiz is a Client Island)

import Link from "next/link";
import type { Metadata } from "next";
import PathwayQuiz from "../components/PathwayQuiz";
import styles from "./pathway.module.css";

export const metadata: Metadata = {
    title: "Pathway Finder — KangaVisa",
    description:
        "Choose your Australian visa type and build a tailored evidence checklist grounded in current migration law.",
};

const VISA_GROUPS = [
    {
        subclass: "500",
        name: "Student visa",
        complexity: "🟡" as const,
        complexityLabel: "Moderate",
        applicantType: "International students enrolled in CRICOS-registered courses",
        keyRisks: ["Genuine student intent", "English proficiency", "Financial capacity"],
        cta: "Build your checklist →",
    },
    {
        subclass: "485",
        name: "Temporary Graduate",
        complexity: "🟡" as const,
        complexityLabel: "Moderate",
        applicantType: "Recent graduates of Australian institutions",
        keyRisks: ["6-month lodgement window", "Qualification eligibility", "English requirements"],
        cta: "Build your checklist →",
    },
    {
        subclass: "482",
        name: "Employer Sponsored (482 / SID)",
        complexity: "🟡" as const,
        complexityLabel: "Moderate",
        applicantType: "Skilled workers nominated by an approved standard business sponsor",
        keyRisks: ["Nomination + TSMIT", "Occupation list eligibility", "Sponsor approval"],
        cta: "Build your checklist →",
    },
    {
        subclass: "417",
        name: "Working Holiday (417)",
        complexity: "🟢" as const,
        complexityLabel: "Lower complexity",
        applicantType: "Youth travellers on working holidays; second/third grant via specified work",
        keyRisks: ["Specified work days (88/179)", "Regional area evidence", "Financial threshold"],
        cta: "Build your checklist →",
    },
    {
        subclass: "820",
        name: "Partner visa (820 / 309)",
        complexity: "🔴" as const,
        complexityLabel: "Higher complexity",
        applicantType: "Partners of Australian citizens or permanent residents (onshore and offshore)",
        keyRisks: ["4-pillar relationship evidence", "Sponsor eligibility", "Processing backlog"],
        cta: "Build your checklist →",
    },
] as const;

const COMPLEXITY_BADGE: Record<string, string> = {
    "🟢": "badge--success",
    "🟡": "badge--warning",
    "🔴": "badge--risk",
};

interface PathwayPageProps {
    searchParams: { caseDate?: string };
}

export default function PathwayPage({ searchParams }: PathwayPageProps) {
    const caseDate = searchParams.caseDate ?? new Date().toISOString().split("T")[0];

    return (
        <div className="section">
            <div className="container container--content">

                {/* Assumptions block */}
                <div className={styles.assumptions}>
                    <p className="caption" style={{ color: "var(--color-muted)" }}>
                        <strong>Assumption:</strong> applying as at{" "}
                        <span className="mono">{caseDate}</span>.{" "}
                        Change this in the checklist if your case date differs.
                    </p>
                </div>

                {/* Header */}
                <div className={styles.header}>
                    <h1 className="h1">Pathway Finder</h1>
                    <p className="body-lg" style={{ color: "var(--color-slate)", marginTop: "var(--sp-3)" }}>
                        Select your visa type to generate a tailored evidence checklist grounded
                        in current Australian migration law.
                    </p>
                </div>

                {/* Visa card grid */}
                <div className={styles.grid}>
                    {VISA_GROUPS.map((visa) => (
                        <article
                            key={visa.subclass}
                            className={`card ${styles.visa_card}`}
                            aria-label={visa.name}
                        >
                            <div className={styles.visa_card__top}>
                                <div className={styles.visa_card__meta}>
                                    <span
                                        className={`badge ${COMPLEXITY_BADGE[visa.complexity] ?? "badge--muted"}`}
                                    >
                                        {visa.complexity} {visa.complexityLabel}
                                    </span>
                                    <span className={`caption mono ${styles.subclass}`}>
                                        Subclass {visa.subclass}
                                    </span>
                                </div>
                                <h2 className={`h3 ${styles.visa_card__name}`}>{visa.name}</h2>
                                <p className={`body-sm ${styles.visa_card__applicant}`}>
                                    {visa.applicantType}
                                </p>
                            </div>

                            <div className={styles.visa_card__risks}>
                                <p className="caption" style={{ color: "var(--color-muted)", marginBottom: "var(--sp-2)" }}>
                                    Key focus areas
                                </p>
                                <ul className={styles.risks__list}>
                                    {visa.keyRisks.map((risk, i) => (
                                        <li key={i} className={`body-sm ${styles.risk}`}>
                                            <span className={styles.risk__dot} aria-hidden="true" />
                                            {risk}
                                        </li>
                                    ))}
                                </ul>
                            </div>

                            <div className={styles.visa_card__actions}>
                                <Link
                                    href={`/checklist/${visa.subclass}?caseDate=${caseDate}`}
                                    className="btn btn--primary"
                                    aria-label={`${visa.cta} for ${visa.name}`}
                                >
                                    {visa.cta}
                                </Link>
                                <Link
                                    href={`/flags/${visa.subclass}`}
                                    className="btn btn--ghost"
                                    aria-label={`View risk flags for ${visa.name}`}
                                >
                                    View flags
                                </Link>
                            </div>
                        </article>
                    ))}
                </div>

                {/* Next actions block */}
                <div className="next-actions" style={{ marginTop: "var(--sp-10)" }}>
                    <p className="next-actions__title">Next actions</p>
                    <ul className="next-actions__list">
                        <li className="next-actions__item">Select your visa type above to open an evidence checklist</li>
                        <li className="next-actions__item">Review the key focus areas to understand the primary risk indicators</li>
                        <li className="next-actions__item">Create an account to save your progress and export your readiness pack</li>
                    </ul>
                </div>
            </div>
        </div>
    );
}
