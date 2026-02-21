import {
  Controller,
  Post,
  Get,
  Patch,
  Delete,
  Body,
  Param,
  HttpCode,
  HttpStatus,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  UnauthorizedException,
  BadRequestException,
  Res,
  StreamableFile,
  Req,
} from '@nestjs/common';
import { Request } from 'express';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiBody,
  ApiConsumes,
} from '@nestjs/swagger';
import { Response } from 'express';
import * as fs from 'fs';
import { Throttle, SkipThrottle } from '@nestjs/throttler';
import { User, ActorType, AuditEntityType } from '@prisma/client';
import { AuthService } from './auth.service';
import { AuditService, AuditActions } from '../audit/audit.service';
import { RegisterDto, LoginDto, RefreshDto, UpdateProfileDto, ChangePasswordDto, ForgotPasswordDto, ResetPasswordDto } from './dto';
import {
  LoginResponseDto,
  RegisterResponseDto,
  UserResponseDto,
  LogoutResponseDto,
} from './dto/auth-response.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { CurrentUser } from './decorators/current-user.decorator';
import { Public } from './decorators/public.decorator';

interface MulterFile {
  fieldname: string;
  originalname: string;
  encoding: string;
  mimetype: string;
  size: number;
  buffer: Buffer;
}

@ApiTags('Authentication')
@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly auditService: AuditService,
  ) {}

  @Public()
  @Post('register')
  @Throttle({ default: { limit: 3, ttl: 60000 } }) // 3 registrations per minute per IP
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Register a new user' })
  @ApiResponse({
    status: 201,
    description: 'User registered successfully',
    type: RegisterResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Validation error' })
  @ApiResponse({ status: 409, description: 'Email already registered' })
  async register(@Body() dto: RegisterDto): Promise<RegisterResponseDto> {
    return this.authService.register(dto);
  }

  @Public()
  @Post('login')
  @Throttle({ default: { limit: 5, ttl: 60000 } }) // 5 login attempts per minute per IP
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Login with email and password' })
  @ApiBody({ type: LoginDto })
  @ApiResponse({
    status: 200,
    description: 'Login successful - returns user object with tokens',
    type: LoginResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Invalid credentials' })
  async login(@Body() dto: LoginDto, @Req() req: Request): Promise<LoginResponseDto> {
    const user = await this.authService.validateUser(dto.email, dto.password);
    if (!user) {
      // SEC-001: Audit failed login attempts for SOC2/OWASP compliance
      await this.auditService.log({
        actorType: ActorType.STAFF,
        action: AuditActions.LOGIN_FAILED,
        entityType: AuditEntityType.AUTH,
        metadata: { attemptedEmail: dto.email },
        request: req,
      });
      throw new UnauthorizedException('Invalid email or password');
    }
    return this.authService.login(user);
  }

  @Public()
  @Post('refresh')
  @Throttle({ default: { limit: 20, ttl: 60000 } }) // 20 refreshes per minute per IP (supports mobile background sync)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Refresh access token using refresh token' })
  @ApiResponse({
    status: 200,
    description: 'Tokens refreshed successfully - returns user object with new tokens',
    type: LoginResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Invalid or expired refresh token' })
  async refresh(@Body() dto: RefreshDto): Promise<LoginResponseDto> {
    return this.authService.refreshTokens(dto.refreshToken);
  }

  @Post('logout')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Logout and revoke refresh token',
    description: 'Requires valid access token to prove caller identity. Revokes the provided refresh token.',
  })
  @ApiResponse({
    status: 200,
    description: 'Logged out successfully',
    type: LogoutResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized — valid access token required' })
  async logout(
    @Body() dto: RefreshDto,
    @CurrentUser() user: Omit<User, 'passwordHash'>,
  ): Promise<LogoutResponseDto> {
    await this.authService.logout(dto.refreshToken, user.id);
    return { success: true };
  }

  @Public()
  @Post('forgot-password')
  @Throttle({ default: { limit: 3, ttl: 60000 } }) // 3 requests per minute per IP
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Request password reset',
    description: 'Send a password reset email. Always returns success to prevent email enumeration.',
  })
  @ApiResponse({
    status: 200,
    description: 'Password reset email sent (if email exists)',
    schema: {
      type: 'object',
      properties: {
        success: { type: 'boolean', example: true },
        message: { type: 'string', example: 'If this email exists, a password reset link has been sent.' },
      },
    },
  })
  @ApiResponse({ status: 400, description: 'Validation error' })
  @ApiResponse({ status: 429, description: 'Too many requests' })
  async forgotPassword(@Body() dto: ForgotPasswordDto): Promise<{ success: boolean; message: string }> {
    await this.authService.forgotPassword(dto);
    // Always return same message to prevent email enumeration
    return {
      success: true,
      message: 'If this email exists, a password reset link has been sent.',
    };
  }

  @Public()
  @Post('reset-password')
  @Throttle({ default: { limit: 5, ttl: 60000 } }) // 5 attempts per minute per IP
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Reset password with token',
    description: 'Reset password using the token from the email link. Token expires after 15 minutes.',
  })
  @ApiResponse({
    status: 200,
    description: 'Password reset successfully',
    schema: {
      type: 'object',
      properties: {
        success: { type: 'boolean', example: true },
        message: { type: 'string', example: 'Password has been reset successfully. Please login with your new password.' },
      },
    },
  })
  @ApiResponse({ status: 400, description: 'Invalid or expired token' })
  @ApiResponse({ status: 429, description: 'Too many requests' })
  async resetPassword(@Body() dto: ResetPasswordDto): Promise<{ success: boolean; message: string }> {
    await this.authService.resetPassword(dto);
    return {
      success: true,
      message: 'Password has been reset successfully. Please login with your new password.',
    };
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Get current authenticated user' })
  @ApiResponse({
    status: 200,
    description: 'Current user profile',
    type: UserResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async me(@CurrentUser() user: Omit<User, 'passwordHash'>): Promise<UserResponseDto> {
    return {
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
  }

  @Patch('profile')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({ summary: 'Update current user profile' })
  @ApiResponse({
    status: 200,
    description: 'Profile updated successfully',
    type: UserResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Validation error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async updateProfile(
    @CurrentUser() user: Omit<User, 'passwordHash'>,
    @Body() dto: UpdateProfileDto,
  ): Promise<UserResponseDto> {
    return this.authService.updateProfile(user.id, dto);
  }

  @Patch('change-password')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Change user password',
    description: 'Change the current user password. Requires current password verification. Invalidates all other sessions.',
  })
  @ApiResponse({
    status: 200,
    description: 'Password changed successfully',
    schema: {
      type: 'object',
      properties: {
        success: { type: 'boolean', example: true },
      },
    },
  })
  @ApiResponse({ status: 400, description: 'Validation error or same password' })
  @ApiResponse({ status: 401, description: 'Current password incorrect' })
  async changePassword(
    @CurrentUser() user: Omit<User, 'passwordHash'>,
    @Body() dto: ChangePasswordDto,
  ): Promise<{ success: boolean }> {
    return this.authService.changePassword(user.id, dto);
  }

  @Patch('profile/image')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FileInterceptor('image'))
  @ApiBearerAuth('JWT-auth')
  @ApiConsumes('multipart/form-data')
  @ApiOperation({
    summary: 'Upload profile image',
    description: 'Upload a profile image. Accepts JPG/PNG, max 5MB. Replaces existing image if any.',
  })
  @ApiBody({
    schema: {
      type: 'object',
      required: ['image'],
      properties: {
        image: {
          type: 'string',
          format: 'binary',
          description: 'Profile image file (JPG or PNG, max 5MB)',
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Profile image uploaded successfully',
    type: UserResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Invalid file type or size' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async uploadProfileImage(
    @CurrentUser() user: Omit<User, 'passwordHash'>,
    @UploadedFile() file: MulterFile,
  ): Promise<UserResponseDto> {
    if (!file) {
      throw new BadRequestException('No image file provided');
    }
    return this.authService.uploadProfileImage(user.id, {
      originalname: file.originalname,
      mimetype: file.mimetype,
      size: file.size,
      buffer: file.buffer,
    });
  }

  @Get('profile/image/*')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @SkipThrottle()
  @ApiOperation({
    summary: 'Get profile image',
    description:
      'Stream the profile image file. Requires authentication — profile images are PII. ' +
      'Path is validated server-side to only serve files from the profiles/ directory (no directory traversal).',
  })
  @ApiResponse({
    status: 200,
    description: 'Profile image file stream',
    content: {
      'image/jpeg': { schema: { type: 'string', format: 'binary' } },
      'image/png': { schema: { type: 'string', format: 'binary' } },
    },
  })
  @ApiResponse({ status: 400, description: 'Invalid path' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 404, description: 'Image not found' })
  async getProfileImage(
    @Param('0') imagePath: string,
    @Res({ passthrough: true }) res: Response,
  ): Promise<StreamableFile> {
    const fileInfo = await this.authService.getProfileImagePath(imagePath);

    res.set({
      'Content-Type': fileInfo.mimeType,
      'Cache-Control': 'public, max-age=86400',
    });

    const fileStream = fs.createReadStream(fileInfo.path);
    return new StreamableFile(fileStream);
  }

  @Delete('profile/image')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT-auth')
  @ApiOperation({
    summary: 'Delete profile image',
    description: 'Remove the current profile image',
  })
  @ApiResponse({
    status: 200,
    description: 'Profile image deleted successfully',
    type: UserResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async deleteProfileImage(
    @CurrentUser() user: Omit<User, 'passwordHash'>,
  ): Promise<UserResponseDto> {
    return this.authService.deleteProfileImage(user.id);
  }
}
