/**
 * supabase.ts — Cookie-aware browser-side Supabase client
 * Uses @supabase/ssr createBrowserClient which stores sessions in cookies
 * so that Server Components (e.g. AppHeader) can read the auth state.
 * Safe to use in Client Components.
 */

import { createBrowserClient } from "@supabase/ssr";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL ?? "";
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? "";

/**
 * Factory — returns a cookie-aware browser-side client.
 * Use in Client Components for auth operations.
 */
export function createClient() {
    return createBrowserClient(supabaseUrl, supabaseAnonKey);
}

/**
 * Singleton for non-auth reads in Client Components.
 */
export const supabase = createBrowserClient(supabaseUrl, supabaseAnonKey);
