import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import PDFDocument from 'pdfkit';
import { InvoiceDetailDto } from './dto/invoice.dto';

@Injectable()
export class InvoicePdfService {
  private readonly logger = new Logger(InvoicePdfService.name);

  // Company details from environment
  private readonly companyName: string;
  private readonly companyAddress1: string;
  private readonly companyAddress2: string;
  private readonly companyVat: string;
  private readonly companyEmail: string;
  private readonly companyPhone: string;
  private readonly bankAccountName: string;
  private readonly bankSortCode: string;
  private readonly bankAccountNumber: string;

  constructor(private readonly configService: ConfigService) {
    this.companyName = this.configService.get('COMPANY_NAME', 'SurveyScriber Ltd');
    this.companyAddress1 = this.configService.get('COMPANY_ADDRESS_LINE1', '123 Business Park');
    this.companyAddress2 = this.configService.get('COMPANY_ADDRESS_LINE2', 'London, SW1A 1AA');
    this.companyVat = this.configService.get('COMPANY_VAT_NUMBER', '');
    this.companyEmail = this.configService.get('COMPANY_EMAIL', 'billing@surveyscriber.com');
    this.companyPhone = this.configService.get('COMPANY_PHONE', '');
    this.bankAccountName = this.configService.get('BANK_ACCOUNT_NAME', 'SurveyScriber Ltd');
    this.bankSortCode = this.configService.get('BANK_SORT_CODE', '');
    this.bankAccountNumber = this.configService.get('BANK_ACCOUNT_NUMBER', '');
  }

  /**
   * Generate PDF invoice as a Buffer
   */
  async generateInvoicePdf(invoice: InvoiceDetailDto): Promise<Buffer> {
    return new Promise((resolve, reject) => {
      try {
        const doc = new PDFDocument({
          size: 'A4',
          margin: 50,
          info: {
            Title: `Invoice ${invoice.invoiceNumber}`,
            Author: this.companyName,
            Subject: `Invoice for ${invoice.client.company || invoice.client.email}`,
          },
        });

        const chunks: Buffer[] = [];

        doc.on('data', (chunk: Buffer) => chunks.push(chunk));
        doc.on('end', () => resolve(Buffer.concat(chunks)));
        doc.on('error', reject);

        // Generate PDF content
        this.renderHeader(doc, invoice);
        this.renderAddresses(doc, invoice);
        this.renderBookingInfo(doc, invoice);
        this.renderLineItems(doc, invoice);
        this.renderTotals(doc, invoice);
        this.renderPaymentInfo(doc, invoice);
        this.renderFooter(doc);

        doc.end();
      } catch (error) {
        reject(error);
      }
    });
  }

  private renderHeader(doc: PDFKit.PDFDocument, invoice: InvoiceDetailDto): void {
    // Company name / logo area
    doc
      .fontSize(24)
      .font('Helvetica-Bold')
      .fillColor('#1a1a1a')
      .text(this.companyName, 50, 50);

    // Invoice title
    doc
      .fontSize(28)
      .fillColor('#4A90A4')
      .text('INVOICE', 400, 50, { align: 'right' });

    // Invoice details box
    const detailsTop = 90;
    doc
      .fontSize(10)
      .fillColor('#666666')
      .font('Helvetica');

    doc.text('Invoice Number:', 400, detailsTop, { align: 'right' });
    doc
      .font('Helvetica-Bold')
      .fillColor('#1a1a1a')
      .text(invoice.invoiceNumber, 400, detailsTop + 12, { align: 'right' });

    doc
      .font('Helvetica')
      .fillColor('#666666')
      .text('Issue Date:', 400, detailsTop + 30, { align: 'right' });
    doc
      .font('Helvetica-Bold')
      .fillColor('#1a1a1a')
      .text(
        invoice.issueDate ? this.formatDate(invoice.issueDate) : 'Not issued',
        400,
        detailsTop + 42,
        { align: 'right' },
      );

    doc
      .font('Helvetica')
      .fillColor('#666666')
      .text('Due Date:', 400, detailsTop + 60, { align: 'right' });
    doc
      .font('Helvetica-Bold')
      .fillColor('#1a1a1a')
      .text(
        invoice.dueDate ? this.formatDate(invoice.dueDate) : '-',
        400,
        detailsTop + 72,
        { align: 'right' },
      );

    // Status badge
    const statusColors: Record<string, string> = {
      DRAFT: '#9E9E9E',
      ISSUED: '#2196F3',
      PAID: '#4CAF50',
      CANCELLED: '#F44336',
    };

    doc
      .roundedRect(400, detailsTop + 90, 80, 20, 3)
      .fillColor(statusColors[invoice.status] || '#9E9E9E')
      .fill();

    doc
      .fontSize(9)
      .fillColor('#FFFFFF')
      .font('Helvetica-Bold')
      .text(invoice.status, 400, detailsTop + 95, {
        width: 80,
        align: 'center',
      });

    // Horizontal line
    doc
      .moveTo(50, 200)
      .lineTo(545, 200)
      .strokeColor('#E0E0E0')
      .stroke();
  }

