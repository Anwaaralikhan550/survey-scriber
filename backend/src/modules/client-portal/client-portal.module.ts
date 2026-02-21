import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule, ConfigService } from '@nestjs/config';

import { PrismaModule } from '../prisma/prisma.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { InvoicesModule } from '../invoices/invoices.module';
import { LocalStorageService } from '../media/storage/local-storage.service';
import { STORAGE_SERVICE } from '../media/storage/storage.interface';

// Services
import { MagicLinkService } from './magic-link.service';
import { ClientAuthService } from './client-auth.service';
import { ClientBookingsService } from './client-bookings.service';
import { ClientReportsService } from './client-reports.service';

// Controllers
import { ClientAuthController } from './client-auth.controller';
import { ClientBookingsController } from './client-bookings.controller';
import { ClientReportsController } from './client-reports.controller';
import { ClientNotificationsController } from './client-notifications.controller';
import { ClientInvoicesController } from './client-invoices.controller';

// Guards & Strategies
import { ClientJwtStrategy } from './guards/client-jwt.strategy';
import { ClientJwtGuard } from './guards/client-jwt.guard';

@Module({
  imports: [
    PrismaModule,
    ConfigModule,
    NotificationsModule,
    InvoicesModule,
    PassportModule.register({ defaultStrategy: 'client-jwt' }),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => {
        const secret = configService.get<string>('JWT_ACCESS_SECRET');
        if (!secret) {
          throw new Error(
            'FATAL: JWT_ACCESS_SECRET environment variable is not set.',
          );
        }
        return {
          secret,
          signOptions: {
            expiresIn: 900, // 15 minutes in seconds
          },
        };
      },
    }),
  ],
  controllers: [
    ClientAuthController,
    ClientBookingsController,
    ClientReportsController,
    ClientNotificationsController,
    ClientInvoicesController,
  ],
  providers: [
    // Services
    MagicLinkService,
    ClientAuthService,
    ClientBookingsService,
    ClientReportsService,
    // Storage
    {
      provide: STORAGE_SERVICE,
      useClass: LocalStorageService,
    },
    // Auth
    ClientJwtStrategy,
    ClientJwtGuard,
  ],
  exports: [
    ClientAuthService,
    ClientJwtGuard,
  ],
})
export class ClientPortalModule {}
