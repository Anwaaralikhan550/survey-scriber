import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { ReportEditingController } from './report-editing.controller';
import { EditorController } from './editor.controller';
import { ReportEditingService } from './report-editing.service';
import { EditorSessionService } from './editor-session.service';
import { EditorSessionGuard, EditorSecurityHeadersInterceptor } from './editor.guard';

@Module({
  imports: [PrismaModule],
  controllers: [ReportEditingController, EditorController],
  providers: [ReportEditingService, EditorSessionService, EditorSessionGuard, EditorSecurityHeadersInterceptor],
  exports: [ReportEditingService, EditorSessionService],
})
export class ReportEditingModule {}
