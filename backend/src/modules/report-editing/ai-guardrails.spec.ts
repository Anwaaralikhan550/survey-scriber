import { checkSuggestion, ineligibleReason, redact, restore, SYSTEM_PROMPT, userPrompt } from './ai-guardrails';

describe('AI guardrails', () => {
  describe('personal data is not sent to the model', () => {
    it('replaces emails, phone numbers and postcodes by placeholders and restores them', () => {
      const text = 'Call Mr Khan on 07700 900123 or khan@example.com about 54 Gas Lane, DA1 2AB. Again khan@example.com.';
      const { text: safe, map } = redact(text);
      expect(safe).not.toMatch(/khan@example\.com|07700|DA1 2AB/);
      expect(safe).toContain('[EMAIL_1]');
      expect(safe).toContain('[PHONE_1]');
      expect(safe).toContain('[POSTCODE_1]');
      expect(safe.match(/\[EMAIL_1\]/g)).toHaveLength(2); // the same email gets the same placeholder
      expect(restore(safe, map)).toBe(text);
    });

    it('leaves ordinary survey text alone, including measurements and years', () => {
      const text = 'The roof, built in 1965, has 12 tiles of 300 mm missing.';
      expect(redact(text).text).toBe(text);
    });

    it('the instructions forbid inventing facts and ratings', () => {
      expect(SYSTEM_PROMPT).toMatch(/Do not add any fact/);
      expect(SYSTEM_PROMPT).toMatch(/Never change or invent a condition rating/);
      expect(userPrompt('SHORTEN', 'Roof', 'x')).toContain('Section: Roof');
    });
  });

  describe('which blocks may be suggested for', () => {
    it('allows paragraphs and recommendations with text', () => {
      expect(ineligibleReason({ type: 'paragraph', text: 'The roof is slate.' })).toBeNull();
      expect(ineligibleReason({ type: 'recommendation', recommendation: 'Repair the gutter.' })).toBeNull();
    });
    it('never ratings, tables, photos, empty text or the phone-built rating sentence', () => {
      expect(ineligibleReason({ type: 'rating' })).toMatch(/never changed by AI/);
      expect(ineligibleReason({ type: 'table' })).toMatch(/never changed by AI/);
      expect(ineligibleReason({ type: 'photo' })).toMatch(/never changed by AI/);
      expect(ineligibleReason({ type: 'paragraph', text: '   ' })).toMatch(/no text/);
      expect(ineligibleReason({ type: 'paragraph', role: 'rating', text: 'Condition rating is: 2' })).toMatch(/professional judgement/);
      expect(ineligibleReason({ type: 'paragraph', text: 'Condition rating is: 3' })).toMatch(/professional judgement/);
    });
  });

  describe('what comes back is checked', () => {
    const original = 'The roof has 12 slipped tiles and the ridge is in poor condition.';

    it('keeping every figure gives no warning; spelling a figure out is flagged for a check', () => {
      expect(checkSuggestion(original, 'Twelve of the roof tiles have slipped; the ridge is in poor condition.', 20000).warnings).toEqual(expect.arrayContaining([expect.stringContaining('missing: 12')]));
      expect(checkSuggestion(original, 'The roof has 12 slipped tiles, and the ridge is in poor condition.', 20000).warnings).toEqual([]);
    });
    it('warns about a figure that was added or dropped', () => {
      const w = checkSuggestion(original, 'The roof has 15 slipped tiles and the ridge is in poor condition.', 20000).warnings.join('|');
      expect(w).toContain('New figure: 15');
      expect(w).toContain('missing: 12');
    });
    it('warns when severity or finding wording appears that the surveyor did not write', () => {
      const w = checkSuggestion('The wall is cracked near the window.', 'The wall shows serious structural cracking near the window.', 20000).warnings.join('|');
      expect(w).toContain('"serious"');
      expect(w).toContain('"structural"');
    });
    it('does not warn about severity words the surveyor already used', () => {
      expect(checkSuggestion('Damp is present at the chimney breast.', 'Damp is present at the chimney breast, as noted.', 20000).warnings).toEqual([]);
    });
    it('says so when nothing changed, and when the answer is much longer', () => {
      expect(checkSuggestion('Same text.', 'Same text.', 20000).warnings).toContain('The suggestion is the same as your text.');
      const long = 'The roof is slate. '.repeat(30);
      expect(checkSuggestion('The roof is slate.', long, 20000).warnings.join('|')).toContain('much longer');
    });
    it('refuses empty answers, too-long answers and any attempt to write a rating', () => {
      expect(checkSuggestion(original, '   ', 20000).reject).toBeDefined();
      expect(checkSuggestion(original, 'x'.repeat(30), 10).reject).toBeDefined();
      expect(checkSuggestion(original, 'Condition rating is: 1', 20000).reject).toMatch(/never allowed/);
    });
  });
});
