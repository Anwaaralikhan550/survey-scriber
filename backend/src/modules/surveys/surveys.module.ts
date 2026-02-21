import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { SurveysController } from './surveys.controller';
import { SurveysService } from './surveys.service';
import { PrismaModule } from '../prisma/prisma.module';
import { WebhooksModule } from '../webhooks/webhooks.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { LocalStorageService } from '../media/storage/local-storage.service';
import { STORAGE_SERVICE } from '../media/storage/storage.interface';

@Module({
  imports: [PrismaModule, ConfigModule, WebhooksModule, NotificationsModule],
  controllers: [SurveysController],
  providers: [
    SurveysService,
    {
      provide: STORAGE_SERVICE,
      useClass: LocalStorageService,
    },
  ],
  exports: [SurveysService],
})
export class SurveysModule {}
