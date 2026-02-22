import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { UserRole, SurveyStatus, SurveyType } from '@prisma/client';
import { createHash } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { ApiUrlBuilder } from '../../common/utils/api-url.util';
import {
  isValidSurveyTransition,
  isManagerOnlyTransition,
} from '../../common/survey-status';
import {
  SyncPushDto,
  SyncOperationDto,
  SyncOperationType,
  SyncEntityType,
  SyncPullDto,
  SyncPushResponseDto,
  SyncOperationResultDto,
  SyncPullResponseDto,
  SyncEntityDto,
} from './dto';

interface AuthenticatedUser {
  id: string;
  role: UserRole;
}

@Injectable()
export class SyncService {
  private readonly logger = new Logger(SyncService.name);
  private readonly urlBuilder: ApiUrlBuilder;

  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {
    this.urlBuilder = new ApiUrlBuilder(configService);
  }

  async push(
    dto: SyncPushDto,
    user: AuthenticatedUser,
  ): Promise<SyncPushResponseDto> {
    const requestHash = this.hashRequest(dto);

    // Check for duplicate batch (idempotency)
    const existingBatch = await this.prisma.syncIdempotency.findUnique({
      where: {
        userId_idempotencyKey: {
          userId: user.id,
          idempotencyKey: dto.idempotencyKey,
        },
      },
    });

    if (existingBatch) {
      this.logger.log(
        'Duplicate batch detected: ' + dto.idempotencyKey + ' for user: ' + user.id,
      );
      return {
        success: true,
        idempotencyKey: dto.idempotencyKey,
        results: dto.operations.map((op) => ({
          operationId: op.operationId,
          success: true,
          duplicate: true,
        })),
        serverTimestamp: existingBatch.createdAt,
        batchDuplicate: true,
      };
    }

    // Process operations in a transaction
    const results: SyncOperationResultDto[] = [];

    await this.prisma.$transaction(async (tx) => {
      // Record idempotency key first
      await tx.syncIdempotency.create({
        data: {
          userId: user.id,
          idempotencyKey: dto.idempotencyKey,
          requestHash,
        },
      });

      // Process each operation
      for (const operation of dto.operations) {
        const result = await this.processOperation(tx, operation, user);
        results.push(result);
      }
    });

    const serverTimestamp = new Date();
    const allSuccess = results.every((r) => r.success);

    this.logger.log(
      'Sync push completed: ' +
        dto.idempotencyKey +
        ' operations: ' +
        results.length +
        ' success: ' +
        allSuccess,
    );

    return {
      success: allSuccess,
      idempotencyKey: dto.idempotencyKey,
      results,
      serverTimestamp,
    };
  }

