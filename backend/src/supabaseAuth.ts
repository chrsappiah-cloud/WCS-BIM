import { createClient, type SupabaseClient } from "@supabase/supabase-js";

let authClient: SupabaseClient | undefined;

const supabaseURL = () => process.env.NEXT_PUBLIC_SUPABASE_URL ?? process.env.SUPABASE_URL;
const supabaseAnonKey = () => process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? process.env.SUPABASE_ANON_KEY;

export const isSupabaseAuthConfigured = () => Boolean(supabaseURL() && supabaseAnonKey());

export const getSupabaseAuthClient = () => {
  if (authClient) return authClient;

  const url = supabaseURL();
  const anonKey = supabaseAnonKey();
  if (!url || !anonKey) {
    throw new Error("Supabase Auth requires SUPABASE_URL and SUPABASE_ANON_KEY.");
  }

  authClient = createClient(url, anonKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
  return authClient;
};

export async function signInWithEmail(email: string, password: string) {
  return getSupabaseAuthClient().auth.signInWithPassword({ email, password });
}

export async function signOut() {
  return getSupabaseAuthClient().auth.signOut();
}

export async function userIDForAccessToken(accessToken: string) {
  const { data, error } = await getSupabaseAuthClient().auth.getUser(accessToken);
  if (error || !data.user) {
    throw error ?? new Error("Supabase access token has no user.");
  }
  return data.user.id;
}
