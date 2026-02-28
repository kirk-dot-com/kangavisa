/**
 * kb-service.ts — Structured-first KB retrieval for KangaVisa.
 *
 * US-F6 | FR-K1, FR-K2, FR-K3
 *
 * Implements the architecture.md §4.2 effective-date selection rule:
 *   effective_from <= case_date AND (effective_to IS NULL OR effective_to >= case_date)
 *
 * Uses the server-side Supabase admin client (bypasses RLS — server only).
 * Import only in API routes or Server Components, never in Client Components.
 */

import { createClient } from "@supabase/supabase-js";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface Requirement {
    requirement_id: string;
    subclass_code: string;
    requirement_type: string;
    title: string;
    plain_english: string;
    effective_from: string;
    effective_to: string | null;
    legal_basis: LegalBasis[];
    operational_basis: OperationalBasis[];
    rule_logic: RuleLogic;
    confidence: "high" | "medium" | "low";
    last_reviewed_at: string | null;
}

export interface LegalBasis {
    authority: "FRL_ACT" | "FRL_REGS" | "FRL_INSTRUMENT";
    citation: string | null;
    frl_title_id: string | null;
    series: string | null;
    notes: string | null;
}

export interface OperationalBasis {
    authority: "HOMEAFFAIRS_PAGE" | "DATAGOV_DATASET";
    url: string;
    title: string;
    last_checked: string | null;
}

export interface RuleLogic {
    inputs: string[];
    outputs: string[];
    logic_notes: string | null;
}

export interface EvidenceItem {
    evidence_id: string;
    requirement_id: string;
    label: string;
    description: string;
    priority: number;
    what_it_proves: string;
    common_gaps: string[];
    format_notes: string;
    effective_from: string;
    effective_to: string | null;
}

export interface FlagTemplate {
    flag_id: string;
    subclass_code: string;
    title: string;
    trigger_schema: Record<string, unknown>;
    why_it_matters: string;
    actions: string[];
    evidence_examples: string[];
    severity: "info" | "warning" | "risk";
    effective_from: string;
    effective_to: string | null;
}

export interface KBPackage {
    requirements: Requirement[];
    evidenceItems: EvidenceItem[];
    flagTemplates: FlagTemplate[];
    caseDate: string; // ISO date used for selection
    warnings: string[]; // staleness / missing-data warnings
}

// ---------------------------------------------------------------------------
// Client
// ---------------------------------------------------------------------------

function adminClient() {
    const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
    if (!url || !key) {
        throw new Error(
            "NEXT_PUBLIC_SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set (server only)."
        );
    }
    return createClient(url, key, { auth: { persistSession: false } });
}

// ---------------------------------------------------------------------------
// Effective-date helpers (architecture.md §4.2)
// ---------------------------------------------------------------------------

function effectiveDateFilter(caseDate: Date) {
    const iso = caseDate.toISOString().split("T")[0]; // YYYY-MM-DD
    return { caseIso: iso };
}

// ---------------------------------------------------------------------------
// Retrieval functions
// ---------------------------------------------------------------------------

/**
 * US-F6 | FR-K1: Fetch all active requirements for a visa subclass
 * as at *caseDate* (defaults to today).
 *
 * Applies architecture.md §4.2 effective-date selection:
 *   effective_from <= caseDate AND (effective_to IS NULL OR effective_to >= caseDate)
 */
export async function getRequirements(
    subclassCode: string,
    caseDate: Date = new Date()
): Promise<Requirement[]> {
    const { caseIso } = effectiveDateFilter(caseDate);
    const supabase = adminClient();

    const { data, error } = await supabase
        .from("requirement")
        .select("*")
        .eq("subclass_code", subclassCode)
        .lte("effective_from", caseIso)
        .or(`effective_to.is.null,effective_to.gte.${caseIso}`)
        .order("last_reviewed_at", { ascending: false, nullsFirst: false });

    if (error) throw new Error(`getRequirements failed: ${error.message}`);
    return (data ?? []) as Requirement[];
}

/**
 * US-F6 | FR-K2: Fetch all evidence items for a set of requirement IDs
 * as at *caseDate*.
 */
export async function getEvidenceItems(
    requirementIds: string[],
    caseDate: Date = new Date()
): Promise<EvidenceItem[]> {
    if (requirementIds.length === 0) return [];
    const { caseIso } = effectiveDateFilter(caseDate);
    const supabase = adminClient();

    const { data, error } = await supabase
        .from("evidence_item")
        .select("*")
        .in("requirement_id", requirementIds)
        .lte("effective_from", caseIso)
        .or(`effective_to.is.null,effective_to.gte.${caseIso}`)
        .order("priority", { ascending: true });

    if (error) throw new Error(`getEvidenceItems failed: ${error.message}`);
    return (data ?? []) as EvidenceItem[];
}

/**
 * US-F6 | FR-K3: Fetch all active flag templates for a visa subclass
 * as at *caseDate*.
 */
export async function getFlagTemplates(
    subclassCode: string,
    caseDate: Date = new Date()
): Promise<FlagTemplate[]> {
    const { caseIso } = effectiveDateFilter(caseDate);
    const supabase = adminClient();

    const { data, error } = await supabase
        .from("flag_template")
        .select("*")
        .eq("subclass_code", subclassCode)
        .lte("effective_from", caseIso)
        .or(`effective_to.is.null,effective_to.gte.${caseIso}`)
        .order("severity", { ascending: false });

    if (error) throw new Error(`getFlagTemplates failed: ${error.message}`);
    return (data ?? []) as FlagTemplate[];
}

/**
 * Convenience wrapper: fetch requirements + evidence + flags for a visa
 * subclass in a single call. Used by API routes and Server Components.
 *
 * FR-K1, FR-K2, FR-K3 — structured-first package.
 */
export async function getKBPackage(
    subclassCode: string,
    caseDate: Date = new Date()
): Promise<KBPackage> {
    const requirements = await getRequirements(subclassCode, caseDate);
    const requirementIds = requirements.map((r) => r.requirement_id);
    const [evidenceItems, flagTemplates] = await Promise.all([
        getEvidenceItems(requirementIds, caseDate),
        getFlagTemplates(subclassCode, caseDate),
    ]);

    const warnings: string[] = [];
    if (requirements.length === 0) {
        warnings.push(
            `No structured requirements found for visa ${subclassCode} as at ${caseDate.toISOString().split("T")[0]}. Falling back to document retrieval.`
        );
    }

    return {
        requirements,
        evidenceItems,
        flagTemplates,
        caseDate: caseDate.toISOString().split("T")[0],
        warnings,
    };
}
