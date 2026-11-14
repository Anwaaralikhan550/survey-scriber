'use strict';
/**
 * Email Templates: the wording of every email the system sends. Placeholders stay
 * locked, as on the phrase pages. With no edit, the original wording goes out.
 */
(function () {
  const view = { box: null, current: null, saved: null, form: null, previewFrame: null, previewSubject: null, problem: null };
  const PLACEHOLDER = /\{\{(\w+)\}\}/g;
  const PARTS = { subject: 'subject', html: 'HTML version', text: 'text version' };

  const namesIn = (text) => new Set([...String(text).matchAll(PLACEHOLDER)].map((m) => m[1]));

  /** The same check the server makes, so a slip shows while typing. */
  function problemWith(edit, original) {
    for (const part of Object.keys(PARTS)) {
      if (!String(edit[part]).trim()) return 'The ' + PARTS[part] + ' cannot be empty.';
      const now = namesIn(edit[part]);
      const wanted = namesIn(original[part]);
      for (const name of now) if (!wanted.has(name)) return '{{' + name + '}} is not available in the ' + PARTS[part] + ' of this email.';
      for (const name of wanted) if (!now.has(name)) return 'The ' + PARTS[part] + ' must keep {{' + name + '}}.';
    }
    if (/<script\b/i.test(edit.html)) return 'Scripts are not allowed in an email.';
    return null;
  }

  function editNow() {
    return { subject: view.form.subject.value, html: view.form.html.value, text: view.form.text.value };
  }

  const isDirty = () => !!view.current && !!view.form
    && Object.keys(PARTS).some((part) => view.form[part].value !== view.saved[part]);

  async function renderList() {
    view.current = null;
    view.form = null;
    view.box.replaceChildren(SS.loadingBox('Loading the emails…'));
    const r = await SS.apiJson('/admin/email-templates', { auth: true });
    if (r.status !== 200) {
      view.box.replaceChildren(SS.errorBox(SS.messageOf(r, 'The emails could not be loaded.'), renderList));
      return;
    }
    view.box.replaceChildren(
      SS.el('p', 'muted page-intro', 'Every email the system sends. Change the wording here; the values in {{double braces}} are filled in when the email goes out.'),
      SS.table([
        { title: 'Email', cell: (e) => SS.el('div', '', [SS.el('div', '', e.name), SS.el('div', 'muted tiny', e.audience)]) },
        { title: 'Wording', cell: (e) => SS.el('span', 'pill ' + (e.edited ? 'warn' : 'idle'), e.edited ? 'Edited' : 'Original') },
        { title: 'Last edited', cell: (e) => (e.edited ? SS.fmtDate(e.updatedAt) + (e.updatedBy ? ' by ' + e.updatedBy : '') : '') },
        {
          title: '',
          cls: 'actions',
          cell: (e) => {
            const b = SS.button('Edit', () => openEmail(e.key));
            b.setAttribute('aria-label', 'Edit ' + e.name);
            return SS.el('div', '', [b]);
          },
        },
      ], r.body),
    );
  }

  function area(part, label, rows) {
    const box = SS.el(part === 'subject' ? 'input' : 'textarea', 'email-box' + (part === 'subject' ? '' : ' code'));
    if (part === 'subject') box.type = 'text';
    else box.rows = rows;
    box.value = view.current[part];
    box.spellcheck = part !== 'html';
    box.setAttribute('aria-label', label);
    box.addEventListener('input', showProblem);
    box.addEventListener('focus', () => { view.lastBox = box; });
    view.form[part] = box;
    return SS.el('label', 'field', [SS.el('span', '', label), box]);
  }

  function showProblem() {
    const problem = problemWith(editNow(), view.current.original);
    view.problem.textContent = problem || '';
    view.problem.hidden = !problem;
    view.saveBtn.disabled = !!problem || !isDirty();
    view.previewBtn.disabled = !!problem;
    view.testBtn.disabled = !!problem;
    return problem;
  }

  function placeholderList() {
    const chips = Object.entries(view.current.placeholders).map(([name, holds]) => {
      const token = '{{' + name + '}}';
      const b = SS.button(token, () => {
        const box = view.lastBox || view.form.html;
        const from = box.selectionStart === null ? box.value.length : box.selectionStart;
        const to = box.selectionEnd === null ? from : box.selectionEnd;
        box.value = box.value.slice(0, from) + token + box.value.slice(to);
        box.focus();
        box.selectionStart = from + token.length;
        box.selectionEnd = from + token.length;
        showProblem();
      }, 'token');
      b.title = holds;
      return SS.el('div', 'placeholder', [b, SS.el('span', 'muted tiny', holds)]);
    });
    return SS.el('div', 'card', [
      SS.el('h3', '', 'Placeholders'),
      SS.el('p', 'muted tiny', 'Each one must stay in its part of the email. Press one to put it back where the cursor is.'),
      SS.el('div', 'placeholder-list', chips),
    ]);
  }

  async function refreshPreview() {
    const r = await SS.apiJson('/admin/email-templates/' + view.current.key + '/preview', { method: 'POST', auth: true, body: editNow() });
    if (r.status !== 200) {
      SS.toast(SS.messageOf(r, 'The preview could not be made.'), 'err');
      return;
    }
    view.previewSubject.textContent = r.body.subject;
    // No scripts or links out of the frame: sandbox with nothing allowed.
    view.previewFrame.srcdoc = r.body.html;
    view.previewText.textContent = r.body.text;
  }

  async function save() {
    view.saveBtn.disabled = true;
    const r = await SS.apiJson('/admin/email-templates/' + view.current.key, { method: 'PUT', auth: true, body: editNow() });
    if (r.status !== 200) {
      SS.toast(SS.messageOf(r, 'The email could not be saved.'), 'err');
      showProblem();
      return;
    }
    SS.toast('Saved. The next email goes out with this wording.', 'ok');
    showEmail(r.body);
  }

  async function reset() {
    const yes = await SS.confirmBox({
      title: 'Go back to the original wording?',
      body: 'Your edits to this email are removed. This cannot be undone.',
      okText: 'Use original',
      danger: true,
    });
    if (!yes) return;
    const r = await SS.apiJson('/admin/email-templates/' + view.current.key, { method: 'DELETE', auth: true });
    if (r.status !== 200) {
      SS.toast(SS.messageOf(r, 'It could not be changed back.'), 'err');
      return;
    }
    SS.toast('Back to the original wording.', 'ok');
    showEmail(r.body);
  }

  async function sendTest() {
    view.testBtn.disabled = true;
    const r = await SS.apiJson('/admin/email-templates/' + view.current.key + '/test', { method: 'POST', auth: true, body: editNow() });
    view.testBtn.disabled = false;
    if (r.status !== 200) {
      SS.toast(SS.messageOf(r, 'The test email could not be sent.'), 'err');
      return;
    }
    SS.toast('Test email sent to ' + r.body.sentTo + ', with made-up values.', 'ok');
  }

  async function backToList() {
    if (isDirty() && !confirm('Your unsaved changes will be lost. Leave this email?')) return;
    renderList();
  }

  function showEmail(email) {
    view.current = email;
    view.saved = { subject: email.subject, html: email.html, text: email.text };
    view.form = {};
    view.problem = SS.el('div', 'alert err');
    view.problem.hidden = true;
    view.problem.setAttribute('role', 'alert');
    view.saveBtn = SS.button('Save', save, 'primary');
    view.previewBtn = SS.button('Refresh preview', refreshPreview);
    view.testBtn = SS.button('Send test to my email', sendTest);
    const resetBtn = SS.button('Back to original', reset, 'danger');
    resetBtn.disabled = !email.edited;

    view.previewSubject = SS.el('div', 'preview-subject');
    view.previewFrame = SS.el('iframe', 'email-preview');
    view.previewFrame.setAttribute('sandbox', '');
    view.previewFrame.title = 'Preview of the email';
    view.previewText = SS.el('pre', 'email-text');

    view.box.replaceChildren(
      SS.el('div', 'toolbar tree-bar', [
        SS.button('All emails', backToList),
        SS.el('div', 'email-title', [SS.el('b', '', email.name), SS.el('span', 'muted tiny', email.audience)]),
        SS.el('span', 'spacer'),
        resetBtn,
        view.testBtn,
        view.saveBtn,
      ]),
      view.problem,
      SS.el('div', 'email-layout', [
        SS.el('div', 'email-edit', [
          SS.el('div', 'card', [
            area('subject', 'Subject'),
            area('html', 'HTML version', 16),
            area('text', 'Text version, for email apps that do not show HTML', 10),
          ]),
          placeholderList(),
        ]),
        SS.el('div', 'email-side', [
          SS.el('div', 'card', [
            SS.el('div', 'detail-head', [SS.el('h3', '', 'Preview, with made-up values'), view.previewBtn]),
            view.previewSubject,
            view.previewFrame,
            SS.el('details', '', [SS.el('summary', '', 'Text version'), view.previewText]),
          ]),
        ]),
      ]),
    );
    showProblem();
    refreshPreview();
  }

  async function openEmail(key) {
    view.box.replaceChildren(SS.loadingBox('Loading the email…'));
    const r = await SS.apiJson('/admin/email-templates/' + key, { auth: true });
    if (r.status !== 200) {
      view.box.replaceChildren(SS.errorBox(SS.messageOf(r, 'The email could not be loaded.'), () => openEmail(key)));
      return;
    }
    showEmail(r.body);
  }

  window.SSPages.email = {
    render(box) {
      view.box = box;
      renderList();
    },
    unsaved: () => isDirty(),
  };
})();
