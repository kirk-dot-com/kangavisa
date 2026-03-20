// middleware.ts — refreshes Supabase auth session on every request
// Without this, server components see stale/null sessions after sign-in.
// See: https://supabase.com/docs/guides/auth/server-side/nextjs

import { createServerClient } from "@supabase/ssr";
import { NextRequest, NextResponse } from "next/server";

export async function middleware(req: NextRequest) {
    let response = NextResponse.next({ request: req });

    const supabase = createServerClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
        {
            cookies: {
                get(name: string) {
                    return req.cookies.get(name)?.value;
                },
                set(name: string, value: string, options) {
                    req.cookies.set({ name, value, ...options });
                    response = NextResponse.next({ request: req });
                    response.cookies.set({ name, value, ...options });
                },
                remove(name: string, options) {
                    req.cookies.set({ name, value: "", ...options });
                    response = NextResponse.next({ request: req });
                    response.cookies.set({ name, value: "", ...options });
                },
            },
        }
    );

    // Refresh session — writes updated cookie to the response
    await supabase.auth.getUser();

    return response;
}

export const config = {
    matcher: [
        // Run on all routes except static files and Next.js internals
        "/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
    ],
};
