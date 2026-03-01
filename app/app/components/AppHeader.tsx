/**
 * AppHeader.tsx — Global navigation shell
 * US-A1 | Brand Guidelines §4, §5
 */

import Link from "next/link";
import styles from "./AppHeader.module.css";

export default function AppHeader() {
    return (
        <header className={styles.header} role="banner">
            <div className={`container ${styles.inner}`}>
                {/* Logo */}
                <Link href="/" className={styles.logo} aria-label="KangaVisa — Home">
                    <span className={styles.logo__mark}>KV</span>
                    <span className={styles.logo__name}>KangaVisa</span>
                </Link>

                {/* Primary Nav */}
                <nav className={styles.nav} aria-label="Primary navigation">
                    <ul className={styles.nav__list}>
                        <li>
                            <Link href="/pathway" className={styles.nav__link}>
                                Pathway Finder
                            </Link>
                        </li>
                        <li>
                            <Link href="/checklist/500" className={styles.nav__link}>
                                Checklist
                            </Link>
                        </li>
                        <li>
                            <Link href="/flags/500" className={styles.nav__link}>
                                Flags
                            </Link>
                        </li>
                    </ul>
                </nav>

                {/* Auth CTA */}
                <div className={styles.actions}>
                    <Link href="/auth/login" className="btn btn--ghost body-sm">
                        Sign in
                    </Link>
                    <Link href="/auth/signup" className="btn btn--primary body-sm">
                        Get started
                    </Link>
                </div>
            </div>
        </header>
    );
}
