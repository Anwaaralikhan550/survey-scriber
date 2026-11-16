import React, { useEffect, useMemo, useRef, useState } from 'react';
import { photoUrl } from './api.js';
import { Dialog, Icon, ICONS } from './ui.jsx';

const NO_SECTION = '__none__';
const fmtSize = (n) => (n >= 1048576 ? `${(n / 1048576).toFixed(1)} MB` : `${Math.max(1, Math.round(n / 1024))} KB`);

function PhotoCard({ photo, reportId, sections, siblings, index, readOnly, busy, onCaption, onMove, onReplace, onDelete }) {
  const [caption, setCaption] = useState(photo.caption || '');
  const [progress, setProgress] = useState(null);
  const file = useRef(null);
  const [broken, setBroken] = useState(false);
  const [attempt, setAttempt] = useState(0); // a picture that fails to load is asked for again a couple of times before giving up
  // A new picture or a changed record is a new chance for the thumbnail.
  useEffect(() => {
    setBroken(false);
    setAttempt(0);
  }, [photo.updatedAt, photo.id]);
  const saved = (photo.caption || '') === caption;
  const working = !!busy;

  return (
    <article className={`photo${working ? ' is-busy' : ''}`} data-photo-id={photo.id} aria-busy={working}>
      <div className="thumb">
        {broken ? (
          <div className="thumb-missing">Picture unavailable</div>
        ) : (
          <img
            src={`${photoUrl(reportId, photo.id)}?v=${encodeURIComponent(photo.updatedAt)}&r=${attempt}`}
            alt={photo.caption || photo.fileName}
            loading="lazy"
            onError={() => (attempt < 2 ? setTimeout(() => setAttempt((a) => a + 1), 1200) : setBroken(true))}
          />
        )}
        {busy === 'replacing' ? (
          <div className="thumb-progress" role="progressbar" aria-valuenow={Math.round((progress ?? 0) * 100)}>
            <span style={{ width: `${Math.round((progress ?? 0) * 100)}%` }} />
          </div>
        ) : null}
        {busy ? <div className="thumb-busy">{busy === 'replacing' ? 'Replacing…' : busy === 'deleting' ? 'Deleting…' : 'Saving…'}</div> : null}
      </div>
      <div className="photo-body">
        <div className="photo-file" title={photo.fileName}>
          {photo.fileName} <span className="muted">· {fmtSize(photo.size)}</span>
        </div>
        <label className="field">
          <span>Caption</span>
          <textarea
            rows={2}
            maxLength={1000}
            value={caption}
            disabled={readOnly || working}
            placeholder="Add a caption"
            onChange={(e) => setCaption(e.target.value)}
            onBlur={() => !saved && onCaption(photo, caption)}
          />
        </label>
        <label className="field">
          <span>Section</span>
          <select value={photo.sectionKey || NO_SECTION} disabled={readOnly || working} onChange={(e) => onMove(photo, { sectionKey: e.target.value === NO_SECTION ? null : e.target.value, order: 0 })}>
            <option value={NO_SECTION}>No section</option>
            {sections.map((s) => (
              <option key={s.key} value={s.key}>
                {s.title}
              </option>
            ))}
          </select>
        </label>
        {!readOnly && (
          <div className="photo-tools">
            <button type="button" className="icon" aria-label="Move earlier" title="Move earlier" disabled={working || index === 0} onClick={() => onMove(photo, { order: index - 1 })}>
              <Icon d={ICONS.left} />
            </button>
            <button type="button" className="icon" aria-label="Move later" title="Move later" disabled={working || index === siblings - 1} onClick={() => onMove(photo, { order: index + 1 })}>
              <Icon d={ICONS.right} />
            </button>
            <button type="button" className="secondary small-btn" disabled={working} onClick={() => file.current && file.current.click()}>
              <Icon d={ICONS.swap} /> Replace
            </button>
            <input
              ref={file}
              type="file"
              accept="image/jpeg,image/png"
              hidden
              aria-label={`Replacement picture for ${photo.fileName}`}
              onChange={(e) => {
                const f = e.target.files && e.target.files[0];
                e.target.value = '';
                if (f) {
                  setProgress(0);
                  onReplace(photo, f, setProgress);
                }
              }}
            />
            <button type="button" className="icon danger" aria-label="Delete photo" title="Delete" disabled={working} onClick={() => onDelete(photo)}>
              <Icon d={ICONS.trash} />
            </button>
          </div>
        )}
      </div>
    </article>
  );
}

