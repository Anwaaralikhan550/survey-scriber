import { HttpStatus, Injectable, Logger } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { Request } from 'express';
import { ActorType, AuditEntityType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { ReportAuditService } from './report-audit.service';
import { AiGeminiService, GeminiError } from '../ai/ai-gemini.service';
import { EditorContext } from './editor-session.service';
import { Errors, editingError } from './editing.errors';
import { LIMITS, ReportContent, sanitizeText } from './report-content';
import { SuggestionAction, SYSTEM_PROMPT, checkSuggestion, ineligibleReason, redact, restore, userPrompt, wordingOf } from './ai-guardrails';

export interface Suggestion {
  suggestionId: string;
  blockId: string;
  action: SuggestionAction;
  original: string;
  suggestion: string;
  baseVersion: number;
  warnings: string[];
  model: string;
}

/**
 * AI wording suggestions for the browser editor (client spec v1.3 section 13, Screen E).
 * The server never changes the report here: it only returns a suggestion for one block.
 * The user applies it through the normal save (version-checked), so nothing is auto-applied.
 */
@Injectable()
export class AiSuggestionService {
  private readonly logger = new Logger(AiSuggestionService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly gemini: AiGeminiService,
    private readonly audit: AuditService,
    private readonly fieldAudit: ReportAuditService,
  ) {}

  private log(action: string, reportId: string, req: Request | undefined, metadata: Record<string, unknown>) {
    return this.audit.log({ actorType: ActorType.SYSTEM, action, entityType: AuditEntityType.REPORT, entityId: reportId, metadata, request: req });
  }

  async suggest(ctx: EditorContext, reportId: string, input: { blockId: string; action: SuggestionAction; expectedVersion: number }, req?: Request): Promise<Suggestion> {
    if (ctx.report.id !== reportId) throw Errors.forbidden();
    if (ctx.readOnly) throw ctx.readOnlyReason === 'REPORT_FINALISED' ? Errors.finalised() : Errors.linkExpired();

    // Read fresh: the suggestion must be about the text as it is saved now.
    const report = await this.prisma.report.findUniqueOrThrow({ where: { id: reportId }, select: { version: true, content: true } });
    if (report.version !== input.expectedVersion) throw Errors.conflict(report.version);

    const found = this.find(report.content as unknown as ReportContent, input.blockId);
    if (!found) throw editingError(HttpStatus.NOT_FOUND, 'NOT_FOUND', 'That paragraph no longer exists');
    const reason = ineligibleReason(found.block);
    if (reason) throw Errors.validation(reason, 'blockId');

    const original = wordingOf(found.block);
    const { text: safeText, map } = redact(original);
    const model = this.gemini.getModelForType('FLASH');

    let raw: string;
    try {
      const out = await this.gemini.generateContent({
        model,
        systemPrompt: SYSTEM_PROMPT,
        userPrompt: userPrompt(input.action, found.sectionTitle, safeText),
        maxTokens: 2048,
        temperature: 0.2,
      });
      raw = out.text;
    } catch (e) {
      const type = e instanceof GeminiError ? e.type : 'UNKNOWN';
      this.logger.warn(`AI suggestion failed for report ${reportId}: ${type}`);
      await this.log('AI_SUGGESTION_FAILED', reportId, req, { blockId: input.blockId, action: input.action, errorType: type });
      throw Errors.aiUnavailable();
    }

    const suggestion = sanitizeText(restore(raw, map)).trim().replace(/^["“”]+|["“”]+$/g, '').trim();
    const check = checkSuggestion(original, suggestion, LIMITS.maxTextLength);
    if (check.reject) {
      await this.log('AI_SUGGESTION_REJECTED_BY_GUARD', reportId, req, { blockId: input.blockId, action: input.action, reason: check.reject });
      throw Errors.aiUnavailable(`${check.reject} Your report is unchanged.`);
    }

    const id = randomUUID();
    // Lengths only: the audit trail never holds report text or the model's answer.
    await this.log('AI_SUGGESTION_CREATED', reportId, req, {
      suggestionId: id, blockId: input.blockId, action: input.action, baseVersion: report.version, originalLength: original.length, suggestionLength: suggestion.length, warnings: check.warnings.length, redacted: map.size, model,
    });
    return { suggestionId: id, blockId: input.blockId, action: input.action, original, suggestion, baseVersion: report.version, warnings: check.warnings, model };
  }

  /** The user's decision. Accepted text was applied by a normal, version-checked save; this only records what happened. */
  async recordOutcome(ctx: EditorContext, reportId: string, dto: { suggestionId: string; blockId: string; outcome: string; action?: string; finalLength?: number }, req?: Request) {
    if (ctx.report.id !== reportId) throw Errors.forbidden();
    const created = await this.prisma.auditLog.findFirst({
      where: { action: 'AI_SUGGESTION_CREATED', entityId: reportId, metadata: { path: ['suggestionId'], equals: dto.suggestionId } },
      select: { id: true },
    });
    if (!created) throw editingError(HttpStatus.NOT_FOUND, 'NOT_FOUND', 'Unknown suggestion');
    await this.log(`AI_SUGGESTION_${dto.outcome}`, reportId, req, { suggestionId: dto.suggestionId, blockId: dto.blockId, action: dto.action, finalLength: dto.finalLength });
    // The amendment history also says that the accepted wording came from an AI suggestion the user accepted (or that one was rejected).
    if (/^(ACCEPTED|ACCEPTED_MODIFIED|REJECTED)$/.test(dto.outcome)) {
      const report = await this.prisma.report.findUniqueOrThrow({ where: { id: reportId }, select: { version: true } });
      await this.fieldAudit.recordNote(
        this.prisma,
        { reportId, version: report.version, actor: `session:${ctx.session.id}`, sessionId: ctx.session.id, source: 'AI' },
        { entityType: 'BLOCK', entityId: dto.blockId, field: 'text', op: dto.outcome === 'REJECTED' ? 'AI_REJECTED' : 'AI_ACCEPTED', after: { suggestionId: dto.suggestionId, outcome: dto.outcome, action: dto.action ?? null } },
      );
    }
    return { ok: true };
  }

  private find(content: ReportContent, blockId: string) {
    for (const s of content) {
      const block = s.blocks.find((b) => b.id === blockId);
      if (block) return { block, sectionTitle: s.title };
    }
    return null;
  }
}
