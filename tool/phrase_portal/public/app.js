'use strict';
/**
 * SurveyScriber admin portal — static web app.
 *
 * Nothing is shown until an administrator or sub admin signs in. This file holds
 * the sign-in, navigation and phrase editor; the other pages are in pages/*.js.
 * After sign-in it talks to the
 * SurveyScriber API (same origin, under /api/v1):
 *   GET  /config/phrase-bank/:type          latest published bank
 *   POST /admin/config/phrase-bank/upload   publish the whole bank (admin only)
 *   POST /auth/login | /auth/refresh | /auth/logout, GET /auth/me
 * The published bank on the API is the source of truth; every phone picks it
 * up on its next start/resume.
 */
const $ = (id) => document.getElementById(id);
const L = window.BankLogic;
const AL = window.AdminLogic;
const API = '/api/v1';
const SESSION_KEY = 'ss_portal_session';
const BANK_NAMES = { inspection: 'Home Survey', valuation: 'Valuation' };

const state = {
  session: null,         // {accessToken, refreshToken, email, role}
  view: 'dash',          // dash | inspection | valuation
  bank: 'inspection',    // bank shown in the editor
  banks: { inspection: null, valuation: null }, // {raw, entries, published, error}
  edited: new Map(),     // key -> unsaved text (current bank only)
  selected: null,
  filter: '',
};
const cur = () => state.banks[state.bank];

// ── session ────────────────────────────────────────────────────────
function loadSession() {
  try { state.session = JSON.parse(sessionStorage.getItem(SESSION_KEY) || 'null'); } catch { state.session = null; }
}
function saveSession(s) {
  state.session = s;
  try { s ? sessionStorage.setItem(SESSION_KEY, JSON.stringify(s)) : sessionStorage.removeItem(SESSION_KEY); } catch { /* storage blocked */ }
}

