import { sanitizeText } from './report-content';

export const REVIEWER_NAME_MIN = 2;
export const REVIEWER_NAME_MAX = 80;

/**
 * The display name a person gives when they open an edit link (Remote Editor spec v1.4 sections 7 and 18). The link is a bearer
 * link, so the name is only what the person typed: it is kept next to the session and written into the history, and is always
 * shown as not verified. Plain text only: tags and control characters are removed, spaces are tidied.
 * Returns the clean name, or null when it is not acceptable.
 */
export function cleanReviewerName(raw: unknown): string | null {
  if (typeof raw !== 'string') return null;
  const name = sanitizeText(raw).replace(/\s+/g, ' ').trim();
  if (name.length < REVIEWER_NAME_MIN || name.length > REVIEWER_NAME_MAX) return null;
  // Letters of any language, digits, spaces and the punctuation names really contain.
  if (!/^[\p{L}\p{M}\p{N} .,'’()\-]+$/u.test(name)) return null;
  // At least two letters, so "..", "--" or "12" are not a name.
  if ((name.match(/\p{L}/gu) ?? []).length < 2) return null;
  return name;
}