/** Photograph manager (spec Screen D): thumbnails, upload, replace, captions, order, section, delete. */
export default function Photos({ reportId, photosState, sections, readOnly }) {
  const { photos, loading, error, setError, busy, uploads, addFiles, retry, dismiss, setCaption, move, replace, remove, reload } = photosState;
  const [filter, setFilter] = useState('all');
  const [confirm, setConfirm] = useState(null);
  const [over, setOver] = useState(false);
  const picker = useRef(null);

  const groups = useMemo(() => {
    const out = sections.map((s) => ({ key: s.key, title: s.title, items: photos.filter((p) => p.sectionKey === s.key).sort((a, b) => a.sortOrder - b.sortOrder) }));
    out.push({ key: NO_SECTION, title: 'No section', items: photos.filter((p) => !p.sectionKey || !sections.some((s) => s.key === p.sectionKey)).sort((a, b) => a.sortOrder - b.sortOrder) });
    return out.filter((g) => g.items.length && (filter === 'all' || filter === g.key));
  }, [photos, sections, filter]);

  const target = filter !== 'all' && filter !== NO_SECTION ? filter : undefined;

  return (
    <section
      className={`photos${over ? ' is-over' : ''}`}
      aria-label="Photographs"
      onDragOver={(e) => {
        if (readOnly) return;
        e.preventDefault();
        setOver(true);
      }}
      onDragLeave={() => setOver(false)}
      onDrop={(e) => {
        e.preventDefault();
        setOver(false);
        if (!readOnly) addFiles([...e.dataTransfer.files], target);
      }}
    >
      <div className="photos-head">
        <h1>Photographs</h1>
        <label className="field inline">
          <span>Show</span>
          <select value={filter} onChange={(e) => setFilter(e.target.value)}>
            <option value="all">All photographs ({photos.length})</option>
            {sections.map((s) => (
              <option key={s.key} value={s.key}>
                {s.title} ({photos.filter((p) => p.sectionKey === s.key).length})
              </option>
            ))}
            <option value={NO_SECTION}>No section ({photos.filter((p) => !p.sectionKey).length})</option>
          </select>
        </label>
        {!readOnly && (
          <>
            <button type="button" className="primary" onClick={() => picker.current && picker.current.click()}>
              <Icon d={ICONS.upload} /> Add photographs
            </button>
            <input
              ref={picker}
              type="file"
              multiple
              accept="image/jpeg,image/png"
              hidden
              aria-label="Choose photographs to add"
              onChange={(e) => {
                addFiles([...e.target.files], target);
                e.target.value = '';
              }}
            />
          </>
        )}
      </div>
      {!readOnly && <p className="muted small">JPEG or PNG, up to 10 MB each. You can also drop files here. Location and camera details are removed from every photo.</p>}

      {error ? (
        <div className="banner banner-failed inline-banner" role="alert">
          {error}
          <button type="button" className="link" onClick={() => (setError(''), reload())}>
            Reload photographs
          </button>
        </div>
      ) : null}

      {uploads.length ? (
        <ul className="uploads" aria-label="Uploads">
          {uploads.map((u) => (
            <li key={u.id} className={`upload upload-${u.state}`} data-upload-state={u.state}>
              <span className="upload-name">{u.name}</span>
              {u.state === 'failed' ? (
                <>
                  <span className="upload-msg" role="alert">
                    {u.message}
                  </span>
                  <button type="button" className="link" onClick={() => retry(u.id)}>
                    Retry
                  </button>
                  <button type="button" className="link" onClick={() => dismiss(u.id)}>
                    Dismiss
                  </button>
                </>
              ) : (
                <span className="bar" role="progressbar" aria-valuenow={Math.round(u.progress * 100)}>
                  <span style={{ width: `${Math.round(u.progress * 100)}%` }} />
                </span>
              )}
            </li>
          ))}
        </ul>
      ) : null}

      {loading ? <p className="muted">Loading photographs…</p> : null}
      {!loading && !photos.length && !uploads.length ? <p className="empty">No photographs yet.{readOnly ? '' : ' Add some with the button above.'}</p> : null}

      {groups.map((g) => (
        <div key={g.key} className="photo-group">
          <h2>
            {g.title} <span className="muted">({g.items.length})</span>
          </h2>
          <div className="photo-grid">
            {g.items.map((p, i) => (
              <PhotoCard
                key={p.id}
                photo={p}
                reportId={reportId}
                sections={sections}
                siblings={g.items.length}
                index={i}
                readOnly={readOnly}
                busy={busy[p.id]}
                onCaption={setCaption}
                onMove={move}
                onReplace={replace}
                onDelete={(photo) => setConfirm(photo)}
              />
            ))}
          </div>
        </div>
      ))}

      {confirm ? (
        <Dialog
          title="Delete this photograph?"
          onClose={() => setConfirm(null)}
          actions={
            <>
              <button type="button" className="secondary" onClick={() => setConfirm(null)}>
                Cancel
              </button>
              <button
                type="button"
                className="danger-btn"
                autoFocus
                onClick={() => {
                  const photo = confirm;
                  setConfirm(null);
                  remove(photo);
                }}
              >
                Delete
              </button>
            </>
          }
        >
          <p>It is removed from the report and from the owner's phone the next time they synchronise. This cannot be undone from here.</p>
        </Dialog>
      ) : null}
    </section>
  );
}