  private renderAddresses(doc: PDFKit.PDFDocument, invoice: InvoiceDetailDto): void {
    const top = 220;

    // Bill To
    doc
      .fontSize(10)
      .fillColor('#666666')
      .font('Helvetica')
      .text('BILL TO', 50, top);

    doc
      .fontSize(11)
      .fillColor('#1a1a1a')
      .font('Helvetica-Bold');

    const clientName = [invoice.client.firstName, invoice.client.lastName]
      .filter(Boolean)
      .join(' ');

    if (clientName) {
      doc.text(clientName, 50, top + 15);
    }

    doc.font('Helvetica').fontSize(10);

    let yOffset = top + (clientName ? 30 : 15);

    if (invoice.client.company) {
      doc.text(invoice.client.company, 50, yOffset);
      yOffset += 15;
    }

    doc.text(invoice.client.email, 50, yOffset);
    yOffset += 15;

    if (invoice.client.phone) {
      doc.text(invoice.client.phone, 50, yOffset);
    }

    // From (Company)
    doc
      .fontSize(10)
      .fillColor('#666666')
      .font('Helvetica')
      .text('FROM', 350, top);

    doc
      .fontSize(11)
      .fillColor('#1a1a1a')
      .font('Helvetica-Bold')
      .text(this.companyName, 350, top + 15);

    doc.font('Helvetica').fontSize(10);

    yOffset = top + 30;
    if (this.companyAddress1) {
      doc.text(this.companyAddress1, 350, yOffset);
      yOffset += 15;
    }
    if (this.companyAddress2) {
      doc.text(this.companyAddress2, 350, yOffset);
      yOffset += 15;
    }
    if (this.companyVat) {
      doc.text(`VAT: ${this.companyVat}`, 350, yOffset);
    }
  }

  private renderBookingInfo(doc: PDFKit.PDFDocument, invoice: InvoiceDetailDto): void {
    if (!invoice.booking) return;

    const top = 320;

    doc
      .moveTo(50, top)
      .lineTo(545, top)
      .strokeColor('#E0E0E0')
      .stroke();

    doc
      .fontSize(10)
      .fillColor('#666666')
      .font('Helvetica')
      .text('RELATED BOOKING', 50, top + 10);

    doc
      .fontSize(10)
      .fillColor('#1a1a1a')
      .font('Helvetica');

    const bookingDate = this.formatDate(invoice.booking.date);
    doc.text(`Date: ${bookingDate}`, 50, top + 25);

    if (invoice.booking.propertyAddress) {
      doc.text(`Property: ${invoice.booking.propertyAddress}`, 50, top + 40);
    }
  }

  private renderLineItems(doc: PDFKit.PDFDocument, invoice: InvoiceDetailDto): void {
    const startY = invoice.booking ? 380 : 330;

    // Table header
    doc
      .rect(50, startY, 495, 25)
      .fillColor('#F5F5F5')
      .fill();

    doc
      .fontSize(9)
      .fillColor('#666666')
      .font('Helvetica-Bold');

    doc.text('DESCRIPTION', 60, startY + 8);
    doc.text('QTY', 350, startY + 8, { width: 40, align: 'center' });
    doc.text('UNIT PRICE', 390, startY + 8, { width: 70, align: 'right' });
    doc.text('AMOUNT', 470, startY + 8, { width: 70, align: 'right' });

    // Table rows
    let y = startY + 30;
    doc.font('Helvetica').fillColor('#1a1a1a').fontSize(10);

    for (const item of invoice.items) {
      // Check if we need a new page
      if (y > 700) {
        doc.addPage();
        y = 50;
      }

      doc.text(item.description, 60, y, { width: 280 });
      doc.text(item.quantity.toString(), 350, y, { width: 40, align: 'center' });
      doc.text(this.formatCurrency(item.unitPrice), 390, y, {
        width: 70,
        align: 'right',
      });
      doc.text(this.formatCurrency(item.amount), 470, y, {
        width: 70,
        align: 'right',
      });

      // Row separator
      y += 20;
      doc
        .moveTo(50, y)
        .lineTo(545, y)
        .strokeColor('#E0E0E0')
        .stroke();

      y += 10;
    }

    // Store Y position for totals
    (doc as any).lineItemsEndY = y;
  }

