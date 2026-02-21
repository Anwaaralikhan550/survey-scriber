import { Module } from '@nestjs/common';
import { ScheduleModule } from '@nestjs/schedule';
import { AiController } from './ai.controller';
import { AiService } from './ai.service';
import { AiGeminiService } from './ai-gemini.service';
import { AiCacheService } from './ai-cache.service';
import { AiPromptService } from './ai-prompt.service';
import { AiCacheCleanupTask } from './ai-cache-cleanup.task';
import { EnhancedReportService } from '../../services/enhanced-report.service';
import { ExcelPhraseGeneratorService } from '../../services/excel-phrase-generator.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule, ScheduleModule],
  controllers: [AiController],
  providers: [
    AiService,
    AiGeminiService,
    AiCacheService,
    AiPromptService,
    AiCacheCleanupTask,
    EnhancedReportService,
    ExcelPhraseGeneratorService,
  ],
  exports: [AiService],
})
export class AiModule {}
