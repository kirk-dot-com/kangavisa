// POST /api/sessions/[sessionId]/items/[evidenceId]/assess
// Sprint 27 P2 — AI assessment of a draft note

import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import OpenAI from "openai";

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

async function validateSessionOwnership(sessionId: string, userId: string): Promise<boolean> {
    const { data } = await adminClient()
        .from("case_session")
        .select("session_id")
        .eq("session_id", sessionId)
        .eq("user_id", userId)
        .maybeSingle();
    return !!data;
}

interface RouteContext {
    params: { sessionId: string; evidenceId: string };
}

export async function POST(req: NextRequest, { params }: RouteContext) {
    const userId = await getUserId(req);
    if (!userId) return NextResponse.json({ error: "Unauthorised" }, { status: 401 });

    const ok = await validateSessionOwnership(params.sessionId, userId);
    if (!ok) return NextResponse.json({ error: "Session not found" }, { status: 404 });

    const body = await req.json();
    const { draft_content, evidence_label, what_it_proves } = body;

    if (!draft_content || draft_content.trim().length < 10) {
        return NextResponse.json({ error: "draft_content must be at least 10 characters" }, { status: 400 });
    }

    const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

    const systemPrompt = `You are a migration agent reviewing a visa applicant's draft evidence note.
You assess whether the described evidence is sufficient for an Australian visa application.
Return a JSON object with exactly these fields:
{
  "rating": "Weak" | "Adequate" | "Strong",
  "summary": "<one sentence summary of the assessment>",
  "gaps": ["<gap 1>", "<gap 2>"] // up to 3 specific gaps or suggestions, empty array if Strong
}

Rating criteria:
- Strong: Evidence is specific, well-documented, and directly addresses the requirement. No gaps.
- Adequate: Evidence is present but could be stronger (missing dates, certifications, or specifics).
- Weak: Evidence is vague, incomplete, or missing key elements.`;

    const userPrompt = `Evidence item: "${evidence_label}"
What it proves: ${what_it_proves}

Applicant's draft notes:
"${draft_content}"

Assess this draft.`;

    try {
        const completion = await openai.chat.completions.create({
            model: "gpt-4o-mini",
            messages: [
                { role: "system", content: systemPrompt },
                { role: "user", content: userPrompt },
            ],
            response_format: { type: "json_object" },
            temperature: 0.3,
            max_tokens: 300,
        });

        const raw = completion.choices[0]?.message?.content ?? "{}";
        const assessment = JSON.parse(raw) as {
            rating: "Weak" | "Adequate" | "Strong";
            summary: string;
            gaps: string[];
        };

        // Validate rating
        if (!["Weak", "Adequate", "Strong"].includes(assessment.rating)) {
            assessment.rating = "Adequate";
        }

        // Persist assessment to DB
        await adminClient()
            .from("checklist_item_state")
            .upsert(
                {
                    session_id: params.sessionId,
                    evidence_id: params.evidenceId,
                    draft_content,
                    assessment_json: assessment,
                    assessed_at: new Date().toISOString(),
                    updated_at: new Date().toISOString(),
                },
                { onConflict: "session_id,evidence_id" }
            );

        return NextResponse.json({ assessment });
    } catch (err) {
        console.error("[assess] Error:", err);
        return NextResponse.json({ error: "Assessment failed" }, { status: 500 });
    }
}
