import { ReportStatus } from '@prisma/client';
import { DAY_MS, DEFAULT_POLICY, RetentionInput, RetentionState, backoffMinutes, dayNumber, daysLeft, dueWarning, eligible, parseDays, retentionOf, warningDays } from './retention';
import { formatDate, holdPlacedText, holdReleasedText, purgedText, warningText } from './retention-messages';

const T0 = new Date('2026-11-19T09:00:00.000Z');
const at = (days: number, extraHours = 0) => new Date(T0.getTime() + days * DAY_MS + extraHours * 3_600_000);
const base: RetentionInput = { status: ReportStatus.FINALISED, updatedAt: T0, finalisedAt: T0, restoredAt: null, linkLive: false };

describe('spec 15.1: a finalised report lives 60 days from finalisation', () => {
  const state = retentionOf(base)!;

  it('day 0: the deadline is finalisedAt + 60 days; nothing is due, nothing is eligible', () => {
    expect(state.kind).toBe('FINALISED');
    expect(state.anchorAt).toEqual(T0);
    expect(state.deleteAt).toEqual(at(60));
    expect(dueWarning('FINALISED', T0, at(0), [])).toBeNull();
    expect(eligible(state, at(0), { held: false, graceUntil: null, linkLive: false })).toBe(false);
  });

  it.each([
    [29, null],
    [30, 30],
    [44, 30],
    [45, 45],
    [54, 45],
    [55, 55],
    [59, 55],
  ])('day %i: the warning that is due (when none was sent) is %s', (day, due) => {
    expect(dueWarning('FINALISED', T0, at(day, 3), [])).toBe(due);
  });

  it('a warning is sent once: with the day-30 warning already sent, day 44 has nothing new, day 45 has the second', () => {
    expect(dueWarning('FINALISED', T0, at(44), [30])).toBeNull();
    expect(dueWarning('FINALISED', T0, at(45), [30])).toBe(45);
    expect(dueWarning('FINALISED', T0, at(55), [30, 45])).toBe(55);
    expect(dueWarning('FINALISED', T0, at(59), [30, 45, 55])).toBeNull();
  });

  it('a job that ran late sends only the latest warning reached, not a burst', () => {
    expect(dueWarning('FINALISED', T0, at(50), [])).toBe(45);
    expect(dueWarning('FINALISED', T0, at(57), [])).toBe(55);
  });

  it('day 59 is not yet eligible; day 60 is, exactly at the deadline', () => {
    const open = { held: false, graceUntil: null, linkLive: false };
    expect(eligible(state, at(59, 23), open)).toBe(false);
    expect(eligible(state, at(60, -0.001), open)).toBe(false);
    expect(eligible(state, at(60), open)).toBe(true);
    expect(eligible(state, at(400), open)).toBe(true);
  });

  it('days left count down to the deadline and stop at 0', () => {
    expect(daysLeft(state.deleteAt, at(0))).toBe(60);
    expect(daysLeft(state.deleteAt, at(30))).toBe(30);
    expect(daysLeft(state.deleteAt, at(59, 1))).toBe(1);
    expect(daysLeft(state.deleteAt, at(70))).toBe(0);
  });

  it('downloading an archive changes nothing: the dates come only from finalisation', () => {
    expect(retentionOf({ ...base, updatedAt: at(10) })!.deleteAt).toEqual(at(60));
  });
});

describe('spec 15.2: a draft lives 30 days from the last meaningful activity', () => {
  const draft: RetentionInput = { status: ReportStatus.DRAFT, updatedAt: T0, finalisedAt: null, restoredAt: null, linkLive: false };
  const state = retentionOf(draft)!;

  it('day 0: the deadline is the last activity + 30 days', () => {
    expect(state.kind).toBe('DRAFT');
    expect(state.anchorAt).toEqual(T0);
    expect(state.deleteAt).toEqual(at(30));
    expect(warningDays('DRAFT')).toEqual([20, 25, 28]);
  });

  it.each([
    [0, null],
    [19, null],
    [20, 20],
    [24, 20],
    [25, 25],
    [27, 25],
    [28, 28],
    [29, 28],
  ])('day %i: the warning due is %s', (day, due) => {
    expect(dueWarning('DRAFT', T0, at(day, 2), [])).toBe(due);
  });

  it('day 29 is not eligible, day 30 is', () => {
    const open = { held: false, graceUntil: null, linkLive: false };
    expect(eligible(state, at(29, 23), open)).toBe(false);
    expect(eligible(state, at(30), open)).toBe(true);
  });

  it('new activity moves the anchor, so the deadline and the warnings start again', () => {
    const resumed = retentionOf({ ...draft, updatedAt: at(27) })!;
    expect(resumed.anchorAt).toEqual(at(27));
    expect(resumed.deleteAt).toEqual(at(57));
    expect(dueWarning('DRAFT', resumed.anchorAt, at(28), [])).toBeNull();
    expect(dayNumber(resumed.anchorAt, at(47))).toBe(20);
    expect(dueWarning('DRAFT', resumed.anchorAt, at(47), [])).toBe(20);
  });

  it('a draft reopened from final starts its 30 days at the reopening', () => {
    const reopened = retentionOf({ status: ReportStatus.DRAFT, updatedAt: at(50), finalisedAt: null, restoredAt: null, linkLive: false })!;
    expect(reopened.deleteAt).toEqual(at(80));
  });
});

