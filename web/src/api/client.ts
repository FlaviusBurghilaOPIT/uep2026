import { translate } from '../i18n';

export function getBaseUrl(): string {
  // 1. SSR / Server-side Node runtime:
  if (typeof window === 'undefined') {
    if (typeof process !== 'undefined' && process.env) {
      if (process.env.INTERNAL_API_URL) return process.env.INTERNAL_API_URL.replace(/\/+$/, '');
      if (process.env.BACKEND_URL) return process.env.BACKEND_URL.replace(/\/+$/, '');
    }
    const metaEnv = import.meta.env;
    if (metaEnv?.INTERNAL_API_URL) return metaEnv.INTERNAL_API_URL.replace(/\/+$/, '');
    if (metaEnv?.BACKEND_URL) return metaEnv.BACKEND_URL.replace(/\/+$/, '');
    if (typeof process !== 'undefined' && process.env?.VITE_API_URL && !process.env.VITE_API_URL.startsWith('/')) {
      return process.env.VITE_API_URL.replace(/\/+$/, '');
    }
    if (metaEnv?.VITE_API_URL && !metaEnv.VITE_API_URL.startsWith('/')) {
      return metaEnv.VITE_API_URL.replace(/\/+$/, '');
    }
    return 'http://backend:8000';
  }

  // 2. Client-side browser runtime:
  const envUrl = import.meta.env.VITE_API_URL;
  if (envUrl && !envUrl.includes('localhost:8000') && !envUrl.includes('backend:8000')) {
    return envUrl.replace(/\/+$/, '');
  }

  // In browser, route requests through relative /api proxy
  return '/api';
}

export const BASE_URL = getBaseUrl();

export class ApiError extends Error {
  status: number;

  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

function extractDetail(errorData: unknown, status: number): string {
  if (errorData && typeof errorData === 'object' && 'detail' in errorData) {
    const detail = (errorData as { detail: unknown }).detail;
    // FastAPI validation errors arrive as an array of {loc, msg} objects
    if (Array.isArray(detail)) {
      return detail
        .map((d) => (d && typeof d === 'object' && 'msg' in d ? String((d as { msg: unknown }).msg) : String(d)))
        .join(' ');
    }
    if (typeof detail === 'string') return detail;
  }
  return `Request failed with status ${status}`;
}

export interface ApiFetchOptions extends RequestInit {
  token?: string;
}

function getCookie(name: string): string | undefined {
  if (typeof document === 'undefined') return undefined;
  const match = document.cookie.match(new RegExp('(^| )' + name + '=([^;]+)'));
  return match ? decodeURIComponent(match[2]) : undefined;
}

export async function apiFetch<T>(endpoint: string, options: ApiFetchOptions = {}): Promise<T> {
  let token = options.token;
  if (!token && typeof window !== 'undefined') {
    token = getCookie('carepro_token') || localStorage.getItem('token') || undefined;
  }

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string> || {}),
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const baseUrl = getBaseUrl();
  const cleanEndpoint = endpoint.startsWith('/') ? endpoint : `/${endpoint}`;
  const targetUrl = baseUrl.endsWith('/api') && cleanEndpoint.startsWith('/api/')
    ? `${baseUrl.slice(0, -4)}${cleanEndpoint}`
    : `${baseUrl}${cleanEndpoint}`;

  let response: Response;
  try {
    response = await fetch(targetUrl, {
      ...options,
      headers,
    });
  } catch (err: any) {
    // SSR Fallback: If connecting to backend:8000 failed in SSR (e.g. running outside Docker), try localhost:8000
    if (typeof window === 'undefined' && targetUrl.includes('backend:8000')) {
      const fallbackUrl = targetUrl.replace('backend:8000', 'localhost:8000');
      try {
        response = await fetch(fallbackUrl, {
          ...options,
          headers,
        });
      } catch {
        throw new ApiError(`Network request to ${targetUrl} failed: ${err?.message || err}`, 500);
      }
    } else {
      throw new ApiError(`Network request to ${targetUrl} failed: ${err?.message || err}`, 500);
    }
  }

  const isLoginRequest = endpoint.includes('/auth/login');

  if (response.status === 401 && !isLoginRequest) {
    if (typeof window !== 'undefined') {
      localStorage.removeItem('token');
      localStorage.removeItem('role');
      localStorage.removeItem('email');
      document.cookie = 'carepro_token=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT';
      if (window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
    }
    throw new ApiError(translate('auth.sessionExpired', 'Session expired. Please log in again.'), 401);
  }

  if (!response.ok) {
    const errorData = await response.json().catch(() => null);
    throw new ApiError(extractDetail(errorData, response.status), response.status);
  }

  return response.json();
}
