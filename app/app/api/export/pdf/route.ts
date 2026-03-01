// GET /api/export/pdf?subclass=500&caseDate=2026-03-01
// US-D1 — Server-side PDF generation via @react-pdf/renderer

import { NextRequest } from "next/server";
import { getKBPackage } from "../../../../lib/kb-service";
import { buildExportPayload, type ChecklistItemState } from "../../../../lib/export-builder";
import { createClient } from "@supabase/supabase-js";
import ReactPDF from "@react-pdf/renderer";
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore — ExportPDFDocument uses react-pdf JSX which tsc cannot type-check in Next.js tsconfig
import { ExportPDFDocument } from "../../components/ExportPDFDocument";

function adminClient() {
    return createClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.SUPABASE_SERVICE_ROLE_KEY!,
        { auth: { persistSession: false } }
    );
}

const VISA_NAMES: Record<string, string> = {
    "500": "Student visa (subclass 500)",
    "485": "Temporary Graduate (subclass 485)",
    "482": "Employer Sponsored (subclass 482 / SID)",
    "417": "Working Holiday (subclass 417)",
    "820": "Partner visa (subclass 820 / 309)",
};

export const runtime = "nodejs";

export async function GET(req: NextRequest) {
    const { searchParams } = new URL(req.url);
    const subclass = searchParams.get("subclass") ?? "500";
    const caseDateStr = searchParams.get("caseDate") ?? new Date().toISOString().split("T")[0];
    const caseDate = new Date(caseDateStr);

    const pkg = await getKBPackage(subclass, caseDate);
    const visaName = VISA_NAMES[subclass] ?? `Subclass ${subclass}`;

    // Load saved item states if authenticated
    let itemStates: ChecklistItemState[] = [];
    const token = req.headers.get("authorization")?.replace("Bearer ", "");
    if (token) {
        const { data: user } = await adminClient().auth.getUser(token);
        if (user.user) {
            const { data: session } = await adminClient()
                .from("case_session")
                .select("session_id")
                .eq("user_id", user.user.id)
                .eq("subclass_code", subclass)
                .eq("case_date", caseDateStr)
                .maybeSingle();
            if (session) {
                const { data: items } = await adminClient()
                    .from("checklist_item_state")
                    .select("evidence_id, status, note")
                    .eq("session_id", session.session_id);
                itemStates = (items ?? []) as ChecklistItemState[];
            }
        }
    }

    if (itemStates.length === 0) {
        itemStates = pkg.evidenceItems.map((e) => ({
            evidence_id: e.evidence_id,
            status: "not_started" as const,
            note: null,
        }));
    }

    const payload = buildExportPayload(pkg, itemStates, visaName, subclass);

    try {
        const buffer = await ReactPDF.renderToBuffer(ExportPDFDocument({ payload }));
        // Wrap in Uint8Array for BodyInit compatibility
        const body = new Uint8Array(buffer);

        const filename = `kangavisa-pack-${subclass}-${caseDateStr}.pdf`;
        return new Response(body, {
            headers: {
                "Content-Type": "application/pdf",
                "Content-Disposition": `attachment; filename="${filename}"`,
            },
        });
    } catch (err: unknown) {
        console.error("PDF render error:", err);
        return new Response("PDF generation failed — check server logs.", { status: 500 });
    }
}