  /**
   * Pull changes since a given timestamp.
   *
   * MEMORY-SAFE IMPLEMENTATION:
   * - Each entity type is queried directly with ownership filter via JOINs
   * - No unbounded ID arrays are constructed
   * - No massive IN(...) clauses are generated
   * - Each query is limited to `limit` rows at the database level
   * - Maximum memory usage: ~4 × limit entities
   *
   * PAGINATION STRATEGY:
   * - Uses `updatedAt > since` as the cursor
   * - Client should use the latest `updatedAt` from response as next `since`
   * - `hasMore` indicates if more changes exist
   */
  async pull(
    dto: SyncPullDto,
    user: AuthenticatedUser,
  ): Promise<SyncPullResponseDto> {
    const limit = dto.limit ?? 100;
    const since = dto.since ? new Date(dto.since) : new Date(0);

    // Ownership filter for direct survey queries
    const surveyOwnerFilter =
      user.role === UserRole.ADMIN ? {} : { userId: user.id };

    // Ownership filter for related entities (via survey relation)
    const relatedOwnerFilter =
      user.role === UserRole.ADMIN ? {} : { survey: { userId: user.id } };

    // Run all queries in parallel - each is independently limited
    const [surveys, sections, answers, media] = await Promise.all([
      // 1. Fetch surveys directly with ownership filter
      this.prisma.survey.findMany({
        where: {
          ...surveyOwnerFilter,
          updatedAt: { gt: since },
        },
        orderBy: { updatedAt: 'asc' },
        take: limit,
      }),

      // 2. Fetch sections via survey JOIN (no IN clause needed)
      this.prisma.section.findMany({
        where: {
          ...relatedOwnerFilter,
          updatedAt: { gt: since },
        },
        orderBy: { updatedAt: 'asc' },
        take: limit,
      }),

      // 3. Fetch answers via section→survey JOIN (no IN clause needed)
      // Include parent section's surveyId + sectionTypeKey so the client
      // can route V2 answers to the correct local table.
      this.prisma.answer.findMany({
        where: {
          section: {
            ...relatedOwnerFilter,
          },
          updatedAt: { gt: since },
        },
        include: {
          section: {
            select: { surveyId: true, sectionTypeKey: true },
          },
        },
        orderBy: { updatedAt: 'asc' },
        take: limit,
      }),

      // 4. Fetch media via survey JOIN (no IN clause needed)
      this.prisma.media.findMany({
        where: {
          ...relatedOwnerFilter,
          updatedAt: { gt: since },
        },
        orderBy: { updatedAt: 'asc' },
        take: limit,
      }),
    ]);

    // Transform to sync entities - bounded by 4 × limit maximum
    const changes: SyncEntityDto[] = [];

    for (const survey of surveys) {
      changes.push({
        entityType: SyncEntityType.SURVEY,
        entityId: survey.id,
        changeType: survey.deletedAt
          ? SyncOperationType.DELETE
          : SyncOperationType.UPDATE,
        data: survey.deletedAt
          ? null
          : {
              id: survey.id,
              title: survey.title,
              propertyAddress: survey.propertyAddress,
              status: survey.status,
              type: survey.type,
              jobRef: survey.jobRef,
              clientName: survey.clientName,
              parentSurveyId: survey.parentSurveyId,
              userId: survey.userId,
              createdAt: survey.createdAt,
              updatedAt: survey.updatedAt,
            },
        updatedAt: survey.updatedAt,
      });
    }

    for (const section of sections) {
      changes.push({
        entityType: SyncEntityType.SECTION,
        entityId: section.id,
        changeType: SyncOperationType.UPDATE,
        data: {
          id: section.id,
          surveyId: section.surveyId,
          title: section.title,
          order: section.order,
          sectionTypeKey: section.sectionTypeKey,
          phraseOutput: section.phraseOutput,
          userNotes: section.userNotes,
          createdAt: section.createdAt,
          updatedAt: section.updatedAt,
        },
        updatedAt: section.updatedAt,
      });
    }

    for (const answer of answers) {
      changes.push({
        entityType: SyncEntityType.ANSWER,
        entityId: answer.id,
        changeType: SyncOperationType.UPDATE,
        data: {
          id: answer.id,
          sectionId: answer.sectionId,
          surveyId: answer.section.surveyId,
          sectionTypeKey: answer.section.sectionTypeKey,
          questionKey: answer.questionKey,
          value: answer.value,
          createdAt: answer.createdAt,
          updatedAt: answer.updatedAt,
        },
        updatedAt: answer.updatedAt,
      });
    }

    for (const m of media) {
      changes.push({
        entityType: SyncEntityType.MEDIA,
        entityId: m.id,
        changeType: m.deletedAt
          ? SyncOperationType.DELETE
          : SyncOperationType.UPDATE,
        data: m.deletedAt
          ? null
          : {
              id: m.id,
              surveyId: m.surveyId,
              type: m.type,
              fileName: m.fileName,
              mimeType: m.mimeType,
              size: m.size,
              url: this.urlBuilder.build('/media', m.id, 'file'),
              createdAt: m.createdAt,
              updatedAt: m.updatedAt,
            },
        updatedAt: m.updatedAt,
      });
    }

    // Sort all changes by updatedAt for consistent cursor-based pagination
    changes.sort((a, b) => a.updatedAt.getTime() - b.updatedAt.getTime());

    // Apply final limit and determine if more data exists
    const limitedChanges = changes.slice(0, limit);
    const hasMore = changes.length > limit;

    const serverTimestamp = new Date();

    return {
      changes: limitedChanges,
      serverTimestamp,
      hasMore,
      totalCount: limitedChanges.length,
    };
  }

