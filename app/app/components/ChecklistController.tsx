"use client";
/**
 * ChecklistController.tsx — Client component managing session state + item states
 * US-B3, US-B4
 *
 * Receives KB data from the Server Component page as props.
 * On mount: loads/creates case_session, fetches saved item states.
 * Renders ChecklistItem per evidence row with persisted status.
 * Keeps a live count of done items for ReadinessScorecard.
 */

import { useState, useEffect, useCallback } from "react";
import { createClient } from "../../lib/supabase";
import ReadinessScorecard from "./ReadinessScorecard";
import ChecklistItem from "./ChecklistItem";
import type { Requirement, EvidenceItem, FlagTemplate } from "../../lib/kb-service";
import type { ItemStatus } from "./ChecklistItem";
import styles from "../checklist/[subclass]/checklist.module.css";
import Link from "next/link";

interface ItemState {
    evidence_id: string;
    status: ItemStatus;
    note?: string | null;
}

interface ChecklistControllerProps {
    subclass: string;
    caseDateStr: string;
    visaName: string;
    requirements: Requirement[];
    evidenceItems: EvidenceItem[];
    flagTemplates: FlagTemplate[];
}

const REQ_TYPE_ORDER = [
    "genuine", "english", "financial", "occupation",
    "nomination", "sponsorship", "work_history", "health", "character", "other",
];

export default function ChecklistController({
    subclass,
    caseDateStr,
    visaName,
    requirements,
    evidenceItems,
    flagTemplates,
}: ChecklistControllerProps) {
    const [sessionId, setSessionId] = useState<string | null>(null);
    const [authToken, setAuthToken] = useState<string | null>(null);
    const [itemStates, setItemStates] = useState<Map<string, ItemStatus>>(new Map());
    const [loading, setLoading] = useState(true);

    // Sort requirements
    const sortedReqs = [...requirements].sort(
        (a, b) =>
            (REQ_TYPE_ORDER.indexOf(a.requirement_type) + 1 || 99) -
            (REQ_TYPE_ORDER.indexOf(b.requirement_type) + 1 || 99)
    );

    // Load session + item states on mount
    useEffect(() => {
        async function init() {
            try {
                const supabase = createClient();
                const { data: sessionData } = await supabase.auth.getSession();
                const token = sessionData.session?.access_token ?? null;
                setAuthToken(token);

                if (!token) {
                    setLoading(false);
                    return; // Unauthenticated — UI-only mode
                }

                const headers = { Authorization: `Bearer ${token}` };

                // Get or create case session
                const getRes = await fetch(
                    `/api/sessions?subclass=${subclass}&caseDate=${caseDateStr}`,
                    { headers }
                );
                const getData = await getRes.json();
                let sid = getData.session?.session_id ?? null;

                if (!sid) {
                    const postRes = await fetch("/api/sessions", {
                        method: "POST",
                        headers: { ...headers, "Content-Type": "application/json" },
                        body: JSON.stringify({ subclass_code: subclass, case_date: caseDateStr }),
                    });
                    const postData = await postRes.json();
                    sid = postData.session?.session_id ?? null;
                }

                setSessionId(sid);

                // Load saved item states
                if (sid) {
                    const itemsRes = await fetch(`/api/sessions/${sid}/items`, { headers });
                    const itemsData = await itemsRes.json();
                    const stateMap = new Map<string, ItemStatus>();
                    for (const item of itemsData.items ?? []) {
                        stateMap.set(item.evidence_id, item.status as ItemStatus);
                    }
                    setItemStates(stateMap);
                }

                // Fire analytics
                await fetch("/api/analytics", {
                    method: "POST",
                    headers: { ...headers, "Content-Type": "application/json" },
                    body: JSON.stringify({
                        event_name: "CHECKLIST_VIEWED",
                        visa_group: subclass,
                        stage: "checklist",
                    }),
                });
            } catch {
                // Non-fatal — gracefully degrade to UI-only mode
            } finally {
                setLoading(false);
            }
        }
        init();
    }, [subclass, caseDateStr]);

    // Called by ChecklistItem when status changes — keep local count in sync
    const handleStatusChange = useCallback(
        (evidenceId: string, status: ItemStatus) => {
            setItemStates((prev) => new Map(prev).set(evidenceId, status));
        },
        []
    );

    const doneCount = Array.from(itemStates.values()).filter(
        (s) => s === "done"
    ).length;

    return (
        <>
            {/* ReadinessScorecard — live-updated */}
            <ReadinessScorecard
                totalItems={evidenceItems.length}
                doneItems={doneCount}
                unresolvedFlags={flagTemplates.length}
                visaName={visaName}
            />

            {/* Assumptions */}
            <div className={`card ${styles.assumptions}`}>
                <h3 className={`caption ${styles.assumptions__title}`}>Assumptions</h3>
                <ul className={styles.assumptions__list}>
                    <li className="body-sm">
                        <strong>Visa:</strong> {visaName}
                    </li>
                    <li className="body-sm">
                        <strong>Case date:</strong>{" "}
                        <span className="mono">{caseDateStr}</span>
                    </li>
                    <li className="body-sm">
                        <strong>Requirements:</strong>{" "}
                        <span className="mono">{requirements.length}</span> loaded
                    </li>
                </ul>
                {!authToken && (
                    <p className="caption" style={{ color: "var(--color-warning)", marginTop: "var(--sp-3)" }}>
                        <Link href="/auth/login" style={{ color: "var(--color-teal)", fontWeight: 600 }}>
                            Sign in
                        </Link>{" "}
                        to save your progress.
                    </p>
                )}
                {authToken && !loading && (
                    <p className="caption" style={{ color: "var(--color-success)", marginTop: "var(--sp-3)" }}>
                        ✓ Progress saving automatically.
                    </p>
                )}
            </div>

            <Link href={`/flags/${subclass}`} className="btn btn--secondary">
                View risk flags →
            </Link>
            <Link href={`/export/${subclass}?caseDate=${caseDateStr}`} className="btn btn--ghost">
                Export pack →
            </Link>
            <Link href="/pathway" className="btn btn--ghost">
                ← Change visa
            </Link>

            {/* Separator — main checklist content below rendered by parent page */}
            {loading && (
                <p className="caption" style={{ color: "var(--color-muted)", fontStyle: "italic" }}>
                    Loading saved progress…
                </p>
            )}

            {/* Requirements accordion with ChecklistItem */}
            <div style={{ display: "none" }} id="checklist-controller-ready" data-session-id={sessionId ?? ""} />

            {/* Pass state down — rendered inline below the sidebar by the page */}
            {typeof window !== "undefined" && (
                <div
                    style={{ display: "none" }}
                    id={`checklist-state-${subclass}`}
                    data-states={JSON.stringify(Object.fromEntries(itemStates))}
                />
            )}
        </>
    );
}

