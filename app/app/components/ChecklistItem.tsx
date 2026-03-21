"use client";
// ChecklistItem.tsx — Client component for a single evidence checklist row
// US-B3, US-B4 — saves state + note to /api/sessions/[sessionId]/items

import { useState, useEffect, useRef, useTransition } from "react";
import styles from "./ChecklistItem.module.css";
import AssessmentBadge, { type Assessment } from "./AssessmentBadge";

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
    initialNote?: string;
    initialAssessment?: Assessment | null;
    sessionId: string | null;   // null = unauthenticated, state not persisted
    authToken: string | null;
    onStatusChange?: (evidenceId: string, status: ItemStatus) => void;
    onNoteChange?: (evidenceId: string, note: string) => void;
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
    initialNote = "",
    initialAssessment = null,
    sessionId,
    authToken,
    onStatusChange,
    onNoteChange,
}: ChecklistItemProps) {
    const [status, setStatus] = useState<ItemStatus>(initialStatus);
    const [note, setNote] = useState(initialNote);
    const [savedChars, setSavedChars] = useState(initialNote.length);
    // P1: always start false (SSR-safe), then open client-side if a note exists
    const [expanded, setExpanded] = useState(false);
    const [saving, setSaving] = useState(false);
    const [assessing, setAssessing] = useState(false);
    // P2: seed from persisted assessment_json so badge survives reload
    const [assessment, setAssessment] = useState<Assessment | null>(initialAssessment ?? null);
    const [, startTransition] = useTransition();
    const textareaRef = useRef<HTMLTextAreaElement>(null);

    // P1: open accordion after hydration if item already has a note
    useEffect(() => {
        if (initialNote.length > 0) setExpanded(true);
    }, []); // eslint-disable-line react-hooks/exhaustive-deps

    async function patchItem(newStatus: ItemStatus, newNote: string) {
        if (!sessionId || !authToken) return;
        try {
            await fetch(`/api/sessions/${sessionId}/items`, {
                method: "PATCH",
                headers: {
                    "Content-Type": "application/json",
                    Authorization: `Bearer ${authToken}`,
                },
                body: JSON.stringify({
                    evidence_id: evidenceId,
                    status: newStatus,
                    note: newNote || null,
                }),
            });
        } catch {
            // Non-fatal
        }
    }

    function cycleStatus() {
        const next = STATUS_ORDER[(STATUS_ORDER.indexOf(status) + 1) % STATUS_ORDER.length];
        setStatus(next);
        onStatusChange?.(evidenceId, next);
        startTransition(() => { patchItem(next, note); });
    }

    function handleLabelClick() {
        setExpanded((prev) => !prev);
        // Focus textarea when opening
        if (!expanded) {
            setTimeout(() => textareaRef.current?.focus(), 50);
        }
    }

    function handleNoteInput(e: React.ChangeEvent<HTMLTextAreaElement>) {
        const val = e.target.value;
        setNote(val);
        onNoteChange?.(evidenceId, val);

        // Auto-advance to in_progress on first keystroke
        if (val.length > 0 && status === "not_started") {
            const next: ItemStatus = "in_progress";
            setStatus(next);
            onStatusChange?.(evidenceId, next);
        }
    }

    async function handleNoteBlur() {
        if (!sessionId || !authToken) return;
        setSaving(true);
        await patchItem(status, note);
        setSavedChars(note.length);
        setSaving(false);
    }

    async function handleAssess() {
        if (!sessionId || !authToken || note.trim().length < 20) return;
        setAssessing(true);
        try {
            const res = await fetch(
                `/api/sessions/${sessionId}/items/${evidenceId}/assess`,
                {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                        Authorization: `Bearer ${authToken}`,
                    },
                    body: JSON.stringify({
                        draft_content: note,
                        evidence_label: label,
                        what_it_proves: whatItProves,
                    }),
                }
            );
            const data = await res.json();
            if (data.assessment) setAssessment(data.assessment as Assessment);
        } catch {
            // Non-fatal
        } finally {
            setAssessing(false);
        }
    }

    const isDone = status === "done";

    return (
        <li
            className={`${styles.item} ${isDone ? styles.item__done : ""} ${expanded ? styles.item__expanded : ""}`}
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
                    {/* Clickable label toggles accordion */}
                    <button
                        type="button"
                        className={styles.label_btn}
                        onClick={handleLabelClick}
                        aria-expanded={expanded}
                        aria-controls={`draft-panel-${evidenceId}`}
                    >
                        <span className={`${styles.label} ${isDone ? styles.label__done : ""}`}>
                            {priority === 1 && (
                                <span className={styles.priority_dot} aria-label="High priority" title="High priority" />
                            )}
                            {label}
                        </span>
                        <span className={`${styles.chevron} ${expanded ? styles.chevron__open : ""}`} aria-hidden="true">
                            ▶
                        </span>
                    </button>
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

                {/* Draft note accordion panel */}
                <div
                    id={`draft-panel-${evidenceId}`}
                    className={`${styles.accordion} ${expanded ? styles.accordion__open : ""}`}
                >
                    <div className={styles.accordion_inner}>
                        <label className={`caption ${styles.draft_label}`} htmlFor={`note-${evidenceId}`}>
                            📝 Your draft notes
                        </label>
                        <textarea
                            id={`note-${evidenceId}`}
                            ref={textareaRef}
                            className={styles.draft_textarea}
                            rows={3}
                            placeholder="Describe what you have, where it's held, and any gaps… (saves automatically)"
                            value={note}
                            onChange={handleNoteInput}
                            onBlur={handleNoteBlur}
                            data-gramm="false"
                            data-gramm_editor="false"
                            data-enable-grammarly="false"
                        />
                        <div className={styles.draft_footer}>
                            <span className={styles.char_count}>
                                {saving
                                    ? "Saving…"
                                    : savedChars > 0
                                        ? `${savedChars} chars saved ✓`
                                        : "Not yet saved"}
                            </span>
                            {note.trim().length >= 20 && (
                                sessionId && authToken ? (
                                    <button
                                        type="button"
                                        className={styles.assess_btn}
                                        onClick={handleAssess}
                                        disabled={assessing}
                                    >
                                        {assessing ? "Assessing…" : "Assess my draft →"}
                                    </button>
                                ) : (
                                    <a
                                        href="/auth/signup"
                                        className={styles.assess_btn}
                                        style={{ textDecoration: "none", display: "inline-block" }}
                                    >
                                        ✨ Get a free AI assessment of this evidence
                                    </a>
                                )
                            )}
                        </div>
                        {assessment && <AssessmentBadge assessment={assessment} />}
                    </div>
                </div>
            </div>
        </li>
    );
}
