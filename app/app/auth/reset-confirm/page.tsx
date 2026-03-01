"use client";
// Password reset confirm — handles RECOVERY token, new password form
// US-E3

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "../../../lib/supabase";
import styles from "../auth.module.css";

export default function ResetConfirmPage() {
    const router = useRouter();
    const [password, setPassword] = useState("");
    const [confirm, setConfirm] = useState("");
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [success, setSuccess] = useState(false);
    const [ready, setReady] = useState(false);

    // Supabase injects the RECOVERY token into the URL hash — listen for auth state change
    useEffect(() => {
        const supabase = createClient();
        const { data: listener } = supabase.auth.onAuthStateChange((event) => {
            if (event === "PASSWORD_RECOVERY") setReady(true);
        });
        return () => listener.subscription.unsubscribe();
    }, []);

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
            const { error: sbErr } = await supabase.auth.updateUser({ password });
            if (sbErr) throw sbErr;
            setSuccess(true);
            setTimeout(() => router.push("/dashboard"), 2000);
        } catch (err: unknown) {
            setError(err instanceof Error ? err.message : "An error occurred.");
        } finally {
            setLoading(false);
        }
    }

    if (!ready) {
        return (
            <div className={styles.page}>
                <div className={styles.card}>
                    <p className="body-sm" style={{ color: "var(--color-muted)", textAlign: "center" }}>
                        Validating reset link…
                    </p>
                </div>
            </div>
        );
    }

    return (
        <div className={styles.page}>
            <div className={styles.card}>
                <h1 className={`h2 ${styles.title}`}>Set new password</h1>

                {success ? (
                    <div className="alert alert--success">
                        <span aria-hidden="true">✓</span>
                        <p className="body-sm">
                            <strong>Password updated.</strong> Redirecting to your dashboard…
                        </p>
                    </div>
                ) : (
                    <form onSubmit={handleSubmit} className={styles.form}>
                        {error && (
                            <div className="alert alert--risk" role="alert">
                                <span aria-hidden="true">⛔</span>
                                <span className="body-sm">{error}</span>
                            </div>
                        )}

                        <div className={styles.field}>
                            <label htmlFor="new-password" className={`caption ${styles.label}`}>
                                New password
                            </label>
                            <input
                                id="new-password"
                                type="password"
                                className="form-input"
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                placeholder="At least 8 characters"
                                minLength={8}
                                required
                                disabled={loading}
                            />
                        </div>

                        <div className={styles.field}>
                            <label htmlFor="confirm-password" className={`caption ${styles.label}`}>
                                Confirm password
                            </label>
                            <input
                                id="confirm-password"
                                type="password"
                                className="form-input"
                                value={confirm}
                                onChange={(e) => setConfirm(e.target.value)}
                                placeholder="Repeat password"
                                minLength={8}
                                required
                                disabled={loading}
                            />
                        </div>

                        <button
                            type="submit"
                            className="btn btn--primary"
                            disabled={loading || !password || !confirm}
                        >
                            {loading ? "Updating…" : "Update password"}
                        </button>
                    </form>
                )}
            </div>
        </div>
    );
}
