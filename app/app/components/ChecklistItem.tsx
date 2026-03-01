"use client";
// ChecklistItem.tsx — Client component for a single evidence checklist row
// US-B3, US-B4 — saves state to /api/sessions/[sessionId]/items

import { useState, useTransition } from "react";
import styles from "./ChecklistItem.module.css";

export type ItemStatus = "not_started" | "in_progress" | "done" | "na";

export interface ChecklistItemProps {
    evidenceId: string;
    label: string;
    whatItProves: string;
    commonGaps: string[];
    citation?: string | null;
    formatNotes?: string;
    priority: number;
    initialStatus?: ItemStatus;
    sessionId: string | null;   // null = unauthenticated, state not persisted
    authToken: string | null;
}

const STATUS_ORDER: ItemStatus[] = ["not_started", "in_progress", "done", "na"];

const STATUS_LABEL: Record<ItemStatus, string> = {
    not_started: "Not started",
    in_progress: "In progress",
    done: "Done",
    na: "N/A",
};

const STATUS_BADGE: Record<ItemStatus, string> = {
    not_started: "badge--muted",
    in_progress: "badge--info",
    done: "badge--success",
    na: "badge--muted",
};

export default function ChecklistItem({
    evidenceId,
    label,
    whatItProves,
    commonGaps,
    citation,
    formatNotes,
    priority,
    initialStatus = "not_started",
    sessionId,
    authToken,
}: ChecklistItemProps) {
    const [status, setStatus] = useState<ItemStatus>(initialStatus);
    const [, startTransition] = useTransition();

    function cycleStatus() {
        const next = STATUS_ORDER[(STATUS_ORDER.indexOf(status) + 1) % STATUS_ORDER.length];
        setStatus(next); // optimistic

        if (!sessionId || !authToken) return; // unauthenticated — UI only

        startTransition(async () => {
            try {
                await fetch(`/api/sessions/${sessionId}/items`, {
                    method: "PATCH",
                    headers: {
                        "Content-Type": "application/json",
                        Authorization: `Bearer ${authToken}`,
                    },
                    body: JSON.stringify({ evidence_id: evidenceId, status: next }),
                });
            } catch {
                // Non-fatal — state already updated optimistically
            }
        });
    }

    const isDone = status === "done";

    return (
        <li
            className={`${styles.item} ${isDone ? styles.item__done : ""}`}
            aria-label={`Evidence item: ${label}`}
        >
            {/* Status cycle button */}
            <button
                onClick={cycleStatus}
                className={styles.cycle_btn}
                aria-label={`Status: ${STATUS_LABEL[status]}. Click to change.`}
                type="button"
            >
                <span className={styles.cycle_icon} aria-hidden="true">
                    {status === "done" ? "✓" : status === "na" ? "–" : status === "in_progress" ? "◑" : "○"}
                </span>
            </button>

            {/* Content */}
            <div className={styles.content}>
                <div className={styles.top_row}>
                    <span className={`${styles.label} ${isDone ? styles.label__done : ""}`}>
                        {priority === 1 && (
                            <span className={styles.priority_dot} aria-label="High priority" title="High priority" />
                        )}
                        {label}
                    </span>
                    <span className={`badge ${STATUS_BADGE[status]} ${styles.status_badge}`}>
                        {STATUS_LABEL[status]}
                    </span>
                </div>

                <p className={`caption ${styles.proves}`}>
                    <em>Proves:</em> {whatItProves}
                </p>

                {citation && (
                    <span className={`caption mono ${styles.citation}`}>{citation}</span>
                )}

                {formatNotes && (
                    <p className={`caption ${styles.format_notes}`}>📋 {formatNotes}</p>
                )}

                {commonGaps.length > 0 && (
                    <details className={styles.gaps}>
                        <summary className={`caption ${styles.gaps_summary}`}>
                            ⚠ Common gaps ({commonGaps.length})
                        </summary>
                        <ul className={styles.gaps_list}>
                            {commonGaps.map((g, i) => (
                                <li key={i} className="caption">• {g}</li>
                            ))}
                        </ul>
                    </details>
                )}
            </div>
        </li>
    );
}
