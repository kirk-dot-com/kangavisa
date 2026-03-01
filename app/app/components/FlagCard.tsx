/**
 * FlagCard.tsx — Risk flag display card
 * US-C1 | Brand Guidelines §9.2 (required structure)
 * 
 * Required structure per brand: trigger · why it matters · actions · evidence examples · status
 * Severity colour-coding always paired with icon + label (WCAG — not colour alone).
 */

import type { FlagTemplate } from "../../lib/kb-service";
import styles from "./FlagCard.module.css";

interface FlagCardProps {
    flag: FlagTemplate;
}

const SEVERITY_CONFIG = {
    risk: { label: "Risk flag", icon: "▲", badgeClass: "badge--risk" },
    warning: { label: "Flag", icon: "◆", badgeClass: "badge--warning" },
    info: { label: "Note", icon: "●", badgeClass: "badge--info" },
} as const;

export default function FlagCard({ flag }: FlagCardProps) {
    const severity = SEVERITY_CONFIG[flag.severity] ?? SEVERITY_CONFIG.info;

    return (
        <article className={styles.card} aria-label={`Flag: ${flag.title}`}>
            {/* Severity badge — always icon + text (WCAG) */}
            <header className={styles.header}>
                <span className={`badge ${severity.badgeClass} ${styles.badge}`}>
                    <span aria-hidden="true">{severity.icon}</span>
                    {severity.label}
                </span>
                <h3 className={`h3 ${styles.title}`}>{flag.title}</h3>
            </header>

            {/* Why it matters */}
            <section className={styles.section} aria-label="Why this matters">
                <p className={`body-sm ${styles.why}`}>{flag.why_it_matters}</p>
            </section>

            {/* Actions */}
            {flag.actions.length > 0 && (
                <section className={styles.section} aria-label="Recommended actions">
                    <h4 className={styles.section__title}>What to do</h4>
                    <ol className={styles.actions}>
                        {flag.actions.map((action, i) => (
                            <li key={i} className={styles.action}>
                                <span className={styles.action__num} aria-hidden="true">
                                    {i + 1}
                                </span>
                                <span className="body-sm">{action}</span>
                            </li>
                        ))}
                    </ol>
                </section>
            )}

            {/* Evidence examples */}
            {flag.evidence_examples.length > 0 && (
                <section className={styles.section} aria-label="Evidence examples">
                    <h4 className={styles.section__title}>Evidence examples</h4>
                    <ul className={styles.evidence}>
                        {flag.evidence_examples.map((ex, i) => (
                            <li key={i} className={`body-sm ${styles.evidence__item}`}>
                                <span className={styles.evidence__icon} aria-hidden="true">📄</span>
                                {ex}
                            </li>
                        ))}
                    </ul>
                </section>
            )}

            {/* Effective date caption */}
            <footer className={styles.footer}>
                <span className={`caption mono ${styles.date}`}>
                    Effective from: {flag.effective_from}
                </span>
                <span className={`badge badge--muted ${styles.status}`}>Unresolved</span>
            </footer>
        </article>
    );
}
