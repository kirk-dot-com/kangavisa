"use client";
// StackedRiskChart.tsx — stacked/grouped bar chart for risk breakdown per country

import {
    BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell,
} from "recharts";

interface Props {
    data: { name: string; rate: number }[];
}

const RISK_COLORS: Record<string, string> = {
    Financial: "var(--color-risk)",
    Documentation: "var(--color-gold)",
    "Intent / Ties": "#6d28d9",
};

export default function StackedRiskChart({ data }: Props) {
    if (!data || data.length === 0) {
        return <p className="caption" style={{ color: "var(--color-muted)", padding: "var(--sp-4)" }}>No risk data available.</p>;
    }
    return (
        <ResponsiveContainer width="100%" height={180}>
            <BarChart data={data} margin={{ top: 8, right: 16, left: -16, bottom: 4 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" />
                <XAxis dataKey="name" tick={{ fontSize: 12, fill: "var(--color-slate)" }} />
                <YAxis tick={{ fontSize: 11, fill: "var(--color-muted)" }} unit="%" domain={[0, 100]} />
                <Tooltip
                    formatter={(v) => (v != null ? `${v}%` : "")}
                    contentStyle={{ fontSize: 12, borderRadius: 8, border: "1px solid var(--color-border)" }}
                />
                <Bar dataKey="rate" radius={[4, 4, 0, 0]}>
                    {data.map((entry, i) => (
                        <Cell key={i} fill={RISK_COLORS[entry.name] ?? "var(--color-teal)"} />
                    ))}
                </Bar>
            </BarChart>
        </ResponsiveContainer>
    );
}
