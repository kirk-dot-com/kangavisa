"use client";
// VisitorIntakeSurvey.tsx — 3-stage progressive intake for Visitor visa (600)
// Stages: Demographics → Risk Signals → Optional Enrichment
// Sprint 31 | kb/schema/visitor_intake_schema.json v1.0

import { useState, useId } from "react";
import { useRouter } from "next/navigation";
import styles from "./VisitorIntakeSurvey.module.css";

// ─── Types ──────────────────────────────────────────────────────────────────

interface Stage1 {
    passport_country: string;
    country_of_residence: string;
    age_band: string;
    trip_duration_band: string;
    travel_history: string;
}

interface Stage2 {
    financial_confidence: string;
    employment_status: string;
    documentation_readiness: string;
}

interface Stage3 {
    accommodation_type: string;
    return_travel_booked: boolean | null;
    travel_companions: string;
}

interface DerivedSignals {
    financial_risk_flag: boolean;
    intent_risk_proxy: boolean;
    documentation_gap_flag: boolean;
    strong_profile_indicator: boolean;
}

// ─── Country list (abbreviated — top source markets + common) ───────────────

const COUNTRIES = [
    "Australia", "Bangladesh", "Brazil", "Canada", "China", "Colombia", "Egypt",
    "France", "Germany", "Ghana", "Hong Kong SAR", "India", "Indonesia", "Iran",
    "Italy", "Japan", "Kenya", "Malaysia", "Mexico", "Nepal", "New Zealand",
    "Nigeria", "Pakistan", "Philippines", "Saudi Arabia", "Singapore", "South Africa",
    "South Korea", "Spain", "Sri Lanka", "Taiwan", "Thailand", "Turkey",
    "United Arab Emirates", "United Kingdom", "United States", "Vietnam", "Zimbabwe",
    "Other",
];

// ─── Derived signal computation ──────────────────────────────────────────────

function computeSignals(s1: Stage1, s2: Stage2): DerivedSignals {
    return {
        financial_risk_flag: ["not_sure", "no"].includes(s2.financial_confidence),
        intent_risk_proxy:
            s1.travel_history === "first_time_traveller" &&
            ["between_jobs", "not_working"].includes(s2.employment_status),
        documentation_gap_flag: s2.documentation_readiness === "none",
        strong_profile_indicator:
            s2.financial_confidence === "yes" &&
            s2.documentation_readiness === "most_ready",
    };
}

// ─── Small helpers ────────────────────────────────────────────────────────────

function RadioGroup({
    id,
    label,
    options,
    value,
    onChange,
    labelMap,
}: {
    id: string;
    label: string;
    options: string[];
    value: string;
    onChange: (v: string) => void;
    labelMap?: Record<string, string>;
}) {
    return (
        <fieldset className={styles.field}>
            <legend className="form-label">{label}</legend>
            <div className={styles.radio_grid}>
                {options.map((opt) => (
                    <label key={opt} className={`${styles.radio_card} ${value === opt ? styles.radio_card_selected : ""}`}>
                        <input
                            type="radio"
                            name={id}
                            value={opt}
                            checked={value === opt}
                            onChange={() => onChange(opt)}
                            className={styles.radio_input}
                        />
                        {labelMap?.[opt] ?? opt.replace(/_/g, " ")}
                    </label>
                ))}
            </div>
        </fieldset>
    );
}

function CountrySelect({
    id,
    label,
    value,
    onChange,
}: {
    id: string;
    label: string;
    value: string;
    onChange: (v: string) => void;
}) {
    return (
        <div className={styles.field}>
            <label htmlFor={id} className="form-label">{label}</label>
            <select
                id={id}
                className="form-input"
                value={value}
                onChange={(e) => onChange(e.target.value)}
            >
                <option value="">Select a country…</option>
                {COUNTRIES.map((c) => (
                    <option key={c} value={c}>{c}</option>
                ))}
            </select>
        </div>
    );
}

// ─── Stage progress bar ───────────────────────────────────────────────────────

function ProgressBar({ stage }: { stage: 1 | 2 | 3 }) {
    return (
        <div className={styles.progress_bar} aria-label={`Step ${stage} of 3`}>
            {[1, 2, 3].map((s) => (
                <div
                    key={s}
                    className={`${styles.progress_step} ${s <= stage ? styles.progress_step_active : ""}`}
                />
            ))}
        </div>
    );
}

// ─── Main component ───────────────────────────────────────────────────────────

