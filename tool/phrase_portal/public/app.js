'use strict';
/**
 * SurveyScriber Phrase Bank portal — static web app.
 *
 * Talks directly to the SurveyScriber API (same origin, under /api/v1):
 *   GET  /config/phrase-bank/:type          latest published bank (public)
 *   POST /admin/config/phrase-bank/upload   publish the whole bank (admin only)
 *   POST /auth/login | /auth/refresh | /auth/logout
 * Nothing is stored on the web server; the published bank on the API is the
 * source of truth, and every phone picks it up on its next start/resume.
 */
const $ = (id) => document.getElementById(id);
const L = window.BankLogic;
const API = '/api/v1';
const SESSION_KEY = 'ss_portal_session';

const state = {
  bank: 'inspection',
  raw: null,            // the full bank object (what gets published)
  entries: [],          // {key, value, tokens, screenId?} snapshot for the list
  edited: new Map(),    // key -> new value (unsaved, in-editor)
  selected: null,
  filter: '',
  published: null,      // {version, checksum, publishedAt} or null when nothing is published yet
  session: null,        // {accessToken, refreshToken, email}
};

// ── session ────────────────────────────────────────────────────────
function loadSession() {
  try { state.session = JSON.parse(sessionStorage.getItem(SESSION_KEY) || 'null'); } catch { state.session = null; }
}
function saveSession(s) {
  state.session = s;
  try { s ? sessionStorage.setItem(SESSION_KEY, JSON.stringify(s)) : sessionStorage.removeItem(SESSION_KEY); } catch {}
}

async function apiJson(path, { method = 'GET', body, auth = false, retry = true } = {}) {
  const headers = { Accept: 'application/json' };
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  if (auth && state.session) headers.Authorization = 'Bearer ' + state.session.accessToken;
  let res;
  try {
    res = await fetch(API + path, { method, headers, body: body === undefined ? undefined : JSON.stringify(body) });
  } catch (e) {
    return { status: 0, body: { message: 'Cannot reach the server: ' + (e.message || e) } };
  }
  let parsed = {};
  try { parsed = await res.json(); } catch { /* empty body */ }
  if (res.status === 401 && auth && retry && (await refreshSession())) {
    return apiJson(path, { method, body, auth, retry: false });
  }
  return { status: res.status, body: parsed };
}

async function refreshSession() {
  if (!state.session || !state.session.refreshToken) return false;
  const r = await apiJson('/auth/refresh', { method: 'POST', body: { refreshToken: state.session.refreshToken } });
  if ((r.status === 200 || r.status === 201) && r.body.accessToken) {
    saveSession({ ...state.session, accessToken: r.body.accessToken, refreshToken: r.body.refreshToken || state.session.refreshToken });
    return true;
  }
  saveSession(null);
  setLive();
  return false;
}

async function login(email, password) {
  const r = await apiJson('/auth/login', { method: 'POST', body: { email, password } });
  if (r.status !== 200 && r.status !== 201) {
    return { ok: false, message: r.body.message || 'Login failed' };
  }
  if (!r.body.accessToken) return { ok: false, message: 'Login response had no token' };
  const role = r.body.user && r.body.user.role;
  if (role && role !== 'ADMIN') {
    return { ok: false, message: 'This account is ' + role + '. Only an ADMIN can publish phrases.' };
  }
  saveSession({ accessToken: r.body.accessToken, refreshToken: r.body.refreshToken || null, email });
  setLive();
  return { ok: true };
}

async function logout() {
  if (state.session && state.session.refreshToken) {
    await apiJson('/auth/logout', { method: 'POST', body: { refreshToken: state.session.refreshToken }, auth: true, retry: false });
  }
  saveSession(null);
  setLive();
}

function setLive() {
  const on = !!state.session;
  const el = $('liveState');
  el.className = 'live-state ' + (on ? 'on' : 'off');
  el.textContent = on ? 'Live - publishing as ' + state.session.email : 'Read only - log in to publish';
  $('loginBtn').textContent = on ? 'Log out' : 'Log in to publish';
}

// ── bank loading ───────────────────────────────────────────────────
async function loadBank(name) {
  const type = L.API_TYPE[name];
  setStatus('Loading…', '');
  const r = await apiJson('/config/phrase-bank/' + type);
  let raw; let published = null;
  if (r.status === 200 && r.body.bank) {
    raw = r.body.bank;
    published = { version: r.body.version, checksum: r.body.checksum, publishedAt: r.body.publishedAt };
  } else if (r.status === 404) {
    // Nothing published yet: start from the bank bundled with the app, so the
    // first save publishes the complete bank.
    const b = await fetch('assets/banks/' + name + '.json', { cache: 'no-store' });
    if (!b.ok) throw new Error('Baseline bank not found (' + b.status + ')');
    raw = await b.json();
  } else {
    throw new Error(r.body.message || ('Server error ' + r.status));
  }
  state.bank = name;
  state.raw = raw;
  state.entries = L.entriesOf(raw);
  state.edited.clear();
  state.selected = null;
  state.published = published;
  $('counts').textContent = state.entries.length + ' phrases';
  renderStatus();
  renderList();
  renderEditor();
}

