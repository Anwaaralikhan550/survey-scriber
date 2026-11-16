/**
 * Guardrails for AI wording suggestions (client spec v1.3 section 13).
 * Pure functions, no I/O: what may be sent to the model, and what a suggestion is checked for before the user sees it.
 * The model only ever rewrites wording. It never decides ratings, findings or facts, and nothing it returns is applied
 * without the user pressing Accept in the browser.
 */

export type SuggestionAction = 'IMPROVE' | 'SHORTEN' | 'FORMAL' | 'PLAIN' | 'GRAMMAR';
export const SUGGESTION_ACTIONS: SuggestionAction[] = ['IMPROVE', 'SHORTEN', 'FORMAL', 'PLAIN', 'GRAMMAR'];

export const ACTION_LABEL: Record<SuggestionAction, string> = {
  IMPROVE: 'Improve wording',
  SHORTEN: 'Make shorter',
  FORMAL: 'More professional',
  PLAIN: 'Plain English',
  GRAMMAR: 'Fix spelling and grammar',
};

const ACTION_BRIEF: Record<SuggestionAction, string> = {
  IMPROVE: 'Improve the clarity and flow of the wording.',
  SHORTEN: 'Make the text shorter by removing repetition and padding.',
  FORMAL: 'Make the tone more professional, as in a chartered surveyor report.',
  PLAIN: 'Rewrite in plain English that a home buyer without technical knowledge can follow.',
  GRAMMAR: 'Correct spelling, punctuation and grammar only. Change as little as possible.',
};

export const SYSTEM_PROMPT = [
  'You are an editor for a UK building surveyor\'s property report. You only rewrite wording.',
  'Strict rules:',
  '1. Keep every fact exactly as written: measurements, dates, quantities, locations, materials, names, defects and their severity.',
  '2. Do not add any fact, cause, risk, recommendation, cost or opinion that is not in the text. Do not remove any fact.',
  '3. Never change or invent a condition rating. Never state that something is safe, fine, urgent or dangerous unless the text already says so.',
  '4. Keep placeholders such as [EMAIL_1] or [PHONE_1] unchanged.',
  '5. Use British English.',
  '6. Reply with the rewritten text only: no title, no quotation marks, no explanation.',
].join('\n');

export function userPrompt(action: SuggestionAction, sectionTitle: string, text: string): string {
  return `${ACTION_BRIEF[action]}\n\nSection: ${sectionTitle}\n\nText to rewrite:\n${text}`;
}

// ---- Personal data: nothing identifying is sent to the model (spec 13: minimise personal data) ----

const PATTERNS: Array<{ tag: string; re: RegExp }> = [
  { tag: 'EMAIL', re: /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g },
  { tag: 'PHONE', re: /(?:\+44\s?\d{3,4}|\(?0\d{3,4}\)?)[\s-]?\d{3}[\s-]?\d{3,4}\b/g },
  { tag: 'POSTCODE', re: /\b[A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2}\b/g },
];

export interface Redaction {
  text: string;
  map: Map<string, string>;
}

/** Replace emails, phone numbers and postcodes by placeholders. The map restores them in the answer. */
export function redact(text: string): Redaction {
  const map = new Map<string, string>();
  let out = text;
  for (const { tag, re } of PATTERNS) {
    let n = 0;
    out = out.replace(re, (m) => {
      for (const [k, v] of map) if (v === m) return k;
      n += 1;
      const key = `[${tag}_${n}]`;
      map.set(key, m);
      return key;
    });
  }
  return { text: out, map };
}

export function restore(text: string, map: Map<string, string>): string {
  let out = text;
  for (const [k, v] of map) out = out.split(k).join(v);
  return out;
}

// ---- Which blocks may be suggested for ----

export interface BlockLike {
  type: string;
  role?: string;
  text?: string;
  recommendation?: string;
}

/** The wording of a block: a recommendation keeps it in `recommendation`, every other text block in `text`. */
export function wordingOf(block: BlockLike): string {
  return (block.type === 'recommendation' ? block.recommendation : block.text) ?? '';
}

/** Wording blocks only. Ratings, tables, photos, and the phone-built rating sentence are never sent. */
export function ineligibleReason(block: BlockLike): string | null {
  if (block.type !== 'paragraph' && block.type !== 'recommendation') return 'AI suggestions are only available for text. Ratings, tables and photographs are never changed by AI.';
  if (block.role === 'rating') return 'Condition ratings are your professional judgement and are never changed by AI.';
  const text = wordingOf(block).trim();
  if (!text) return 'There is no text to improve yet.';
  if (/^condition rating is\b/i.test(text)) return 'Condition ratings are your professional judgement and are never changed by AI.';
  return null;
}

// ---- Checks on what the model returned ----

const NUMBER = /\d+(?:[.,]\d+)*/g;

/** Words that carry a finding or a severity. If the suggestion brings one in that the text did not have, warn. */
const SEVERITY_WORDS = [
  'asbestos', 'subsidence', 'structural', 'structurally', 'movement', 'dangerous', 'unsafe', 'safe', 'urgent', 'urgently', 'immediate', 'immediately',
  'serious', 'severe', 'significant', 'critical', 'defective', 'failure', 'failed', 'collapse', 'dampness', 'damp', 'rot', 'infestation', 'leak', 'leaking',
  'cracking', 'cracks', 'no evidence', 'no signs', 'satisfactory', 'excellent', 'good condition', 'poor condition',
];

function numbersOf(s: string): string[] {
  return (s.match(NUMBER) ?? []).map((n) => n.replace(/,/g, ''));
}

function containsWord(haystack: string, word: string): boolean {
  return new RegExp(`(?:^|[^a-z])${word.replace(/ /g, '\\s+')}(?:[^a-z]|$)`, 'i').test(haystack);
}

export interface SuggestionCheck {
  warnings: string[];
  /** true when the suggestion must not be shown at all */
  reject?: string;
}

export function checkSuggestion(original: string, suggestion: string, maxLength: number): SuggestionCheck {
  const warnings: string[] = [];
  const s = suggestion.trim();
  if (!s) return { warnings, reject: 'The assistant returned no text.' };
  if (s.length > maxLength) return { warnings, reject: 'The assistant returned more text than a paragraph can hold.' };
  if (/^condition rating is\b/i.test(s)) return { warnings, reject: 'The assistant tried to write a condition rating. That is never allowed.' };
  if (s === original.trim()) warnings.push('The suggestion is the same as your text.');

  const before = numbersOf(original);
  const after = numbersOf(s);
  const count = (list: string[]) => list.reduce((m, n) => m.set(n, (m.get(n) ?? 0) + 1), new Map<string, number>());
  const b = count(before);
  const a = count(after);
  for (const [n, c] of a) if (c > (b.get(n) ?? 0)) warnings.push(`New figure: ${n} is not in your text. Check it against your notes.`);
  for (const [n, c] of b) if (c > (a.get(n) ?? 0)) warnings.push(`A figure from your text is missing: ${n}.`);

  for (const w of SEVERITY_WORDS) {
    if (containsWord(s, w) && !containsWord(original, w)) warnings.push(`New wording about condition: "${w}" is not in your text. Check it is true.`);
  }
  if (s.length > original.length * 2 + 80) warnings.push('The suggestion is much longer than your text and may add detail you did not write.');
  return { warnings };
}
