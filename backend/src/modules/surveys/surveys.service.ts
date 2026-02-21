import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  ConflictException,
  Inject,
  Logger,
} from '@nestjs/common';
import { UserRole, Prisma, SurveyType, SurveyStatus, ActorType, AuditEntityType } from '@prisma/client';
import { AuditService, AuditActions } from '../audit/audit.service';
import { PrismaService } from '../prisma/prisma.service';
import { WebhookDispatcherService } from '../webhooks/webhook-dispatcher.service';
import { StorageService, STORAGE_SERVICE } from '../media/storage/storage.interface';
import { validateSurveyTransition } from '../../common/survey-status';
import { CreateSurveyDto } from './dto/create-survey.dto';
import { UpdateSurveyDto } from './dto/update-survey.dto';
import { SurveyResponseDto } from './dto/survey-response.dto';
import { ListSurveysDto } from './dto/list-surveys.dto';
import {
  SurveyListResponseDto,
  SurveyListItemDto,
  DeleteSurveyResponseDto,
} from './dto/survey-list-response.dto';
import {
  ReportDataResponseDto,
  ReportSectionDto,
  ReportFieldDto,
} from './dto/report-data.dto';

interface AuthenticatedUser {
  id: string;
  role: UserRole;
}

@Injectable()
export class SurveysService {
  private readonly logger = new Logger(SurveysService.name);

  /**
   * Survey states that allow PDF report uploads.
   *
   * All active states are allowed — surveyors need interim reports during
   * fieldwork (DRAFT, IN_PROGRESS, PAUSED) and final reports for review
   * (COMPLETED, PENDING_REVIEW, APPROVED). Only REJECTED is excluded
   * because rejected surveys should be revised before generating reports.
   */
  private readonly ALLOWED_PDF_UPLOAD_STATES: SurveyStatus[] = [
    SurveyStatus.DRAFT,
    SurveyStatus.IN_PROGRESS,
    SurveyStatus.PAUSED,
    SurveyStatus.COMPLETED,
    SurveyStatus.PENDING_REVIEW,
    SurveyStatus.APPROVED,
  ];

  /**
   * Validate parent survey reference.
   * Ensures parent survey exists, is not deleted, and prevents circular references.
   */
  private async validateParentSurvey(
    parentSurveyId: string,
    currentSurveyId?: string,
  ): Promise<void> {
    const parentSurvey = await this.prisma.survey.findUnique({
      where: { id: parentSurveyId },
      select: { id: true, deletedAt: true, parentSurveyId: true },
    });

    if (!parentSurvey) {
      throw new BadRequestException(
        `Parent survey with ID '${parentSurveyId}' does not exist`,
      );
    }

    if (parentSurvey.deletedAt !== null) {
      throw new BadRequestException(
        `Parent survey with ID '${parentSurveyId}' has been deleted`,
      );
    }

    // Prevent circular reference (survey cannot be its own parent)
    if (currentSurveyId && parentSurveyId === currentSurveyId) {
      throw new BadRequestException(
        'A survey cannot be its own parent',
      );
    }

    // Prevent multi-level circular reference (parent's parent cannot be this survey)
    if (currentSurveyId && parentSurvey.parentSurveyId === currentSurveyId) {
      throw new BadRequestException(
        'Circular parent reference detected',
      );
    }
  }

  constructor(
    private readonly prisma: PrismaService,
    @Inject(STORAGE_SERVICE) private readonly storageService: StorageService,
    private readonly auditService: AuditService,
    private readonly webhookDispatcher: WebhookDispatcherService,
  ) {}

