import { Test, TestingModule } from '@nestjs/testing';
import { ServiceUnavailableException } from '@nestjs/common';

// Mock transitive dependencies that have pre-existing TS errors
jest.mock('./ai-gemini.service', () => ({
  AiGeminiService: jest.fn().mockImplementation(() => ({})),
}));
jest.mock('./ai-cache.service', () => ({
  AiCacheService: jest.fn().mockImplementation(() => ({})),
}));
jest.mock('./ai-prompt.service', () => ({
  AiPromptService: jest.fn().mockImplementation(() => ({})),
}));
jest.mock('../../services/enhanced-report.service', () => ({
  EnhancedReportService: jest.fn().mockImplementation(() => ({})),
}));

import { AiService } from './ai.service';
import { PrismaService } from '../prisma/prisma.service';
import { AiGeminiService } from './ai-gemini.service';
import { AiCacheService } from './ai-cache.service';
import { AiPromptService } from './ai-prompt.service';
import { EnhancedReportService } from '../../services/enhanced-report.service';
import { GenerateRecommendationsDto } from './dto/ai-report.dto';

/**
 * AiService Unit Tests
 *
 * Covers:
 * 1. getDailyQuota - null-safe guard when aiDailyQuota model is unavailable
 * 2. getUserDailyQuota - null-safe guard when aiUsageLog model is unavailable
 * 3. checkAvailabilityAndQuota - availability check, org + user quota enforcement
 * 4. generateRiskSummary - end-to-end through quota check to Gemini call
 */
