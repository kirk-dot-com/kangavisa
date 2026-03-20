"use client";
// AssessmentBadge.tsx — displays GPT-4o-mini evidence quality assessment
// Sprint 27 P2

import styles from "./AssessmentBadge.module.css";

export interface Assessment {
    rating: "Weak" | "Adequate" | "Strong";
    summary: string;
    gaps: string[];
}

interface AssessmentBadgeProps {
    assessment: Assessment;
}

const RATING_CONFIG = {
    Weak: { icon: "⚠", badgeClass: "badge--warning", labelClass: "" },
    Adequate: { icon: "◎", badgeClass: "badge--info", labelClass: "" },
    Strong: { icon: "✓", badgeClass: "badge--success", labelClass: "" },
};

export default function AssessmentBadge({ assessment }: AssessmentBadgeProps) {
    const config = RATING_CONFIG[assessment.rating] ?? RATING_CONFIG["Adequate"];

    return (
        <div className={styles.wrapper}>
            <div className={styles.header}>
                <span className={`badge ${config.badgeClass} ${styles.rating_badge}`}>
                    {config.icon} {assessment.rating}
                </span>
                <span className={`caption ${styles.summary}`}>{assessment.summary}</span>
            </div>

            {assessment.gaps.length > 0 && (
                <ul className={styles.gaps_list}>
                    {assessment.gaps.map((gap, i) => (
                        <li key={i} className={`caption ${styles.gap_item}`}>
                            → {gap}
                        </li>
                    ))}
                </ul>
            )}
        </div>
    );
}
