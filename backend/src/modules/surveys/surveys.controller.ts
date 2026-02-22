import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  HttpCode,
  HttpStatus,
  UseGuards,
  ParseUUIDPipe,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
  ApiQuery,
  ApiConsumes,
  ApiBody,
} from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { UserRole } from '@prisma/client';
import { SurveysService } from './surveys.service';
import { CreateSurveyDto } from './dto/create-survey.dto';
import { UpdateSurveyDto } from './dto/update-survey.dto';
import { SurveyResponseDto } from './dto/survey-response.dto';
import { ListSurveysDto } from './dto/list-surveys.dto';
import {
  SurveyListResponseDto,
  DeleteSurveyResponseDto,
} from './dto/survey-list-response.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { NotificationEmailService } from '../notifications/notification-email.service';
import { SendReportDto, SendReportResponseDto } from './dto/send-report.dto';
import { ReportDataResponseDto } from './dto/report-data.dto';

interface AuthenticatedUser {
  id: string;
  email: string;
  firstName?: string;
  lastName?: string;
  role: UserRole;
}

@ApiTags('Surveys')
@ApiBearerAuth('JWT-auth')
@Controller('surveys')
@UseGuards(JwtAuthGuard, RolesGuard)
export class SurveysController {
  constructor(
    private readonly surveysService: SurveysService,
    private readonly notificationEmailService: NotificationEmailService,
  ) {}

