"use client";
/**
 * OnboardingModal.tsx — First-visit welcome modal for new authenticated users
 * US-E1 | narrative_scaffolding_pack.md §2
 *
 * Shown once per browser (localStorage-guarded with "kv_onboarded" key).
 * 4 slides matching the product narrative arc.
 */

import { useState, useEffect } from "react";
import styles from "./OnboardingModal.module.css";

const STORAGE_KEY = "kv_onboarded";

const SLIDES = [
    {
        emoji: "🇦🇺",
        title: "The system has two speeds",
        body: "Australia combines a high-volume temporary visa system with a capped permanent program. This can create \"visa limbo\" for people transitioning onshore — understanding which speed you're in matters.",
    },
    {
        emoji: "📋",
        title: "Some decisions are documentary, some are satisfaction-based",
        body: "Many requirements are objective: documents, dates, thresholds. Others involve decision-maker satisfaction (like \"genuine student\" intent), where evidence clarity and coherent timelines make a real difference.",
    },
    {
        emoji: "🔔",
        title: "Policy changes are normal — we'll warn you",
        body: "Requirements and thresholds can shift. KangaVisa tracks official sources and shows a staleness warning when KB data may be outdated, so you always know what's verified.",
    },
    {
        emoji: "🔍",
        title: "The biggest avoidable risk is evidence quality",
        body: "The most common friction: missing documents, mismatched dates, weak explanations, and poor alignment between claims and evidence. KangaVisa's checklist and flags are designed to surface these gaps before you lodge.",
    },
];

interface OnboardingModalProps {
    /** Only show for authenticated users */
    isAuthenticated: boolean;
}

export function OnboardingModal({ isAuthenticated }: OnboardingModalProps) {
    const [visible, setVisible] = useState(false);
    const [slide, setSlide] = useState(0);

    useEffect(() => {
        if (!isAuthenticated) return;
        if (typeof window === "undefined") return;
        if (!localStorage.getItem(STORAGE_KEY)) {
            setVisible(true);
        }
    }, [isAuthenticated]);

    function handleDismiss() {
        localStorage.setItem(STORAGE_KEY, "1");
        setVisible(false);
    }

    function handleNext() {
        if (slide < SLIDES.length - 1) {
            setSlide((s) => s + 1);
        } else {
            handleDismiss();
        }
    }

    function handlePrev() {
        setSlide((s) => Math.max(0, s - 1));
    }

    if (!visible) return null;

    const current = SLIDES[slide];
    const isLast = slide === SLIDES.length - 1;

    return (
        <div className={styles.overlay} role="dialog" aria-modal="true" aria-label="Welcome to KangaVisa">
            <div className={styles.modal}>
                {/* Progress dots */}
                <div className={styles.dots} aria-label="Step indicator">
                    {SLIDES.map((_, i) => (
                        <button
                            key={i}
                            className={`${styles.dot} ${i === slide ? styles.dot__active : ""}`}
                            onClick={() => setSlide(i)}
                            aria-label={`Go to step ${i + 1}`}
                            aria-current={i === slide ? "step" : undefined}
                        />
                    ))}
                </div>

                {/* Slide content */}
                <div className={styles.slide}>
                    <span className={styles.emoji} aria-hidden="true">{current.emoji}</span>
                    <h2 className={`h3 ${styles.title}`}>{current.title}</h2>
                    <p className={`body-sm ${styles.body}`}>{current.body}</p>
                </div>

                {/* Step counter + actions */}
                <div className={styles.footer}>
                    <span className={`caption ${styles.step_count}`}>
                        {slide + 1} of {SLIDES.length}
                    </span>
                    <div className={styles.actions}>
                        {slide > 0 && (
                            <button onClick={handlePrev} className="btn btn--ghost">
                                ← Back
                            </button>
                        )}
                        <button onClick={handleNext} className="btn btn--primary">
                            {isLast ? "Get started →" : "Next →"}
                        </button>
                    </div>
                </div>

                {/* Skip */}
                <button onClick={handleDismiss} className={styles.skip} aria-label="Skip onboarding">
                    Skip
                </button>
            </div>
        </div>
    );
}
