/**
 * ExportPDFDocument.tsx — @react-pdf/renderer Document for the Readiness Pack
 * US-D1 | Brand Guidelines §9.5
 *
 * WARNING: This file uses @react-pdf/renderer primitives (View, Text, etc.)
 * NOT browser DOM elements. It must only be imported from server-side contexts.
 */

import {
    Document,
    Page,
    Text,
    View,
    StyleSheet,
    Font,
} from "@react-pdf/renderer";
import type { ExportPayload } from "../../lib/export-builder";

// ---------------------------------------------------------------------------
// PDF Styles
// ---------------------------------------------------------------------------
const NAVY = "#0a1628";
const GOLD = "#c9902a";
const TEAL = "#1a7a72";
const SLATE = "#64748b";
const BORDER = "#e2e8f0";
const SUCCESS = "#16a34a";
const WARNING = "#d97706";
const RISK = "#dc2626";

const s = StyleSheet.create({
    page: {
        fontFamily: "Helvetica",
        fontSize: 9,
        color: NAVY,
        paddingHorizontal: 40,
        paddingVertical: 40,
        lineHeight: 1.5,
    },
    // Header
    header: {
        borderBottomWidth: 2,
        borderBottomColor: GOLD,
        paddingBottom: 10,
        marginBottom: 16,
        flexDirection: "row",
        justifyContent: "space-between",
        alignItems: "flex-end",
    },
    headerTitle: { fontSize: 18, fontFamily: "Helvetica-Bold", color: NAVY },
    headerSubtitle: { fontSize: 10, color: SLATE, marginTop: 2 },
    headerMeta: { alignItems: "flex-end" },
    packVersion: { fontSize: 8, fontFamily: "Courier", color: GOLD },
    exportDate: { fontSize: 7, color: SLATE, marginTop: 2 },
    // Section
    section: { marginBottom: 14 },
    sectionTitle: {
        fontSize: 10,
        fontFamily: "Helvetica-Bold",
        color: NAVY,
        borderBottomWidth: 1,
        borderBottomColor: BORDER,
        paddingBottom: 3,
        marginBottom: 6,
    },
    // Assumptions
    assumptionRow: { flexDirection: "row", marginBottom: 2 },
    assumptionBullet: { width: 12, color: SLATE },
    assumptionText: { flex: 1, color: SLATE },
    // Coverage
    coverageRow: { flexDirection: "row", alignItems: "center", gap: 8, marginBottom: 4 },
    coveragePct: { fontSize: 20, fontFamily: "Helvetica-Bold", color: TEAL },
    coverageSub: { color: SLATE, fontSize: 8 },
    barWrap: { height: 6, backgroundColor: BORDER, borderRadius: 3, flex: 1 },
    barFill: { height: 6, backgroundColor: TEAL, borderRadius: 3 },
    // Flag row
    flagRow: {
        flexDirection: "row",
        gap: 8,
        paddingVertical: 6,
        borderBottomWidth: 1,
        borderBottomColor: BORDER,
    },
    flagBadge: { fontSize: 7, fontFamily: "Helvetica-Bold", paddingHorizontal: 4, paddingVertical: 2, borderRadius: 2 },
    flagBadgeRisk: { backgroundColor: "#fee2e2", color: RISK },
    flagBadgeWarn: { backgroundColor: "#fef3c7", color: WARNING },
    flagBadgeInfo: { backgroundColor: "#dbeafe", color: TEAL },
    flagContent: { flex: 1 },
    flagTitle: { fontFamily: "Helvetica-Bold", fontSize: 9 },
    flagWhy: { color: SLATE, fontSize: 8, marginTop: 1 },
    // Evidence items
    evidenceRow: {
        flexDirection: "row",
        gap: 6,
        paddingVertical: 4,
        borderBottomWidth: 1,
        borderBottomColor: BORDER,
    },
    evidenceStatus: { width: 48, fontSize: 7, fontFamily: "Helvetica-Bold" },
    evidenceLabel: { flex: 1, fontSize: 8 },
    evidenceProves: { flex: 1, fontSize: 7, color: SLATE },
    // Disclaimer
    disclaimer: {
        marginTop: 16,
        paddingTop: 8,
        borderTopWidth: 1,
        borderTopColor: BORDER,
        fontSize: 7,
        color: SLATE,
        fontStyle: "italic",
    },
    footer: {
        position: "absolute",
        bottom: 20,
        left: 40,
        right: 40,
        fontSize: 7,
        color: SLATE,
        textAlign: "center",
        borderTopWidth: 1,
        borderTopColor: BORDER,
        paddingTop: 4,
    },
});

