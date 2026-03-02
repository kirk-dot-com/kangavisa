"use client";
/**
 * DaaSConsentBanner.tsx — DaaS research data consent prompt
 * US-C1 | FR-DaaS-1 | daas_metric_hypotheses.md
 *
 * Shown to authenticated users who haven't yet opted in or declined.
 * Calls POST /api/auth/create-consent on opt-in.
 * Decline sets a localStorage flag to suppress future display.
 * Strictly aggregate data — no personal info shared per DaaS policy.
 */

import { useState } from "react";
import styles from "./DaaSConsentBanner.module.css";

const DECLINE_KEY = "kv_daas_declined";

interface DaaSConsentBannerProps {
    /** Whether the user has already given consent (from server-side DB check) */
    hasConsent: boolean;
    /** Auth token to attach to the consent API call */
    authToken: string | null;
}

export function DaaSConsentBanner({ hasConsent, authToken }: DaaSConsentBannerProps) {
    const [dismissed, setDismissed] = useState(false);
    const [loading, setLoading] = useState(false);
    const [status, setStatus] = useState<"idle" | "opted_in" | "declined">("idle");

    // Don't show if: already consented, user declined before, or dismissed this session
    if (hasConsent || dismissed) return null;
    if (typeof window !== "undefined" && localStorage.getItem(DECLINE_KEY)) return null;

    async function handleOptIn() {
        setLoading(true);
        try {
            await fetch("/api/auth/create-consent", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    ...(authToken ? { Authorization: `Bearer ${authToken}` } : {}),
                },
                body: JSON.stringify({ govdata_research_enabled: true }),
            });
            setStatus("opted_in");
            setTimeout(() => setDismissed(true), 2500);
        } catch {
            // Soft fail — don't block the UI
            setDismissed(true);
        } finally {
            setLoading(false);
        }
    }

    function handleDecline() {
        localStorage.setItem(DECLINE_KEY, "1");
        setStatus("declined");
        setTimeout(() => setDismissed(true), 1200);
    }

    if (status === "opted_in") {
        return (
            <div className={`${styles.banner} ${styles.banner__success}`} role="status">
                <span className={styles.icon}>✓</span>
                <p className={`body-sm ${styles.message}`}>
                    Thank you for supporting Australian immigration research. Your anonymous readiness
                    data helps improve the system.
                </p>
            </div>
        );
    }

    if (status === "declined") {
        return (
            <div className={`${styles.banner} ${styles.banner__muted}`} role="status">
                <p className={`caption ${styles.message}`}>No problem — you can always opt in from your account settings.</p>
            </div>
        );
    }

    return (
        <div className={styles.banner} role="complementary" aria-label="Research data consent">
            <div className={styles.content}>
                <span className={styles.icon} aria-hidden="true">📊</span>
                <div className={styles.text}>
                    <p className={`body-sm ${styles.heading}`}>
                        <strong>Help improve Australian immigration research</strong>
                    </p>
                    <p className={`caption ${styles.description}`}>
                        Opt in to share anonymous, aggregated readiness patterns with researchers and policymakers.
                        No personal information, no individual profiling. You can opt out at any time.
                    </p>
                </div>
            </div>
            <div className={styles.actions}>
                <button
                    onClick={handleDecline}
                    className="btn btn--ghost"
                    disabled={loading}
                >
                    Decline
                </button>
                <button
                    onClick={handleOptIn}
                    className="btn btn--primary"
                    disabled={loading}
                >
                    {loading ? "Saving…" : "Opt in"}
                </button>
            </div>
        </div>
    );
}
