// lib/supabase/server.ts
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createSupabaseServerClient() {
  const cookieStore = await cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return cookieStore.get(name)?.value
        },
        set(name: string, value: string, options: any) {
          try {
            // maxAge ve expires değerlerini silerek çerezi 'session cookie' haline getiriyoruz.
            // Bu, uygulama/tarayıcı kapandığında oturumun sonlanmasını sağlar.
            const { maxAge, expires, ...sessionOptions } = options
            cookieStore.set({ name, value, ...sessionOptions })
          } catch (error) {
            // Can be ignored if called from a Server Component
          }
        },
        remove(name: string, options: any) {
          try {
            cookieStore.set({ name, value: '', ...options })
          } catch (error) {
            // Can be ignored if called from a Server Component
          }
        },
      },
    }
  )
}

// Service Role client — for internal logic that needs to bypass RLS
export function createSupabaseServiceClient() {
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    {
      cookies: {
        get() {
          return undefined
        },
        set() {
          return undefined
        },
        remove() {
          return undefined
        },
      },
    }
  )
}
