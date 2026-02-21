import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { AiGeminiService, GeminiError, GeminiErrorType } from './ai-gemini.service';
import { MetricsService } from '../metrics/metrics.service';

// Mock global fetch
const mockFetch = jest.fn();
global.fetch = mockFetch;

describe('AiGeminiService', () => {
  let service: AiGeminiService;
  let configService: jest.Mocked<ConfigService>;
  let metricsService: jest.Mocked<MetricsService>;

  const mockConfigService = {
    get: jest.fn(),
  };

  const mockMetricsService = {
    recordAiRequest: jest.fn(),
    recordAiLatency: jest.fn(),
    recordAiFailure: jest.fn(),
    setAiCircuitBreakerState: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    mockFetch.mockReset();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AiGeminiService,
        { provide: ConfigService, useValue: mockConfigService },
        { provide: MetricsService, useValue: mockMetricsService },
      ],
    }).compile();

    service = module.get<AiGeminiService>(AiGeminiService);
    configService = module.get(ConfigService);
    metricsService = module.get(MetricsService);
  });

  describe('initialization', () => {
    it('should mark service as unavailable when API key is not configured', async () => {
      mockConfigService.get.mockReturnValue(undefined);

      await service.onModuleInit();

      expect(service.checkAvailability()).toBe(false);
    });

    it('should use default model names when env vars not set', async () => {
      mockConfigService.get.mockImplementation((key: string) => {
        if (key === 'GEMINI_API_KEY') return 'test-api-key';
        return undefined; // Other config not set
      });

      // Mock successful model listing with new 2.5 models
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          models: [
            { name: 'models/gemini-2.5-pro', supportedGenerationMethods: ['generateContent'] },
            { name: 'models/gemini-2.5-flash', supportedGenerationMethods: ['generateContent'] },
          ],
        }),
      });

      await service.onModuleInit();

      expect(service.getModelForType('PRO')).toBe('gemini-2.5-pro');
      expect(service.getModelForType('FLASH')).toBe('gemini-2.5-flash');
    });

    it('should auto-fallback when primary models are unavailable', async () => {
      mockConfigService.get.mockImplementation((key: string) => {
        if (key === 'GEMINI_API_KEY') return 'test-api-key';
        return undefined;
      });

      // Mock model listing WITHOUT the primary models, but WITH fallback
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          models: [
            { name: 'models/gemini-2.0-flash', supportedGenerationMethods: ['generateContent'] },
            // gemini-2.5-pro and gemini-2.5-flash are NOT available
          ],
        }),
      });

      await service.onModuleInit();

      // Should fallback to gemini-2.0-flash
      expect(service.getModelForType('PRO')).toBe('gemini-2.0-flash');
      expect(service.getModelForType('FLASH')).toBe('gemini-2.0-flash');
      expect(service.checkAvailability()).toBe(true);
    });

    it('should use custom model names from env vars', async () => {
      mockConfigService.get.mockImplementation((key: string) => {
        const config: Record<string, string> = {
          GEMINI_API_KEY: 'test-api-key',
          GEMINI_PRO_MODEL: 'gemini-2.0-pro',
          GEMINI_FLASH_MODEL: 'gemini-2.0-flash',
        };
        return config[key];
      });

      // Mock successful model listing with custom models
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          models: [
            { name: 'models/gemini-2.0-pro', supportedGenerationMethods: ['generateContent'] },
            { name: 'models/gemini-2.0-flash', supportedGenerationMethods: ['generateContent'] },
          ],
        }),
      });

      await service.onModuleInit();

      expect(service.getModelForType('PRO')).toBe('gemini-2.0-pro');
      expect(service.getModelForType('FLASH')).toBe('gemini-2.0-flash');
    });
  });

  describe('generateContent', () => {
    beforeEach(async () => {
      // Initialize service with valid config
      mockConfigService.get.mockImplementation((key: string) => {
        if (key === 'GEMINI_API_KEY') return 'test-api-key';
        return undefined;
      });

      // Mock model validation with new 2.5 models
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          models: [
            { name: 'models/gemini-2.5-pro', supportedGenerationMethods: ['generateContent'] },
            { name: 'models/gemini-2.5-flash', supportedGenerationMethods: ['generateContent'] },
          ],
        }),
      });

      await service.onModuleInit();
      mockFetch.mockReset();
    });

    it('should return parsed response on successful API call', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          candidates: [
            {
              content: {
                parts: [{ text: '{"result": "success"}' }],
              },
              finishReason: 'STOP',
            },
          ],
          usageMetadata: {
            promptTokenCount: 100,
            candidatesTokenCount: 50,
            totalTokenCount: 150,
          },
        }),
      });

      const result = await service.generateContent({
        model: 'gemini-2.5-flash',
        systemPrompt: 'You are a helpful assistant',
        userPrompt: 'Hello',
        maxTokens: 1000,
        temperature: 0.3,
      });

      expect(result.text).toBe('{"result": "success"}');
      expect(result.inputTokens).toBe(100);
      expect(result.outputTokens).toBe(50);
    });

    it('should throw NOT_CONFIGURED error when service is not available', async () => {
      // Create a new service without API key
      mockConfigService.get.mockReturnValue(undefined);
      const uninitializedService = new AiGeminiService(configService, metricsService);
      await uninitializedService.onModuleInit();

      await expect(
        uninitializedService.generateContent({
          model: 'gemini-2.5-flash',
          systemPrompt: 'test',
          userPrompt: 'test',
          maxTokens: 100,
          temperature: 0.3,
        }),
      ).rejects.toThrow(GeminiError);
    });

    it('should record metrics on successful request', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          candidates: [
            {
              content: { parts: [{ text: 'response' }] },
              finishReason: 'STOP',
            },
          ],
          usageMetadata: { promptTokenCount: 10, candidatesTokenCount: 5 },
        }),
      });

      await service.generateContent({
        model: 'gemini-2.5-flash',
        systemPrompt: 'test',
        userPrompt: 'test',
        maxTokens: 100,
        temperature: 0.3,
      });

      expect(mockMetricsService.recordAiRequest).toHaveBeenCalledWith(
        'generateContent',
        'gemini-2.5-flash',
        'success',
      );
      // Note: recordAiLatency may not be called if latency is 0 (fast tests)
    });
  });

  describe('error handling', () => {
    beforeEach(async () => {
      mockConfigService.get.mockImplementation((key: string) => {
        if (key === 'GEMINI_API_KEY') return 'test-api-key';
        return undefined;
      });

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          models: [
            { name: 'models/gemini-2.5-flash', supportedGenerationMethods: ['generateContent'] },
          ],
        }),
      });

      await service.onModuleInit();
      mockFetch.mockReset();
    });

    it('should classify 404 as MODEL_NOT_FOUND', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 404,
        text: async () => 'Model not found',
      });

      await expect(
        service.generateContent({
          model: 'invalid-model',
          systemPrompt: 'test',
          userPrompt: 'test',
          maxTokens: 100,
          temperature: 0.3,
        }),
      ).rejects.toMatchObject({
        type: GeminiErrorType.MODEL_NOT_FOUND,
        retryable: false,
      });
    });

    it('should classify 429 as RATE_LIMITED and mark as retryable', async () => {
      // Will fail all retries
      mockFetch.mockResolvedValue({
        ok: false,
        status: 429,
        text: async () => 'Rate limit exceeded',
      });

      await expect(
        service.generateContent({
          model: 'gemini-2.5-flash',
          systemPrompt: 'test',
          userPrompt: 'test',
          maxTokens: 100,
          temperature: 0.3,
        }),
      ).rejects.toMatchObject({
        type: GeminiErrorType.RATE_LIMITED,
        retryable: true,
      });
    });

    it('should classify 400 as INVALID_REQUEST', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 400,
        text: async () => 'Invalid request',
      });

      await expect(
        service.generateContent({
          model: 'gemini-2.5-flash',
          systemPrompt: 'test',
          userPrompt: 'test',
          maxTokens: 100,
          temperature: 0.3,
        }),
      ).rejects.toMatchObject({
        type: GeminiErrorType.INVALID_REQUEST,
        retryable: false,
      });
    });

    it('should classify 500+ as SERVER_ERROR and retry', async () => {
      mockFetch.mockResolvedValue({
        ok: false,
        status: 503,
        text: async () => 'Service unavailable',
      });

      await expect(
        service.generateContent({
          model: 'gemini-2.5-flash',
          systemPrompt: 'test',
          userPrompt: 'test',
          maxTokens: 100,
          temperature: 0.3,
        }),
      ).rejects.toMatchObject({
        type: GeminiErrorType.SERVER_ERROR,
        retryable: true,
      });

      // Should have retried multiple times
      expect(mockFetch).toHaveBeenCalledTimes(3); // maxRetries from config
    });

    it('should handle SAFETY blocked responses', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          candidates: [
            {
              content: { parts: [{ text: '' }] },
              finishReason: 'SAFETY',
            },
          ],
        }),
      });

      await expect(
        service.generateContent({
          model: 'gemini-2.5-flash',
          systemPrompt: 'test',
          userPrompt: 'test',
          maxTokens: 100,
          temperature: 0.3,
        }),
      ).rejects.toMatchObject({
        type: GeminiErrorType.SAFETY_BLOCKED,
      });
    });
  });

  describe('circuit breaker', () => {
    beforeEach(async () => {
      mockConfigService.get.mockImplementation((key: string) => {
        if (key === 'GEMINI_API_KEY') return 'test-api-key';
        return undefined;
      });

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          models: [
            { name: 'models/gemini-2.5-flash', supportedGenerationMethods: ['generateContent'] },
          ],
        }),
      });

      await service.onModuleInit();
      mockFetch.mockReset();
    });

    it('should track circuit breaker state', () => {
      const status = service.getCircuitStatus();

      expect(status.state).toBe('CLOSED');
      expect(status.failures).toBe(0);
    });

    it('should open circuit after threshold failures', async () => {
      // Configure to always fail with non-retryable error to avoid retry delays
      mockFetch.mockResolvedValue({
        ok: false,
        status: 400,
        text: async () => 'Bad request',
      });

      // Trigger multiple failures to open the circuit
      // Each call = 1 failure (no retries for 400 errors)
      for (let i = 0; i < 6; i++) {
        try {
          await service.generateContent({
            model: 'gemini-2.5-flash',
            systemPrompt: 'test',
            userPrompt: 'test',
            maxTokens: 100,
            temperature: 0.3,
          });
        } catch {
          // Expected
        }
      }

      const status = service.getCircuitStatus();
      expect(status.state).toBe('OPEN');
    }, 10000);

    it('should reject requests when circuit is open', async () => {
      // Force circuit open by setting failures with non-retryable error
      mockFetch.mockResolvedValue({
        ok: false,
        status: 400,
        text: async () => 'Bad request',
      });

      // Open the circuit - need 5+ failures
      for (let i = 0; i < 6; i++) {
        try {
          await service.generateContent({
            model: 'gemini-2.5-flash',
            systemPrompt: 'test',
            userPrompt: 'test',
            maxTokens: 100,
            temperature: 0.3,
          });
        } catch {
          // Expected
        }
      }

      // Reset mock to track new calls
      mockFetch.mockReset();

      // This should fail immediately without calling fetch
      await expect(
        service.generateContent({
          model: 'gemini-2.5-flash',
          systemPrompt: 'test',
          userPrompt: 'test',
          maxTokens: 100,
          temperature: 0.3,
        }),
      ).rejects.toMatchObject({
        type: GeminiErrorType.CIRCUIT_OPEN,
      });

      // Verify fetch was not called (circuit rejected it)
      expect(mockFetch).not.toHaveBeenCalled();
    }, 10000);
  });

  describe('model validation', () => {
    it('should validate models at startup', async () => {
      mockConfigService.get.mockImplementation((key: string) => {
        if (key === 'GEMINI_API_KEY') return 'test-api-key';
        return undefined;
      });

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          models: [
            { name: 'models/gemini-2.5-pro', supportedGenerationMethods: ['generateContent'] },
            { name: 'models/gemini-2.5-flash', supportedGenerationMethods: ['generateContent'] },
          ],
        }),
      });

      await service.onModuleInit();

      expect(service.isModelValidated('gemini-2.5-pro')).toBe(true);
      expect(service.isModelValidated('gemini-2.5-flash')).toBe(true);
      expect(service.isModelValidated('invalid-model')).toBe(false);
    });

    it('should fail closed when model validation fails (security: prevent unvalidated runtime)', async () => {
      mockConfigService.get.mockImplementation((key: string) => {
        if (key === 'GEMINI_API_KEY') return 'test-api-key';
        return undefined;
      });

      // Model listing fails
      mockFetch.mockRejectedValueOnce(new Error('Network error'));

      await service.onModuleInit();

      // FAIL CLOSED: Service must NOT be available if models cannot be validated.
      // This prevents unpredictable runtime failures with unvalidated models.
      expect(service.checkAvailability()).toBe(false);
    });

    it('should return detailed status for monitoring', async () => {
      mockConfigService.get.mockImplementation((key: string) => {
        if (key === 'GEMINI_API_KEY') return 'test-api-key';
        return undefined;
      });

      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          models: [
            { name: 'models/gemini-2.5-pro', supportedGenerationMethods: ['generateContent'] },
            { name: 'models/gemini-2.5-flash', supportedGenerationMethods: ['generateContent'] },
          ],
        }),
      });

      await service.onModuleInit();

      const status = service.getDetailedStatus();

      expect(status.enabled).toBe(true);
      expect(status.selectedProModel).toBe('gemini-2.5-pro');
      expect(status.selectedFlashModel).toBe('gemini-2.5-flash');
      expect(status.circuitBreakerState).toBe('CLOSED');
      expect(status.lastValidationTime).toBeDefined();
      expect(status.validationError).toBeNull();
      expect(status.availableModels).toContain('gemini-2.5-pro');
    });

    it('should mark service unavailable when no valid models found', async () => {
      mockConfigService.get.mockImplementation((key: string) => {
        if (key === 'GEMINI_API_KEY') return 'test-api-key';
        return undefined;
      });

      // Mock model listing with NO compatible models
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          models: [
            { name: 'models/some-other-model', supportedGenerationMethods: ['embedContent'] },
          ],
        }),
      });

      await service.onModuleInit();

      expect(service.checkAvailability()).toBe(false);
      const status = service.getDetailedStatus();
      expect(status.enabled).toBe(false);
      expect(status.validationError).toBe('No valid Gemini models found');
    });
  });

  describe('strict runtime guard', () => {
    /**
     * These tests verify the STRICT RUNTIME GUARD that blocks unvalidated models.
     * This is a critical security/reliability feature that ensures only validated
     * models can be used, preventing MODEL_NOT_FOUND errors at runtime.
     */

    beforeEach(async () => {
      mockConfigService.get.mockImplementation((key: string) => {
        if (key === 'GEMINI_API_KEY') return 'test-api-key';
        return undefined;
      });

      // Initialize with specific validated models
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          models: [
            { name: 'models/gemini-2.5-flash', supportedGenerationMethods: ['generateContent'] },
            // Note: gemini-2.5-pro is NOT in this list
          ],
        }),
      });

      await service.onModuleInit();
      mockFetch.mockReset();
    });

    it('should BLOCK requests using unvalidated models (runtime guard)', async () => {
      // Try to use gemini-2.5-pro which was NOT validated (not in the mock list above)
      // This simulates the scenario where database has stale model names

      await expect(
        service.generateContent({
          model: 'gemini-2.5-pro', // This was NOT validated at startup
          systemPrompt: 'test',
          userPrompt: 'test',
          maxTokens: 100,
          temperature: 0.3,
        }),
      ).rejects.toMatchObject({
        type: GeminiErrorType.MODEL_NOT_FOUND,
        statusCode: 503, // Should return 503, not 500
        retryable: false,
      });

      // CRITICAL: Verify the API was NEVER called (guard blocked it)
      expect(mockFetch).not.toHaveBeenCalled();
    });

    it('should ALLOW requests using validated models', async () => {
      // Use gemini-2.5-flash which WAS validated
      mockFetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          candidates: [
            {
              content: { parts: [{ text: 'response' }] },
              finishReason: 'STOP',
            },
          ],
          usageMetadata: { promptTokenCount: 10, candidatesTokenCount: 5 },
        }),
      });

      const result = await service.generateContent({
        model: 'gemini-2.5-flash', // This WAS validated at startup
        systemPrompt: 'test',
        userPrompt: 'test',
        maxTokens: 100,
        temperature: 0.3,
      });

      expect(result.text).toBe('response');
      expect(mockFetch).toHaveBeenCalledTimes(1);
    });

    it('should BLOCK stale legacy model names (gemini-1.5-flash)', async () => {
      // This tests the specific scenario from the bug report:
      // database had gemini-1.5-flash but API only supports 2.5 models

      await expect(
        service.generateContent({
          model: 'gemini-1.5-flash', // Legacy model NOT in validated list
          systemPrompt: 'test',
          userPrompt: 'test',
          maxTokens: 100,
          temperature: 0.3,
        }),
      ).rejects.toMatchObject({
        type: GeminiErrorType.MODEL_NOT_FOUND,
        statusCode: 503,
      });

      // Guard blocked before API call
      expect(mockFetch).not.toHaveBeenCalled();
    });

    it('should BLOCK generateWithVision for unvalidated models', async () => {
      await expect(
        service.generateWithVision({
          model: 'gemini-1.5-pro', // NOT validated
          systemPrompt: 'test',
          userPrompt: 'test',
          imageBase64: 'dGVzdA==',
          maxTokens: 100,
          temperature: 0.3,
        }),
      ).rejects.toMatchObject({
        type: GeminiErrorType.MODEL_NOT_FOUND,
        statusCode: 503,
      });

      expect(mockFetch).not.toHaveBeenCalled();
    });
  });
});