async function apiJson(path, { method = 'GET', body, auth = false, retry = true } = {}) {
  const headers = { Accept: 'application/json' };
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  if (auth && state.session) headers.Authorization = 'Bearer ' + state.session.accessToken;
  let res;
  try {
    res = await fetch(API + path, { method, headers, body: body === undefined ? undefined : JSON.stringify(body) });
  } catch (e) {
    return { status: 0, body: { message: 'Cannot reach the server. Check your internet connection.' } };
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
  return false;
}

async function login(email, password) {
  const r = await apiJson('/auth/login', { method: 'POST', body: { email, password } });
  if (r.status !== 200 && r.status !== 201) {
    return { ok: false, message: r.status === 0 ? r.body.message : (r.body.message || 'Sign in failed') };
  }
  if (!r.body.accessToken) return { ok: false, message: 'Sign in failed (no token returned).' };
  const role = r.body.user && r.body.user.role;
  if (!AL.canUsePortal(role)) {
    return { ok: false, message: 'This account is a ' + AL.roleLabel(role) + ' account. Only administrators and sub admins can use this portal.' };
  }
  saveSession({ accessToken: r.body.accessToken, refreshToken: r.body.refreshToken || null, email, role });
  return { ok: true };
}

async function signOut(message) {
  if (state.session && state.session.refreshToken) {
    await apiJson('/auth/logout', { method: 'POST', body: { refreshToken: state.session.refreshToken }, auth: true, retry: false });
  }
  saveSession(null);
  state.banks = { inspection: null, valuation: null };
  state.edited.clear();
  state.selected = null;
  showLogin(message);
}

// ── screens ────────────────────────────────────────────────────────
function showLogin(message) {
  $('appView').hidden = true;
  $('loginView').hidden = false;
  $('loginPass').value = '';
  const err = $('loginErr');
  err.hidden = !message;
  err.textContent = message || '';
  setTimeout(() => $('loginEmail').focus(), 0);
}

function showApp() {
  $('loginView').hidden = true;
  $('appView').hidden = false;
  const email = state.session.email || 'admin';
  $('whoEmail').textContent = email;
  $('avatar').textContent = email.charAt(0).toUpperCase();
  const role = state.session.role;
  $('whoRole').textContent = AL.roleLabel(role);
  document.querySelectorAll('.nav-item').forEach((b) => { b.hidden = !AL.canSee(b.dataset.view, role); });
  document.querySelectorAll('.nav-label.admin-only').forEach((n) => { n.hidden = role !== 'ADMIN'; });
  go(AL.startPage(location.hash, role));
}

/** Switch page. Returns false if the user cancelled because of unsaved edits. */
function go(view) {
  if (state.edited.size && state.view !== 'dash' &&
      !confirm(state.edited.size + ' unsaved edit(s) will be lost. Leave this page?')) {
    return false;
  }
  const leaving = window.SSPages[state.view];
  if (leaving && leaving.unsaved && leaving.unsaved() &&
      !confirm('Your unsaved changes will be lost. Leave this page?')) {
    return false;
  }
  if (!AL.canSee(view, state.session.role)) view = 'dash';
  state.edited.clear();
  state.selected = null;
  state.filter = '';
  $('search').value = '';
  state.view = view;
  document.querySelectorAll('.nav-item').forEach((b) => b.classList.toggle('active', b.dataset.view === view));
  $('side').classList.remove('open');
  const isDash = view === 'dash';
  const isBank = !!BANK_NAMES[view];
  $('dashView').hidden = !isDash;
  $('editView').hidden = !isBank;
  $('pageView').hidden = isDash || isBank;
  $('pageTitle').textContent = AL.pageOf(view).title;
  history.replaceState(null, '', '#/' + view);
  if (isDash) { renderCards(); ensureBanks(); }
  else if (isBank) { state.bank = view; openEditor(); }
  else renderPage(view);
  return true;
}

function renderPage(view) {
  const box = $('pageView');
  box.replaceChildren();
  const page = window.SSPages[view];
  if (page) page.render(box);
  else box.append(SS.emptyBox(AL.pageOf(view).title, 'This page is being built.'));
}

// ── bank loading ───────────────────────────────────────────────────
async function fetchBank(name) {
  const type = L.API_TYPE[name];
  const r = await apiJson('/config/phrase-bank/' + type);
  if (r.status === 200 && r.body.bank) {
    const raw = r.body.bank;
    return { raw, entries: L.entriesOf(raw),
      published: { version: r.body.version, checksum: r.body.checksum, publishedAt: r.body.publishedAt } };
  }
  if (r.status === 404) {
    // Nothing published yet: start from the bank bundled with the app, so the
    // first save publishes the complete bank.
    const b = await fetch('assets/banks/' + name + '.json', { cache: 'no-store' });
    if (!b.ok) return { error: 'Baseline bank not found (' + b.status + ')' };
    const raw = await b.json();
    return { raw, entries: L.entriesOf(raw), published: null };
  }
  return { error: r.body.message || ('Server error ' + r.status) };
}

async function ensureBank(name, force) {
  if (state.banks[name] && !state.banks[name].error && !force) return state.banks[name];
  state.banks[name] = await fetchBank(name);
  return state.banks[name];
}

async function ensureBanks() {
  await Promise.all(Object.keys(BANK_NAMES).map((n) => ensureBank(n)));
  updateNavCounts();
  if (state.view === 'dash') renderCards();
}

function updateNavCounts() {
  $('navCountInspection').textContent = state.banks.inspection && state.banks.inspection.entries ? state.banks.inspection.entries.length : '';
  $('navCountValuation').textContent = state.banks.valuation && state.banks.valuation.entries ? state.banks.valuation.entries.length : '';
}

// ── dashboard ──────────────────────────────────────────────────────
function fmtDate(iso) {
  if (!iso) return '';
  const d = new Date(iso);
  return d.toLocaleString(undefined, { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
}
function el(tag, cls, text) {
  const e = document.createElement(tag);
  if (cls) e.className = cls;
  if (text !== undefined) e.textContent = text;
  return e;
}

function renderCards() {
  const wrap = $('statCards');
  wrap.innerHTML = '';
  for (const name of Object.keys(BANK_NAMES)) {
    const b = state.banks[name];
    if (!b) { const s = el('div', 'skeleton'); wrap.appendChild(s); continue; }
    const card = el('div', 'card');
    const k = el('div', 'k', BANK_NAMES[name] + ' phrases');
    let pill;
    let big; let sub;
    if (b.error) {
      pill = el('span', 'pill err', 'Error'); big = '—'; sub = b.error;
    } else if (b.published) {
      pill = el('span', 'pill ok', 'Live'); big = 'Version ' + b.published.version;
      sub = 'Published ' + fmtDate(b.published.publishedAt) + ' · ' + b.entries.length + ' phrases';
    } else {
      pill = el('span', 'pill warn', 'Not published yet'); big = b.entries.length + ' phrases';
      sub = 'Phones use the wording built into the app. Your first save publishes this bank.';
    }
    k.appendChild(pill);
    card.append(k, el('div', 'v', big), el('div', 's', sub));
    const go2 = el('button', 'btn go', 'Open ' + BANK_NAMES[name]);
    go2.type = 'button';
    go2.onclick = () => go(name);
    card.appendChild(go2);
    wrap.appendChild(card);
  }
}

// ── editor ─────────────────────────────────────────────────────────
async function openEditor() {
  setStatus('Loading…', '');
  $('list').innerHTML = '';
  $('listMeta').textContent = '';
  renderEditor();
  const b = await ensureBank(state.bank, true);
  if (state.view !== state.bank) return; // user navigated away
  updateNavCounts();
  if (b.error) { setStatus(b.error, 'err'); return; }
  renderStatus();
  renderList();
}

function renderStatus() {
  const p = cur().published;
  if (p) setStatus('Published version ' + p.version + ' · ' + fmtDate(p.publishedAt) + ' · live on all phones', 'ok');
  else setStatus('Not published yet: phones use the bank built into the app. Your first save publishes the complete bank.', 'warn');
}
function setStatus(text, kind) {
  const e = $('bankStatus');
  e.textContent = text;
  e.className = 'bank-status ' + (kind || '');
}

function originalEntry(key) { const b = cur(); return b && b.entries ? b.entries.find((x) => x.key === key) : undefined; }
function currentValue(key) {
  if (state.edited.has(key)) return state.edited.get(key);
  const e = originalEntry(key);
  return e ? e.value : '';
}
function matches(e) {
  const f = state.filter;
  if (!f) return true;
  return e.key.toLowerCase().includes(f) ||
    String(e.screenId || '').toLowerCase().includes(f) ||
    String(currentValue(e.key)).toLowerCase().includes(f);
}

function renderList() {
  const b = cur();
  const list = $('list');
  list.innerHTML = '';
  if (!b || !b.entries) return;
  const frag = document.createDocumentFragment();
  let shown = 0;
  for (const e of b.entries) {
    if (!matches(e)) continue;
    shown++;
    if (shown > 400) continue; // keep the DOM light; narrow the search
    const row = el('button', 'row' + (e.key === state.selected ? ' active' : '') + (state.edited.has(e.key) ? ' edited' : ''));
    row.type = 'button';
    row.append(el('div', 'rk', e.screenId ? e.key + '  ·  ' + e.screenId : e.key), el('div', 'rv', currentValue(e.key)));
    row.onclick = () => select(e.key);
    frag.appendChild(row);
  }
  list.appendChild(frag);
  $('listMeta').textContent = shown === b.entries.length
    ? b.entries.length + ' phrases'
    : shown + ' of ' + b.entries.length + ' phrases' + (shown > 400 ? ' (showing 400, refine your search)' : '');
  if (shown === 0) list.appendChild(el('div', 'row', 'No phrase matches your search.'));
}

function select(key) { state.selected = key; renderList(); renderEditor(); }

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
  if (!before.length && !added.length) chips.appendChild(el('span', 'muted tiny', 'None: this sentence has no placeholders.'));
  for (const t of before) chips.appendChild(el('span', 'chip' + (missing.includes(t) ? ' missing' : ''), t));
  for (const t of added) chips.appendChild(el('span', 'chip added', t + ' (new)'));

  const dirty = state.edited.has(key) || $('editValue').value !== (orig ? orig.value : '');
  $('dirtyBadge').hidden = !dirty;

  const v = $('validation');
  const override = $('overrideChk').checked;
  const changed = missing.length || added.length;
  if (changed && !override) {
    v.hidden = false; v.className = 'alert err';
    v.textContent =
      (missing.length ? 'Removed placeholder(s): ' + missing.join(', ') + '. ' : '') +
      (added.length ? 'New placeholder(s): ' + added.join(', ') + '. ' : '') +
      'Put them back as they were, or tick Override only if your developer asked for this change.';
    $('saveBtn').disabled = true;
  } else if (changed && override) {
    v.hidden = false; v.className = 'alert warn';
    v.textContent = 'Token lock overridden. Make sure the report engine fills these placeholders.';
    $('saveBtn').disabled = false;
  } else {
    v.hidden = true;
    $('saveBtn').disabled = !dirty;
  }
}

// ── save = publish the whole bank ──────────────────────────────────
async function save() {
  const b = cur();
  const key = state.selected;
  const value = $('editValue').value;
  const override = $('overrideChk').checked;

  // Apply on a copy so a failed publish never corrupts the in-memory bank.
  const draft = JSON.parse(JSON.stringify(b.raw));
  const edit = L.applyEdit(draft, key, value, override);
  if (edit.status !== 200) { toast(edit.body.message || edit.body.error, 'err'); return; }

  $('saveBtn').disabled = true;
  $('saveBtn').textContent = 'Publishing…';
  setStatus('Publishing…', '');
  const r = await apiJson('/admin/config/phrase-bank/upload', {
    method: 'POST', auth: true, body: { bankType: L.API_TYPE[state.bank], bank: draft },
  });
  $('saveBtn').textContent = 'Save & publish';
  if (r.status === 201 || r.status === 200) {
    b.raw = draft;
    const e = originalEntry(key);
    if (e) { e.value = value; e.tokens = L.tokenSet(value); }
    state.edited.delete(key);
    b.published = { version: r.body.version, checksum: r.body.checksum, publishedAt: r.body.publishedAt };
    renderStatus();
    toast(r.body.unchanged ? 'Already live, nothing changed.' : 'Saved and LIVE on all phones (version ' + r.body.version + ')', 'ok');
    renderList();
    renderEditor();
    return;
  }
  renderStatus();
  validate();
  if (r.status === 401) { await signOut('Your session expired. Please sign in again.'); return; }
  if (r.status === 403) { toast('This account is not an ADMIN, so it cannot publish.', 'err'); return; }
  toast('NOT published: ' + (r.body.message || ('server error ' + r.status)), 'err');
}

let toastTimer;
function toast(msg, kind) {
  const t = $('toast');
  t.textContent = msg;
  t.className = 'toast ' + (kind || '');
  t.hidden = false;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { t.hidden = true; }, 4200);
}

// ── events ─────────────────────────────────────────────────────────
$('loginForm').addEventListener('submit', async (ev) => {
  ev.preventDefault();
  const btn = $('loginSubmit');
  btn.disabled = true; btn.textContent = 'Signing in…';
  $('loginErr').hidden = true;
  try {
    const r = await login($('loginEmail').value.trim(), $('loginPass').value);
    if (!r.ok) { $('loginErr').textContent = r.message; $('loginErr').hidden = false; return; }
    $('loginPass').value = '';
    showApp();
  } finally {
    btn.disabled = false; btn.textContent = 'Sign in';
  }
});
$('pwToggle').addEventListener('click', () => {
  const p = $('loginPass');
  const show = p.type === 'password';
  p.type = show ? 'text' : 'password';
  $('pwToggle').textContent = show ? 'Hide' : 'Show';
});
$('logoutBtn').addEventListener('click', async () => {
  if (state.edited.size && !confirm(state.edited.size + ' unsaved edit(s) will be lost. Sign out?')) return;
  const open = window.SSPages[state.view];
  if (open && open.unsaved && open.unsaved() && !confirm('Your unsaved changes will be lost. Sign out?')) return;
  await signOut();
});
$('menuBtn').addEventListener('click', () => $('side').classList.toggle('open'));
document.querySelectorAll('.nav-item').forEach((b) => b.addEventListener('click', () => go(b.dataset.view)));
document.querySelectorAll('[data-go]').forEach((b) => b.addEventListener('click', () => go(b.dataset.go)));

$('search').addEventListener('input', (e) => { state.filter = e.target.value.trim().toLowerCase(); renderList(); });
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
window.addEventListener('beforeunload', (e) => {
  const open = window.SSPages[state.view];
  if (state.edited.size || (open && open.unsaved && open.unsaved())) { e.preventDefault(); e.returnValue = ''; }
});
document.addEventListener('keydown', (e) => {
  if ((e.ctrlKey || e.metaKey) && e.key === 's' && state.view !== 'dash' && !$('saveBtn').disabled && state.selected != null) {
    e.preventDefault(); save();
  }
});

// What the admin pages use from this file.
Object.assign(window.SS, { apiJson, toast, state, go, signOut });

// ── boot ───────────────────────────────────────────────────────────
(async function boot() {
  loadSession();
  if (!state.session) { showLogin(); return; }
  // Verify the stored session still works before showing anything.
  const me = await apiJson('/auth/me', { auth: true });
  if (me.status === 200 && AL.canUsePortal(me.body.role)) {
    saveSession({ ...state.session, role: me.body.role });
    showApp();
    return;
  }
  saveSession(null);
  showLogin();
})();
