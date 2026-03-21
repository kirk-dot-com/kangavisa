// lib/admin-check.ts
// Server-side helper to read admin role from profiles table.
// Sprint 33 | admin_console_prd.md
//
// NOTE: Uses service role client for role lookup to bypass RLS.
// Auth identity is still verified via cookie session before the lookup.

import { createSupabaseServerClient } from "./supabase-server";
import { createClient } from "@supabase/supabase-js";
import { redirect } from "next/navigation";

export type AdminRole = "user" | "analyst" | "product_admin" | "super_admin" | "govdata_client";

const ADMIN_ROLES: AdminRole[] = ["super_admin", "analyst", "product_admin"];

function serviceClient() {
    const url = process.env.NEXT_PUBLIC_SUPABASE_URL!;
    const key = process.env.SUPABASE_SERVICE_ROLE_KEY!;
    return createClient(url, key, { auth: { persistSession: false } });
}

/**
 * Returns the authenticated user's role from the profiles table.
 * Uses service role to bypass RLS on the profiles table.
 * Returns null if unauthenticated or no profile found.
 */
export async function getAdminRole(): Promise<AdminRole | null> {
    try {
        const supabase = createSupabaseServerClient();
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return null;

        const { data: profile } = await serviceClient()
            .from("profiles")
            .select("role")
            .eq("id", user.id)
            .single();

        return (profile?.role as AdminRole) ?? null;
    } catch {
        return null;
    }
}

/**
 * Asserts the request is from an admin-role user.
 * - Redirects to /auth/login if not authenticated.
 * - Redirects to /pathway if role is not admin.
 * Call at the top of any admin Server Component or layout.
 */
export async function assertAdmin(): Promise<{ role: AdminRole }> {
    // Step 1: verify auth via cookie session
    const supabase = createSupabaseServerClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) redirect("/auth/login?next=/admin");

    // Step 2: read role via service role (bypasses RLS)
    const { data: profile } = await serviceClient()
        .from("profiles")
        .select("role")
        .eq("id", user.id)
        .single();

    const role = profile?.role as AdminRole;
    if (!role || !ADMIN_ROLES.includes(role)) redirect("/pathway");

    return { role };
}

/**
 * Returns true only if role is super_admin.
 */
export function isSuperAdmin(role: AdminRole): boolean {
    return role === "super_admin";
}
