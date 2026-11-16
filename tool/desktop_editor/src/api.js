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

const wait = (ms) => new Promise((r) => setTimeout(r, ms));
/** The API allows only a few requests a second from one address. A 429 is not a failure: wait a moment and go on. */
const RATE_RETRIES = 4;

async function call(method, path, body, attempt = 0) {
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
  if (res.status === 429 && attempt < RATE_RETRIES) {
    await wait(1100 * (attempt + 1));
    return call(method, path, body, attempt + 1);
  }
  const data = await res.json().catch(() => ({}));
  if (res.status === 429) throw new ApiError(429, 'RATE_LIMITED', 'Too many requests at once. Please wait a moment and try again.');
  if (!res.ok) throw new ApiError(res.status, data.error || 'ERROR', data.message || 'Request failed', data.details);
  return data;
}

/** Upload with progress: fetch cannot report upload progress, XMLHttpRequest can. Cookie and CSRF as for every write. */
function sendForm(method, path, form, onProgress, attempt = 0) {
  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    xhr.open(method, `${BASE}${path}`);
    xhr.withCredentials = true;
    xhr.setRequestHeader('X-CSRF-Token', getCsrf());
    xhr.upload.onprogress = (e) => e.lengthComputable && onProgress && onProgress(e.loaded / e.total);
    xhr.onerror = () => reject(new ApiError(0, 'NETWORK', 'No connection to SurveyScriber'));
    xhr.ontimeout = xhr.onerror;
    xhr.onload = () => {
      let data = {};
      try {
        data = JSON.parse(xhr.responseText);
      } catch {
        /* not JSON */
      }
      if (xhr.status === 429) {
        if (attempt < RATE_RETRIES) wait(1100 * (attempt + 1)).then(() => sendForm(method, path, form, onProgress, attempt + 1)).then(resolve, reject);
        else reject(new ApiError(429, 'RATE_LIMITED', 'Too many requests at once. Please wait a moment and try again.'));
        return;
      }
      if (xhr.status >= 200 && xhr.status < 300) resolve(data);
      else reject(new ApiError(xhr.status, data.error || 'ERROR', data.message || 'Request failed', data.details));
    };
    xhr.send(form);
  });
}

export const photoUrl = (reportId, photoId) => `${BASE}/editor/reports/${reportId}/photos/${photoId}/file`;

export const photoApi = {
  list: (reportId) => call('GET', `/editor/reports/${reportId}/photos`),
  upload(reportId, file, { expectedReportVersion, sectionKey, caption }, onProgress) {
    const form = new FormData();
    form.append('expectedReportVersion', String(expectedReportVersion));
    if (sectionKey) form.append('sectionKey', sectionKey);
    if (caption) form.append('caption', caption);
    form.append('file', file, file.name);
    return sendForm('POST', `/editor/reports/${reportId}/photos`, form, onProgress);
  },
  replace(reportId, photoId, file, expectedReportVersion, onProgress) {
    const form = new FormData();
    form.append('expectedReportVersion', String(expectedReportVersion));
    form.append('file', file, file.name);
    return sendForm('POST', `/editor/reports/${reportId}/photos/${photoId}/replace`, form, onProgress);
  },
  update: (reportId, photoId, body) => call('PUT', `/editor/reports/${reportId}/photos/${photoId}`, body),
  remove: (reportId, photoId, expectedReportVersion) => call('DELETE', `/editor/reports/${reportId}/photos/${photoId}?expectedReportVersion=${expectedReportVersion}`),
};

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
