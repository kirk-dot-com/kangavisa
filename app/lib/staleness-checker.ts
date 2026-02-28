/**
 * staleness-checker.ts — Staleness warning service for KB sources.
 *
 * US-F6 | FR-K5 (architecture.md §7.2)
 *
 * Checks source_document.retrieved_at against per-source-type thresholds.
 * Surfaced as warnings in the UI when sources are overdue for refresh.
 *
 * Thresholds (architecture.md §5 + Sprint 1 watcher cadences):
 *   FRL_ACT / FRL_REGS / FRL_INSTRUMENT — 14 days
 *   HOMEAFFAIRS_PAGE                     — 30 days
 *   DATAGOV_DATASET                      — 30 days
 */

// ---------------------------------------------------------------------------
// Thresholds (days)
// ---------------------------------------------------------------------------

export const STALENESS_THRESHOLDS_DAYS: Record<string, number> = {
    FRL_ACT: 14,
    FRL_REGS: 14,
    FRL_INSTRUMENT: 14,
    HOMEAFFAIRS_PAGE: 30,
    DATAGOV_DATASET: 30,
};

const DEFAULT_THRESHOLD_DAYS = 30;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface SourceDocumentStub {
    source_doc_id: string;
    source_type: string;
    canonical_url: string;
    retrieved_at: string; // ISO-8601
    title?: string | null;
}

export interface StalenessWarning {
    source_doc_id: string;
    source_type: string;
    canonical_url: string;
    title: string | null;
    retrieved_at: string;
    days_since_retrieved: number;
    threshold_days: number;
    message: string;
}

// ---------------------------------------------------------------------------
// Core functions
// ---------------------------------------------------------------------------

/**
 * Returns the number of calendar days between *retrievedAt* and *asAt* (default: now).
 */
export function daysSince(retrievedAt: string, asAt: Date = new Date()): number {
    const retrieved = new Date(retrievedAt);
    const diffMs = asAt.getTime() - retrieved.getTime();
    return Math.floor(diffMs / (1000 * 60 * 60 * 24));
}

/**
 * Check a single source document for staleness.
 * Returns a StalenessWarning if overdue, or null if within threshold.
 */
export function checkSourceStaleness(
    doc: SourceDocumentStub,
    asAt: Date = new Date()
): StalenessWarning | null {
    const threshold =
        STALENESS_THRESHOLDS_DAYS[doc.source_type] ?? DEFAULT_THRESHOLD_DAYS;
    const days = daysSince(doc.retrieved_at, asAt);

    if (days <= threshold) return null;

    return {
        source_doc_id: doc.source_doc_id,
        source_type: doc.source_type,
        canonical_url: doc.canonical_url,
        title: doc.title ?? null,
        retrieved_at: doc.retrieved_at,
        days_since_retrieved: days,
        threshold_days: threshold,
        message:
            `Source "${doc.title ?? doc.canonical_url}" (${doc.source_type}) ` +
            `was last retrieved ${days} days ago (threshold: ${threshold} days). ` +
            `Displayed information may not reflect the latest changes. ` +
            `Verify against the official source before relying on this content.`,
    };
}

/**
 * Check a list of source documents and return all active staleness warnings.
 * Used by API routes to inject warnings into KB packages.
 */
export function checkAllSourceStaleness(
    docs: SourceDocumentStub[],
    asAt: Date = new Date()
): StalenessWarning[] {
    return docs
        .map((doc) => checkSourceStaleness(doc, asAt))
        .filter((w): w is StalenessWarning => w !== null);
}

/**
 * Format staleness warnings as a single user-facing banner message,
 * suitable for injection into a UI alert or disclaimer block.
 */
export function formatStalenessAlert(warnings: StalenessWarning[]): string | null {
    if (warnings.length === 0) return null;
    const sourceList = warnings.map((w) => w.title ?? w.canonical_url).join(", ");
    return (
        `⚠️ Some sources may not be current: ${sourceList}. ` +
        `KangaVisa refreshes sources regularly, but always verify critical requirements ` +
        `against the official Home Affairs website or Federal Register of Legislation ` +
        `before lodging your application.`
    );
}
