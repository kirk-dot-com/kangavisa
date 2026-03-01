import { createClient as _createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL ?? ''
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? ''

/**
 * Browser-side Supabase client singleton.
 * Uses the anon key — subject to RLS policies.
 * Safe to use in Client Components.
 */
export const supabase = _createClient(supabaseUrl, supabaseAnonKey)

/**
 * Factory — returns a fresh browser-side client.
 * Use in Client Components that cannot import the singleton
 * (e.g. auth pages using useRouter hooks).
 */
export function createClient() {
    return _createClient(supabaseUrl, supabaseAnonKey)
}
