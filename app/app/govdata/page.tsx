// /govdata — GovData Intelligence Dashboard
// Auth-gated: requires login. Renders GovDataDashboard client island.
// Sprint 32 | govdata_dashboard_spec.md

import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { createSupabaseServerClient } from "../../lib/supabase-server";
import GovDataDashboard from "../components/govdata/GovDataDashboard";

export const metadata: Metadata = {
    title: "GovData Intelligence — KangaVisa",
    description: "Migration readiness intelligence dashboard for government and embassy stakeholders.",
};

export default async function GovDataPage() {
    // Auth gate — redirect if not logged in
    const supabase = createSupabaseServerClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) redirect("/auth/login?next=/govdata");

    return (
        <div className="section">
            <div className="container" style={{ maxWidth: 1280 }}>
                {/* Header */}
                <div style={{ marginBottom: "var(--sp-8)" }}>
                    <div style={{ display: "flex", alignItems: "baseline", gap: "var(--sp-3)", flexWrap: "wrap" }}>
                        <h1 className="h1">GovData</h1>
                        <span className="badge badge--muted caption" style={{ textTransform: "uppercase", letterSpacing: "0.07em" }}>
                            Intelligence Platform
                        </span>
                    </div>
                    <p className="body-lg" style={{ color: "var(--color-slate)", marginTop: "var(--sp-2)" }}>
                        Pre-lodgement migration readiness signals, aggregated and de-identified.
                    </p>
                </div>

                <GovDataDashboard />
            </div>
        </div>
    );
}
