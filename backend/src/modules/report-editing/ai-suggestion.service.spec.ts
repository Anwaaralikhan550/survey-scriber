import { HttpException } from '@nestjs/common';
import { AiSuggestionService } from './ai-suggestion.service';
import { GeminiError, GeminiErrorType } from '../ai/ai-gemini.service';
import { EditorContext } from './editor-session.service';

const REPORT = '11111111-1111-4111-8111-111111111111';
const PARA = '22222222-2222-4222-8222-222222222222';
const RATING = '33333333-3333-4333-8333-333333333333';
const REC = '66666666-6666-4666-8666-666666666666';
const TABLE = '44444444-4444-4444-8444-444444444444';

const content = [
  {
    id: '55555555-5555-4555-8555-555555555555',
    key: 'E1_ROOF',
    title: 'Roof',
    blocks: [
      { id: PARA, type: 'paragraph', text: 'The roof has 12 slipped tiles. Call 07700 900123.' },
      { id: REC, type: 'recommendation', recommendation: 'Repair the ridge within 12 months.' },
      { id: RATING, type: 'rating', rating: '2' },
      { id: TABLE, type: 'table', table: { headers: ['a'], rows: [['b']] } },
    ],
  },
];

function setup(opts: { reply?: string; fail?: boolean; version?: number } = {}) {
  const audit = { log: jest.fn().mockResolvedValue(undefined) };
  const prisma = {
    report: { findUniqueOrThrow: jest.fn().mockResolvedValue({ version: opts.version ?? 4, content }) },
    auditLog: { findFirst: jest.fn() },
  };
  const gemini = {
    getModelForType: jest.fn().mockReturnValue('gemini-test'),
    generateContent: jest.fn(async () => {
      if (opts.fail) throw new GeminiError(GeminiErrorType.NOT_CONFIGURED, 'x', 503, false);
      return { text: opts.reply ?? 'The roof has 12 slipped tiles; please call 07700 900123.', inputTokens: 1, outputTokens: 1 };
    }),
  };
  const fieldAudit = { recordNote: jest.fn().mockResolvedValue(undefined) };
  const svc = new AiSuggestionService(prisma as never, gemini as never, audit as never, fieldAudit as never);
  const ctx = { report: { id: REPORT }, session: { id: 'session-1' }, readOnly: false } as unknown as EditorContext;
  return { svc, ctx, audit, prisma, gemini, fieldAudit };
}

const codeOf = async (p: Promise<unknown>) => {
  try {
    await p;
  } catch (e) {
    const r = (e as HttpException).getResponse() as { error: string };
    return { status: (e as HttpException).getStatus(), code: r.error };
  }
  return null;
};

