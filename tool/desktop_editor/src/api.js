// Thin client for the editor API (backend/src/modules/report-editing). Cookie + CSRF header, no tokens in URLs.

const BASE = import.meta.env.VITE_API_BASE || '/api/v1';
const CSRF_KEY = 'ss_editor_csrf';

export class ApiError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

const getCsrf = () => {
  try {
    return sessionStorage.getItem(CSRF_KEY) || '';
  } catch {
    return '';
  }
};
const setCsrf = (v) => {
  try {
    if (v) sessionStorage.setItem(CSRF_KEY, v);
    else sessionStorage.removeItem(CSRF_KEY);
  } catch {
    /* tab storage unavailable: the user will need to reopen the link */
  }
};
export const hasSession = () => !!getCsrf();

async function call(method, path, body) {
  let res;
  try {
    res = await fetch(`${BASE}${path}`, {
      method,
      credentials: 'include',
      cache: 'no-store',
      referrerPolicy: 'no-referrer',
      headers: { 'Content-Type': 'application/json', ...(method !== 'GET' ? { 'X-CSRF-Token': getCsrf() } : {}) },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
  } catch {
    throw new ApiError(0, 'NETWORK', 'No connection to SurveyScriber');
  }
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new ApiError(res.status, data.error || 'ERROR', data.message || 'Request failed', data.details);
  return data;
}

export const api = {
  /** Exchange the link token for the session cookie. The caller removes the token from the address bar. */
  async open(token) {
    const data = await call('POST', '/editor/open', { token });
    setCsrf(data.csrfToken);
    return data;
  },
  read: (reportId) => call('GET', `/editor/reports/${reportId}`),
  save: (reportId, payload) => call('PATCH', `/editor/reports/${reportId}`, payload),
  async close() {
    try {
      await call('POST', '/editor/close');
    } finally {
      setCsrf('');
    }
  },
};
