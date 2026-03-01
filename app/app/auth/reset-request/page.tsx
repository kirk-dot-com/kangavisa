"use client";
// Password reset request — sends reset email via Supabase Auth
// US-E3

import { useState } from "react";
import Link from "next/link";
import { createClient } from "../../../lib/supabase";
import styles from "../auth.module.css";

export default function ResetRequestPage() {
    const [email, setEmail] = useState("");
    const [sent, setSent] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [loading, setLoading] = useState(false);

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        setError(null);
        setLoading(true);
        try {
            const supabase = createClient();
            const { error: sbErr } = await supabase.auth.resetPasswordForEmail(email, {
                redirectTo: `${window.location.origin}/auth/reset-confirm`,
            });
            if (sbErr) throw sbErr;
            setSent(true);
        } catch (err: unknown) {
            setError(err instanceof Error ? err.message : "An error occurred.");
        } finally {
            setLoading(false);
        }
    }

    return (
        <div className={styles.page}>
            <div className={styles.card}>
                <h1 className={`h2 ${styles.title}`}>Reset password</h1>

                {sent ? (
                    <div className="alert alert--success">
                        <span aria-hidden="true">✓</span>
                        <div>
                            <p className="body-sm">
                                <strong>Email sent.</strong> Check your inbox for a reset link.
                                It expires in 60 minutes.
                            </p>
                            <Link href="/auth/login" className="btn btn--ghost" style={{ marginTop: "var(--sp-4)" }}>
                                ← Back to sign in
                            </Link>
                        </div>
                    </div>
                ) : (
                    <form onSubmit={handleSubmit} className={styles.form}>
                        <p className="body-sm" style={{ color: "var(--color-slate)" }}>
                            Enter the email address associated with your account and we'll send a
                            reset link.
                        </p>

                        {error && (
                            <div className="alert alert--risk" role="alert">
                                <span aria-hidden="true">⛔</span>
                                <span className="body-sm">{error}</span>
                            </div>
                        )}

                        <div className={styles.field}>
                            <label htmlFor="reset-email" className={`caption ${styles.label}`}>
                                Email address
                            </label>
                            <input
                                id="reset-email"
                                type="email"
                                className="form-input"
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                                placeholder="you@example.com"
                                required
                                autoComplete="email"
                                disabled={loading}
                            />
                        </div>

                        <button
                            type="submit"
                            className="btn btn--primary"
                            disabled={loading || !email}
                        >
                            {loading ? "Sending…" : "Send reset link"}
                        </button>

                        <Link href="/auth/login" className={`caption ${styles.footer_link}`}>
                            ← Back to sign in
                        </Link>
                    </form>
                )}
            </div>
        </div>
    );
}
