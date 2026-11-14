/**
 * Phrase-bank logic shared by the browser portal and the Node tests.
 *
 * A bank is either a flat {key: text} map (Home Survey / inspection) or
 * {meta, templates: {id: {screenId, text, ...}}} (valuation). Every edit is
 * token-preserving: the set of {TOKEN} placeholders must not change unless the
 * editor explicitly overrides, because the report engine substitutes them.
 */
(function (root, factory) {
  if (typeof module === 'object' && module.exports) module.exports = factory();
  else root.BankLogic = factory();
})(typeof self !== 'undefined' ? self : this, function () {
  'use strict';

  const TOKEN_RE = /\{[A-Z0-9_]+\}/g;
  const tokens = (s) => String(s).match(TOKEN_RE) || [];
  const tokenSet = (s) => [...new Set(tokens(s))].sort();

  const isTemplatesBank = (raw) =>
    !!raw && typeof raw.templates === 'object' && raw.templates !== null && !Array.isArray(raw.templates);

  const textOfTemplate = (t) => (typeof t === 'string' ? t : String((t && t.text) || ''));

  /** Editable entries of a bank, whatever its shape. */
  function entriesOf(raw) {
    if (isTemplatesBank(raw)) {
      return Object.entries(raw.templates).map(([key, t]) => {
        const value = textOfTemplate(t);
        return { key, value, tokens: tokenSet(value), screenId: (t && t.screenId) || undefined };
      });
    }
    return Object.entries(raw || {}).map(([key, value]) => ({ key, value, tokens: tokenSet(value) }));
  }

  function currentText(raw, key) {
    if (isTemplatesBank(raw)) return key in raw.templates ? textOfTemplate(raw.templates[key]) : undefined;
    return raw && key in raw ? raw[key] : undefined;
  }

  /** Writes the new text in place (a valuation template keeps its screenId and other fields). */
  function setText(raw, key, value) {
    if (isTemplatesBank(raw)) {
      const t = raw.templates[key];
      raw.templates[key] = typeof t === 'object' && t !== null ? { ...t, text: value } : value;
    } else {
      raw[key] = value;
    }
  }

  /** Token-preserving edit of one entry. Returns {status, body}; mutates `raw` only on success. */
  function applyEdit(raw, key, value, force = false) {
    if (!key) return { status: 400, body: { error: 'Missing key' } };
    const old = currentText(raw, key);
    if (old === undefined) return { status: 404, body: { error: 'Key not found: ' + key } };
    const before = tokenSet(old);
    const after = tokenSet(value);
    const removed = before.filter((t) => !after.includes(t));
    const added = after.filter((t) => !before.includes(t));
    if (!force && (removed.length || added.length)) {
      return {
        status: 409,
        body: {
          error: 'placeholder_mismatch', removed, added,
          message:
            'This edit changes the {TOKEN} placeholders. Removing or adding a ' +
            'token can break the report. Fix the tokens, or re-save with ' +
            'Override if you are certain.',
        },
      };
    }
    setText(raw, key, value);
    return { status: 200, body: { ok: true, key, tokens: after } };
  }

  /** Number of editable phrases (what the server's shrink guard counts). */
  const entryCount = (raw) => (isTemplatesBank(raw) ? Object.keys(raw.templates).length : Object.keys(raw || {}).length);

  /** Bank type names used by the server API. */
  const API_TYPE = { inspection: 'inspection_phrases', valuation: 'valuation_phrases' };

  return { tokenSet, isTemplatesBank, textOfTemplate, entriesOf, currentText, setText, applyEdit, entryCount, API_TYPE };
});
