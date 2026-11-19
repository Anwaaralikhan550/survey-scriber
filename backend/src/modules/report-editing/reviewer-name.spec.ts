import { cleanReviewerName } from './reviewer-name';

describe('cleanReviewerName', () => {
  it('accepts ordinary names in any language and tidies them', () => {
    expect(cleanReviewerName('Jane Smith')).toBe('Jane Smith');
    expect(cleanReviewerName('  Jane    Smith  ')).toBe('Jane Smith');
    expect(cleanReviewerName("Zoë O'Brien-Smith")).toBe("Zoë O'Brien-Smith");
    expect(cleanReviewerName('محمد علي')).toBe('محمد علي');
    expect(cleanReviewerName('李小龙')).toBe('李小龙');
    expect(cleanReviewerName('J. R. Smith (Surveyor)')).toBe('J. R. Smith (Surveyor)');
    expect(cleanReviewerName('Dr. Ali, B.Sc.')).toBe('Dr. Ali, B.Sc.');
  });
  it('removes markup and keeps the words; control characters go', () => {
    expect(cleanReviewerName('<b>Jane</b> Smith')).toBe('Jane Smith');
    expect(cleanReviewerName('<script>alert(1)</script>Jane Smith')).toBe('Jane Smith');
    expect(cleanReviewerName('Jane\u0000 Smith\r\n')).toBe('Jane Smith');
  });
  it('refuses what is not a name: empty, too short, too long, symbols, numbers only, not text', () => {
    for (const bad of ['', ' ', 'J', '..', '--', '12', '1234567', 'a', '<b></b>', 'x'.repeat(81), 'Jane; DROP TABLE', 'Jane@example.com', 'http://evil.example', 'Jane\\Smith', 'Jane/Smith', 'Jane "The Roof"']) {
      expect([bad, cleanReviewerName(bad)]).toEqual([bad, null]);
    }
    for (const bad of [undefined, null, 5, {}, ['Jane Smith'], true]) {
      expect(cleanReviewerName(bad)).toBeNull();
    }
  });
  it('the longest allowed name is accepted', () => {
    expect(cleanReviewerName('a'.repeat(80))).toBe('a'.repeat(80));
  });
});
