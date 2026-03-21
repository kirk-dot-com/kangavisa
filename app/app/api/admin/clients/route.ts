// /api/admin/clients — GovData client management: list + create
// Service role only. Sprint 33.

import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";

export const dynamic = "force-dynamic";

function adminClient() {
    const url = process.env.NEXT_PUBLIC_SUPABASE_URL!;
    const key = process.env.SUPABASE_SERVICE_ROLE_KEY!;
    return createClient(url, key, { auth: { persistSession: false } });
}

export async function GET() {
    try {
        const supabase = adminClient();
        const { data, error } = await supabase
            .from("client_accounts")
            .select("id, name, tier, contact_email, notes, active, created_at")
            .order("created_at", { ascending: false });

        if (error) throw error;
        return NextResponse.json({ clients: data ?? [] });
    } catch (err) {
        console.error("[GET /api/admin/clients]", err);
        return NextResponse.json({ error: "internal" }, { status: 500 });
    }
}

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();
        const { name, tier, contact_email, notes } = body;

        if (!name || !tier) {
            return NextResponse.json({ error: "name and tier required" }, { status: 400 });
        }

        const supabase = adminClient();

        const { data, error } = await supabase
            .from("client_accounts")
            .insert({ name, tier, contact_email: contact_email ?? null, notes: notes ?? null })
            .select()
            .single();

        if (error) throw error;

        // Audit log
        await supabase.from("audit_logs").insert({
            action: "client_created",
            metadata: { client_id: data.id, name, tier },
        });

        return NextResponse.json({ client: data }, { status: 201 });
    } catch (err) {
        console.error("[POST /api/admin/clients]", err);
        return NextResponse.json({ error: "internal" }, { status: 500 });
    }
}
