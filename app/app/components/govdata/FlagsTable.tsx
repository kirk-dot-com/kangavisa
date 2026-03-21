"use client";
// FlagsTable.tsx — ranked risk flags table

interface Flag {
    flag: string;
    frequency: number;
    rate: number;
}

interface Props {
    flags: Flag[];
    showRate?: boolean;
}

export default function FlagsTable({ flags, showRate }: Props) {
    if (!flags || flags.length === 0) {
        return <p className="caption" style={{ color: "var(--color-muted)", padding: "var(--sp-4)" }}>No flag data yet.</p>;
    }
    return (
        <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "var(--text-sm)" }}>
            <thead>
                <tr style={{ borderBottom: "1px solid var(--color-border)" }}>
                    <th style={{ textAlign: "left", padding: "var(--sp-2) var(--sp-3)", color: "var(--color-muted)", fontWeight: "var(--fw-semibold)", fontSize: "var(--text-xs)", textTransform: "uppercase", letterSpacing: "0.07em" }}>Flag</th>
                    <th style={{ textAlign: "right", padding: "var(--sp-2) var(--sp-3)", color: "var(--color-muted)", fontWeight: "var(--fw-semibold)", fontSize: "var(--text-xs)", textTransform: "uppercase", letterSpacing: "0.07em" }}>Count</th>
                    {showRate && <th style={{ textAlign: "right", padding: "var(--sp-2) var(--sp-3)", color: "var(--color-muted)", fontWeight: "var(--fw-semibold)", fontSize: "var(--text-xs)", textTransform: "uppercase", letterSpacing: "0.07em" }}>Rate</th>}
                </tr>
            </thead>
            <tbody>
                {flags.map((f, i) => (
                    <tr key={i} style={{ borderBottom: "1px solid var(--color-border)" }}>
                        <td style={{ padding: "var(--sp-3)", color: "var(--color-navy)", fontWeight: i === 0 ? "var(--fw-semibold)" : undefined }}>
                            {i === 0 && <span style={{ color: "var(--color-risk)", marginRight: "var(--sp-1)" }}>▲</span>}
                            {f.flag}
                        </td>
                        <td style={{ padding: "var(--sp-3)", textAlign: "right", color: "var(--color-slate)" }}>{f.frequency}</td>
                        {showRate && (
                            <td style={{ padding: "var(--sp-3)", textAlign: "right" }}>
                                <span style={{
                                    background: f.rate > 25 ? "rgba(239,68,68,0.1)" : "rgba(20,184,166,0.1)",
                                    color: f.rate > 25 ? "var(--color-risk)" : "var(--color-teal)",
                                    padding: "2px 8px",
                                    borderRadius: "var(--radius-full)",
                                    fontSize: "var(--text-xs)",
                                    fontWeight: "var(--fw-semibold)",
                                }}>
                                    {f.rate}%
                                </span>
                            </td>
                        )}
                    </tr>
                ))}
            </tbody>
        </table>
    );
}
