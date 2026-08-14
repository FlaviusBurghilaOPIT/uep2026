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

export async function apiFetch<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const token = localStorage.getItem('token');
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string> || {}),
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const response = await fetch(`${BASE_URL}${endpoint}`, {
    ...options,
    headers,
  });

  // A 401 on the login endpoint itself means "bad credentials", not an expired
  // session — let the backend detail (e.g. "Invalid credentials") surface below
  // instead of hijacking it with the session-expired flow.
  const isLoginRequest = endpoint.includes('/auth/login');

  if (response.status === 401 && !isLoginRequest) {
    // Expired or invalid session on an authenticated call — force re-login
    localStorage.removeItem('token');
    localStorage.removeItem('role');
    localStorage.removeItem('email');
    if (window.location.pathname !== '/login') {
      window.location.href = '/login';
    }
    throw new ApiError(translate('auth.sessionExpired', 'Session expired. Please log in again.'), 401);
  }

  if (!response.ok) {
    const errorData = await response.json().catch(() => null);
    throw new ApiError(extractDetail(errorData, response.status), response.status);
  }

  return response.json();
}
