import type { APIRoute } from 'astro'

export const prerender = false

function getBackendBaseUrl(): string {
  // 1. Check process.env (Node runtime in Docker container)
  if (typeof process !== 'undefined' && process.env) {
    if (process.env.INTERNAL_API_URL) return process.env.INTERNAL_API_URL.replace(/\/+$/, '')
    if (process.env.BACKEND_URL) return process.env.BACKEND_URL.replace(/\/+$/, '')
  }

  // 2. Check import.meta.env (Vite / Astro runtime)
  const metaEnv = import.meta.env
  if (metaEnv?.INTERNAL_API_URL) return metaEnv.INTERNAL_API_URL.replace(/\/+$/, '')
  if (metaEnv?.BACKEND_URL) return metaEnv.BACKEND_URL.replace(/\/+$/, '')

  if (typeof process !== 'undefined' && process.env?.VITE_API_URL && !process.env.VITE_API_URL.startsWith('/')) {
    return process.env.VITE_API_URL.replace(/\/+$/, '')
  }
  if (metaEnv?.VITE_API_URL && !metaEnv.VITE_API_URL.startsWith('/')) {
    return metaEnv.VITE_API_URL.replace(/\/+$/, '')
  }

  // Default fallback for docker container if no env provided, or localhost for local dev
  return 'http://backend:8000'
}

export const ALL: APIRoute = async ({ request, params, url }) => {
  const backendBase = getBackendBaseUrl()
  const subPath = params.path ? `/${params.path}` : ''
  const search = url.search || ''
  const targetUrl = `${backendBase}${subPath}${search}`

  const headers = new Headers()
  request.headers.forEach((value, key) => {
    const lowerKey = key.toLowerCase()
    // Skip hop-by-hop and host/content-length headers so fetch sets them properly
    if (lowerKey !== 'host' && lowerKey !== 'connection' && lowerKey !== 'content-length') {
      headers.set(key, value)
    }
  })

  const method = request.method
  const hasBody = method !== 'GET' && method !== 'HEAD'
  let body: ArrayBuffer | null = null
  if (hasBody) {
    try {
      body = await request.arrayBuffer()
    } catch {
      body = null
    }
  }

  try {
    const backendRes = await fetch(targetUrl, {
      method,
      headers,
      body: hasBody && body && body.byteLength > 0 ? body : undefined,
      redirect: 'manual',
    })

    const responseHeaders = new Headers()
    backendRes.headers.forEach((value, key) => {
      responseHeaders.set(key, value)
    })

    return new Response(backendRes.body, {
      status: backendRes.status,
      statusText: backendRes.statusText,
      headers: responseHeaders,
    })
  } catch (err: any) {
    // If backend:8000 fails (e.g. running locally outside Docker), attempt fallback to localhost:8000
    if (backendBase.includes('backend:8000')) {
      const fallbackUrl = `http://localhost:8000${subPath}${search}`
      try {
        const backendRes = await fetch(fallbackUrl, {
          method,
          headers,
          body: hasBody && body && body.byteLength > 0 ? body : undefined,
          redirect: 'manual',
        })

        const responseHeaders = new Headers()
        backendRes.headers.forEach((value, key) => {
          responseHeaders.set(key, value)
        })

        return new Response(backendRes.body, {
          status: backendRes.status,
          statusText: backendRes.statusText,
          headers: responseHeaders,
        })
      } catch {
        // Fall through to error response below
      }
    }

    console.error(`[API Proxy Error] Failed to proxy ${method} ${targetUrl}:`, err?.message || err)
    return new Response(
      JSON.stringify({
        detail: `Backend proxy connection failed: ${err?.message || 'Unable to reach backend service'}`,
        target: targetUrl,
      }),
      {
        status: 502,
        headers: { 'Content-Type': 'application/json' },
      }
    )
  }
}
