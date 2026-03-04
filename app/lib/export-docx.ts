/**
 * export-docx.ts — DOCX export builder
 * US-D1 | Brand Guidelines §9.5
 *
 * Generates a branded .docx readiness pack using the `docx` library.
 * Server-side only — import only in API routes.
 *
 * Document structure:
 *   1. Cover: visa name, subclass, case date, pack version
 *   2. Assumptions
 *   3. Requirements summary (table)
 *   4. Top risk flags (table)
 *   5. Evidence checklist (table: label, status, note)
 *   6. Disclaimer footer
 */

import {
    Document,
    Packer,
    Paragraph,
    Table,
    TableRow,
    TableCell,
    TextRun,
    HeadingLevel,
    AlignmentType,
    WidthType,
    BorderStyle,
    ShadingType,
    VerticalAlign,
    PageBreak,
} from "docx";
import type { ExportPayload } from "./export-builder";

// ---------------------------------------------------------------------------
// Brand colours (as hex integers for docx)
// ---------------------------------------------------------------------------
const NAVY = "0B1F3B";
const GOLD = "C9902A";
const WHITE = "FFFFFF";
const LIGHT = "F4F6F9";
const MUTED = "4A5568";

// ---------------------------------------------------------------------------
// Helper primitives
// ---------------------------------------------------------------------------

function heading(text: string, level: (typeof HeadingLevel)[keyof typeof HeadingLevel] = HeadingLevel.HEADING_2): Paragraph {
    return new Paragraph({
        text,
        heading: level,
        spacing: { before: 280, after: 120 },
        run: { color: NAVY, bold: true },
    });
}



function noBorder() {
    return {
        top: { style: BorderStyle.NONE, size: 0, color: "auto" },
        bottom: { style: BorderStyle.NONE, size: 0, color: "auto" },
        left: { style: BorderStyle.NONE, size: 0, color: "auto" },
        right: { style: BorderStyle.NONE, size: 0, color: "auto" },
    };
}

function thinBorder() {
    return {
        top: { style: BorderStyle.SINGLE, size: 4, color: "D1D9E0" },
        bottom: { style: BorderStyle.SINGLE, size: 4, color: "D1D9E0" },
        left: { style: BorderStyle.SINGLE, size: 4, color: "D1D9E0" },
        right: { style: BorderStyle.SINGLE, size: 4, color: "D1D9E0" },
    };
}

function headerCell(text: string): TableCell {
    return new TableCell({
        children: [new Paragraph({
            children: [new TextRun({ text, bold: true, color: WHITE, size: 20 })],
        })],
        borders: noBorder(),
        shading: { type: ShadingType.SOLID, color: NAVY, fill: NAVY },
        verticalAlign: VerticalAlign.CENTER,
        margins: { top: 80, bottom: 80, left: 120, right: 120 },
    });
}

function dataCell(text: string, shade = false): TableCell {
    return new TableCell({
        children: [new Paragraph({
            children: [new TextRun({ text: text || "—", color: MUTED, size: 20 })],
        })],
        borders: thinBorder(),
        shading: shade
            ? { type: ShadingType.SOLID, color: LIGHT, fill: LIGHT }
            : undefined,
        verticalAlign: VerticalAlign.CENTER,
        margins: { top: 60, bottom: 60, left: 120, right: 120 },
    });
}

// ---------------------------------------------------------------------------
// Section builders
// ---------------------------------------------------------------------------

function buildCoverSection(payload: ExportPayload): Paragraph[] {
    return [
        new Paragraph({
            children: [new TextRun({ text: "KangaVisa", bold: true, color: GOLD, size: 56 })],
            alignment: AlignmentType.CENTER,
            spacing: { before: 400, after: 120 },
        }),
        new Paragraph({
            children: [new TextRun({ text: "Readiness Pack", bold: true, color: NAVY, size: 44 })],
            alignment: AlignmentType.CENTER,
            spacing: { after: 80 },
        }),
        new Paragraph({
            children: [new TextRun({ text: payload.visa_name, color: MUTED, size: 28 })],
            alignment: AlignmentType.CENTER,
            spacing: { after: 80 },
        }),
        new Paragraph({
            children: [new TextRun({ text: `Case date: ${payload.case_date}`, color: MUTED, size: 22 })],
            alignment: AlignmentType.CENTER,
            spacing: { after: 80 },
        }),
        new Paragraph({
            children: [new TextRun({ text: `Pack version: ${payload.pack_version}`, color: MUTED, size: 20 })],
            alignment: AlignmentType.CENTER,
            spacing: { after: 80 },
        }),
        new Paragraph({
            children: [new TextRun({ text: `Generated: ${new Date(payload.export_date).toLocaleDateString("en-AU")}`, color: MUTED, size: 20 })],
            alignment: AlignmentType.CENTER,
            spacing: { after: 600 },
        }),
        new Paragraph({ children: [new PageBreak()] }),
    ];
}

