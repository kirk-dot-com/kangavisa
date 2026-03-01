/**
 * export-builder.ts — Assembles the export data payload
 * US-D1, US-D2 | Brand Guidelines §9.5
 *
 * Required fields per brand §9.5:
 *   - case snapshot (visa name, subclass, case date)
 *   - evidence coverage % 
 *   - top flags (max 5, by severity: risk > warning > info)
 *   - assumptions
 *   - export date + pack version
 */

import type { KBPackage, FlagTemplate } from "./kb-service";

export interface ChecklistItemState {
    evidence_id: string;
    status: "not_started" | "in_progress" | "done" | "na";
    note?: string | null;
}

export interface ExportPayload {
    // Case snapshot
    visa_name: string;
    subclass_code: string;
    case_date: string;

    // Coverage
    total_items: number;
    done_items: number;
    coverage_pct: number;

    // Flags (top 5 by severity)
    top_flags: Array<{
        title: string;
        severity: FlagTemplate["severity"];
        why_it_matters: string;
        actions: string[];
        effective_from: string;
    }>;

    // Requirements summary
    requirements_summary: Array<{
        type: string;
        title: string;
        plain_english: string;
        citation?: string;
    }>;

    // Assumptions
    assumptions: string[];

    // Export metadata
    export_date: string;        // ISO timestamp
    pack_version: string;       // kb-vYYYYMMDD
    disclaimer: string;

    // Item states (for CSV)
    item_states: ChecklistItemState[];
}

const DISCLAIMER =
    "KangaVisa is an information and preparation tool — not legal advice. " +
    "This export does not guarantee visa approval or constitute advice " +
    "from a registered migration agent. Always verify against official " +
    "Home Affairs guidance and the Federal Register of Legislation.";

const SEVERITY_ORDER: Record<FlagTemplate["severity"], number> = {
    risk: 0,
    warning: 1,
    info: 2,
};

export function buildExportPayload(
    pkg: KBPackage,
    itemStates: ChecklistItemState[],
    visaName: string,
    subclassCode: string
): ExportPayload {
    const doneItems = itemStates.filter((s) => s.status === "done").length;
    const naItems = itemStates.filter((s) => s.status === "na").length;
    const applicableItems = itemStates.length - naItems;
    const coveragePct =
        applicableItems > 0 ? Math.round((doneItems / applicableItems) * 100) : 0;

    // Top flags sorted by severity
    const topFlags = [...pkg.flagTemplates]
        .sort(
            (a, b) => SEVERITY_ORDER[a.severity] - SEVERITY_ORDER[b.severity]
        )
        .slice(0, 5)
        .map((f) => ({
            title: f.title,
            severity: f.severity,
            why_it_matters: f.why_it_matters,
            actions: f.actions,
            effective_from: f.effective_from,
        }));

    // Requirements summary
    const requirementsSummary = pkg.requirements.map((r) => ({
        type: r.requirement_type,
        title: r.title,
        plain_english: r.plain_english,
        citation:
            r.legal_basis.length > 0
                ? (r.legal_basis[0].citation ?? r.legal_basis[0].authority)
                : undefined,
    }));

    // Pack version from KB caseDate
    const now = new Date();
    const packVersion = `kb-v${now.toISOString().slice(0, 10).replace(/-/g, "")}`;

    const assumptions = [
        `Visa subclass: ${subclassCode}`,
        `Case date: ${pkg.caseDate}`,
        `Requirements loaded: ${pkg.requirements.length}`,
        `Evidence items: ${itemStates.length}`,
        "Effective date selection: as at case date above",
    ];

    return {
        visa_name: visaName,
        subclass_code: subclassCode,
        case_date: pkg.caseDate,
        total_items: itemStates.length,
        done_items: doneItems,
        coverage_pct: coveragePct,
        top_flags: topFlags,
        requirements_summary: requirementsSummary,
        assumptions,
        export_date: now.toISOString(),
        pack_version: packVersion,
        disclaimer: DISCLAIMER,
        item_states: itemStates,
    };
}

// ---------- CSV builder ----------

function escapeCsv(v: string | undefined | null): string {
    if (v == null) return "";
    const s = String(v);
    if (s.includes(",") || s.includes('"') || s.includes("\n")) {
        return `"${s.replace(/"/g, '""')}"`;
    }
    return s;
}

export function buildCsv(payload: ExportPayload): string {
    const header = [
        "evidence_id",
        "label",
        "what_it_proves",
        "status",
        "note",
        "requirement",
        "visa",
        "case_date",
        "pack_version",
    ].join(",");

    // Join evidence item metadata with item states
    const rows = payload.item_states.map((s) => {
        return [
            escapeCsv(s.evidence_id),
            "", // label not in state — populated from KB in route
            "",
            escapeCsv(s.status),
            escapeCsv(s.note ?? ""),
            "",
            escapeCsv(payload.visa_name),
            escapeCsv(payload.case_date),
            escapeCsv(payload.pack_version),
        ].join(",");
    });

    return [header, ...rows].join("\n");
}
