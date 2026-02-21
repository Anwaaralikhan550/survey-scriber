import { Module } from '@nestjs/common';
import { SectionsController } from './sections.controller';
import { SectionsService } from './sections.service';
import { PrismaModule } from '../prisma/prisma.module';
import { SurveysModule } from '../surveys/surveys.module';

@Module({
  imports: [PrismaModule, SurveysModule],
  controllers: [SectionsController],
  providers: [SectionsService],
  exports: [SectionsService],
})
export class SectionsModule {}
