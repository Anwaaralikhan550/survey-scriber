'use strict';
/**
 * Building blocks of the admin pages. Text always goes in through textContent,
 * so a name or an option typed by anyone can never run as HTML.
 */
window.SSPages = window.SSPages || {};
window.SS = window.SS || {};

(function (SS) {
  /** el('div', 'card', 'text') or el('div', 'card', [childA, childB]) */
  SS.el = function (tag, cls, content) {
    const e = document.createElement(tag);
    if (cls) e.className = cls;
    if (Array.isArray(content)) e.append(...content.filter(Boolean));
    else if (content !== undefined && content !== null) e.textContent = content;
    return e;
  };

  SS.button = function (text, onClick, cls) {
    const b = SS.el('button', 'btn' + (cls ? ' ' + cls : ''), text);
    b.type = 'button';
    if (onClick) b.addEventListener('click', onClick);
    return b;
  };

  SS.fmtDate = function (iso) {
    if (!iso) return '';
    const d = new Date(iso);
    return d.toLocaleString(undefined, { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
  };

  SS.fmtDay = function (iso) {
    if (!iso) return '';
    return new Date(iso).toLocaleDateString(undefined, { day: 'numeric', month: 'short', year: 'numeric' });
  };

  SS.loadingBox = function (text) {
    const box = SS.el('div', 'state', [SS.el('div', 'spinner'), SS.el('p', '', text || 'Loading…')]);
    box.setAttribute('role', 'status');
    return box;
  };

  SS.emptyBox = function (title, hint) {
    return SS.el('div', 'state', [SS.el('h3', '', title), hint ? SS.el('p', '', hint) : null]);
  };

  SS.errorBox = function (message, retry) {
    const box = SS.el('div', 'state err', [
      SS.el('h3', '', 'Something went wrong'),
      SS.el('p', '', message),
      retry ? SS.button('Try again', retry) : null,
    ]);
    box.setAttribute('role', 'alert');
    return box;
  };

  /** columns: [{title, cell(row) -> text or node, cls}] */
  SS.table = function (columns, rows) {
    const head = SS.el('tr', '', columns.map((c) => SS.el('th', c.cls, c.title)));
    const body = rows.map((row) => SS.el('tr', '', columns.map((c) => {
      const value = c.cell(row);
      const td = SS.el('td', c.cls);
      if (value instanceof Node) td.append(value);
      else td.textContent = value === undefined || value === null || value === '' ? '—' : value;
      return td;
    })));
    return SS.el('div', 'table-wrap', [
      SS.el('table', 'table', [SS.el('thead', '', [head]), SS.el('tbody', '', body)]),
    ]);
  };

  /** Previous / Next with "21-40 of 57". */
  SS.pager = function (page, limit, total, onPage) {
    const from = total === 0 ? 0 : (page - 1) * limit + 1;
    const to = Math.min(page * limit, total);
    const prev = SS.button('Previous', () => onPage(page - 1));
    const next = SS.button('Next', () => onPage(page + 1));
    prev.disabled = page <= 1;
    next.disabled = to >= total;
    return SS.el('div', 'pager', [SS.el('span', 'muted', from + '-' + to + ' of ' + total), prev, next]);
  };

  function openDialog(content, onClose) {
    const dialog = SS.el('dialog', 'dialog', content);
    document.body.append(dialog);
    dialog.addEventListener('close', () => { dialog.remove(); if (onClose) onClose(); });
    dialog.showModal();
    return dialog;
  }
  SS.openDialog = openDialog;

  /** Resolves true when confirmed; Escape, Cancel and clicking away all mean no. */
  SS.confirmBox = function ({ title, body, okText, danger }) {
    return new Promise((resolve) => {
      let answer = false;
      const cancel = SS.button('Cancel', () => dialog.close());
      const ok = SS.button(okText || 'Confirm', () => { answer = true; dialog.close(); }, danger ? 'danger' : 'primary');
      const dialog = openDialog([
        SS.el('h3', '', title),
        body ? SS.el('p', 'muted', body) : null,
        SS.el('div', 'dialog-actions', [cancel, ok]),
      ], () => resolve(answer));
      cancel.focus();
    });
  };

  /**
   * fields: [{name, label, type, value, options:[{value,label}], required, hint, autocomplete}]
   * save(values) returns an error message, or nothing when done.
   */
  SS.formBox = function ({ title, intro, fields, okText, save }) {
    const inputs = {};
    const error = SS.el('div', 'alert err');
    error.hidden = true;
    error.setAttribute('role', 'alert');

    const rows = fields.map((f) => {
      let input;
      if (f.type === 'select') {
        input = SS.el('select', '', f.options.map((o) => {
          const opt = SS.el('option', '', o.label);
          opt.value = o.value;
          return opt;
        }));
      } else if (f.type === 'textarea') {
        input = SS.el('textarea');
        input.rows = f.rows || 4;
      } else {
        input = SS.el('input');
        input.type = f.type || 'text';
      }
      input.value = f.value === undefined || f.value === null ? '' : f.value;
      input.required = !!f.required;
      if (f.autocomplete) input.autocomplete = f.autocomplete;
      if (f.maxLength) input.maxLength = f.maxLength;
      inputs[f.name] = input;
      return SS.el('label', 'field', [
        SS.el('span', '', f.label + (f.required ? ' *' : '')),
        input,
        f.hint ? SS.el('small', 'muted', f.hint) : null,
      ]);
    });

    return new Promise((resolve) => {
      let saved = false;
      const cancel = SS.button('Cancel', () => dialog.close());
      const ok = SS.button(okText || 'Save', null, 'primary');
      ok.type = 'submit';
      const form = SS.el('form', 'form', [
        SS.el('h3', '', title),
        intro ? SS.el('p', 'muted', intro) : null,
        ...rows,
        error,
        SS.el('div', 'dialog-actions', [cancel, ok]),
      ]);
      form.addEventListener('submit', async (ev) => {
        ev.preventDefault();
        const values = {};
        for (const f of fields) values[f.name] = inputs[f.name].value.trim();
        ok.disabled = true;
        error.hidden = true;
        let message;
        try {
          message = await save(values);
        } catch (e) {
          message = 'Could not save. Please try again.';
        }
        ok.disabled = false;
        if (message) {
          error.textContent = message;
          error.hidden = false;
          return;
        }
        saved = true;
        dialog.close();
      });
      const dialog = openDialog([form], () => resolve(saved));
      const first = fields[0] && inputs[fields[0].name];
      if (first) first.focus();
    });
  };

  /** The server's message, which NestJS may send as a list. */
  SS.messageOf = function (r, fallback) {
    const m = r && r.body && r.body.message;
    const details = r && r.body && r.body.details;
    if (Array.isArray(details) && details.length) return details.join('. ');
    if (Array.isArray(m)) return m.join('. ');
    return m || fallback || ('Server error ' + (r ? r.status : ''));
  };

  /** Search box that waits for typing to stop. */
  SS.searchBox = function (placeholder, value, onChange) {
    const input = SS.el('input', 'search');
    input.type = 'search';
    input.placeholder = placeholder;
    input.value = value || '';
    input.setAttribute('aria-label', placeholder);
    let timer;
    input.addEventListener('input', () => {
      clearTimeout(timer);
      timer = setTimeout(() => onChange(input.value.trim()), 250);
    });
    return input;
  };
})(window.SS);
