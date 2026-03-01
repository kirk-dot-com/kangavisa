"use client";
// AskBar.tsx — KB-grounded AI query interface with SSE streaming
// US-F1 | FR-K6 | Brand Guidelines §3 (no determinative language, disclaimer mandatory)

import { useState, useRef } from "react";
import styles from "./AskBar.module.css";
import Disclaimer from "./Disclaimer";

interface AskBarProps {
    subclass: string;
    caseDate: string;
}

export default function AskBar({ subclass, caseDate }: AskBarProps) {
    const [query, setQuery] = useState("");
    const [answer, setAnswer] = useState("");
    const [citations, setCitations] = useState<string[]>([]);
    const [refusal, setRefusal] = useState<string | null>(null);
    const [violations, setViolations] = useState<string[]>([]);
    const [loading, setLoading] = useState(false);
    const [done, setDone] = useState(false);
    const abortRef = useRef<AbortController | null>(null);

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        if (!query.trim()) return;

        // Reset state
        setAnswer("");
        setCitations([]);
        setRefusal(null);
        setViolations([]);
        setDone(false);
        setLoading(true);

        abortRef.current = new AbortController();

        try {
            const res = await fetch("/api/ask", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ query, subclass, caseDate }),
                signal: abortRef.current.signal,
            });

            if (!res.body) throw new Error("No response body");

            const reader = res.body.getReader();
            const decoder = new TextDecoder();

            while (true) {
                const { value, done: readerDone } = await reader.read();
                if (readerDone) break;

                const lines = decoder.decode(value).split("\n");
                for (const line of lines) {
                    if (!line.startsWith("data: ")) continue;
                    try {
                        const payload = JSON.parse(line.slice(6));
                        if (payload.token) setAnswer((prev) => prev + payload.token);
                        if (payload.done) {
                            if (payload.refusal) setRefusal(payload.refusal);
                            if (payload.citations) setCitations(payload.citations);
                            if (payload.violations) setViolations(payload.violations);
                            setDone(true);
                        }
                    } catch {
                        // Malformed SSE line — skip
                    }
                }
            }
        } catch (err) {
            if ((err as Error).name !== "AbortError") {
                setAnswer("An error occurred while fetching the answer. Please try again.");
                setDone(true);
            }
        } finally {
            setLoading(false);
        }
    }

    function handleStop() {
        abortRef.current?.abort();
        setLoading(false);
    }

    return (
        <section className={styles.askbar} aria-label="Ask KangaVisa">
            <div className={styles.header}>
                <h2 className={`h3 ${styles.title}`}>Ask about this visa</h2>
                <p className={`body-sm ${styles.subtitle}`}>
                    Answers are grounded in the structured requirements above and current Australian
                    migration law. Not legal advice.
                </p>
            </div>

            {/* Query form */}
            <form onSubmit={handleSubmit} className={styles.form}>
                <textarea
                    id="ask-query"
                    className={`form-input ${styles.textarea}`}
                    value={query}
                    onChange={(e) => setQuery(e.target.value)}
                    placeholder={`e.g. "What documents do I need for a ${subclass} visa and what are the common gaps?"`}
                    rows={3}
                    disabled={loading}
                    aria-label="Your question"
                />
                <div className={styles.form_actions}>
                    {loading ? (
                        <button
                            type="button"
                            onClick={handleStop}
                            className="btn btn--ghost"
                        >
                            Stop
                        </button>
                    ) : (
                        <button
                            type="submit"
                            className="btn btn--primary"
                            disabled={!query.trim()}
                        >
                            Ask →
                        </button>
                    )}
                    {loading && (
                        <span className={`caption ${styles.streaming}`} aria-live="polite">
                            Generating answer…
                        </span>
                    )}
                </div>
            </form>

            {/* Refusal banner */}
            {refusal && (
                <div className="alert alert--risk" role="alert" aria-live="assertive">
                    <span aria-hidden="true">⛔</span>
                    <div>
                        <strong className="body-sm">KangaVisa cannot help with this request</strong>
                        <p className="body-sm" style={{ marginTop: "var(--sp-1)" }}>{refusal}</p>
                    </div>
                </div>
            )}

            {/* Safety violation warnings (non-refusal) */}
            {violations.length > 0 && !refusal && (
                <div className="alert alert--warning" role="alert">
                    <span aria-hidden="true">⚠️</span>
                    <p className="body-sm">
                        Some parts of this answer were flagged by safety checks. Please verify
                        anything stated against official sources before relying on it.
                    </p>
                </div>
            )}

            {/* Streamed answer */}
            {(answer || loading) && !refusal && (
                <div className={styles.answer} aria-live="polite" aria-label="Answer">
                    <div className={styles.answer__body}>
                        {answer.split("\n").map((line, i) => (
                            <p key={i} className="body-sm" style={{ marginBottom: line ? "var(--sp-2)" : "var(--sp-4)" }}>
                                {line}
                            </p>
                        ))}
                        {loading && <span className={styles.cursor} aria-hidden="true">▌</span>}
                    </div>

                    {/* Citations */}
                    {done && citations.length > 0 && (
                        <div className={styles.citations}>
                            <p className={`caption ${styles.citations_label}`}>Sources</p>
                            <div className={styles.citations_list}>
                                {citations.map((c, i) => (
                                    <span key={i} className={`caption mono ${styles.citation_chip}`}>
                                        {c.startsWith("http") ? (
                                            <a href={c} target="_blank" rel="noopener noreferrer">{c}</a>
                                        ) : c}
                                    </span>
                                ))}
                            </div>
                        </div>
                    )}
                </div>
            )}

            {/* Disclaimer — mandatory per brand §3 */}
            <Disclaimer compact />
        </section>
    );
}