function SeverityBadge({ severity }: { severity: "risk" | "warning" | "info" }) {
    const label = severity === "risk" ? "▲ RISK" : severity === "warning" ? "◆ FLAG" : "● NOTE";
    const style =
        severity === "risk"
            ? s.flagBadgeRisk
            : severity === "warning"
                ? s.flagBadgeWarn
                : s.flagBadgeInfo;
    return <Text style={[s.flagBadge, style]}>{label}</Text>;
}

// ---------------------------------------------------------------------------
// Main Document
// ---------------------------------------------------------------------------
export function ExportPDFDocument({ payload }: { payload: ExportPayload }) {
    const coverWidth = `${payload.coverage_pct}%`;

    return (
        <Document
            title={`KangaVisa Readiness Pack — ${payload.visa_name}`}
            author="KangaVisa"
            subject={`Visa ${payload.subclass_code} readiness pack`}
            keywords="KangaVisa visa readiness checklist"
        >
            <Page size="A4" style={s.page}>

                {/* Header */}
                <View style={s.header}>
                    <View>
                        <Text style={s.headerTitle}>KangaVisa — Readiness Pack</Text>
                        <Text style={s.headerSubtitle}>{payload.visa_name}</Text>
                    </View>
                    <View style={s.headerMeta}>
                        <Text style={s.packVersion}>{payload.pack_version}</Text>
                        <Text style={s.exportDate}>
                            Generated {new Date(payload.export_date).toLocaleDateString("en-AU")}
                        </Text>
                    </View>
                </View>

                {/* Case assumptions */}
                <View style={s.section}>
                    <Text style={s.sectionTitle}>Case assumptions</Text>
                    {payload.assumptions.map((a, i) => (
                        <View key={i} style={s.assumptionRow}>
                            <Text style={s.assumptionBullet}>·</Text>
                            <Text style={s.assumptionText}>{a}</Text>
                        </View>
                    ))}
                </View>

                {/* Coverage */}
                <View style={s.section}>
                    <Text style={s.sectionTitle}>Evidence coverage</Text>
                    <View style={s.coverageRow}>
                        <Text style={s.coveragePct}>{payload.coverage_pct}%</Text>
                        <View style={{ flex: 1 }}>
                            <View style={s.barWrap}>
                                <View style={[s.barFill, { width: coverWidth }]} />
                            </View>
                            <Text style={s.coverageSub}>
                                {payload.done_items} of {payload.total_items} items done
                            </Text>
                        </View>
                    </View>
                </View>

                {/* Top flags */}
                {payload.top_flags.length > 0 && (
                    <View style={s.section}>
                        <Text style={s.sectionTitle}>Top risk flags</Text>
                        {payload.top_flags.map((flag, i) => (
                            <View key={i} style={s.flagRow}>
                                <SeverityBadge severity={flag.severity} />
                                <View style={s.flagContent}>
                                    <Text style={s.flagTitle}>{flag.title}</Text>
                                    <Text style={s.flagWhy}>{flag.why_it_matters}</Text>
                                </View>
                            </View>
                        ))}
                    </View>
                )}

                {/* Evidence checklist */}
                <View style={s.section}>
                    <Text style={s.sectionTitle}>Evidence checklist</Text>
                    {/* header row */}
                    <View style={[s.evidenceRow, { borderBottomWidth: 0 }]}>
                        <Text style={[s.evidenceStatus, { color: SLATE }]}>STATUS</Text>
                        <Text style={[s.evidenceLabel, { fontFamily: "Helvetica-Bold" }]}>ITEM</Text>
                    </View>
                    {payload.item_states.map((item, i) => (
                        <View key={i} style={s.evidenceRow}>
                            <Text
                                style={[
                                    s.evidenceStatus,
                                    { color: item.status === "done" ? SUCCESS : item.status === "in_progress" ? TEAL : SLATE },
                                ]}
                            >
                                {item.status.replace("_", " ").toUpperCase()}
                            </Text>
                            <Text style={s.evidenceLabel}>{item.evidence_id}</Text>
                        </View>
                    ))}
                </View>

                {/* Disclaimer */}
                <Text style={s.disclaimer}>{payload.disclaimer}</Text>

                {/* Footer */}
                <Text
                    style={s.footer}
                    render={({ pageNumber, totalPages }) =>
                        `KangaVisa — Not legal advice — Page ${pageNumber} of ${totalPages}`
                    }
                    fixed
                />
            </Page>
        </Document>
    );
}
