import React, { useCallback, useEffect, useRef, useState } from 'react';
import { ApiError, reviewApi } from './api.js';

export const STATUS_LABEL = {
  DRAFT: 'Draft',
  SUBMITTED_FOR_REVIEW: 'Submitted for review',
  UNDER_REVIEW: 'Under review',
  AMENDMENTS_REQUIRED: 'Changes requested',
  REVIEWER_APPROVED: 'Approved by a reviewer',
  OWNER_FINAL_APPROVAL: 'Final approval given',
  FINALISING: 'Being finalised',
  FINALISED: 'Finalised',
};

const DECISION_LABEL = { SUBMITTED: 'Submitted for review', APPROVED: 'Approved', AMENDMENTS_REQUIRED: 'Changes requested', OWNER_APPROVED: 'Final approval' };
const fmt = (d) => new Date(d).toLocaleString(undefined, { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' });

function explain(v) {
  const n = (x) => `version ${x}`;
  switch (v.status) {
    case 'DRAFT':
      return 'This report is a draft. When you have finished editing, submit it for review.';
    case 'SUBMITTED_FOR_REVIEW':
      return `Submitted for review at ${n(v.submittedVersion ?? v.version)}. A reviewer can start the review or decide straight away.`;
    case 'UNDER_REVIEW':
      return 'A reviewer is looking at this report. They can approve it or ask for changes.';
    case 'AMENDMENTS_REQUIRED':
      return 'Changes were requested. Make them, then submit the report for review again.';
    case 'REVIEWER_APPROVED':
      return `A reviewer approved ${n(v.reviewerApproval?.version ?? v.version)}. The report owner gives the final approval.`;
    case 'OWNER_FINAL_APPROVAL':
      return `The report owner gave final approval to ${n(v.ownerApproval?.version ?? v.version)}. Only the owner can finalise the report.`;
    case 'FINALISING':
    case 'FINALISED':
      return 'This report has been finalised. It can no longer be changed.';
    default:
      return '';
  }
}

/** Screen F: status, submitted version, reviewer decision and comment, owner approval; the review actions for a link holder. */
export default function Review({ reportId, editor, readOnly, onStatus }) {
  const { server, flush, refreshServer, syncVersion } = editor;
  const [view, setView] = useState(null);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState('');
  const [comment, setComment] = useState('');
  const alive = useRef(true);
  useEffect(() => () => (alive.current = false), []);

  const load = useCallback(async () => {
    try {
      const v = await reviewApi.view(reportId);
      if (!alive.current) return;
      setView(v);
      onStatus(v.status);
    } catch (e) {
      if (alive.current) setError(e.message);
    }
  }, [reportId, onStatus]);

  // Read it again whenever the report moves (a save, a photo change) and when the page comes back into view.
  useEffect(() => {
    load();
  }, [load, server.version]);
  useEffect(() => {
    const f = () => document.visibilityState === 'visible' && load();
    document.addEventListener('visibilitychange', f);
    window.addEventListener('focus', f);
    return () => {
      document.removeEventListener('visibilitychange', f);
      window.removeEventListener('focus', f);
    };
  }, [load]);

  const act = async (name, call, body) => {
    setError('');
    setBusy(name);
    try {
      // The decision is about what is saved on the server: save pending edits first, then use the version that results.
      await flush();
      const fresh = await refreshServer();
      const v = await call(reportId, { expectedReportVersion: fresh.version, ...body });
      syncVersion(fresh.version);
      setView(v);
      onStatus(v.status);
      setComment('');
    } catch (e) {
      if (!(e instanceof ApiError)) throw e;
      setError(
        e.code === 'VERSION_CONFLICT'
          ? 'The report changed while you were deciding. Have another look, then try again.'
          : e.code === 'INVALID_STATE'
            ? `${e.message} The review status was refreshed.`
            : e.message,
      );
      await load();
    } finally {
      if (alive.current) setBusy('');
    }
  };

  if (!view) {
    return (
      <section className="review" aria-label="Review">
        <h1>Review</h1>
        {error ? <p role="alert" className="muted">{error}</p> : <p className="muted">Loading the review status…</p>}
      </section>
    );
  }

  const { status } = view;
  const canSubmit = status === 'DRAFT' || status === 'AMENDMENTS_REQUIRED';
  const canStart = status === 'SUBMITTED_FOR_REVIEW';
  const canDecide = status === 'SUBMITTED_FOR_REVIEW' || status === 'UNDER_REVIEW';
  const canWithdraw = status === 'REVIEWER_APPROVED';
  const trimmed = comment.trim();
  const needsComment = 'Please say what needs to change.';

  return (
    <section className="review" aria-label="Review">
      <h1>Review</h1>
      <div className={`status-card status-${status}`} role="status">
        <span className="status-pill" data-status={status}>
          {STATUS_LABEL[status] || status}
        </span>
        <p>{explain(view)}</p>
      </div>

      {view.lastAmendmentRequest && status === 'AMENDMENTS_REQUIRED' ? (
        <blockquote className="amend" aria-label="Requested changes">
          <strong>Requested changes</strong>
          <p>{view.lastAmendmentRequest.comment}</p>
          <small className="muted">
            {view.lastAmendmentRequest.by === 'owner' ? 'The report owner' : 'A reviewer'}, {fmt(view.lastAmendmentRequest.createdAt)}, on version {view.lastAmendmentRequest.version}
          </small>
        </blockquote>
      ) : null}

      <dl className="facts">
        <dt>Current version</dt>
        <dd>{view.version}</dd>
        <dt>Submitted version</dt>
        <dd>{status === 'DRAFT' || view.submittedVersion == null ? 'Not submitted yet' : view.submittedVersion}</dd>
        <dt>Reviewer decision</dt>
        <dd>
          {view.reviewerApproval ? (
            <>
              Approved, version {view.reviewerApproval.version} <span className="badge ok">current</span>
              {view.reviewerApproval.comment ? <div className="muted small">{view.reviewerApproval.comment}</div> : null}
            </>
          ) : (
            'No approval that still stands'
          )}
        </dd>
        <dt>Owner approval</dt>
        <dd>{view.ownerApproval ? <>Given, version {view.ownerApproval.version} <span className="badge ok">current</span></> : 'Not given'}</dd>
      </dl>

      {error ? (
        <div className="banner banner-failed inline-banner" role="alert">
          {error}
        </div>
      ) : null}

      {!readOnly && (canSubmit || canStart || canDecide || canWithdraw) ? (
        <div className="review-actions">
          <label className="field">
            <span>
              Comment {canDecide || canWithdraw ? '(needed when asking for changes)' : '(optional)'}
            </span>
            <textarea rows={3} maxLength={2000} value={comment} onChange={(e) => setComment(e.target.value)} placeholder="Add a comment" disabled={!!busy} />
          </label>
          <div className="row">
            {canSubmit ? (
              <button type="button" className="primary" disabled={!!busy} onClick={() => act('submit', reviewApi.submit, { comment: trimmed || undefined })}>
                {busy === 'submit' ? 'Submitting…' : 'Submit for review'}
              </button>
            ) : null}
            {canStart ? (
              <button type="button" className="secondary" disabled={!!busy} onClick={() => act('start', reviewApi.start, {})}>
                Start review
              </button>
            ) : null}
            {canDecide ? (
              <button type="button" className="primary" disabled={!!busy} onClick={() => act('approve', reviewApi.decide, { decision: 'APPROVED', comment: trimmed || undefined })}>
                Approve this version
              </button>
            ) : null}
            {canDecide || canWithdraw ? (
              <button
                type="button"
                className="secondary"
                disabled={!!busy}
                title={trimmed ? '' : needsComment}
                onClick={() => (trimmed ? act('amend', reviewApi.decide, { decision: 'AMENDMENTS_REQUIRED', comment: trimmed }) : setError(needsComment))}
              >
                {canWithdraw ? 'Withdraw approval and request changes' : 'Request changes'}
              </button>
            ) : null}
          </div>
          <p className="muted small">Your unsaved edits are saved first, so the decision is about exactly what is saved. Only the report owner gives the final approval.</p>
        </div>
      ) : null}

      <h2>History</h2>
      {view.reviews.length === 0 ? (
        <p className="muted">Nothing yet.</p>
      ) : (
        <ol className="history">
          {view.reviews.map((r) => (
            <li key={r.id} className={r.invalidated ? 'is-old' : ''}>
              <span className="what">{DECISION_LABEL[r.decision] || r.decision}</span>
              <span className="muted">
                {' '}
                · version {r.version} · {r.by === 'owner' ? 'owner' : 'reviewer'} · {fmt(r.createdAt)}
              </span>
              {r.invalidated ? <span className="badge warn">out of date</span> : null}
              {r.comment ? <div className="comment">{r.comment}</div> : null}
            </li>
          ))}
        </ol>
      )}
    </section>
  );
}
