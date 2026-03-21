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
    const { data: { user } } = await supabase.auth.getUser();

    // Auth gate: /checklist/[subclass] except 600 requires sign-in
    const pathname = req.nextUrl.pathname;
    const checklistMatch = pathname.match(/^\/checklist\/(\w+)/);
    if (checklistMatch) {
        const subclass = checklistMatch[1];
        if (subclass === "600") {
            // Intake gate: must complete /visitor survey before accessing 600 checklist
            const intakeDone = req.cookies.get("kv_intake_done")?.value;
            if (!intakeDone) {
                const visitorUrl = new URL("/visitor", req.url);
                visitorUrl.searchParams.set("next", pathname);
                return NextResponse.redirect(visitorUrl);
            }
        } else if (!user) {
            // Non-600 subclasses require auth
            const loginUrl = new URL("/auth/login", req.url);
            loginUrl.searchParams.set("next", pathname);
            return NextResponse.redirect(loginUrl);
        }
    }

    return response;
}

export const config = {
    matcher: [
        // Run on all routes except static files and Next.js internals
        "/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
    ],
};
