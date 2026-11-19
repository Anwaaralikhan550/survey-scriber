import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { AiModule } from '../ai/ai.module';
import { ReportEditingController } from './report-editing.controller';
import { EditorController } from './editor.controller';
import { ReportEditingService } from './report-editing.service';
import { EditorSessionService } from './editor-session.service';
import { EditorSessionGuard, EditorSecurityHeadersInterceptor } from './editor.guard';
import { EditorPhotosController } from './editor-photos.controller';
import { ReportPhotosService } from './report-photos.service';
import { ReportFilesService } from './report-files.service';
import { OriginalSnapshotService } from './original-snapshot.service';
import { ReportAuditService } from './report-audit.service';
import { ReportMediaService } from './report-media.service';
import { ReportArchiveService } from './report-archive.service';
import { ReportRetentionService } from './report-retention.service';
import { AuthModule } from '../auth/auth.module';
import { EditorReviewController } from './editor-review.controller';
import { ReviewService } from './review.service';
import { FinalisationService } from './finalisation.service';
import { EditorAiController } from './editor-ai.controller';
import { AiSuggestionService } from './ai-suggestion.service';
import { LocalStorageService } from '../media/storage/local-storage.service';
import { STORAGE_SERVICE } from '../media/storage/storage.interface';

@Module({
  imports: [PrismaModule, AiModule, AuthModule],
  controllers: [ReportEditingController, EditorController, EditorPhotosController, EditorReviewController, EditorAiController],
  providers: [
    ReportEditingService,
    EditorSessionService,
    EditorSessionGuard,
    EditorSecurityHeadersInterceptor,
    ReportPhotosService,
    ReportFilesService,
    OriginalSnapshotService,
    ReportAuditService,
    ReportMediaService,
    ReportArchiveService,
    ReportRetentionService,
    ReviewService,
    AiSuggestionService,
    FinalisationService,
    { provide: STORAGE_SERVICE, useClass: LocalStorageService },
  ],
  exports: [FinalisationService, ReportEditingService, EditorSessionService, ReportPhotosService, ReportFilesService, ReviewService],
})
export class ReportEditingModule {}