function renderStatus() {
  const p = state.published;
  if (p) {
    const when = p.publishedAt ? new Date(p.publishedAt).toLocaleString() : '';
    setStatus('Published version ' + p.version + (when ? ' · ' + when : '') + ' · live on all phones', 'ok');
  } else {
    setStatus('Not published yet: phones use the bank built into the app. Your first save publishes the complete bank.', 'warn');
  }
}
function setStatus(text, kind) {
  const el = $('bankStatus');
  el.textContent = text;
  el.className = 'bank-status ' + (kind || '');
}

// ── list / editor ──────────────────────────────────────────────────
function currentValue(key) {
  if (state.edited.has(key)) return state.edited.get(key);
  const e = originalEntry(key);
  return e ? e.value : '';
}
function originalEntry(key) { return state.entries.find((x) => x.key === key); }

function matches(e) {
  const f = state.filter;
  if (!f) return true;
  return e.key.toLowerCase().includes(f) ||
         String(e.screenId || '').toLowerCase().includes(f) ||
         String(currentValue(e.key)).toLowerCase().includes(f);
}

function renderList() {
  const list = $('list');
  list.innerHTML = '';
  const frag = document.createDocumentFragment();
  let shown = 0;
  for (const e of state.entries) {
    if (!matches(e)) continue;
    shown++;
    if (shown > 600) continue; // keep the DOM light; narrow the search
    const row = document.createElement('button');
    row.type = 'button';
    row.className = 'row' + (e.key === state.selected ? ' active' : '') + (state.edited.has(e.key) ? ' edited' : '');
    row.innerHTML = '<div class="rk"></div><div class="rv"></div>';
    row.querySelector('.rk').textContent = e.screenId ? e.key + '  ·  ' + e.screenId : e.key;
    row.querySelector('.rv').textContent = currentValue(e.key);
    row.onclick = () => select(e.key);
    frag.appendChild(row);
  }
  list.appendChild(frag);
  if (shown > 600) {
    const more = document.createElement('div');
    more.className = 'row';
    more.style.cursor = 'default';
    more.innerHTML = '<div class="rv"></div>';
    more.querySelector('.rv').textContent = (shown - 600) + ' more… refine your search.';
    list.appendChild(more);
  }
}

function select(key) {
  state.selected = key;
  renderList();
  renderEditor();
}

function renderEditor() {
  const hasSel = state.selected != null;
  $('empty').hidden = hasSel;
  $('editor').hidden = !hasSel;
  if (!hasSel) return;
  $('editKey').textContent = state.selected;
  $('editValue').value = currentValue(state.selected);
  $('overrideChk').checked = false;
  validate();
}

function validate() {
  const key = state.selected;
  const orig = originalEntry(key);
  const before = orig ? orig.tokens : [];
  const now = L.tokenSet($('editValue').value);
  const missing = before.filter((t) => !now.includes(t));
  const added = now.filter((t) => !before.includes(t));

  const chips = $('tokenChips');
  chips.innerHTML = '';
  for (const t of before) {
    const c = document.createElement('span');
    c.className = 'chip' + (missing.includes(t) ? ' missing' : '');
    c.textContent = t;
    chips.appendChild(c);
  }
  for (const t of added) {
    const c = document.createElement('span');
    c.className = 'chip added';
    c.textContent = t + ' (new)';
    chips.appendChild(c);
  }

  const dirty = state.edited.has(key) || $('editValue').value !== (orig ? orig.value : '');
  $('dirtyBadge').hidden = !dirty;

  const v = $('validation');
  const override = $('overrideChk').checked;
  const changed = missing.length || added.length;
  if (changed && !override) {
    v.hidden = false; v.className = 'validation err';
    v.innerHTML =
      (missing.length ? 'Removed token(s): <b></b>. ' : '') +
      (added.length ? 'New token(s): <b></b>. ' : '') +
      'Fix the tokens, or tick Override to save anyway.';
    const bs = v.querySelectorAll('b');
    let i = 0;
    if (missing.length) bs[i++].textContent = missing.join(', ');
    if (added.length) bs[i++].textContent = added.join(', ');
    $('saveBtn').disabled = true;
  } else if (changed && override) {
    v.hidden = false; v.className = 'validation warn';
    v.textContent = 'Token lock overridden — make sure the engine substitutes these tokens.';
    $('saveBtn').disabled = false;
  } else {
    v.hidden = true;
    $('saveBtn').disabled = !dirty;
  }
  $('saveBtn').textContent = state.session ? 'Save & publish' : 'Save (log in first)';
  return { missing, added, override };
}

