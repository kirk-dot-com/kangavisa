/**
 * AppHeader.tsx — Auth-aware global navigation shell
 * US-A1, US-G1 | Brand Guidelines §4, §5
 *
 * Server Component — reads auth state server-side via @supabase/ssr.
 * Authenticated: shows Dashboard link + Sign out.
 * Unauthenticated: shows Sign in + Get started.
 */

import Link from "next/link";
import { getServerUser } from "../../lib/supabase-server";
import { AppHeaderClient } from "./AppHeaderClient";
import styles from "./AppHeader.module.css";

export default async function AppHeader() {
    // Read auth state from server-side cookie session
    const user = await getServerUser().catch(() => null);
    const isAuthenticated = !!user;

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
                        {isAuthenticated && (
                            <li>
                                <Link href="/dashboard" className={styles.nav__link}>
                                    Dashboard
                                </Link>
                            </li>
                        )}
                    </ul>
                </nav>

                {/* Auth CTA */}
                <div className={styles.actions}>
                    {isAuthenticated ? (
                        <>
                            <span className={styles.user_pill} title={user?.email ?? "Signed in"}>
                                <span className={styles.user_avatar} aria-hidden="true">
                                    {(user?.email?.[0] ?? "U").toUpperCase()}
                                </span>
                                <span className={styles.user_email}>
                                    {user?.email?.split("@")[0]}
                                </span>
                            </span>
                            <a
                                href="/auth/signout"
                                className="btn btn--ghost body-sm"
                                aria-label="Sign out"
                            >
                                Sign out
                            </a>
                        </>
                    ) : (
                        <>
                            <Link href="/auth/login" className="btn btn--ghost body-sm">
                                Sign in
                            </Link>
                            <Link href="/auth/signup" className="btn btn--primary body-sm">
                                Get started
                            </Link>
                        </>
                    )}

                    {/* Mobile hamburger (client island — manages drawer state) */}
                    <AppHeaderClient
                        isAuthenticated={isAuthenticated}
                        userEmail={user?.email ?? null}
                    />
                </div>
            </div>
        </header>
    );
}
