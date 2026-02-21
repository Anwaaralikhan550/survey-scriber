import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { InvoiceStatus, UserRole, ActorType, AuditEntityType } from '@prisma/client';
import { AuditService, AuditActions } from '../audit/audit.service';
import { Decimal } from '@prisma/client/runtime/library';
import { PrismaService } from '../prisma/prisma.service';
import {
  CreateInvoiceDto,
  UpdateInvoiceDto,
  InvoicesQueryDto,
  InvoicesResponseDto,
  InvoiceDto,
  InvoiceDetailDto,
  MarkPaidDto,
  CancelInvoiceDto,
} from './dto/invoice.dto';
import {
  InvoiceIssuedEvent,
  InvoicePaidEvent,
  InvoiceWithRelations,
} from './events/invoice.events';

interface AuthenticatedUser {
  id: string;
  email: string;
  role: UserRole;
}

@Injectable()
export class InvoicesService {
  private readonly logger = new Logger(InvoicesService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly eventEmitter: EventEmitter2,
    private readonly auditService: AuditService,
  ) {}

  // ===========================
  // Invoice Number Generation
  // ===========================

  /**
   * Generates invoice number atomically within a transaction.
   * Uses raw query with FOR UPDATE to prevent race conditions.
   * Format: INV-YYYYMM-XXXX (e.g., INV-202501-0001)
   *
   * IMPORTANT: Raw SQL must use physical table/column names from @@map/@map:
   * - Table: "invoices" (not "Invoice")
   * - Column: "invoice_number" (not "invoiceNumber")
   */
  private async generateInvoiceNumberAtomic(
    tx: Parameters<Parameters<typeof this.prisma.$transaction>[0]>[0],
  ): Promise<string> {
    const now = new Date();
    const yearMonth = `${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}`;
    const prefix = `INV-${yearMonth}-`;

    // Use raw query with FOR UPDATE to lock the row and prevent race conditions
    // This ensures serialized access to the latest invoice number
    // NOTE: Must use physical table name "invoices" and column name "invoice_number"
    // as defined by @@map("invoices") and @map("invoice_number") in schema.prisma
    const lastInvoices = await tx.$queryRaw<Array<{ invoice_number: string }>>`
      SELECT "invoice_number"
      FROM "invoices"
      WHERE "invoice_number" LIKE ${prefix + '%'}
      ORDER BY "invoice_number" DESC
      LIMIT 1
      FOR UPDATE
    `;

    const lastInvoice = lastInvoices.length > 0 ? lastInvoices[0] : null;

    const nextNumber = lastInvoice
      ? parseInt(lastInvoice.invoice_number.split('-')[2]) + 1
      : 1;

    return `${prefix}${String(nextNumber).padStart(4, '0')}`;
  }

  // ===========================
  // CRUD Operations
  // ===========================

  /**
   * Create a new invoice
   * Uses atomic transaction to prevent invoice number race conditions.
   */
  async createInvoice(
    dto: CreateInvoiceDto,
    currentUser: AuthenticatedUser,
  ): Promise<InvoiceDetailDto> {
    // Validate client exists
    const client = await this.prisma.client.findUnique({
      where: { id: dto.clientId },
    });

    if (!client) {
      throw new NotFoundException('Client not found');
    }

    // Validate booking if provided
    if (dto.bookingId) {
      const booking = await this.prisma.booking.findUnique({
        where: { id: dto.bookingId },
      });
      if (!booking) {
        throw new NotFoundException('Booking not found');
      }
    }

    // Validate at least one item
    if (!dto.items || dto.items.length === 0) {
      throw new BadRequestException('Invoice must have at least one line item');
    }

    // Calculate amounts
    const subtotal = dto.items.reduce(
      (sum, item) => sum + item.quantity * item.unitPrice,
      0,
    );
    const taxRate = dto.taxRate ?? 20;
    const taxAmount = Math.round(subtotal * (taxRate / 100));
    const total = subtotal + taxAmount;

    // Calculate default due date (30 days from now)
    const dueDate = dto.dueDate
      ? new Date(dto.dueDate)
      : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

    // Create invoice with items inside a transaction
    // Invoice number generation is atomic to prevent race conditions
    const invoice = await this.prisma.$transaction(async (tx) => {
      // Generate invoice number atomically within the transaction
      const invoiceNumber = await this.generateInvoiceNumberAtomic(tx);

      // Create invoice with items
      return tx.invoice.create({
        data: {
          invoiceNumber,
          clientId: dto.clientId,
          bookingId: dto.bookingId,
          status: InvoiceStatus.DRAFT,
          subtotal,
          taxRate: new Decimal(taxRate),
          taxAmount,
          total,
          notes: dto.notes,
          dueDate,
          paymentTerms: dto.paymentTerms ?? 'Payment due within 30 days',
          createdById: currentUser.id,
          items: {
            create: dto.items.map((item, index) => ({
              description: item.description,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              amount: item.quantity * item.unitPrice,
              itemType: item.itemType,
              sortOrder: index,
            })),
          },
        },
        include: this.getInvoiceInclude(),
      });
    });

    this.logger.log(`Created invoice ${invoice.invoiceNumber} for client ${dto.clientId}`);

    return this.mapToDetailDto(invoice);
  }

