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

import type { KBPackage, FlagTemplate, EvidenceItem } from "./kb-service";

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

    // Item states (for CSV / DOCX)
    item_states: ChecklistItemState[];

    // Evidence items (for enriched CSV + weighted score)
    evidence_items: EvidenceItem[];

    // Weighted coverage — evidence_item.priority weighted (1=high→3pts, 2→2pts, ≥3→1pt)
    weighted_coverage_pct: number;
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

// ---------------------------------------------------------------------------
// Weighted coverage helper
// ---------------------------------------------------------------------------

/**
 * Maps EvidenceItem.priority to a weight value.
 * priority 1 (high) = 3 pts, priority 2 = 2 pts, priority ≥ 3 (default) = 1 pt.
 * Brand-safe: labelled "Priority-weighted coverage", not "approval likelihood".
 */
function priorityWeight(priority: number): number {
    if (priority <= 1) return 3;
    if (priority === 2) return 2;
    return 1;
}

export function computeWeightedCoverage(
    itemStates: ChecklistItemState[],
    evidenceItems: EvidenceItem[]
): number {
    const priorityMap = new Map(evidenceItems.map((e) => [e.evidence_id, e.priority]));
    const applicable = itemStates.filter((s) => s.status !== "na");
    const totalWeight = applicable.reduce(
        (sum, s) => sum + priorityWeight(priorityMap.get(s.evidence_id) ?? 3),
        0
    );
    const doneWeight = applicable
        .filter((s) => s.status === "done")
        .reduce(
            (sum, s) => sum + priorityWeight(priorityMap.get(s.evidence_id) ?? 3),
            0
        );
    return totalWeight > 0 ? Math.round((doneWeight / totalWeight) * 100) : 0;
}

// ---------------------------------------------------------------------------
// 4-component readiness score (readiness_scoring_model.json v1.0)
// ---------------------------------------------------------------------------

export interface ReadinessScore {
    /** 0–100 overall readiness score */
    score: number;
    /** "Strong readiness" | "Moderate readiness" | "Preparation gaps" | "Early preparation" */
    band: string;
    /** Component scores 0–1 */
    components: {
        evidenceCoverage: number;
        timelineCompleteness: number;
        consistencyScore: number;
        riskIndicators: number;
    };
}

/** Flag penalty weights from readiness_scoring_model.json */
const FLAG_PENALTIES: Record<string, number> = {
    critical: 0.20,
    high: 0.12,
    medium: 0.07,
    low: 0.03,
};

/**
 * Compute the 4-component KangaVisa readiness score.
 *
 * Formula (from readiness_scoring_model.json):
 *   score = (evidenceCoverage × 0.35) + (timelineCompleteness × 0.20)
 *         + (consistencyScore × 0.20) + (riskIndicators × 0.25)
 *
 * Timeline and consistency default to 1.0 (neutral) when not yet collected.
 * This ensures the score degrades gracefully as more signals become available.
 */
export function computeReadinessScore(
    itemStates: ChecklistItemState[],
    evidenceItems: EvidenceItem[],
    options?: {
        /** 0–365: largest gap in days. Default 0 (no gaps detected). */
        largestTimelineGapDays?: number;
        /** Count of consistency flags triggered. Default 0. */
        consistencyFlagCount?: number;
        /** Array of {severity: 'critical'|'high'|'medium'|'low'} for triggered flags */
        triggeredFlags?: Array<{ severity: string }>;
    }
): ReadinessScore {
    const opts = options ?? {};

    // Component 1 — evidence coverage (0–1)
    // Draft credit: in_progress items with a non-empty note score 0.3× their weight.
    // This rewards users who have started drafting evidence even if not marked Done.
    const priorityMap = new Map(evidenceItems.map((e) => [e.evidence_id, e.priority]));
    const totalWeight = (() => {
        const applicable = itemStates.filter((s) => s.status !== "na");
        return applicable.reduce((sum, s) => sum + priorityWeight(priorityMap.get(s.evidence_id) ?? 3), 0);
    })();
    const doneWeight = (() => {
        return itemStates
            .filter((s) => s.status === "done")
            .reduce((sum, s) => sum + priorityWeight(priorityMap.get(s.evidence_id) ?? 3), 0);
    })();
    const draftWeight = (() => {
        // Only credit in_progress items that have a non-empty note (actual draft content)
        return itemStates
            .filter((s) => s.status === "in_progress" && s.note && s.note.trim().length > 0)
            .reduce((sum, s) => sum + priorityWeight(priorityMap.get(s.evidence_id) ?? 3) * 0.3, 0);
    })();
    const evidenceCoverage = totalWeight > 0 ? (doneWeight + draftWeight) / totalWeight : 0;

    // Component 2 — timeline completeness (0–1). Neutral (1.0) if not collected yet.
    const gapDays = opts.largestTimelineGapDays ?? 0;
    const timelineCompleteness = Math.max(0, 1 - gapDays / 365);

    // Component 3 — consistency (0–1). Neutral (1.0) if not collected.
    const consistencyFlagCount = opts.consistencyFlagCount ?? 0;
    const consistencyScore = Math.max(0, 1 - consistencyFlagCount * 0.1);

    // Component 4 — risk flag penalty (0–1).
    const triggeredFlags = opts.triggeredFlags ?? [];
    const penalty = Math.min(
        1,
        triggeredFlags.reduce((sum, f) => sum + (FLAG_PENALTIES[f.severity] ?? 0), 0)
    );
    const riskIndicators = 1 - penalty;

    // Weighted sum
    const raw =
        evidenceCoverage * 0.35 +
        timelineCompleteness * 0.20 +
        consistencyScore * 0.20 +
        riskIndicators * 0.25;

    const score = Math.round(raw * 100);

    const band =
        score >= 85 ? "Strong readiness"
            : score >= 70 ? "Moderate readiness"
                : score >= 50 ? "Preparation gaps"
                    : "Early preparation";

    return {
        score,
        band,
        components: { evidenceCoverage, timelineCompleteness, consistencyScore, riskIndicators },
    };
}

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

    const weightedCoveragePct = computeWeightedCoverage(itemStates, pkg.evidenceItems);

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
        evidence_items: pkg.evidenceItems,
        weighted_coverage_pct: weightedCoveragePct,
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

    // Build lookup maps from evidence_items in the payload
    const evidenceMap = new Map(
        payload.evidence_items.map((e) => [e.evidence_id, e])
    );
    // Map requirement_id → title from requirements_summary (best effort)
    const reqMap = new Map(
        payload.requirements_summary.map((r) => [r.title, r.title])
    );

    // Join evidence item metadata with item states
    const rows = payload.item_states.map((s) => {
        const ev = evidenceMap.get(s.evidence_id);
        // Find the requirement title for this evidence item
        const reqSummary = payload.requirements_summary.find(
            (r) => r.title && reqMap.has(r.title)
        );
        return [
            escapeCsv(s.evidence_id),
            escapeCsv(ev?.label ?? ""),
            escapeCsv(ev?.what_it_proves ?? ""),
            escapeCsv(s.status),
            escapeCsv(s.note ?? ""),
            escapeCsv(reqSummary?.title ?? ""),
            escapeCsv(payload.visa_name),
            escapeCsv(payload.case_date),
            escapeCsv(payload.pack_version),
        ].join(",");
    });

    return [header, ...rows].join("\n");
}