  async findAll(
    query: ListSurveysDto,
    user: AuthenticatedUser,
  ): Promise<SurveyListResponseDto> {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const skip = (page - 1) * limit;

    const where: Prisma.SurveyWhereInput = {
      deletedAt: null,
    };

    // User scope (ADMIN sees all, others see only their own)
    if (user.role !== UserRole.ADMIN) {
      where.userId = user.id;
    }

    // Text search across title, clientName, and propertyAddress
    if (query.q) {
      const searchTerm = query.q.toLowerCase();
      where.OR = [
        { title: { contains: searchTerm, mode: 'insensitive' } },
        { clientName: { contains: searchTerm, mode: 'insensitive' } },
        { propertyAddress: { contains: searchTerm, mode: 'insensitive' } },
        { jobRef: { contains: searchTerm, mode: 'insensitive' } },
      ];
    }

    // Status filter
    if (query.status) {
      where.status = query.status;
    }

    // Type filter
    if (query.type) {
      where.type = query.type;
    }

    // Client name filter (separate from text search for specific filtering)
    if (query.clientName) {
      where.clientName = { contains: query.clientName, mode: 'insensitive' };
    }

    // Date range filter
    if (query.createdFrom || query.createdTo) {
      where.createdAt = {};
      if (query.createdFrom) {
        where.createdAt.gte = new Date(query.createdFrom);
      }
      if (query.createdTo) {
        where.createdAt.lte = new Date(query.createdTo);
      }
    }

    this.logger.debug(`Search query: ${JSON.stringify(query)}`);

    const [total, surveys] = await Promise.all([
      this.prisma.survey.count({ where }),
      this.prisma.survey.findMany({
        where,
        orderBy: { updatedAt: 'desc' },
        skip,
        take: limit,
        select: {
          id: true,
          title: true,
          propertyAddress: true,
          status: true,
          type: true,
          jobRef: true,
          clientName: true,
          userId: true,
          createdAt: true,
          updatedAt: true,
        },
      }),
    ]);

    const totalPages = Math.ceil(total / limit);

    const data: SurveyListItemDto[] = surveys.map((survey) => ({
      id: survey.id,
      title: survey.title,
      propertyAddress: survey.propertyAddress,
      status: survey.status,
      type: survey.type ?? undefined,
      jobRef: survey.jobRef ?? undefined,
      clientName: survey.clientName ?? undefined,
      userId: survey.userId,
      createdAt: survey.createdAt,
      updatedAt: survey.updatedAt,
    }));

    return {
      data,
      meta: {
        page,
        limit,
        total,
        totalPages,
        hasNext: page < totalPages,
        hasPrev: page > 1,
      },
    };
  }

  async create(
    dto: CreateSurveyDto,
    user: AuthenticatedUser,
  ): Promise<SurveyResponseDto> {
    // Validate parent survey reference if provided
    if (dto.parentSurveyId) {
      await this.validateParentSurvey(dto.parentSurveyId);
    }

    let survey;
    try {
      survey = await this.prisma.$transaction(async (tx) => {
        const createdSurvey = await tx.survey.create({
          data: {
            // Support client-provided UUID for offline-first sync
            ...(dto.id ? { id: dto.id } : {}),
            title: dto.title,
            propertyAddress: dto.propertyAddress,
            status: dto.status,
            type: dto.type,
            jobRef: dto.jobRef,
            clientName: dto.clientName,
            parentSurveyId: dto.parentSurveyId,
            userId: user.id,
            sections: dto.sections
              ? {
                  create: dto.sections.map((section, index) => ({
                    title: section.title,
                    sectionTypeKey: section.sectionTypeKey,
                    order: section.order ?? index,
                    answers: section.answers
                      ? {
                          create: section.answers.map((answer) => ({
                            questionKey: answer.questionKey,
                            value: answer.value,
                          })),
                        }
                      : undefined,
                  })),
                }
              : undefined,
          },
          include: {
            sections: {
              include: {
                answers: true,
              },
              orderBy: {
                order: 'asc',
              },
            },
          },
        });

        return createdSurvey;
      });
    } catch (error: any) {
      // Handle duplicate ID conflict (Prisma P2002)
      if (error?.code === 'P2002') {
        throw new ConflictException(
          `Survey with the provided ID already exists`,
        );
      }
      throw error;
    }

    this.logger.log('Survey created: ' + survey.id + ' by user: ' + user.id);

    return this.mapToResponse(survey);
  }