export default function VisitorIntakeSurvey({ redirectTo = "/checklist/600" }: { redirectTo?: string }) {
    const router = useRouter();
    const uid = useId();

    const [stage, setStage] = useState<1 | 2 | 3>(1);
    const [submitting, setSubmitting] = useState(false);

    const [s1, setS1] = useState<Stage1>({
        passport_country: "",
        country_of_residence: "",
        age_band: "",
        trip_duration_band: "",
        travel_history: "",
    });

    const [s2, setS2] = useState<Stage2>({
        financial_confidence: "",
        employment_status: "",
        documentation_readiness: "",
    });

    const [s3, setS3] = useState<Stage3>({
        accommodation_type: "",
        return_travel_booked: null,
        travel_companions: "",
    });

    const stage1Complete =
        s1.passport_country &&
        s1.country_of_residence &&
        s1.age_band &&
        s1.trip_duration_band &&
        s1.travel_history;

    const stage2Complete =
        s2.financial_confidence &&
        s2.employment_status &&
        s2.documentation_readiness;

    // ── Stage 1 submit ────────────────────────────────────────────────────────
    function handleStage1() {
        if (!stage1Complete) return;
        // Persist Stage 1 to localStorage immediately
        if (typeof window !== "undefined") {
            localStorage.setItem("kv_visitor_intake_s1", JSON.stringify(s1));
        }
        setStage(2);
    }

    // ── Stage 2 submit ────────────────────────────────────────────────────────
    function handleStage2() {
        if (!stage2Complete) return;
        setStage(3);
    }

    // ── Final submit (Stage 3 or skip) ────────────────────────────────────────
    async function handleFinish() {
        setSubmitting(true);
        const signals = computeSignals(s1, s2);

        const sessionId =
            (typeof window !== "undefined" && localStorage.getItem("kv_visitor_session_id")) ||
            crypto.randomUUID();

        if (typeof window !== "undefined") {
            localStorage.setItem("kv_visitor_session_id", sessionId);
            localStorage.setItem("kv_visitor_intake", JSON.stringify({ ...s1, ...s2, ...s3, derived_signals: signals }));
        }

        // Await the persist so the Set-Cookie header is received before we navigate.
        // The server sets kv_intake_done=1 which middleware checks to gate /checklist/600.
        try {
            await fetch("/api/intake", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    session_id: sessionId,
                    ...s1,
                    ...s2,
                    ...s3,
                    derived_signals: signals,
                }),
            });
        } catch {
            // Cookie may not be set, but allow navigation anyway
        }

        router.push(redirectTo);
    }

    return (
        <div className={styles.survey}>
            <ProgressBar stage={stage} />

            {/* ── Stage 1 ── */}
            {stage === 1 && (
                <div className={styles.stage}>
                    <div className={styles.stage_header}>
                        <span className={`caption ${styles.stage_label}`}>Step 1 of 3</span>
                        <h2 className="h2">Tell us about your trip</h2>
                        <p className="body-sm" style={{ color: "var(--color-slate)" }}>
                            Takes under 60 seconds. We use this to personalise your readiness checklist.
                        </p>
                    </div>

                    <div className={styles.fields}>
                        <CountrySelect
                            id={`${uid}-passport`}
                            label="Country of passport"
                            value={s1.passport_country}
                            onChange={(v) => setS1((p) => ({ ...p, passport_country: v }))}
                        />
                        <CountrySelect
                            id={`${uid}-residence`}
                            label="Country where you currently live"
                            value={s1.country_of_residence}
                            onChange={(v) => setS1((p) => ({ ...p, country_of_residence: v }))}
                        />
                        <RadioGroup
                            id={`${uid}-age`}
                            label="Age range"
                            options={["18-24", "25-34", "35-44", "45-54", "55+"]}
                            value={s1.age_band}
                            onChange={(v) => setS1((p) => ({ ...p, age_band: v }))}
                        />
                        <RadioGroup
                            id={`${uid}-duration`}
                            label="How long are you planning to stay?"
                            options={["<1 month", "1-3 months", "3+ months"]}
                            value={s1.trip_duration_band}
                            onChange={(v) => setS1((p) => ({ ...p, trip_duration_band: v }))}
                        />
                        <RadioGroup
                            id={`${uid}-history`}
                            label="Have you travelled internationally before?"
                            options={["first_time_traveller", "some_travel", "frequent_traveller"]}
                            value={s1.travel_history}
                            onChange={(v) => setS1((p) => ({ ...p, travel_history: v }))}
                            labelMap={{
                                first_time_traveller: "First time",
                                some_travel: "Some travel",
                                frequent_traveller: "Frequent traveller",
                            }}
                        />
                    </div>

                    <div className={styles.actions}>
                        <button
                            className="btn btn--primary"
                            onClick={handleStage1}
                            disabled={!stage1Complete}
                        >
                            Continue →
                        </button>
                    </div>
                </div>
            )}

            {/* ── Stage 2 ── */}
            {stage === 2 && (
                <div className={styles.stage}>
                    <div className={styles.stage_header}>
                        <span className={`caption ${styles.stage_label}`}>Step 2 of 3</span>
                        <h2 className="h2">How prepared are you?</h2>
                        <p className="body-sm" style={{ color: "var(--color-slate)" }}>
                            These signals help us highlight the most relevant risk flags for your situation.
                        </p>
                    </div>

                    <div className={styles.fields}>
                        <RadioGroup
                            id={`${uid}-financial`}
                            label="Do you feel confident you can show enough funds for your trip?"
                            options={["yes", "not_sure", "no"]}
                            value={s2.financial_confidence}
                            onChange={(v) => setS2((p) => ({ ...p, financial_confidence: v }))}
                            labelMap={{ yes: "Yes", not_sure: "Not sure", no: "No" }}
                        />
                        <RadioGroup
                            id={`${uid}-employment`}
                            label="What best describes your current situation?"
                            options={["employed", "self_employed", "student", "between_jobs", "not_working"]}
                            value={s2.employment_status}
                            onChange={(v) => setS2((p) => ({ ...p, employment_status: v }))}
                            labelMap={{
                                employed: "Employed",
                                self_employed: "Self-employed",
                                student: "Student",
                                between_jobs: "Between jobs",
                                not_working: "Not working",
                            }}
                        />
                        <RadioGroup
                            id={`${uid}-docs`}
                            label="How prepared are your documents?"
                            options={["none", "some", "most_ready"]}
                            value={s2.documentation_readiness}
                            onChange={(v) => setS2((p) => ({ ...p, documentation_readiness: v }))}
                            labelMap={{
                                none: "Haven't started",
                                some: "Some ready",
                                most_ready: "Most ready",
                            }}
                        />
                    </div>

                    <div className={styles.actions}>
                        <button
                            className="btn btn--primary"
                            onClick={handleStage2}
                            disabled={!stage2Complete}
                        >
                            Continue →
                        </button>
                    </div>
                </div>
            )}

            {/* ── Stage 3 (optional) ── */}
            {stage === 3 && (
                <div className={styles.stage}>
                    <div className={styles.stage_header}>
                        <span className={`caption ${styles.stage_label}`}>Step 3 of 3 · Optional</span>
                        <h2 className="h2">A few more details</h2>
                        <p className="body-sm" style={{ color: "var(--color-slate)" }}>
                            Optional — skip any time. This helps us improve our guidance.
                        </p>
                    </div>

                    <div className={styles.fields}>
                        <RadioGroup
                            id={`${uid}-accommodation`}
                            label="Where will you stay?"
                            options={["hotel", "family_or_friends", "mixed", "not_sure"]}
                            value={s3.accommodation_type}
                            onChange={(v) => setS3((p) => ({ ...p, accommodation_type: v }))}
                            labelMap={{
                                hotel: "Hotel / serviced",
                                family_or_friends: "Family or friends",
                                mixed: "Mixed",
                                not_sure: "Not sure yet",
                            }}
                        />
                        <RadioGroup
                            id={`${uid}-return`}
                            label="Have you booked return travel?"
                            options={["true", "false"]}
                            value={s3.return_travel_booked === null ? "" : String(s3.return_travel_booked)}
                            onChange={(v) => setS3((p) => ({ ...p, return_travel_booked: v === "true" }))}
                            labelMap={{ true: "Yes", false: "Not yet" }}
                        />
                        <RadioGroup
                            id={`${uid}-companions`}
                            label="Who are you travelling with?"
                            options={["solo", "partner", "family", "group"]}
                            value={s3.travel_companions}
                            onChange={(v) => setS3((p) => ({ ...p, travel_companions: v }))}
                            labelMap={{
                                solo: "Solo",
                                partner: "Partner",
                                family: "Family",
                                group: "Group",
                            }}
                        />
                    </div>

                    <div className={styles.actions}>
                        <button
                            className="btn btn--primary"
                            onClick={handleFinish}
                            disabled={submitting}
                        >
                            {submitting ? "Loading…" : "Go to my checklist →"}
                        </button>
                        <button className="btn btn--ghost" onClick={handleFinish} disabled={submitting}>
                            Skip
                        </button>
                    </div>
                </div>
            )}

            <p className="caption" style={{ color: "var(--color-muted)", textAlign: "center", marginTop: "var(--sp-4)" }}>
                All responses are de-identified. No personal information is stored or shared.
            </p>
        </div>
    );
}
