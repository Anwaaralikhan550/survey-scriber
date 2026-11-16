import { Body, Controller, HttpCode, HttpStatus, Param, ParseUUIDPipe, Post, Req, UseGuards, UseInterceptors } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { Request } from 'express';
import { Public } from '../auth/decorators/public.decorator';
import { EditorRequest, EditorSecurityHeadersInterceptor, EditorSessionGuard } from './editor.guard';
import { AiSuggestionService } from './ai-suggestion.service';
import { SuggestDto, SuggestionOutcomeDto } from './dto/ai.dto';
import { SuggestionAction } from './ai-guardrails';

/** AI wording suggestions for the browser editor (spec section 13, Screen E). Same session cookie and CSRF rules as every editor write. */
@ApiTags('Report editor AI')
@Controller('editor/reports/:id/ai')
@UseGuards(EditorSessionGuard)
@UseInterceptors(EditorSecurityHeadersInterceptor)
export class EditorAiController {
  constructor(private readonly ai: AiSuggestionService) {}

  @Public()
  @Post('suggest')
  @HttpCode(HttpStatus.OK)
  @Throttle({ short: { limit: 2, ttl: 1000 }, medium: { limit: Number(process.env.EDITOR_AI_LIMIT_PER_MINUTE ?? 12), ttl: 60000 } })
  suggest(@Param('id', ParseUUIDPipe) id: string, @Body() dto: SuggestDto, @Req() req: EditorRequest) {
    return this.ai.suggest(req.editor, id, { blockId: dto.blockId, action: dto.action as SuggestionAction, expectedVersion: dto.expectedReportVersion }, req as unknown as Request);
  }

  @Public()
  @Post('outcome')
  @HttpCode(HttpStatus.OK)
  outcome(@Param('id', ParseUUIDPipe) id: string, @Body() dto: SuggestionOutcomeDto, @Req() req: EditorRequest) {
    return this.ai.recordOutcome(req.editor, id, dto, req as unknown as Request);
  }
}
