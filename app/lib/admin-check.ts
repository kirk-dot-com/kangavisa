// lib/admin-check.ts
// Server-side helper to read admin role from profiles table.
// Sprint 33 | admin_console_prd.md

import { createSupabaseServerClient } from "./supabase-server";
import { redirect } from "next/navigation";

export type AdminRole = "user" | "analyst" | "product_admin" | "super_admin" | "govdata_client";

const ADMIN_ROLES: AdminRole[] = ["super_admin", "analyst", "product_admin"];

/**
 * Returns the authenticated user's role from the profiles table.
 * Returns null if unauthenticated or no profile found.
 */
export async function getAdminRole(): Promise<AdminRole | null> {
    try {
        const supabase = createSupabaseServerClient();
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) return null;

        const { data: profile } = await supabase
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
 * Redirects to login if unauthenticated, /pathway if insufficient role.
 * Call at the top of any admin Server Component.
 */
export async function assertAdmin(): Promise<{ role: AdminRole }> {
    try {
        const supabase = createSupabaseServerClient();
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) redirect("/auth/login?next=/admin");

        const { data: profile } = await supabase
            .from("profiles")
            .select("role")
            .eq("id", user.id)
            .single();

        const role = profile?.role as AdminRole;
        if (!role || !ADMIN_ROLES.includes(role)) redirect("/pathway");

        return { role };
    } catch (err) {
        // If it's a redirect, re-throw
        throw err;
    }
}

/**
 * Returns true only if role is super_admin.
 */
export function isSuperAdmin(role: AdminRole): boolean {
    return role === "super_admin";
}
