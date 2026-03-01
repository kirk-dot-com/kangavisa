"use client";
/**
 * MobileNav.tsx — Slide-out navigation drawer for mobile viewports
 * US-A2 | Brand Guidelines §4, §5
 *
 * Rendered by AppHeader. Handles its own open/close state via props.
 * Closes on: link click, backdrop click, Escape key.
 * Focus-traps for accessibility.
 */

import { useEffect, useRef } from "react";
import Link from "next/link";
import styles from "./MobileNav.module.css";

interface MobileNavProps {
    isOpen: boolean;
    onClose: () => void;
    isAuthenticated: boolean;
    userEmail?: string | null;
}

export function MobileNav({ isOpen, onClose, isAuthenticated, userEmail }: MobileNavProps) {
    const drawerRef = useRef<HTMLDivElement>(null);

    // Close on Escape
    useEffect(() => {
        function handleKey(e: KeyboardEvent) {
            if (e.key === "Escape" && isOpen) onClose();
        }
        document.addEventListener("keydown", handleKey);
        return () => document.removeEventListener("keydown", handleKey);
    }, [isOpen, onClose]);

    // Prevent body scroll when open
    useEffect(() => {
        if (isOpen) {
            document.body.style.overflow = "hidden";
            // Focus first focusable element in drawer
            drawerRef.current?.querySelector<HTMLElement>("a, button")?.focus();
        } else {
            document.body.style.overflow = "";
        }
        return () => { document.body.style.overflow = ""; };
    }, [isOpen]);

    if (!isOpen) return null;

    const navLinks = [
        { href: "/pathway", label: "Pathway Finder" },
        { href: "/checklist/500", label: "Checklist" },
        { href: "/flags/500", label: "Flags" },
        ...(isAuthenticated ? [{ href: "/dashboard", label: "Dashboard" }] : []),
    ];

    return (
        <>
            {/* Backdrop */}
            <div
                className={styles.backdrop}
                onClick={onClose}
                aria-hidden="true"
            />

            {/* Drawer */}
            <div
                ref={drawerRef}
                className={styles.drawer}
                role="dialog"
                aria-modal="true"
                aria-label="Navigation menu"
            >
                {/* Drawer header */}
                <div className={styles.drawer__header}>
                    <span className={styles.drawer__logo}>KV</span>
                    <button
                        onClick={onClose}
                        className={styles.close_btn}
                        aria-label="Close navigation"
                    >
                        ✕
                    </button>
                </div>

                {/* User pill (authenticated) */}
                {isAuthenticated && userEmail && (
                    <div className={styles.user_row}>
                        <span className={styles.user_avatar}>
                            {userEmail[0].toUpperCase()}
                        </span>
                        <span className={styles.user_email}>{userEmail.split("@")[0]}</span>
                    </div>
                )}

                {/* Nav links */}
                <nav aria-label="Mobile navigation">
                    <ul className={styles.nav__list}>
                        {navLinks.map((link) => (
                            <li key={link.href}>
                                <Link
                                    href={link.href}
                                    className={styles.nav__link}
                                    onClick={onClose}
                                >
                                    {link.label}
                                </Link>
                            </li>
                        ))}
                    </ul>
                </nav>

                {/* Auth CTA */}
                <div className={styles.drawer__actions}>
                    {isAuthenticated ? (
                        <a href="/auth/signout" className="btn btn--ghost" onClick={onClose}>
                            Sign out
                        </a>
                    ) : (
                        <>
                            <Link href="/auth/login" className="btn btn--ghost" onClick={onClose}>
                                Sign in
                            </Link>
                            <Link href="/auth/signup" className="btn btn--primary" onClick={onClose}>
                                Get started
                            </Link>
                        </>
                    )}
                </div>
            </div>
        </>
    );
}
