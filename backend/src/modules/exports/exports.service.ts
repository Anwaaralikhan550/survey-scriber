import { Injectable, Logger } from '@nestjs/common';
import { Prisma, ActorType, AuditEntityType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import {
  BookingExportQueryDto,
  InvoiceExportQueryDto,
  ReportExportQueryDto,
} from './dto/export-query.dto';
import {
  generateCsv,
  formatDate,
  formatDateTime,
  formatCurrency,
} from './utils/csv-writer';

/**
 * Audit action for data exports
 */
export const DATA_EXPORTED = 'data.exported';

interface AuthenticatedUser {
  id: string;
  email: string;
}

@Injectable()
export class ExportsService {
  private readonly logger = new Logger(ExportsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AuditService,
  ) {}

  // ===========================
  // Bookings Export
  // ===========================

  async exportBookings(
    query: BookingExportQueryDto,
    user: AuthenticatedUser,
  ): Promise<string> {
    const { startDate, endDate, status, limit = 5000 } = query;

    const where: Prisma.BookingWhereInput = {};

    if (status) {
      where.status = status;
    }

    if (startDate || endDate) {
      where.date = {};
      if (startDate) {
        where.date.gte = new Date(startDate);
      }
      if (endDate) {
        where.date.lte = new Date(endDate);
      }
    }

    const bookings = await this.prisma.booking.findMany({
      where,
      orderBy: { date: 'desc' },
      take: limit,
      include: {
        surveyor: {
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
          },
        },
        client: {
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
            company: true,
          },
        },
      },
    });

    // Flatten data for CSV
    const flatData = bookings.map((b) => ({
      id: b.id,
      date: formatDate(b.date),
      startTime: b.startTime,
      endTime: b.endTime,
      status: b.status,
      propertyAddress: b.propertyAddress ?? '',
      clientName: b.client
        ? `${b.client.firstName ?? ''} ${b.client.lastName ?? ''}`.trim() || b.client.email
        : b.clientName ?? '',
      clientEmail: b.client?.email ?? b.clientEmail ?? '',
      clientPhone: b.clientPhone ?? '',
      clientCompany: b.client?.company ?? '',
      surveyorName: b.surveyor
        ? `${b.surveyor.firstName ?? ''} ${b.surveyor.lastName ?? ''}`.trim() || b.surveyor.email
        : '',
      surveyorEmail: b.surveyor?.email ?? '',
      notes: b.notes ?? '',
      createdAt: formatDateTime(b.createdAt),
    }));

    const columns = [
      { key: 'id' as const, header: 'Booking ID' },
      { key: 'date' as const, header: 'Date' },
      { key: 'startTime' as const, header: 'Start Time' },
      { key: 'endTime' as const, header: 'End Time' },
      { key: 'status' as const, header: 'Status' },
      { key: 'propertyAddress' as const, header: 'Property Address' },
      { key: 'clientName' as const, header: 'Client Name' },
      { key: 'clientEmail' as const, header: 'Client Email' },
      { key: 'clientPhone' as const, header: 'Client Phone' },
      { key: 'clientCompany' as const, header: 'Client Company' },
      { key: 'surveyorName' as const, header: 'Surveyor Name' },
      { key: 'surveyorEmail' as const, header: 'Surveyor Email' },
      { key: 'notes' as const, header: 'Notes' },
      { key: 'createdAt' as const, header: 'Created At' },
    ];

    const csv = generateCsv(flatData, columns);

    // Audit log
    await this.auditService.log({
      actorType: ActorType.STAFF,
      actorId: user.id,
      action: DATA_EXPORTED,
      entityType: AuditEntityType.BOOKING,
      metadata: {
        exportType: 'BOOKINGS',
        rowCount: bookings.length,
        filters: { startDate, endDate, status },
      },
    });

    this.logger.log(
      `User ${user.id} exported ${bookings.length} bookings to CSV`,
    );

    return csv;
  }

  // ===========================
  // Invoices Export
  // ===========================

  async exportInvoices(
    query: InvoiceExportQueryDto,
    user: AuthenticatedUser,
  ): Promise<string> {
    const { startDate, endDate, status, limit = 5000 } = query;

    const where: Prisma.InvoiceWhereInput = {};

    if (status) {
      where.status = status;
    }

    if (startDate || endDate) {
      where.createdAt = {};
      if (startDate) {
        where.createdAt.gte = new Date(startDate);
      }
      if (endDate) {
        where.createdAt.lte = new Date(endDate);
      }
    }

    const invoices = await this.prisma.invoice.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: limit,
      include: {
        client: {
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
            company: true,
          },
        },
        items: {
          select: {
            description: true,
            quantity: true,
            unitPrice: true,
            amount: true,
          },
        },
      },
    });

    // Flatten data for CSV
    const flatData = invoices.map((inv) => ({
      id: inv.id,
      invoiceNumber: inv.invoiceNumber,
      status: inv.status,
      issueDate: formatDate(inv.issueDate),
      dueDate: formatDate(inv.dueDate),
      paidDate: formatDate(inv.paidDate),
      clientName: inv.client
        ? `${inv.client.firstName ?? ''} ${inv.client.lastName ?? ''}`.trim() || inv.client.email
        : '',
      clientEmail: inv.client?.email ?? '',
      clientCompany: inv.client?.company ?? '',
      subtotal: formatCurrency(inv.subtotal),
      taxRate: inv.taxRate?.toString() ?? '20',
      taxAmount: formatCurrency(inv.taxAmount),
      total: formatCurrency(inv.total),
      itemCount: inv.items.length,
      notes: inv.notes ?? '',
      paymentTerms: inv.paymentTerms ?? '',
      createdAt: formatDateTime(inv.createdAt),
    }));

    const columns = [
      { key: 'id' as const, header: 'Invoice ID' },
      { key: 'invoiceNumber' as const, header: 'Invoice Number' },
      { key: 'status' as const, header: 'Status' },
      { key: 'issueDate' as const, header: 'Issue Date' },
      { key: 'dueDate' as const, header: 'Due Date' },
      { key: 'paidDate' as const, header: 'Paid Date' },
      { key: 'clientName' as const, header: 'Client Name' },
      { key: 'clientEmail' as const, header: 'Client Email' },
      { key: 'clientCompany' as const, header: 'Client Company' },
      { key: 'subtotal' as const, header: 'Subtotal' },
      { key: 'taxRate' as const, header: 'Tax Rate (%)' },
      { key: 'taxAmount' as const, header: 'Tax Amount' },
      { key: 'total' as const, header: 'Total' },
      { key: 'itemCount' as const, header: 'Line Items' },
      { key: 'notes' as const, header: 'Notes' },
      { key: 'paymentTerms' as const, header: 'Payment Terms' },
      { key: 'createdAt' as const, header: 'Created At' },
    ];

    const csv = generateCsv(flatData, columns);

    // Audit log
    await this.auditService.log({
      actorType: ActorType.STAFF,
      actorId: user.id,
      action: DATA_EXPORTED,
      entityType: AuditEntityType.INVOICE,
      metadata: {
        exportType: 'INVOICES',
        rowCount: invoices.length,
        filters: { startDate, endDate, status },
      },
    });

    this.logger.log(
      `User ${user.id} exported ${invoices.length} invoices to CSV`,
    );

    return csv;
  }

  // ===========================
  // Reports/Surveys Export
  // ===========================

  async exportReports(
    query: ReportExportQueryDto,
    user: AuthenticatedUser,
  ): Promise<string> {
    const { startDate, endDate, status, limit = 5000 } = query;

    const where: Prisma.SurveyWhereInput = {
      deletedAt: null,
    };

    if (status) {
      where.status = status;
    }

    if (startDate || endDate) {
      where.createdAt = {};
      if (startDate) {
        where.createdAt.gte = new Date(startDate);
      }
      if (endDate) {
        where.createdAt.lte = new Date(endDate);
      }
    }

    const surveys = await this.prisma.survey.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: limit,
      include: {
        user: {
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
          },
        },
        client: {
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
            company: true,
          },
        },
        _count: {
          select: {
            sections: true,
            media: true,
          },
        },
      },
    });

    // Flatten data for CSV
    const flatData = surveys.map((s) => ({
      id: s.id,
      title: s.title,
      status: s.status,
      type: s.type ?? '',
      jobRef: s.jobRef ?? '',
      propertyAddress: s.propertyAddress,
      clientName: s.client
        ? `${s.client.firstName ?? ''} ${s.client.lastName ?? ''}`.trim() || s.client.email
        : s.clientName ?? '',
      clientEmail: s.client?.email ?? '',
      clientCompany: s.client?.company ?? '',
      surveyorName: s.user
        ? `${s.user.firstName ?? ''} ${s.user.lastName ?? ''}`.trim() || s.user.email
        : '',
      surveyorEmail: s.user?.email ?? '',
      sectionCount: s._count.sections,
      mediaCount: s._count.media,
      hasReportPdf: s.reportPdfPath ? 'Yes' : 'No',
      createdAt: formatDateTime(s.createdAt),
      updatedAt: formatDateTime(s.updatedAt),
    }));

    const columns = [
      { key: 'id' as const, header: 'Survey ID' },
      { key: 'title' as const, header: 'Title' },
      { key: 'status' as const, header: 'Status' },
      { key: 'type' as const, header: 'Type' },
      { key: 'jobRef' as const, header: 'Job Reference' },
      { key: 'propertyAddress' as const, header: 'Property Address' },
      { key: 'clientName' as const, header: 'Client Name' },
      { key: 'clientEmail' as const, header: 'Client Email' },
      { key: 'clientCompany' as const, header: 'Client Company' },
      { key: 'surveyorName' as const, header: 'Surveyor Name' },
      { key: 'surveyorEmail' as const, header: 'Surveyor Email' },
      { key: 'sectionCount' as const, header: 'Sections' },
      { key: 'mediaCount' as const, header: 'Media Files' },
      { key: 'hasReportPdf' as const, header: 'Has PDF' },
      { key: 'createdAt' as const, header: 'Created At' },
      { key: 'updatedAt' as const, header: 'Updated At' },
    ];

    const csv = generateCsv(flatData, columns);

    // Audit log
    await this.auditService.log({
      actorType: ActorType.STAFF,
      actorId: user.id,
      action: DATA_EXPORTED,
      entityType: AuditEntityType.SURVEY,
      metadata: {
        exportType: 'REPORTS',
        rowCount: surveys.length,
        filters: { startDate, endDate, status },
      },
    });

    this.logger.log(
      `User ${user.id} exported ${surveys.length} reports to CSV`,
    );

    return csv;
  }
}
