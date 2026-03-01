/**
 * StalenessAlert.tsx — Renders staleness warnings as dismissible amber banner
 * US-F6 | FR-K5 | Brand Guidelines §10
 */

"use client";

import { useState } from "react";
import type { StalenessWarning } from "../../lib/staleness-checker";
import styles from "./StalenessAlert.module.css";

interface StalenessAlertProps {
    warnings: StalenessWarning[];
}

export default function StalenessAlert({ warnings }: StalenessAlertProps) {
    const [dismissed, setDismissed] = useState(false);

    if (warnings.length === 0 || dismissed) return null;

    const sourceList = warnings
        .map((w) => w.title ?? w.canonical_url)
        .join(", ");

    return (
        <div className={`alert alert--warning ${styles.alert}`} role="alert">
            <span className={styles.icon} aria-hidden="true">⚠️</span>
            <div className={styles.body}>
                <strong className={styles.heading}>Source data may not be current</strong>
                <p className={styles.message}>
                    {sourceList} — last retrieved{" "}
                    {Math.max(...warnings.map((w) => w.days_since_retrieved))} days ago.
                    Always verify critical requirements against the official{" "}
                    <a
                        href="https://immi.homeaffairs.gov.au"
                        target="_blank"
                        rel="noopener noreferrer"
                        className={styles.link}
                    >
                        Home Affairs website
                    </a>{" "}
                    or{" "}
                    <a
                        href="https://www.legislation.gov.au"
                        target="_blank"
                        rel="noopener noreferrer"
                        className={styles.link}
                    >
                        Federal Register of Legislation
                    </a>{" "}
                    before lodging.
                </p>
            </div>
            <button
                onClick={() => setDismissed(true)}
                className={styles.dismiss}
                aria-label="Dismiss staleness warning"
            >
                ✕
            </button>
        </div>
    );
}
