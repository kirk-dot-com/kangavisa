"use client";
// /admin/users — User Management screen
// View all auth users, change roles. Sprint 33.

import { useState, useEffect, useCallback } from "react";
import styles from "../admin-layout.module.css";

interface User {
    id: string;
    email: string;
    role: string;
    created_at: string;
    last_sign_in: string | null;
}

const ROLES = [
    { value: "user",           label: "User — no admin access" },
    { value: "analyst",        label: "Analyst — read analytics" },
    { value: "product_admin",  label: "Product Admin — manage visas/flags" },
    { value: "super_admin",    label: "Super Admin — full access" },
    { value: "govdata_client", label: "GovData Client — read-only dashboard" },
];

const ROLE_VARIANT: Record<string, string> = {
    super_admin:    "badge_risk",   // stands out
    product_admin:  "badge_warn",
    analyst:        "badge_ok",
    govdata_client: "badge_ok",
    user:           "neutral_badge",
};

function formatDate(iso: string | null) {
    if (!iso) return "Never";
    return new Date(iso).toLocaleDateString("en-AU", { day: "2-digit", month: "short", year: "numeric" });
}

export default function AdminUsersPage() {
    const [users, setUsers] = useState<User[]>([]);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState<string | null>(null); // user_id being saved
    const [pendingRoles, setPendingRoles] = useState<Record<string, string>>({});
    const [message, setMessage] = useState<{ type: "ok" | "err"; text: string } | null>(null);

    const fetchUsers = useCallback(async () => {
        setLoading(true);
        const res = await fetch("/api/admin/users");
        if (res.ok) {
            const data = await res.json();
            setUsers(data.users);
            // Initialise pending roles from current roles
            const roles: Record<string, string> = {};
            data.users.forEach((u: User) => { roles[u.id] = u.role; });
            setPendingRoles(roles);
        }
        setLoading(false);
    }, []);

    useEffect(() => { fetchUsers(); }, [fetchUsers]);

    async function saveRole(user_id: string) {
        setSaving(user_id);
        setMessage(null);
        try {
            const res = await fetch("/api/admin/users", {
                method: "PATCH",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ user_id, role: pendingRoles[user_id] }),
            });
            if (!res.ok) throw new Error("Failed to update role");
            setMessage({ type: "ok", text: "Role updated successfully." });
            fetchUsers();
        } catch {
            setMessage({ type: "err", text: "Failed to update role. Try again." });
        } finally {
            setSaving(null);
        }
    }

    return (
        <>
            <div className={styles.screen_header}>
                <h1 className={styles.screen_title}>User Management</h1>
                <p className={styles.screen_subtitle}>
                    View all registered users and assign roles. Changes take effect immediately.
                </p>
            </div>

            {message && (
                <div
                    className={`alert ${message.type === "ok" ? "alert--success" : "alert--risk"}`}
                    style={{ marginBottom: "var(--sp-4)" }}
                >
                    <span>{message.type === "ok" ? "✅" : "⚠️"}</span>
                    <span className="body-sm">{message.text}</span>
                </div>
            )}

            <div className="card" style={{ padding: "var(--sp-5)" }}>
                <p className={styles.section_title}>All users ({users.length})</p>
                <div className={styles.table_wrap}>
                    <table className={styles.admin_table}>
                        <thead>
                            <tr>
                                <th>Email</th>
                                <th>Current role</th>
                                <th>Joined</th>
                                <th>Last sign-in</th>
                                <th>Change role</th>
                                <th></th>
                            </tr>
                        </thead>
                        <tbody>
                            {loading ? (
                                <tr><td colSpan={6} style={{ color: "var(--color-muted)" }}>Loading…</td></tr>
                            ) : users.length === 0 ? (
                                <tr><td colSpan={6} style={{ color: "var(--color-muted)", fontStyle: "italic" }}>No users found.</td></tr>
                            ) : users.map(u => (
                                <tr key={u.id}>
                                    <td style={{ color: "var(--color-navy)", fontWeight: "var(--fw-medium)" }}>
                                        {u.email}
                                    </td>
                                    <td>
                                        <span className={styles[ROLE_VARIANT[u.role] ?? "neutral_badge"] as string}>
                                            {u.role.replace(/_/g, " ")}
                                        </span>
                                    </td>
                                    <td style={{ fontSize: "var(--text-xs)", color: "var(--color-muted)" }}>
                                        {formatDate(u.created_at)}
                                    </td>
                                    <td style={{ fontSize: "var(--text-xs)", color: "var(--color-muted)" }}>
                                        {formatDate(u.last_sign_in)}
                                    </td>
                                    <td style={{ minWidth: 200 }}>
                                        <select
                                            className="form-input"
                                            value={pendingRoles[u.id] ?? u.role}
                                            onChange={e => setPendingRoles(prev => ({ ...prev, [u.id]: e.target.value }))}
                                            style={{ fontSize: "var(--text-xs)", padding: "var(--sp-1) var(--sp-2)" }}
                                        >
                                            {ROLES.map(r => (
                                                <option key={r.value} value={r.value}>{r.label}</option>
                                            ))}
                                        </select>
                                    </td>
                                    <td>
                                        <button
                                            className="btn btn--primary"
                                            style={{ fontSize: "var(--text-xs)", padding: "var(--sp-1) var(--sp-3)" }}
                                            disabled={saving === u.id || pendingRoles[u.id] === u.role}
                                            onClick={() => saveRole(u.id)}
                                        >
                                            {saving === u.id ? "Saving…" : "Save"}
                                        </button>
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
