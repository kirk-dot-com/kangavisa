"use client";
// Sign-up page — US-E1 (consent_state on sign-up) | Brand Guidelines §10
import { useState } from "react";
import Link from "next/link";
import { createClient } from "../../../lib/supabase";
import styles from "../auth.module.css";

export default function SignupPage() {
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [confirm, setConfirm] = useState("");
    const [productAnalytics, setProductAnalytics] = useState(false);
    const [govdataResearch, setGovdataResearch] = useState(false);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [success, setSuccess] = useState(false);

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        setError(null);

        if (password !== confirm) {
            setError("Passwords do not match.");
            return;
        }
        if (password.length < 8) {
            setError("Password must be at least 8 characters.");
            return;
        }

        setLoading(true);
        try {
            const supabase = createClient();
            const { data, error: signUpError } = await supabase.auth.signUp({
                email,
                password,
            });

            if (signUpError) throw signUpError;

            // Create consent_state row via API route
            if (data.user) {
                await fetch("/api/auth/create-consent", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({
                        user_id: data.user.id,
                        product_analytics_enabled: productAnalytics,
                        govdata_research_enabled: govdataResearch,
                    }),
                });
            }

            setSuccess(true);
        } catch (err: unknown) {
            setError(err instanceof Error ? err.message : "Sign-up failed. Please try again.");
        } finally {
            setLoading(false);
        }
    }

    if (success) {
        return (
            <div className={styles.page}>
                <div className={`card ${styles.card}`}>
                    <div className={styles.success_icon} aria-hidden="true">✓</div>
                    <h1 className={`h2 ${styles.heading}`}>Account created</h1>
                    <p className="body-sm" style={{ color: "var(--color-slate)", marginTop: "var(--sp-2)" }}>
                        Please check your email to verify your account, then sign in to continue.
                    </p>
                    <Link href="/auth/login" className="btn btn--primary" style={{ marginTop: "var(--sp-6)", width: "100%", justifyContent: "center" }}>
                        Go to sign in →
                    </Link>
                </div>
            </div>
        );
    }

    return (
        <div className={styles.page}>
            <div className={`card ${styles.card}`}>
                {/* Header */}
                <div className={styles.header}>
                    <span className={styles.logo_mark} aria-hidden="true">KV</span>
                    <h1 className={`h2 ${styles.heading}`}>Create your account</h1>
                    <p className="body-sm" style={{ color: "var(--color-muted)" }}>
                        Free to start — no credit card required.
                    </p>
                </div>

                {/* Form */}
                <form onSubmit={handleSubmit} className={styles.form} noValidate>
                    <div className={styles.field}>
                        <label htmlFor="email" className="form-label">Email address</label>
                        <input
                            id="email"
                            type="email"
                            className="form-input"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            required
                            autoComplete="email"
                            placeholder="you@example.com"
                        />
                    </div>

                    <div className={styles.field}>
                        <label htmlFor="password" className="form-label">Password</label>
                        <input
                            id="password"
                            type="password"
                            className="form-input"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            required
                            autoComplete="new-password"
                            placeholder="Minimum 8 characters"
                        />
                    </div>

                    <div className={styles.field}>
                        <label htmlFor="confirm" className="form-label">Confirm password</label>
                        <input
                            id="confirm"
                            type="password"
                            className="form-input"
                            value={confirm}
                            onChange={(e) => setConfirm(e.target.value)}
                            required
                            autoComplete="new-password"
                            placeholder="Repeat password"
                        />
                    </div>

                    {/* Consent toggles — Brand Guidelines §10 */}
                    <div className={styles.consent_section}>
                        <p className="caption" style={{ fontWeight: 600, color: "var(--color-slate)", marginBottom: "var(--sp-3)" }}>
                            Privacy choices — you can change these at any time in settings
                        </p>

                        <label className="toggle-label">
                            <input
                                type="checkbox"
                                checked={productAnalytics}
                                onChange={(e) => setProductAnalytics(e.target.checked)}
                            />
                            <span>
                                <strong>Product analytics (optional).</strong>{" "}
                                Help us improve KangaVisa by sharing anonymised usage data. We never share personal details.{" "}
                                <a href="/privacy" className={styles.consent_link}>
                                    Why we ask this
                                </a>
                            </span>
                        </label>

                        <label className="toggle-label" style={{ marginTop: "var(--sp-3)" }}>
                            <input
                                type="checkbox"
                                checked={govdataResearch}
                                onChange={(e) => setGovdataResearch(e.target.checked)}
                            />
                            <span>
                                <strong>GovData research (optional).</strong>{" "}
                                Contribute de-identified, aggregated data to help improve policy outcomes. Strictly no personal information, no linking back to you.{" "}
                                <a href="/privacy#govdata" className={styles.consent_link}>
                                    Why we ask this
                                </a>
                            </span>
                        </label>
                    </div>

                    {/* Error */}
                    {error && (
                        <div className="alert alert--risk" role="alert">
                            <span aria-hidden="true">⚠</span>
                            <span className="body-sm">{error}</span>
                        </div>
                    )}

                    <button
                        type="submit"
                        className="btn btn--primary"
                        disabled={loading}
                        style={{ width: "100%", justifyContent: "center" }}
                    >
                        {loading ? "Creating account…" : "Create account →"}
                    </button>
                </form>

                {/* Footer links */}
                <p className={`caption ${styles.footer_link}`}>
                    Already have an account?{" "}
                    <Link href="/auth/login" style={{ color: "var(--color-teal)", fontWeight: 600 }}>
                        Sign in
                    </Link>
                </p>

                <p className={`caption ${styles.disclaimer_text}`}>
                    By creating an account you agree to our{" "}
                    <a href="/terms" style={{ color: "var(--color-muted)", textDecoration: "underline" }}>Terms of Service</a>{" "}
                    and{" "}
                    <a href="/privacy" style={{ color: "var(--color-muted)", textDecoration: "underline" }}>Privacy Policy</a>.
                    KangaVisa is not legal advice.
                </p>
            </div>
        </div>
    );
}