function buildAssumptionsSection(payload: ExportPayload): (Paragraph)[] {
    return [
        heading("Case Assumptions", HeadingLevel.HEADING_1),
        ...payload.assumptions.map((a) =>
            new Paragraph({
                children: [new TextRun({ text: `• ${a}`, color: MUTED, size: 22 })],
                spacing: { after: 60 },
                indent: { left: 240 },
            })
        ),
        new Paragraph({ spacing: { after: 200 } }),
    ];
}

function buildRequirementsTable(payload: ExportPayload): (Paragraph | Table)[] {
    if (payload.requirements_summary.length === 0) return [];
    const rows = [
        new TableRow({
            children: [
                headerCell("Type"),
                headerCell("Requirement"),
                headerCell("Plain English"),
                headerCell("Citation"),
            ],
            tableHeader: true,
        }),
        ...payload.requirements_summary.map((r, i) =>
            new TableRow({
                children: [
                    dataCell(r.type, i % 2 === 1),
                    dataCell(r.title, i % 2 === 1),
                    dataCell(r.plain_english, i % 2 === 1),
                    dataCell(r.citation ?? "", i % 2 === 1),
                ],
            })
        ),
    ];

    return [
        heading("Requirements Summary", HeadingLevel.HEADING_1),
        new Table({
            rows,
            width: { size: 100, type: WidthType.PERCENTAGE },
        }),
        new Paragraph({ spacing: { after: 200 } }),
    ];
}

function buildFlagsTable(payload: ExportPayload): (Paragraph | Table)[] {
    if (payload.top_flags.length === 0) return [];
    const rows = [
        new TableRow({
            children: [
                headerCell("Severity"),
                headerCell("Flag"),
                headerCell("Why it matters"),
            ],
            tableHeader: true,
        }),
        ...payload.top_flags.map((f, i) =>
            new TableRow({
                children: [
                    dataCell(f.severity.toUpperCase(), i % 2 === 1),
                    dataCell(f.title, i % 2 === 1),
                    dataCell(f.why_it_matters, i % 2 === 1),
                ],
            })
        ),
    ];

    return [
        heading("Risk Flags", HeadingLevel.HEADING_1),
        new Table({
            rows,
            width: { size: 100, type: WidthType.PERCENTAGE },
        }),
        new Paragraph({ spacing: { after: 200 } }),
    ];
}

function buildEvidenceTable(payload: ExportPayload): (Paragraph | Table)[] {
    if (payload.item_states.length === 0) return [];

    // Build a lookup from the requirements_summary for labels
    // (item_states carry evidence_id; we match via evidenceItems in payload)
    const rows = [
        new TableRow({
            children: [
                headerCell("Evidence item"),
                headerCell("Status"),
                headerCell("Note"),
            ],
            tableHeader: true,
        }),
        ...payload.item_states.map((s, i) =>
            new TableRow({
                children: [
                    dataCell(s.evidence_id, i % 2 === 1),
                    dataCell(s.status.replace("_", " "), i % 2 === 1),
                    dataCell(s.note ?? "", i % 2 === 1),
                ],
            })
        ),
    ];

    return [
        heading("Evidence Checklist", HeadingLevel.HEADING_1),
        new Table({
            rows,
            width: { size: 100, type: WidthType.PERCENTAGE },
        }),
        new Paragraph({ spacing: { after: 200 } }),
    ];
}

function buildDisclaimerSection(payload: ExportPayload): Paragraph[] {
    return [
        new Paragraph({ children: [new PageBreak()] }),
        heading("Disclaimer", HeadingLevel.HEADING_2),
        new Paragraph({
            children: [new TextRun({ text: payload.disclaimer, color: MUTED, size: 18, italics: true })],
            spacing: { after: 120 },
        }),
    ];
}

// ---------------------------------------------------------------------------
// Main export
// ---------------------------------------------------------------------------

export async function buildDocx(payload: ExportPayload): Promise<Buffer> {
    const doc = new Document({
        creator: "KangaVisa",
        title: `${payload.visa_name} — Readiness Pack`,
        description: `KangaVisa readiness pack for ${payload.visa_name}, case date ${payload.case_date}`,
        styles: {
            default: {
                document: {
                    run: { font: "Calibri", size: 22, color: MUTED },
                },
            },
        },
        sections: [
            {
                properties: {
                    page: {
                        margin: { top: 1000, bottom: 1000, left: 1200, right: 1200 },
                    },
                },
                children: [
                    ...buildCoverSection(payload),
                    ...buildAssumptionsSection(payload),
                    ...buildRequirementsTable(payload),
                    ...buildFlagsTable(payload),
                    ...buildEvidenceTable(payload),
                    ...buildDisclaimerSection(payload),
                ],
            },
        ],
    });

    return Packer.toBuffer(doc);
}
