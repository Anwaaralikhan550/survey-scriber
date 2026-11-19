import React, { useState } from 'react';
import { api } from './api.js';

/**
 * The display name of the person using the link (Remote Editor spec v1.4). The link itself proves nothing about who holds it,
 * so the name is only what the person types: it is recorded next to their changes and shown as not verified.
 */
const KEY = 'ss_reviewer_name';

export function rememberedName() {
  try {
    return localStorage.getItem(KEY) || '';
  } catch {
    return '';
  }
}

function remember(name) {
  try {
    localStorage.setItem(KEY, name);
  } catch {
    /* private mode: the name is simply asked again next time */
  }
}

/** The same rule as the server (the server decides; this only saves a round trip). Returns a message or null. */
export function nameProblem(raw) {
  const n = String(raw).replace(/\s+/g, ' ').trim();
  if (n.length < 2) return 'Please enter your name (at least 2 letters).';
  if (n.length > 80) return 'Please use at most 80 characters.';
  if (!/^[\p{L}\p{M}\p{N} .,'’()-]+$/u.test(n)) return "Please use letters, numbers, spaces and . , ' ( ) - only.";
  if ((n.match(/\p{L}/gu) || []).length < 2) return 'Please enter your name.';
  return null;
}

export function NameForm({ initial = '', onDone, submitLabel = 'Continue', autoFocus = true, secondary = null }) {
  const [name, setName] = useState(initial);
  const [touched, setTouched] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const problem = nameProblem(name);

  const submit = async (e) => {
    e.preventDefault();
    setTouched(true);
    if (problem || busy) return;
    setBusy(true);
    setError('');
    try {
      const out = await api.setName(name.replace(/\s+/g, ' ').trim());
      remember(out.name);
      onDone(out.name);
    } catch (err) {
      setError(err.message || 'The name could not be saved. Please try again.');
      setBusy(false);
    }
  };

  return (
    <form className="name-form" onSubmit={submit} noValidate>
      <label htmlFor="reviewer-name">Your name</label>
      <input
        id="reviewer-name"
        type="text"
        autoComplete="name"
        autoFocus={autoFocus}
        value={name}
        maxLength={100}
        aria-invalid={touched && problem ? 'true' : 'false'}
        aria-describedby="reviewer-name-help"
        onChange={(e) => setName(e.target.value)}
        onBlur={() => setTouched(true)}
      />
      <p id="reviewer-name-help" className={touched && problem ? 'help bad' : 'help'}>
        {touched && problem ? problem : 'Shown to the report owner and recorded with the changes you make. It is not verified.'}
      </p>
      {error ? (
        <p className="help bad" role="alert">
          {error}
        </p>
      ) : null}
      <div className="name-actions">
        {secondary}
        <button type="submit" className="primary big" disabled={busy || !!problem}>
          {busy ? 'Saving…' : submitLabel}
        </button>
      </div>
    </form>
  );
}
