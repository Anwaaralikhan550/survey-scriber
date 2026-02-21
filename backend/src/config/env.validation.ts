import { plainToInstance } from 'class-transformer';
import { IsBoolean, IsEnum, IsNumber, IsOptional, IsString, validateSync, Min, Max, MinLength } from 'class-validator';

enum Environment {
  Development = 'development',
  Production = 'production',
  Test = 'test',
}

enum StorageDriver {
  Local = 'local',
  S3 = 's3',
}

/**
 * P1-4: Known default/insecure JWT secret patterns that MUST be replaced in production
 */
const FORBIDDEN_SECRET_PATTERNS = [
  'default',
  'secret',
  'change-in-production',
  'your-super-secret',
  'changeme',
  'password',
  'test',
  'example',
];

function isDefaultSecret(secret: string): boolean {
  const lowerSecret = secret.toLowerCase();
  return FORBIDDEN_SECRET_PATTERNS.some((pattern) => lowerSecret.includes(pattern));
}

class EnvironmentVariables {
  @IsEnum(Environment)
  @IsOptional()
  NODE_ENV: Environment = Environment.Development;

  @IsNumber()
  @Min(1)
  @Max(65535)
  @IsOptional()
  PORT: number = 3000;

  @IsString()
  @IsOptional()
  API_PREFIX: string = 'api';

  @IsString()
  @IsOptional()
  APP_NAME: string = 'SurveyScriber API';

  @IsString()
  @IsOptional()
  APP_VERSION: string = '1.0.0';

  @IsString()
  DATABASE_URL!: string;

  @IsString()
  @MinLength(32)
  JWT_ACCESS_SECRET!: string;

  @IsString()
  @IsOptional()
  JWT_ACCESS_EXPIRES_IN: string = '15m';

  @IsString()
  @MinLength(32)
  JWT_REFRESH_SECRET!: string;

  @IsNumber()
  @Min(1)
  @Max(365)
  @IsOptional()
  REFRESH_TOKEN_EXPIRES_DAYS: number = 7;

  @IsNumber()
  @Min(4)
  @Max(31)
  @IsOptional()
  BCRYPT_SALT_ROUNDS: number = 12;

  @IsString()
  @IsOptional()
  LOG_LEVEL: string = 'debug';

  @IsString()
  @IsOptional()
  CORS_ORIGINS: string = '';

  // ============================================
  // Media Storage Configuration (Phase 5C-3)
  // ============================================

  @IsEnum(StorageDriver)
  @IsOptional()
  MEDIA_STORAGE_DRIVER: StorageDriver = StorageDriver.Local;

  @IsString()
  @IsOptional()
  MEDIA_LOCAL_ROOT: string = 'storage';

  @IsNumber()
  @Min(1)
  @Max(100)
  @IsOptional()
  MAX_UPLOAD_MB_PHOTO: number = 10;

  @IsNumber()
  @Min(1)
  @Max(100)
  @IsOptional()
  MAX_UPLOAD_MB_AUDIO: number = 30;

  @IsNumber()
  @Min(1)
  @Max(50)
  @IsOptional()
  MAX_UPLOAD_MB_SIGNATURE: number = 5;

  @IsString()
  @IsOptional()
  ALLOWED_MIME_PHOTO: string = 'image/jpeg,image/png,image/webp,image/heic';

  @IsString()
  @IsOptional()
  ALLOWED_MIME_AUDIO: string = 'audio/mpeg,audio/wav,audio/mp4,audio/aac,audio/ogg';

  @IsString()
  @IsOptional()
  ALLOWED_MIME_SIGNATURE: string = 'image/png,image/svg+xml';

  // ============================================
  // Rate Limiting Configuration (Phase 3.3)
  // ============================================

  @IsNumber()
  @Min(1)
  @Max(10)
  @IsOptional()
  RATE_LIMIT_MAGIC_LINK_MAX: number = 3;

  @IsNumber()
  @Min(60)
  @Max(3600)
  @IsOptional()
  RATE_LIMIT_MAGIC_LINK_TTL_SECONDS: number = 900; // 15 minutes

  // Magic link token expiry (separate from rate limit TTL)
  @IsNumber()
  @Min(300) // 5 minutes minimum
  @Max(3600) // 60 minutes maximum
  @IsOptional()
  MAGIC_LINK_EXPIRY_SECONDS: number = 900; // 15 minutes default

  @IsNumber()
  @Min(1)
  @Max(50)
  @IsOptional()
  RATE_LIMIT_BOOKING_REQUEST_MAX: number = 10;

