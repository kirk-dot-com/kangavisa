"use client";
// Login page — redirects to /pathway on success
import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createClient } from "../../../lib/supabase";
import styles from "../auth.module.css";

export default function LoginPage() {
    const router = useRouter();
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        setError(null);
        setLoading(true);
        try {
            const supabase = createClient();
            const { error: signInError } = await supabase.auth.signInWithPassword({ email, password });
            if (signInError) throw signInError;
            router.push("/pathway");
        } catch (err: unknown) {
            setError(err instanceof Error ? err.message : "Sign-in failed. Check your credentials and try again.");
        } finally {
            setLoading(false);
        }
    }

    return (
        <div className={styles.page}>
            <div className={`card ${styles.card}`}>
                <div className={styles.header}>
                    <span className={styles.logo_mark} aria-hidden="true">KV</span>
                    <h1 className={`h2 ${styles.heading}`}>Sign in</h1>
                    <p className="body-sm" style={{ color: "var(--color-muted)" }}>
                        Continue building your readiness pack.
                    </p>
                </div>

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
                            autoComplete="current-password"
                            placeholder="Your password"
                        />
                    </div>

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
                        {loading ? "Signing in…" : "Sign in →"}
                    </button>
                </form>

                <p className={`caption ${styles.footer_link}`}>
                    No account yet?{" "}
                    <Link href="/auth/signup" style={{ color: "var(--color-teal)", fontWeight: 600 }}>
                        Create one free
                    </Link>
                </p>
            </div>
        </div>
    );
}