  async findOne(
    id: string,
    user: AuthenticatedUser,
  ): Promise<SurveyResponseDto> {
    const survey = await this.prisma.survey.findUnique({
      where: { id },
      include: {
        sections: {
          include: {
            answers: true,
          },
          orderBy: {
            order: 'asc',
          },
        },
      },
    });

    if (!survey || survey.deletedAt !== null) {
      throw new NotFoundException('Survey not found');
    }

    if (survey.userId !== user.id && user.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Access denied to this survey');
    }

    return this.mapToResponse(survey);
  }

  async update(
    id: string,
    dto: UpdateSurveyDto,
    user: AuthenticatedUser,
  ): Promise<SurveyResponseDto> {
    const existingSurvey = await this.prisma.survey.findUnique({
      where: { id },
    });

    if (!existingSurvey || existingSurvey.deletedAt !== null) {
      throw new NotFoundException('Survey not found');
    }

    if (existingSurvey.userId !== user.id && user.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Access denied to this survey');
    }

    // Validate status transition if status is being changed
    if (dto.status !== undefined) {
      validateSurveyTransition(existingSurvey.status, dto.status);
    }

    // Validate parent survey reference if being set or changed
    if (dto.parentSurveyId !== undefined && dto.parentSurveyId !== null) {
      await this.validateParentSurvey(dto.parentSurveyId, id);
    }

    const survey = await this.prisma.$transaction(async (tx) => {
      if (dto.sections !== undefined) {
        await tx.section.deleteMany({
          where: { surveyId: id },
        });
      }

      const updatedSurvey = await tx.survey.update({
        where: { id },
        data: {
          title: dto.title,
          propertyAddress: dto.propertyAddress,
          status: dto.status,
          type: dto.type,
          jobRef: dto.jobRef,
          clientName: dto.clientName,
          parentSurveyId: dto.parentSurveyId,
          sections:
            dto.sections !== undefined
              ? {
                  create: dto.sections.map((section, index) => ({
                    title: section.title,
                    sectionTypeKey: section.sectionTypeKey,
                    order: section.order ?? index,
                    answers: section.answers
                      ? {
                          create: section.answers.map((answer) => ({
                            questionKey: answer.questionKey,
                            value: answer.value,
                          })),
                        }
                      : undefined,
                  })),
                }
              : undefined,
        },
        include: {
          sections: {
            include: {
              answers: true,
            },
            orderBy: {
              order: 'asc',
            },
          },
        },
      });

      return updatedSurvey;
    });

    this.logger.log('Survey updated: ' + survey.id + ' by user: ' + user.id);

    // Dispatch REPORT_APPROVED webhook when status changes to APPROVED
    if (
      dto.status === SurveyStatus.APPROVED &&
      existingSurvey.status !== SurveyStatus.APPROVED
    ) {
      await this.webhookDispatcher.dispatchReportApproved({
        id: survey.id,
        title: survey.title,
        clientId: undefined, // Survey doesn't have clientId, omit
        userId: user.id,
      });
    }

    return this.mapToResponse(survey);
  }