describe('safeguards: active work, live link, hold, grace', () => {
  const finalised = retentionOf(base)!;
  const late = at(100);

  it.each([ReportStatus.SUBMITTED_FOR_REVIEW, ReportStatus.UNDER_REVIEW, ReportStatus.AMENDMENTS_REQUIRED, ReportStatus.REVIEWER_APPROVED, ReportStatus.OWNER_FINAL_APPROVAL, ReportStatus.FINALISING])(
    '%s is a workflow in progress: no retention clock at all',
    (status) => expect(retentionOf({ ...base, status })).toBeNull(),
  );

  it('a legal hold, a live edit link or a grace period each stop deletion; all clear means eligible', () => {
    expect(eligible(finalised, late, { held: true, graceUntil: null, linkLive: false })).toBe(false);
    expect(eligible(finalised, late, { held: false, graceUntil: null, linkLive: true })).toBe(false);
    expect(eligible(finalised, late, { held: false, graceUntil: at(105), linkLive: false })).toBe(false);
    expect(eligible(finalised, late, { held: false, graceUntil: at(99), linkLive: false })).toBe(true);
    expect(eligible(finalised, late, { held: false, graceUntil: null, linkLive: false })).toBe(true);
  });

  it('retention counts from the moment it was switched on for reports that already existed', () => {
    const policy = { ...DEFAULT_POLICY, startsAt: at(500) };
    const old = retentionOf({ ...base, finalisedAt: at(-300) }, policy)!;
    expect(old.anchorAt).toEqual(at(500));
    expect(old.deleteAt).toEqual(at(560));
    const oldDraft = retentionOf({ status: ReportStatus.DRAFT, updatedAt: at(-90), finalisedAt: null, restoredAt: null, linkLive: false }, policy)!;
    expect(oldDraft.deleteAt).toEqual(at(530));
    const newer = retentionOf({ ...base, finalisedAt: at(510) }, policy)!;
    expect(newer.anchorAt).toEqual(at(510));
  });

  it('a restored finalised report counts from the restore, not from its old finalisation', () => {
    const restored = retentionOf({ ...base, finalisedAt: at(-200), restoredAt: at(5) })!;
    expect(restored.anchorAt).toEqual(at(5));
    expect(restored.deleteAt).toEqual(at(65));
    expect(retentionOf({ ...base, finalisedAt: at(8), restoredAt: at(5) })!.anchorAt).toEqual(at(8));
  });

  it('the configured days are used', () => {
    const s = retentionOf(base, { ...DEFAULT_POLICY, finalisedDays: 90 }) as RetentionState;
    expect(s.deleteAt).toEqual(at(90));
  });
});

describe('helpers', () => {
  it('warning days from configuration text; bad values fall back', () => {
    expect(parseDays('55, 30,45,30', [1])).toEqual([30, 45, 55]);
    expect(parseDays('abc', [1, 2])).toEqual([1, 2]);
    expect(parseDays('', [3])).toEqual([3]);
    expect(parseDays(undefined, [4])).toEqual([4]);
    expect(parseDays('0,-5', [9])).toEqual([9]);
  });

  it('retry back-off grows and is capped at a day', () => {
    expect([1, 2, 3, 4].map(backoffMinutes)).toEqual([5, 10, 20, 40]);
    expect(backoffMinutes(30)).toBe(24 * 60);
  });
});

describe('the words of the notices', () => {
  const anchor = T0;
  const deleteAt = at(60);

  it('finalised warning: what, when, what to do, and that the archive does not extend it', () => {
    const w = warningText({ kind: 'FINALISED', title: '54 Gas Lane', day: 30, isFinal: false, anchorAt: anchor, deleteAt, now: at(30) });
    expect(w.title).toBe('Report "54 Gas Lane" will be removed in 30 days');
    expect(w.body).toContain('finalised on 19 Nov 2026');
    expect(w.body).toContain('removed from the cloud on 18 Jan 2027');
    expect(w.body).toContain('Download the complete archive');
    expect(w.body).toContain('does not extend the 60 days');
  });

  it('the last warning says so, with one day left in the singular', () => {
    const w = warningText({ kind: 'FINALISED', title: 'X', day: 55, isFinal: true, anchorAt: anchor, deleteAt, now: at(59, 1) });
    expect(w.title).toBe('Final warning: Report "X" will be removed in 1 day');
  });

  it('draft warning: working on it restarts the 30 days, opening it does not', () => {
    const w = warningText({ kind: 'DRAFT', title: '12 High St', day: 20, isFinal: false, anchorAt: anchor, deleteAt: at(30), now: at(20) });
    expect(w.title).toBe('Draft "12 High St" will be removed in 10 days');
    expect(w.body).toContain('make a change');
    expect(w.body).toContain('Merely opening the report does not restart the 30 days');
  });

  it('hold and purge notices', () => {
    expect(holdPlacedText('X', 'Client complaint ref 77', 'MANAGER').body).toContain('will not be deleted, whatever its age');
    expect(holdPlacedText('X', 'Client complaint ref 77', 'MANAGER').body).toContain('Reason given: Client complaint ref 77');
    expect(holdReleasedText('X', at(7), 'Dispute settled').body).toContain('not be deleted before 26 Nov 2026');
    expect(purgedText('X', 'DRAFT').body).toContain('30-day inactivity');
    expect(purgedText('X', 'FINALISED').body).toContain('no report content');
    expect(formatDate(new Date('2027-01-05T23:59:59Z'))).toBe('5 Jan 2027');
  });
});
