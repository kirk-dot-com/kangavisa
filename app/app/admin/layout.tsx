// /admin/layout.tsx — Admin Console shell layout
// Auth-gated + role-gated via assertAdmin(). Sprint 33.

import Link from "next/link";
import { assertAdmin } from "../../lib/admin-check";
import styles from "./admin-layout.module.css";

const NAV = [
    { href: "/admin",          label: "System Overview", icon: "🧭" },
    { href: "/admin/govdata",  label: "GovData Monitor", icon: "📊" },
    { href: "/admin/clients",  label: "Clients",          icon: "🏛️" },
    { href: "/admin/rules",    label: "Rules Engine",     icon: "⚙️",  badge: "Soon" },
    { href: "/admin/visas",    label: "Visa Config",      icon: "📁",  badge: "Soon" },
];

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
    const { role } = await assertAdmin();

    return (
        <div className={styles.shell}>
            {/* Sidebar */}
            <aside className={styles.sidebar}>
                <span className={styles.sidebar_label}>Console</span>
                {NAV.map(item => (
                    <Link key={item.href} href={item.href} className={styles.nav_link}>
                        <span>{item.icon}</span>
                        {item.label}
                        {item.badge && (
                            <span style={{
                                marginLeft: "auto",
                                fontSize: "var(--text-xs)",
                                opacity: 0.5,
                                background: "rgba(255,255,255,0.1)",
                                borderRadius: "var(--radius-full)",
                                padding: "1px 6px",
                            }}>
                                {item.badge}
                            </span>
                        )}
                    </Link>
                ))}
                <div className={styles.role_badge}>{role.replace("_", " ")}</div>
            </aside>

            {/* Content */}
            <main className={styles.content}>
                {children}
            </main>
        </div>
    );
}
