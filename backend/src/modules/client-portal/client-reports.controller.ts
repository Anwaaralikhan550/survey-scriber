import {
  Controller,
  Get,
  Param,
  Query,
  UseGuards,
  Request,
  ParseUUIDPipe,
  Res,
  StreamableFile,
} from '@nestjs/common';
import { sanitizeFilename } from '../../common/utils/sanitize-filename';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
  ApiProduces,
} from '@nestjs/swagger';
import { Response, Request as ExpressRequest } from 'express';
import { ClientReportsService } from './client-reports.service';
import { ClientJwtGuard } from './guards/client-jwt.guard';
import {
  ClientReportsQueryDto,
  ClientReportsResponseDto,
  ClientReportDetailDto,
} from './dto/client-reports.dto';

interface ClientRequest extends ExpressRequest {
  user: { id: string; email: string; type: string };
}

@ApiTags('Client Portal - Reports')
@Controller('client/reports')
@UseGuards(ClientJwtGuard)
@ApiBearerAuth()
export class ClientReportsController {
  constructor(private readonly clientReportsService: ClientReportsService) {}

  @Get()
  @ApiOperation({
    summary: 'List client reports',
    description: 'Returns all approved survey reports for the authenticated client.',
  })
  @ApiResponse({
    status: 200,
    description: 'List of approved reports',
    type: ClientReportsResponseDto,
  })
  async getReports(
    @Request() req: ClientRequest,
    @Query() query: ClientReportsQueryDto,
  ): Promise<ClientReportsResponseDto> {
    return this.clientReportsService.getClientReports(req.user.id, query);
  }

  @Get(':id')
  @ApiOperation({
    summary: 'Get report details',
    description: 'Returns details of a specific approved report.',
  })
  @ApiParam({
    name: 'id',
    description: 'Report/Survey ID',
    type: String,
  })
  @ApiResponse({
    status: 200,
    description: 'Report details',
    type: ClientReportDetailDto,
  })
  @ApiResponse({
    status: 404,
    description: 'Report not found',
  })
  async getReport(
    @Request() req: ClientRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ClientReportDetailDto> {
    return this.clientReportsService.getClientReport(req.user.id, id);
  }

  @Get(':id/download')
  @ApiOperation({
    summary: 'Download report PDF',
    description: 'Downloads the PDF version of an approved report.',
  })
  @ApiParam({
    name: 'id',
    description: 'Report/Survey ID',
    type: String,
  })
  @ApiProduces('application/pdf')
  @ApiResponse({
    status: 200,
    description: 'PDF file stream',
  })
  @ApiResponse({
    status: 404,
    description: 'Report not found or PDF not yet available',
  })
  async downloadReport(
    @Request() req: ClientRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Res({ passthrough: true }) res: Response,
  ): Promise<StreamableFile | { message: string }> {
    // Get the report PDF (also validates client access)
    const result = await this.clientReportsService.getReportPdf(
      req.user.id,
      id,
    );

    // If no PDF is available yet, return informative message
    if (!result) {
      res.status(404);
      return {
        message: 'PDF not yet available. The surveyor needs to export the report first.',
      };
    }

    // Set headers for PDF download
    const filename = sanitizeFilename(result.title) + '.pdf';
    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': `attachment; filename="${filename}"`,
      'Content-Length': result.buffer.length,
      // Cache headers: PDFs can be cached but may be regenerated
      'Cache-Control': 'private, max-age=3600', // 1 hour cache
    });

    return new StreamableFile(result.buffer);
  }
}
