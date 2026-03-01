// GET  /api/sessions/[sessionId]/items — load all checklist item states
// PATCH /api/sessions/[sessionId]/items — upsert one item's status + note
// US-B3, US-B4

import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";

function adminClient() {
    return createClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.SUPABASE_SERVICE_ROLE_KEY!,
        { auth: { persistSession: false } }
    );
}

async function getUserId(req: NextRequest): Promise<string | null> {
    const token = req.headers.get("authorization")?.replace("Bearer ", "");
    if (!token) return null;
    const { data } = await adminClient().auth.getUser(token);
    return data.user?.id ?? null;
}

async function validateSessionOwnership(
    sessionId: string,
    userId: string
): Promise<boolean> {
    const { data } = await adminClient()
        .from("case_session")
        .select("session_id")
        .eq("session_id", sessionId)
        .eq("user_id", userId)
        .maybeSingle();
    return !!data;
}

interface RouteContext {
    params: { sessionId: string };
}

export async function GET(req: NextRequest, { params }: RouteContext) {
    const userId = await getUserId(req);
    if (!userId) return NextResponse.json({ error: "Unauthorised" }, { status: 401 });

    const ok = await validateSessionOwnership(params.sessionId, userId);
    if (!ok) return NextResponse.json({ error: "Session not found" }, { status: 404 });

    const { data, error } = await adminClient()
        .from("checklist_item_state")
        .select("*")
        .eq("session_id", params.sessionId)
        .order("updated_at", { ascending: false });

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ items: data ?? [] });
}

export async function PATCH(req: NextRequest, { params }: RouteContext) {
    const userId = await getUserId(req);
    if (!userId) return NextResponse.json({ error: "Unauthorised" }, { status: 401 });

    const ok = await validateSessionOwnership(params.sessionId, userId);
    if (!ok) return NextResponse.json({ error: "Session not found" }, { status: 404 });

    const body = await req.json();
    const { evidence_id, status, note } = body;

    const VALID_STATUSES = ["not_started", "in_progress", "done", "na"];
    if (!evidence_id || !VALID_STATUSES.includes(status)) {
        return NextResponse.json(
            { error: `evidence_id required and status must be one of: ${VALID_STATUSES.join(", ")}` },
            { status: 400 }
        );
    }

    const { data, error } = await adminClient()
        .from("checklist_item_state")
        .upsert(
            {
                session_id: params.sessionId,
                evidence_id,
                status,
                note: note ?? null,
                updated_at: new Date().toISOString(),
            },
            { onConflict: "session_id,evidence_id" }
        )
        .select("*")
        .single();

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ item: data });
}
