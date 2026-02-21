import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { EmailService } from './email.service';
import { JwtStrategy } from './strategies/jwt.strategy';
import { LocalStrategy } from './strategies/local.strategy';
import { PrismaModule } from '../prisma/prisma.module';
import { AuditModule } from '../audit/audit.module';
import { LocalStorageService } from '../media/storage/local-storage.service';
import { STORAGE_SERVICE } from '../media/storage/storage.interface';

@Module({
  imports: [
    PrismaModule,
    ConfigModule,
    AuditModule,
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => {
        // SECURITY: Fail-fast if JWT secret is not configured
        // This prevents the app from starting with an insecure default
        const secret = configService.get<string>('JWT_ACCESS_SECRET');
        if (!secret) {
          throw new Error(
            'FATAL: JWT_ACCESS_SECRET environment variable is not set. ' +
            'The application cannot start without a secure JWT secret.',
          );
        }
        return {
          secret: secret,
          signOptions: {
            expiresIn: 900, // 15 minutes in seconds
          },
        };
      },
    }),
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    EmailService,
    JwtStrategy,
    LocalStrategy,
    {
      provide: STORAGE_SERVICE,
      useClass: LocalStorageService,
    },
  ],
  exports: [AuthService, JwtStrategy],
})
export class AuthModule {}