  async softDelete(
    id: string,
    user: AuthenticatedUser,
  ): Promise<DeleteSurveyResponseDto> {
    const existingSurvey = await this.prisma.survey.findUnique({
      where: { id },
    });

    if (!existingSurvey || existingSurvey.deletedAt !== null) {
      throw new NotFoundException('Survey not found');
    }

    if (existingSurvey.userId !== user.id && user.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Access denied to this survey');
    }

    const deletedAt = new Date();

    await this.prisma.survey.update({
      where: { id },
      data: { deletedAt },
    });

    this.logger.log('Survey soft-deleted: ' + id + ' by user: ' + user.id);

    return {
      success: true,
      id,
      deletedAt,
    };
  }

  
  async verifySurveyOwnership(surveyId: string, user: AuthenticatedUser): Promise<void> {
    const survey = await this.prisma.survey.findUnique({
      where: { id: surveyId },
      select: { userId: true, deletedAt: true },
    });

    if (!survey || survey.deletedAt !== null) {
      throw new NotFoundException('Survey not found');
    }

    if (survey.userId !== user.id && user.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Access denied to this survey');
    }
  }

private mapToResponse(survey: {
    id: string;
    title: string;
    propertyAddress: string;
    status: SurveyStatus;
    type: SurveyType | null;
    jobRef: string | null;
    clientName: string | null;
    parentSurveyId: string | null;
    userId: string;
    createdAt: Date;
    updatedAt: Date;
    sections: Array<{
      id: string;
      title: string;
      sectionTypeKey?: string | null;
      order: number;
      createdAt: Date;
      updatedAt: Date;
      answers: Array<{
        id: string;
        questionKey: string;
        value: string;
        createdAt: Date;
        updatedAt: Date;
      }>;
    }>;
  }): SurveyResponseDto {
    return {
      id: survey.id,
      title: survey.title,
      propertyAddress: survey.propertyAddress,
      status: survey.status,
      type: survey.type ?? undefined,
      jobRef: survey.jobRef ?? undefined,
      clientName: survey.clientName ?? undefined,
      parentSurveyId: survey.parentSurveyId ?? undefined,
      userId: survey.userId,
      createdAt: survey.createdAt,
      updatedAt: survey.updatedAt,
      sections: survey.sections.map((section) => ({
        id: section.id,
        title: section.title,
        order: section.order,
        sectionTypeKey: section.sectionTypeKey ?? undefined,
        createdAt: section.createdAt,
        updatedAt: section.updatedAt,
        answers: section.answers.map((answer) => ({
          id: answer.id,
          questionKey: answer.questionKey,
          value: answer.value,
          createdAt: answer.createdAt,
          updatedAt: answer.updatedAt,
        })),
      })),
    };
  }

