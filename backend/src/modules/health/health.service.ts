import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import {
  HealthResponseDto,
  VersionResponseDto,
  DatabaseStatus,
  ReadinessResponseDto,
  LivenessResponseDto,
} from './dto/health.dto';

@Injectable()
export class HealthService {
  private readonly logger = new Logger(HealthService.name);

  constructor(
    private readonly configService: ConfigService,
    private readonly prismaService: PrismaService,
  ) {}

  async getHealth(): Promise<HealthResponseDto> {
    const dbStatus = await this.checkDatabase();

    return {
      status: dbStatus.status === 'up' ? 'ok' : 'degraded',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      database: dbStatus,
    };
  }

  getVersion(): VersionResponseDto {
    return {
      name: this.configService.get<string>('APP_NAME', 'SurveyScriber API'),
      version: this.configService.get<string>('APP_VERSION', '1.0.0'),
      env: this.configService.get<string>('NODE_ENV', 'development'),
      nodeVersion: process.version,
    };
  }

  /**
   * Kubernetes readiness probe - can this instance accept traffic?
   * Checks if all dependencies (database) are available.
   */
  async checkReadiness(): Promise<ReadinessResponseDto> {
    const dbStatus = await this.checkDatabase();
    const dbReady = dbStatus.status === 'up';

    const response: ReadinessResponseDto = {
      ready: dbReady,
      timestamp: new Date().toISOString(),
      checks: {
        database: dbReady,
      },
    };

    if (!dbReady) {
      response.reason = `Database unavailable: ${dbStatus.error || 'connection failed'}`;
    }

    return response;
  }

  /**
   * Kubernetes liveness probe - is this process alive?
   * Simple check that the event loop is responsive (not deadlocked).
   * Should NOT check dependencies - that's what readiness is for.
   */
  checkLiveness(): LivenessResponseDto {
    return {
      alive: true,
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
    };
  }

  private async checkDatabase(): Promise<DatabaseStatus> {
    try {
      const startTime = Date.now();
      await this.prismaService.$queryRaw`SELECT 1`;
      const responseTime = Date.now() - startTime;

      return {
        status: 'up',
        responseTime: `${responseTime}ms`,
      };
    } catch (error) {
      this.logger.error('Database health check failed', error);
      return {
        status: 'down',
        error: error instanceof Error ? error.message : 'Unknown error',
      };
    }
  }
}
