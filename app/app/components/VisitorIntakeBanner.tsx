"use client";
// VisitorIntakeBanner.tsx — reads visitor intake from localStorage and renders
// personalised risk signal cards on the 600 checklist. Zero server touch.
// Sprint 31

import { useEffect, useState } from "react";

interface DerivedSignals {
    financial_risk_flag: boolean;
    intent_risk_proxy: boolean;
    documentation_gap_flag: boolean;
    strong_profile_indicator: boolean;
}

interface IntakeData {
    derived_signals: DerivedSignals;
    passport_country?: string;
    financial_confidence?: string;
    documentation_readiness?: string;
}

function FlagCard({ icon, title, body, variant }: { icon: string; title: string; body: string; variant: "risk" | "warning" | "success" }) {
    const color = variant === "risk" ? "var(--color-risk)" : variant === "warning" ? "var(--color-gold)" : "var(--color-teal)";
    return (
        <div
            style={{
                display: "flex",
                gap: "var(--sp-3)",
                padding: "var(--sp-4)",
                borderRadius: "var(--radius-md)",
                border: `1px solid ${color}`,
                background: `color-mix(in srgb, ${color} 6%, transparent)`,
            }}
        >
            <span style={{ fontSize: "1.25rem", lineHeight: 1.4 }} aria-hidden="true">{icon}</span>
            <div>
                <p style={{ fontWeight: "var(--fw-semibold)", color: "var(--color-navy)", fontSize: "var(--text-sm)", marginBottom: "var(--sp-1)" }}>
                    {title}
                </p>
                <p className="body-sm" style={{ color: "var(--color-slate)" }}>{body}</p>
            </div>
        </div>
    );
}

export default function VisitorIntakeBanner() {
    const [intake, setIntake] = useState<IntakeData | null>(null);

    useEffect(() => {
        try {
            const raw = localStorage.getItem("kv_visitor_intake");
            if (raw) setIntake(JSON.parse(raw));
        } catch { /* ignore */ }
    }, []);

    if (!intake?.derived_signals) return null;

    const { financial_risk_flag, intent_risk_proxy, documentation_gap_flag, strong_profile_indicator } =
        intake.derived_signals;

    const hasFlags = financial_risk_flag || intent_risk_proxy || documentation_gap_flag || strong_profile_indicator;
    if (!hasFlags) return null;

    return (
        <div
            aria-label="Personalised readiness signals"
            style={{
                display: "flex",
                flexDirection: "column",
                gap: "var(--sp-3)",
                marginBottom: "var(--sp-6)",
                padding: "var(--sp-5)",
                background: "var(--color-surface)",
                borderRadius: "var(--radius-lg)",
                border: "1px solid var(--color-border)",
            }}
        >
            <p
                className="caption"
                style={{ color: "var(--color-muted)", textTransform: "uppercase", letterSpacing: "0.07em", fontWeight: "var(--fw-semibold)", marginBottom: "var(--sp-1)" }}
            >
                Your readiness signals
            </p>
            {financial_risk_flag && (
                <FlagCard
                    icon="💰"
                    title="Financial evidence gap"
                    body="You indicated uncertainty about demonstrating funds. Gather bank statements (3–6 months) and a letter confirming available funds before lodging."
                    variant="risk"
                />
            )}
            {intent_risk_proxy && (
                <FlagCard
                    icon="🔗"
                    title="Ties to home country"
                    body="First-time travellers without stable employment are often asked to demonstrate strong ties to their home country. Prepare evidence of property, family obligations, or employment offers to return to."
                    variant="warning"
                />
            )}
            {documentation_gap_flag && (
                <FlagCard
                    icon="📄"
                    title="Documentation not started"
                    body="You haven't begun gathering documents. Work through the checklist below — each item links to the relevant requirement in migration law."
                    variant="warning"
                />
            )}
            {strong_profile_indicator && (
                <FlagCard
                    icon="✅"
                    title="Strong applicant profile"
                    body="Your financial confidence and document readiness suggest a well-prepared application. Review the remaining items below to confirm full coverage."
                    variant="success"
                />
            )}
        </div>
    );
}
