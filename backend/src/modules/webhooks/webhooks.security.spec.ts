import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { WebhooksService } from './webhooks.service';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';

// Mock dns.lookup so that promisify(dns.lookup) returns { address, family }
// like the real Node.js dns module.
//
// Node's dns.lookup has a custom promisify handler that returns { address, family }.
// We replicate this via util.promisify.custom on the mock.
const mockDnsLookup = jest.fn();

jest.mock('dns', () => {
  const { promisify } = require('util');
  const fakeLookup: any = (hostname: string, callback: Function) => {
    mockDnsLookup(hostname, callback);
  };
  fakeLookup[promisify.custom] = (hostname: string) => {
    return new Promise((resolve, reject) => {
      mockDnsLookup(hostname, (err: Error | null, address: string, family: number) => {
        if (err) return reject(err);
        resolve({ address, family });
      });
    });
  };
  return { lookup: fakeLookup };
});

/**
 * SEC-004: SSRF Protection Tests
 * SEC-005: HTTPS Enforcement Tests
 * Verifies that webhook URL validation blocks internal/private IP addresses
 * and enforces HTTPS in production environments
 */
describe('WebhooksService - Security Tests (SEC-004, SEC-005)', () => {
  let service: WebhooksService;
  let mockConfigService: { get: jest.Mock };

  const mockPrismaService = {
    webhook: {
      create: jest.fn(),
      findUnique: jest.fn(),
      findMany: jest.fn(),
      update: jest.fn(),
    },
    webhookDelivery: {
      create: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
    },
  };

  const mockAuditService = {
    log: jest.fn(),
  };

  const mockUser = { id: 'user-123', email: 'test@example.com' };

  /**
   * Helper to create service with specific NODE_ENV
   */
  async function createServiceWithEnv(nodeEnv: string): Promise<WebhooksService> {
    mockConfigService = {
      get: jest.fn((key: string) => (key === 'NODE_ENV' ? nodeEnv : undefined)),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WebhooksService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: AuditService, useValue: mockAuditService },
        { provide: ConfigService, useValue: mockConfigService },
      ],
    }).compile();

    return module.get<WebhooksService>(WebhooksService);
  }

  beforeEach(async () => {
    jest.clearAllMocks();
    // Default to development mode
    service = await createServiceWithEnv('development');
  });

  describe('createWebhook - URL validation', () => {
    it('should allow valid external HTTPS URL', async () => {
      mockDnsLookup.mockImplementation((hostname: string, callback: Function) => {
        callback(null, '203.0.113.1', 4); // Public IP
      });

      mockPrismaService.webhook.create.mockResolvedValue({
        id: 'webhook-1',
        url: 'https://example.com/webhook',
        secretHash: 'hash',
        events: ['BOOKING_CREATED'],
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const result = await service.createWebhook(
        { url: 'https://example.com/webhook', events: ['BOOKING_CREATED'] as any },
        mockUser,
      );

      expect(result).toBeDefined();
      expect(result.url).toBe('https://example.com/webhook');
    });

    it('should block localhost URL', async () => {
      await expect(
        service.createWebhook(
          { url: 'https://localhost/webhook', events: ['BOOKING_CREATED'] as any },
          mockUser,
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it('should block 127.0.0.1 URL', async () => {
      await expect(
        service.createWebhook(
          { url: 'https://127.0.0.1/webhook', events: ['BOOKING_CREATED'] as any },
          mockUser,
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it('should block hostname resolving to private IP (10.x.x.x)', async () => {
      mockDnsLookup.mockImplementation((hostname: string, callback: Function) => {
        callback(null, '10.0.0.1', 4);
      });

      await expect(
        service.createWebhook(
          { url: 'https://internal.example.com/webhook', events: ['BOOKING_CREATED'] as any },
          mockUser,
        ),
      ).rejects.toThrow('Webhook URL cannot target internal/private networks');
    });

    it('should block hostname resolving to private IP (172.16.x.x)', async () => {
      mockDnsLookup.mockImplementation((hostname: string, callback: Function) => {
        callback(null, '172.16.0.1', 4);
      });

      await expect(
        service.createWebhook(
          { url: 'https://internal.example.com/webhook', events: ['BOOKING_CREATED'] as any },
          mockUser,
        ),
      ).rejects.toThrow('Webhook URL cannot target internal/private networks');
    });

    it('should block hostname resolving to private IP (192.168.x.x)', async () => {
      mockDnsLookup.mockImplementation((hostname: string, callback: Function) => {
        callback(null, '192.168.1.1', 4);
      });

      await expect(
        service.createWebhook(
          { url: 'https://internal.example.com/webhook', events: ['BOOKING_CREATED'] as any },
          mockUser,
        ),
      ).rejects.toThrow('Webhook URL cannot target internal/private networks');
    });

    it('should block hostname resolving to link-local IP (169.254.x.x)', async () => {
      mockDnsLookup.mockImplementation((hostname: string, callback: Function) => {
        callback(null, '169.254.169.254', 4); // AWS metadata endpoint
      });

      await expect(
        service.createWebhook(
          { url: 'https://metadata.example.com/webhook', events: ['BOOKING_CREATED'] as any },
          mockUser,
        ),
      ).rejects.toThrow('Webhook URL cannot target internal/private networks');
    });

    it('should block invalid URL format', async () => {
      await expect(
        service.createWebhook(
          { url: 'not-a-valid-url', events: ['BOOKING_CREATED'] as any },
          mockUser,
        ),
      ).rejects.toThrow('Invalid URL format');
    });

    it('should block non-HTTP protocols', async () => {
      await expect(
        service.createWebhook(
          { url: 'ftp://example.com/webhook', events: ['BOOKING_CREATED'] as any },
          mockUser,
        ),
      ).rejects.toThrow('Only HTTP/HTTPS URLs are allowed');
    });
  });

  /**
   * SEC-005: HTTPS Enforcement Tests
   * Verifies that HTTP URLs are rejected in production environments
   */
  describe('SEC-005: HTTPS Enforcement in Production', () => {
    it('should REJECT HTTP URL in production environment', async () => {
      // Create service in production mode
      service = await createServiceWithEnv('production');

      await expect(
        service.createWebhook(
          { url: 'http://example.com/webhook', events: ['BOOKING_CREATED'] as any },
          mockUser,
        ),
      ).rejects.toThrow('Webhook URLs must use HTTPS in production');
    });

    it('should ALLOW HTTPS URL in production environment', async () => {
      // Create service in production mode
      service = await createServiceWithEnv('production');

      mockDnsLookup.mockImplementation((hostname: string, callback: Function) => {
        callback(null, '203.0.113.1', 4); // Public IP
      });

      mockPrismaService.webhook.create.mockResolvedValue({
        id: 'webhook-1',
        url: 'https://example.com/webhook',
        secretHash: 'hash',
        events: ['BOOKING_CREATED'],
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const result = await service.createWebhook(
        { url: 'https://example.com/webhook', events: ['BOOKING_CREATED'] as any },
        mockUser,
      );

      expect(result).toBeDefined();
      expect(result.url).toBe('https://example.com/webhook');
    });

    it('should ALLOW HTTP URL in development environment', async () => {
      // Service is already in development mode from beforeEach
      mockDnsLookup.mockImplementation((hostname: string, callback: Function) => {
        callback(null, '203.0.113.1', 4); // Public IP
      });

      mockPrismaService.webhook.create.mockResolvedValue({
        id: 'webhook-1',
        url: 'http://dev-server.local/webhook',
        secretHash: 'hash',
        events: ['BOOKING_CREATED'],
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const result = await service.createWebhook(
        { url: 'http://dev-server.local/webhook', events: ['BOOKING_CREATED'] as any },
        mockUser,
      );

      expect(result).toBeDefined();
      expect(result.url).toBe('http://dev-server.local/webhook');
    });

    it('should ALLOW HTTP URL in test environment', async () => {
      service = await createServiceWithEnv('test');

      mockDnsLookup.mockImplementation((hostname: string, callback: Function) => {
        callback(null, '203.0.113.1', 4); // Public IP
      });

      mockPrismaService.webhook.create.mockResolvedValue({
        id: 'webhook-1',
        url: 'http://test-server.local/webhook',
        secretHash: 'hash',
        events: ['BOOKING_CREATED'],
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const result = await service.createWebhook(
        { url: 'http://test-server.local/webhook', events: ['BOOKING_CREATED'] as any },
        mockUser,
      );

      expect(result).toBeDefined();
    });

    it('should REJECT non-HTTP/HTTPS protocols in production', async () => {
      service = await createServiceWithEnv('production');

      await expect(
        service.createWebhook(
          { url: 'ftp://example.com/webhook', events: ['BOOKING_CREATED'] as any },
          mockUser,
        ),
      ).rejects.toThrow('Webhook URLs must use HTTPS in production');
    });
  });

  describe('updateWebhook - URL validation', () => {
    it('should validate URL when updating webhook URL', async () => {
      mockPrismaService.webhook.findUnique.mockResolvedValue({
        id: 'webhook-1',
        url: 'https://old.example.com/webhook',
        secretHash: 'hash',
        events: ['BOOKING_CREATED'],
        isActive: true,
      });

      mockDnsLookup.mockImplementation((hostname: string, callback: Function) => {
        callback(null, '10.0.0.1', 4); // Private IP
      });

      await expect(
        service.updateWebhook(
          'webhook-1',
          { url: 'https://internal.example.com/webhook' },
          mockUser,
        ),
      ).rejects.toThrow('Webhook URL cannot target internal/private networks');
    });

    it('should not validate URL when only updating other fields', async () => {
      mockPrismaService.webhook.findUnique.mockResolvedValue({
        id: 'webhook-1',
        url: 'https://example.com/webhook',
        secretHash: 'hash',
        events: ['BOOKING_CREATED'],
        isActive: true,
      });

      mockPrismaService.webhook.update.mockResolvedValue({
        id: 'webhook-1',
        url: 'https://example.com/webhook',
        secretHash: 'hash',
        events: ['BOOKING_CREATED'],
        isActive: false,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      // Should not throw even though mockDnsLookup is not mocked for this test
      const result = await service.updateWebhook(
        'webhook-1',
        { isActive: false },
        mockUser,
      );

      expect(result.isActive).toBe(false);
      expect(mockDnsLookup).not.toHaveBeenCalled();
    });
  });
});
