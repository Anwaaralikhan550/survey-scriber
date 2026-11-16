p = r'E:/survey-scriber/tool/desktop_editor/src/Workspace.jsx'
t = open(p, encoding='utf-8').read()


def rep(a, b):
    global t
    assert a in t, a[:70]
    t = t.replace(a, b, 1)


rep("import Photos from './Photos.jsx';", "import Photos from './Photos.jsx';\nimport Review, { STATUS_LABEL } from './Review.jsx';")
rep("  const [view, setView] = useState('report'); // 'report' | 'photos'", "  const [view, setView] = useState('report'); // 'report' | 'photos' | 'review'")
# header chip for the review status, and the quick action
rep("""          <span className="chip" title={`Link expires ${fmt(server.linkExpiresAt)}`}>Link: {linkLeft}</span>
        </div>""", """          <button type="button" className={`chip chip-btn review-chip review-${server.status}`} title="Open the review screen" onClick={() => (ed.flush(), setView('review'))}>
            {STATUS_LABEL[server.status] || server.status}
          </button>
          <span className="chip" title={`Link expires ${fmt(server.linkExpiresAt)}`}>Link: {linkLeft}</span>
        </div>""")
rep("""          <button type="button" className="primary" disabled={readOnly || saveState === 'saving' || saveState === 'conflict'} onClick={ed.save}>""", """          {!readOnly && (server.status === 'DRAFT' || server.status === 'AMENDMENTS_REQUIRED') ? (
            <button type="button" className="secondary" onClick={() => (ed.flush(), setView('review'))}>
              Submit for review
            </button>
          ) : null}
          <button type="button" className="primary" disabled={readOnly || saveState === 'saving' || saveState === 'conflict'} onClick={ed.save}>""")
rep("aria-label={view === 'photos' ? 'Photographs' : section.title}>", "aria-label={view === 'photos' ? 'Photographs' : view === 'review' ? 'Review' : section.title}>")
rep("""              Photographs <span className="count">{photosState.loading ? '' : photosState.photos.length}</span>
            </button>
          </div>
          {view === 'photos' ? (""", """              Photographs <span className="count">{photosState.loading ? '' : photosState.photos.length}</span>
            </button>
            <button type="button" role="tab" aria-selected={view === 'review'} className={view === 'review' ? 'is-current' : ''} onClick={() => (ed.flush(), setView('review'))}>
              Review <span className={`count status-dot dot-${server.status}`}>{STATUS_LABEL[server.status] || ''}</span>
            </button>
          </div>
          {view === 'review' ? (
            <Review reportId={server.reportId} editor={ed} readOnly={readOnly} onStatus={ed.syncStatus} />
          ) : view === 'photos' ? (""")
rep("            <dd>{String(server.status).replaceAll('_', ' ').toLowerCase()}</dd>", "            <dd>{STATUS_LABEL[server.status] || server.status}</dd>")
rep("      setView('report');\n      setActiveId(null);", "      setView('report');\n      setActiveId(null);")
open(p, 'w', encoding='utf-8').write(t)

p = r'E:/survey-scriber/tool/desktop_editor/src/styles.css'
c = open(p, encoding='utf-8').read()
c += '''
/* Review (Screen F) */
.chip-btn { cursor: pointer; font: inherit; font-size: 13px; }
.chip-btn:hover { background: var(--brand-soft); }
.review-DRAFT { color: var(--muted); }
.review-SUBMITTED_FOR_REVIEW, .review-UNDER_REVIEW { color: var(--warn); border-color: #ebcf9f; background: #fff6e5; }
.review-AMENDMENTS_REQUIRED { color: var(--bad); border-color: #efb8b4; background: #fdeceb; }
.review-REVIEWER_APPROVED, .review-OWNER_FINAL_APPROVAL, .review-FINALISED, .review-FINALISING { color: var(--ok); border-color: #b9dcc7; background: #eef8f1; }
.tabs .count.status-dot { font-weight: 600; }
.review h2 { margin: 22px 0 8px; color: var(--brand); }
.status-card { border: 1px solid var(--line); border-radius: 10px; padding: 14px 16px; margin: 6px 0 14px; background: var(--canvas); }
.status-card p { margin: 6px 0 0; }
.status-pill { display: inline-block; font-weight: 700; padding: 3px 12px; border-radius: 999px; background: var(--paper); border: 1px solid var(--line); }
.status-pill[data-status='SUBMITTED_FOR_REVIEW'], .status-pill[data-status='UNDER_REVIEW'] { color: var(--warn); border-color: #ebcf9f; background: #fff6e5; }
.status-pill[data-status='AMENDMENTS_REQUIRED'] { color: var(--bad); border-color: #efb8b4; background: #fdeceb; }
.status-pill[data-status='REVIEWER_APPROVED'], .status-pill[data-status='OWNER_FINAL_APPROVAL'], .status-pill[data-status='FINALISED'], .status-pill[data-status='FINALISING'] { color: var(--ok); border-color: #b9dcc7; background: #eef8f1; }
.amend { margin: 0 0 14px; padding: 10px 14px; border-left: 4px solid var(--bad); background: #fdf3f2; border-radius: 0 8px 8px 0; }
.amend p { margin: 4px 0; white-space: pre-wrap; }
.facts { display: grid; grid-template-columns: 170px 1fr; gap: 8px 14px; margin: 0 0 14px; }
.facts dt { color: var(--muted); }
.facts dd { margin: 0; font-weight: 600; }
.badge.ok { background: #eef8f1; color: var(--ok); margin-left: 6px; }
.badge.warn { background: #fff6e5; color: var(--warn); margin-left: 8px; }
.review-actions { border: 1px solid var(--line); border-radius: 10px; padding: 12px 14px; margin: 14px 0; display: grid; gap: 10px; }
.review-actions .row { display: flex; flex-wrap: wrap; gap: 8px; }
.history { list-style: none; padding: 0; margin: 0; display: grid; gap: 8px; }
.history li { border: 1px solid var(--line); border-radius: 8px; padding: 8px 12px; }
.history li.is-old { opacity: 0.7; }
.history .what { font-weight: 600; }
.history .comment { margin-top: 4px; white-space: pre-wrap; }
'''
open(p, 'w', encoding='utf-8').write(c)
print('ok')