  private async processOperation(
    tx: Parameters<Parameters<typeof this.prisma.$transaction>[0]>[0],
    operation: SyncOperationDto,
    user: AuthenticatedUser,
  ): Promise<SyncOperationResultDto> {
    try {
      switch (operation.entityType) {
        case SyncEntityType.SURVEY:
          return await this.processSurveyOperation(tx, operation, user);
        case SyncEntityType.SECTION:
          return await this.processSectionOperation(tx, operation, user);
        case SyncEntityType.ANSWER:
          return await this.processAnswerOperation(tx, operation, user);
        default:
          return {
            operationId: operation.operationId,
            success: false,
            error: 'Unsupported entity type: ' + operation.entityType,
          };
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(
        'Operation failed: ' + operation.operationId + ' error: ' + message,
      );
      return {
        operationId: operation.operationId,
        success: false,
        error: message,
      };
    }
  }

  private async processSurveyOperation(
    tx: Parameters<Parameters<typeof this.prisma.$transaction>[0]>[0],
    operation: SyncOperationDto,
    user: AuthenticatedUser,
  ): Promise<SyncOperationResultDto> {
    const { operationId, operationType, entityId, data } = operation;

    switch (operationType) {
      case SyncOperationType.CREATE: {
        if (!data) {
          return { operationId, success: false, error: 'Data required for CREATE' };
        }

        // Check if survey already exists (idempotent create)
        const existing = await tx.survey.findUnique({ where: { id: entityId } });
        if (existing) {
          return { operationId, success: true, entityId, duplicate: true };
        }

        await tx.survey.create({
          data: {
            id: entityId,
            title: String(data.title || 'Untitled Survey'),
            propertyAddress: String(data.propertyAddress || ''),
            status: (data.status as SurveyStatus) || SurveyStatus.DRAFT,
            type: (data.type as SurveyType) || undefined,
            jobRef: data.jobRef ? String(data.jobRef) : undefined,
            clientName: data.clientName ? String(data.clientName) : undefined,
            parentSurveyId: data.parentSurveyId ? String(data.parentSurveyId) : undefined,
            userId: user.id,
          },
        });
        return { operationId, success: true, entityId };
      }

      case SyncOperationType.UPDATE: {
        const survey = await tx.survey.findUnique({ where: { id: entityId } });
        if (!survey || survey.deletedAt !== null) {
          return { operationId, success: false, error: 'Survey not found' };
        }
        if (survey.userId !== user.id && user.role !== UserRole.ADMIN) {
          return { operationId, success: false, error: 'Access denied' };
        }

        // Validate status transition if status is being changed
        let validatedStatus: SurveyStatus | undefined;
        if (data?.status !== undefined) {
          const requestedStatus = data.status as SurveyStatus;
          const currentStatus = survey.status;

          // Validate the requested status is a valid SurveyStatus enum value
          if (!Object.values(SurveyStatus).includes(requestedStatus)) {
            return {
              operationId,
              success: false,
              error: `Invalid status: ${requestedStatus}`,
            };
          }

          // If status is the same, allow it (no transition)
          if (requestedStatus !== currentStatus) {
            // Check if transition is allowed by state machine
            if (!isValidSurveyTransition(currentStatus, requestedStatus)) {
              return {
                operationId,
                success: false,
                error: `Invalid status transition: ${currentStatus} → ${requestedStatus}`,
              };
            }

            // Check if this is a manager-only transition
            if (
              isManagerOnlyTransition(currentStatus, requestedStatus) &&
              user.role !== UserRole.ADMIN &&
              user.role !== UserRole.MANAGER
            ) {
              return {
                operationId,
                success: false,
                error: `Status transition ${currentStatus} → ${requestedStatus} requires manager permissions`,
              };
            }
          }

          validatedStatus = requestedStatus;
        }

        await tx.survey.update({
          where: { id: entityId },
          data: {
            title: data?.title !== undefined ? String(data.title) : undefined,
            propertyAddress:
              data?.propertyAddress !== undefined
                ? String(data.propertyAddress)
                : undefined,
            status: validatedStatus,
            type: data?.type !== undefined ? (data.type as SurveyType) : undefined,
            jobRef: data?.jobRef !== undefined ? String(data.jobRef) : undefined,
            clientName: data?.clientName !== undefined ? String(data.clientName) : undefined,
          },
        });
        return { operationId, success: true, entityId };
      }

      case SyncOperationType.DELETE: {
        const survey = await tx.survey.findUnique({ where: { id: entityId } });
        if (!survey) {
          return { operationId, success: true, entityId, duplicate: true };
        }
        if (survey.userId !== user.id && user.role !== UserRole.ADMIN) {
          return { operationId, success: false, error: 'Access denied' };
        }

        await tx.survey.update({
          where: { id: entityId },
          data: { deletedAt: new Date() },
        });
        return { operationId, success: true, entityId };
      }

      default:
        return { operationId, success: false, error: 'Unknown operation type' };
    }
  }

  private async processSectionOperation(
    tx: Parameters<Parameters<typeof this.prisma.$transaction>[0]>[0],
    operation: SyncOperationDto,
    user: AuthenticatedUser,
  ): Promise<SyncOperationResultDto> {
    const { operationId, operationType, entityId, data } = operation;

    switch (operationType) {
      case SyncOperationType.CREATE: {
        if (!data || !data.surveyId) {
          return { operationId, success: false, error: 'surveyId required' };
        }

        // Verify survey access
        const survey = await tx.survey.findUnique({
          where: { id: String(data.surveyId) },
        });
        if (!survey || survey.deletedAt !== null) {
          return { operationId, success: false, error: 'Survey not found' };
        }
        if (survey.userId !== user.id && user.role !== UserRole.ADMIN) {
          return { operationId, success: false, error: 'Access denied' };
        }

        // Check for existing section
        const existing = await tx.section.findUnique({ where: { id: entityId } });
        if (existing) {
          return { operationId, success: true, entityId, duplicate: true };
        }

        await tx.section.create({
          data: {
            id: entityId,
            surveyId: String(data.surveyId),
            title: String(data.title || 'Untitled Section'),
            order: typeof data.order === 'number' ? data.order : 0,
          },
        });
        return { operationId, success: true, entityId };
      }

      case SyncOperationType.UPDATE: {
        const section = await tx.section.findUnique({
          where: { id: entityId },
          include: { survey: { select: { userId: true, deletedAt: true } } },
        });
        if (!section) {
          return { operationId, success: false, error: 'Section not found' };
        }
        if (section.survey.deletedAt !== null) {
          return { operationId, success: false, error: 'Survey deleted' };
        }
        if (section.survey.userId !== user.id && user.role !== UserRole.ADMIN) {
          return { operationId, success: false, error: 'Access denied' };
        }

        await tx.section.update({
          where: { id: entityId },
          data: {
            title: data?.title !== undefined ? String(data.title) : undefined,
            order: typeof data?.order === 'number' ? data.order : undefined,
          },
        });
        return { operationId, success: true, entityId };
      }

      case SyncOperationType.DELETE: {
        const section = await tx.section.findUnique({
          where: { id: entityId },
          include: { survey: { select: { userId: true, deletedAt: true } } },
        });
        if (!section) {
          return { operationId, success: true, entityId, duplicate: true };
        }
        if (section.survey.userId !== user.id && user.role !== UserRole.ADMIN) {
          return { operationId, success: false, error: 'Access denied' };
        }

        await tx.section.delete({ where: { id: entityId } });
        return { operationId, success: true, entityId };
      }

      default:
        return { operationId, success: false, error: 'Unknown operation type' };
    }
  }

  private async processAnswerOperation(
    tx: Parameters<Parameters<typeof this.prisma.$transaction>[0]>[0],
    operation: SyncOperationDto,
    user: AuthenticatedUser,
  ): Promise<SyncOperationResultDto> {
    const { operationId, operationType, entityId, data } = operation;

    switch (operationType) {
      case SyncOperationType.CREATE: {
        if (!data || !data.sectionId) {
          return { operationId, success: false, error: 'sectionId required' };
        }

        // Verify section access
        const section = await tx.section.findUnique({
          where: { id: String(data.sectionId) },
          include: { survey: { select: { userId: true, deletedAt: true } } },
        });
        if (!section) {
          return { operationId, success: false, error: 'Section not found' };
        }
        if (section.survey.deletedAt !== null) {
          return { operationId, success: false, error: 'Survey deleted' };
        }
        if (section.survey.userId !== user.id && user.role !== UserRole.ADMIN) {
          return { operationId, success: false, error: 'Access denied' };
        }

        // Check for existing answer
        const existing = await tx.answer.findUnique({ where: { id: entityId } });
        if (existing) {
          return { operationId, success: true, entityId, duplicate: true };
        }

        await tx.answer.create({
          data: {
            id: entityId,
            sectionId: String(data.sectionId),
            questionKey: String(data.questionKey || ''),
            value: String(data.value || ''),
          },
        });
        return { operationId, success: true, entityId };
      }

      case SyncOperationType.UPDATE: {
        const answer = await tx.answer.findUnique({
          where: { id: entityId },
          include: {
            section: {
              include: { survey: { select: { userId: true, deletedAt: true } } },
            },
          },
        });
        if (!answer) {
          return { operationId, success: false, error: 'Answer not found' };
        }
        if (answer.section.survey.deletedAt !== null) {
          return { operationId, success: false, error: 'Survey deleted' };
        }
        if (
          answer.section.survey.userId !== user.id &&
          user.role !== UserRole.ADMIN
        ) {
          return { operationId, success: false, error: 'Access denied' };
        }

        await tx.answer.update({
          where: { id: entityId },
          data: {
            questionKey:
              data?.questionKey !== undefined ? String(data.questionKey) : undefined,
            value: data?.value !== undefined ? String(data.value) : undefined,
          },
        });
        return { operationId, success: true, entityId };
      }

      case SyncOperationType.DELETE: {
        const answer = await tx.answer.findUnique({
          where: { id: entityId },
          include: {
            section: {
              include: { survey: { select: { userId: true, deletedAt: true } } },
            },
          },
        });
        if (!answer) {
          return { operationId, success: true, entityId, duplicate: true };
        }
        if (
          answer.section.survey.userId !== user.id &&
          user.role !== UserRole.ADMIN
        ) {
          return { operationId, success: false, error: 'Access denied' };
        }

        await tx.answer.delete({ where: { id: entityId } });
        return { operationId, success: true, entityId };
      }

      default:
        return { operationId, success: false, error: 'Unknown operation type' };
    }
  }

  // NOTE: getUserSurveyIds() was REMOVED - it loaded unbounded arrays causing OOM.
  // The pull() method now uses direct queries with ownership JOINs instead.

  private hashRequest(dto: SyncPushDto): string {
    const content = JSON.stringify({
      idempotencyKey: dto.idempotencyKey,
      operations: dto.operations.map((op) => ({
        operationId: op.operationId,
        operationType: op.operationType,
        entityType: op.entityType,
        entityId: op.entityId,
      })),
    });
    return createHash('sha256').update(content).digest('hex');
  }
}
