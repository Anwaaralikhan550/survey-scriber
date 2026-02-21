import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException, BadRequestException } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { InvoiceStatus, UserRole } from '@prisma/client';
import { Decimal } from '@prisma/client/runtime/library';
import { InvoicesService } from './invoices.service';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';

/**
 * Unit Tests: InvoicesService
 *
 * Focus areas:
 * 1. Invoice number generation (critical fix for C1)
 * 2. CRUD operations
 * 3. Status transitions
 *
 * IMPORTANT: The generateInvoiceNumberAtomic() method uses raw SQL.
 * The raw query MUST use physical table/column names:
 * - Table: "invoices" (not "Invoice")
 * - Column: "invoice_number" (not "invoiceNumber")
 *
 * @see prisma/schema.prisma - Invoice model has @@map("invoices")
 */
describe('InvoicesService', () => {
  let service: InvoicesService;
  let prismaService: jest.Mocked<PrismaService>;

  const mockUser = {
    id: 'user-uuid-123',
    email: 'admin@test.com',
    role: UserRole.ADMIN,
  };

  const mockClient = {
    id: 'client-uuid-123',
    email: 'client@test.com',
    firstName: 'Test',
    lastName: 'Client',
  };

  const mockInvoice = {
    id: 'invoice-uuid-123',
    invoiceNumber: 'INV-202601-0001',
    clientId: 'client-uuid-123',
    bookingId: null,
    status: InvoiceStatus.DRAFT,
    issueDate: null,
    dueDate: new Date('2026-02-08'),
    paidDate: null,
    cancelledDate: null,
    cancellationReason: null,
    subtotal: 10000,
    taxRate: new Decimal(20),
    taxAmount: 2000,
    total: 12000,
    notes: null,
    paymentTerms: 'Payment due within 30 days',
    createdById: 'user-uuid-123',
    createdAt: new Date('2026-01-08'),
    updatedAt: new Date('2026-01-08'),
    client: mockClient,
    items: [
      {
        id: 'item-uuid-1',
        invoiceId: 'invoice-uuid-123',
        description: 'Survey service',
        quantity: 1,
        unitPrice: 10000,
        amount: 10000,
        itemType: 'SERVICE',
        sortOrder: 0,
      },
    ],
    createdBy: {
      id: 'user-uuid-123',
      email: 'admin@test.com',
      firstName: 'Admin',
      lastName: 'User',
    },
  };

  const mockPrismaService = {
    client: {
      findUnique: jest.fn(),
    },
    booking: {
      findUnique: jest.fn(),
    },
    invoice: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
      count: jest.fn(),
    },
    invoiceItem: {
      deleteMany: jest.fn(),
      createMany: jest.fn(),
    },
    user: {
      findUnique: jest.fn(),
    },
    $transaction: jest.fn(),
    $queryRaw: jest.fn(),
  };

  const mockAuditService = {
    log: jest.fn(),
  };

  const mockEventEmitter = {
    emit: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        InvoicesService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: AuditService, useValue: mockAuditService },
        { provide: EventEmitter2, useValue: mockEventEmitter },
      ],
    }).compile();

    service = module.get<InvoicesService>(InvoicesService);
    prismaService = module.get(PrismaService);
  });

  describe('createInvoice', () => {
    it('should create an invoice with correct number format', async () => {
      // Setup mocks
      mockPrismaService.client.findUnique.mockResolvedValue(mockClient);

      // Mock transaction to capture the raw query
      mockPrismaService.$transaction.mockImplementation(async (callback) => {
        const mockTx = {
          $queryRaw: jest.fn().mockResolvedValue([]),
          invoice: {
            create: jest.fn().mockResolvedValue(mockInvoice),
          },
        };
        return callback(mockTx);
      });

      const result = await service.createInvoice(
        {
          clientId: mockClient.id,
          items: [
            {
              description: 'Survey service',
              quantity: 1,
              unitPrice: 10000,
            },
          ],
        },
        mockUser,
      );

      expect(result).toBeDefined();
      expect(result.invoiceNumber).toMatch(/^INV-\d{6}-\d{4}$/);
    });

    it('should throw NotFoundException when client does not exist', async () => {
      mockPrismaService.client.findUnique.mockResolvedValue(null);

      await expect(
        service.createInvoice(
          {
            clientId: 'non-existent-client',
            items: [{ description: 'Test', quantity: 1, unitPrice: 100 }],
          },
          mockUser,
        ),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw BadRequestException when no items provided', async () => {
      mockPrismaService.client.findUnique.mockResolvedValue(mockClient);

      await expect(
        service.createInvoice(
          {
            clientId: mockClient.id,
            items: [],
          },
          mockUser,
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw NotFoundException when booking does not exist', async () => {
      mockPrismaService.client.findUnique.mockResolvedValue(mockClient);
      mockPrismaService.booking.findUnique.mockResolvedValue(null);

      await expect(
        service.createInvoice(
          {
            clientId: mockClient.id,
            bookingId: 'non-existent-booking',
            items: [{ description: 'Test', quantity: 1, unitPrice: 100 }],
          },
          mockUser,
        ),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('Invoice number generation - raw SQL verification', () => {
    /**
     * CRITICAL: This test documents the fix for issue C1.
     *
     * The raw SQL query in generateInvoiceNumberAtomic() MUST use:
     * - Physical table name: "invoices" (not "Invoice")
     * - Physical column name: "invoice_number" (not "invoiceNumber")
     *
     * These are defined by @@map and @map in the Prisma schema.
     */
    it('should use correct physical table and column names in raw query', async () => {
      mockPrismaService.client.findUnique.mockResolvedValue(mockClient);

      let capturedQuery: string | undefined;

      mockPrismaService.$transaction.mockImplementation(async (callback) => {
        const mockTx = {
          $queryRaw: jest.fn().mockImplementation((strings: TemplateStringsArray) => {
            // Capture the raw query template
            capturedQuery = strings.join('');
            return Promise.resolve([]);
          }),
          invoice: {
            create: jest.fn().mockResolvedValue(mockInvoice),
          },
        };
        return callback(mockTx);
      });

      await service.createInvoice(
        {
          clientId: mockClient.id,
          items: [{ description: 'Test', quantity: 1, unitPrice: 100 }],
        },
        mockUser,
      );

      // Verify the raw query uses correct physical names
      expect(capturedQuery).toBeDefined();
      expect(capturedQuery).toContain('"invoices"'); // Physical table name
      expect(capturedQuery).toContain('"invoice_number"'); // Physical column name
      expect(capturedQuery).not.toContain('"Invoice"'); // Should NOT use model name
      expect(capturedQuery).not.toContain('"invoiceNumber"'); // Should NOT use property name
    });

    it('should increment invoice number correctly when previous invoices exist', async () => {
      mockPrismaService.client.findUnique.mockResolvedValue(mockClient);

      const now = new Date();
      const yearMonth = `${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}`;
      const expectedPrefix = `INV-${yearMonth}-`;

      // Simulate existing invoice INV-YYYYMM-0005
      const existingInvoiceNumber = `${expectedPrefix}0005`;

      mockPrismaService.$transaction.mockImplementation(async (callback) => {
        const mockTx = {
          $queryRaw: jest.fn().mockResolvedValue([{ invoice_number: existingInvoiceNumber }]),
          invoice: {
            create: jest.fn().mockImplementation((args) => {
              return Promise.resolve({
                ...mockInvoice,
                invoiceNumber: args.data.invoiceNumber,
              });
            }),
          },
        };
        return callback(mockTx);
      });

      const result = await service.createInvoice(
        {
          clientId: mockClient.id,
          items: [{ description: 'Test', quantity: 1, unitPrice: 100 }],
        },
        mockUser,
      );

      // Should be INV-YYYYMM-0006 (next after 0005)
      expect(result.invoiceNumber).toBe(`${expectedPrefix}0006`);
    });
  });

  describe('updateInvoice', () => {
    it('should throw BadRequestException when trying to update non-draft invoice', async () => {
      mockPrismaService.invoice.findUnique.mockResolvedValue({
        ...mockInvoice,
        status: InvoiceStatus.ISSUED,
      });

      await expect(
        service.updateInvoice(
          mockInvoice.id,
          { notes: 'Updated notes' },
          mockUser,
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw NotFoundException when invoice does not exist', async () => {
      mockPrismaService.invoice.findUnique.mockResolvedValue(null);

      await expect(
        service.updateInvoice(
          'non-existent-id',
          { notes: 'Updated notes' },
          mockUser,
        ),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('deleteInvoice', () => {
    it('should throw BadRequestException when trying to delete non-draft invoice', async () => {
      mockPrismaService.invoice.findUnique.mockResolvedValue({
        ...mockInvoice,
        status: InvoiceStatus.ISSUED,
      });

      await expect(
        service.deleteInvoice(mockInvoice.id, mockUser),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('Status transitions', () => {
    it('should issue a draft invoice (DRAFT → ISSUED)', async () => {
      mockPrismaService.invoice.findUnique.mockResolvedValue({
        ...mockInvoice,
        status: InvoiceStatus.DRAFT,
        items: mockInvoice.items,
      });

      mockPrismaService.invoice.update.mockResolvedValue({
        ...mockInvoice,
        status: InvoiceStatus.ISSUED,
        issueDate: new Date(),
      });

      mockPrismaService.user.findUnique.mockResolvedValue({
        id: mockUser.id,
        email: mockUser.email,
        firstName: 'Admin',
        lastName: 'User',
      });

      const result = await service.issueInvoice(mockInvoice.id, mockUser);

      expect(result.status).toBe(InvoiceStatus.ISSUED);
      expect(mockAuditService.log).toHaveBeenCalled();
    });

    it('should not issue an already issued invoice', async () => {
      mockPrismaService.invoice.findUnique.mockResolvedValue({
        ...mockInvoice,
        status: InvoiceStatus.ISSUED,
      });

      await expect(
        service.issueInvoice(mockInvoice.id, mockUser),
      ).rejects.toThrow(BadRequestException);
    });

    it('should mark issued invoice as paid (ISSUED → PAID)', async () => {
      mockPrismaService.invoice.findUnique.mockResolvedValue({
        ...mockInvoice,
        status: InvoiceStatus.ISSUED,
      });

      mockPrismaService.invoice.update.mockResolvedValue({
        ...mockInvoice,
        status: InvoiceStatus.PAID,
        paidDate: new Date(),
      });

      mockPrismaService.user.findUnique.mockResolvedValue({
        id: mockUser.id,
        email: mockUser.email,
        firstName: 'Admin',
        lastName: 'User',
      });

      const result = await service.markAsPaid(mockInvoice.id, {}, mockUser);

      expect(result.status).toBe(InvoiceStatus.PAID);
      expect(mockAuditService.log).toHaveBeenCalled();
    });

    it('should not mark draft invoice as paid', async () => {
      mockPrismaService.invoice.findUnique.mockResolvedValue({
        ...mockInvoice,
        status: InvoiceStatus.DRAFT,
      });

      await expect(
        service.markAsPaid(mockInvoice.id, {}, mockUser),
      ).rejects.toThrow(BadRequestException);
    });
  });
});
