'use strict';
const $ = (id) => document.getElementById(id);
const TOKEN_RE = /\{[A-Z0-9_]+\}/g;
const tokenSet = (s) => [...new Set((String(s).match(TOKEN_RE) || []))].sort();

const state = {
  bank: 'inspection',
  entries: [],          // {key, value, tokens} — original loaded values
  edited: new Map(),    // key -> new value (unsaved)
  selected: null,       // key
  filter: '',
};

async function loadBank(name) {
  const res = await fetch(`/api/bank?name=${encodeURIComponent(name)}`);
  const data = await res.json();
  if (!res.ok) throw new Error(data.error || 'Load failed');
  state.bank = name;
  state.entries = data.entries;
  state.edited.clear();
  state.selected = null;
  $('counts').textContent = `${data.count} phrases`;
  renderList();
  renderEditor();
}

function currentValue(key) {
  if (state.edited.has(key)) return state.edited.get(key);
  const e = state.entries.find((x) => x.key === key);
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
    row.className = 'row' + (e.key === state.selected ? ' active' : '') +
      (state.edited.has(e.key) ? ' edited' : '');
    row.innerHTML =
      `<div class="rk"></div><div class="rv"></div>`;
    // valuation templates carry the screen they belong to
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
    more.innerHTML = `<div class="rv">${shown - 600} more… refine your search.</div>`;
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

  const key = state.selected;
  $('editKey').textContent = key;
  const ta = $('editValue');
  ta.value = currentValue(key);
  $('overrideChk').checked = false;
  validate();
}

function validate() {
  const key = state.selected;
  const orig = originalEntry(key);
  const before = orig ? orig.tokens : [];
  const now = tokenSet($('editValue').value);
  const missing = before.filter((t) => !now.includes(t));
  const added = now.filter((t) => !before.includes(t));

  // token chips
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

  // dirty state
  const dirty = state.edited.has(key) ||
    $('editValue').value !== (orig ? orig.value : '');
  $('dirtyBadge').hidden = !dirty;

  // validation message
  const v = $('validation');
  const override = $('overrideChk').checked;
  const changed = missing.length || added.length;
  if (changed && !override) {
    v.hidden = false; v.className = 'validation err';
    v.innerHTML =
      (missing.length ? `Removed token(s): <b>${missing.join(', ')}</b>. ` : '') +
      (added.length ? `New token(s): <b>${added.join(', ')}</b>. ` : '') +
      'Fix the tokens, or tick Override to save anyway.';
    $('saveBtn').disabled = true;
  } else if (changed && override) {
    v.hidden = false; v.className = 'validation warn';
    v.textContent = 'Token lock overridden — make sure the engine substitutes these tokens.';
    $('saveBtn').disabled = false;
  } else {
    v.hidden = true;
    $('saveBtn').disabled = !dirty;
  }
  return { missing, added, override };
}

async function save() {
  const key = state.selected;
  const value = $('editValue').value;
  const { override } = validate();
  try {
    const res = await fetch('/api/save', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: state.bank, key, value, force: override }),
    });
    const data = await res.json();
    if (!res.ok) {
      toast(data.message || data.error || 'Save failed', 'err');
      return;
    }
    // commit into the loaded snapshot so it becomes the new baseline
    const e = originalEntry(key);
    if (e) { e.value = value; e.tokens = tokenSet(value); }
    state.edited.delete(key);
    reportPublish(data.publish);
    renderList();
    renderEditor();
  } catch (err) {
    toast(String(err.message || err), 'err');
  }
}

function setLive(on, email) {
  const el = $('liveState');
  el.className = 'live-state ' + (on ? 'on' : 'off');
  el.textContent = on ? 'Live - publishing as ' + email : 'Offline - not logged in';
  $('loginBtn').textContent = on ? 'Log out' : 'Log in to publish';
}

function reportPublish(p) {
  if (p && p.live) {
    toast(p.unchanged ? 'Saved. Already live (no change).' : 'Saved and LIVE on all phones (version ' + p.version + ')', 'ok');
    return;
  }
  if (p && p.reason === 'login_expired') setLive(false);
  const why = !p || p.reason === 'not_logged_in' ? 'log in to publish'
    : p.reason === 'login_expired' ? 'login expired, log in again' : p.reason;
  toast('Saved to file only - NOT live (' + why + ')', 'err');
}

async function refreshStatus() {
  try {
    const st = await (await fetch('/api/status')).json();
    setLive(st.loggedIn, st.email);
  } catch { setLive(false); }
}

$('loginBtn').addEventListener('click', async () => {
  if ($('liveState').classList.contains('on')) {
    await fetch('/api/logout', { method: 'POST' });
    setLive(false);
    return;
  }
  $('loginErr').hidden = true;
  $('loginDlg').showModal();
});
$('loginCancel').addEventListener('click', () => $('loginDlg').close());
$('loginForm').addEventListener('submit', async (ev) => {
  ev.preventDefault();
  $('loginSubmit').disabled = true;
  try {
    const res = await fetch('/api/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: $('loginEmail').value, password: $('loginPass').value }),
    });
    const data = await res.json();
    if (!res.ok) {
      $('loginErr').textContent = data.error || 'Login failed';
      $('loginErr').hidden = false;
      return;
    }
    $('loginPass').value = '';
    $('loginDlg').close();
    setLive(true, data.email);
    const changed = Object.values(data.pulls || {}).some((p) => p.changed);
    toast(changed ? 'Logged in. Latest published phrases loaded - reloading.' : 'Logged in. Saves now go live.', 'ok');
    if (changed) loadBank(state.bank).catch((err) => toast(String(err), 'err'));
  } catch (err) {
    $('loginErr').textContent = String(err.message || err);
    $('loginErr').hidden = false;
  } finally {
    $('loginSubmit').disabled = false;
  }
});
refreshStatus();

let toastTimer;
function toast(msg, kind) {
  const t = $('toast');
  t.textContent = msg;
  t.className = 'toast ' + (kind || '');
  t.hidden = false;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => { t.hidden = true; }, 3200);
}

// ── events ──
$('search').addEventListener('input', (e) => {
  state.filter = e.target.value.trim().toLowerCase();
  renderList();
});
$('bankSelect').addEventListener('change', (e) => {
  const go = () => loadBank(e.target.value).catch((err) => toast(String(err), 'err'));
  if (state.edited.size &&
      !confirm(`${state.edited.size} unsaved edit(s) will be discarded. Switch bank?`)) {
    e.target.value = state.bank; return;
  }
  go();
});
$('editValue').addEventListener('input', () => {
  const key = state.selected;
  const orig = originalEntry(key);
  const val = $('editValue').value;
  if (orig && val === orig.value) state.edited.delete(key);
  else state.edited.set(key, val);
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
  if (state.edited.size) { e.preventDefault(); e.returnValue = ''; }
});

loadBank('inspection').catch((err) => toast(String(err), 'err'));
