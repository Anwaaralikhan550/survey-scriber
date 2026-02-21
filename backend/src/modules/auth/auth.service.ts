import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
  NotFoundException,
  Inject,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { User, UserRole, ActorType, AuditEntityType } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';
import * as fs from 'fs';
import * as path from 'path';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService, AuditActions } from '../audit/audit.service';
import { RegisterDto } from './dto/register.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import {
  LoginResponseDto,
  RegisterResponseDto,
  UserResponseDto,
} from './dto/auth-response.dto';
import { EmailService } from './email.service';
import { JwtPayload } from './strategies/jwt.strategy';
import { StorageService, STORAGE_SERVICE } from '../media/storage/storage.interface';
import { ApiUrlBuilder } from '../../common/utils/api-url.util';

interface UploadedFile {
  originalname: string;
  mimetype: string;
  size: number;
  buffer: Buffer;
}

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private readonly maxImageSize = 5 * 1024 * 1024; // 5MB
  private readonly allowedMimeTypes = ['image/jpeg', 'image/png'];
  private readonly RESET_TOKEN_EXPIRY_MINUTES = 15;
  private readonly urlBuilder: ApiUrlBuilder;

  // OWASP A7: Account lockout thresholds (brute-force protection)
  private readonly MAX_FAILED_ATTEMPTS = 5;
  private readonly LOCKOUT_DURATION_MINUTES = 15;

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    @Inject(STORAGE_SERVICE) private readonly storageService: StorageService,
    private readonly emailService: EmailService,
    private readonly auditService: AuditService,
  ) {
    this.urlBuilder = new ApiUrlBuilder(configService);
  }

  async register(dto: RegisterDto): Promise<RegisterResponseDto> {
    const existingUser = await this.prisma.user.findUnique({
      where: { email: dto.email.toLowerCase() },
    });

    // SEC-M2: Prevent email enumeration on registration.
    // Always hash the password (constant-time) and return the same response shape
    // regardless of whether the email already exists.
    const saltRounds = this.configService.get<number>('BCRYPT_SALT_ROUNDS') || 12;
    const passwordHash = await bcrypt.hash(dto.password, saltRounds);

    if (existingUser) {
      // Return same shape as a successful registration to prevent enumeration.
      // The existing user's data is NOT modified or overwritten.
      this.logger.warn(`Registration attempt for existing email (user ${existingUser.id})`);
      return {
        id: existingUser.id,
        email: existingUser.email,
        role: existingUser.role,
      };
    }

    const user = await this.prisma.user.create({
      data: {
        email: dto.email.toLowerCase(),
        passwordHash,
        firstName: dto.firstName,
        lastName: dto.lastName,
        role: UserRole.SURVEYOR,
      },
    });

    // SEC-003: Avoid PII in logs (SOC2 compliance)
    this.logger.log(`User registered: ${user.id}`);

    return {
      id: user.id,
      email: user.email,
      role: user.role,
    };
  }

  // OWASP A7: Dummy hash used for constant-time login when user not found.
  // Prevents timing oracle that leaks valid emails via response time difference.
  private readonly DUMMY_HASH = '$2b$12$LJ3m4ys3Lf0Xg0eTsVxBu.Ye0fLz2T2C9Y5EJsAOqXWLfNyssHHzS';

  async validateUser(email: string, password: string): Promise<Omit<User, 'passwordHash'> | null> {
    const user = await this.prisma.user.findUnique({
      where: { email: email.toLowerCase() },
    });

    if (!user) {
      // Constant-time: run bcrypt even when user doesn't exist to prevent
      // timing-based email enumeration (OWASP A7)
      await bcrypt.compare(password, this.DUMMY_HASH);
      return null;
    }

    if (!user.isActive) {
      throw new UnauthorizedException('User account is deactivated');
    }

    // OWASP A7: Check if account is currently locked out
    if (user.lockedUntil && new Date() < user.lockedUntil) {
      const remainingMinutes = Math.ceil(
        (user.lockedUntil.getTime() - Date.now()) / 60000,
      );
      this.logger.warn(`Login blocked for locked account: ${user.id}`);
      throw new UnauthorizedException(
        `Account is temporarily locked. Try again in ${remainingMinutes} minute(s).`,
      );
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);

    if (!isPasswordValid) {
      // Increment failed attempts and lock if threshold exceeded
      const attempts = (user.failedLoginAttempts ?? 0) + 1;
      const lockData: { failedLoginAttempts: number; lockedUntil?: Date } = {
        failedLoginAttempts: attempts,
      };

      if (attempts >= this.MAX_FAILED_ATTEMPTS) {
        const lockUntil = new Date();
        lockUntil.setMinutes(lockUntil.getMinutes() + this.LOCKOUT_DURATION_MINUTES);
        lockData.lockedUntil = lockUntil;
        this.logger.warn(
          `Account locked after ${attempts} failed attempts: ${user.id}`,
        );
      }

      await this.prisma.user.update({
        where: { id: user.id },
        data: lockData,
      });

      return null;
    }

    // Successful login: reset failed attempts and clear any lockout
    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        lastLoginAt: new Date(),
        failedLoginAttempts: 0,
        lockedUntil: null,
      },
    });

    const { passwordHash: _, ...userWithoutPassword } = user;
    return userWithoutPassword;
  }

  /**
   * P0-1 Fix: Login now returns user object along with tokens
   * Response shape: { user, accessToken, refreshToken, expiresIn }
   */
  async login(user: Omit<User, 'passwordHash'>): Promise<LoginResponseDto> {
    // SEC-L1: Explicit realm marker — client tokens carry type:'client',
    // staff tokens must carry type:'staff' so the JWT strategy can enforce realm isolation.
    const payload: JwtPayload = {
      sub: user.id,
      email: user.email,
      role: user.role,
      type: 'staff',
    };

    // SECURITY: No fallback - fail fast if secret is missing (defense-in-depth)
    const secret = this.configService.get<string>('JWT_ACCESS_SECRET');
    if (!secret) {
      throw new Error('JWT_ACCESS_SECRET is not configured - cannot sign tokens');
    }
    const expiresInStr = this.configService.get<string>('JWT_ACCESS_EXPIRES_IN') || '15m';
    const expiresIn = this.parseExpirationToSeconds(expiresInStr);

    const accessToken = this.jwtService.sign(payload, {
      secret: secret,
      expiresIn: expiresIn,
    });

    const refreshToken = this.generateRefreshToken();
    await this.storeRefreshToken(user.id, refreshToken);

    // SEC-AUDIT: Log successful staff login for compliance/forensics
    await this.auditService.log({
      actorType: ActorType.STAFF,
      actorId: user.id,
      action: AuditActions.STAFF_LOGIN,
      entityType: AuditEntityType.AUTH,
      metadata: { role: user.role },
    });

    this.logger.log(`User logged in: ${user.id}`);

    // P0-1: Include user object in response
    const userResponse: UserResponseDto = {
      id: user.id,
      email: user.email,
      firstName: user.firstName ?? undefined,
      lastName: user.lastName ?? undefined,
      phone: user.phone ?? undefined,
      organization: user.organization ?? undefined,
      avatarUrl: user.avatarUrl ?? undefined,
      emailVerified: user.emailVerified,
      role: user.role,
      isActive: user.isActive,
      createdAt: user.createdAt,
    };

    return {
      user: userResponse,
      accessToken,
      refreshToken,
      expiresIn,
    };
  }

  async refreshTokens(refreshToken: string): Promise<LoginResponseDto> {
    const tokenHash = this.hashToken(refreshToken);

    const storedToken = await this.prisma.refreshToken.findFirst({
      where: { tokenHash },
      include: { user: true },
    });

    if (!storedToken) {
      throw new UnauthorizedException('Invalid refresh token');
    }

    if (storedToken.revokedAt) {
      // SEC-AUDIT: Potential token theft - log as security incident
      await this.auditService.log({
        actorType: ActorType.STAFF,
        actorId: storedToken.userId,
        action: AuditActions.STAFF_TOKEN_REUSE_DETECTED,
        entityType: AuditEntityType.AUTH,
        metadata: { reason: 'revoked_token_reuse', severity: 'high' },
      });
      this.logger.warn('Revoked token reuse detected for user: ' + storedToken.userId);
      await this.revokeAllUserTokens(storedToken.userId);
      throw new UnauthorizedException('Refresh token has been revoked. Please login again.');
    }

    if (new Date() > storedToken.expiresAt) {
      await this.prisma.refreshToken.update({
        where: { id: storedToken.id },
        data: { revokedAt: new Date() },
      });
      throw new UnauthorizedException('Refresh token has expired');
    }

    if (!storedToken.user.isActive) {
      throw new UnauthorizedException('User account is deactivated');
    }

    await this.prisma.refreshToken.update({
      where: { id: storedToken.id },
      data: { revokedAt: new Date() },
    });

    const { passwordHash: _, ...userWithoutPassword } = storedToken.user;
    return this.login(userWithoutPassword);
  }

  async logout(refreshToken: string, userId?: string): Promise<boolean> {
    const tokenHash = this.hashToken(refreshToken);

    // Find token first to get userId for audit if not provided
    const token = await this.prisma.refreshToken.findFirst({
      where: { tokenHash },
      select: { userId: true },
    });

    const result = await this.prisma.refreshToken.updateMany({
      where: {
        tokenHash,
        revokedAt: null,
      },
      data: {
        revokedAt: new Date(),
      },
    });

    if (result.count === 0) {
      this.logger.debug('Logout with invalid or already revoked token');
    } else {
      // SEC-AUDIT: Log successful logout for session tracking
      const actorId = userId || token?.userId;
      if (actorId) {
        await this.auditService.log({
          actorType: ActorType.STAFF,
          actorId,
          action: AuditActions.STAFF_LOGOUT,
          entityType: AuditEntityType.AUTH,
        });
      }
    }

    return true;
  }

  async updateProfile(userId: string, dto: UpdateProfileDto): Promise<UserResponseDto> {
    // Parse fullName into firstName and lastName
    const nameParts = dto.fullName.trim().split(/\s+/);
    const firstName = nameParts[0];
    const lastName = nameParts.length > 1 ? nameParts.slice(1).join(' ') : null;

    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data: {
        firstName,
        lastName,
      },
    });

    this.logger.log(`Profile updated for user: ${updatedUser.id}`);

    return {
      id: updatedUser.id,
      email: updatedUser.email,
      firstName: updatedUser.firstName ?? undefined,
      lastName: updatedUser.lastName ?? undefined,
      phone: updatedUser.phone ?? undefined,
      organization: updatedUser.organization ?? undefined,
      avatarUrl: updatedUser.avatarUrl ?? undefined,
      emailVerified: updatedUser.emailVerified,
      role: updatedUser.role,
      isActive: updatedUser.isActive,
      createdAt: updatedUser.createdAt,
    };
  }

  async changePassword(userId: string, dto: ChangePasswordDto): Promise<{ success: boolean }> {
    // Fetch user with password hash
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new BadRequestException('User not found');
    }

    // Verify current password
    const isCurrentPasswordValid = await bcrypt.compare(dto.currentPassword, user.passwordHash);
    if (!isCurrentPasswordValid) {
      throw new UnauthorizedException('Current password is incorrect');
    }

    // Ensure new password is different from current
    const isSamePassword = await bcrypt.compare(dto.newPassword, user.passwordHash);
    if (isSamePassword) {
      throw new BadRequestException('New password must be different from current password');
    }

    // Hash new password
    const saltRounds = this.configService.get<number>('BCRYPT_SALT_ROUNDS') || 12;
    const newPasswordHash = await bcrypt.hash(dto.newPassword, saltRounds);

    // Update password in database
    await this.prisma.user.update({
      where: { id: userId },
      data: { passwordHash: newPasswordHash },
    });

    // Invalidate all refresh tokens for this user (force re-login on other devices)
    await this.revokeAllUserTokens(userId);

    // SEC-AUDIT: Log password change for compliance (credential change is high-risk)
    await this.auditService.log({
      actorType: ActorType.STAFF,
      actorId: userId,
      action: AuditActions.STAFF_PASSWORD_CHANGED,
      entityType: AuditEntityType.AUTH,
      metadata: { tokensRevoked: true },
    });

    this.logger.log(`Password changed for user: ${userId}`);

    return { success: true };
  }

  /**
   * Request a password reset email.
   * SECURITY: Always return success even if email not found (prevent enumeration).
   * SECURITY: Invalidate any existing reset tokens before creating new one.
   * SECURITY: Store only hashed token in database.
   */
  async forgotPassword(dto: ForgotPasswordDto): Promise<{ success: boolean }> {
    const email = dto.email.toLowerCase();

    // Find user (but don't reveal if exists)
    const user = await this.prisma.user.findUnique({
      where: { email },
    });

    // SECURITY: Always return success even if user not found
    // This prevents email enumeration attacks
    if (!user) {
      this.logger.log('Password reset requested for unknown account');
      return { success: true };
    }

    if (!user.isActive) {
      this.logger.log(`Password reset requested for deactivated account: ${user.id}`);
      return { success: true };
    }

    // Generate cryptographically secure token (32 bytes = 64 hex chars)
    const plainToken = crypto.randomBytes(32).toString('hex');
    const tokenHash = this.hashToken(plainToken);

    // Set expiry (15 minutes from now)
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + this.RESET_TOKEN_EXPIRY_MINUTES);

    // Store hashed token in database (invalidates any previous token)
    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        resetPasswordToken: tokenHash,
        resetPasswordExpiresAt: expiresAt,
      },
    });

    // Send reset email with plain token
    try {
      await this.emailService.sendPasswordResetEmail(
        user.email,
        user.firstName || 'User',
        plainToken,
      );
      this.logger.log(`Password reset email sent to user: ${user.id}`);
    } catch (error) {
      this.logger.error(`Failed to send password reset email: ${error}`);
      // Don't throw - we don't want to reveal if email sending failed
    }

    return { success: true };
  }

  /**
   * Reset password with token.
   * SECURITY: Token is single-use (cleared after successful reset).
   * SECURITY: Revoke all refresh tokens after password change.
   * SECURITY: Check token expiry.
   */
  async resetPassword(dto: ResetPasswordDto): Promise<{ success: boolean }> {
    const tokenHash = this.hashToken(dto.token);

    // Find user with matching token
    const user = await this.prisma.user.findFirst({
      where: {
        resetPasswordToken: tokenHash,
        resetPasswordExpiresAt: { gte: new Date() }, // Not expired
      },
    });

    if (!user) {
      throw new BadRequestException(
        'Invalid or expired reset token. Please request a new password reset.',
      );
    }

    if (!user.isActive) {
      throw new BadRequestException('Account is deactivated');
    }

    // Hash new password
    const saltRounds = this.configService.get<number>('BCRYPT_SALT_ROUNDS') || 12;
    const newPasswordHash = await bcrypt.hash(dto.newPassword, saltRounds);

    // Update password and clear reset token (single-use)
    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        passwordHash: newPasswordHash,
        resetPasswordToken: null,
        resetPasswordExpiresAt: null,
      },
    });

    // Revoke all refresh tokens (force re-login on all devices)
    await this.revokeAllUserTokens(user.id);

    // SEC-AUDIT: Log password reset completion (credential change via reset flow)
    await this.auditService.log({
      actorType: ActorType.STAFF,
      actorId: user.id,
      action: AuditActions.STAFF_PASSWORD_RESET,
      entityType: AuditEntityType.AUTH,
      metadata: { tokensRevoked: true, method: 'email_reset_link' },
    });

    this.logger.log(`Password reset completed for user: ${user.id}`);

    return { success: true };
  }

  async uploadProfileImage(userId: string, file: UploadedFile): Promise<UserResponseDto> {
    // Validate file size
    if (file.size > this.maxImageSize) {
      throw new BadRequestException(
        `Image too large. Maximum size: ${this.maxImageSize / 1024 / 1024}MB`,
      );
    }

    // Validate mime type
    if (!this.allowedMimeTypes.includes(file.mimetype)) {
      throw new BadRequestException(
        `Invalid file type. Allowed types: ${this.allowedMimeTypes.join(', ')}`,
      );
    }

    // Get current user to check for existing avatar
    const currentUser = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!currentUser) {
      throw new BadRequestException('User not found');
    }

    // Delete old avatar if exists
    if (currentUser.avatarUrl) {
      try {
        // Extract storage path from URL (format: /api/v1/auth/profile/image/{path})
        const oldPath = this.extractStoragePathFromUrl(currentUser.avatarUrl);
        if (oldPath) {
          await this.storageService.delete(oldPath);
          this.logger.log(`Deleted old avatar: ${oldPath}`);
        }
      } catch (error) {
        this.logger.warn(`Failed to delete old avatar: ${error}`);
        // Continue even if delete fails
      }
    }

    // Generate file ID and get extension
    const fileId = crypto.randomUUID();
    const extension = this.getExtensionFromMime(file.mimetype);

    // Store file in profiles/{userId}/{fileId}.{ext}
    let storagePath: string;
    try {
      storagePath = await this.storageService.store(
        `profiles/${userId}`,
        fileId,
        file.buffer,
        extension,
      );
    } catch (error) {
      this.logger.error(`Failed to store profile image: ${error}`);
      throw new BadRequestException('Failed to save profile image. Please try again.');
    }

    // Generate the URL for the avatar using configured API prefix
    const avatarUrl = this.urlBuilder.build('/auth/profile/image', storagePath);

    // Update user with new avatar URL
    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data: { avatarUrl },
    });

    this.logger.log(`Profile image updated for user: ${updatedUser.id}`);

    return {
      id: updatedUser.id,
      email: updatedUser.email,
      firstName: updatedUser.firstName ?? undefined,
      lastName: updatedUser.lastName ?? undefined,
      phone: updatedUser.phone ?? undefined,
      organization: updatedUser.organization ?? undefined,
      avatarUrl: updatedUser.avatarUrl ?? undefined,
      emailVerified: updatedUser.emailVerified,
      role: updatedUser.role,
      isActive: updatedUser.isActive,
      createdAt: updatedUser.createdAt,
    };
  }

  async getProfileImagePath(storagePath: string): Promise<{ path: string; mimeType: string }> {
    // Security: Validate path format
    if (!storagePath.startsWith('profiles/')) {
      throw new BadRequestException('Invalid image path');
    }

    const absolutePath = this.storageService.getAbsolutePath(storagePath);

    // Verify file exists before streaming
    if (!fs.existsSync(absolutePath)) {
      throw new NotFoundException('Image not found');
    }

    const extension = path.extname(storagePath).toLowerCase();
    const mimeType = extension === '.png' ? 'image/png' : 'image/jpeg';

    return { path: absolutePath, mimeType };
  }

  async deleteProfileImage(userId: string): Promise<UserResponseDto> {
    const currentUser = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!currentUser) {
      throw new BadRequestException('User not found');
    }

    // Delete avatar file if exists
    if (currentUser.avatarUrl) {
      try {
        const storagePath = this.extractStoragePathFromUrl(currentUser.avatarUrl);
        if (storagePath) {
          await this.storageService.delete(storagePath);
          this.logger.log(`Deleted avatar: ${storagePath}`);
        }
      } catch (error) {
        this.logger.warn(`Failed to delete avatar: ${error}`);
      }
    }

    // Update user to remove avatar URL
    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data: { avatarUrl: null },
    });

    this.logger.log(`Profile image deleted for user: ${updatedUser.id}`);

    return {
      id: updatedUser.id,
      email: updatedUser.email,
      firstName: updatedUser.firstName ?? undefined,
      lastName: updatedUser.lastName ?? undefined,
      phone: updatedUser.phone ?? undefined,
      organization: updatedUser.organization ?? undefined,
      avatarUrl: updatedUser.avatarUrl ?? undefined,
      emailVerified: updatedUser.emailVerified,
      role: updatedUser.role,
      isActive: updatedUser.isActive,
      createdAt: updatedUser.createdAt,
    };
  }

  /**
   * Extract storage path from avatar URL.
   * Uses a robust pattern-based approach that doesn't depend on hardcoded API paths.
   * Supports reverse proxies, versioned APIs, and path structure changes.
   *
   * Storage paths always start with 'profiles/' - we extract everything from that point.
   */
  private extractStoragePathFromUrl(url: string): string | null {
    // Pattern 1: Look for 'profiles/' which is our storage path prefix
    // This works regardless of API version or proxy configuration
    const profilesIndex = url.indexOf('profiles/');
    if (profilesIndex !== -1) {
      return url.substring(profilesIndex);
    }

    // Pattern 2: Fallback - extract last path segment if it looks like a storage path
    // Handles URLs like: /api/v1/auth/profile/image/profiles/userId/fileId.jpg
    // or: /custom/proxy/path/profiles/userId/fileId.jpg
    const segments = url.split('/').filter(Boolean);
    const profilesSegmentIndex = segments.findIndex((s) => s === 'profiles');
    if (profilesSegmentIndex !== -1) {
      return segments.slice(profilesSegmentIndex).join('/');
    }

    // Pattern 3: If URL doesn't contain 'profiles/', it might be a legacy format
    // Return null to indicate extraction failed (caller should handle gracefully)
    this.logger.warn(`Could not extract storage path from URL: ${url}`);
    return null;
  }

  private getExtensionFromMime(mimeType: string): string {
    const mimeToExt: Record<string, string> = {
      'image/jpeg': 'jpg',
      'image/png': 'png',
    };
    return mimeToExt[mimeType] || 'jpg';
  }

  async revokeAllUserTokens(userId: string): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: {
        userId,
        revokedAt: null,
      },
      data: {
        revokedAt: new Date(),
      },
    });
  }

  private generateRefreshToken(): string {
    return crypto.randomBytes(64).toString('hex');
  }

  private hashToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }

  private async storeRefreshToken(userId: string, token: string): Promise<void> {
    const tokenHash = this.hashToken(token);
    const expiresDays = this.configService.get<number>('REFRESH_TOKEN_EXPIRES_DAYS') || 7;
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + expiresDays);

    await this.prisma.refreshToken.create({
      data: {
        userId,
        tokenHash,
        expiresAt,
      },
    });

    await this.prisma.refreshToken.deleteMany({
      where: {
        userId,
        expiresAt: { lt: new Date() },
      },
    });
  }

  private parseExpirationToSeconds(expiration: string): number {
    const match = expiration.match(/^(\d+)([smhd])$/);
    if (!match) {
      return 900;
    }

    const value = parseInt(match[1], 10);
    const unit = match[2];

    switch (unit) {
      case 's':
        return value;
      case 'm':
        return value * 60;
      case 'h':
        return value * 3600;
      case 'd':
        return value * 86400;
      default:
        return 900;
    }
  }
}