  @Get()
  @Roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.SURVEYOR, UserRole.VIEWER)
  @ApiOperation({ summary: 'Search and list surveys with pagination and filtering' })
  @ApiQuery({
    name: 'q',
    required: false,
    type: String,
    description: 'Search query - searches title, client name, property address, and job ref',
    example: 'Main Street',
  })
  @ApiQuery({
    name: 'page',
    required: false,
    type: Number,
    description: 'Page number (1-based)',
    example: 1,
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    type: Number,
    description: 'Items per page (1-100)',
    example: 20,
  })
  @ApiQuery({
    name: 'status',
    required: false,
    enum: ['DRAFT', 'IN_PROGRESS', 'PAUSED', 'COMPLETED', 'PENDING_REVIEW', 'APPROVED', 'REJECTED'],
    description: 'Filter by survey status',
  })
  @ApiQuery({
    name: 'type',
    required: false,
    enum: ['INSPECTION', 'VALUATION', 'REINSPECTION', 'OTHER', 'LEVEL_2', 'LEVEL_3', 'SNAGGING'],
    description: 'Filter by survey type',
  })
  @ApiQuery({
    name: 'clientName',
    required: false,
    type: String,
    description: 'Filter by client name (partial match)',
    example: 'Smith',
  })
  @ApiQuery({
    name: 'createdFrom',
    required: false,
    type: String,
    description: 'Filter surveys created on or after this date (ISO 8601)',
    example: '2024-01-01T00:00:00.000Z',
  })
  @ApiQuery({
    name: 'createdTo',
    required: false,
    type: String,
    description: 'Filter surveys created on or before this date (ISO 8601)',
    example: '2024-12-31T23:59:59.999Z',
  })
  @ApiResponse({
    status: 200,
    description: 'Paginated list of surveys matching search criteria',
    type: SurveyListResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - insufficient role' })
  async findAll(
    @Query() query: ListSurveysDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<SurveyListResponseDto> {
    return this.surveysService.findAll(query, user);
  }

  @Post()
  @Roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.SURVEYOR)
  @HttpCode(HttpStatus.CREATED)
  // Relaxed rate limits for offline-first sync: multiple surveys may be
  // created rapidly when the mobile app comes online after extended offline use.
  @Throttle({
    short: { limit: 20, ttl: 1000 },
    medium: { limit: 120, ttl: 10000 },
    long: { limit: 600, ttl: 60000 },
  })
  @ApiOperation({ summary: 'Create a new survey with sections and answers' })
  @ApiResponse({
    status: 201,
    description: 'Survey created successfully',
    type: SurveyResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Validation error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - insufficient role' })
  async create(
    @Body() dto: CreateSurveyDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<SurveyResponseDto> {
    return this.surveysService.create(dto, user);
  }

  @Get(':id/report-data')
  @Roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.SURVEYOR, UserRole.VIEWER)
  @ApiOperation({
    summary: 'Get report-ready data with resolved display values for PDF generation',
  })
  @ApiParam({
    name: 'id',
    description: 'Survey UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Report data with resolved field labels and display values',
    type: ReportDataResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - not owner or admin' })
  @ApiResponse({ status: 404, description: 'Survey not found' })
  async getReportData(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<ReportDataResponseDto> {
    return this.surveysService.getReportData(id, user);
  }

  @Get(':id')
  @Roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.SURVEYOR, UserRole.VIEWER)
  @ApiOperation({ summary: 'Get a survey by ID with all sections and answers' })
  @ApiParam({
    name: 'id',
    description: 'Survey UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Survey retrieved successfully',
    type: SurveyResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - not owner or admin' })
  @ApiResponse({ status: 404, description: 'Survey not found' })
  async findOne(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<SurveyResponseDto> {
    return this.surveysService.findOne(id, user);
  }

  @Put(':id')
  @Roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.SURVEYOR)
  // Relaxed rate limits for offline-first sync.
  @Throttle({
    short: { limit: 20, ttl: 1000 },
    medium: { limit: 120, ttl: 10000 },
    long: { limit: 600, ttl: 60000 },
  })
  @ApiOperation({ summary: 'Update a survey with sections and answers' })
  @ApiParam({
    name: 'id',
    description: 'Survey UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Survey updated successfully',
    type: SurveyResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Validation error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - not owner or admin' })
  @ApiResponse({ status: 404, description: 'Survey not found' })
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateSurveyDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<SurveyResponseDto> {
    return this.surveysService.update(id, dto, user);
  }

  @Delete(':id')
  @Roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.SURVEYOR)
  @ApiOperation({ summary: 'Soft delete a survey (marks as deleted)' })
  @ApiParam({
    name: 'id',
    description: 'Survey UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Survey soft-deleted successfully',
    type: DeleteSurveyResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - not owner or admin' })
  @ApiResponse({ status: 404, description: 'Survey not found' })
  async remove(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<DeleteSurveyResponseDto> {
    return this.surveysService.softDelete(id, user);
  }

  @Post(':id/report-pdf')
  @Roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.SURVEYOR)
  @Throttle({ default: { limit: 10, ttl: 60000 } }) // SEC-L8: 10 uploads per minute
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Upload report PDF for a survey (after staff export)' })
  @ApiParam({
    name: 'id',
    description: 'Survey UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: {
          type: 'string',
          format: 'binary',
          description: 'PDF file',
        },
      },
    },
  })
  @ApiResponse({
    status: 201,
    description: 'Report PDF uploaded successfully',
    schema: {
      type: 'object',
      properties: {
        success: { type: 'boolean' },
        storagePath: { type: 'string' },
      },
    },
  })
  @ApiResponse({ status: 400, description: 'Invalid file or missing PDF' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - not owner or admin' })
  @ApiResponse({ status: 404, description: 'Survey not found' })
  async uploadReportPdf(
    @Param('id', ParseUUIDPipe) id: string,
    @UploadedFile() file: Express.Multer.File,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<{ success: boolean; storagePath: string }> {
    if (!file) {
      throw new BadRequestException('PDF file is required');
    }

    if (file.mimetype !== 'application/pdf') {
      throw new BadRequestException('Only PDF files are allowed');
    }

    // Validate PDF magic bytes - PDF files must start with "%PDF-" (hex: 25 50 44 46 2D)
    // This prevents attackers from spoofing Content-Type header to upload malicious files
    const pdfMagicBytes = Buffer.from([0x25, 0x50, 0x44, 0x46, 0x2d]); // %PDF-
    if (
      file.buffer.length < 5 ||
      !file.buffer.subarray(0, 5).equals(pdfMagicBytes)
    ) {
      throw new BadRequestException(
        'Invalid PDF file: file does not have valid PDF signature',
      );
    }

    // Max 50MB for report PDFs
    const maxSize = 50 * 1024 * 1024;
    if (file.size > maxSize) {
      throw new BadRequestException('PDF file too large. Maximum size: 50MB');
    }

    return this.surveysService.uploadReportPdf(id, file.buffer, user);
  }

  @Post(':id/send-report')
  @Roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.SURVEYOR)
  @Throttle({ default: { limit: 5, ttl: 60000 } }) // SEC-L8: 5 emails per minute — prevent email flooding
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Send survey report PDF via email' })
  @ApiParam({
    name: 'id',
    description: 'Survey UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Report email sent successfully',
    type: SendReportResponseDto,
  })
  @ApiResponse({ status: 400, description: 'No PDF available or email send failed' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - not owner or admin' })
  @ApiResponse({ status: 404, description: 'Survey not found' })
  async sendReport(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SendReportDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<SendReportResponseDto> {
    return this.surveysService.sendSurveyReport(
      id,
      dto.email,
      user,
      this.notificationEmailService,
    );
  }
}
