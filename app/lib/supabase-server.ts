/**
 * supabase-server.ts — Cookie-based Supabase client for Server Components
 * Uses @supabase/ssr to read the session from Next.js cookies.
 * Server-only — never import in Client Components.
 */

import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

export function createSupabaseServerClient() {
    const cookieStore = cookies();
    return createServerClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
        {
            cookies: {
                get(name: string) {
                    return cookieStore.get(name)?.value;
                },
            },
        }
    );
}

/**
 * Returns the current authenticated user from the cookie session.
 * Returns null if unauthenticated or session expired.
 */
export async function getServerUser() {
    const supabase = createSupabaseServerClient();
    const {
        data: { user },
    } = await supabase.auth.getUser();
    return user;
}
