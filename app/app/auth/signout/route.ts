// app/auth/signout/route.ts
// POST /auth/signout — signs out the current user and redirects to home
// US-G1 — auth flow completion

import { NextRequest, NextResponse } from "next/server";
import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

export async function POST(req: NextRequest) {
    const cookieStore = cookies();

    const supabase = createServerClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
        {
            cookies: {
                get(name: string) {
                    return cookieStore.get(name)?.value;
                },
                set(name: string, value: string, options) {
                    cookieStore.set({ name, value, ...options });
                },
                remove(name: string, options) {
                    cookieStore.set({ name, value: "", ...options });
                },
            },
        }
    );

    await supabase.auth.signOut();
    return NextResponse.redirect(new URL("/", req.url));
}

// Also handle GET for simple link-based sign-outs (e.g., <a href="/auth/signout">)
export async function GET(req: NextRequest) {
    return POST(req);
}
