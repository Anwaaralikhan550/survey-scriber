import re
def rw(p, fn):
    t = open(p, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in t else '\n'
    t = fn(t.replace('\r\n', '\n'))
    open(p, 'w', encoding='utf-8', newline='').write(t.replace('\n', nl))
def sub(t, a, b):
    assert t.count(a) == 1, (t.count(a), a[:70])
    return t.replace(a, b, 1)

rw('api.js', lambda t: sub(t, "  read: (reportId) => call('GET', `/editor/reports/${reportId}`),", "  read: (reportId) => call('GET', `/editor/reports/${reportId}`),\n  /** The name of the person using this link (typed, not verified). */\n  setName: (name) => call('PUT', '/editor/session/name', { name }),"))

def app(t):
    t = sub(t, "import { api, hasSession } from './api.js';", "import { api, hasSession } from './api.js';\nimport { NameForm, rememberedName } from './Name.jsx';")
    old = t[t.index("        <button type=\"button\" className=\"primary big\" autoFocus onClick={() => setView({ name: 'workspace', report: r })}>"):t.index("      </Shell>\n    );\n  }\n  return <Workspace")]
    new = """        {r.readOnly || r.reviewer?.name ? (
          <button type="button" className="primary big" autoFocus onClick={() => setView({ name: 'workspace', report: r })}>
            Continue to the editor
          </button>
        ) : (
          <NameForm
            initial={rememberedName()}
            submitLabel="Continue to the editor"
            onDone={(name) => setView({ name: 'workspace', report: { ...r, reviewer: { name, verified: false } } })}
          />
        )}
"""
    t = t.replace(old, new)
    return t
rw('App.jsx', app)

def ws(t):
    t = sub(t, "import { Dialog, Icon, ICONS } from './ui.jsx';", "import { Dialog, Icon, ICONS } from './ui.jsx';\nimport { NameForm, rememberedName } from './Name.jsx';")
    t = sub(t, "  const [dialog, setDialog] = useState(null);\n", "  const [dialog, setDialog] = useState(null);\n  const [reviewerName, setReviewerName] = useState(initial.reviewer?.name || null);\n")
    t = sub(t, "          <span className=\"chip\" title={`Link expires ${fmt(server.linkExpiresAt)}`}>Link: {linkLeft}</span>",
"          <span className=\"chip\" title={`Link expires ${fmt(server.linkExpiresAt)}`}>Link: {linkLeft}</span>\n          {!server.readOnly ? (\n            <button type=\"button\" className=\"chip chip-btn name-chip\" title=\"The name you gave. It is recorded with your changes and is not verified. Click to change it.\" onClick={() => setDialog('name')}>\n              You: {reviewerName || 'add your name'}\n            </button>\n          ) : null}")
    # required name dialog when the session has none; change dialog from the chip
    marker = "      {dialog === 'exit' && ("
    if marker not in t:
        raise SystemExit('exit dialog marker not found')
    add = """      {!readOnly && (!reviewerName || dialog === 'name') ? (
        <Dialog title={reviewerName ? 'Change your name' : 'Please enter your name'} onClose={reviewerName ? () => setDialog(null) : undefined} actions={null}>
          <p className="muted">The report owner sees this name next to your changes and review decisions. It is not verified.</p>
          <NameForm
            initial={reviewerName || rememberedName()}
            submitLabel="Save name"
            onDone={(n) => {
              setReviewerName(n);
              setDialog(null);
            }}
            secondary={reviewerName ? <button type="button" className="secondary" onClick={() => setDialog(null)}>Cancel</button> : null}
          />
        </Dialog>
      ) : null}
"""
    t = t.replace(marker, add + marker, 1)
    return t
rw('Workspace.jsx', ws)

def rev(t):
    t = sub(t, "                · version {r.version} · {r.by === 'owner' ? 'owner' : 'reviewer'} · {fmt(r.createdAt)}", "                · version {r.version} · {r.by === 'owner' ? 'owner' : r.reviewerName ? `${r.reviewerName} (name not verified)` : 'reviewer'} · {fmt(r.createdAt)}")
    t = sub(t, "              Approved, version {view.reviewerApproval.version} <span className=\"badge ok\">current</span>", "              Approved{view.reviewerApproval.reviewerName ? ` by ${view.reviewerApproval.reviewerName} (name not verified)` : ''}, version {view.reviewerApproval.version} <span className=\"badge ok\">current</span>")
    return t
rw('Review.jsx', rev)

def css(t):
    return t.rstrip('\n') + """

.name-form { display: grid; gap: 6px; margin-top: 14px; }
.name-form label { font-weight: 600; }
.name-form input { border: 1px solid var(--line); border-radius: 8px; padding: 10px 12px; font-size: 16px; }
.name-form input[aria-invalid='true'] { border-color: #b3261e; }
.name-form .help { margin: 0; font-size: 13px; color: var(--muted, #5c6b75); }
.name-form .help.bad { color: #b3261e; }
.name-actions { display: flex; gap: 10px; justify-content: flex-end; margin-top: 8px; }
.name-chip { max-width: 240px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
"""
rw('styles.css', css)
print('ok')
