/**
 * AppHeaderClient.tsx — Client wrapper for mobile hamburger toggle
 * US-A2 | Sprint 7
 *
 * AppHeader (Server Component) renders this as a client island.
 * Manages mobile drawer open/close state.
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
            {/* Hamburger button — visible on mobile only */}
            <button
                className={styles.hamburger}
                onClick={() => setDrawerOpen(true)}
                aria-label="Open navigation"
                aria-expanded={drawerOpen}
            >
                <span className={styles.hamburger__bar} />
                <span className={styles.hamburger__bar} />
                <span className={styles.hamburger__bar} />
            </button>

            {/* Mobile navigation drawer */}
            <MobileNav
                isOpen={drawerOpen}
                onClose={() => setDrawerOpen(false)}
                isAuthenticated={isAuthenticated}
                userEmail={userEmail}
            />
        </>
    );
}
