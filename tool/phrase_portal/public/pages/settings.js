'use strict';
/**
 * Settings: company and bank details for invoices, and how emails are sent out.
 * Changes apply at once, without restarting the server. Passwords are not here.
 */
(function () {
  const view = { box: null, settings: null, inputs: {}, saveBtn: null, problem: null };
  const looksLikeEmail = (v) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v);

  const isDirty = () => !!view.settings
    && view.settings.some((s) => view.inputs[s.key] && view.inputs[s.key].value.trim() !== s.value);

  function problemNow() {
    for (const s of view.settings) {
      const value = view.inputs[s.key].value.trim();
      if (s.type === 'email' && value && !looksLikeEmail(value)) return s.label + ' is not a valid email address.';
    }
    return null;
  }

  function refresh() {
    const problem = problemNow();
    view.problem.textContent = problem || '';
    view.problem.hidden = !problem;
    view.saveBtn.disabled = !!problem || !isDirty();
  }

  async function save() {
    view.saveBtn.disabled = true;
    const values = Object.fromEntries(view.settings.map((s) => [s.key, view.inputs[s.key].value.trim()]));
    const r = await SS.apiJson('/admin/settings', { method: 'PUT', auth: true, body: { values } });
    if (r.status !== 200) {
      SS.toast(SS.messageOf(r, 'The settings could not be saved.'), 'err');
      refresh();
      return;
    }
    SS.toast('Saved. The next invoice and email use these.', 'ok');
    show(r.body);
  }

  function fieldOf(s) {
    const input = SS.el('input');
    input.type = s.type === 'email' ? 'email' : 'text';
    input.value = s.value;
    input.maxLength = 200;
    input.placeholder = s.serverValue || 'Not set';
    input.addEventListener('input', refresh);
    view.inputs[s.key] = input;
    const hint = [s.hint, s.serverValue ? 'Empty uses the server\'s value: ' + s.serverValue + '.' : null].filter(Boolean).join(' ');
    return SS.el('label', 'field', [
      SS.el('span', '', s.label),
      input,
      hint ? SS.el('small', 'muted', hint) : null,
    ]);
  }

  function show(settings) {
    view.settings = settings;
    view.inputs = {};
    view.saveBtn = SS.button('Save', save, 'primary');
    view.problem = SS.el('div', 'alert err');
    view.problem.hidden = true;
    view.problem.setAttribute('role', 'alert');

    const groups = [...new Set(settings.map((s) => s.group))];
    const latest = settings.filter((s) => s.updatedAt).sort((a, b) => String(b.updatedAt).localeCompare(String(a.updatedAt)))[0];
    view.box.replaceChildren(
      SS.el('div', 'toolbar tree-bar', [
        SS.el('span', 'muted tree-status', latest
          ? 'Last changed ' + SS.fmtDate(latest.updatedAt) + (latest.updatedBy ? ' by ' + latest.updatedBy : '')
          : 'Nothing changed here yet: everything uses the server\'s values.'),
        SS.el('span', 'spacer'),
        view.saveBtn,
      ]),
      view.problem,
      SS.el('div', 'settings-groups', groups.map((group) => SS.el('div', 'card', [
        SS.el('h3', '', group),
        SS.el('div', 'settings-grid', settings.filter((s) => s.group === group).map(fieldOf)),
      ]))),
    );
    refresh();
  }

  async function load() {
    view.settings = null;
    view.box.replaceChildren(SS.loadingBox('Loading the settings…'));
    const r = await SS.apiJson('/admin/settings', { auth: true });
    if (r.status !== 200) {
      view.box.replaceChildren(SS.errorBox(SS.messageOf(r, 'The settings could not be loaded.'), load));
      return;
    }
    show(r.body);
  }

  window.SSPages.settings = {
    render(box) {
      view.box = box;
      load();
    },
    unsaved: () => isDirty(),
  };
})();
