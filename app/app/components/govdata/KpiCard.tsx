"use client";
// KpiCard.tsx — reusable KPI metric tile for GovData dashboard

interface KpiCardProps {
    label: string;
    value: string;
    icon?: string;
    variant?: "neutral" | "risk" | "warning" | "success";
    small?: boolean;
}

const VARIANT_COLORS: Record<string, string> = {
    neutral: "var(--color-navy)",
    risk: "var(--color-risk)",
    warning: "var(--color-gold)",
    success: "var(--color-teal)",
};

export default function KpiCard({ label, value, icon, variant = "neutral", small }: KpiCardProps) {
    const color = VARIANT_COLORS[variant];
    return (
        <div
            style={{
                padding: "var(--sp-5)",
                background: "var(--color-white)",
                border: "1px solid var(--color-border)",
                borderRadius: "var(--radius-lg)",
                borderLeft: `4px solid ${color}`,
                display: "flex",
                flexDirection: "column",
                gap: "var(--sp-1)",
                flex: 1,
                minWidth: 0,
            }}
        >
            <span className="caption" style={{ color: "var(--color-muted)", textTransform: "uppercase", letterSpacing: "0.07em" }}>
                {icon && <span style={{ marginRight: "var(--sp-1)" }}>{icon}</span>}{label}
            </span>
            <span
                style={{
                    fontSize: small ? "var(--text-base)" : "var(--text-2xl)",
                    fontWeight: "var(--fw-bold)",
                    color,
                    lineHeight: 1.2,
                    wordBreak: "break-word",
                }}
            >
                {value}
            </span>
        </div>
    );
}
