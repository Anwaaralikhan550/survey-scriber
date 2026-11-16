import React, { useEffect, useRef, useState } from 'react';
import { ApiError, aiApi } from './api.js';
import { wordDiff } from './wordDiff.js';

export const ACTIONS = [
  { id: 'IMPROVE', label: 'Improve wording', hint: 'Clearer and smoother. Same facts.' },
  { id: 'SHORTEN', label: 'Make shorter', hint: 'Remove repetition and padding.' },
  { id: 'FORMAL', label: 'More professional', hint: 'A formal surveyor tone.' },
  { id: 'PLAIN', label: 'Plain English', hint: 'Easy for a home buyer to follow.' },
  { id: 'GRAMMAR', label: 'Fix spelling and grammar', hint: 'Changes as little as possible.' },
];

function Marked({ parts, kind }) {
  return (
    <p className="diff-text">
      {parts.map((p, i) => (p.changed ? (kind === 'del' ? <del key={i}>{p.text}</del> : <ins key={i}>{p.text}</ins>) : <React.Fragment key={i}>{p.text}</React.Fragment>))}
    </p>
  );
}

const FRIENDLY = {
  VERSION_CONFLICT: 'The report changed while you were working. Close this and look at the latest text, then ask again.',
  REPORT_FINALISED: 'This report has been finalised and can no longer be changed.',
  LINK_EXPIRED: 'This link has expired, so suggestions are not available.',
  NETWORK: 'No connection to SurveyScriber. Your text is unchanged.',
};

/**
 * Screen E: AI wording suggestion for one paragraph. Nothing is changed until the user presses Accept (or uses their own
 * edit of the suggestion). The server never edits the report; Accept goes through the normal, version-checked save.
 */
export default function Suggest({ reportId, editor, blockId, blockLabel, getText, onApply, onClose }) {
  const [step, setStep] = useState('choose'); // choose | loading | result | editing | error
  const [error, setError] = useState('');
  const [result, setResult] = useState(null);
  const [mine, setMine] = useState('');
  const [stale, setStale] = useState(false);
  const closed = useRef(false);
  const alive = useRef(true);
  useEffect(() => () => (alive.current = false), []);
  const resultRef = useRef(null);
  resultRef.current = result;
  useEffect(() => {
    const k = (e) => e.key === 'Escape' && reject();
    window.addEventListener('keydown', k);
    return () => window.removeEventListener('keydown', k);
  });

  const log = (outcome, extra = {}) => {
    if (!result || closed.current) return Promise.resolve();
    closed.current = true;
    return aiApi.outcome(reportId, { suggestionId: result.suggestionId, blockId: result.blockId, action: result.action, outcome, ...extra }).catch(() => {});
  };

  const ask = async (action) => {
    setStep('loading');
    setError('');
    setStale(false);
    try {
      // The suggestion is about the saved text: save pending edits first, then ask for exactly that version.
      await editor.flush();
      const fresh = await editor.refreshServer();
      const r = await aiApi.suggest(reportId, { blockId, action, expectedReportVersion: fresh.version });
      if (!alive.current) return;
      closed.current = false;
      setResult(r);
      setMine(r.suggestion);
      setStep('result');
    } catch (e) {
      if (!alive.current) return;
      if (!(e instanceof ApiError)) throw e;
      setError(FRIENDLY[e.code] || e.message);
      setStep('error');
    }
  };

  const currentIsOriginal = () => getText() === result.original;
  const apply = async (text, outcome) => {
    if (!currentIsOriginal()) {
      setStale(true);
      return;
    }
    onApply(text);
    await log(outcome, { finalLength: text.length });
    onClose();
  };
  const reject = async () => {
    await log('REJECTED');
    onClose();
  };

  const diff = result ? wordDiff(result.original, result.suggestion) : null;
  const warnings = result?.warnings ?? [];

  return (
    <div className="scrim" role="presentation">
      <div className="dialog dialog-wide" role="dialog" aria-modal="true" aria-label="AI wording suggestion">
        <h2>Suggest wording</h2>
        <div className="dialog-body">
          <p className="ai-notice" role="note">
            AI only rewords. It can make mistakes. Check every fact, figure and finding before you accept. Ratings are never changed by AI.
          </p>

          {step === 'choose' && (
            <>
              <p className="muted">What should it do with this {blockLabel.toLowerCase()}?</p>
              <ul className="ai-actions">
                {ACTIONS.map((a) => (
                  <li key={a.id}>
                    <button type="button" className="secondary ai-action" data-action={a.id} onClick={() => ask(a.id)}>
                      <strong>{a.label}</strong>
                      <span className="muted">{a.hint}</span>
                    </button>
                  </li>
                ))}
              </ul>
            </>
          )}

          {step === 'loading' && (
            <p role="status" className="muted">
              Asking the assistant… your text is not changed.
            </p>
          )}

          {step === 'error' && (
            <div className="banner banner-failed inline-banner" role="alert">
              {error}
            </div>
          )}

          {(step === 'result' || step === 'editing') && result && (
            <>
              {warnings.length > 0 && (
                <div className="ai-warnings" role="alert">
                  <strong>Check these against your notes before you accept</strong>
                  <ul>
                    {warnings.map((w, i) => (
                      <li key={i}>{w}</li>
                    ))}
                  </ul>
                </div>
              )}
              {stale && (
                <div className="banner banner-failed inline-banner" role="alert">
                  This paragraph changed while you were looking. Nothing was applied. Close this and ask again.
                </div>
              )}
              <div className="ai-compare">
                <section aria-label="Your text">
                  <h3>Your text</h3>
                  <Marked parts={diff.before} kind="del" />
                </section>
                <section aria-label={step === 'editing' ? 'Your edited version' : 'Suggestion'}>
                  <h3>{step === 'editing' ? 'Your edited version' : 'Suggestion'}</h3>
                  {step === 'editing' ? (
                    <textarea className="ai-edit" rows={8} maxLength={20000} value={mine} onChange={(e) => setMine(e.target.value)} aria-label="Edit the suggestion" autoFocus />
                  ) : (
                    <Marked parts={diff.after} kind="ins" />
                  )}
                </section>
              </div>
            </>
          )}
        </div>
        <div className="dialog-actions">
          {step === 'choose' && (
            <button type="button" className="secondary" onClick={onClose}>
              Cancel
            </button>
          )}
          {step === 'error' && (
            <>
              <button type="button" className="secondary" onClick={onClose}>
                Close
              </button>
              <button type="button" className="primary" onClick={() => setStep('choose')}>
                Try again
              </button>
            </>
          )}
          {step === 'result' && (
            <>
              <button type="button" className="secondary" onClick={reject}>
                Reject
              </button>
              <button type="button" className="secondary" onClick={() => setStep('editing')}>
                Copy and modify
              </button>
              <button type="button" className="secondary" onClick={async () => (await log('REJECTED'), setResult(null), setStep('choose'))}>
                Another style
              </button>
              <button type="button" className="primary" autoFocus onClick={() => apply(result.suggestion, 'ACCEPTED')}>
                Accept
              </button>
            </>
          )}
          {step === 'editing' && (
            <>
              <button type="button" className="secondary" onClick={() => setStep('result')}>
                Back
              </button>
              <button type="button" className="primary" disabled={!mine.trim()} onClick={() => apply(mine.trim(), mine.trim() === result.suggestion ? 'ACCEPTED' : 'ACCEPTED_MODIFIED')}>
                Use my edited version
              </button>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
