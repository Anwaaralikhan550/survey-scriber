import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Query,
  Body,
  UseGuards,
  Request,
  ParseUUIDPipe,
  HttpCode,
  HttpStatus,
  Res,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { sanitizeFilename } from '../../common/utils/sanitize-filename';
import { Response } from 'express';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { InvoicesService } from './invoices.service';
import { InvoicePdfService } from './invoice-pdf.service';
import {
  CreateInvoiceDto,
  UpdateInvoiceDto,
  InvoicesQueryDto,
  InvoicesResponseDto,
  InvoiceDetailDto,
  MarkPaidDto,
  CancelInvoiceDto,
} from './dto/invoice.dto';

@ApiTags('Invoices')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('invoices')
export class InvoicesController {
  constructor(
    private readonly invoicesService: InvoicesService,
    private readonly pdfService: InvoicePdfService,
  ) {}

  /**
   * Create a new invoice
   */
  @Post()
  @Roles('ADMIN', 'MANAGER')
  @ApiOperation({ summary: 'Create a new invoice' })
  @ApiResponse({
    status: 201,
    description: 'Invoice created successfully',
    type: InvoiceDetailDto,
  })
  @ApiResponse({ status: 400, description: 'Invalid request' })
  @ApiResponse({ status: 404, description: 'Client or booking not found' })
  async createInvoice(
    @Request() req: any,
    @Body() dto: CreateInvoiceDto,
  ): Promise<InvoiceDetailDto> {
    return this.invoicesService.createInvoice(dto, req.user);
  }

  /**
   * Get paginated list of invoices
   */
  @Get()
  @Roles('ADMIN', 'MANAGER', 'VIEWER')
  @ApiOperation({ summary: 'Get all invoices' })
  @ApiResponse({
    status: 200,
    description: 'List of invoices',
    type: InvoicesResponseDto,
  })
  async getInvoices(
    @Query() query: InvoicesQueryDto,
  ): Promise<InvoicesResponseDto> {
    return this.invoicesService.getInvoices(query);
  }

  /**
   * Get invoice by ID
   */
  @Get(':id')
  @Roles('ADMIN', 'MANAGER', 'VIEWER')
  @ApiOperation({ summary: 'Get invoice by ID' })
  @ApiParam({ name: 'id', description: 'Invoice ID' })
  @ApiResponse({
    status: 200,
    description: 'Invoice detail',
    type: InvoiceDetailDto,
  })
  @ApiResponse({ status: 404, description: 'Invoice not found' })
  async getInvoiceById(
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<InvoiceDetailDto> {
    return this.invoicesService.getInvoiceById(id);
  }

  /**
   * Update a draft invoice
   */
  @Patch(':id')
  @Roles('ADMIN', 'MANAGER')
  @ApiOperation({ summary: 'Update a draft invoice' })
  @ApiParam({ name: 'id', description: 'Invoice ID' })
  @ApiResponse({
    status: 200,
    description: 'Invoice updated successfully',
    type: InvoiceDetailDto,
  })
  @ApiResponse({ status: 400, description: 'Cannot update non-draft invoice' })
  @ApiResponse({ status: 404, description: 'Invoice not found' })
  async updateInvoice(
    @Request() req: any,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateInvoiceDto,
  ): Promise<InvoiceDetailDto> {
    return this.invoicesService.updateInvoice(id, dto, req.user);
  }

  /**
   * Delete a draft invoice
   */
  @Delete(':id')
  @Roles('ADMIN', 'MANAGER')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a draft invoice' })
  @ApiParam({ name: 'id', description: 'Invoice ID' })
  @ApiResponse({ status: 204, description: 'Invoice deleted' })
  @ApiResponse({ status: 400, description: 'Cannot delete non-draft invoice' })
  @ApiResponse({ status: 404, description: 'Invoice not found' })
  async deleteInvoice(
    @Request() req: any,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<void> {
    await this.invoicesService.deleteInvoice(id, req.user);
  }

  /**
   * Issue an invoice (DRAFT → ISSUED)
   */
  @Post(':id/issue')
  @Roles('ADMIN', 'MANAGER')
  @Throttle({ default: { limit: 10, ttl: 60000 } }) // SEC-L9: 10 state changes per minute
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Issue an invoice' })
  @ApiParam({ name: 'id', description: 'Invoice ID' })
  @ApiResponse({
    status: 200,
    description: 'Invoice issued successfully',
    type: InvoiceDetailDto,
  })
  @ApiResponse({ status: 400, description: 'Cannot issue non-draft invoice' })
  @ApiResponse({ status: 404, description: 'Invoice not found' })
  async issueInvoice(
    @Request() req: any,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<InvoiceDetailDto> {
    return this.invoicesService.issueInvoice(id, req.user);
  }

  /**
   * Mark invoice as paid (ISSUED → PAID)
   */
  @Post(':id/mark-paid')
  @Roles('ADMIN', 'MANAGER')
  @Throttle({ default: { limit: 10, ttl: 60000 } }) // SEC-L9
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Mark invoice as paid' })
  @ApiParam({ name: 'id', description: 'Invoice ID' })
  @ApiResponse({
    status: 200,
    description: 'Invoice marked as paid',
    type: InvoiceDetailDto,
  })
  @ApiResponse({ status: 400, description: 'Cannot mark non-issued invoice as paid' })
  @ApiResponse({ status: 404, description: 'Invoice not found' })
  async markAsPaid(
    @Request() req: any,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: MarkPaidDto,
  ): Promise<InvoiceDetailDto> {
    return this.invoicesService.markAsPaid(id, dto, req.user);
  }

  /**
   * Cancel an invoice (ISSUED → CANCELLED)
   */
  @Post(':id/cancel')
  @Roles('ADMIN', 'MANAGER')
  @Throttle({ default: { limit: 10, ttl: 60000 } }) // SEC-L9
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Cancel an invoice' })
  @ApiParam({ name: 'id', description: 'Invoice ID' })
  @ApiResponse({
    status: 200,
    description: 'Invoice cancelled',
    type: InvoiceDetailDto,
  })
  @ApiResponse({ status: 400, description: 'Cannot cancel non-issued invoice' })
  @ApiResponse({ status: 404, description: 'Invoice not found' })
  async cancelInvoice(
    @Request() req: any,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CancelInvoiceDto,
  ): Promise<InvoiceDetailDto> {
    return this.invoicesService.cancelInvoice(id, dto, req.user);
  }

  /**
   * Download invoice as PDF
   */
  @Get(':id/pdf')
  @Roles('ADMIN', 'MANAGER', 'VIEWER')
  @ApiOperation({ summary: 'Download invoice as PDF' })
  @ApiParam({ name: 'id', description: 'Invoice ID' })
  @ApiResponse({ status: 200, description: 'PDF file' })
  @ApiResponse({ status: 404, description: 'Invoice not found' })
  async downloadPdf(
    @Param('id', ParseUUIDPipe) id: string,
    @Res() res: Response,
  ): Promise<void> {
    const invoice = await this.invoicesService.getInvoiceById(id);
    const pdfBuffer = await this.pdfService.generateInvoicePdf(invoice);

    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': `attachment; filename="${sanitizeFilename(invoice.invoiceNumber)}.pdf"`,
      'Content-Length': pdfBuffer.length,
    });

    res.send(pdfBuffer);
  }
}