  /**
   * Get report-ready data for a survey with resolved display values.
   *
   * Loads the survey with all sections/answers, then enriches each answer
   * with the corresponding field definition label and resolved display value
   * from phrase categories. Fields without answers are included as
   * "Not assessed".
   */
  async getReportData(
    id: string,
    user: AuthenticatedUser,
  ): Promise<ReportDataResponseDto> {
    this.logger.log(`getReportData: surveyId=${id}, userId=${user.id}`);

    // Load survey with sections and answers
    const survey = await this.prisma.survey.findUnique({
      where: { id },
      include: {
        sections: {
          include: { answers: true },
          orderBy: { order: 'asc' },
        },
      },
    });

    if (!survey || survey.deletedAt !== null) {
      this.logger.warn(`getReportData: survey ${id} not found`);
      throw new NotFoundException('Survey not found');
    }

    if (survey.userId !== user.id && user.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Access denied to this survey');
    }

    this.logger.log(
      `getReportData: survey "${survey.title}" has ${survey.sections.length} sections`,
    );

    // Load all section type definitions to map section titles → sectionType keys
    const sectionTypeDefs = await this.prisma.sectionTypeDefinition.findMany({
      where: { isActive: true, deletedAt: null },
    });

    // Build a lookup: label (lowercase) → key
    const labelToKey = new Map<string, string>();
    for (const st of sectionTypeDefs) {
      labelToKey.set(st.label.toLowerCase(), st.key);
    }

    // Title alias map for known mismatches between Flutter template titles and seed labels
    const titleAliasToKey = new Map<string, string>([
      ['about this inspection', 'about-inspection'],
      ['construction details', 'construction'],
      ['room details', 'rooms'],
      ['services & utilities', 'services'],
      ['photo documentation', 'photos'],
      ['photo evidence', 'photos'],
      ['additional notes', 'notes'],
      ['sign off', 'signature'],
      ['comparable properties', 'comparables'],
      ['final valuation', 'valuation'],
      ['notes & assumptions', 'notes'],
      ['summary & conclusion', 'summary'],
      ['property information', 'about-property'],
      ['about this property', 'about-property'],
      ['valuation assessment', 'valuation'],
      ['exterior assessment', 'exterior'],
      ['interior assessment', 'interior'],
      ['issues & defects', 'issues-and-risks'],
      ['issues & risks', 'issues-and-risks'],
      ['about this valuation', 'about-valuation'],
    ]);

    // Resolve section type key with fallback chain:
    // 1. section.sectionTypeKey (stored directly from Flutter)
    // 2. labelToKey (exact label match from SectionTypeDefinition)
    // 3. titleAliasToKey (known title mismatches)
    const resolveSectionTypeKey = (section: { sectionTypeKey?: string | null; title: string }): string | undefined => {
      if (section.sectionTypeKey) return section.sectionTypeKey;
      const titleLower = section.title.toLowerCase();
      return labelToKey.get(titleLower) ?? titleAliasToKey.get(titleLower);
    };

    // Collect all unique section type keys we need field definitions for
    const sectionTypeKeys = new Set<string>();
    for (const section of survey.sections) {
      const key = resolveSectionTypeKey(section);
      if (key) sectionTypeKeys.add(key);
    }

    // Load field definitions with phrase categories for all relevant section types
    const fieldDefinitions = await this.prisma.fieldDefinition.findMany({
      where: {
        sectionType: { in: Array.from(sectionTypeKeys) },
        isActive: true,
      },
      orderBy: { displayOrder: 'asc' },
      include: {
        phraseCategory: {
          include: {
            phrases: {
              where: { isActive: true },
              orderBy: { displayOrder: 'asc' },
            },
          },
        },
      },
    });

    // Group field definitions by section type
    const fieldsBySection = new Map<string, typeof fieldDefinitions>();
    for (const fd of fieldDefinitions) {
      const existing = fieldsBySection.get(fd.sectionType) ?? [];
      existing.push(fd);
      fieldsBySection.set(fd.sectionType, existing);
    }

    this.logger.log(
      `getReportData: ${sectionTypeDefs.length} section type definitions loaded, ` +
      `${fieldDefinitions.length} field definitions loaded`,
    );

    // Build enriched sections
    const reportSections: ReportSectionDto[] = survey.sections.map((section) => {
      const sectionTypeKey = resolveSectionTypeKey(section);
      const definitions = sectionTypeKey
        ? fieldsBySection.get(sectionTypeKey) ?? []
        : [];

      // Build answer lookup: questionKey → value
      const answerMap = new Map<string, string>();
      for (const answer of section.answers) {
        answerMap.set(answer.questionKey, answer.value);
      }

      this.logger.debug(
        `getReportData: section "${section.title}" → ` +
        `sectionTypeKey=${sectionTypeKey ?? 'NONE'}, ` +
        `definitions=${definitions.length}, answers=${answerMap.size}`,
      );

      const fields: ReportFieldDto[] = [];

      if (definitions.length > 0) {
        // We have field definitions — use them for labels and ordering
        for (const fd of definitions) {
          const rawValue = answerMap.get(fd.fieldKey);
          const displayValue = this.resolveDisplayValue(fd, rawValue);

          fields.push({
            fieldKey: fd.fieldKey,
            label: fd.label,
            fieldType: fd.fieldType.toLowerCase(),
            rawValue: rawValue ?? undefined,
            displayValue,
            fieldGroup: fd.fieldGroup ?? undefined,
            displayOrder: fd.displayOrder,
          });

          // Remove from answerMap so we can detect unmatched answers
          answerMap.delete(fd.fieldKey);
        }
      }

      // Add any answers that didn't match a field definition (legacy or custom fields)
      for (const [key, value] of answerMap) {
        fields.push({
          fieldKey: key,
          label: this.formatFieldKey(key),
          fieldType: 'text',
          rawValue: value,
          displayValue: value || 'Not assessed',
          fieldGroup: undefined,
          displayOrder: fields.length,
        });
      }

      if (fields.length === 0 && answerMap.size === 0) {
        this.logger.debug(
          `getReportData: section "${section.title}" has 0 answers in DB ` +
          `(${section.answers?.length ?? 0} raw answer rows)`,
        );
      }

      return {
        id: section.id,
        title: section.title,
        order: section.order,
        sectionTypeKey,
        fields,
      };
    });

    const totalFields = reportSections.reduce(
      (sum, s) => sum + s.fields.length,
      0,
    );
    this.logger.log(
      `getReportData: returning ${reportSections.length} sections with ${totalFields} total fields`,
    );

    return {
      id: survey.id,
      title: survey.title,
      propertyAddress: survey.propertyAddress,
      status: survey.status,
      type: survey.type ?? undefined,
      jobRef: survey.jobRef ?? undefined,
      clientName: survey.clientName ?? undefined,
      createdAt: survey.createdAt,
      updatedAt: survey.updatedAt,
      sections: reportSections,
    };
  }