  @IsNumber()
  @Min(60)
  @Max(3600)
  @IsOptional()
  RATE_LIMIT_BOOKING_REQUEST_TTL_SECONDS: number = 3600; // 60 minutes

  @IsNumber()
  @Min(1)
  @Max(20)
  @IsOptional()
  RATE_LIMIT_CHANGE_REQUEST_MAX: number = 5;

  @IsNumber()
  @Min(60)
  @Max(3600)
  @IsOptional()
  RATE_LIMIT_CHANGE_REQUEST_TTL_SECONDS: number = 3600; // 60 minutes

  // ===========================================
  // SMTP / Email Configuration (SEC-M5)
  // ===========================================
  // Optional in development (emails logged to console), required in production.

  @IsString()
  @IsOptional()
  SMTP_HOST?: string;

  @IsNumber()
  @Min(1)
  @Max(65535)
  @IsOptional()
  SMTP_PORT?: number;

  @IsString()
  @IsOptional()
  SMTP_USER?: string;

  @IsString()
  @IsOptional()
  SMTP_PASS?: string;

  @IsString()
  @IsOptional()
  SMTP_FROM?: string;

  @IsBoolean()
  @IsOptional()
  SMTP_SECURE?: boolean;

  // ===========================================
  // Proxy Configuration (AWS ALB/ELB/CloudFront)
  // ===========================================
  @IsBoolean()
  @IsOptional()
  TRUST_PROXY: boolean = false; // Set true when behind AWS ALB/ELB
}

export function validate(config: Record<string, unknown>): Record<string, unknown> {
  const validatedConfig = plainToInstance(EnvironmentVariables, config, {
    enableImplicitConversion: true,
  });

  const errors = validateSync(validatedConfig, {
    skipMissingProperties: false,
  });

  if (errors.length > 0) {
    const errorMessages = errors
      .map((error) => {
        const constraints = error.constraints ? Object.values(error.constraints).join(', ') : '';
        return error.property + ': ' + constraints;
      })
      .join('\n');

    throw new Error('Environment validation failed:\n' + errorMessages);
  }

  // P1-4: Validate JWT secrets are not default/insecure values
  const nodeEnv = validatedConfig.NODE_ENV;
  const accessSecret = validatedConfig.JWT_ACCESS_SECRET;
  const refreshSecret = validatedConfig.JWT_REFRESH_SECRET;

  const accessSecretIsDefault = isDefaultSecret(accessSecret);
  const refreshSecretIsDefault = isDefaultSecret(refreshSecret);

  if (nodeEnv === Environment.Production) {
    // In production: FAIL FAST if default secrets detected
    const secretErrors: string[] = [];

    if (accessSecretIsDefault) {
      secretErrors.push('JWT_ACCESS_SECRET contains forbidden default pattern - use a secure random value');
    }
    if (refreshSecretIsDefault) {
      secretErrors.push('JWT_REFRESH_SECRET contains forbidden default pattern - use a secure random value');
    }

    if (secretErrors.length > 0) {
      throw new Error(
        'SECURITY ERROR: Default JWT secrets detected in production!\n' +
          secretErrors.join('\n') +
          '\n\nGenerate secure secrets with: node -e "console.log(require(\'crypto\').randomBytes(64).toString(\'hex\'))"'
      );
    }
  } else {
    // In development/test: WARN but allow
    if (accessSecretIsDefault || refreshSecretIsDefault) {
      console.warn('\nWARNING: Using default JWT secrets. This is ONLY acceptable for development.');
      console.warn('Generate production secrets with: node -e "console.log(require(\'crypto\').randomBytes(64).toString(\'hex\'))"\n');
    }
  }

  // SEC-M5: In production, SMTP must be configured for password reset emails to work.
  // Without it, forgot-password silently succeeds but no email is sent — users are locked out.
  if (nodeEnv === Environment.Production) {
    const smtpErrors: string[] = [];
    if (!validatedConfig.SMTP_HOST) smtpErrors.push('SMTP_HOST is required in production');
    if (!validatedConfig.SMTP_FROM) smtpErrors.push('SMTP_FROM is required in production');

    if (smtpErrors.length > 0) {
      console.warn(
        '\nWARNING: SMTP not fully configured in production:\n' +
          smtpErrors.join('\n') +
          '\nPassword reset emails will not be delivered.\n',
      );
    }
  }

  return validatedConfig as unknown as Record<string, unknown>;
}
