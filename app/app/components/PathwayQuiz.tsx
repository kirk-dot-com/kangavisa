// PathwayQuiz — 3-step eligibility pre-filter for Pathway Finder
// US-A1 | Sprint 8
// Client Component — uses router.push on completion
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import styles from "./PathwayQuiz.module.css";

/* ─── Types ──────────────────────────────────────────────────────────── */
type Purpose = "500" | "485" | "482" | "417" | "820" | "unsure";
type Location = "onshore" | "offshore";

interface PurposeTile {
    icon: string;
    label: string;
    sublabel: string;
    value: Purpose;
}

/* ─── Data ────────────────────────────────────────────────────────────── */
const PURPOSE_TILES: PurposeTile[] = [
    {
        icon: "📚",
        label: "Study in Australia",
        sublabel: "University, college, or CRICOS course",
        value: "500",
    },
    {
        icon: "🎓",
        label: "I recently graduated",
        sublabel: "From an Australian institution",
        value: "485",
    },
    {
        icon: "💼",
        label: "My employer is sponsoring me",
        sublabel: "Temporary Skill Shortage (482 / SID)",
        value: "482",
    },
    {
        icon: "🌏",
        label: "Working holiday or travel",
        sublabel: "Explore and work across Australia",
        value: "417",
    },
    {
        icon: "❤️",
        label: "Join my Australian partner",
        sublabel: "Citizen, permanent resident, or eligible NZ citizen",
        value: "820",
    },
    {
        icon: "🤔",
        label: "I'm not sure yet",
        sublabel: "Browse all Australian visa types below",
        value: "unsure",
    },
];

const VISA_NAMES: Record<string, string> = {
    "500": "Student visa (Subclass 500)",
    "485": "Temporary Graduate (Subclass 485)",
    "482": "Employer Sponsored (Subclass 482)",
    "417": "Working Holiday (Subclass 417)",
    "820": "Partner visa — Onshore (Subclass 820)",
    "309": "Partner visa — Offshore (Subclass 309)",
};

