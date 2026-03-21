"use client";
// /admin/clients — Client Management screen
// Sprint 33 | admin_console_prd.md § 4.6

import { useState, useEffect } from "react";
import styles from "../admin-layout.module.css";

interface Client {
    id: string;
    name: string;
    tier: string;
    contact_email: string | null;
    active: boolean;
    created_at: string;
}

const TIER_LABELS: Record<string, string> = {
    basic: "Basic",
    advanced: "Advanced",
    enterprise: "Enterprise",
};

function formatDate(iso: string) {
    return new Date(iso).toLocaleDateString("en-AU", { day: "2-digit", month: "short", year: "numeric" });
}

export default function AdminClientsPage() {
    const [clients, setClients] = useState<Client[]>([]);
    const [loading, setLoading] = useState(true);
    const [adding, setAdding] = useState(false);
    const [name, setName] = useState("");
    const [tier, setTier] = useState("basic");
    const [email, setEmail] = useState("");
    const [error, setError] = useState<string | null>(null);
    const [success, setSuccess] = useState<string | null>(null);

    async function fetchClients() {
        const res = await fetch("/api/admin/clients");
        if (res.ok) {
            const data = await res.json();
            setClients(data.clients);
        }
        setLoading(false);
    }

    useEffect(() => { fetchClients(); }, []);

    async function handleAdd(e: React.FormEvent) {
        e.preventDefault();
        setAdding(true);
        setError(null);
        setSuccess(null);
        try {
            const res = await fetch("/api/admin/clients", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ name, tier, contact_email: email || null }),
            });
            if (!res.ok) throw new Error("Failed to create client");
            setName(""); setTier("basic"); setEmail("");
            setSuccess(`Client "${name}" created successfully.`);
            fetchClients();
        } catch (err) {
            setError(err instanceof Error ? err.message : "Error creating client");
        } finally {
            setAdding(false);
        }
    }

    return (
        <>
            <div className={styles.screen_header}>
                <h1 className={styles.screen_title}>Client Management</h1>
                <p className={styles.screen_subtitle}>Manage GovData B2G clients, subscription tiers, and dataset access.</p>
            </div>

            {/* Add client form */}
            <form onSubmit={handleAdd} className={styles.add_form}>
                <div>
                    <label className="form-label" htmlFor="client-name">Organisation name</label>
                    <input
                        id="client-name"
                        className="form-input"
                        value={name}
                        onChange={e => setName(e.target.value)}
                        placeholder="e.g. Indian High Commission"
                        required
                    />
                </div>
                <div>
                    <label className="form-label" htmlFor="client-tier">Tier</label>
                    <select
                        id="client-tier"
                        className="form-input"
                        value={tier}
                        onChange={e => setTier(e.target.value)}
                    >
                        <option value="basic">Basic — Dashboard</option>
                        <option value="advanced">Advanced — Dashboard + Export</option>
                        <option value="enterprise">Enterprise — API + Custom</option>
                    </select>
                </div>
                <div>
                    <label className="form-label" htmlFor="client-email">Contact email</label>
                    <input
                        id="client-email"
                        className="form-input"
                        type="email"
                        value={email}
                        onChange={e => setEmail(e.target.value)}
                        placeholder="contact@example.gov"
                    />
                </div>
                <button type="submit" className="btn btn--primary" disabled={adding} style={{ whiteSpace: "nowrap" }}>
                    {adding ? "Adding…" : "+ Add client"}
                </button>
            </form>

            {success && (
                <div className="alert alert--success" style={{ marginBottom: "var(--sp-4)" }}>
                    <span>✅</span><span className="body-sm">{success}</span>
                </div>
            )}
            {error && (
                <div className="alert alert--risk" style={{ marginBottom: "var(--sp-4)" }}>
                    <span>⚠️</span><span className="body-sm">{error}</span>
                </div>
            )}

            {/* Client table */}
            <div className="card" style={{ padding: "var(--sp-5)" }}>
                <p className={styles.section_title}>Active clients ({clients.filter(c => c.active).length})</p>
                <div className={styles.table_wrap}>
                    <table className={styles.admin_table}>
                        <thead>
                            <tr>
                                <th>Organisation</th>
                                <th>Tier</th>
                                <th>Contact</th>
                                <th>Created</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            {loading ? (
                                <tr><td colSpan={5} style={{ color: "var(--color-muted)" }}>Loading…</td></tr>
                            ) : clients.length === 0 ? (
                                <tr><td colSpan={5} style={{ color: "var(--color-muted)", fontStyle: "italic" }}>No clients yet. Add your first GovData client above.</td></tr>
                            ) : clients.map(c => (
                                <tr key={c.id}>
                                    <td style={{ fontWeight: "var(--fw-semibold)", color: "var(--color-navy)" }}>{c.name}</td>
                                    <td>
                                        <span className={c.tier === "enterprise" ? styles.badge_warn : styles.badge_ok}>
                                            {TIER_LABELS[c.tier] ?? c.tier}
                                        </span>
                                    </td>
                                    <td style={{ fontSize: "var(--text-xs)", color: "var(--color-muted)" }}>{c.contact_email ?? "—"}</td>
                                    <td style={{ fontSize: "var(--text-xs)", color: "var(--color-muted)" }}>{formatDate(c.created_at)}</td>
                                    <td>
                                        <span className={c.active ? styles.badge_ok : styles.badge_risk}>
                                            {c.active ? "Active" : "Inactive"}
                                        </span>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </div>
        </>
    );
}
