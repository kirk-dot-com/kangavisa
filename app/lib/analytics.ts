/**
 * analytics.ts — Consent-gated analytics event helper
 * US-E2 | migrations_20260301_daas_consent_and_analytics.sql
 *
 * Client-side helper — reads consent from the server via /api/analytics POST.
 * The API route checks consent_state before inserting analytics_event.
 *
 * Events:
 *   CHECKLIST_VIEWED       — checklist page load
 *   ITEM_STATUS_CHANGED    — checkbox cycled
 *   PACK_EXPORTED          — PDF or CSV downloaded
 *   ASK_SUBMITTED          — LLM query sent
 */

export type AnalyticsEventName =
    | "CHECKLIST_VIEWED"
    | "ITEM_STATUS_CHANGED"
    | "PACK_EXPORTED"
    | "ASK_SUBMITTED";

export interface AnalyticsEventPayload {
    event_name: AnalyticsEventName;
    visa_group?: string;
    stage?: string;
    properties?: Record<string, unknown>;
}

/**
 * Fire an analytics event.
 * Non-blocking (fire-and-forget) — never throws.
 * The API gate checks consent_state before inserting.
 */
export async function track(payload: AnalyticsEventPayload): Promise<void> {
    try {
        await fetch("/api/analytics", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(payload),
        });
    } catch {
        // Non-fatal — analytics must never break the UX
    }
}