/* ─── Component ───────────────────────────────────────────────────────── */
export default function PathwayQuiz() {
    const router = useRouter();
    const [step, setStep] = useState<1 | 2 | 3>(1);
    const [purpose, setPurpose] = useState<Purpose | null>(null);
    const [location, setLocation] = useState<Location | null>(null);

    const today = new Date().toISOString().split("T")[0];

    function resolvedSubclass(): string {
        if (purpose === "820") return location === "offshore" ? "309" : "820";
        return purpose ?? "500";
    }

    function handlePurposeSelect(value: Purpose) {
        setPurpose(value);
        if (value === "unsure") {
            // Scroll down to the card grid — no redirect
            document
                .getElementById("browse-all")
                ?.scrollIntoView({ behavior: "smooth" });
            return;
        }
        if (value === "820") {
            setStep(2); // Ask onshore / offshore
        } else {
            setStep(3); // Go straight to confirm
        }
    }

    function handleLocationSelect(value: Location) {
        setLocation(value);
        setStep(3);
    }

    function handleStart() {
        const subclass = resolvedSubclass();
        router.push(`/checklist/${subclass}?caseDate=${today}`);
    }

    const resolved = resolvedSubclass();
    const resolvedName = VISA_NAMES[resolved] ?? "";

    return (
        <div className={styles.quiz}>
            {/* Step indicators */}
            <div className={styles.steps} aria-label="Quiz progress">
                {[1, 2, 3].map((n) => (
                    <span
                        key={n}
                        className={`${styles.step_dot} ${step >= n ? styles.step_dot__active : ""}`}
                        aria-current={step === n ? "step" : undefined}
                    />
                ))}
            </div>

            {/* ── Step 1: Purpose ─────────────────────────────────────── */}
            {step === 1 && (
                <div className={styles.step}>
                    <h2 className={`h2 ${styles.quiz__heading}`}>
                        What best describes your situation?
                    </h2>
                    <p className={`body-lg ${styles.quiz__sub}`}>
                        Select the option that fits and we&apos;ll suggest the right Australian
                        visa type.
                    </p>
                    <div className={styles.tile_grid} role="group" aria-label="Visa purpose">
                        {PURPOSE_TILES.map((tile) => (
                            <button
                                key={tile.value}
                                className={`${styles.tile} ${purpose === tile.value ? styles.tile__active : ""}`}
                                onClick={() => handlePurposeSelect(tile.value)}
                                aria-pressed={purpose === tile.value}
                            >
                                <span className={styles.tile__icon}>{tile.icon}</span>
                                <span className={styles.tile__label}>{tile.label}</span>
                                <span className={styles.tile__sub}>{tile.sublabel}</span>
                            </button>
                        ))}
                    </div>
                </div>
            )}

            {/* ── Step 2: Location (partner only) ─────────────────────── */}
            {step === 2 && (
                <div className={styles.step}>
                    <button
                        className={styles.back_btn}
                        onClick={() => { setStep(1); setLocation(null); }}
                        aria-label="Back to purpose selection"
                    >
                        ← Back
                    </button>
                    <h2 className={`h2 ${styles.quiz__heading}`}>
                        Where are you applying from?
                    </h2>
                    <p className={`body-lg ${styles.quiz__sub}`}>
                        Partner visa options differ for onshore and offshore applicants.
                    </p>
                    <div className={styles.tile_grid} role="group" aria-label="Application location">
                        <button
                            className={`${styles.tile} ${location === "onshore" ? styles.tile__active : ""}`}
                            onClick={() => handleLocationSelect("onshore")}
                            aria-pressed={location === "onshore"}
                        >
                            <span className={styles.tile__icon}>🇦🇺</span>
                            <span className={styles.tile__label}>I&apos;m in Australia</span>
                            <span className={styles.tile__sub}>Onshore — Subclass 820</span>
                        </button>
                        <button
                            className={`${styles.tile} ${location === "offshore" ? styles.tile__active : ""}`}
                            onClick={() => handleLocationSelect("offshore")}
                            aria-pressed={location === "offshore"}
                        >
                            <span className={styles.tile__icon}>✈️</span>
                            <span className={styles.tile__label}>I&apos;m outside Australia</span>
                            <span className={styles.tile__sub}>Offshore — Subclass 309</span>
                        </button>
                    </div>
                </div>
            )}

            {/* ── Step 3: Confirm ──────────────────────────────────────── */}
            {step === 3 && (
                <div className={styles.step}>
                    <button
                        className={styles.back_btn}
                        onClick={() => setStep(purpose === "820" ? 2 : 1)}
                        aria-label="Back"
                    >
                        ← Back
                    </button>
                    <h2 className={`h2 ${styles.quiz__heading}`}>
                        We&apos;ll build your checklist for:
                    </h2>
                    <div className={styles.confirm_card}>
                        <p className={styles.confirm_visa}>{resolvedName}</p>
                        <p className={`body-sm ${styles.confirm_note}`}>
                            A subclass-specific evidence checklist grounded in current
                            Australian migration law, as at{" "}
                            <span className="mono">{today}</span>.
                        </p>
                    </div>
                    <div className={styles.confirm_actions}>
                        <button
                            id="quiz-start-btn"
                            className="btn btn--primary btn--lg"
                            onClick={handleStart}
                        >
                            Start my checklist →
                        </button>
                        <button
                            className="btn btn--ghost"
                            onClick={() => { setPurpose(null); setStep(1); }}
                        >
                            Choose a different visa
                        </button>
                    </div>
                    <p className={`caption ${styles.confirm_disclaimer}`}>
                        Not legal advice · No approval guarantees · Privacy-first
                    </p>
                </div>
            )}
        </div>
    );
}
