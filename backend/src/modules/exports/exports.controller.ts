import {
  Controller,
  Get,
  Query,
  UseGuards,
  Res,
  Header,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiProduces,
} from '@nestjs/swagger';
import { Response } from 'express';
import { UserRole } from '@prisma/client';
import { ExportsService } from './exports.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import {
  BookingExportQueryDto,
  InvoiceExportQueryDto,
  ReportExportQueryDto,
} from './dto/export-query.dto';

/**
 * Generate filename with current date
 */
function getFilename(prefix: string): string {
  const date = new Date().toISOString().split('T')[0];
  return `${prefix}_${date}.csv`;
}

@ApiTags('Exports')
@ApiBearerAuth('JWT-auth')
@Controller('exports')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN, UserRole.MANAGER)
export class ExportsController {
  constructor(private readonly exportsService: ExportsService) {}

  @Get('bookings')
  @ApiOperation({
    summary: 'Export bookings to CSV',
    description:
      'Exports booking data to a CSV file. Supports filtering by date range and status. Max 10,000 rows.',
  })
  @ApiProduces('text/csv')
  @ApiResponse({
    status: 200,
    description: 'CSV file download',
    content: {
      'text/csv': {
        schema: {
          type: 'string',
          format: 'binary',
        },
      },
    },
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - ADMIN/MANAGER role required',
  })
  async exportBookings(
    @Query() query: BookingExportQueryDto,
    @CurrentUser() user: { id: string; email: string },
    @Res() res: Response,
  ): Promise<void> {
    const csv = await this.exportsService.exportBookings(query, user);

    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="${getFilename('bookings')}"`,
    );
    res.send(csv);
  }

  @Get('invoices')
  @ApiOperation({
    summary: 'Export invoices to CSV',
    description:
      'Exports invoice data to a CSV file. Supports filtering by date range and status. Max 10,000 rows.',
  })
  @ApiProduces('text/csv')
  @ApiResponse({
    status: 200,
    description: 'CSV file download',
    content: {
      'text/csv': {
        schema: {
          type: 'string',
          format: 'binary',
        },
      },
    },
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - ADMIN/MANAGER role required',
  })
  async exportInvoices(
    @Query() query: InvoiceExportQueryDto,
    @CurrentUser() user: { id: string; email: string },
    @Res() res: Response,
  ): Promise<void> {
    const csv = await this.exportsService.exportInvoices(query, user);

    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="${getFilename('invoices')}"`,
    );
    res.send(csv);
  }

  @Get('reports')
  @ApiOperation({
    summary: 'Export reports/surveys to CSV',
    description:
      'Exports survey/report data to a CSV file. Supports filtering by date range and status. Max 10,000 rows.',
  })
  @ApiProduces('text/csv')
  @ApiResponse({
    status: 200,
    description: 'CSV file download',
    content: {
      'text/csv': {
        schema: {
          type: 'string',
          format: 'binary',
        },
      },
    },
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - ADMIN/MANAGER role required',
  })
  async exportReports(
    @Query() query: ReportExportQueryDto,
    @CurrentUser() user: { id: string; email: string },
    @Res() res: Response,
  ): Promise<void> {
    const csv = await this.exportsService.exportReports(query, user);

    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="${getFilename('reports')}"`,
    );
    res.send(csv);
  }
}
