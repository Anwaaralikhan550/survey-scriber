// Word-level difference between the surveyor's text and an AI suggestion, for the side-by-side view (spec section 13).
// Plain longest-common-subsequence on words; texts are paragraphs, so the table stays small.

const tokens = (s) => s.split(/(\s+)/).filter((t) => t !== '');
const isSpace = (t) => /^\s+$/.test(t);

/**
 * Returns { before, after }: two lists of { text, changed }. `before` marks words that were removed or replaced,
 * `after` marks words that are new. Joined, they reproduce the two texts exactly.
 */
export function wordDiff(a, b) {
  const x = tokens(a);
  const y = tokens(b);
  const n = x.length;
  const m = y.length;
  // lcs[i][j] = length of the common run of x[i..] and y[j..]
  const lcs = Array.from({ length: n + 1 }, () => new Uint16Array(m + 1));
  for (let i = n - 1; i >= 0; i--) {
    for (let j = m - 1; j >= 0; j--) {
      lcs[i][j] = x[i] === y[j] ? lcs[i + 1][j + 1] + 1 : Math.max(lcs[i + 1][j], lcs[i][j + 1]);
    }
  }
  const before = [];
  const after = [];
  let i = 0;
  let j = 0;
  while (i < n && j < m) {
    if (x[i] === y[j]) {
      before.push({ text: x[i], changed: false });
      after.push({ text: y[j], changed: false });
      i++;
      j++;
    } else if (lcs[i + 1][j] >= lcs[i][j + 1]) {
      before.push({ text: x[i], changed: !isSpace(x[i]) });
      i++;
    } else {
      after.push({ text: y[j], changed: !isSpace(y[j]) });
      j++;
    }
  }
  while (i < n) before.push({ text: x[i], changed: !isSpace(x[i++]) });
  while (j < m) after.push({ text: y[j], changed: !isSpace(y[j++]) });
  return { before, after };
}
