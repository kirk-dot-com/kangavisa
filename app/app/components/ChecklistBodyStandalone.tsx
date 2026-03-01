"use client";
/**
 * ChecklistBodyStandalone.tsx — Self-contained checklist body (Client Component)
 * US-B3, US-B4
 *
 * Loads its own session on mount and renders ChecklistItem for each evidence row.
 * Separated from ChecklistController to avoid "Server Component passes to Server Page" issues.
 */

import { useState, useEffect, useCallback } from "react";
import { createClient } from "../../lib/supabase";
import ChecklistItem from "./ChecklistItem";
import type { Requirement, EvidenceItem } from "../../lib/kb-service";
import type { ItemStatus } from "./ChecklistItem";
import styles from "../checklist/[subclass]/checklist.module.css";

interface ChecklistBodyProps {
    subclass: string;
    caseDateStr: string;
    requirements: Requirement[];
    evidenceItems: EvidenceItem[];
}

const REQ_TYPE_ORDER = [
    "genuine", "english", "financial", "occupation",
    "nomination", "sponsorship", "work_history", "health", "character", "other",
];

export function ChecklistBodyStandalone({
    subclass,
    caseDateStr,
    requirements,
    evidenceItems,
}: ChecklistBodyProps) {
    const [sessionId, setSessionId] = useState<string | null>(null);
    const [authToken, setAuthToken] = useState<string | null>(null);
    const [itemStates, setItemStates] = useState<Map<string, ItemStatus>>(new Map());

    // Sort requirements
    const sortedReqs = [...requirements].sort(
        (a, b) =>
            (REQ_TYPE_ORDER.indexOf(a.requirement_type) + 1 || 99) -
            (REQ_TYPE_ORDER.indexOf(b.requirement_type) + 1 || 99)
    );

    useEffect(() => {
        async function init() {
            try {
                const supabase = createClient();
                const { data } = await supabase.auth.getSession();
                const token = data.session?.access_token ?? null;
                setAuthToken(token);
                if (!token) return;

                const headers = { Authorization: `Bearer ${token}` };

                // Get or create session
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
                    sid = (await postRes.json()).session?.session_id ?? null;
                }

                setSessionId(sid);

                if (sid) {
                    const itemsRes = await fetch(`/api/sessions/${sid}/items`, { headers });
                    const stateMap = new Map<string, ItemStatus>();
                    for (const item of (await itemsRes.json()).items ?? []) {
                        stateMap.set(item.evidence_id, item.status as ItemStatus);
                    }
                    setItemStates(stateMap);
                }
            } catch {
                // Degrade gracefully — UI-only mode
            }
        }
        init();
    }, [subclass, caseDateStr]);

    const handleStatusChange = useCallback((evidenceId: string, status: ItemStatus) => {
        setItemStates((prev) => new Map(prev).set(evidenceId, status));
    }, []);

    return (
        <>
            {sortedReqs.map((req) => {
                const items = evidenceItems
                    .filter((e) => e.requirement_id === req.requirement_id)
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
                                            priority={item.priority}
                                            initialStatus={itemStates.get(item.evidence_id) ?? "not_started"}
                                            sessionId={sessionId}
                                            authToken={authToken}
                                            onStatusChange={handleStatusChange}
                                        />
                                    ))}
                                </ul>
                            ) : (
                                <p className="caption" style={{ color: "var(--color-muted)", fontStyle: "italic", marginTop: "var(--sp-3)" }}>
                                    No evidence items seeded for this requirement yet.
                                </p>
                            )}
                        </div>
                    </details>
                );
            })}
        </>
    );
}
