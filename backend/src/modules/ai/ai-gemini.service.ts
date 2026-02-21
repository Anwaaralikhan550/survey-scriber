import { Injectable, Logger, OnModuleInit, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { RETRY_CONFIG, AI_MODELS_DEFAULT, AI_MODELS_FALLBACK } from './ai.constants';
import { MetricsService } from '../metrics/metrics.service';

/**
 * Gemini API response structure
 */
interface GeminiResponse {
  candidates: Array<{
    content: {
      parts: Array<{ text: string }>;
    };
    finishReason: string;
  }>;
  usageMetadata?: {
    promptTokenCount: number;
    candidatesTokenCount: number;
    totalTokenCount: number;
  };
}

interface ListModelsResponse {
  models: Array<{
    name: string;
    supportedGenerationMethods: string[];
  }>;
}

interface GenerateContentParams {
  model: string;
  systemPrompt: string;
  userPrompt: string;
  maxTokens: number;
  temperature: number;
  responseSchema?: object;
}

interface GeminiResult {
  text: string;
  inputTokens: number;
  outputTokens: number;
}

/**
 * Error types for better handling
 */
export enum GeminiErrorType {
  MODEL_NOT_FOUND = 'MODEL_NOT_FOUND',
  RATE_LIMITED = 'RATE_LIMITED',
  SAFETY_BLOCKED = 'SAFETY_BLOCKED',
  INVALID_REQUEST = 'INVALID_REQUEST',
  SERVER_ERROR = 'SERVER_ERROR',
  NETWORK_ERROR = 'NETWORK_ERROR',
  CIRCUIT_OPEN = 'CIRCUIT_OPEN',
  NOT_CONFIGURED = 'NOT_CONFIGURED',
}

export class GeminiError extends Error {
  constructor(
    public readonly type: GeminiErrorType,
    message: string,
    public readonly statusCode?: number,
    public readonly retryable: boolean = false,
  ) {
    super(message);
    this.name = 'GeminiError';
  }
}

/**
 * Circuit breaker state
 */
interface CircuitState {
  failures: number;
  lastFailure: number;
  state: 'CLOSED' | 'OPEN' | 'HALF_OPEN';
}

/**
 * Detailed status for health/monitoring endpoints
 */
export interface GeminiServiceStatus {
  enabled: boolean;
  selectedProModel: string | null;
  selectedFlashModel: string | null;
  fallbackProModel: string | null;
  fallbackFlashModel: string | null;
  lastValidationTime: string | null;
  validationError: string | null;
  circuitBreakerState: string;
  availableModels: string[];
}

@Injectable()
export class AiGeminiService implements OnModuleInit {
  private readonly logger = new Logger(AiGeminiService.name);
  private apiKey: string = '';
  private baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  private isAvailable = false;
  private validatedModels: Set<string> = new Set();
  private availableModelsList: string[] = [];

  // Model configuration (loaded from env)
  private proModel: string = AI_MODELS_DEFAULT.PRO;
  private flashModel: string = AI_MODELS_DEFAULT.FLASH;

  // Fallback models (used if primary models not available)
  private proFallback: string | null = null;
  private flashFallback: string | null = null;

  // Validation tracking
  private lastValidationTime: Date | null = null;
  private validationError: string | null = null;

  // Circuit breaker configuration
  private readonly circuitBreaker: CircuitState = {
    failures: 0,
    lastFailure: 0,
    state: 'CLOSED',
  };
  private readonly CIRCUIT_FAILURE_THRESHOLD = 5;
  private readonly CIRCUIT_RESET_TIMEOUT_MS = 60000; // 1 minute

  // Request timeout — Gemini PRO (report/recommendations) routinely takes
  // 30-90s for complex surveys. 120s allows headroom for retries.
  private readonly REQUEST_TIMEOUT_MS = 120000; // 120 seconds

  constructor(
    private readonly configService: ConfigService,
    @Optional() private readonly metricsService?: MetricsService,
  ) {}

  async onModuleInit() {
    this.apiKey = this.configService.get<string>('GEMINI_API_KEY') || '';

    if (!this.apiKey) {
      this.logger.warn('GEMINI_API_KEY not configured - AI features disabled');
      this.isAvailable = false;
      return;
    }

    // Load model names from config with defaults
    this.proModel = this.configService.get<string>('GEMINI_PRO_MODEL') || AI_MODELS_DEFAULT.PRO;
    this.flashModel = this.configService.get<string>('GEMINI_FLASH_MODEL') || AI_MODELS_DEFAULT.FLASH;

    this.logger.log(`Initializing Gemini AI service with models: PRO=${this.proModel}, FLASH=${this.flashModel}`);

    // Validate models exist by calling ListModels API
    await this.validateModelsAtStartup();
  }

  /**
   * Validate configured models exist by calling ListModels API.
   * Implements auto-fallback: if primary model unavailable, tries fallback.
   */
  private async validateModelsAtStartup(): Promise<void> {
    this.lastValidationTime = new Date();
    this.validationError = null;

    try {
      const availableModels = await this.listAvailableModels();

      // Store available models list for status endpoint
      this.availableModelsList = availableModels
        .filter(m => m.supportedGenerationMethods.includes('generateContent'))
        .map(m => m.name.replace('models/', ''));

      this.logger.log(`Available Gemini models: ${this.availableModelsList.slice(0, 15).join(', ')}`);

      // Helper to check if model is available
      const isModelAvailable = (modelName: string): boolean =>
        availableModels.some(
          m => m.name.includes(modelName) && m.supportedGenerationMethods.includes('generateContent'),
        );

      // Validate PRO model with fallback
      let proModelValid = isModelAvailable(this.proModel);
      if (!proModelValid) {
        this.logger.warn(`PRO model "${this.proModel}" not found, trying fallback "${AI_MODELS_FALLBACK.PRO}"`);
        if (isModelAvailable(AI_MODELS_FALLBACK.PRO)) {
          this.proFallback = AI_MODELS_FALLBACK.PRO;
          this.proModel = AI_MODELS_FALLBACK.PRO;
          proModelValid = true;
          this.logger.log(`Using fallback PRO model: ${this.proModel}`);
        } else {
          this.logger.error(`PRO fallback "${AI_MODELS_FALLBACK.PRO}" also not found`);
        }
      }

      // Validate FLASH model with fallback
      let flashModelValid = isModelAvailable(this.flashModel);
      if (!flashModelValid) {
        this.logger.warn(`FLASH model "${this.flashModel}" not found, trying fallback "${AI_MODELS_FALLBACK.FLASH}"`);
        if (isModelAvailable(AI_MODELS_FALLBACK.FLASH)) {
          this.flashFallback = AI_MODELS_FALLBACK.FLASH;
          this.flashModel = AI_MODELS_FALLBACK.FLASH;
          flashModelValid = true;
          this.logger.log(`Using fallback FLASH model: ${this.flashModel}`);
        } else {
          this.logger.error(`FLASH fallback "${AI_MODELS_FALLBACK.FLASH}" also not found`);
        }
      }

      // Add validated models to set
      if (proModelValid) {
        this.validatedModels.add(this.proModel);
        this.logger.log(`PRO model "${this.proModel}" validated successfully`);
      }
      if (flashModelValid) {
        this.validatedModels.add(this.flashModel);
        this.logger.log(`FLASH model "${this.flashModel}" validated successfully`);
      }

      // Service is available if at least one model is valid
      this.isAvailable = proModelValid || flashModelValid;

      if (!this.isAvailable) {
        this.validationError = 'No valid Gemini models found';
        this.logger.error('No valid Gemini models found - AI features disabled');
        this.logger.error(`Configured: PRO=${AI_MODELS_DEFAULT.PRO}, FLASH=${AI_MODELS_DEFAULT.FLASH}`);
        this.logger.error(`Available models: ${this.availableModelsList.slice(0, 10).join(', ')}`);
      } else {
        this.logger.log(`Gemini AI service initialized successfully (PRO=${this.proModel}, FLASH=${this.flashModel})`);
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      this.validationError = errorMsg;
      this.logger.error(`Failed to validate models at startup: ${errorMsg}`);
      // FAIL CLOSED: Do not mark as available if we cannot validate models
      // Industry standard: fail closed on validation errors to prevent unpredictable runtime failures
      this.isAvailable = false;
      this.logger.error('AI service disabled - failed to validate models at startup');
    }
  }

  /**
   * List available models from Gemini API
   */
  async listAvailableModels(): Promise<Array<{ name: string; supportedGenerationMethods: string[] }>> {
    const url = `${this.baseUrl}/models?key=${this.apiKey}`;

    try {
      const response = await fetch(url, {
        method: 'GET',
        headers: { 'Content-Type': 'application/json' },
        signal: AbortSignal.timeout(10000), // 10 second timeout for list
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Failed to list models: ${response.status} ${errorText}`);
      }

      const data: ListModelsResponse = await response.json();
      return data.models || [];
    } catch (error) {
      this.logger.error(`Failed to list Gemini models: ${error}`);
      throw error;
    }
  }

  /**
   * Get the configured model name for a feature type
   */
  getModelForType(type: 'PRO' | 'FLASH'): string {
    return type === 'PRO' ? this.proModel : this.flashModel;
  }

  /**
   * Check if Gemini service is available
   */
  checkAvailability(): boolean {
    return this.isAvailable;
  }

  /**
   * Check if a specific model is validated
   */
  isModelValidated(model: string): boolean {
    return this.validatedModels.has(model);
  }

  /**
   * Get detailed service status for monitoring/health endpoints
   */
  getDetailedStatus(): GeminiServiceStatus {
    return {
      enabled: this.isAvailable,
      selectedProModel: this.isAvailable ? this.proModel : null,
      selectedFlashModel: this.isAvailable ? this.flashModel : null,
      fallbackProModel: this.proFallback,
      fallbackFlashModel: this.flashFallback,
      lastValidationTime: this.lastValidationTime?.toISOString() || null,
      validationError: this.validationError,
      circuitBreakerState: this.circuitBreaker.state,
      availableModels: this.availableModelsList.slice(0, 20), // Limit to first 20
    };
  }

  /**
   * Generate content using Gemini API
   */
  async generateContent(params: GenerateContentParams): Promise<GeminiResult> {
    const startTime = Date.now();
    const { model } = params;

    // Check availability
    if (!this.isAvailable) {
      this.recordMetrics('generateContent', model, 0, 'error', GeminiErrorType.NOT_CONFIGURED);
      throw new GeminiError(GeminiErrorType.NOT_CONFIGURED, 'Gemini API not configured', undefined, false);
    }

    // Check circuit breaker
    if (this.isCircuitOpen()) {
      this.recordMetrics('generateContent', model, 0, 'error', GeminiErrorType.CIRCUIT_OPEN);
      throw new GeminiError(
        GeminiErrorType.CIRCUIT_OPEN,
        'AI service temporarily unavailable due to repeated failures. Please try again later.',
        503,
        false,
      );
    }

    // STRICT RUNTIME GUARD: Block ALL unvalidated models
    // This is a defense-in-depth measure to ensure only validated models are used
    if (!this.validatedModels.has(model)) {
      this.logger.error(`BLOCKED: Attempted to use unvalidated model "${model}". Validated models: [${Array.from(this.validatedModels).join(', ')}]`);
      this.recordMetrics('generateContent', model, 0, 'error', GeminiErrorType.MODEL_NOT_FOUND);
      throw new GeminiError(
        GeminiErrorType.MODEL_NOT_FOUND,
        `Model "${model}" is not in the validated registry. This is a configuration error. Available models: ${this.proModel}, ${this.flashModel}`,
        503,
        false,
      );
    }

    this.logger.debug(`Using validated model: ${model}`);

    const url = `${this.baseUrl}/models/${model}:generateContent?key=${this.apiKey}`;

    const requestBody = {
      contents: [
        {
          role: 'user',
          parts: [{ text: params.userPrompt }],
        },
      ],
      systemInstruction: {
        parts: [{ text: params.systemPrompt }],
      },
      generationConfig: {
        maxOutputTokens: params.maxTokens,
        temperature: params.temperature,
        topP: 0.95,
        topK: 40,
        ...(params.responseSchema && {
          responseMimeType: 'application/json',
          responseSchema: params.responseSchema,
        }),
      },
      safetySettings: [
        { category: 'HARM_CATEGORY_HARASSMENT', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
        { category: 'HARM_CATEGORY_HATE_SPEECH', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
        { category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
        { category: 'HARM_CATEGORY_DANGEROUS_CONTENT', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
      ],
    };

    try {
      const result = await this.executeWithRetry(url, requestBody, model);
      const latency = Date.now() - startTime;

      // Success - reset circuit breaker
      this.resetCircuit();
      this.recordMetrics('generateContent', model, latency, 'success');

      this.logger.log({
        message: 'Gemini API call successful',
        model,
        latencyMs: latency,
        inputTokens: result.inputTokens,
        outputTokens: result.outputTokens,
      });

      return result;
    } catch (error) {
      const latency = Date.now() - startTime;
      const geminiError = error instanceof GeminiError ? error : this.wrapError(error);

      this.recordMetrics('generateContent', model, latency, 'error', geminiError.type);

      this.logger.error({
        message: 'Gemini API call failed',
        model,
        latencyMs: latency,
        errorType: geminiError.type,
        error: geminiError.message,
      });

      throw geminiError;
    }
  }

  /**
   * Generate content with vision (for photo analysis)
   */
  async generateWithVision(params: {
    model: string;
    systemPrompt: string;
    userPrompt: string;
    imageBase64: string;
    mimeType?: string;
    maxTokens: number;
    temperature: number;
  }): Promise<GeminiResult> {
    const startTime = Date.now();
    const { model } = params;

    if (!this.isAvailable) {
      throw new GeminiError(GeminiErrorType.NOT_CONFIGURED, 'Gemini API not configured', undefined, false);
    }

    if (this.isCircuitOpen()) {
      throw new GeminiError(
        GeminiErrorType.CIRCUIT_OPEN,
        'AI service temporarily unavailable due to repeated failures.',
        503,
        false,
      );
    }

    // STRICT RUNTIME GUARD: Block ALL unvalidated models (same as generateContent)
    if (!this.validatedModels.has(model)) {
      this.logger.error(`BLOCKED (vision): Attempted to use unvalidated model "${model}". Validated models: [${Array.from(this.validatedModels).join(', ')}]`);
      throw new GeminiError(
        GeminiErrorType.MODEL_NOT_FOUND,
        `Model "${model}" is not in the validated registry. Available models: ${this.proModel}, ${this.flashModel}`,
        503,
        false,
      );
    }

    this.logger.debug(`Using validated model for vision: ${model}`);

    const url = `${this.baseUrl}/models/${model}:generateContent?key=${this.apiKey}`;

    const requestBody = {
      contents: [
        {
          role: 'user',
          parts: [
            { text: params.userPrompt },
            {
              inlineData: {
                mimeType: params.mimeType || 'image/jpeg',
                data: params.imageBase64,
              },
            },
          ],
        },
      ],
      systemInstruction: {
        parts: [{ text: params.systemPrompt }],
      },
      generationConfig: {
        maxOutputTokens: params.maxTokens,
        temperature: params.temperature,
        topP: 0.95,
        topK: 40,
      },
      safetySettings: [
        { category: 'HARM_CATEGORY_HARASSMENT', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
        { category: 'HARM_CATEGORY_HATE_SPEECH', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
        { category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
        { category: 'HARM_CATEGORY_DANGEROUS_CONTENT', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
      ],
    };

    try {
      const result = await this.executeWithRetry(url, requestBody, model);
      const latency = Date.now() - startTime;

      this.resetCircuit();
      this.recordMetrics('generateWithVision', model, latency, 'success');

      return result;
    } catch (error) {
      const latency = Date.now() - startTime;
      const geminiError = error instanceof GeminiError ? error : this.wrapError(error);

      this.recordMetrics('generateWithVision', model, latency, 'error', geminiError.type);
      throw geminiError;
    }
  }

  /**
   * Execute request with retry logic
   */
  private async executeWithRetry(url: string, body: unknown, model: string): Promise<GeminiResult> {
    let lastError: GeminiError | null = null;
    let delay = RETRY_CONFIG.baseDelayMs;

    for (let attempt = 1; attempt <= RETRY_CONFIG.maxRetries; attempt++) {
      try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), this.REQUEST_TIMEOUT_MS);

        const response = await fetch(url, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(body),
          signal: controller.signal,
        });

        clearTimeout(timeoutId);

        if (!response.ok) {
          const errorText = await response.text();
          const status = response.status;
          const geminiError = this.parseApiError(status, errorText);

          // Record failure for circuit breaker
          this.recordFailure();

          // Check if retryable
          if (geminiError.retryable && attempt < RETRY_CONFIG.maxRetries) {
            this.logger.warn({
              message: `Gemini API error, retrying`,
              attempt,
              maxRetries: RETRY_CONFIG.maxRetries,
              status,
              model,
              errorType: geminiError.type,
            });
            lastError = geminiError;
            await this.sleep(delay);
            delay = Math.min(delay * RETRY_CONFIG.exponentialBase, RETRY_CONFIG.maxDelayMs);
            continue;
          }

          throw geminiError;
        }

        const data: GeminiResponse = await response.json();

        if (!data.candidates || data.candidates.length === 0) {
          throw new GeminiError(GeminiErrorType.INVALID_REQUEST, 'No response candidates from Gemini', undefined, false);
        }

        const candidate = data.candidates[0];
        if (candidate.finishReason === 'SAFETY') {
          throw new GeminiError(GeminiErrorType.SAFETY_BLOCKED, 'Response blocked by safety filters', undefined, false);
        }

        const text = candidate.content?.parts?.[0]?.text || '';
        const inputTokens = data.usageMetadata?.promptTokenCount || 0;
        const outputTokens = data.usageMetadata?.candidatesTokenCount || 0;

        return { text, inputTokens, outputTokens };
      } catch (error) {
        if (error instanceof GeminiError) {
          lastError = error;
          if (!error.retryable || attempt >= RETRY_CONFIG.maxRetries) {
            throw error;
          }
        } else {
          // Network error or timeout
          lastError = this.wrapError(error);
          this.recordFailure();

          if (lastError.retryable && attempt < RETRY_CONFIG.maxRetries) {
            this.logger.warn({
              message: `Gemini request failed, retrying`,
              attempt,
              maxRetries: RETRY_CONFIG.maxRetries,
              error: lastError.message,
            });
            await this.sleep(delay);
            delay = Math.min(delay * RETRY_CONFIG.exponentialBase, RETRY_CONFIG.maxDelayMs);
            continue;
          }
          throw lastError;
        }

        await this.sleep(delay);
        delay = Math.min(delay * RETRY_CONFIG.exponentialBase, RETRY_CONFIG.maxDelayMs);
      }
    }

    throw lastError || new GeminiError(GeminiErrorType.SERVER_ERROR, 'Max retries exceeded', undefined, false);
  }

  /**
   * Parse API error into typed GeminiError
   */
  private parseApiError(status: number, errorText: string): GeminiError {
    const errorLower = errorText.toLowerCase();

    // Model not found - configuration error, not retryable
    if (status === 404 || errorLower.includes('not found') || errorLower.includes('not supported')) {
      return new GeminiError(
        GeminiErrorType.MODEL_NOT_FOUND,
        `Model not found or not supported: ${errorText}`,
        status,
        false,
      );
    }

    // Rate limited - retryable
    if (status === 429 || errorLower.includes('quota') || errorLower.includes('rate limit')) {
      return new GeminiError(GeminiErrorType.RATE_LIMITED, `Rate limit exceeded: ${errorText}`, status, true);
    }

    // Invalid request - not retryable
    if (status === 400) {
      return new GeminiError(GeminiErrorType.INVALID_REQUEST, `Invalid request: ${errorText}`, status, false);
    }

    // Server errors - retryable
    if (status >= 500) {
      return new GeminiError(GeminiErrorType.SERVER_ERROR, `Server error: ${errorText}`, status, true);
    }

    // Other 4xx - not retryable
    return new GeminiError(GeminiErrorType.INVALID_REQUEST, `API error ${status}: ${errorText}`, status, false);
  }

  /**
   * Wrap unknown error into GeminiError
   */
  private wrapError(error: unknown): GeminiError {
    if (error instanceof GeminiError) {
      return error;
    }

    const message = error instanceof Error ? error.message : String(error);
    const messageLower = message.toLowerCase();

    // Network/timeout errors are retryable
    if (
      messageLower.includes('network') ||
      messageLower.includes('timeout') ||
      messageLower.includes('abort') ||
      messageLower.includes('econnreset') ||
      messageLower.includes('enotfound')
    ) {
      return new GeminiError(GeminiErrorType.NETWORK_ERROR, `Network error: ${message}`, undefined, true);
    }

    return new GeminiError(GeminiErrorType.SERVER_ERROR, message, undefined, false);
  }

  // ===========================
  // Circuit Breaker
  // ===========================

  private isCircuitOpen(): boolean {
    if (this.circuitBreaker.state === 'CLOSED') {
      return false;
    }

    if (this.circuitBreaker.state === 'OPEN') {
      // Check if reset timeout has passed
      const timeSinceLastFailure = Date.now() - this.circuitBreaker.lastFailure;
      if (timeSinceLastFailure >= this.CIRCUIT_RESET_TIMEOUT_MS) {
        // Transition to half-open
        this.circuitBreaker.state = 'HALF_OPEN';
        this.logger.log('Circuit breaker transitioning to HALF_OPEN');
        return false;
      }
      return true;
    }

    // HALF_OPEN - allow one request through
    return false;
  }

  private recordFailure(): void {
    this.circuitBreaker.failures++;
    this.circuitBreaker.lastFailure = Date.now();

    if (this.circuitBreaker.failures >= this.CIRCUIT_FAILURE_THRESHOLD) {
      this.circuitBreaker.state = 'OPEN';
      this.logger.warn({
        message: 'Circuit breaker OPEN - AI service temporarily disabled',
        failures: this.circuitBreaker.failures,
        resetTimeoutMs: this.CIRCUIT_RESET_TIMEOUT_MS,
      });
    }
  }

  private resetCircuit(): void {
    if (this.circuitBreaker.state !== 'CLOSED') {
      this.logger.log('Circuit breaker reset to CLOSED');
    }
    this.circuitBreaker.failures = 0;
    this.circuitBreaker.state = 'CLOSED';
  }

  /**
   * Get circuit breaker status (for monitoring)
   */
  getCircuitStatus(): { state: string; failures: number; lastFailure: number } {
    return {
      state: this.circuitBreaker.state,
      failures: this.circuitBreaker.failures,
      lastFailure: this.circuitBreaker.lastFailure,
    };
  }

  // ===========================
  // Metrics
  // ===========================

  private recordMetrics(
    operation: string,
    model: string,
    latencyMs: number,
    status: 'success' | 'error',
    errorType?: GeminiErrorType,
  ): void {
    if (!this.metricsService) return;

    try {
      // Record request count
      this.metricsService.recordAiRequest(operation, model, status);

      // Record latency
      if (latencyMs > 0) {
        this.metricsService.recordAiLatency(operation, model, latencyMs);
      }

      // Record failures by type
      if (status === 'error' && errorType) {
        this.metricsService.recordAiFailure(operation, model, errorType);
      }
    } catch (e) {
      // Don't let metrics errors affect the main flow
      this.logger.debug(`Failed to record metrics: ${e}`);
    }
  }

  /**
   * Sleep helper
   */
  private sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}
