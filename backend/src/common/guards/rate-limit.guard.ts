import {
  Injectable,
  CanActivate,
  ExecutionContext,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Request } from 'express';

/**
 * Rate limit configuration for different endpoint types
 */
interface RateLimitConfig {
  max: number;
  ttlMs: number;
}

/**
 * In-memory rate limit entry
 */
interface RateLimitEntry {
  count: number;
  expiresAt: number;
}

/**
 * Simple in-memory rate limit store.
 * Uses a Map with automatic cleanup of expired entries.
 *
 * MULTI-INSTANCE LIMITATION:
 * This store is local to each process instance. In a multi-instance
 * deployment (e.g., AWS ECS with multiple tasks, Kubernetes with replicas),
 * each instance maintains its own counter, allowing clients to multiply
 * their effective rate by the number of instances.
 *
 * For production multi-instance deployments, replace with Redis-based storage:
 * - @nestjs/throttler-storage-redis
 * - Or custom Redis implementation for the custom guards
 *
 * Current single-instance deployment: Rate limits work correctly.
 */
class RateLimitStore {
  private static instance: RateLimitStore;
  private store = new Map<string, RateLimitEntry>();
  private cleanupInterval: NodeJS.Timeout | null = null;

  private constructor() {
    // Cleanup expired entries every minute
    this.cleanupInterval = setInterval(() => this.cleanup(), 60000);
  }

  static getInstance(): RateLimitStore {
    if (!RateLimitStore.instance) {
      RateLimitStore.instance = new RateLimitStore();
    }
    return RateLimitStore.instance;
  }

  get(key: string): RateLimitEntry | undefined {
    const entry = this.store.get(key);
    if (entry && entry.expiresAt < Date.now()) {
      this.store.delete(key);
      return undefined;
    }
    return entry;
  }

  set(key: string, entry: RateLimitEntry): void {
    this.store.set(key, entry);
  }

  delete(key: string): void {
    this.store.delete(key);
  }

  private cleanup(): void {
    const now = Date.now();
    for (const [key, entry] of this.store.entries()) {
      if (entry.expiresAt < now) {
        this.store.delete(key);
      }
    }
  }
}

/**
 * Base rate limiting guard using in-memory store.
 * Tracks requests by a composite key (type + identifier).
 */
@Injectable()
export abstract class BaseRateLimitGuard implements CanActivate {
  protected readonly store = RateLimitStore.getInstance();

  constructor(protected readonly configService: ConfigService) {}

  protected abstract getConfig(): RateLimitConfig;
  protected abstract getIdentifier(
    request: Request,
    context: ExecutionContext,
  ): string | null;
  protected abstract getLimitType(): string;

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request>();
    const identifier = this.getIdentifier(request, context);

    if (!identifier) {
      // If no identifier can be extracted, allow the request
      return true;
    }

    const config = this.getConfig();
    const key = `ratelimit:${this.getLimitType()}:${identifier}`;

    const existing = this.store.get(key);
    const now = Date.now();

    if (existing) {
      if (existing.count >= config.max) {
        const retryAfter = Math.ceil((existing.expiresAt - now) / 1000);
        // Set Retry-After HTTP header so clients can respect the backoff period
        const response = context.switchToHttp().getResponse();
        response.header('Retry-After', String(retryAfter));
        throw new HttpException(
          {
            statusCode: HttpStatus.TOO_MANY_REQUESTS,
            error: 'Too Many Requests',
            message: `Rate limit exceeded. Please try again in ${retryAfter} seconds.`,
            retryAfter,
          },
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }

      // Increment counter
      this.store.set(key, {
        count: existing.count + 1,
        expiresAt: existing.expiresAt,
      });
    } else {
      // First request, start new window
      this.store.set(key, {
        count: 1,
        expiresAt: now + config.ttlMs,
      });
    }

    return true;
  }

  protected getClientIp(request: Request): string {
    // Get IP from various headers (proxy support)
    const forwarded = request.headers['x-forwarded-for'];
    if (forwarded) {
      const ips = (Array.isArray(forwarded) ? forwarded[0] : forwarded).split(',');
      return ips[0].trim();
    }
    return request.ip || request.socket?.remoteAddress || 'unknown';
  }
}

/**
 * Rate limiter for magic link requests.
 * Limits by email + IP combined to prevent abuse.
 */
@Injectable()
export class MagicLinkRateLimitGuard extends BaseRateLimitGuard {
  protected getConfig(): RateLimitConfig {
    return {
      max: this.configService.get<number>('RATE_LIMIT_MAGIC_LINK_MAX', 3),
      ttlMs:
        this.configService.get<number>('RATE_LIMIT_MAGIC_LINK_TTL_SECONDS', 900) *
        1000,
    };
  }

  protected getIdentifier(request: Request): string | null {
    const email = request.body?.email;
    const ip = this.getClientIp(request);

    if (!email) {
      return null;
    }

    // Combine email and IP for more granular limiting
    return `${email.toLowerCase()}:${ip}`;
  }

  protected getLimitType(): string {
    return 'magic-link';
  }
}

/**
 * Rate limiter for booking requests.
 * Limits by clientId.
 */
@Injectable()
export class BookingRequestRateLimitGuard extends BaseRateLimitGuard {
  protected getConfig(): RateLimitConfig {
    return {
      max: this.configService.get<number>('RATE_LIMIT_BOOKING_REQUEST_MAX', 10),
      ttlMs:
        this.configService.get<number>(
          'RATE_LIMIT_BOOKING_REQUEST_TTL_SECONDS',
          3600,
        ) * 1000,
    };
  }

  protected getIdentifier(
    request: Request,
    _context: ExecutionContext,
  ): string | null {
    // The user is attached by ClientJwtGuard
    const user = (request as any).user;
    return user?.id || null;
  }

  protected getLimitType(): string {
    return 'booking-request';
  }
}

/**
 * Rate limiter for booking change requests.
 * Limits by clientId.
 */
@Injectable()
export class ChangeRequestRateLimitGuard extends BaseRateLimitGuard {
  protected getConfig(): RateLimitConfig {
    return {
      max: this.configService.get<number>('RATE_LIMIT_CHANGE_REQUEST_MAX', 5),
      ttlMs:
        this.configService.get<number>(
          'RATE_LIMIT_CHANGE_REQUEST_TTL_SECONDS',
          3600,
        ) * 1000,
    };
  }

  protected getIdentifier(
    request: Request,
    _context: ExecutionContext,
  ): string | null {
    // The user is attached by ClientJwtGuard
    const user = (request as any).user;
    return user?.id || null;
  }

  protected getLimitType(): string {
    return 'change-request';
  }
}