  /**
   * Resolve a raw answer value to a human-readable display string.
   *
   * For dropdown/radio/checkbox fields with a phrase category, the raw value
   * is already the phrase label (by convention in this app), so we return it
   * as-is. For boolean-like values, we map to Yes/No. For empty/missing
   * values, we return "Not assessed".
   */
  private resolveDisplayValue(
    fd: {
      fieldType: string;
      phraseCategory?: {
        phrases: Array<{ value: string }>;
      } | null;
    },
    rawValue: string | undefined,
  ): string {
    if (rawValue === undefined || rawValue === null || rawValue === '') {
      return 'Not assessed';
    }

    const fieldType = fd.fieldType.toLowerCase();

    // Boolean mapping
    if (rawValue === 'true') return 'Yes';
    if (rawValue === 'false') return 'No';

    // For selection fields, the stored value is already the phrase label.
    // But verify it matches a known phrase; if not, return the raw value.
    if (
      (fieldType === 'dropdown' || fieldType === 'radio' || fieldType === 'checkbox') &&
      fd.phraseCategory?.phrases
    ) {
      const phrases = fd.phraseCategory.phrases.map((p) => p.value);
      // For checkbox, the value might be a JSON array
      if (fieldType === 'checkbox') {
        try {
          const parsed = JSON.parse(rawValue);
          if (Array.isArray(parsed)) {
            return parsed
              .map((v: string) => phrases.includes(v) ? v : v)
              .join(', ');
          }
        } catch {
          // Not JSON — return as-is
        }
      }
      // For dropdown/radio, return the value (it should already be the label)
      return rawValue;
    }

    return rawValue;
  }

  /**
   * Convert a field key like "property_type" or "propertyType" to "Property Type".
   * Used as fallback label when no FieldDefinition exists.
   */
  private formatFieldKey(key: string): string {
    return key
      .replace(/([a-z])([A-Z])/g, '$1 $2')
      .replace(/_/g, ' ')
      .split(' ')
      .map((word) =>
        word.length > 0
          ? word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()
          : '',
      )
      .join(' ')
      .trim();
  }

  /**
   * Upload and store a report PDF for a survey.
   * Called after staff exports a PDF from the mobile app.
   * Only allowed for surveys in COMPLETED, PENDING_REVIEW, or APPROVED states.
   */
  async uploadReportPdf(
    surveyId: string,
    pdfBuffer: Buffer,
    user: AuthenticatedUser,
  ): Promise<{ success: boolean; storagePath: string }> {
    // Verify survey exists and user has access
    const survey = await this.prisma.survey.findUnique({
      where: { id: surveyId },
      select: { id: true, userId: true, deletedAt: true, status: true },
    });

    if (!survey) {
      throw new NotFoundException('Survey not found');
    }

    if (survey.userId !== user.id && user.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Access denied to this survey');
    }

    // Allow uploading PDFs for soft-deleted surveys to support archival/reporting flows.
    // We still enforce ownership/admin access above.
    const isSoftDeleted = survey.deletedAt !== null;
    if (isSoftDeleted) {
      this.logger.warn(
        `Uploading report PDF for soft-deleted survey ${surveyId} by user ${user.id}`,
      );
    }

    // Validate survey status - only allow PDF upload for completed/reviewed/approved surveys
    if (!this.ALLOWED_PDF_UPLOAD_STATES.includes(survey.status)) {
      throw new BadRequestException(
        `Cannot upload PDF report for survey in ${survey.status} status. ` +
        `PDF upload is only allowed for surveys in: ${this.ALLOWED_PDF_UPLOAD_STATES.join(', ')}`,
      );
    }

    // Generate unique file ID for the PDF
    const { randomUUID } = require('crypto');
    const fileId = randomUUID();

    // Store PDF in reports/{surveyId}/ directory
    const storagePath = await this.storageService.store(
      `reports/${surveyId}`,
      fileId,
      pdfBuffer,
      'pdf',
    );

    // Update survey with the PDF path
    await this.prisma.survey.update({
      where: { id: surveyId },
      data: { reportPdfPath: storagePath },
    });

    this.logger.log(`Report PDF uploaded for survey ${surveyId}: ${storagePath}`);

    // Audit log
    await this.auditService.log({
      actorType: ActorType.STAFF,
      actorId: user.id,
      action: AuditActions.REPORT_PDF_UPLOADED,
      entityType: AuditEntityType.REPORT_PDF,
      entityId: surveyId,
      metadata: { storagePath },
    });

    return { success: true, storagePath };
  }

