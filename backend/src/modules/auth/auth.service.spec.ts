import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { AuthService } from './auth.service';
import { PrismaService } from '../prisma/prisma.service';
import { EmailService } from './email.service';
import { AuditService } from '../audit/audit.service';
import { STORAGE_SERVICE } from '../media/storage/storage.interface';

jest.mock('bcrypt');

describe('AuthService', () => {
  let service: AuthService;
  let prismaService: jest.Mocked<PrismaService>;
  let jwtService: jest.Mocked<JwtService>;
  let configService: jest.Mocked<ConfigService>;

  const mockUser = {
    id: 'user-uuid-123',
    email: 'test@example.com',
    passwordHash: 'hashed-password',
    firstName: 'Test',
    lastName: 'User',
    phone: null,
    organization: null,
    avatarUrl: null,
    emailVerified: false,
    role: UserRole.SURVEYOR,
    isActive: true,
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-01'),
    lastLoginAt: null,
  };

  const mockPrismaService = {
    user: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    refreshToken: {
      findFirst: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
      deleteMany: jest.fn(),
    },
  };

  const mockJwtService = {
    sign: jest.fn(),
  };

  const mockConfigService = {
    get: jest.fn(),
  };

  const mockEmailService = {
    sendPasswordResetEmail: jest.fn(),
    sendWelcomeEmail: jest.fn(),
  };

  const mockStorageService = {
    uploadFile: jest.fn(),
    deleteFile: jest.fn(),
    getSignedUrl: jest.fn(),
  };

  const mockAuditService = {
    log: jest.fn(),
    query: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: JwtService, useValue: mockJwtService },
        { provide: ConfigService, useValue: mockConfigService },
        { provide: STORAGE_SERVICE, useValue: mockStorageService },
        { provide: EmailService, useValue: mockEmailService },
        { provide: AuditService, useValue: mockAuditService },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
    prismaService = module.get(PrismaService);
    jwtService = module.get(JwtService);
    configService = module.get(ConfigService);

    mockConfigService.get.mockImplementation((key: string) => {
      const config: Record<string, string | number> = {
        BCRYPT_SALT_ROUNDS: 10,
        JWT_ACCESS_SECRET: 'test-secret',
        JWT_ACCESS_EXPIRES_IN: '15m',
        REFRESH_TOKEN_EXPIRES_DAYS: 7,
      };
      return config[key];
    });
  });

  describe('register', () => {
    it('should register a new user successfully', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(null);
      (bcrypt.hash as jest.Mock).mockResolvedValue('hashed-password');
      mockPrismaService.user.create.mockResolvedValue(mockUser);

      const result = await service.register({
        email: 'test@example.com',
        password: 'password123',
        firstName: 'Test',
        lastName: 'User',
      });

      expect(result).toEqual({
        id: mockUser.id,
        email: mockUser.email,
        role: mockUser.role,
      });
      expect(mockPrismaService.user.findUnique).toHaveBeenCalledWith({
        where: { email: 'test@example.com' },
      });
      expect(mockPrismaService.user.create).toHaveBeenCalled();
    });

    it('should throw ConflictException if email already registered', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(mockUser);

      await expect(
        service.register({
          email: 'test@example.com',
          password: 'password123',
          firstName: 'Test',
          lastName: 'User',
        }),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe('validateUser', () => {
    it('should return user without password if credentials are valid', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(mockUser);
      (bcrypt.compare as jest.Mock).mockResolvedValue(true);
      mockPrismaService.user.update.mockResolvedValue(mockUser);

      const result = await service.validateUser('test@example.com', 'password123');

      expect(result).toBeDefined();
      expect(result?.email).toBe(mockUser.email);
      expect((result as Record<string, unknown>)?.passwordHash).toBeUndefined();
    });

    it('should return null if user not found', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(null);

      const result = await service.validateUser('nonexistent@example.com', 'password123');

      expect(result).toBeNull();
    });

    it('should return null if password is invalid', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(mockUser);
      (bcrypt.compare as jest.Mock).mockResolvedValue(false);

      const result = await service.validateUser('test@example.com', 'wrongpassword');

      expect(result).toBeNull();
    });

    it('should throw UnauthorizedException if user is deactivated', async () => {
      const inactiveUser = { ...mockUser, isActive: false };
      mockPrismaService.user.findUnique.mockResolvedValue(inactiveUser);

      await expect(
        service.validateUser('test@example.com', 'password123'),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('login', () => {
    it('should return tokens and user data', async () => {
      const userWithoutPassword = { ...mockUser };
      delete (userWithoutPassword as Record<string, unknown>).passwordHash;

      mockJwtService.sign.mockReturnValue('access-token');
      mockPrismaService.refreshToken.create.mockResolvedValue({
        id: 'token-id',
        tokenHash: 'hash',
        userId: mockUser.id,
        expiresAt: new Date(),
        revokedAt: null,
        createdAt: new Date(),
      });
      mockPrismaService.refreshToken.deleteMany.mockResolvedValue({ count: 0 });

      const result = await service.login(userWithoutPassword as any);

      expect(result).toHaveProperty('accessToken', 'access-token');
      expect(result).toHaveProperty('refreshToken');
      expect(result).toHaveProperty('expiresIn', 900);
      expect(result).toHaveProperty('user');
      expect(result.user.id).toBe(mockUser.id);
      expect(result.user.email).toBe(mockUser.email);
    });
  });

  describe('refreshTokens', () => {
    it('should return new tokens when refresh token is valid', async () => {
      const storedToken = {
        id: 'token-id',
        tokenHash: 'hash',
        userId: mockUser.id,
        expiresAt: new Date(Date.now() + 86400000),
        revokedAt: null,
        createdAt: new Date(),
        user: mockUser,
      };

      mockPrismaService.refreshToken.findFirst.mockResolvedValue(storedToken);
      mockPrismaService.refreshToken.update.mockResolvedValue({
        ...storedToken,
        revokedAt: new Date(),
      });
      mockJwtService.sign.mockReturnValue('new-access-token');
      mockPrismaService.refreshToken.create.mockResolvedValue({
        id: 'new-token-id',
        tokenHash: 'new-hash',
        userId: mockUser.id,
        expiresAt: new Date(),
        revokedAt: null,
        createdAt: new Date(),
      });
      mockPrismaService.refreshToken.deleteMany.mockResolvedValue({ count: 0 });

      const result = await service.refreshTokens('valid-refresh-token');

      expect(result).toHaveProperty('accessToken', 'new-access-token');
      expect(result).toHaveProperty('user');
    });

    it('should throw UnauthorizedException if token not found', async () => {
      mockPrismaService.refreshToken.findFirst.mockResolvedValue(null);

      await expect(service.refreshTokens('invalid-token')).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('should throw UnauthorizedException if token is revoked', async () => {
      const revokedToken = {
        id: 'token-id',
        tokenHash: 'hash',
        userId: mockUser.id,
        expiresAt: new Date(Date.now() + 86400000),
        revokedAt: new Date(),
        createdAt: new Date(),
        user: mockUser,
      };

      mockPrismaService.refreshToken.findFirst.mockResolvedValue(revokedToken);
      mockPrismaService.refreshToken.updateMany.mockResolvedValue({ count: 1 });

      await expect(service.refreshTokens('revoked-token')).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('should throw UnauthorizedException if token is expired', async () => {
      const expiredToken = {
        id: 'token-id',
        tokenHash: 'hash',
        userId: mockUser.id,
        expiresAt: new Date(Date.now() - 86400000),
        revokedAt: null,
        createdAt: new Date(),
        user: mockUser,
      };

      mockPrismaService.refreshToken.findFirst.mockResolvedValue(expiredToken);
      mockPrismaService.refreshToken.update.mockResolvedValue({
        ...expiredToken,
        revokedAt: new Date(),
      });

      await expect(service.refreshTokens('expired-token')).rejects.toThrow(
        UnauthorizedException,
      );
    });
  });

  describe('logout', () => {
    it('should revoke the refresh token', async () => {
      mockPrismaService.refreshToken.updateMany.mockResolvedValue({ count: 1 });

      const result = await service.logout('refresh-token');

      expect(result).toBe(true);
      expect(mockPrismaService.refreshToken.updateMany).toHaveBeenCalled();
    });

    it('should return true even if token was already revoked', async () => {
      mockPrismaService.refreshToken.updateMany.mockResolvedValue({ count: 0 });

      const result = await service.logout('already-revoked-token');

      expect(result).toBe(true);
    });
  });
});
