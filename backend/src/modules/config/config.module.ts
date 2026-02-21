import { Module, OnModuleInit } from '@nestjs/common';
import { ConfigService } from './config.service';
import { ConfigPublicController, ConfigAdminController } from './config.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { AuditModule } from '../audit/audit.module';

@Module({
  imports: [PrismaModule, AuditModule],
  controllers: [ConfigPublicController, ConfigAdminController],
  providers: [ConfigService],
  exports: [ConfigService],
})
export class ConfigManagementModule implements OnModuleInit {
  constructor(private readonly configService: ConfigService) {}

  async onModuleInit(): Promise<void> {
    await this.configService.seedDefaultSectionTypes();
  }
}