// ── save = publish the whole bank ──────────────────────────────────
async function save() {
  if (!state.session) {
    toast('Log in with an admin account to publish.', 'err');
    openLogin();
    return;
  }
  const key = state.selected;
  const value = $('editValue').value;
  const { override } = validate();

  // Apply on a copy so a failed publish never corrupts the in-memory bank.
  const draft = JSON.parse(JSON.stringify(state.raw));
  const edit = L.applyEdit(draft, key, value, override);
  if (edit.status !== 200) { toast(edit.body.message || edit.body.error, 'err'); return; }

  $('saveBtn').disabled = true;
  setStatus('Publishing…', '');
  const r = await apiJson('/admin/config/phrase-bank/upload', {
    method: 'POST', auth: true, body: { bankType: L.API_TYPE[state.bank], bank: draft },
  });
  if (r.status === 201 || r.status === 200) {
    state.raw = draft;
    const e = originalEntry(key);
    if (e) { e.value = value; e.tokens = L.tokenSet(value); }
    state.edited.delete(key);
    state.published = { version: r.body.version, checksum: r.body.checksum, publishedAt: r.body.publishedAt };
    renderStatus();
    toast(r.body.unchanged ? 'Already live (no change).' : 'Saved and LIVE on all phones (version ' + r.body.version + ')', 'ok');
    renderList();
    renderEditor();
    return;
  }
  renderStatus();
  $('saveBtn').disabled = false;
  if (r.status === 401) { saveSession(null); setLive(); toast('Login expired. Log in again, then save.', 'err'); openLogin(); return; }
  if (r.status === 403) { toast('This account is not an ADMIN. Cannot publish.', 'err'); return; }
  toast('NOT published: ' + (r.body.message || ('server error ' + r.status)), 'err');
}

// ── login dialog ───────────────────────────────────────────────────
function openLogin() { $('loginErr').hidden = true; $('loginDlg').showModal(); }

$('loginBtn').addEventListener('click', async () => {
  if (state.session) { await logout(); toast('Logged out.', 'ok'); renderEditor(); return; }
  openLogin();
});
$('loginCancel').addEventListener('click', () => $('loginDlg').close());
$('loginForm').addEventListener('submit', async (ev) => {
  ev.preventDefault();
  $('loginSubmit').disabled = true;
  try {
    const r = await login($('loginEmail').value.trim(), $('loginPass').value);
    if (!r.ok) { $('loginErr').textContent = r.message; $('loginErr').hidden = false; return; }
    $('loginPass').value = '';
    $('loginDlg').close();
    toast('Logged in. Saves now go live on all phones.', 'ok');
    renderEditor();
  } finally {
    $('loginSubmit').disabled = false;
  }
});

let toastTimer;
function toast(msg, kind) {
  const t = $('toast');
  t.textContent = msg;
  t.className = 'toast ' + (kind || '');
  t.hidden = false;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { t.hidden = true; }, 3600);
}

// ── events ─────────────────────────────────────────────────────────
$('search').addEventListener('input', (e) => { state.filter = e.target.value.trim().toLowerCase(); renderList(); });
$('bankSelect').addEventListener('change', (e) => {
  if (state.edited.size && !confirm(state.edited.size + ' unsaved edit(s) will be discarded. Switch bank?')) {
    e.target.value = state.bank; return;
  }
  loadBank(e.target.value).catch((err) => { setStatus(String(err.message || err), 'err'); toast(String(err.message || err), 'err'); });
});
$('editValue').addEventListener('input', () => {
  const key = state.selected;
  const orig = originalEntry(key);
  const val = $('editValue').value;
  if (orig && val === orig.value) state.edited.delete(key); else state.edited.set(key, val);
  validate();
});
$('overrideChk').addEventListener('change', validate);
$('saveBtn').addEventListener('click', save);
$('revertBtn').addEventListener('click', () => {
  const orig = originalEntry(state.selected);
  if (orig) { $('editValue').value = orig.value; state.edited.delete(state.selected); }
  validate(); renderList();
});
window.addEventListener('beforeunload', (e) => { if (state.edited.size) { e.preventDefault(); e.returnValue = ''; } });

loadSession();
setLive();
loadBank('inspection').catch((err) => { setStatus(String(err.message || err), 'err'); toast(String(err.message || err), 'err'); });
