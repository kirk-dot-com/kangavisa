"use client";
// TrendLineChart.tsx — time series line chart via Recharts

import {
    LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
} from "recharts";

interface Props {
    data: { month: string; [key: string]: number | string }[];
    dataKey: string;
    color?: string;
}

export default function TrendLineChart({ data, dataKey, color = "var(--color-teal)" }: Props) {
    if (!data || data.length === 0) {
        return <p className="caption" style={{ color: "var(--color-muted)", padding: "var(--sp-4)" }}>No trend data yet.</p>;
    }
    return (
        <ResponsiveContainer width="100%" height={200}>
            <LineChart data={data} margin={{ top: 8, right: 16, left: -16, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="var(--color-border)" />
                <XAxis dataKey="month" tick={{ fontSize: 11, fill: "var(--color-muted)" }} />
                <YAxis tick={{ fontSize: 11, fill: "var(--color-muted)" }} />
                <Tooltip
                    contentStyle={{ fontSize: 12, borderRadius: 8, border: "1px solid var(--color-border)" }}
                />
                <Line
                    type="monotone"
                    dataKey={dataKey}
                    stroke={color}
                    strokeWidth={2}
                    dot={{ r: 3, fill: color }}
                    activeDot={{ r: 5 }}
                />
            </LineChart>
        </ResponsiveContainer>
    );
}
