import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { api, ApiError } from './api.js';
import { applyOps, chunkOps, clone, diffContent, normalise, same } from './diff.js';

const AUTOSAVE_MS = 2000;
const RETRY_MS = 5000;
const COALESCE_MS = 1000;
const HISTORY_LIMIT = 100;

/**
 * All editing state: the server copy, the working copy, undo/redo, and the save state machine.
 * States: saved | unsaved | saving | failed | offline | conflict | readonly | lost
 * "Saved" is only ever shown after the server confirmed the version (spec section 7 Screen B).
 */
export function useEditor(initial) {
  const [server, setServer] = useState(() => ({ ...initial, content: normalise(initial.content) }));
  const [cur, setCurState] = useState(() => normalise(initial.content));
  const [past, setPast] = useState([]);
  const [future, setFuture] = useState([]);
  const [saveState, setSaveStateRaw] = useState(initial.readOnly ? 'readonly' : 'saved');
  const stateRef = useRef(initial.readOnly ? 'readonly' : 'saved');
  // The ref is updated at once, so a second save() fired in the same moment already sees e.g. 'conflict'.
  const setSaveState = useCallback((v) => {
    stateRef.current = v;
    setSaveStateRaw(v);
  }, []);
  const [lastSavedAt, setLastSavedAt] = useState(null);
  const [message, setMessage] = useState('');
  const [conflict, setConflict] = useState(null); // { serverVersion, mine: ops, theirs: fresh }

  const serverRef = useRef(server);
  const curRef = useRef(cur);
  serverRef.current = server;
  curRef.current = cur;
  const inFlight = useRef(false);
  const rerun = useRef(false);
  const lastKey = useRef({ key: null, at: 0 });
  const retryKey = useRef({ sig: '', key: '' });
  const timer = useRef(null);

  const readOnly = server.readOnly || saveState === 'lost';
  const pending = useMemo(() => diffContent(server.content, cur), [server.content, cur]);
  const dirty = pending.length > 0;

  /** Change the working copy. Edits sharing a key within a second are one undo step (typing). */
  const edit = useCallback(
    (producer, key = null) => {
      if (readOnly) return;
      const before = curRef.current;
      const next = clone(before);
      producer(next);
      next.forEach((s) => s.blocks.forEach((b, i) => (b.order = i)));
      if (same(before, next)) return;
      const now = Date.now();
      const merge = key && lastKey.current.key === key && now - lastKey.current.at < COALESCE_MS;
      lastKey.current = { key, at: now };
      if (!merge) setPast((p) => [...p.slice(-(HISTORY_LIMIT - 1)), before]);
      setFuture([]);
      setCurState(next);
    },
    [readOnly],
  );

  const undo = useCallback(() => {
    setPast((p) => {
      if (!p.length) return p;
      setFuture((f) => [curRef.current, ...f]);
      setCurState(p[p.length - 1]);
      lastKey.current = { key: null, at: 0 };
      return p.slice(0, -1);
    });
  }, []);

  const redo = useCallback(() => {
    setFuture((f) => {
      if (!f.length) return f;
      setPast((p) => [...p, curRef.current]);
      setCurState(f[0]);
      lastKey.current = { key: null, at: 0 };
      return f.slice(1);
    });
  }, []);

  const fail = useCallback((e) => {
    if (e instanceof ApiError) {
      if (e.code === 'VERSION_CONFLICT') return 'conflict';
      if (e.code === 'NETWORK') return 'offline';
      if (e.code === 'LINK_EXPIRED' || e.code === 'REPORT_FINALISED') return 'readonly';
      if (e.code === 'LINK_REVOKED' || e.code === 'LINK_INVALID') return 'lost';
    }
    return 'failed';
  }, []);

  const loadLatest = useCallback(async () => {
    const fresh = await api.read(serverRef.current.reportId);
    fresh.content = normalise(fresh.content);
    setServer(fresh);
    return fresh;
  }, []);

  const save = useCallback(async () => {
    if (inFlight.current) {
      rerun.current = true;
      return;
    }
    if (['conflict', 'lost', 'readonly'].includes(stateRef.current)) return; // needs the user's decision first
    const base = serverRef.current;
    const ops = diffContent(base.content, curRef.current);
    if (!ops.length) {
      if (!base.readOnly) setSaveState('saved');
      return;
    }
    inFlight.current = true;
    setSaveState('saving');
    setMessage('');
    const sent = curRef.current;
    try {
      let version = base.version;
      for (const chunk of chunkOps(ops)) {
        const sig = `${version}:${JSON.stringify(chunk)}`;
        if (retryKey.current.sig !== sig) retryKey.current = { sig, key: crypto.randomUUID() };
        const r = await api.save(base.reportId, { baseVersion: version, changes: chunk, idempotencyKey: retryKey.current.key });
        version = r.version;
        retryKey.current = { sig: '', key: '' };
      }
      const fresh = await loadLatest();
      setLastSavedAt(new Date());
      lastKey.current = { key: null, at: 0 }; // typing after a save is a new undo step
      if (same(sent, curRef.current)) {
        setCurState(fresh.content); // take the server's cleaned-up text
        setSaveState('saved');
      } else {
        setSaveState(diffContent(fresh.content, curRef.current).length ? 'unsaved' : 'saved');
      }
    } catch (e) {
      const next = fail(e);
      rerun.current = false; // a failed save is never repeated behind the user's back (conflict dialog, retry timer decide)
      setMessage(e.message || 'Save failed');
      if (next === 'conflict') {
        const serverVersion = e.details?.serverVersion;
        try {
          const theirs = await loadLatest();
          setConflict({ serverVersion: serverVersion ?? theirs.version, mine: ops, theirs });
        } catch {
          setConflict({ serverVersion, mine: ops, theirs: null });
        }
      }
      if (next === 'readonly') {
        try {
          await loadLatest();
        } catch {
          /* keep the working copy visible */
        }
      }
      setSaveState(next);
    } finally {
      inFlight.current = false;
      if (rerun.current) {
        rerun.current = false;
        save();
      }
    }
  }, [fail, loadLatest, setSaveState]);

  // Autosave: 2 s after the last change; transient failures retry by themselves (same idempotency key).
  useEffect(() => {
    clearTimeout(timer.current);
    if (readOnly || !dirty || ['saving', 'conflict', 'lost', 'readonly'].includes(saveState)) return undefined;
    if (saveState === 'saved') {
      setSaveState('unsaved');
      return undefined;
    }
    timer.current = setTimeout(save, saveState === 'unsaved' ? AUTOSAVE_MS : RETRY_MS);
    return () => clearTimeout(timer.current);
  }, [cur, dirty, saveState, readOnly, save]);

  useEffect(() => {
    const online = () => dirty && save();
    window.addEventListener('online', online);
    return () => window.removeEventListener('online', online);
  }, [dirty, save]);

  /** Spec 10: flush on blur and navigation. */
  const flush = useCallback(() => {
    clearTimeout(timer.current);
    return dirty && !readOnly ? save() : Promise.resolve();
  }, [dirty, readOnly, save]);

  /** Reload latest from the server, dropping local edits. */
  const reloadLatest = useCallback(async () => {
    const fresh = await loadLatest();
    setCurState(fresh.content);
    setPast([]);
    setFuture([]);
    setConflict(null);
    setMessage('');
    setSaveState(fresh.readOnly ? 'readonly' : 'saved');
  }, [loadLatest, setSaveState]);

  /** After a conflict: put my own pending changes on top of the newer server content, if they still fit. */
  const reapplyMine = useCallback(async () => {
    if (!conflict) return { ok: false };
    const theirs = conflict.theirs || (await loadLatest());
    try {
      const merged = normalise(applyOps(theirs.content, conflict.mine));
      setServer({ ...theirs, content: normalise(theirs.content) });
      setCurState(merged);
      setConflict(null);
      setSaveState('unsaved');
      return { ok: true };
    } catch (e) {
      return { ok: false, reason: e.message };
    }
  }, [conflict, loadLatest, setSaveState]);

  return { server, cur, pending, dirty, readOnly, saveState, lastSavedAt, message, conflict, canUndo: past.length > 0, canRedo: future.length > 0, edit, undo, redo, save, flush, reloadLatest, reapplyMine };
}
