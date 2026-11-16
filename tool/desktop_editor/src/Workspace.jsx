import React, { useCallback, useEffect, useMemo, useState } from 'react';
import TextEditor from './TextEditor.jsx';
import { useEditor } from './useEditor.js';
import { api } from './api.js';
import { Dialog, Icon, ICONS } from './ui.jsx';
import Photos from './Photos.jsx';
import Review, { STATUS_LABEL } from './Review.jsx';
import { usePhotos } from './usePhotos.js';

const TYPE_NAMES = { L2: 'Home Survey Level 2', L3: 'Home Survey Level 3', VALUATION: 'Valuation' };
const RATINGS = ['NI', '1', '2', '3'];
const BLOCK_LABEL = { paragraph: 'Paragraph', rating: 'Condition rating', recommendation: 'Recommendation', photo: 'Photograph', table: 'Table' };

const REASONS = {
  'block not found': 'a paragraph you changed was removed',
  'section not found': 'the section you changed was removed',
  'afterBlockId not found': 'the paragraph next to your change was removed',
  'block id already exists': 'the same paragraph was added by someone else',
  'required block': 'a template field cannot be removed or moved',
};
const friendly = (r) => REASONS[r] || 'it no longer fits';
const fmt = (d) => new Date(d).toLocaleString(undefined, { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' });
function remaining(to, now) {
  const ms = new Date(to).getTime() - now;
  if (ms <= 0) return 'expired';
  const h = Math.floor(ms / 3600000);
  const m = Math.floor((ms % 3600000) / 60000);
  return h >= 24 ? `${Math.floor(h / 24)}d ${h % 24}h left` : h ? `${h}h ${m}m left` : `${m}m left`;
}

const SAVE_LABEL = {
  saved: 'Saved',
  unsaved: 'Unsaved changes',
  saving: 'Saving…',
  failed: 'Save failed',
  offline: 'Offline: changes kept, will retry',
  conflict: 'Newer version on server',
  readonly: 'Read-only',
  lost: 'Access ended',
};

function Block({ block, index, count, sections, sectionId, readOnly, active, onActivate, onEdit, onMove, onDelete, onMoveTo, onBlur }) {
  const label = BLOCK_LABEL[block.type] || 'Block';
  const field = block.type === 'recommendation' ? 'recommendation' : 'text';
  const body = (() => {
    if (block.type === 'rating') {
      return (
        <label className="rating">
          <span>Rating</span>
          <select value={block.rating || ''} disabled={readOnly} onChange={(e) => onEdit((b) => (b.rating = e.target.value))}>
            {RATINGS.map((r) => (
              <option key={r} value={r}>
                {r}
              </option>
            ))}
          </select>
          {block.text ? <span className="muted">{block.text}</span> : null}
        </label>
      );
    }
    if (block.type === 'photo') {
      return <p className="muted">Photograph reference {block.photoId ? block.photoId.slice(0, 8) : ''}. Photos are managed in the photo panel.</p>;
    }
    if (block.type === 'table' && block.table) {
      return (
        <div className="tablewrap">
          <table>
            <thead>
              <tr>
                {block.table.headers.map((h, i) => (
                  <th key={i}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {block.table.rows.map((row, r) => (
                <tr key={r}>
                  {row.map((cell, c) => (
                    <td key={c}>
                      <input
                        value={cell}
                        readOnly={readOnly}
                        aria-label={`${block.table.headers[c]} row ${r + 1}`}
                        onChange={(e) => onEdit((b) => (b.table.rows[r][c] = e.target.value), `${block.id}:${r}:${c}`)}
                        onBlur={onBlur}
                      />
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      );
    }
    const value = block[field] ?? '';
    if (active && !readOnly) {
      return <TextEditor value={value} label={label} autoFocus onChange={(v) => onEdit((b) => (b[field] = v), block.id)} onBlur={onBlur} />;
    }
    return (
      <button type="button" className={`textview${value ? '' : ' is-empty'}`} disabled={readOnly} onClick={onActivate} aria-label={`Edit ${label.toLowerCase()}`}>
        {value || (readOnly ? '' : 'Empty. Click to write.')}
      </button>
    );
  })();

  return (
    <article className={`block block-${block.type}${active && !readOnly ? ' is-active' : ''}`} data-block-id={block.id}>
      <header>
        <span className="block-label">{label}</span>
        {block.required ? <span className="badge" title="Template field: can be edited, not deleted">Template field</span> : null}
        {!readOnly && (
          <span className="block-tools">
            <button type="button" className="icon" aria-label="Move up" disabled={index === 0} onClick={() => onMove(-1)}>
              <Icon d={ICONS.up} />
            </button>
            <button type="button" className="icon" aria-label="Move down" disabled={index === count - 1} onClick={() => onMove(1)}>
              <Icon d={ICONS.down} />
            </button>
            {!block.required && sections.length > 1 && (
              <select aria-label="Move to another section" value="" onChange={(e) => e.target.value && onMoveTo(e.target.value)}>
                <option value="">Move to…</option>
                {sections.filter((s) => s.id !== sectionId).map((s) => (
                  <option key={s.id} value={s.id}>
                    {s.title}
                  </option>
                ))}
              </select>
            )}
            <button type="button" className="icon danger" aria-label="Delete" disabled={!!block.required} title={block.required ? 'Template fields cannot be deleted' : 'Delete'} onClick={onDelete}>
              <Icon d={ICONS.trash} />
            </button>
          </span>
        )}
      </header>
      {body}
    </article>
  );
}

export default function Workspace({ initial, onExit }) {
  const ed = useEditor(initial);
  const { server, cur, readOnly, saveState, dirty } = ed;
  const [sectionId, setSectionId] = useState(cur[0]?.id);
  const [activeId, setActiveId] = useState(null);
  const [dialog, setDialog] = useState(null);
  const [view, setView] = useState('report'); // 'report' | 'photos' | 'review'
  const photosState = usePhotos({ reportId: server.reportId, editor: ed, readOnly });
  const [now, setNow] = useState(Date.now());

  useEffect(() => {
    const t = setInterval(() => setNow(Date.now()), 30000);
    return () => clearInterval(t);
  }, []);

  const section = cur.find((s) => s.id === sectionId) || cur[0];
  const touched = useMemo(() => new Set(ed.pending.map((o) => o.sectionId).concat(ed.pending.map((o) => o.toSectionId).filter(Boolean))), [ed.pending]);

  // Unsaved-exit warning (browser tab close or reload).
  useEffect(() => {
    const h = (e) => {
      if (dirty || saveState === 'saving') {
        e.preventDefault();
        e.returnValue = '';
      }
    };
    window.addEventListener('beforeunload', h);
    return () => window.removeEventListener('beforeunload', h);
  }, [dirty, saveState]);

  useEffect(() => {
    const k = (e) => {
      const mod = e.ctrlKey || e.metaKey;
      if (!mod) return;
      const key = e.key.toLowerCase();
      if (key === 's') {
        e.preventDefault();
        ed.save();
      } else if (key === 'z' && !e.shiftKey) {
        e.preventDefault();
        ed.undo();
      } else if (key === 'y' || (key === 'z' && e.shiftKey)) {
        e.preventDefault();
        ed.redo();
      }
    };
    window.addEventListener('keydown', k);
    return () => window.removeEventListener('keydown', k);
  }, [ed]);

  const goSection = useCallback(
    (id) => {
      setView('report');
      setActiveId(null);
      ed.flush();
      setSectionId(id);
    },
    [ed],
  );

  const blockOps = (secId) => ({
    add: (afterId) =>
      ed.edit((c) => {
        const s = c.find((x) => x.id === secId);
        const nb = { id: crypto.randomUUID(), type: 'paragraph', text: '', order: 0 };
        const at = afterId ? s.blocks.findIndex((b) => b.id === afterId) + 1 : s.blocks.length;
        s.blocks.splice(at, 0, nb);
        setActiveId(nb.id);
      }),
    move: (id, d) =>
      ed.edit((c) => {
        const s = c.find((x) => x.id === secId);
        const i = s.blocks.findIndex((b) => b.id === id);
        const j = i + d;
        if (j < 0 || j >= s.blocks.length) return;
        [s.blocks[i], s.blocks[j]] = [s.blocks[j], s.blocks[i]];
      }),
    moveTo: (id, toId) =>
      ed.edit((c) => {
        const s = c.find((x) => x.id === secId);
        const i = s.blocks.findIndex((b) => b.id === id);
        const [b] = s.blocks.splice(i, 1);
        c.find((x) => x.id === toId).blocks.push(b);
      }),
    remove: (id) =>
      ed.edit((c) => {
        const s = c.find((x) => x.id === secId);
        s.blocks.splice(s.blocks.findIndex((b) => b.id === id), 1);
      }),
  });
  const ops = blockOps(section.id);

  const doExit = async () => {
    try {
      await api.close();
    } catch {
      /* the session ends by itself */
    }
    onExit('exited');
  };
  const askExit = () => {
    if (dirty || saveState === 'saving') setDialog('exit');
    else doExit();
  };

  const status = SAVE_LABEL[saveState] || saveState;
  const linkLeft = remaining(server.linkExpiresAt, now);

  return (
    <div className="workspace">
      <header className="topbar">
        <div className="brand-mini" aria-label="SurveyScriber">
          <span className="logo" aria-hidden="true">S</span>
        </div>
        <div className="title">
          <strong>{server.property?.jobRef || 'Report'}</strong>
          <span className="muted">{server.property?.address || server.property?.title}</span>
        </div>
        <div className="meta">
          <span className="chip">{TYPE_NAMES[server.reportType] || server.reportType}</span>
          <span className="chip" title="Report version on the server">Version {server.version}</span>
          {saveState !== 'readonly' && saveState !== 'lost' ? (
            <span className={`chip state state-${saveState}`} role="status" aria-live="polite">
              {status}
            </span>
          ) : null}
          <span className={`chip ${saveState === 'lost' ? 'state-lost' : server.readOnly ? 'chip-warn' : 'chip-ok'}`} role={saveState === 'lost' || server.readOnly ? 'status' : undefined}>
            {saveState === 'lost' ? 'Access ended' : server.readOnly ? (server.readOnlyReason === 'REPORT_FINALISED' ? 'Finalised, read-only' : 'Link expired, read-only') : 'Editing'}
          </span>
          <button type="button" className={`chip chip-btn review-chip review-${server.status}`} title="Open the review screen" onClick={() => (ed.flush(), setView('review'))}>
            {STATUS_LABEL[server.status] || server.status}
          </button>
          <span className="chip" title={`Link expires ${fmt(server.linkExpiresAt)}`}>Link: {linkLeft}</span>
        </div>
        <div className="actions">
          <button type="button" className="icon" aria-label="Undo" title="Undo (Ctrl+Z)" disabled={!ed.canUndo || readOnly} onClick={ed.undo}>
            <Icon d={ICONS.undo} />
          </button>
          <button type="button" className="icon" aria-label="Redo" title="Redo (Ctrl+Y)" disabled={!ed.canRedo || readOnly} onClick={ed.redo}>
            <Icon d={ICONS.redo} />
          </button>
          <button type="button" className="secondary" onClick={() => (dirty ? setDialog('reload') : ed.reloadLatest())}>
            Reload latest
          </button>
          {!readOnly && (server.status === 'DRAFT' || server.status === 'AMENDMENTS_REQUIRED') ? (
            <button type="button" className="secondary" onClick={() => (ed.flush(), setView('review'))}>
              Submit for review
            </button>
          ) : null}
          <button type="button" className="primary" disabled={readOnly || saveState === 'saving' || saveState === 'conflict'} onClick={ed.save}>
            SAVE TO SURVEYSCRIBER
          </button>
          <button type="button" className="secondary" onClick={askExit}>
            Exit
          </button>
        </div>
      </header>

      {ed.message && ['failed', 'offline', 'lost', 'readonly'].includes(saveState) ? (
        <div className={`banner banner-${saveState}`} role="alert">
          {saveState === 'lost' ? 'Your access to this report has ended. Please contact the report owner.' : saveState === 'readonly' ? 'This report can no longer be edited. You can still read it.' : ed.message}
          {saveState === 'failed' || saveState === 'offline' ? <button type="button" className="link" onClick={ed.save}>Retry now</button> : null}
        </div>
      ) : null}

      <div className="body">
        <nav className="sections" aria-label="Report sections">
          <label className="section-select">
            <span>Section</span>
            <select value={section.id} onChange={(e) => goSection(e.target.value)}>
              {cur.map((s) => (
                <option key={s.id} value={s.id}>
                  {s.title}
                </option>
              ))}
            </select>
          </label>
          <ul>
            {cur.map((s) => (
              <li key={s.id}>
                <button type="button" className={s.id === section.id ? 'is-current' : ''} aria-current={s.id === section.id ? 'true' : undefined} onClick={() => goSection(s.id)}>
                  <span>{s.title}</span>
                  <span className="count">{s.blocks.length}</span>
                  {touched.has(s.id) ? <span className="dot" title="Unsaved changes in this section" /> : null}
                </button>
              </li>
            ))}
          </ul>
        </nav>

        <main className="pane" aria-label={view === 'photos' ? 'Photographs' : view === 'review' ? 'Review' : section.title}>
          <div className="tabs" role="tablist" aria-label="Report view">
            <button type="button" role="tab" aria-selected={view === 'report'} className={view === 'report' ? 'is-current' : ''} onClick={() => setView('report')}>
              Report text
            </button>
            <button type="button" role="tab" aria-selected={view === 'photos'} className={view === 'photos' ? 'is-current' : ''} onClick={() => (ed.flush(), setView('photos'))}>
              Photographs <span className="count">{photosState.loading ? '' : photosState.photos.length}</span>
            </button>
            <button type="button" role="tab" aria-selected={view === 'review'} className={view === 'review' ? 'is-current' : ''} onClick={() => (ed.flush(), setView('review'))}>
              Review <span className={`count status-dot dot-${server.status}`}>{STATUS_LABEL[server.status] || ''}</span>
            </button>
          </div>
          {view === 'review' ? (
            <Review reportId={server.reportId} editor={ed} readOnly={readOnly} onStatus={ed.syncStatus} />
          ) : view === 'photos' ? (
            <Photos reportId={server.reportId} photosState={photosState} sections={cur.map((s) => ({ key: s.key, title: s.title }))} readOnly={readOnly} />
          ) : (
            <>
          <h1>{section.title}</h1>
          {section.blocks.length === 0 ? <p className="muted">No content in this section yet.</p> : null}
          {section.blocks.map((b, i) => (
            <React.Fragment key={b.id}>
              <Block
                block={b}
                index={i}
                count={section.blocks.length}
                sections={cur}
                sectionId={section.id}
                readOnly={readOnly}
                active={activeId === b.id}
                onActivate={() => setActiveId(b.id)}
                onEdit={(fn, key) => ed.edit((c) => fn(c.find((s) => s.id === section.id).blocks.find((x) => x.id === b.id)), key)}
                onMove={(d) => ops.move(b.id, d)}
                onMoveTo={(to) => ops.moveTo(b.id, to)}
                onDelete={() => setDialog({ type: 'delete', id: b.id })}
                onBlur={() => ed.flush()}
              />
              {!readOnly && (
                <div className="insert">
                  <button
                    type="button"
                    onClick={(e) => {
                      e.currentTarget.blur();
                      ops.add(b.id);
                    }}
                    aria-label="Add paragraph below"
                  >
                    <Icon d={ICONS.plus} /> Add paragraph
                  </button>
                </div>
              )}
            </React.Fragment>
          ))}
          {!readOnly && section.blocks.length === 0 ? (
            <button type="button" className="secondary" onClick={() => ops.add(null)}>
              <Icon d={ICONS.plus} /> Add paragraph
            </button>
          ) : null}
            </>
          )}
        </main>

        <aside className="side" aria-label="Report information">
          <h2>Report</h2>
          <dl>
            <dt>Reference</dt>
            <dd>{server.property?.jobRef || 'None'}</dd>
            <dt>Property</dt>
            <dd>{server.property?.address || server.property?.title}</dd>
            <dt>Type</dt>
            <dd>{TYPE_NAMES[server.reportType] || server.reportType}</dd>
            <dt>Status</dt>
            <dd>{STATUS_LABEL[server.status] || server.status}</dd>
            <dt>Last saved</dt>
            <dd>{fmt(ed.lastSavedAt || server.updatedAt)}</dd>
            <dt>Link expires</dt>
            <dd>{fmt(server.linkExpiresAt)}</dd>
          </dl>
          <p className="muted small">Autosave runs a couple of seconds after you stop typing. Use SAVE TO SURVEYSCRIBER to save at once.</p>
        </aside>
      </div>

      {dialog && dialog.type === 'delete' && (
        <Dialog
          title="Delete this paragraph?"
          onClose={() => setDialog(null)}
          actions={
            <>
              <button type="button" className="secondary" onClick={() => setDialog(null)}>
                Cancel
              </button>
              <button
                type="button"
                className="danger-btn"
                autoFocus
                onClick={() => {
                  ops.remove(dialog.id);
                  setDialog(null);
                }}
              >
                Delete
              </button>
            </>
          }
        >
          <p>It is removed from the report when you save. You can bring it back with Undo (Ctrl+Z) until then.</p>
        </Dialog>
      )}

      {dialog === 'exit' && (
        <Dialog
          title="You have unsaved changes"
          onClose={() => setDialog(null)}
          actions={
            <>
              <button type="button" className="secondary" onClick={() => setDialog(null)}>
                Keep editing
              </button>
              <button type="button" className="secondary" onClick={doExit}>
                Exit without saving
              </button>
              <button
                type="button"
                className="primary"
                autoFocus
                onClick={async () => {
                  await ed.save();
                  setDialog(null);
                  doExit();
                }}
              >
                Save and exit
              </button>
            </>
          }
        >
          <p>Changes that are not saved yet will be lost if you exit now.</p>
        </Dialog>
      )}

      {dialog === 'reload' && (
        <Dialog
          title="Reload the latest version?"
          onClose={() => setDialog(null)}
          actions={
            <>
              <button type="button" className="secondary" onClick={() => setDialog(null)}>
                Cancel
              </button>
              <button
                type="button"
                className="danger-btn"
                autoFocus
                onClick={async () => {
                  setDialog(null);
                  await ed.reloadLatest();
                }}
              >
                Discard my changes and reload
              </button>
            </>
          }
        >
          <p>You have changes that are not saved. Reloading replaces them with the version on the server.</p>
        </Dialog>
      )}

      {ed.conflict && !(dialog && dialog.type === 'noreapply') && (
        <Dialog
          title="Someone saved a newer version"
          actions={
            <>
              <button
                type="button"
                className="secondary"
                onClick={async () => {
                  await ed.reloadLatest();
                }}
              >
                Discard my changes and reload
              </button>
              <button
                type="button"
                className="primary"
                autoFocus
                onClick={async () => {
                  const r = await ed.reapplyMine();
                  if (!r.ok) setDialog({ type: 'noreapply', reason: r.reason });
                }}
              >
                Reload and re-apply my changes
              </button>
            </>
          }
        >
          <p>
            The report on the server is now at version {ed.conflict.serverVersion}. Nothing was overwritten, and your {ed.conflict.mine.length} unsaved change{ed.conflict.mine.length === 1 ? '' : 's'} {ed.conflict.mine.length === 1 ? 'is' : 'are'} still here.
          </p>
          <p className="muted">Re-apply puts your changes on top of the newer version. If a paragraph you edited was removed meanwhile, it will tell you.</p>
        </Dialog>
      )}

      {dialog && dialog.type === 'noreapply' && (
        <Dialog
          title="Your changes could not be re-applied"
          onClose={() => setDialog(null)}
          actions={
            <button
              type="button"
              className="primary"
              autoFocus
              onClick={async () => {
                setDialog(null);
                await ed.reloadLatest();
              }}
            >
              Reload latest version
            </button>
          }
        >
          <p>The newer version changed the same part of the report: {friendly(dialog.reason)}. Reload the latest version and make the edit again.</p>
        </Dialog>
      )}
    </div>
  );
}
