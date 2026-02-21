import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AiFeatureType } from '@prisma/client';
import { createHash } from 'crypto';
import { AI_CACHE_TTL } from './ai.constants';

export interface CacheEntry {
  response: unknown;
  inputTokens: number;
  outputTokens: number;
  promptVersion: string;
}

@Injectable()
export class AiCacheService {
  private readonly logger = new Logger(AiCacheService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Generate a deterministic cache key from inputs
   */
  generateCacheKey(params: {
    surveyId: string;
    featureType: AiFeatureType;
    promptVersion: string;
    inputData: unknown;
  }): string {
    const inputHash = this.hashInput(params.inputData);
    return `${params.featureType}_${params.surveyId}_${params.promptVersion}_${inputHash}`;
  }

  /**
   * Hash input data for cache key generation.
   *
   * ARCH-C2 FIX: Uses stableStringify for robust serialization that handles
   * all data types (null, undefined, primitives, arrays, objects) without throwing.
   */
  private hashInput(data: unknown): string {
    const json = this.stableStringify(data);
    return createHash('sha256').update(json).digest('hex').substring(0, 16);
  }

  /**
   * Produce a stable, deterministic JSON string for any input.
   *
   * ARCH-C2 FIX: Implements robust serialization that:
   * - Handles null → "null"
   * - Handles undefined → "undefined" (special marker)
   * - Handles primitives (string, number, boolean) safely
   * - Handles arrays with recursive stable serialization
   * - Handles objects with sorted keys for deterministic output
   * - Handles nested structures recursively
   * - Never throws for any input type
   *
   * @param data - Any value to serialize
   * @returns Deterministic JSON string representation
   */
  private stableStringify(data: unknown): string {
    return this.stableStringifyRecursive(data);
  }

  /**
   * Recursive stable serialization implementation.
   */
  private stableStringifyRecursive(value: unknown): string {
    // Handle null explicitly
    if (value === null) {
      return 'null';
    }

    // Handle undefined - use special marker for cache differentiation
    if (value === undefined) {
      return '"__undefined__"';
    }

    // Handle primitives
    const type = typeof value;

    if (type === 'string') {
      // Escape and quote string
      return JSON.stringify(value);
    }

    if (type === 'number') {
      // Handle special number cases
      if (Number.isNaN(value as number)) {
        return '"NaN"';
      }
      if (!Number.isFinite(value as number)) {
        return value === Infinity ? '"Infinity"' : '"-Infinity"';
      }
      return String(value);
    }

    if (type === 'boolean') {
      return value ? 'true' : 'false';
    }

    if (type === 'bigint') {
      return `"${String(value)}n"`;
    }

    if (type === 'symbol') {
      return `"Symbol(${(value as symbol).description || ''})"`;
    }

    if (type === 'function') {
      // Functions are serialized as a marker (not executable)
      return '"[Function]"';
    }

    // Handle arrays
    if (Array.isArray(value)) {
      const elements = value.map((item) => this.stableStringifyRecursive(item));
      return `[${elements.join(',')}]`;
    }

    // Handle Date objects
    if (value instanceof Date) {
      return `"${value.toISOString()}"`;
    }

    // Handle Map
    if (value instanceof Map) {
      const entries: [string, string][] = [];
      for (const [k, v] of value) {
        entries.push([
          this.stableStringifyRecursive(k),
          this.stableStringifyRecursive(v),
        ]);
      }
      // Sort by key for determinism
      entries.sort((a, b) => a[0].localeCompare(b[0]));
      const mapEntries = entries.map(([k, v]) => `[${k},${v}]`);
      return `{"__type__":"Map","entries":[${mapEntries.join(',')}]}`;
    }

    // Handle Set
    if (value instanceof Set) {
      const elements = Array.from(value)
        .map((item) => this.stableStringifyRecursive(item))
        .sort(); // Sort for determinism
      return `{"__type__":"Set","values":[${elements.join(',')}]}`;
    }

    // Handle RegExp
    if (value instanceof RegExp) {
      return `"${value.toString()}"`;
    }

    // Handle Error
    if (value instanceof Error) {
      return JSON.stringify({
        __type__: 'Error',
        name: value.name,
        message: value.message,
      });
    }

    // Handle plain objects (including Object.create(null))
    if (type === 'object') {
      try {
        const obj = value as Record<string, unknown>;
        const keys = Object.keys(obj).sort(); // Sort keys for determinism

        if (keys.length === 0) {
          return '{}';
        }

        const pairs = keys.map((key) => {
          const serializedKey = JSON.stringify(key);
          const serializedValue = this.stableStringifyRecursive(obj[key]);
          return `${serializedKey}:${serializedValue}`;
        });

        return `{${pairs.join(',')}}`;
      } catch {
        // Fallback for objects that throw on property access
        return '"[Object]"';
      }
    }

    // Unknown type fallback
    return '"[Unknown]"';
  }

  /**
   * Get cached response if valid
   */
  async get(cacheKey: string): Promise<CacheEntry | null> {
    try {
      const cached = await this.prisma.aiResponseCache.findUnique({
        where: { cacheKey },
      });

      if (!cached) {
        return null;
      }

      // Check if expired
      if (new Date() > cached.expiresAt) {
        // Clean up expired entry
        await this.prisma.aiResponseCache.delete({
          where: { cacheKey },
        }).catch(() => {}); // Ignore if already deleted
        return null;
      }

      this.logger.debug(`Cache hit for key: ${cacheKey}`);
      return {
        response: cached.response,
        inputTokens: cached.inputTokens,
        outputTokens: cached.outputTokens,
        promptVersion: cached.promptVersion,
      };
    } catch (error) {
      this.logger.error(`Cache get error: ${error}`);
      return null;
    }
  }

  /**
   * Store response in cache
   */
  async set(params: {
    cacheKey: string;
    featureType: AiFeatureType;
    surveyId: string;
    promptVersion: string;
    inputHash: string;
    response: unknown;
    inputTokens: number;
    outputTokens: number;
  }): Promise<void> {
    try {
      const ttl = AI_CACHE_TTL[params.featureType] || AI_CACHE_TTL.REPORT;
      const expiresAt = new Date(Date.now() + ttl);

      await this.prisma.aiResponseCache.upsert({
        where: { cacheKey: params.cacheKey },
        create: {
          cacheKey: params.cacheKey,
          featureType: params.featureType,
          surveyId: params.surveyId,
          promptVersion: params.promptVersion,
          inputHash: params.inputHash,
          response: params.response as object,
          inputTokens: params.inputTokens,
          outputTokens: params.outputTokens,
          expiresAt,
        },
        update: {
          response: params.response as object,
          inputTokens: params.inputTokens,
          outputTokens: params.outputTokens,
          expiresAt,
        },
      });

      this.logger.debug(`Cache set for key: ${params.cacheKey}`);
    } catch (error) {
      this.logger.error(`Cache set error: ${error}`);
      // Don't throw - caching is non-critical
    }
  }

  /**
   * Invalidate cache for a survey
   */
  async invalidateSurvey(surveyId: string): Promise<void> {
    try {
      await this.prisma.aiResponseCache.deleteMany({
        where: { surveyId },
      });
      this.logger.debug(`Cache invalidated for survey: ${surveyId}`);
    } catch (error) {
      this.logger.error(`Cache invalidation error: ${error}`);
    }
  }

  /**
   * Clean up expired cache entries (call from scheduled task)
   */
  async cleanupExpired(): Promise<number> {
    try {
      const result = await this.prisma.aiResponseCache.deleteMany({
        where: {
          expiresAt: { lt: new Date() },
        },
      });
      this.logger.log(`Cleaned up ${result.count} expired cache entries`);
      return result.count;
    } catch (error) {
      this.logger.error(`Cache cleanup error: ${error}`);
      return 0;
    }
  }
}
