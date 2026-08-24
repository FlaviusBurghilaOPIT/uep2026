import { translate } from '../i18n';

const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

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

  const cleanEndpoint = endpoint.startsWith('/') ? endpoint : `/${endpoint}`;
  const response = await fetch(`${BASE_URL}${cleanEndpoint}`, {
    ...options,
    headers,
  });

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