  private renderTotals(doc: PDFKit.PDFDocument, invoice: InvoiceDetailDto): void {
    let y = (doc as any).lineItemsEndY || 500;
    y += 20;

    const rightX = 390;
    const valueX = 470;

    // Subtotal
    doc
      .fontSize(10)
      .fillColor('#666666')
      .font('Helvetica')
      .text('Subtotal:', rightX, y, { width: 70, align: 'right' });
    doc
      .fillColor('#1a1a1a')
      .text(this.formatCurrency(invoice.subtotal), valueX, y, {
        width: 70,
        align: 'right',
      });

    y += 20;

    // Tax
    doc
      .fillColor('#666666')
      .text(`VAT (${invoice.taxRate}%):`, rightX, y, { width: 70, align: 'right' });
    doc
      .fillColor('#1a1a1a')
      .text(this.formatCurrency(invoice.taxAmount), valueX, y, {
        width: 70,
        align: 'right',
      });

    y += 25;

    // Total box
    doc
      .rect(rightX - 10, y - 5, 160, 30)
      .fillColor('#4A90A4')
      .fill();

    doc
      .fontSize(12)
      .fillColor('#FFFFFF')
      .font('Helvetica-Bold')
      .text('TOTAL:', rightX, y + 3, { width: 70, align: 'right' });
    doc.text(this.formatCurrency(invoice.total), valueX, y + 3, {
      width: 70,
      align: 'right',
    });

    (doc as any).totalsEndY = y + 40;
  }

  private renderPaymentInfo(doc: PDFKit.PDFDocument, invoice: InvoiceDetailDto): void {
    let y = (doc as any).totalsEndY || 600;
    y += 30;

    // Check if we need a new page
    if (y > 650) {
      doc.addPage();
      y = 50;
    }

    // Payment terms
    if (invoice.paymentTerms) {
      doc
        .fontSize(10)
        .fillColor('#666666')
        .font('Helvetica-Bold')
        .text('Payment Terms:', 50, y);

      doc
        .font('Helvetica')
        .fillColor('#1a1a1a')
        .text(invoice.paymentTerms, 50, y + 15);

      y += 40;
    }

    // Notes
    if (invoice.notes) {
      doc
        .fontSize(10)
        .fillColor('#666666')
        .font('Helvetica-Bold')
        .text('Notes:', 50, y);

      doc
        .font('Helvetica')
        .fillColor('#1a1a1a')
        .text(invoice.notes, 50, y + 15, { width: 300 });

      y += 50;
    }

    // Bank details
    if (this.bankAccountNumber && invoice.status !== 'PAID') {
      doc
        .rect(50, y, 250, 90)
        .fillColor('#F5F5F5')
        .fill();

      doc
        .fontSize(10)
        .fillColor('#666666')
        .font('Helvetica-Bold')
        .text('Bank Details', 60, y + 10);

      doc.font('Helvetica').fontSize(9).fillColor('#1a1a1a');

      let bankY = y + 28;
      doc.text(`Account Name: ${this.bankAccountName}`, 60, bankY);
      bankY += 15;
      if (this.bankSortCode) {
        doc.text(`Sort Code: ${this.bankSortCode}`, 60, bankY);
        bankY += 15;
      }
      doc.text(`Account Number: ${this.bankAccountNumber}`, 60, bankY);
      bankY += 15;
      doc.text(`Reference: ${invoice.invoiceNumber}`, 60, bankY);
    }

    // Paid stamp
    if (invoice.status === 'PAID') {
      doc
        .save()
        .translate(450, y + 30)
        .rotate(-15)
        .fontSize(36)
        .fillOpacity(0.3)
        .fillColor('#4CAF50')
        .font('Helvetica-Bold')
        .text('PAID', 0, 0)
        .fillOpacity(1)
        .restore();
    }
  }

  private renderFooter(doc: PDFKit.PDFDocument): void {
    const pageHeight = doc.page.height;

    doc
      .fontSize(8)
      .fillColor('#999999')
      .font('Helvetica')
      .text(
        `Thank you for your business | ${this.companyEmail}${this.companyPhone ? ' | ' + this.companyPhone : ''}`,
        50,
        pageHeight - 50,
        { align: 'center', width: 495 },
      );
  }

  // ===========================
  // Utility Methods
  // ===========================

  private formatCurrency(pence: number): string {
    const pounds = pence / 100;
    return `£${pounds.toLocaleString('en-GB', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    })}`;
  }

  private formatDate(isoDate: string): string {
    const date = new Date(isoDate);
    return date.toLocaleDateString('en-GB', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    });
  }
}
