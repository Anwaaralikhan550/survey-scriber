import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from '../prisma/prisma.module';
import { MediaController } from './media.controller';
import { MediaService } from './media.service';
import { LocalStorageService } from './storage/local-storage.service';
import { STORAGE_SERVICE } from './storage/storage.interface';

@Module({
  imports: [PrismaModule, ConfigModule],
  controllers: [MediaController],
  providers: [
    MediaService,
    {
      provide: STORAGE_SERVICE,
      useClass: LocalStorageService,
    },
  ],
  exports: [MediaService],
})
export class MediaModule {}
