// Flag Cards page
// US-C1 | FR-K3 | Brand Guidelines §9.2
// Server Component

import type { Metadata } from "next";
import Link from "next/link";
import { getFlagTemplates } from "../../../lib/kb-service";
import FlagCard from "../../components/FlagCard";
import Disclaimer from "../../components/Disclaimer";
import styles from "./flags.module.css";

interface FlagsPageProps {
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

export async function generateMetadata({ params }: FlagsPageProps): Promise<Metadata> {
    const name = VISA_NAMES[params.subclass] ?? `Subclass ${params.subclass}`;
    return {
        title: `Risk Flags — ${name} — KangaVisa`,
        description: `Risk flags for ${name} — know what to watch for and how to address it.`,
    };
}

export default async function FlagsPage({ params, searchParams }: FlagsPageProps) {
    const subclass = params.subclass;
    const caseDateStr = searchParams.caseDate ?? new Date().toISOString().split("T")[0];
    const caseDate = new Date(caseDateStr);
    const visaName = VISA_NAMES[subclass] ?? `Subclass ${subclass}`;

    let flags: import("../../../lib/kb-service").FlagTemplate[] = [];
    try {
        flags = await getFlagTemplates(subclass, caseDate);
    } catch {
        flags = [];
    }

    return (
        <div className="section">
            <div className="container container--content">

                {/* Breadcrumb + header */}
                <div className={styles.page_header}>
                    <Link href={`/checklist/${subclass}`} className={`caption ${styles.breadcrumb}`}>
                        ← Back to checklist
                    </Link>
                    <div className={styles.header_row}>
                        <div>
                            <h1 className="h2">Risk flags</h1>
                            <p className="body-sm" style={{ color: "var(--color-slate)", marginTop: "var(--sp-2)" }}>
                                {visaName} — as at <span className="mono">{caseDateStr}</span>
                            </p>
                        </div>
                        <span className={`badge ${flags.length > 0 ? "badge--warning" : "badge--success"}`}>
                            {flags.length} flag{flags.length !== 1 ? "s" : ""} active
                        </span>
                    </div>
                </div>

                {/* Intro */}
                <div className={`alert alert--info ${styles.intro}`}>
                    <span aria-hidden="true">ⓘ</span>
                    <p className="body-sm">
                        Flags are risk indicators — areas where applications commonly have gaps or
                        inconsistencies. Each flag shows what to look for, why it matters, and how to
                        address it. They are not predictions of outcome.
                    </p>
                </div>

                {/* Flag cards */}
                {flags.length > 0 ? (
                    <div className={styles.flags_grid}>
                        {flags.map((flag) => (
                            <FlagCard key={flag.flag_id} flag={flag} />
                        ))}
                    </div>
                ) : (
                    <div className={`card ${styles.empty}`}>
                        <span className={styles.empty__icon} aria-hidden="true">✓</span>
                        <h2 className="h3" style={{ color: "var(--color-navy)" }}>
                            No flags loaded for this visa group
                        </h2>
                        <p className="body-sm" style={{ color: "var(--color-slate)", marginTop: "var(--sp-2)" }}>
                            Flag templates for{" "}
                            <span className="mono">subclass {subclass}</span> have not been seeded yet,
                            or the KB service is unavailable. Run the seed loader to populate flag data.
                        </p>
                        <Link
                            href={`/checklist/${subclass}`}
                            className="btn btn--secondary"
                            style={{ marginTop: "var(--sp-5)" }}
                        >
                            ← View evidence checklist
                        </Link>
                    </div>
                )}

                {/* Next actions */}
                <div className="next-actions" style={{ marginTop: "var(--sp-8)" }}>
                    <p className="next-actions__title">Next actions</p>
                    <ul className="next-actions__list">
                        <li className="next-actions__item">Review each flag and check whether it applies to your circumstances</li>
                        <li className="next-actions__item">Work through the suggested actions for any applicable flags</li>
                        <li className="next-actions__item">Return to the{" "}
                            <Link href={`/checklist/${subclass}`} style={{ color: "var(--color-gold)" }}>
                                evidence checklist
                            </Link>{" "}
                            to mark supporting items as done
                        </li>
                    </ul>
                </div>

                {/* Mandatory disclaimer — required on flags screens */}
                <div style={{ marginTop: "var(--sp-8)" }}>
                    <Disclaimer />
                </div>
            </div>
        </div>
    );
}