  /**
   * Get paginated list of invoices
   */
  async getInvoices(
    query: InvoicesQueryDto,
  ): Promise<InvoicesResponseDto> {
    const { page = 1, limit = 20, status, clientId, fromDate, toDate } = query;
    const skip = (page - 1) * limit;

    const where: any = {};

    if (status) {
      where.status = status;
    }

    if (clientId) {
      where.clientId = clientId;
    }

    if (fromDate || toDate) {
      where.createdAt = {};
      if (fromDate) {
        where.createdAt.gte = new Date(fromDate);
      }
      if (toDate) {
        where.createdAt.lte = new Date(toDate);
      }
    }

    const [invoices, total] = await Promise.all([
      this.prisma.invoice.findMany({
        where,
        include: {
          client: true,
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.invoice.count({ where }),
    ]);

    return {
      data: invoices.map((inv) => this.mapToDto(inv)),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Get single invoice detail
   */
  async getInvoiceById(id: string): Promise<InvoiceDetailDto> {
    const invoice = await this.prisma.invoice.findUnique({
      where: { id },
      include: this.getInvoiceInclude(),
    });

    if (!invoice) {
      throw new NotFoundException('Invoice not found');
    }

    return this.mapToDetailDto(invoice);
  }

  /**
   * Update a draft invoice
   */
  async updateInvoice(
    id: string,
    dto: UpdateInvoiceDto,
    currentUser: AuthenticatedUser,
  ): Promise<InvoiceDetailDto> {
    const invoice = await this.prisma.invoice.findUnique({
      where: { id },
    });

    if (!invoice) {
      throw new NotFoundException('Invoice not found');
    }

    if (invoice.status !== InvoiceStatus.DRAFT) {
      throw new BadRequestException('Only draft invoices can be edited');
    }

    // Calculate new amounts if items provided
    let updateData: any = {
      notes: dto.notes,
      paymentTerms: dto.paymentTerms,
    };

    if (dto.taxRate !== undefined) {
      updateData.taxRate = new Decimal(dto.taxRate);
    }

    if (dto.dueDate) {
      updateData.dueDate = new Date(dto.dueDate);
    }

    if (dto.items && dto.items.length > 0) {
      const subtotal = dto.items.reduce(
        (sum, item) => sum + item.quantity * item.unitPrice,
        0,
      );
      const taxRate = dto.taxRate ?? Number(invoice.taxRate);
      const taxAmount = Math.round(subtotal * (taxRate / 100));
      const total = subtotal + taxAmount;

      updateData = {
        ...updateData,
        subtotal,
        taxAmount,
        total,
      };

      // Delete existing items and create new ones
      await this.prisma.invoiceItem.deleteMany({
        where: { invoiceId: id },
      });

      await this.prisma.invoiceItem.createMany({
        data: dto.items.map((item, index) => ({
          invoiceId: id,
          description: item.description,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          amount: item.quantity * item.unitPrice,
          itemType: item.itemType,
          sortOrder: index,
        })),
      });
    }

    const updated = await this.prisma.invoice.update({
      where: { id },
      data: updateData,
      include: this.getInvoiceInclude(),
    });

    this.logger.log(`Updated invoice ${invoice.invoiceNumber}`);

    return this.mapToDetailDto(updated);
  }

  /**
   * Delete a draft invoice
   */
  async deleteInvoice(id: string, currentUser: AuthenticatedUser): Promise<void> {
    const invoice = await this.prisma.invoice.findUnique({
      where: { id },
    });

    if (!invoice) {
      throw new NotFoundException('Invoice not found');
    }

    if (invoice.status !== InvoiceStatus.DRAFT) {
      throw new BadRequestException('Only draft invoices can be deleted');
    }

    await this.prisma.invoice.delete({
      where: { id },
    });

    this.logger.log(`Deleted invoice ${invoice.invoiceNumber}`);
  }

  // ===========================
  // Status Transitions
  // ===========================

  /**
   * Issue an invoice (DRAFT → ISSUED)
   */
  async issueInvoice(
    id: string,
    currentUser: AuthenticatedUser,
  ): Promise<InvoiceDetailDto> {
    const invoice = await this.prisma.invoice.findUnique({
      where: { id },
      include: { items: true },
    });

    if (!invoice) {
      throw new NotFoundException('Invoice not found');
    }

    if (invoice.status !== InvoiceStatus.DRAFT) {
      throw new BadRequestException('Only draft invoices can be issued');
    }

    if (invoice.items.length === 0) {
      throw new BadRequestException('Invoice must have at least one line item');
    }

    const updated = await this.prisma.invoice.update({
      where: { id },
      data: {
        status: InvoiceStatus.ISSUED,
        issueDate: new Date(),
      },
      include: this.getInvoiceInclude(),
    });

    this.logger.log(`Issued invoice ${invoice.invoiceNumber}`);

    // Audit log
    await this.auditService.log({
      actorType: ActorType.STAFF,
      actorId: currentUser.id,
      action: AuditActions.INVOICE_ISSUED,
      entityType: AuditEntityType.INVOICE,
      entityId: id,
      metadata: { invoiceNumber: invoice.invoiceNumber, clientId: invoice.clientId },
    });

    // Emit event for notifications
    const issuedByUser = await this.prisma.user.findUnique({
      where: { id: currentUser.id },
    });

    if (issuedByUser) {
      this.eventEmitter.emit(
        InvoiceIssuedEvent.eventName,
        new InvoiceIssuedEvent(updated as InvoiceWithRelations, issuedByUser),
      );
    }

    return this.mapToDetailDto(updated);
  }

  /**
   * Mark invoice as paid (ISSUED → PAID)
   */
  async markAsPaid(
    id: string,
    dto: MarkPaidDto,
    currentUser: AuthenticatedUser,
  ): Promise<InvoiceDetailDto> {
    const invoice = await this.prisma.invoice.findUnique({
      where: { id },
    });

    if (!invoice) {
      throw new NotFoundException('Invoice not found');
    }

    if (invoice.status !== InvoiceStatus.ISSUED) {
      throw new BadRequestException('Only issued invoices can be marked as paid');
    }

    const paidDate = dto.paidDate ? new Date(dto.paidDate) : new Date();

    const updated = await this.prisma.invoice.update({
      where: { id },
      data: {
        status: InvoiceStatus.PAID,
        paidDate,
      },
      include: this.getInvoiceInclude(),
    });

    this.logger.log(`Marked invoice ${invoice.invoiceNumber} as paid`);

    // Audit log
    await this.auditService.log({
      actorType: ActorType.STAFF,
      actorId: currentUser.id,
      action: AuditActions.INVOICE_PAID,
      entityType: AuditEntityType.INVOICE,
      entityId: id,
      metadata: { invoiceNumber: invoice.invoiceNumber, paidDate: paidDate.toISOString() },
    });

    // Emit event for notifications
    const markedPaidByUser = await this.prisma.user.findUnique({
      where: { id: currentUser.id },
    });

    if (markedPaidByUser) {
      this.eventEmitter.emit(
        InvoicePaidEvent.eventName,
        new InvoicePaidEvent(updated as InvoiceWithRelations, markedPaidByUser),
      );
    }

    return this.mapToDetailDto(updated);
  }

  /**
   * Cancel an invoice (ISSUED → CANCELLED)
   */
  async cancelInvoice(
    id: string,
    dto: CancelInvoiceDto,
    currentUser: AuthenticatedUser,
  ): Promise<InvoiceDetailDto> {
    const invoice = await this.prisma.invoice.findUnique({
      where: { id },
    });

    if (!invoice) {
      throw new NotFoundException('Invoice not found');
    }

    if (invoice.status !== InvoiceStatus.ISSUED) {
      throw new BadRequestException('Only issued invoices can be cancelled');
    }

    const updated = await this.prisma.invoice.update({
      where: { id },
      data: {
        status: InvoiceStatus.CANCELLED,
        cancelledDate: new Date(),
        cancellationReason: dto.reason,
      },
      include: this.getInvoiceInclude(),
    });

    this.logger.log(`Cancelled invoice ${invoice.invoiceNumber}: ${dto.reason}`);

    // Audit log
    await this.auditService.log({
      actorType: ActorType.STAFF,
      actorId: currentUser.id,
      action: AuditActions.INVOICE_CANCELLED,
      entityType: AuditEntityType.INVOICE,
      entityId: id,
      metadata: { invoiceNumber: invoice.invoiceNumber, reason: dto.reason },
    });

    return this.mapToDetailDto(updated);
  }

  // ===========================
  // Client Portal Methods
  // ===========================

  /**
   * Get invoices for a client (excludes drafts)
   */
  async getClientInvoices(
    clientId: string,
    query: InvoicesQueryDto,
  ): Promise<InvoicesResponseDto> {
    const { page = 1, limit = 20, status } = query;
    const skip = (page - 1) * limit;

    const where: any = {
      clientId,
      status: { not: InvoiceStatus.DRAFT },
    };

    if (status && status !== InvoiceStatus.DRAFT) {
      where.status = status;
    }

    const [invoices, total] = await Promise.all([
      this.prisma.invoice.findMany({
        where,
        include: { client: true },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.invoice.count({ where }),
    ]);

    return {
      data: invoices.map((inv) => this.mapToDto(inv)),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Get single invoice for client (excludes drafts)
   */
  async getClientInvoiceById(
    clientId: string,
    invoiceId: string,
  ): Promise<InvoiceDetailDto> {
    const invoice = await this.prisma.invoice.findUnique({
      where: { id: invoiceId },
      include: this.getInvoiceInclude(),
    });

    if (!invoice) {
      throw new NotFoundException('Invoice not found');
    }

    if (invoice.clientId !== clientId) {
      throw new ForbiddenException('Access denied');
    }

    if (invoice.status === InvoiceStatus.DRAFT) {
      throw new NotFoundException('Invoice not found');
    }

    return this.mapToDetailDto(invoice);
  }

  // ===========================
  // Helper Methods
  // ===========================

  private getInvoiceInclude() {
    return {
      client: true,
      items: { orderBy: { sortOrder: 'asc' as const } },
      createdBy: {
        select: { id: true, email: true, firstName: true, lastName: true },
      },
    };
  }

  private mapToDto(invoice: any): InvoiceDto {
    const clientName = invoice.client
      ? [invoice.client.firstName, invoice.client.lastName]
          .filter(Boolean)
          .join(' ') || invoice.client.email
      : 'Unknown';

    return {
      id: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      status: invoice.status,
      clientId: invoice.clientId,
      clientName,
      bookingId: invoice.bookingId ?? undefined,
      issueDate: invoice.issueDate?.toISOString() ?? undefined,
      dueDate: invoice.dueDate?.toISOString() ?? undefined,
      paidDate: invoice.paidDate?.toISOString() ?? undefined,
      subtotal: invoice.subtotal,
      taxRate: Number(invoice.taxRate),
      taxAmount: invoice.taxAmount,
      total: invoice.total,
      createdAt: invoice.createdAt.toISOString(),
    };
  }

  private mapToDetailDto(invoice: any): InvoiceDetailDto {
    const base = this.mapToDto(invoice);

    return {
      ...base,
      items: invoice.items.map((item: any) => ({
        id: item.id,
        description: item.description,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        amount: item.amount,
        itemType: item.itemType ?? undefined,
      })),
      notes: invoice.notes ?? undefined,
      paymentTerms: invoice.paymentTerms ?? undefined,
      cancellationReason: invoice.cancellationReason ?? undefined,
      cancelledDate: invoice.cancelledDate?.toISOString() ?? undefined,
      client: {
        id: invoice.client.id,
        email: invoice.client.email,
        firstName: invoice.client.firstName ?? undefined,
        lastName: invoice.client.lastName ?? undefined,
        company: invoice.client.company ?? undefined,
        phone: invoice.client.phone ?? undefined,
      },
      booking: invoice.booking
        ? {
            id: invoice.booking.id,
            date: invoice.booking.date.toISOString(),
            propertyAddress: invoice.booking.propertyAddress ?? undefined,
          }
        : undefined,
      createdBy: {
        id: invoice.createdBy.id,
        firstName: invoice.createdBy.firstName ?? undefined,
        lastName: invoice.createdBy.lastName ?? undefined,
      },
    };
  }
}
