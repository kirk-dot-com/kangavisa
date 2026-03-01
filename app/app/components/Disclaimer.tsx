/**
 * Disclaimer.tsx — Mandatory legal disclaimer (Brand Guidelines §3)
 * US-C3 | Placement: onboarding, flags screens, exports
 */

import styles from "./Disclaimer.module.css";

interface DisclaimerProps {
    compact?: boolean;
}

export default function Disclaimer({ compact = false }: DisclaimerProps) {
    return (
        <aside
            className={`${styles.disclaimer} ${compact ? styles.compact : ""}`}
            aria-label="Legal disclaimer"
        >
            <span className={styles.icon} aria-hidden="true">ⓘ</span>
            <p className={styles.text}>
                KangaVisa provides information and application preparation assistance.
                It is not legal advice and does not guarantee outcomes.
                For advice, consult a{" "}
                <a
                    href="https://www.mara.gov.au/looking-for-a-registered-migration-agent"
                    target="_blank"
                    rel="noopener noreferrer"
                    className={styles.link}
                >
                    registered migration agent (RMA)
                </a>{" "}
                or lawyer.
            </p>
        </aside>
    );
}
