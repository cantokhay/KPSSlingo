import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({
    request,
  })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) => request.cookies.set(name, value))
          supabaseResponse = NextResponse.next({
            request,
          })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  const {
    data: { user },
  } = await supabase.auth.getUser()

  // Sadece /dashboard altında olan yolları koruyalım
  if (request.nextUrl.pathname.startsWith('/dashboard')) {
    if (!user) {
      const url = request.nextUrl.clone()
      url.pathname = '/login'
      return NextResponse.redirect(url)
    }

    // Rol kontrolü: Session'daki rollerin geçerliliğini kontrol etmek için
    // user_roles tablosuna da bakabiliriz veya metadata'yı da kontrol edebiliriz.
    // Ancak user_metadata güvensiz olduğu için middleware'de user_roles'a service role ile bakabiliriz.
    // Veya app_metadata kullanabiliriz.
    const isSuperAdmin = user.user_metadata?.role === 'superadmin';
    const isAdmin = user.user_metadata?.role === 'admin';
    
    // Güvenliği arttırmak için veritabanında da rolu kontrol ediyoruz.
    const { data: roleData } = await supabase
      .from('user_roles')
      .select('role')
      .eq('user_id', user.id)
      .single()

    const dbRole = roleData?.role;

    if (dbRole !== 'admin' && dbRole !== 'superadmin') {
      const url = request.nextUrl.clone()
      url.pathname = '/login'
      url.searchParams.set('error', 'unauthorized')
      return NextResponse.redirect(url)
    }
  }

  // /login veya /register sayfalarında oturumu varsa geri at
  if (
    request.nextUrl.pathname.startsWith('/login') ||
    request.nextUrl.pathname.startsWith('/register')
  ) {
    if (user) {
      const { data: roleData } = await supabase
        .from('user_roles')
        .select('role')
        .eq('user_id', user.id)
        .single()
      
      const dbRole = roleData?.role;
      if (dbRole === 'superadmin' || dbRole === 'admin') {
        const url = request.nextUrl.clone()
        url.pathname = '/dashboard'
        return NextResponse.redirect(url)
      }
    }
  }

  return supabaseResponse
}
