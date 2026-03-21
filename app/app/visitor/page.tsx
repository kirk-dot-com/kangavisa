// /visitor — entry point for Visitor visa (600) funnel
// Free access — no login required. Renders intake survey then redirects to /checklist/600.
// Sprint 31

import type { Metadata } from "next";
import VisitorIntakeSurvey from "../components/VisitorIntakeSurvey";

export const metadata: Metadata = {
    title: "Visitor Visa Checklist — KangaVisa",
    description:
        "Build a personalised evidence checklist for your Australian Visitor visa (subclass 600). Free — no account required.",
};

export default function VisitorPage() {
    return (
        <div className="section">
            <div className="container container--content">
                <div style={{ textAlign: "center", marginBottom: "var(--sp-10)" }}>
                    <h1 className="h1">Visitor visa readiness check</h1>
                    <p className="body-lg" style={{ color: "var(--color-slate)", marginTop: "var(--sp-3)", maxWidth: 560, margin: "var(--sp-3) auto 0" }}>
                        Answer a few quick questions and we&apos;ll build you a tailored evidence checklist for your Australian{" "}
                        <strong>Visitor visa (subclass 600)</strong>. Free — no account needed.
                    </p>
                </div>

                <VisitorIntakeSurvey />

                <p
                    className="caption"
                    style={{
                        textAlign: "center",
                        color: "var(--color-muted)",
                        marginTop: "var(--sp-8)",
                        borderTop: "1px solid var(--color-border)",
                        paddingTop: "var(--sp-6)",
                    }}
                >
                    KangaVisa is an information and preparation tool. It is not legal advice and does not guarantee outcomes.{" "}
                    All data is de-identified and aggregated. No personal information is stored.
                </p>
            </div>
        </div>
    );
}
