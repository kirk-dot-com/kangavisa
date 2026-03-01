/**
 * ReadinessScorecard.tsx — Evidence coverage + flag summary
 * US-B1 | Brand Guidelines §9.1
 *
 * Must NOT say "approval likelihood", "probability", or "chance of approval".
 * Shows completeness + readiness, not prediction.
 */

import styles from "./ReadinessScorecard.module.css";

interface ReadinessScorecardProps {
    totalItems: number;
    doneItems: number;
    unresolvedFlags: number;
    visaName: string;
    lastUpdated?: string | null; // ISO date of most recent source retrieved_at
}

export default function ReadinessScorecard({
    totalItems,
    doneItems,
    unresolvedFlags,
    visaName,
    lastUpdated,
}: ReadinessScorecardProps) {
    const coveragePct =
        totalItems > 0 ? Math.round((doneItems / totalItems) * 100) : 0;

    // Coverage label — no approval language
    const coverageLabel =
        coveragePct >= 80
            ? "Strong coverage"
            : coveragePct >= 50
                ? "Partial coverage"
                : "Early stage";

    const coverageBadge =
        coveragePct >= 80 ? "badge--success" : coveragePct >= 50 ? "badge--warning" : "badge--risk";

    return (
        <div className={styles.scorecard} aria-label="Readiness scorecard">
            <div className={styles.header}>
                <h2 className={`h3 ${styles.title}`}>Readiness overview</h2>
                <p className={`caption ${styles.subtitle}`}>
                    {visaName} — based on evidence coverage and open flags
                </p>
            </div>

            <div className={styles.metrics}>
                {/* Coverage */}
                <div className={styles.metric}>
                    <div className={styles.metric__value}>
                        <span className={`mono ${styles.number}`}>{coveragePct}%</span>
                    </div>
                    <div className={styles.metric__label}>Evidence coverage</div>
                    <span className={`badge ${coverageBadge}`}>{coverageLabel}</span>
                </div>

                {/* Progress bar */}
                <div className={styles.progress__wrap} role="progressbar"
                    aria-valuenow={coveragePct} aria-valuemin={0} aria-valuemax={100}
                    aria-label={`Evidence coverage ${coveragePct}%`}>
                    <div
                        className={styles.progress__bar}
                        style={{ width: `${coveragePct}%` }}
                    />
                </div>

                {/* Items count */}
                <div className={styles.metric}>
                    <div className={styles.metric__value}>
                        <span className={`mono ${styles.number}`}>
                            {doneItems}<span className={styles.number__total}>/{totalItems}</span>
                        </span>
                    </div>
                    <div className={styles.metric__label}>Items addressed</div>
                </div>

                {/* Unresolved flags */}
                <div className={styles.metric}>
                    <div className={styles.metric__value}>
                        <span className={`mono ${styles.number} ${unresolvedFlags > 0 ? styles.number__risk : styles.number__ok}`}>
                            {unresolvedFlags}
                        </span>
                    </div>
                    <div className={styles.metric__label}>Open flags</div>
                    {unresolvedFlags > 0 && (
                        <span className="badge badge--warning">Review needed</span>
                    )}
                    {unresolvedFlags === 0 && doneItems > 0 && (
                        <span className="badge badge--success">All resolved</span>
                    )}
                </div>
            </div>

            {lastUpdated && (
                <p className={`caption ${styles.updated}`}>
                    <span className="mono">Source last refreshed:</span> {lastUpdated}
                </p>
            )}

            {/* Explicit non-prediction notice — brand §9.1 */}
            <p className={`caption ${styles.notice}`}>
                Coverage reflects items you have marked as addressed. It does not indicate
                approval likelihood or predict outcomes.
            </p>
        </div>
    );
}
