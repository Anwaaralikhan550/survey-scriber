import { useCallback, useEffect, useRef, useState } from 'react';
import { ApiError, photoApi } from './api.js';

export const ALLOWED_TYPES = ['image/jpeg', 'image/png'];
export const MAX_BYTES = 10 * 1024 * 1024;

/** The first thing wrong with a picked file, before anything is sent. The server checks everything again. */
export function checkFile(file) {
  if (!ALLOWED_TYPES.includes(file.type)) return `${file.name}: only JPEG and PNG photos can be added.`;
  if (file.size > MAX_BYTES) return `${file.name}: the photo is larger than 10 MB.`;
  if (file.size === 0) return `${file.name}: the file is empty.`;
  return null;
}

/**
 * Photos of the report (spec section 9). Every change names the report version it was made against and takes the
 * new version from the reply, so photo changes and text saves stay on one version line. One change at a time.
 * `editor` supplies the current version and is told the new one (`editor.syncVersion`).
 */
export function usePhotos({ reportId, editor, readOnly }) {
  const { syncVersion, refreshServer } = editor; // stable functions: the editor object itself changes every render
  const [photos, setPhotos] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState({}); // photoId -> 'saving' | 'replacing' | 'deleting'
  const [uploads, setUploads] = useState([]); // { id, name, progress, state: 'waiting'|'uploading'|'failed', message }
  const versionRef = useRef(editor.server.version);
  // A text save can move the version too, so follow the editor; our own changes set it at once, before React renders.
  useEffect(() => {
    versionRef.current = editor.server.version;
  }, [editor.server.version]);
  const bump = useCallback(
    (v) => {
      versionRef.current = v;
      syncVersion(v);
    },
    [syncVersion],
  );
  const queue = useRef(Promise.resolve());
  const files = useRef(new Map());
  const alive = useRef(true);
  useEffect(() => () => (alive.current = false), []);

  const load = useCallback(async () => {
    try {
      const l = await photoApi.list(reportId);
      if (!alive.current) return;
      setPhotos(l.photos);
      if (l.version !== versionRef.current) bump(l.version);
      setError('');
    } catch (e) {
      if (alive.current) setError(e.message);
    } finally {
      if (alive.current) setLoading(false);
    }
  }, [reportId, bump]);

  useEffect(() => {
    load();
  }, [load]);

  const guard = useCallback(
    async (fn) => {
      try {
        setError('');
        return await fn();
      } catch (e) {
        if (!(e instanceof ApiError)) throw e;
        if (e.code === 'VERSION_CONFLICT') {
          await load();
          setError('The report changed while you were working. The photos were reloaded; please try again.');
        } else if (e.code === 'LINK_EXPIRED' || e.code === 'REPORT_FINALISED' || e.code === 'LINK_REVOKED') {
          setError(e.code === 'LINK_REVOKED' ? 'Your access to this report has ended.' : 'This report can no longer be changed.');
          await refreshServer().catch(() => {});
        } else {
          setError(e.message);
        }
        return null;
      }
    },
    [load, refreshServer],
  );

  const applyResult = useCallback(
    (r, replacedId) => {
      bump(r.version);
      setPhotos((list) => {
        const without = list.filter((p) => p.id !== (replacedId || r.photo?.id));
        return r.photo ? [...without, r.photo] : without;
      });
    },
    [bump],
  );

  const mark = (id, v) => setBusy((b) => (v ? { ...b, [id]: v } : Object.fromEntries(Object.entries(b).filter(([k]) => k !== id))));

  const run = useCallback(
    (id, kind, fn) => {
      mark(id, kind);
      // One at a time, in the order asked: each change reads the report version when it starts, after the one before
      // has stored its new version. Two quick changes on different photos must not collide with each other (409).
      const done = queue.current.then(() => guard(fn));
      queue.current = done.catch(() => undefined);
      return done.finally(() => alive.current && mark(id, null));
    },
    [guard],
  );

  // After a change that renumbers other photos, the list is read again: the server is the source of truth.
  const reloadSoon = load;

  const addFiles = useCallback(
    (picked, sectionKey) => {
      if (readOnly) return;
      const items = [];
      const problems = [];
      for (const file of picked) {
        const problem = checkFile(file);
        if (problem) problems.push(problem);
        else items.push({ id: crypto.randomUUID(), name: file.name, progress: 0, state: 'waiting', message: '', sectionKey, file });
      }
      setError(problems.join(' '));
      if (!items.length) return;
      for (const it of items) files.current.set(it.id, it);
      setUploads((u) => [...u, ...items.map(({ file, ...rest }) => rest)]);
      for (const it of items) queue.current = queue.current.then(() => sendOne(it.id));
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [readOnly],
  );

  const sendOne = async (uploadId) => {
    const it = files.current.get(uploadId);
    if (!it || !alive.current) return;
    const patch = (p) => alive.current && setUploads((u) => u.map((x) => (x.id === uploadId ? { ...x, ...p } : x)));
    patch({ state: 'uploading', progress: 0, message: '' });
    try {
      const r = await photoApi.upload(reportId, it.file, { expectedReportVersion: versionRef.current, sectionKey: it.sectionKey }, (p) => patch({ progress: p }));
      applyResult(r);
      files.current.delete(uploadId);
      if (alive.current) setUploads((u) => u.filter((x) => x.id !== uploadId));
    } catch (e) {
      if (e instanceof ApiError && e.code === 'VERSION_CONFLICT') {
        await load(); // a newer version: take it and send again once, with the right version
        try {
          const r = await photoApi.upload(reportId, it.file, { expectedReportVersion: versionRef.current, sectionKey: it.sectionKey }, (p) => patch({ progress: p }));
          applyResult(r);
          files.current.delete(uploadId);
          if (alive.current) setUploads((u) => u.filter((x) => x.id !== uploadId));
          return;
        } catch (e2) {
          patch({ state: 'failed', message: e2.message });
          return;
        }
      }
      patch({ state: 'failed', message: e.message || 'Upload failed' });
    }
  };

  const retry = useCallback((uploadId) => {
    queue.current = queue.current.then(() => sendOne(uploadId));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const dismiss = useCallback((uploadId) => {
    files.current.delete(uploadId);
    setUploads((u) => u.filter((x) => x.id !== uploadId));
  }, []);

  const setCaption = useCallback(
    (photo, caption) =>
      run(photo.id, 'saving', async () => {
        const r = await photoApi.update(reportId, photo.id, { expectedReportVersion: versionRef.current, caption: caption.trim() === '' ? null : caption });
        bump(r.version);
        setPhotos((l) => l.map((p) => (p.id === photo.id ? r.photo : p)));
      }),
    [run, reportId, bump],
  );

  const move = useCallback(
    (photo, { sectionKey, order }) =>
      run(photo.id, 'saving', async () => {
        const body = { expectedReportVersion: versionRef.current };
        if (sectionKey !== undefined) body.sectionKey = sectionKey;
        if (order !== undefined) body.order = order;
        const r = await photoApi.update(reportId, photo.id, body);
        bump(r.version);
        await reloadSoon();
      }),
    [run, reportId, bump, reloadSoon],
  );

  const replace = useCallback(
    (photo, file, onProgress) => {
      const problem = checkFile(file);
      if (problem) {
        setError(problem);
        return Promise.resolve(null);
      }
      // The current picture stays on screen until the new one is stored (spec: failed replacement keeps the old).
      return run(photo.id, 'replacing', async () => {
        const r = await photoApi.replace(reportId, photo.id, file, versionRef.current, onProgress);
        applyResult(r, r.replaced);
      });
    },
    [run, reportId, applyResult],
  );

  const remove = useCallback(
    (photo) =>
      run(photo.id, 'deleting', async () => {
        const r = await photoApi.remove(reportId, photo.id, versionRef.current);
        bump(r.version);
        await reloadSoon();
      }),
    [run, reportId, bump, reloadSoon],
  );

  return { photos, loading, error, setError, busy, uploads, addFiles, retry, dismiss, setCaption, move, replace, remove, reload: load };
}