describe('AiSuggestionService', () => {
  it('returns a suggestion for one paragraph and never changes the report', async () => {
    const { svc, ctx, prisma, gemini } = setup();
    const out = await svc.suggest(ctx, REPORT, { blockId: PARA, action: 'IMPROVE', expectedVersion: 4 });
    expect(out).toMatchObject({ blockId: PARA, action: 'IMPROVE', baseVersion: 4, model: 'gemini-test', warnings: [] });
    expect(out.original).toBe('The roof has 12 slipped tiles. Call 07700 900123.');
    expect(out.suggestion).toBe('The roof has 12 slipped tiles; please call 07700 900123.');
    expect(out.suggestionId).toMatch(/^[0-9a-f-]{36}$/);
    expect(Object.keys(prisma.report)).toEqual(['findUniqueOrThrow']); // no write call exists on the mock: nothing was saved
    expect(gemini.generateContent).toHaveBeenCalledTimes(1);
  });

  it('the model never sees the phone number; it comes back into the answer from the placeholder', async () => {
    const { svc, ctx, gemini } = setup({ reply: 'The roof has 12 slipped tiles. Please call [PHONE_1].' });
    const out = await svc.suggest(ctx, REPORT, { blockId: PARA, action: 'FORMAL', expectedVersion: 4 });
    const sent = (gemini.generateContent.mock.calls[0] as unknown as [{ userPrompt: string }])[0].userPrompt;
    expect(sent).not.toContain('07700');
    expect(sent).toContain('[PHONE_1]');
    expect(out.suggestion).toContain('07700 900123');
  });

  it('recommendations are suggested for from their own field', async () => {
    const { svc, ctx, gemini } = setup({ reply: 'Repair the ridge within 12 months.' });
    const out = await svc.suggest(ctx, REPORT, { blockId: REC, action: 'IMPROVE', expectedVersion: 4 });
    expect(out.original).toBe('Repair the ridge within 12 months.');
    expect((gemini.generateContent.mock.calls[0] as unknown as [{ userPrompt: string }])[0].userPrompt).toContain('Repair the ridge');
  });

  it('refuses ratings and tables, whatever the action', async () => {
    const { svc, ctx, gemini } = setup();
    for (const id of [RATING, TABLE]) {
      expect(await codeOf(svc.suggest(ctx, REPORT, { blockId: id, action: 'IMPROVE', expectedVersion: 4 }))).toEqual({ status: 400, code: 'VALIDATION_ERROR' });
    }
    expect(gemini.generateContent).not.toHaveBeenCalled();
  });

  it('refuses text the user is not looking at (version moved on)', async () => {
    const { svc, ctx, gemini } = setup({ version: 5 });
    expect(await codeOf(svc.suggest(ctx, REPORT, { blockId: PARA, action: 'IMPROVE', expectedVersion: 4 }))).toEqual({ status: 409, code: 'VERSION_CONFLICT' });
    expect(gemini.generateContent).not.toHaveBeenCalled();
  });

  it('read-only sessions (finalised or expired) cannot ask', async () => {
    const { svc, gemini } = setup();
    const fin = { report: { id: REPORT }, readOnly: true, readOnlyReason: 'REPORT_FINALISED' } as unknown as EditorContext;
    const exp = { report: { id: REPORT }, readOnly: true, readOnlyReason: 'LINK_EXPIRED' } as unknown as EditorContext;
    expect(await codeOf(svc.suggest(fin, REPORT, { blockId: PARA, action: 'IMPROVE', expectedVersion: 4 }))).toEqual({ status: 403, code: 'REPORT_FINALISED' });
    expect(await codeOf(svc.suggest(exp, REPORT, { blockId: PARA, action: 'IMPROVE', expectedVersion: 4 }))).toEqual({ status: 410, code: 'LINK_EXPIRED' });
    expect(gemini.generateContent).not.toHaveBeenCalled();
  });

  it('a report of another link is forbidden', async () => {
    const { svc, ctx } = setup();
    expect(await codeOf(svc.suggest(ctx, '99999999-9999-4999-8999-999999999999', { blockId: PARA, action: 'IMPROVE', expectedVersion: 4 }))).toEqual({ status: 403, code: 'FORBIDDEN' });
  });

  it('when the AI is down the user gets a clear 503 and the report is untouched', async () => {
    const { svc, ctx, audit } = setup({ fail: true });
    expect(await codeOf(svc.suggest(ctx, REPORT, { blockId: PARA, action: 'IMPROVE', expectedVersion: 4 }))).toEqual({ status: 503, code: 'AI_UNAVAILABLE' });
    expect(audit.log).toHaveBeenCalledWith(expect.objectContaining({ action: 'AI_SUGGESTION_FAILED' }));
  });

  it('an answer that writes a rating is thrown away, not shown', async () => {
    const { svc, ctx, audit } = setup({ reply: 'Condition rating is: 1' });
    expect(await codeOf(svc.suggest(ctx, REPORT, { blockId: PARA, action: 'IMPROVE', expectedVersion: 4 }))).toEqual({ status: 503, code: 'AI_UNAVAILABLE' });
    expect(audit.log).toHaveBeenCalledWith(expect.objectContaining({ action: 'AI_SUGGESTION_REJECTED_BY_GUARD' }));
  });

  it('flags new figures and new severity wording as warnings', async () => {
    const { svc, ctx } = setup({ reply: 'The roof has 20 slipped tiles, a serious structural problem. Call 07700 900123.' });
    const out = await svc.suggest(ctx, REPORT, { blockId: PARA, action: 'IMPROVE', expectedVersion: 4 });
    const w = out.warnings.join('|');
    expect(w).toContain('New figure: 20');
    expect(w).toContain('missing: 12');
    expect(w).toContain('"serious"');
    expect(w).toContain('"structural"');
  });

  it('strips markup and surrounding quotes from the answer', async () => {
    const { svc, ctx } = setup({ reply: '"The roof has 12 slipped tiles. <b>Call</b> 07700 900123."' });
    const out = await svc.suggest(ctx, REPORT, { blockId: PARA, action: 'IMPROVE', expectedVersion: 4 });
    expect(out.suggestion).toBe('The roof has 12 slipped tiles. Call 07700 900123.');
  });

  it('the audit trail holds lengths, never report text or the answer', async () => {
    const { svc, ctx, audit } = setup();
    await svc.suggest(ctx, REPORT, { blockId: PARA, action: 'SHORTEN', expectedVersion: 4 });
    const entry = audit.log.mock.calls.map((c) => c[0]).find((a: { action: string }) => a.action === 'AI_SUGGESTION_CREATED');
    expect(entry.metadata).toMatchObject({ blockId: PARA, action: 'SHORTEN', baseVersion: 4, redacted: 1 });
    expect(JSON.stringify(entry.metadata)).not.toMatch(/slipped|07700/);
  });

  it('outcomes are recorded only for a suggestion this report was given', async () => {
    const { svc, ctx, prisma, audit, fieldAudit } = setup();
    prisma.auditLog.findFirst.mockResolvedValueOnce(null);
    expect(await codeOf(svc.recordOutcome(ctx, REPORT, { suggestionId: PARA, blockId: PARA, outcome: 'ACCEPTED' }))).toEqual({ status: 404, code: 'NOT_FOUND' });
    prisma.auditLog.findFirst.mockResolvedValueOnce({ id: 'x' });
    await svc.recordOutcome(ctx, REPORT, { suggestionId: PARA, blockId: PARA, outcome: 'ACCEPTED_MODIFIED', action: 'IMPROVE', finalLength: 40 });
    expect(audit.log).toHaveBeenCalledWith(expect.objectContaining({ action: 'AI_SUGGESTION_ACCEPTED_MODIFIED', metadata: expect.objectContaining({ finalLength: 40 }) }));
    expect(fieldAudit.recordNote).toHaveBeenCalledWith(prisma, expect.objectContaining({ source: 'AI', actor: 'session:session-1' }), expect.objectContaining({ op: 'AI_ACCEPTED', entityId: PARA }));
    // a refused outcome (unknown suggestion) leaves nothing in the history
    expect(fieldAudit.recordNote).toHaveBeenCalledTimes(1);
  });
});
