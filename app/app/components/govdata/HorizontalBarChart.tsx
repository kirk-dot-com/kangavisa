"use client";
// HorizontalBarChart.tsx — horizontal bar chart for top countries, trip duration etc.

import {
    BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell,
} from "recharts";

interface Props {
    data: Record<string, string | number>[];
    dataKey: string;
    nameKey: string;
    color?: string;
}

const PALETTE = [
    "#0d9488", "#0f766e", "#1d4ed8", "#1e40af", "#b45309", "#92400e",
    "#6d28d9", "#4c1d95", "#be185d", "#9d174d",
];

export default function HorizontalBarChart({ data, dataKey, nameKey, color }: Props) {
    if (!data || data.length === 0) {
        return <p className="caption" style={{ color: "var(--color-muted)", padding: "var(--sp-4)" }}>No data yet.</p>;
    }
    return (
        <ResponsiveContainer width="100%" height={Math.max(180, data.length * 36)}>
            <BarChart data={data} layout="vertical" margin={{ top: 4, right: 24, left: 8, bottom: 4 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" horizontal={false} />
                <XAxis type="number" tick={{ fontSize: 11, fill: "var(--color-muted)" }} />
                <YAxis dataKey={nameKey} type="category" tick={{ fontSize: 12, fill: "var(--color-slate)" }} width={110} />
                <Tooltip
                    contentStyle={{ fontSize: 12, borderRadius: 8, border: "1px solid var(--color-border)" }}
                />
                <Bar dataKey={dataKey} radius={[0, 4, 4, 0]}>
                    {data.map((_, i) => (
                        <Cell key={i} fill={color ?? PALETTE[i % PALETTE.length]} />
                    ))}
                </Bar>
            </BarChart>
        </ResponsiveContainer>
    );
}
