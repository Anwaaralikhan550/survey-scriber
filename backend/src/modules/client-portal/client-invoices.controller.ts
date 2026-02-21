import {
  Controller,
  Get,
  Param,
  Query,
  UseGuards,
  Request,
  ParseUUIDPipe,
  Res,
} from '@nestjs/common';
import { sanitizeFilename } from '../../common/utils/sanitize-filename';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
} from '@nestjs/swagger';
import { Request as ExpressRequest, Response } from 'express';
import { ClientJwtGuard } from './guards/client-jwt.guard';
import { InvoicesService } from '../invoices/invoices.service';
import { InvoicePdfService } from '../invoices/invoice-pdf.service';
import {
  InvoicesQueryDto,
  InvoicesResponseDto,
  InvoiceDetailDto,
} from '../invoices/dto/invoice.dto';

interface ClientRequest extends ExpressRequest {
  user: { id: string; email: string; type: string };
}

@ApiTags('Client Portal - Invoices')
@Controller('client/invoices')
@UseGuards(ClientJwtGuard)
@ApiBearerAuth()
export class ClientInvoicesController {
  constructor(
    private readonly invoicesService: InvoicesService,
    private readonly pdfService: InvoicePdfService,
  ) {}

  /**
   * Get all invoices for the authenticated client (excludes DRAFT)
   */
  @Get()
  @ApiOperation({
    summary: 'Get client invoices',
    description:
      'Returns all non-draft invoices for the authenticated client with pagination.',
  })
  @ApiResponse({
    status: 200,
    description: 'List of invoices',
    type: InvoicesResponseDto,
  })
  async getInvoices(
    @Request() req: ClientRequest,
    @Query() query: InvoicesQueryDto,
  ): Promise<InvoicesResponseDto> {
    return this.invoicesService.getClientInvoices(req.user.id, query);
  }

  /**
   * Get a specific invoice for the authenticated client
   */
  @Get(':id')
  @ApiOperation({
    summary: 'Get invoice details',
    description: 'Returns detailed information about a specific invoice.',
  })
  @ApiParam({ name: 'id', description: 'Invoice ID' })
  @ApiResponse({
    status: 200,
    description: 'Invoice detail',
    type: InvoiceDetailDto,
  })
  @ApiResponse({ status: 404, description: 'Invoice not found' })
  async getInvoiceById(
    @Request() req: ClientRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<InvoiceDetailDto> {
    return this.invoicesService.getClientInvoiceById(req.user.id, id);
  }

  /**
   * Download invoice as PDF
   */
  @Get(':id/pdf')
  @ApiOperation({
    summary: 'Download invoice PDF',
    description: 'Downloads the invoice as a PDF document.',
  })
  @ApiParam({ name: 'id', description: 'Invoice ID' })
  @ApiResponse({ status: 200, description: 'PDF file' })
  @ApiResponse({ status: 404, description: 'Invoice not found' })
  async downloadPdf(
    @Request() req: ClientRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Res() res: Response,
  ): Promise<void> {
    // This also validates that the invoice belongs to the client
    const invoice = await this.invoicesService.getClientInvoiceById(
      req.user.id,
      id,
    );

    const pdfBuffer = await this.pdfService.generateInvoicePdf(invoice);

    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': `attachment; filename="${sanitizeFilename(invoice.invoiceNumber)}.pdf"`,
      'Content-Length': pdfBuffer.length,
    });

    res.send(pdfBuffer);
  }
}
