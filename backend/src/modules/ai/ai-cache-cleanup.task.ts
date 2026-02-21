import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { AiCacheService } from './ai-cache.service';

@Injectable()
export class AiCacheCleanupTask {
  private readonly logger = new Logger(AiCacheCleanupTask.name);

  constructor(private readonly cacheService: AiCacheService) {}

  /**
   * Clean up expired cache entries every hour
   */
  @Cron(CronExpression.EVERY_HOUR)
  async handleCacheCleanup() {
    this.logger.debug('Running AI cache cleanup...');
    const count = await this.cacheService.cleanupExpired();
    if (count > 0) {
      this.logger.log(`Cleaned up ${count} expired AI cache entries`);
    }
  }
}