describe('AiService', () => {
  let service: AiService;

  const mockPrisma = {
    aiDailyQuota: {
      findUnique: jest.fn(),
      upsert: jest.fn().mockResolvedValue({}),
    },
    aiUsageLog: {
      aggregate: jest.fn(),
      create: jest.fn(),
    },
  };

  const mockGemini = {
    checkAvailability: jest.fn(),
    getDetailedStatus: jest.fn(),
    getModelForType: jest.fn(),
    generateContent: jest.fn(),
  };

  const mockCache = {
    generateCacheKey: jest.fn(),
    get: jest.fn(),
    set: jest.fn(),
  };

  const mockPrompts = {
    getPrompt: jest.fn(),
  };

  const mockUser = {
    userId: 'user-123',
    organization: 'test-org',
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AiService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: AiGeminiService, useValue: mockGemini },
        { provide: AiCacheService, useValue: mockCache },
        { provide: AiPromptService, useValue: mockPrompts },
        { provide: EnhancedReportService, useValue: {} },
      ],
    }).compile();

    service = module.get<AiService>(AiService);
  });

  // ============================================================
  // getDailyQuota: null-safe guard
  // ============================================================
  describe('getDailyQuota (via checkAvailabilityAndQuota)', () => {
    it('should return zero usage when aiDailyQuota model is undefined', async () => {
      // Simulate the condition that caused the 500:
      // this.prisma.aiDailyQuota is undefined
      const serviceWithNullModel = createServiceWithPrisma({
        aiDailyQuota: undefined, // <-- THIS is the bug
        aiUsageLog: {
          aggregate: jest.fn().mockResolvedValue({
            _sum: { inputTokens: 0, outputTokens: 0 },
            _count: 0,
          }),
        },
      });

      mockGemini.checkAvailability.mockReturnValue(true);

      // Should NOT throw - the null guard should handle it
      await expect(
        (serviceWithNullModel as any).checkAvailabilityAndQuota(mockUser),
      ).resolves.toBeUndefined();
    });

    it('should return actual quota when aiDailyQuota model exists', async () => {
      mockGemini.checkAvailability.mockReturnValue(true);
      mockPrisma.aiDailyQuota.findUnique.mockResolvedValue({
        tokensUsed: 500,
        requestsCount: 10,
      });
      mockPrisma.aiUsageLog.aggregate.mockResolvedValue({
        _sum: { inputTokens: 100, outputTokens: 50 },
        _count: 5,
      });

      // Should pass without throwing (usage is below limits)
      await expect(
        (service as any).checkAvailabilityAndQuota(mockUser),
      ).resolves.toBeUndefined();

      expect(mockPrisma.aiDailyQuota.findUnique).toHaveBeenCalledTimes(1);
    });

    it('should throw ServiceUnavailableException when AI is not configured', async () => {
      mockGemini.checkAvailability.mockReturnValue(false);

      await expect(
        (service as any).checkAvailabilityAndQuota(mockUser),
      ).rejects.toThrow(ServiceUnavailableException);
    });
  });

  // ============================================================
  // getUserDailyQuota: null-safe guard
  // ============================================================
  describe('getUserDailyQuota', () => {
    it('should return zero usage when aiUsageLog model is undefined', async () => {
      const serviceWithNullModel = createServiceWithPrisma({
        aiDailyQuota: { findUnique: jest.fn().mockResolvedValue(null) },
        aiUsageLog: undefined, // <-- Missing model
      });

      mockGemini.checkAvailability.mockReturnValue(true);

      // Should NOT throw
      await expect(
        (serviceWithNullModel as any).checkAvailabilityAndQuota(mockUser),
      ).resolves.toBeUndefined();
    });
  });

  // ============================================================
  // generateRiskSummary: end-to-end through quota check
  // ============================================================
  describe('generateRiskSummary', () => {
    const riskSummaryDto = {
      surveyId: 'survey-123',
      propertyAddress: '42 Test Lane',
      sections: [
        {
          sectionId: 'section-1',
          sectionType: 'externalCondition',
          title: 'Roof',
          answers: { roof_condition: 'Good' },
        },
      ],
    };

    it('should generate risk summary when quota is available', async () => {
      mockGemini.checkAvailability.mockReturnValue(true);
      mockPrisma.aiDailyQuota.findUnique.mockResolvedValue(null);
      mockPrisma.aiUsageLog.aggregate.mockResolvedValue({
        _sum: { inputTokens: 0, outputTokens: 0 },
        _count: 0,
      });
      mockPrisma.aiUsageLog.create.mockResolvedValue({});
      mockCache.get.mockResolvedValue(null);
      mockCache.generateCacheKey.mockReturnValue('cache-key-123');
      mockCache.set.mockResolvedValue(undefined);
      mockPrompts.getPrompt.mockReturnValue({
        version: 'v1',
        systemPrompt: 'You are a survey expert.',
        userPromptTemplate: 'Analyze: {{sectionsJson}}',
        maxTokens: 4000,
        temperature: 0.3,
        outputSchema: null,
      });
      mockGemini.getModelForType.mockReturnValue('gemini-2.5-pro');
      mockGemini.generateContent.mockResolvedValue({
        text: JSON.stringify({
          overallRiskLevel: 'low',
          summary: 'Property in good condition.',
          keyRisks: [],
          keyPositives: ['Good roof'],
        }),
        inputTokens: 100,
        outputTokens: 50,
      });

      const result = await service.generateRiskSummary(riskSummaryDto, mockUser);

      expect(result.surveyId).toBe('survey-123');
      expect(result.overallRiskLevel).toBe('low');
      expect(result.summary).toBe('Property in good condition.');
      expect(result.fromCache).toBe(false);
      expect(mockGemini.generateContent).toHaveBeenCalledTimes(1);
    });

    it('should return cached response when available', async () => {
      mockGemini.checkAvailability.mockReturnValue(true);
      mockPrisma.aiDailyQuota.findUnique.mockResolvedValue(null);
      mockPrisma.aiUsageLog.aggregate.mockResolvedValue({
        _sum: { inputTokens: 0, outputTokens: 0 },
        _count: 0,
      });
      mockPrisma.aiUsageLog.create.mockResolvedValue({});
      mockPrompts.getPrompt.mockReturnValue({
        version: 'v1',
        systemPrompt: 'test',
        userPromptTemplate: 'test',
        maxTokens: 4000,
        temperature: 0.3,
      });
      mockCache.generateCacheKey.mockReturnValue('cache-key-123');
      mockCache.get.mockResolvedValue({
        response: {
          surveyId: 'survey-123',
          overallRiskLevel: 'low',
          summary: 'Cached result.',
          keyRisks: [],
          keyPositives: [],
        },
        inputTokens: 50,
        outputTokens: 25,
      });

      const result = await service.generateRiskSummary(riskSummaryDto, mockUser);

      expect(result.fromCache).toBe(true);
      expect(result.summary).toBe('Cached result.');
      // Gemini should NOT have been called
      expect(mockGemini.generateContent).not.toHaveBeenCalled();
    });

    it('should throw ServiceUnavailableException when AI is unavailable', async () => {
      mockGemini.checkAvailability.mockReturnValue(false);

      await expect(
        service.generateRiskSummary(riskSummaryDto, mockUser),
      ).rejects.toThrow(ServiceUnavailableException);
    });
  });

  // ============================================================
  // generateRecommendations
  // ============================================================
  describe('generateRecommendations', () => {
    const recommendationsDto: GenerateRecommendationsDto = {
      surveyId: 'survey-456',
      propertyAddress: '10 Repair Road',
      propertyType: 'Semi-detached',
      sections: [
        {
          sectionId: 'section-1',
          sectionType: 'exterior',
          title: 'Exterior',
          answers: { wall_condition: 'Fair', roof_condition: 'Poor' },
        },
        {
          sectionId: 'section-2',
          sectionType: 'services',
          title: 'Services & Utilities',
          answers: { boiler_age: '15 years' },
        },
      ],
      issues: [
        {
          id: 'issue-1',
          title: 'Cracked render on south wall',
          category: 'Exterior',
          severity: 'high',
          location: 'South wall',
          description: 'Visible cracks in render approximately 2m long',
        },
      ],
    };

    const mockPrompt = {
      version: 'v1.2.0',
      systemPrompt: 'You are a property surveyor assistant.',
      userPromptTemplate: 'Property: {{propertyAddress}}\n{{issuesJson}}\n{{sectionsJson}}',
      maxTokens: 8000,
      temperature: 0.3,
      outputSchema: { type: 'object', properties: { recommendations: { type: 'array' } }, required: ['recommendations'] },
    };

    function setupQuotaMocks() {
      mockGemini.checkAvailability.mockReturnValue(true);
      mockPrisma.aiDailyQuota.findUnique.mockResolvedValue(null);
      mockPrisma.aiUsageLog.aggregate.mockResolvedValue({
        _sum: { inputTokens: 0, outputTokens: 0 },
        _count: 0,
      });
      mockPrisma.aiUsageLog.create.mockResolvedValue({});
      mockCache.get.mockResolvedValue(null);
      mockCache.generateCacheKey.mockReturnValue('rec-cache-key');
      mockCache.set.mockResolvedValue(undefined);
      mockPrompts.getPrompt.mockReturnValue(mockPrompt);
      mockGemini.getModelForType.mockReturnValue('gemini-2.5-pro');
    }

    it('should return non-empty recommendations when issues are provided', async () => {
      setupQuotaMocks();
      mockGemini.generateContent.mockResolvedValue({
        text: JSON.stringify({
          recommendations: [
            {
              issueId: 'issue-1',
              priority: 'immediate',
              action: 'Repair cracked render on south wall',
              reasoning: 'Cracked render allows water ingress',
              specialistReferral: 'Qualified renderer',
              urgencyExplanation: 'Prevents further water damage',
            },
            {
              issueId: 'inferred-1',
              priority: 'short_term',
              action: 'Service boiler — unit is 15 years old',
              reasoning: 'Boiler age exceeds typical efficient lifespan',
              specialistReferral: 'Gas Safe registered engineer',
              urgencyExplanation: 'Efficiency and safety concern',
            },
            {
              issueId: 'inferred-2',
              priority: 'medium_term',
              action: 'Commission EICR',
              reasoning: 'No electrical test data in inspection',
              specialistReferral: 'NICEIC registered electrician',
              urgencyExplanation: 'Recommended within 6-12 months',
            },
          ],
        }),
        inputTokens: 800,
        outputTokens: 600,
      });

      const result = await service.generateRecommendations(recommendationsDto, mockUser);

      expect(result.recommendations.length).toBeGreaterThanOrEqual(3);
      expect(result.recommendations[0].action).toContain('Repair cracked render');
      expect(result.surveyId).toBe('survey-456');
      expect(result.fromCache).toBe(false);
      expect(result.disclaimer).toBeTruthy();
    });

    it('should return preventive recommendations when no issues exist', async () => {
      setupQuotaMocks();
      const noIssuesDto = {
        ...recommendationsDto,
        issues: undefined,
      };

      mockGemini.generateContent.mockResolvedValue({
        text: JSON.stringify({
          recommendations: [
            {
              issueId: 'inferred-1',
              priority: 'short_term',
              action: 'Arrange gas safety inspection',
              reasoning: 'Annual gas checks recommended',
              specialistReferral: 'Gas Safe engineer',
              urgencyExplanation: 'Safety compliance',
            },
            {
              issueId: 'inferred-2',
              priority: 'medium_term',
              action: 'Commission EICR',
              reasoning: 'Electrical safety',
              specialistReferral: 'Electrician',
              urgencyExplanation: 'Compliance',
            },
            {
              issueId: 'inferred-3',
              priority: 'long_term',
              action: 'Establish maintenance schedule',
              reasoning: 'Preventive care',
              specialistReferral: '',
              urgencyExplanation: 'Best practice',
            },
          ],
        }),
        inputTokens: 500,
        outputTokens: 400,
      });

      const result = await service.generateRecommendations(noIssuesDto, mockUser);

      expect(result.recommendations.length).toBeGreaterThanOrEqual(3);
      // All should be inferred since no explicit issues
      expect(result.recommendations.every(r => r.issueId.startsWith('inferred'))).toBe(true);
    });

    it('should retry when AI returns fewer than 3 recommendations', async () => {
      setupQuotaMocks();

      // First call: returns only 1 recommendation (too few)
      mockGemini.generateContent
        .mockResolvedValueOnce({
          text: JSON.stringify({
            recommendations: [
              {
                issueId: 'issue-1',
                priority: 'immediate',
                action: 'Fix render',
                reasoning: 'Cracking observed',
                specialistReferral: '',
                urgencyExplanation: 'Urgent',
              },
            ],
          }),
          inputTokens: 800,
          outputTokens: 200,
        })
        // Second call (retry): returns 5 recommendations
        .mockResolvedValueOnce({
          text: JSON.stringify({
            recommendations: [
              { issueId: 'issue-1', priority: 'immediate', action: 'Fix render', reasoning: 'Cracking', specialistReferral: '', urgencyExplanation: 'Urgent' },
              { issueId: 'inferred-1', priority: 'short_term', action: 'Gas check', reasoning: 'Safety', specialistReferral: 'Gas Safe', urgencyExplanation: 'Compliance' },
              { issueId: 'inferred-2', priority: 'short_term', action: 'EICR', reasoning: 'Electrical', specialistReferral: 'Electrician', urgencyExplanation: 'Compliance' },
              { issueId: 'inferred-3', priority: 'medium_term', action: 'Roof survey', reasoning: 'Poor condition', specialistReferral: 'Roofer', urgencyExplanation: 'Prevent damage' },
              { issueId: 'inferred-4', priority: 'long_term', action: 'Maintenance plan', reasoning: 'Best practice', specialistReferral: '', urgencyExplanation: 'Long-term' },
            ],
          }),
          inputTokens: 900,
          outputTokens: 500,
        });

      const result = await service.generateRecommendations(recommendationsDto, mockUser);

      expect(mockGemini.generateContent).toHaveBeenCalledTimes(2);
      expect(result.recommendations.length).toBe(5);
    });

    it('should use deterministic fallback when AI returns empty after retry', async () => {
      setupQuotaMocks();

      // Both calls return empty recommendations
      mockGemini.generateContent.mockResolvedValue({
        text: JSON.stringify({ recommendations: [] }),
        inputTokens: 800,
        outputTokens: 50,
      });

      const result = await service.generateRecommendations(recommendationsDto, mockUser);

      // Should have fallback recommendations (not empty)
      expect(result.recommendations.length).toBeGreaterThanOrEqual(10);
      // First few should be core safety items
      expect(result.recommendations[0].action).toContain('electrical');
      // Fallback recommendations should use inferred IDs
      expect(result.recommendations.every(r => r.issueId.startsWith('inferred'))).toBe(true);
    });

    it('should use deterministic fallback when JSON parsing fails', async () => {
      setupQuotaMocks();

      // AI returns truncated/invalid JSON
      mockGemini.generateContent.mockResolvedValue({
        text: '{"recommendations": [{"issueId": "issue-1", "priority": "imm',
        inputTokens: 800,
        outputTokens: 50,
      });

      const result = await service.generateRecommendations(recommendationsDto, mockUser);

      // Should have fallback recommendations
      expect(result.recommendations.length).toBeGreaterThanOrEqual(10);
    });
  });

  // ============================================================
  // Regression: Risk Summary must remain unchanged
  // ============================================================
  describe('generateRiskSummary - regression guard', () => {
    it('should still use FLASH model for risk summary', async () => {
      mockGemini.checkAvailability.mockReturnValue(true);
      mockPrisma.aiDailyQuota.findUnique.mockResolvedValue(null);
      mockPrisma.aiUsageLog.aggregate.mockResolvedValue({
        _sum: { inputTokens: 0, outputTokens: 0 },
        _count: 0,
      });
      mockPrisma.aiUsageLog.create.mockResolvedValue({});
      mockCache.get.mockResolvedValue(null);
      mockCache.generateCacheKey.mockReturnValue('risk-cache');
      mockCache.set.mockResolvedValue(undefined);
      mockPrompts.getPrompt.mockReturnValue({
        version: 'v1.1.0',
        systemPrompt: 'Risk analyst.',
        userPromptTemplate: '{{sectionsJson}}',
        maxTokens: 8000,
        temperature: 0.3,
        outputSchema: null,
      });
      mockGemini.getModelForType.mockReturnValue('gemini-2.5-flash');
      mockGemini.generateContent.mockResolvedValue({
        text: JSON.stringify({
          overallRiskLevel: 'medium',
          overallRationale: ['Test'],
          summary: 'Test summary.',
          keyRiskDrivers: ['Test driver'],
          keyRisks: [],
          keyPositives: [],
          riskByCategory: [],
          immediateActions: [],
          shortTermActions: [],
          longTermActions: [],
          dataGaps: [],
        }),
        inputTokens: 100,
        outputTokens: 200,
      });

      await service.generateRiskSummary({
        surveyId: 'survey-789',
        propertyAddress: '99 Test St',
        sections: [{ sectionId: 's1', sectionType: 'exterior', title: 'Exterior', answers: {} }],
      }, mockUser);

      // Risk summary should call getModelForType with 'RISK_SUMMARY' feature
      // which maps to FLASH, not PRO
      expect(mockGemini.getModelForType).toHaveBeenCalledWith('FLASH');
    });
  });

  // ============================================================
  // Helper: create service with custom Prisma mock
  // ============================================================
  function createServiceWithPrisma(prismaOverride: Record<string, unknown>): AiService {
    // Create a new service instance with overridden Prisma
    const svc = new AiService(
      prismaOverride as any,
      mockGemini as any,
      mockCache as any,
      mockPrompts as any,
      {} as any, // EnhancedReportService stub
    );
    return svc;
  }
});
