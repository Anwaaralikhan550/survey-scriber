import { DAY_MS, RetentionKind } from './retention';

/** UTC date as 19 Nov 2026 (the same in the app, the e-mail and the tests). */
export function formatDate(d: Date): string {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return `${d.getUTCDate()} ${months[d.getUTCMonth()]} ${d.getUTCFullYear()}`;
}

export interface WarningText {
  title: string;
  body: string;
}

/** The warning of spec 15.1 / 15.2 in plain words: what, when, what to do. Day numbers are the policy's, not the clock's. */
export function warningText(p: { kind: RetentionKind; title: string; day: number; isFinal: boolean; anchorAt: Date; deleteAt: Date; now: Date }): WarningText {
  const left = Math.max(0, Math.ceil((p.deleteAt.getTime() - p.now.getTime()) / DAY_MS));
  const days = `${left} day${left === 1 ? '' : 's'}`;
  const prefix = p.isFinal ? 'Final warning: ' : '';
  if (p.kind === 'FINALISED') {
    return {
      title: `${prefix}Report "${p.title}" will be removed in ${days}`,
      body:
        `The report "${p.title}" was finalised on ${formatDate(p.anchorAt)}. SurveyScriber keeps finalised reports for 60 days, so it will be removed from the cloud on ${formatDate(p.deleteAt)} (${days} left).\n\n` +
        'Download the complete archive now (open the report, Edit on a computer, Download complete archive) and keep it in your own secure storage. ' +
        'Downloading the archive does not extend the 60 days. You are responsible for keeping your own long-term record.',
    };
  }
  return {
    title: `${prefix}Draft "${p.title}" will be removed in ${days}`,
    body:
      `You have not worked on the draft report "${p.title}" since ${formatDate(p.anchorAt)}. Drafts with no activity are removed after 30 days, on ${formatDate(p.deleteAt)} (${days} left).\n\n` +
      'To keep it, open the report and make a change: working on it starts the 30 days again. Or download the complete archive and keep it in your own secure storage. ' +
      'Merely opening the report does not restart the 30 days.',
  };
}

export function holdPlacedText(title: string, reason: string, byRole: string): WarningText {
  return {
    title: `Legal hold on report "${title}"`,
    body: `A ${byRole.toLowerCase()} placed a legal hold on the report "${title}". While the hold is active the report will not be deleted, whatever its age.\n\nReason given: ${reason}`,
  };
}

export function holdReleasedText(title: string, deleteOn: Date, reason: string): WarningText {
  return {
    title: `Legal hold released on report "${title}"`,
    body: `The legal hold on the report "${title}" was released (${reason}). The normal retention rules apply again; the report will not be deleted before ${formatDate(deleteOn)}.\n\nDownload the complete archive if you want your own copy.`,
  };
}

export function purgedText(title: string, kind: RetentionKind): WarningText {
  return {
    title: `Report "${title}" was removed`,
    body: `The report "${title}" was removed from SurveyScriber's cloud under the ${kind === 'FINALISED' ? '60-day' : '30-day inactivity'} retention policy. Only a record that it was removed is kept, no report content. Your own archive, if you downloaded one, can still be restored.`,
  };
}
