import { Test, TestingModule } from '@nestjs/testing';
import { Reflector } from '@nestjs/core';
import { ROLES_KEY } from '../auth/decorators/roles.decorator';

/**
 * AiController Tests
 *
 * Tests the GET /ai/status endpoint behavior and route metadata.
 * Uses manual mocking to avoid importing AiService which has
 * pre-existing TS errors due to missing Prisma AI models.
 */

// Mock the entire AiService module to avoid transitive TS errors
jest.mock('./ai.service', () => ({
  AiService: jest.fn().mockImplementation(() => ({
    getPublicStatus: jest.fn(),
    getStatus: jest.fn(),
    generateReport: jest.fn(),
    generateRecommendations: jest.fn(),
    generateRiskSummary: jest.fn(),
    checkConsistency: jest.fn(),
    generatePhotoTags: jest.fn(),
  })),
}));

// Must import AFTER jest.mock
import { AiController } from './ai.controller';
import { AiService } from './ai.service';

describe('AiController', () => {
  let controller: AiController;
  let aiService: AiService;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [AiController],
      providers: [
        {
          provide: AiService,
          useFactory: () => ({
            getPublicStatus: jest.fn(),
            getStatus: jest.fn(),
            generateReport: jest.fn(),
            generateRecommendations: jest.fn(),
            generateRiskSummary: jest.fn(),
            checkConsistency: jest.fn(),
            generatePhotoTags: jest.fn(),
          }),
        },
      ],
    }).compile();

    controller = module.get<AiController>(AiController);
    aiService = module.get<AiService>(AiService);
  });

  describe('GET /ai/status', () => {
    it('should return available status when AI is configured', async () => {
      const expected = {
        available: true,
        selectedProModel: 'gemini-2.5-pro',
        selectedFlashModel: 'gemini-2.5-flash',
        circuitBreakerState: 'closed',
        availableModels: ['gemini-2.5-pro', 'gemini-2.5-flash'],
      };

      (aiService.getPublicStatus as jest.Mock).mockResolvedValue(expected);

      const result = await controller.getStatus();

      expect(result).toEqual(expected);
      expect(result.available).toBe(true);
      expect(aiService.getPublicStatus).toHaveBeenCalledTimes(1);
    });

    it('should return unavailable status when AI is not configured', async () => {
      const expected = {
        available: false,
        message: 'AI service is not configured',
        circuitBreakerState: 'closed',
        availableModels: [],
      };

      (aiService.getPublicStatus as jest.Mock).mockResolvedValue(expected);

      const result = await controller.getStatus();

      expect(result).toEqual(expected);
      expect(result.available).toBe(false);
      expect(result.message).toBe('AI service is not configured');
    });

    it('should return unavailable status when API key is missing', async () => {
      const expected = {
        available: false,
        message: 'GEMINI_API_KEY not set',
        circuitBreakerState: 'closed',
        availableModels: [],
      };

      (aiService.getPublicStatus as jest.Mock).mockResolvedValue(expected);

      const result = await controller.getStatus();

      expect(result.available).toBe(false);
      expect(result.message).toContain('not set');
    });

    it('should be a public endpoint (no auth required)', () => {
      const metadata = Reflect.getMetadata('isPublic', AiController.prototype.getStatus);
      expect(metadata).toBe(true);
    });

    it('should not have any @Roles restriction', () => {
      const roles = Reflect.getMetadata(ROLES_KEY, AiController.prototype.getStatus);
      expect(roles).toBeUndefined();
    });
  });
});
