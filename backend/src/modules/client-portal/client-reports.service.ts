import { Injectable, NotFoundException, Inject, Logger } from '@nestjs/common';
import { SurveyStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService, STORAGE_SERVICE } from '../media/storage/storage.interface';
import {
  ClientReportsQueryDto,
  ClientReportsResponseDto,
  ClientReportDto,
  ClientReportDetailDto,
} from './dto/client-reports.dto';

@Injectable()
export class ClientReportsService {
  private readonly logger = new Logger(ClientReportsService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Inject(STORAGE_SERVICE) private readonly storageService: StorageService,
  ) {}

  /**
   * Get all approved reports for a client.
   * SECURITY: Only returns APPROVED surveys for the specific client.
   */
  async getClientReports(
    clientId: string,
    query: ClientReportsQueryDto,
  ): Promise<ClientReportsResponseDto> {
    const { page = 1, limit = 20 } = query;
    const skip = (page - 1) * limit;

    const where = {
      clientId,
      status: SurveyStatus.APPROVED, // Only approved reports visible to clients
      deletedAt: null,
    };

    const [surveys, total] = await Promise.all([
      this.prisma.survey.findMany({
        where,
        include: {
          user: {
            select: {
              firstName: true,
              lastName: true,
            },
          },
        },
        orderBy: { updatedAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.survey.count({ where }),
    ]);

    const data: ClientReportDto[] = surveys.map((survey) => ({
      id: survey.id,
      title: survey.title,
      propertyAddress: survey.propertyAddress,
      type: survey.type ?? undefined,
      status: survey.status,
      jobRef: survey.jobRef ?? undefined,
      surveyor: {
        firstName: survey.user.firstName ?? '',
        lastName: survey.user.lastName ?? '',
      },
      createdAt: survey.createdAt,
      updatedAt: survey.updatedAt,
    }));

    return {
      data,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Get a single report by ID.
   * SECURITY: Validates report is APPROVED and belongs to client.
   */
  async getClientReport(
    clientId: string,
    reportId: string,
  ): Promise<ClientReportDetailDto> {
    const survey = await this.prisma.survey.findFirst({
      where: {
        id: reportId,
        clientId, // SECURITY: Ensure report belongs to this client
        status: SurveyStatus.APPROVED, // Only approved reports
        deletedAt: null,
      },
      include: {
        user: {
          select: {
            firstName: true,
            lastName: true,
          },
        },
        sections: {
          select: { id: true },
        },
        media: {
          where: { deletedAt: null },
          select: { id: true },
        },
      },
    });

    if (!survey) {
      throw new NotFoundException('Report not found');
    }

    return {
      id: survey.id,
      title: survey.title,
      propertyAddress: survey.propertyAddress,
      type: survey.type ?? undefined,
      status: survey.status,
      jobRef: survey.jobRef ?? undefined,
      surveyor: {
        firstName: survey.user.firstName ?? '',
        lastName: survey.user.lastName ?? '',
      },
      createdAt: survey.createdAt,
      updatedAt: survey.updatedAt,
      sectionCount: survey.sections.length,
      photoCount: survey.media.length,
    };
  }

  /**
   * Verify client has access to a report (for PDF download).
   * Returns the survey if access is allowed.
   */
  async verifyReportAccess(
    clientId: string,
    reportId: string,
  ): Promise<{ id: string; title: string; propertyAddress: string }> {
    const survey = await this.prisma.survey.findFirst({
      where: {
        id: reportId,
        clientId,
        status: SurveyStatus.APPROVED,
        deletedAt: null,
      },
      select: {
        id: true,
        title: true,
        propertyAddress: true,
      },
    });

    if (!survey) {
      throw new NotFoundException('Report not found or access denied');
    }

    return survey;
  }

  /**
   * Get the report PDF for download.
   * SECURITY: Validates report is APPROVED and belongs to client.
   * Returns the PDF buffer and filename if available.
   */
  async getReportPdf(
    clientId: string,
    reportId: string,
  ): Promise<{ buffer: Buffer; title: string } | null> {
    const survey = await this.prisma.survey.findFirst({
      where: {
        id: reportId,
        clientId,
        status: SurveyStatus.APPROVED,
        deletedAt: null,
      },
      select: {
        id: true,
        title: true,
        reportPdfPath: true,
      },
    });

    if (!survey) {
      throw new NotFoundException('Report not found or access denied');
    }

    // Check if PDF has been generated and stored
    if (!survey.reportPdfPath) {
      return null; // PDF not yet available
    }

    // Retrieve the PDF from storage
    try {
      const buffer = await this.storageService.retrieve(survey.reportPdfPath);
      return { buffer, title: survey.title };
    } catch (error) {
      this.logger.error(
        `Failed to retrieve PDF for report ${reportId}: ${error}`,
      );
      return null;
    }
  }
}
