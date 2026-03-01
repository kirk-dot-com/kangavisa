// POST /api/sessions — get-or-create case_session for current user
// GET  /api/sessions?subclass=500&caseDate=2026-03-01 — return existing session
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

// Verify the bearer token from the request and return user_id
async function getUserId(req: NextRequest): Promise<string | null> {
    const token = req.headers.get("authorization")?.replace("Bearer ", "");
    if (!token) return null;
    const supabase = adminClient();
    const { data } = await supabase.auth.getUser(token);
    return data.user?.id ?? null;
}

export async function GET(req: NextRequest) {
    const userId = await getUserId(req);
    if (!userId) return NextResponse.json({ error: "Unauthorised" }, { status: 401 });

    const { searchParams } = new URL(req.url);
    const subclass = searchParams.get("subclass");
    const caseDate = searchParams.get("caseDate");
    if (!subclass || !caseDate) {
        return NextResponse.json({ error: "subclass and caseDate required" }, { status: 400 });
    }

    const supabase = adminClient();
    const { data, error } = await supabase
        .from("case_session")
        .select("*")
        .eq("user_id", userId)
        .eq("subclass_code", subclass)
        .eq("case_date", caseDate)
        .maybeSingle();

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ session: data });
}

export async function POST(req: NextRequest) {
    const userId = await getUserId(req);
    if (!userId) return NextResponse.json({ error: "Unauthorised" }, { status: 401 });

    const body = await req.json();
    const { subclass_code, case_date } = body;
    if (!subclass_code || !case_date) {
        return NextResponse.json({ error: "subclass_code and case_date required" }, { status: 400 });
    }

    const supabase = adminClient();
    const { data, error } = await supabase
        .from("case_session")
        .upsert(
            { user_id: userId, subclass_code, case_date, updated_at: new Date().toISOString() },
            { onConflict: "user_id,subclass_code,case_date" }
        )
        .select("*")
        .single();

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ session: data }, { status: 201 });
}
