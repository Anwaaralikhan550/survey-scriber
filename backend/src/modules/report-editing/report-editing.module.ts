import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { ReportEditingController } from './report-editing.controller';
import { EditorController } from './editor.controller';
import { ReportEditingService } from './report-editing.service';
import { EditorSessionService } from './editor-session.service';
import { EditorSessionGuard, EditorSecurityHeadersInterceptor } from './editor.guard';
import { EditorPhotosController } from './editor-photos.controller';
import { ReportPhotosService } from './report-photos.service';
import { EditorReviewController } from './editor-review.controller';
import { ReviewService } from './review.service';
import { LocalStorageService } from '../media/storage/local-storage.service';
import { STORAGE_SERVICE } from '../media/storage/storage.interface';

@Module({
  imports: [PrismaModule],
  controllers: [ReportEditingController, EditorController, EditorPhotosController, EditorReviewController],
  providers: [
    ReportEditingService,
    EditorSessionService,
    EditorSessionGuard,
    EditorSecurityHeadersInterceptor,
    ReportPhotosService,
    ReviewService,
    { provide: STORAGE_SERVICE, useClass: LocalStorageService },
  ],
  exports: [ReportEditingService, EditorSessionService, ReportPhotosService, ReviewService],
})
export class ReportEditingModule {}
