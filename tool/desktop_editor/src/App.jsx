import React, { useEffect, useRef, useState } from 'react';
import Workspace from './Workspace.jsx';
import { api, hasSession } from './api.js';
import { NameForm, rememberedName } from './Name.jsx';

const TYPE_NAMES = { L2: 'Home Survey Level 2', L3: 'Home Survey Level 3', VALUATION: 'Valuation' };

// Safe messages (spec Screen A): they say what to do and never reveal report content.
const SAFE = {
  LINK_INVALID: ['This link is not valid', 'Please contact the report owner for a new link.'],
  LINK_EXPIRED: ['This link has expired', 'Please contact the report owner for a new link.'],
  LINK_REVOKED: ['This link is no longer active', 'The report owner has cancelled it. Please contact them for a new link.'],
  REPORT_FINALISED: ['This report has been finalised', 'It can no longer be edited. Please contact the report owner.'],
  NETWORK: ['No connection', 'Check your internet connection and try again.'],
};

function Shell({ children }) {
  return (
    <div className="landing">
      <div className="card">
        <div className="brand">
          <img className="logo" src="/logo.png" width="32" height="32" alt="" />
          <span>SurveyScriber</span>
        </div>
        {children}
      </div>
    </div>
  );
}

function Problem({ code, onRetry }) {
  const [title, text] = SAFE[code] || ['Something went wrong', 'Please try again, or contact the report owner.'];
  return (
    <Shell>
      <h1>{title}</h1>
      <p>{text}</p>
      {code === 'NETWORK' && onRetry ? (
        <button type="button" className="primary" onClick={onRetry}>
          Try again
        </button>
      ) : null}
    </Shell>
  );
}

const fmt = (d) => new Date(d).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' });

export default function App() {
  const [view, setView] = useState({ name: 'checking' });
  const started = useRef(false);

  const start = async () => {
    const m = window.location.pathname.match(/^\/open\/([A-Za-z0-9_-]+)\/?$/);
    try {
      if (m) {
        // Screen A: validate the link, then take the secret out of the address bar and history at once (spec 5.3).
        const session = await api.open(m[1]);
        window.history.replaceState(null, '', '/editor');
        const report = await api.read(session.reportId);
        setView({ name: 'landing', report });
      } else if (hasSession()) {
        const reportId = window.location.pathname.match(/^\/editor\/([0-9a-f-]{36})$/)?.[1] || sessionStorage.getItem('ss_editor_report');
        if (!reportId) throw Object.assign(new Error(), { code: 'LINK_INVALID' });
        setView({ name: 'workspace', report: await api.read(reportId) });
      } else {
        setView({ name: 'problem', code: 'LINK_INVALID' });
      }
    } catch (e) {
      setView({ name: 'problem', code: e.code || 'ERROR' });
    }
  };

  useEffect(() => {
    if (started.current) return;
    started.current = true;
    start();
  }, []);

  if (view.name === 'checking') {
    return (
      <Shell>
        <h1>Checking your link…</h1>
        <p className="muted">One moment.</p>
      </Shell>
    );
  }
  if (view.name === 'problem') return <Problem code={view.code} onRetry={() => (setView({ name: 'checking' }), start())} />;
  if (view.name === 'exited') {
    return (
      <Shell>
        <h1>You have left the editor</h1>
        <p>Your saved changes are safe. To continue, open the link you were sent again.</p>
      </Shell>
    );
  }
  if (view.name === 'landing') {
    const r = view.report;
    try {
      sessionStorage.setItem('ss_editor_report', r.reportId);
    } catch {
      /* private mode: reload will ask for the link again */
    }
    return (
      <Shell>
        <h1>Report editing</h1>
        <p className="muted">You have been invited to edit a SurveyScriber report. Changes are saved to the report owner's copy.</p>
        <dl className="summary">
          <dt>Reference</dt>
          <dd>{r.property?.jobRef || 'None'}</dd>
          <dt>Property</dt>
          <dd>{r.property?.address || r.property?.title}</dd>
          <dt>Report type</dt>
          <dd>{TYPE_NAMES[r.reportType] || r.reportType}</dd>
          <dt>Access</dt>
          <dd>{r.readOnly ? 'Read-only' : 'You can edit'}. The link works until {fmt(r.linkExpiresAt)}.</dd>
        </dl>
        {r.readOnly || r.reviewer?.name ? (
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
      </Shell>
    );
  }
  return <Workspace initial={view.report} onExit={(why) => setView({ name: why })} />;
}
