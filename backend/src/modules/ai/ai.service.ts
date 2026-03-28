import {
  Injectable,
  Logger,
  BadRequestException,
  ServiceUnavailableException,
  InternalServerErrorException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AiFeatureType } from '@prisma/client';
import { AiGeminiService, GeminiError, GeminiErrorType } from './ai-gemini.service';
import { AiCacheService } from './ai-cache.service';
import { AiPromptService } from './ai-prompt.service';
import { EnhancedReportService } from '../../services/enhanced-report.service';
import { AI_DISCLAIMERS, AI_RATE_LIMITS, AI_FEATURE_MODEL_TYPE } from './ai.constants';
import {
  GenerateReportDto,
  GenerateRecommendationsDto,
  GenerateRiskSummaryDto,
  ConsistencyCheckDto,
  PhotoTagsDto,
  AiReportResponseDto,
  AiRecommendationsResponseDto,
  AiRiskSummaryResponseDto,
  AiConsistencyResponseDto,
  AiPhotoTagsResponseDto,
  AiStatusResponseDto,
  SectionNarrativeDto,
  RecommendationDto,
  RiskItemDto,
  ConsistencyIssueDto,
  PhotoTagDto,
} from './dto';
import { createHash } from 'crypto';

interface UserContext {
  userId: string;
  organization?: string;
}

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly gemini: AiGeminiService,
    private readonly cache: AiCacheService,
    private readonly prompts: AiPromptService,
    private readonly enhancedReport: EnhancedReportService,
  ) {}

  /**
   * Check AI service status (public endpoint - no auth required).
   * Does not log usage or consume quota.
   *
   * SEC-M6: Returns ONLY availability boolean + optional error message.
   * Model names, circuit breaker state, and available model lists are internal
   * infrastructure details that help attackers fingerprint the AI provider/version.
   * Detailed status is available via the authenticated /ai/status/detailed endpoint.
   */
  async getPublicStatus(): Promise<AiStatusResponseDto> {
    const detailedStatus = this.gemini.getDetailedStatus();

    if (!detailedStatus.enabled) {
      return {
        available: false,
        message: 'AI service is currently unavailable',
      };
    }

    return {
      available: true,
    };
  }

  /**
   * Check AI service status and availability with quota info (authenticated).
   * B3 FIX: Now includes both org-level and user-level quota information.
   */
  async getStatus(user: UserContext): Promise<AiStatusResponseDto> {
    const isAvailable = this.gemini.checkAvailability();

    if (!isAvailable) {
      return {
        available: false,
        message: 'AI service is not configured',
      };
    }

    // Check organization daily quota
    const orgQuota = await this.getDailyQuota(user.organization || 'default');
    const orgQuotaRemaining = AI_RATE_LIMITS.ORG_DAILY_TOKENS - orgQuota.tokensUsed;

    // B3 FIX: Check user daily quota
    const userQuota = await this.getUserDailyQuota(user.userId);
    const userQuotaRemaining = AI_RATE_LIMITS.USER_DAILY_TOKENS - userQuota.tokensUsed;

    // Check if either quota is exceeded
    if (orgQuotaRemaining <= 0) {
      return {
        available: false,
        message: 'Organization daily AI quota exceeded. Please try again tomorrow.',
        quotaRemaining: 0,
        quotaLimit: AI_RATE_LIMITS.ORG_DAILY_TOKENS,
      };
    }

    if (userQuotaRemaining <= 0) {
      return {
        available: false,
        message: 'Your daily AI quota exceeded. Please try again tomorrow.',
        quotaRemaining: 0,
        quotaLimit: AI_RATE_LIMITS.USER_DAILY_TOKENS,
      };
    }

    // Return the more restrictive quota (lower of org or user remaining)
    const effectiveRemaining = Math.min(orgQuotaRemaining, userQuotaRemaining);
    const effectiveLimit = Math.min(AI_RATE_LIMITS.ORG_DAILY_TOKENS, AI_RATE_LIMITS.USER_DAILY_TOKENS);

    return {
      available: true,
      quotaRemaining: effectiveRemaining,
      quotaLimit: effectiveLimit,
    };
  }

  /**
   * Generate AI report narratives
   * NOW WITH EXCEL PHRASE INTEGRATION
   * - First checks for professional phrases from Excel database
   * - Only uses AI for fields without predefined phrases
   * - Reduces AI costs and improves consistency
   */
  async generateReport(
    dto: GenerateReportDto,
    user: UserContext,
  ): Promise<AiReportResponseDto> {
    const featureType: AiFeatureType = 'REPORT';
    await this.checkAvailabilityAndQuota(user);

    const prompt = this.prompts.getPrompt(featureType);
    this.logger.log(
      `Report request: surveyId=${dto.surveyId}, ` +
      `sections=${dto.sections?.length ?? 0}, issues=${dto.issues?.length ?? 0}, ` +
      `promptVersion=${prompt.version}`,
    );

    // ========================================
    // STEP 1: Enrich with Excel Phrases
    // ========================================
    const enrichedSections = this.enhancedReport.enrichSectionsWithPhrases(dto.sections);
    const { ast, sectionsWithPhrases, stats } = this.enhancedReport.buildReportWithExcelPhrases(
      enrichedSections,
      {
        surveyId: dto.surveyId,
        propertyAddress: dto.propertyAddress,
        propertyType: dto.propertyType,
      },
    );

    this.logger.log(
      `Excel phrase coverage: ${stats.excelPhraseCount}/${stats.totalFields} ` +
      `(${stats.coveragePercent}%) fields using professional phrases`,
    );

    // If 100% Excel coverage, return immediately without AI call!
    if (stats.aiNeededCount === 0 && stats.excelPhraseCount > 0) {
      this.logger.log(
        `✓ Report fully generated from Excel phrases (no AI needed)`,
      );

      const sectionNarratives = sectionsWithPhrases.map(s => ({
        sectionId: s.sectionId,
        sectionType: s.sectionType,
        title: s.title,
        narrative: s.narrative,
        confidence: 1.0, // Excel phrases have 100% confidence
      }));

      const executiveSummary = this.buildExecutiveSummaryFromPhrases(sectionsWithPhrases);

      return {
        surveyId: dto.surveyId,
        promptVersion: `excel-${prompt.version}`,
        executiveSummary,
        sections: sectionNarratives,
        ast,
        fromCache: false,
        disclaimer: 'This report uses professional, pre-written phrases from industry-standard templates.',
        usage: {
          inputTokens: 0,
          outputTokens: 0,
        },
        // Add custom metadata to track Excel usage
        metadata: {
          excelPhraseCount: stats.excelPhraseCount,
          aiNeededCount: 0,
          coveragePercent: 100,
          source: 'excel',
        },
      } as AiReportResponseDto & { metadata?: any };
    }

    const inputData = this.prepareReportInput(dto);
    const inputHash = this.hashInput(inputData);

    // Check cache (only for AI-generated parts)
    if (!dto.skipCache) {
      const cacheKey = this.cache.generateCacheKey({
        surveyId: dto.surveyId,
        featureType,
        promptVersion: prompt.version,
        inputData,
      });

      const cached = await this.cache.get(cacheKey);
      if (cached) {
        await this.logUsage(user, featureType, dto.surveyId, prompt.version, cached.inputTokens, cached.outputTokens, true);
        return {
          ...(cached.response as AiReportResponseDto),
          fromCache: true,
        };
      }
    }

    // ========================================
    // STEP 2: Call AI only for sections that need it
    // ========================================
    const sectionsNeedingAI = this.enhancedReport.getSectionsNeedingAI(enrichedSections);

    this.logger.log(
      `AI needed for ${sectionsNeedingAI.length}/${dto.sections.length} sections ` +
      `(${stats.aiNeededCount} fields)`,
    );

    // Build prompt (only for fields needing AI)
    const userPrompt = this.buildPrompt(prompt.userPromptTemplate, {
      propertyAddress: dto.propertyAddress,
      propertyType: dto.propertyType || 'Unknown',
      sectionsJson: JSON.stringify(sectionsNeedingAI, null, 2),
      issuesJson: dto.issues ? JSON.stringify(dto.issues, null, 2) : undefined,
    });

    const startTime = Date.now();
    const validatedModel = this.getValidatedModelForFeature(featureType);

    try {
      const result = await this.gemini.generateContent({
        model: validatedModel,
        systemPrompt: prompt.systemPrompt,
        userPrompt,
        maxTokens: prompt.maxTokens,
        temperature: prompt.temperature,
        responseSchema: prompt.outputSchema,
      });

      const latencyMs = Date.now() - startTime;
      const parsedResponse = this.parseJsonResponse(result.text);

      const aiExecutiveSummary = (parsedResponse.executiveSummary as string) ?? '';
      const aiSectionNarratives = (parsedResponse.sections as SectionNarrativeDto[]) ?? [];

      this.logger.log(
        `AI report generated: surveyId=${dto.surveyId}, ` +
        `aiSections=${aiSectionNarratives.length}, ` +
        `outputTokens=${result.outputTokens}`,
      );

      // ========================================
      // STEP 3: Merge Excel phrases with AI narratives
      // ========================================
      const mergedSections = sectionsWithPhrases.map(excelSection => {
        // Find corresponding AI section
        const aiSection = aiSectionNarratives.find(
          ai => ai.sectionId === excelSection.sectionId,
        );

        // Combine Excel + AI narratives
        const combinedNarrative = [
          excelSection.narrative,
          aiSection?.narrative || '',
        ]
          .filter(Boolean)
          .join('\n\n');

        return {
          sectionId: excelSection.sectionId,
          sectionType: excelSection.sectionType,
          title: excelSection.title,
          narrative: combinedNarrative,
          confidence: aiSection?.confidence || 1.0,
        };
      });

      // Build executive summary (Excel summary + AI summary)
      const excelSummary = this.buildExecutiveSummaryFromPhrases(sectionsWithPhrases);
      const executiveSummary = [excelSummary, aiExecutiveSummary]
        .filter(Boolean)
        .join('\n\n');

      const response: AiReportResponseDto = {
        surveyId: dto.surveyId,
        promptVersion: `hybrid-excel-ai-${prompt.version}`,
        executiveSummary,
        sections: mergedSections,
        ast,
        fromCache: false,
        disclaimer: `This report uses ${stats.coveragePercent}% professional pre-written phrases from industry templates, with AI-generated content for remaining fields. ${AI_DISCLAIMERS.REPORT}`,
        usage: {
          inputTokens: result.inputTokens,
          outputTokens: result.outputTokens,
        },
        // Add metadata to track hybrid generation
        metadata: {
          excelPhraseCount: stats.excelPhraseCount,
          aiNeededCount: stats.aiNeededCount,
          coveragePercent: stats.coveragePercent,
          source: 'hybrid',
        },
      } as AiReportResponseDto & { metadata?: any };

      // Cache the response
      const cacheKey = this.cache.generateCacheKey({
        surveyId: dto.surveyId,
        featureType,
        promptVersion: prompt.version,
        inputData,
      });

      await this.cache.set({
        cacheKey,
        featureType,
        surveyId: dto.surveyId,
        promptVersion: prompt.version,
        inputHash,
        response,
        inputTokens: result.inputTokens,
        outputTokens: result.outputTokens,
      });

      // Log usage
      await this.logUsage(user, featureType, dto.surveyId, prompt.version, result.inputTokens, result.outputTokens, false, latencyMs);

      return response;
    } catch (error) {
      await this.logUsage(user, featureType, dto.surveyId, prompt.version, 0, 0, false, Date.now() - startTime, String(error));
      throw this.handleAiError(error);
    }
  }

  /**
   * Generate recommendations from issues and/or sections.
   * When issues are provided, recommendations target those specific issues.
   * When only sections are provided, the AI infers potential issues from
   * section data and generates general maintenance recommendations.
   */
  async generateRecommendations(
    dto: GenerateRecommendationsDto,
    user: UserContext,
  ): Promise<AiRecommendationsResponseDto> {
    const featureType: AiFeatureType = 'RECOMMENDATIONS';
    await this.checkAvailabilityAndQuota(user);

    const hasIssues = dto.issues && dto.issues.length > 0;
    const hasSections = dto.sections && dto.sections.length > 0;

    this.logger.log(
      `Recommendations request: surveyId=${dto.surveyId}, ` +
      `issues=${dto.issues?.length ?? 0}, sections=${dto.sections?.length ?? 0}, ` +
      `inputMode=${hasIssues ? 'issues' : 'sections'}`,
    );

    if (!hasIssues && !hasSections) {
      throw new BadRequestException('At least one issue or one section is required');
    }

    const prompt = this.prompts.getPrompt(featureType);
    this.logger.log(`Using prompt version ${prompt.version} for RECOMMENDATIONS`);
    const inputData = { issues: dto.issues, sections: dto.sections, propertyAddress: dto.propertyAddress };
    const inputHash = this.hashInput(inputData);

    // Check cache
    if (!dto.skipCache) {
      const cacheKey = this.cache.generateCacheKey({
        surveyId: dto.surveyId,
        featureType,
        promptVersion: prompt.version,
        inputData,
      });

      const cached = await this.cache.get(cacheKey);
      if (cached) {
        await this.logUsage(user, featureType, dto.surveyId, prompt.version, cached.inputTokens, cached.outputTokens, true);
        return {
          ...(cached.response as AiRecommendationsResponseDto),
          fromCache: true,
        };
      }
    }

    // Build prompt substitution data depending on available input
    const promptData: Record<string, string> = {
      propertyAddress: dto.propertyAddress,
      propertyType: dto.propertyType || 'Unknown',
    };

    if (hasIssues) {
      promptData.issuesJson = JSON.stringify(dto.issues, null, 2);
      promptData.sectionsJson = hasSections ? JSON.stringify(dto.sections, null, 2) : 'Not provided';
      promptData.inputMode = 'issues';
    } else {
      promptData.issuesJson = 'No explicit issues recorded';
      promptData.sectionsJson = JSON.stringify(dto.sections, null, 2);
      promptData.inputMode = 'sections';
    }

    const userPrompt = this.buildPrompt(prompt.userPromptTemplate, promptData);

    const startTime = Date.now();
    // CRITICAL: Use validated model from AiGeminiService, NOT from database
    const validatedModel = this.getValidatedModelForFeature(featureType);

    try {
      let recommendations = await this.callGeminiForRecommendations(
        validatedModel, prompt, userPrompt,
      );

      const latencyMs = Date.now() - startTime;

      this.logger.log(
        `Recommendations generated: surveyId=${dto.surveyId}, ` +
        `count=${recommendations.recs.length}, ` +
        `outputTokens=${recommendations.outputTokens}, ` +
        `inputMode=${hasIssues ? 'issues' : 'sections'}`,
      );

      // Retry once with stricter prompt if result is empty or too few
      if (recommendations.recs.length < 3) {
        this.logger.warn(
          `Recommendations too few (${recommendations.recs.length}), retrying with stricter prompt`,
        );
        const retryPrompt = userPrompt +
          '\n\nCRITICAL: You MUST return at least 5 recommendations. ' +
          'Examine every section for maintenance needs, safety checks, ' +
          'compliance requirements, and preventive actions. ' +
          'Do NOT return an empty array.';

        recommendations = await this.callGeminiForRecommendations(
          validatedModel, prompt, retryPrompt,
        );

        this.logger.log(
          `Recommendations retry result: count=${recommendations.recs.length}, ` +
          `outputTokens=${recommendations.outputTokens}`,
        );
      }

      // Deterministic fallback: if AI still returns empty, generate rule-based recommendations
      let finalRecs = recommendations.recs;
      if (finalRecs.length === 0) {
        this.logger.warn('AI returned empty recommendations, using deterministic fallback');
        finalRecs = this.generateFallbackRecommendations(dto);
      }

      const totalInputTokens = recommendations.inputTokens;
      const totalOutputTokens = recommendations.outputTokens;
      const totalLatencyMs = Date.now() - startTime;

      const response: AiRecommendationsResponseDto = {
        surveyId: dto.surveyId,
        promptVersion: prompt.version,
        recommendations: finalRecs,
        fromCache: false,
        disclaimer: AI_DISCLAIMERS.RECOMMENDATIONS,
        usage: {
          inputTokens: totalInputTokens,
          outputTokens: totalOutputTokens,
        },
      };

      // Cache and log
      const cacheKey = this.cache.generateCacheKey({
        surveyId: dto.surveyId,
        featureType,
        promptVersion: prompt.version,
        inputData,
      });

      await this.cache.set({
        cacheKey,
        featureType,
        surveyId: dto.surveyId,
        promptVersion: prompt.version,
        inputHash,
        response,
        inputTokens: totalInputTokens,
        outputTokens: totalOutputTokens,
      });

      await this.logUsage(user, featureType, dto.surveyId, prompt.version, totalInputTokens, totalOutputTokens, false, totalLatencyMs);

      return response;
    } catch (error) {
      await this.logUsage(user, featureType, dto.surveyId, prompt.version, 0, 0, false, Date.now() - startTime, String(error));
      throw this.handleAiError(error);
    }
  }

  /**
   * Generate risk summary
   */
  async generateRiskSummary(
    dto: GenerateRiskSummaryDto,
    user: UserContext,
  ): Promise<AiRiskSummaryResponseDto> {
    const featureType: AiFeatureType = 'RISK_SUMMARY';
    await this.checkAvailabilityAndQuota(user);

    const prompt = this.prompts.getPrompt(featureType);
    this.logger.log(
      `Risk summary request: surveyId=${dto.surveyId}, ` +
      `sections=${dto.sections?.length ?? 0}, issues=${dto.issues?.length ?? 0}, ` +
      `promptVersion=${prompt.version}`,
    );
    const inputData = { sections: dto.sections, issues: dto.issues };
    const inputHash = this.hashInput(inputData);

    // Check cache
    if (!dto.skipCache) {
      const cacheKey = this.cache.generateCacheKey({
        surveyId: dto.surveyId,
        featureType,
        promptVersion: prompt.version,
        inputData,
      });

      const cached = await this.cache.get(cacheKey);
      if (cached) {
        await this.logUsage(user, featureType, dto.surveyId, prompt.version, cached.inputTokens, cached.outputTokens, true);
        return {
          ...(cached.response as AiRiskSummaryResponseDto),
          fromCache: true,
        };
      }
    }

    const userPrompt = this.buildPrompt(prompt.userPromptTemplate, {
      propertyAddress: dto.propertyAddress,
      propertyType: dto.propertyType || 'Unknown',
      sectionsJson: JSON.stringify(dto.sections, null, 2),
      issuesJson: dto.issues ? JSON.stringify(dto.issues, null, 2) : undefined,
    });

    const startTime = Date.now();
    // CRITICAL: Use validated model from AiGeminiService, NOT from database
    // This is the FIX for MODEL_NOT_FOUND errors on risk-summary endpoint
    const validatedModel = this.getValidatedModelForFeature(featureType);
    this.logger.log(`RISK_SUMMARY using validated model: ${validatedModel}`);

    try {
      const result = await this.gemini.generateContent({
        model: validatedModel,
        systemPrompt: prompt.systemPrompt,
        userPrompt,
        maxTokens: prompt.maxTokens,
        temperature: prompt.temperature,
        responseSchema: prompt.outputSchema,
      });

      const latencyMs = Date.now() - startTime;
      const parsedResponse = this.parseJsonResponse(result.text);

      this.logger.log(
        `Risk summary generated: surveyId=${dto.surveyId}, ` +
        `overallRisk=${parsedResponse.overallRiskLevel}, ` +
        `keyRiskDrivers=${(parsedResponse.keyRiskDrivers as string[])?.length ?? 0}, ` +
        `riskByCategory=${(parsedResponse.riskByCategory as unknown[])?.length ?? 0}, ` +
        `outputTokens=${result.outputTokens}`,
      );

      const response: AiRiskSummaryResponseDto = {
        surveyId: dto.surveyId,
        promptVersion: prompt.version,
        overallRiskLevel: (parsedResponse.overallRiskLevel as string) ?? 'medium',
        overallRationale: (parsedResponse.overallRationale as string[]) ?? [],
        summary: (parsedResponse.summary as string) ?? '',
        keyRiskDrivers: (parsedResponse.keyRiskDrivers as string[]) ?? [],
        keyRisks: (parsedResponse.keyRisks as RiskItemDto[]) ?? [],
        keyPositives: (parsedResponse.keyPositives as string[]) ?? [],
        riskByCategory: (parsedResponse.riskByCategory as AiRiskSummaryResponseDto['riskByCategory']) ?? [],
        immediateActions: (parsedResponse.immediateActions as string[]) ?? [],
        shortTermActions: (parsedResponse.shortTermActions as string[]) ?? [],
        longTermActions: (parsedResponse.longTermActions as string[]) ?? [],
        dataGaps: (parsedResponse.dataGaps as string[]) ?? [],
        fromCache: false,
        disclaimer: AI_DISCLAIMERS.RISK_SUMMARY,
        usage: {
          inputTokens: result.inputTokens,
          outputTokens: result.outputTokens,
        },
      };

      // Cache and log
      const cacheKey = this.cache.generateCacheKey({
        surveyId: dto.surveyId,
        featureType,
        promptVersion: prompt.version,
        inputData,
      });

      await this.cache.set({
        cacheKey,
        featureType,
        surveyId: dto.surveyId,
        promptVersion: prompt.version,
        inputHash,
        response,
        inputTokens: result.inputTokens,
        outputTokens: result.outputTokens,
      });

      await this.logUsage(user, featureType, dto.surveyId, prompt.version, result.inputTokens, result.outputTokens, false, latencyMs);

      return response;
    } catch (error) {
      await this.logUsage(user, featureType, dto.surveyId, prompt.version, 0, 0, false, Date.now() - startTime, String(error));
      throw this.handleAiError(error);
    }
  }

  /**
   * Run consistency check
   */
  async checkConsistency(
    dto: ConsistencyCheckDto,
    user: UserContext,
  ): Promise<AiConsistencyResponseDto> {
    const featureType: AiFeatureType = 'CONSISTENCY_CHECK';
    await this.checkAvailabilityAndQuota(user);

    const prompt = this.prompts.getPrompt(featureType);
    const inputData = { sections: dto.sections, issues: dto.issues };
    const inputHash = this.hashInput(inputData);

    // Check cache
    if (!dto.skipCache) {
      const cacheKey = this.cache.generateCacheKey({
        surveyId: dto.surveyId,
        featureType,
        promptVersion: prompt.version,
        inputData,
      });

      const cached = await this.cache.get(cacheKey);
      if (cached) {
        await this.logUsage(user, featureType, dto.surveyId, prompt.version, cached.inputTokens, cached.outputTokens, true);
        return {
          ...(cached.response as AiConsistencyResponseDto),
          fromCache: true,
        };
      }
    }

    const userPrompt = this.buildPrompt(prompt.userPromptTemplate, {
      sectionsJson: JSON.stringify(dto.sections, null, 2),
      issuesJson: dto.issues ? JSON.stringify(dto.issues, null, 2) : undefined,
    });

    const startTime = Date.now();
    // CRITICAL: Use validated model from AiGeminiService, NOT from database
    const validatedModel = this.getValidatedModelForFeature(featureType);

    try {
      const result = await this.gemini.generateContent({
        model: validatedModel,
        systemPrompt: prompt.systemPrompt,
        userPrompt,
        maxTokens: prompt.maxTokens,
        temperature: prompt.temperature,
        responseSchema: prompt.outputSchema,
      });

      const latencyMs = Date.now() - startTime;
      const parsedResponse = this.parseJsonResponse(result.text);

      const response: AiConsistencyResponseDto = {
        surveyId: dto.surveyId,
        promptVersion: prompt.version,
        score: (parsedResponse.score as number) ?? 80,
        issues: (parsedResponse.issues as ConsistencyIssueDto[]) ?? [],
        fromCache: false,
        disclaimer: AI_DISCLAIMERS.CONSISTENCY_CHECK,
        usage: {
          inputTokens: result.inputTokens,
          outputTokens: result.outputTokens,
        },
      };

      // Cache and log
      const cacheKey = this.cache.generateCacheKey({
        surveyId: dto.surveyId,
        featureType,
        promptVersion: prompt.version,
        inputData,
      });

      await this.cache.set({
        cacheKey,
        featureType,
        surveyId: dto.surveyId,
        promptVersion: prompt.version,
        inputHash,
        response,
        inputTokens: result.inputTokens,
        outputTokens: result.outputTokens,
      });

      await this.logUsage(user, featureType, dto.surveyId, prompt.version, result.inputTokens, result.outputTokens, false, latencyMs);

      return response;
    } catch (error) {
      await this.logUsage(user, featureType, dto.surveyId, prompt.version, 0, 0, false, Date.now() - startTime, String(error));
      throw this.handleAiError(error);
    }
  }

  /**
   * Generate photo tags
   */
  async generatePhotoTags(
    dto: PhotoTagsDto,
    user: UserContext,
  ): Promise<AiPhotoTagsResponseDto> {
    const featureType: AiFeatureType = 'PHOTO_TAGS';
    await this.checkAvailabilityAndQuota(user);

    const prompt = this.prompts.getPrompt(featureType);

    // For photos, cache key includes photo ID
    const inputData = { photoId: dto.photoId, context: dto.sectionContext };
    const inputHash = this.hashInput(inputData);

    // Check cache
    if (!dto.skipCache) {
      const cacheKey = `${featureType}_${dto.photoId}_${prompt.version}_${inputHash}`;

      const cached = await this.cache.get(cacheKey);
      if (cached) {
        await this.logUsage(user, featureType, dto.surveyId, prompt.version, cached.inputTokens, cached.outputTokens, true);
        return {
          ...(cached.response as AiPhotoTagsResponseDto),
          fromCache: true,
        };
      }
    }

    const userPrompt = this.buildPrompt(prompt.userPromptTemplate, {
      sectionContext: dto.sectionContext,
      existingCaption: dto.existingCaption,
    });

    const startTime = Date.now();
    // CRITICAL: Use validated model from AiGeminiService, NOT from database
    const validatedModel = this.getValidatedModelForFeature(featureType);

    try {
      // Extract base64 data (remove data URL prefix if present)
      let imageBase64 = dto.imageData;
      let mimeType = 'image/jpeg';

      if (imageBase64.startsWith('data:')) {
        const match = imageBase64.match(/^data:([^;]+);base64,(.+)$/);
        if (match) {
          mimeType = match[1];
          imageBase64 = match[2];
        }
      }

      const result = await this.gemini.generateWithVision({
        model: validatedModel,
        systemPrompt: prompt.systemPrompt,
        userPrompt,
        imageBase64,
        mimeType,
        maxTokens: prompt.maxTokens,
        temperature: prompt.temperature,
      });

      const latencyMs = Date.now() - startTime;
      const parsedResponse = this.parseJsonResponse(result.text);

      const response: AiPhotoTagsResponseDto = {
        surveyId: dto.surveyId,
        photoId: dto.photoId,
        promptVersion: prompt.version,
        tags: (parsedResponse.tags as PhotoTagDto[]) ?? [],
        suggestedSection: (parsedResponse.suggestedSection as string) ?? 'unknown',
        description: (parsedResponse.description as string) ?? '',
        fromCache: false,
        disclaimer: AI_DISCLAIMERS.PHOTO_TAGS,
        usage: {
          inputTokens: result.inputTokens,
          outputTokens: result.outputTokens,
        },
      };

      // Cache and log
      const cacheKey = `${featureType}_${dto.photoId}_${prompt.version}_${inputHash}`;

      await this.cache.set({
        cacheKey,
        featureType,
        surveyId: dto.surveyId,
        promptVersion: prompt.version,
        inputHash,
        response,
        inputTokens: result.inputTokens,
        outputTokens: result.outputTokens,
      });

      await this.logUsage(user, featureType, dto.surveyId, prompt.version, result.inputTokens, result.outputTokens, false, latencyMs);

      return response;
    } catch (error) {
      await this.logUsage(user, featureType, dto.surveyId, prompt.version, 0, 0, false, Date.now() - startTime, String(error));
      throw this.handleAiError(error);
    }
  }

  // ============================================
  // Helper Methods
  // ============================================

  /**
   * Call Gemini for recommendations and parse the response.
   * Returns parsed recommendations array plus token usage.
   */
  private async callGeminiForRecommendations(
    model: string,
    prompt: { systemPrompt: string; maxTokens: number; temperature: number; outputSchema?: object },
    userPrompt: string,
  ): Promise<{ recs: RecommendationDto[]; inputTokens: number; outputTokens: number }> {
    const result = await this.gemini.generateContent({
      model,
      systemPrompt: prompt.systemPrompt,
      userPrompt,
      maxTokens: prompt.maxTokens,
      temperature: prompt.temperature,
      responseSchema: prompt.outputSchema,
    });

    const parsedResponse = this.parseJsonResponse(result.text);
    const recs = (parsedResponse.recommendations as RecommendationDto[]) ?? [];
    return { recs, inputTokens: result.inputTokens, outputTokens: result.outputTokens };
  }

  /**
   * Generate deterministic fallback recommendations when AI returns empty.
   * Uses section data to produce rule-based safety, maintenance, and compliance items.
   * This ensures the UI never shows a blank result.
   */
  private generateFallbackRecommendations(
    dto: GenerateRecommendationsDto,
  ): RecommendationDto[] {
    const recs: RecommendationDto[] = [];
    let inferredIdx = 1;

    // Always include core safety/compliance recommendations
    const coreRecs: Array<{ action: string; reasoning: string; priority: string; specialist: string }> = [
      {
        action: 'Commission a full electrical installation condition report (EICR) by a qualified electrician',
        reasoning: 'Electrical safety is critical for all properties. Regular testing ensures compliance with current regulations and identifies potential hazards.',
        priority: 'short_term',
        specialist: 'NICEIC or NAPIT registered electrician',
      },
      {
        action: 'Arrange a Gas Safety inspection by a Gas Safe registered engineer',
        reasoning: 'Annual gas safety checks are a legal requirement for landlords and a best-practice recommendation for all properties to prevent carbon monoxide risks.',
        priority: 'short_term',
        specialist: 'Gas Safe registered engineer',
      },
      {
        action: 'Verify smoke and carbon monoxide detector coverage and test functionality',
        reasoning: 'Working smoke and CO alarms are essential life-safety devices. Current regulations require alarms on every floor.',
        priority: 'immediate',
        specialist: '',
      },
      {
        action: 'Inspect roof covering, flashings, and rainwater goods from ground level and arrange professional roof survey if any concerns noted',
        reasoning: 'Roof defects can lead to water ingress causing significant damage to building fabric if unaddressed.',
        priority: 'medium_term',
        specialist: 'Qualified roofing contractor',
      },
      {
        action: 'Check external walls, pointing, and render for signs of deterioration, cracking, or movement',
        reasoning: 'External envelope condition is fundamental to preventing water ingress and maintaining structural integrity.',
        priority: 'medium_term',
        specialist: 'Building surveyor or structural engineer if cracks observed',
      },
      {
        action: 'Inspect and clear all gutters, downpipes, and drainage runs to ensure free flow',
        reasoning: 'Blocked rainwater goods are a common cause of damp penetration, which can lead to timber decay and structural damage.',
        priority: 'short_term',
        specialist: 'General builder or gutter cleaning specialist',
      },
      {
        action: 'Review heating system age and efficiency, and arrange boiler service',
        reasoning: 'Regular servicing extends equipment life, maintains efficiency, and ensures safe operation. Boilers over 15 years old may benefit from replacement.',
        priority: 'short_term',
        specialist: 'Gas Safe registered heating engineer',
      },
      {
        action: 'Check windows and external doors for draughtproofing, security, and ease of operation',
        reasoning: 'Defective windows and doors affect energy efficiency, security, and weather resistance of the building envelope.',
        priority: 'long_term',
        specialist: 'Window specialist or general builder',
      },
      {
        action: 'Inspect internal areas for signs of dampness, condensation, or mould growth',
        reasoning: 'Dampness can indicate failed damp-proof courses, plumbing leaks, or inadequate ventilation, all requiring investigation.',
        priority: 'medium_term',
        specialist: 'Damp and timber specialist (PCA registered)',
      },
      {
        action: 'Establish a planned preventive maintenance schedule for the property',
        reasoning: 'Proactive maintenance prevents costly reactive repairs and preserves property value over time.',
        priority: 'long_term',
        specialist: '',
      },
    ];

    for (const rec of coreRecs) {
      recs.push({
        issueId: `inferred-${inferredIdx++}`,
        priority: rec.priority,
        action: rec.action,
        reasoning: rec.reasoning,
        specialistReferral: rec.specialist,
        urgencyExplanation: rec.priority === 'immediate'
          ? 'Safety-critical item requiring prompt attention'
          : rec.priority === 'short_term'
            ? 'Should be addressed within 1-3 months to prevent deterioration'
            : rec.priority === 'medium_term'
              ? 'Recommended within 3-12 months as part of ongoing maintenance'
              : 'Long-term maintenance item to schedule within 1-5 years',
      } as RecommendationDto);
    }

    // Add section-specific recommendations based on what sections exist
    const sectionTypes = new Set(
      (dto.sections || []).map(s => (s.sectionType || s.title || '').toLowerCase()),
    );

    if (sectionTypes.has('services') || sectionTypes.has('services & utilities')) {
      recs.push({
        issueId: `inferred-${inferredIdx++}`,
        priority: 'short_term',
        action: 'Check water supply stop-cock location and operation, and inspect visible plumbing for leaks or corrosion',
        reasoning: 'Knowledge of stop-cock location is essential for emergency response. Plumbing deterioration can cause significant water damage.',
        specialistReferral: 'Qualified plumber',
        urgencyExplanation: 'Should be verified within 1-3 months for emergency preparedness',
      } as RecommendationDto);
    }

    if (sectionTypes.has('construction') || sectionTypes.has('about-property') || sectionTypes.has('aboutproperty')) {
      recs.push({
        issueId: `inferred-${inferredIdx++}`,
        priority: 'monitor',
        action: 'Monitor any existing cracks or movement indicators and photograph for future comparison',
        reasoning: 'Tracking changes over time helps distinguish between historic settlement and active structural movement.',
        specialistReferral: 'Structural engineer if movement suspected',
        urgencyExplanation: 'Ongoing monitoring item — review annually',
      } as RecommendationDto);
    }

    return recs;
  }

  /**
   * Get the validated model for a feature type.
   * SINGLE SOURCE OF TRUTH: Always uses AiGeminiService.getModelForType()
   * which returns models validated at startup from env config.
   *
   * This ensures:
   * 1. Models are always from validated registry
   * 2. Database model field is ignored (prevents stale values)
   * 3. All features use consistent, validated models
   */
  private getValidatedModelForFeature(featureType: AiFeatureType): string {
    const modelType = AI_FEATURE_MODEL_TYPE[featureType];
    const model = this.gemini.getModelForType(modelType);
    this.logger.debug(`Feature ${featureType} using validated model: ${model} (type: ${modelType})`);
    return model;
  }

  private async checkAvailabilityAndQuota(user: UserContext): Promise<void> {
    if (!this.gemini.checkAvailability()) {
      throw new ServiceUnavailableException('AI service is not configured');
    }

    // Check organization-level quota
    const orgQuota = await this.getDailyQuota(user.organization || 'default');
    if (orgQuota.tokensUsed >= AI_RATE_LIMITS.ORG_DAILY_TOKENS) {
      throw new ServiceUnavailableException('Organization daily AI quota exceeded');
    }

    // B3 FIX: Check per-user daily quota
    const userQuota = await this.getUserDailyQuota(user.userId);
    if (userQuota.tokensUsed >= AI_RATE_LIMITS.USER_DAILY_TOKENS) {
      throw new ServiceUnavailableException(
        'Your daily AI quota exceeded. Please try again tomorrow or contact an administrator.',
      );
    }
  }

  // B3 FIX: Get per-user daily quota
  private async getUserDailyQuota(userId: string): Promise<{ tokensUsed: number; requestsCount: number }> {
    if (!this.prisma.aiUsageLog) {
      this.logger.warn('aiUsageLog model not available on Prisma client.');
      return { tokensUsed: 0, requestsCount: 0 };
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Aggregate tokens used by this user today
    const result = await this.prisma.aiUsageLog.aggregate({
      where: {
        userId,
        createdAt: { gte: today },
        status: 'success',
        cacheHit: false, // Only count non-cached requests
      },
      _sum: {
        inputTokens: true,
        outputTokens: true,
      },
      _count: true,
    });

    const tokensUsed = (result._sum.inputTokens || 0) + (result._sum.outputTokens || 0);
    return {
      tokensUsed,
      requestsCount: result._count,
    };
  }

  private prepareReportInput(dto: GenerateReportDto): object {
    return {
      propertyAddress: dto.propertyAddress,
      propertyType: dto.propertyType,
      sections: dto.sections.map((s) => ({
        sectionId: s.sectionId,
        sectionType: s.sectionType,
        title: s.title,
        answers: s.answers,
      })),
      issues: dto.issues,
    };
  }

  private hashInput(data: unknown): string {
    const json = JSON.stringify(data, Object.keys(data as object).sort());
    return createHash('sha256').update(json).digest('hex').substring(0, 16);
  }

  private buildPrompt(template: string, variables: Record<string, string | undefined>): string {
    let result = template;

    // Handle conditionals {{#if variable}}...{{/if}}
    const conditionalRegex = /\{\{#if (\w+)\}\}([\s\S]*?)\{\{\/if\}\}/g;
    result = result.replace(conditionalRegex, (_, varName, content) => {
      return variables[varName] ? content : '';
    });

    // Replace variables
    for (const [key, value] of Object.entries(variables)) {
      if (value !== undefined) {
        result = result.replace(new RegExp(`\\{\\{${key}\\}\\}`, 'g'), value);
      }
    }

    return result;
  }

  private parseJsonResponse(text: string): Record<string, unknown> {
    try {
      // Try to extract JSON from markdown code blocks
      const jsonMatch = text.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[1]);
      }

      // Try direct JSON parse
      return JSON.parse(text);
    } catch (error) {
      this.logger.warn(
        `Failed to parse AI response as JSON (length=${text.length}, ` +
        `truncated=${text.length > 100 ? text.substring(text.length - 80) : text}): ${error}`,
      );
      // Return empty object if parsing fails
      return {};
    }
  }

  private async getDailyQuota(organization: string): Promise<{ tokensUsed: number; requestsCount: number }> {
    // Guard: aiDailyQuota model requires Prisma schema + generate.
    // Return zero-usage if the model is not available (prevents 500 crash).
    if (!this.prisma.aiDailyQuota) {
      this.logger.warn(
        'aiDailyQuota model not available on Prisma client. ' +
        'Run "npx prisma generate" to regenerate the client after schema changes.',
      );
      return { tokensUsed: 0, requestsCount: 0 };
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const quota = await this.prisma.aiDailyQuota.findUnique({
      where: {
        organization_date: {
          organization,
          date: today,
        },
      },
    });

    return {
      tokensUsed: quota?.tokensUsed || 0,
      requestsCount: quota?.requestsCount || 0,
    };
  }

  private async logUsage(
    user: UserContext,
    featureType: AiFeatureType,
    surveyId: string,
    promptVersion: string,
    inputTokens: number,
    outputTokens: number,
    cacheHit: boolean,
    latencyMs = 0,
    errorMessage?: string,
  ): Promise<void> {
    // Guard: Skip logging if userId is missing (prevents Prisma validation error)
    if (!user?.userId) {
      this.logger.warn(`Skipping AI usage log - userId is undefined for ${featureType}`);
      return;
    }

    // Guard: Skip if aiUsageLog model is not available on Prisma client
    if (!this.prisma.aiUsageLog) {
      this.logger.warn(`Skipping AI usage log - aiUsageLog model not available for ${featureType}`);
      return;
    }

    try {
      // Log the usage
      await this.prisma.aiUsageLog.create({
        data: {
          userId: user.userId,
          organization: user.organization ?? 'default',
          featureType,
          surveyId,
          promptVersion,
          inputTokens,
          outputTokens,
          latencyMs,
          cacheHit,
          status: errorMessage ? 'error' : 'success',
          errorMessage,
        },
      });

      // Update daily quota (only for non-cached requests)
      if (!cacheHit && !errorMessage) {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const totalTokens = inputTokens + outputTokens;
        const org = user.organization || 'default';

        await this.prisma.aiDailyQuota.upsert({
          where: {
            organization_date: {
              organization: org,
              date: today,
            },
          },
          create: {
            organization: org,
            date: today,
            tokensUsed: totalTokens,
            requestsCount: 1,
          },
          update: {
            tokensUsed: { increment: totalTokens },
            requestsCount: { increment: 1 },
          },
        });
      }
    } catch (error) {
      this.logger.error(`Failed to log AI usage: ${error}`);
    }
  }

  private handleAiError(error: unknown): Error {
    // Handle typed GeminiError
    if (error instanceof GeminiError) {
      this.logger.error({
        message: 'AI error',
        errorType: error.type,
        errorMessage: error.message,
        statusCode: error.statusCode,
        retryable: error.retryable,
      });

      switch (error.type) {
        case GeminiErrorType.MODEL_NOT_FOUND:
          // Configuration error - return 500 (NOT 503) as this is NOT transient
          // 503 implies "retry later" but config errors require deployment fix
          // This should never happen with validated models (defense-in-depth)
          return new InternalServerErrorException(
            'AI service configuration error. This is not a transient issue.',
          );

        case GeminiErrorType.RATE_LIMITED:
          return new ServiceUnavailableException(
            'AI service rate limit exceeded. Please try again later.',
          );

        case GeminiErrorType.SAFETY_BLOCKED:
          return new BadRequestException(
            'AI could not process this request due to content policy.',
          );

        case GeminiErrorType.INVALID_REQUEST:
          return new BadRequestException(
            'Invalid request to AI service. Please check your input.',
          );

        case GeminiErrorType.CIRCUIT_OPEN:
          return new ServiceUnavailableException(
            'AI service temporarily unavailable due to high error rate. Please try again later.',
          );

        case GeminiErrorType.NOT_CONFIGURED:
          // Configuration error - return 500 (NOT 503) as this is NOT transient
          return new InternalServerErrorException(
            'AI service is not configured. Contact administrator.',
          );

        case GeminiErrorType.NETWORK_ERROR:
        case GeminiErrorType.SERVER_ERROR:
        default:
          return new ServiceUnavailableException(
            'AI service temporarily unavailable. Please try again.',
          );
      }
    }

    // Handle non-GeminiError (legacy fallback)
    const message = error instanceof Error ? error.message : String(error);

    if (message.includes('quota') || message.includes('429')) {
      return new ServiceUnavailableException('AI service rate limit exceeded. Please try again later.');
    }

    if (message.includes('safety')) {
      return new BadRequestException('AI could not process this request due to content policy.');
    }

    this.logger.error(`AI error: ${message}`);
    return new ServiceUnavailableException('AI service temporarily unavailable. Please try again.');
  }

  /**
   * Build executive summary from Excel phrase sections
   * Creates a professional summary highlighting key property information
   */
  private buildExecutiveSummaryFromPhrases(
    sectionsWithPhrases: Array<{
      title: string;
      narrative: string;
      usedExcelPhrases: number;
    }>,
  ): string {
    const summaryParts: string[] = [];

    // Add key sections to summary
    for (const section of sectionsWithPhrases) {
      if (section.narrative && section.usedExcelPhrases > 0) {
        // Extract first paragraph or first 200 characters as summary
        const firstParagraph = section.narrative.split('\n\n')[0];
        const excerpt = firstParagraph.length > 200
          ? firstParagraph.substring(0, 200) + '...'
          : firstParagraph;

        if (excerpt) {
          summaryParts.push(excerpt);
        }
      }
    }

    if (summaryParts.length === 0) {
      return '';
    }

    return `**Property Survey Summary**\n\n${summaryParts.join('\n\n')}`;
  }
}