  /**
   * Get the stored report PDF path for a survey.
   */
  async getReportPdfPath(surveyId: string): Promise<string | null> {
    const survey = await this.prisma.survey.findUnique({
      where: { id: surveyId },
      select: { reportPdfPath: true },
    });

    return survey?.reportPdfPath ?? null;
  }

  /**
   * Retrieve the report PDF buffer from storage.
   */
  async getReportPdfBuffer(storagePath: string): Promise<Buffer> {
    return this.storageService.retrieve(storagePath);
  }

  /**
   * Send a survey report PDF via email.
   * Retrieves the stored PDF and delegates to NotificationEmailService.
   */
  async sendSurveyReport(
    surveyId: string,
    recipientEmail: string,
    user: AuthenticatedUser & { email: string; firstName?: string; lastName?: string },
    emailService: {
      sendSurveyReportEmail: (
        email: string,
        title: string,
        pdf: Buffer,
        sender: string,
      ) => Promise<boolean>;
    },
  ): Promise<{ success: boolean; message: string; recipientEmail: string }> {
    // Verify survey exists and user has access
    const survey = await this.prisma.survey.findUnique({
      where: { id: surveyId },
      select: {
        id: true,
        userId: true,
        title: true,
        reportPdfPath: true,
        deletedAt: true,
        status: true,
      },
    });

    if (!survey) {
      throw new NotFoundException('Survey not found');
    }

    if (survey.userId !== user.id && user.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Access denied to this survey');
    }

    if (!survey.reportPdfPath) {
      throw new BadRequestException(
        'No PDF report available for this survey. Please generate and upload the report first.',
      );
    }

    // Retrieve the PDF from storage
    let pdfBuffer: Buffer;
    try {
      pdfBuffer = await this.storageService.retrieve(survey.reportPdfPath);
    } catch {
      throw new BadRequestException(
        'PDF report file could not be retrieved. Please regenerate and upload the report.',
      );
    }

    // Build sender name
    const senderName = [user.firstName, user.lastName]
      .filter(Boolean)
      .join(' ') || 'Staff';

    // Send via email service
    const sent = await emailService.sendSurveyReportEmail(
      recipientEmail,
      survey.title,
      pdfBuffer,
      senderName,
    );

    if (!sent) {
      throw new BadRequestException(
        'Failed to send email. Please check SMTP configuration or try again later.',
      );
    }

    // Audit log
    await this.auditService.log({
      actorType: ActorType.STAFF,
      actorId: user.id,
      action: AuditActions.REPORT_EMAIL_SENT,
      entityType: AuditEntityType.REPORT_PDF,
      entityId: surveyId,
      metadata: { recipientEmail, surveyTitle: survey.title },
    });

    this.logger.log(
      `Survey report emailed for survey ${surveyId} to ${recipientEmail} by user ${user.id}`,
    );

    return {
      success: true,
      message: `Report sent to ${recipientEmail}`,
      recipientEmail,
    };
  }
}