// ---------------------------------------------------------------------------
// Checklist body — separate export for use in the main column
// ---------------------------------------------------------------------------
export function ChecklistBody({
    subclass,
    caseDateStr,
    requirements,
    evidenceItems,
    sessionId,
    authToken,
    itemStates,
    onStatusChange,
}: {
    subclass: string;
    caseDateStr: string;
    requirements: Requirement[];
    evidenceItems: EvidenceItem[];
    sessionId: string | null;
    authToken: string | null;
    itemStates: Map<string, ItemStatus>;
    onStatusChange: (evidenceId: string, status: ItemStatus) => void;
}) {
    const sortedReqs = [...requirements].sort(
        (a, b) =>
            (REQ_TYPE_ORDER.indexOf(a.requirement_type) + 1 || 99) -
            (REQ_TYPE_ORDER.indexOf(b.requirement_type) + 1 || 99)
    );

    return (
        <>
            {sortedReqs.map((req) => {
                const items = evidenceItems.filter((e) => e.requirement_id === req.requirement_id)
                    .sort((a, b) => a.priority - b.priority);
                return (
                    <details key={req.requirement_id} className={styles.req_section} open>
                        <summary className={styles.req_summary}>
                            <span className={styles.req_type_badge}>
                                {req.requirement_type.replace(/_/g, " ")}
                            </span>
                            <span className={styles.req_title}>{req.title}</span>
                            <span className={`caption mono ${styles.req_count}`}>
                                {items.length} items
                            </span>
                        </summary>
                        <div className={styles.req_body}>
                            <p className="body-sm" style={{ color: "var(--color-slate)" }}>
                                {req.plain_english}
                            </p>
                            {req.legal_basis.length > 0 && (
                                <div className={styles.citations}>
                                    <span className="caption" style={{ color: "var(--color-muted)", fontWeight: 600 }}>
                                        Legal basis:
                                    </span>
                                    {req.legal_basis.map((lb, i) => (
                                        <span key={i} className={`caption mono ${styles.citation}`}>
                                            {lb.authority} · {lb.citation ?? lb.series}
                                        </span>
                                    ))}
                                </div>
                            )}
                            {items.length > 0 ? (
                                <ul className={styles.evidence_list}>
                                    {items.map((item) => (
                                        <ChecklistItem
                                            key={item.evidence_id}
                                            evidenceId={item.evidence_id}
                                            label={item.label}
                                            whatItProves={item.what_it_proves}
                                            commonGaps={item.common_gaps}
                                            citation={
                                                item.legal_basis.length > 0
                                                    ? (item.legal_basis[0].citation ?? item.legal_basis[0].authority ?? null)
                                                    : null
                                            }
                                            priority={item.priority}
                                            initialStatus={itemStates.get(item.evidence_id) ?? "not_started"}
                                            sessionId={sessionId}
                                            authToken={authToken}
                                            onStatusChange={onStatusChange}
                                        />
                                    ))}
                                </ul>
                            ) : (
                                <p className="caption" style={{ color: "var(--color-muted)", fontStyle: "italic", marginTop: "var(--sp-3)" }}>
                                    No evidence items loaded for this requirement.
                                </p>
                            )}
                        </div>
                    </details>
                );
            })}
        </>
    );
}
