/**
 * AppHeaderClient.tsx — Client island for mobile hamburger toggle
 * US-A2 | Sprint 7
 *
 * AppHeader (Server Component) passes auth state down to this thin
 * client island. It manages the mobile drawer open/close state only.
 */
"use client";

import { useState } from "react";
import { MobileNav } from "./MobileNav";
import styles from "./AppHeader.module.css";

interface AppHeaderClientProps {
    isAuthenticated: boolean;
    userEmail?: string | null;
}

export function AppHeaderClient({ isAuthenticated, userEmail }: AppHeaderClientProps) {
    const [drawerOpen, setDrawerOpen] = useState(false);

    return (
        <>
            {/* Hamburger — mobile only, hidden via CSS on desktop */}
            <button
                className={styles.hamburger}
                onClick={() => setDrawerOpen(true)}
                aria-label="Open navigation menu"
                aria-expanded={drawerOpen}
                aria-controls="mobile-nav"
            >
                <span className={styles.hamburger__bar} aria-hidden="true" />
                <span className={styles.hamburger__bar} aria-hidden="true" />
                <span className={styles.hamburger__bar} aria-hidden="true" />
            </button>

            {/* Mobile nav drawer */}
            <MobileNav
                isOpen={drawerOpen}
                onClose={() => setDrawerOpen(false)}
                isAuthenticated={isAuthenticated}
                userEmail={userEmail}
            />
        </>
    );
}
