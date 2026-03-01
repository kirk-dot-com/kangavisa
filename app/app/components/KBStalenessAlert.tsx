"use client";
/**
 * KBStalenessAlert.tsx — Warns when KB data may be outdated
 * US-B5 | architecture.md §4.2
 *
 * Checks the most recent `last_reviewed_at` date in the loaded requirements.
 * If older than STALENESS_DAYS (30), shows an amber banner above the checklist.
 * Client Component — receives staleness metadata as props from Server Component.
 */

import { useState } from "react";
import styles from "./KBStalenessAlert.module.css";

interface KBStalenessAlertProps {
    /** ISO date string of the most-recently-reviewed requirement, or null */
    lastReviewedAt: string | null;
    /** Pack version tag shown in the alert (e.g., "kb-v20260301") */
    packVersion?: string;
}

const STALENESS_DAYS = 30;

export function KBStalenessAlert({ lastReviewedAt, packVersion }: KBStalenessAlertProps) {
    const [dismissed, setDismissed] = useState(false);

    if (dismissed || !lastReviewedAt) return null;

    const reviewedDate = new Date(lastReviewedAt);
    const now = new Date();
    const daysSince = Math.floor((now.getTime() - reviewedDate.getTime()) / (1000 * 60 * 60 * 24));

    if (daysSince < STALENESS_DAYS) return null;

    const formattedDate = reviewedDate.toLocaleDateString("en-AU", {
        day: "numeric",
        month: "long",
        year: "numeric",
    });

    return (
        <div className={styles.alert} role="alert" aria-live="polite">
            <span className={styles.icon} aria-hidden="true">⚠</span>
            <div className={styles.content}>
                <p className={styles.message}>
                    <strong>KB last reviewed: {formattedDate}</strong>
                    {" "}({daysSince} days ago{packVersion ? ` · ${packVersion}` : ""}).
                    Immigration policy can change. Verify requirements against the{" "}
                    <a
                        href="https://immi.homeaffairs.gov.au"
                        target="_blank"
                        rel="noopener noreferrer"
                        className={styles.link}
                    >
                        Home Affairs website
                    </a>
                    {" "}before lodging.
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
