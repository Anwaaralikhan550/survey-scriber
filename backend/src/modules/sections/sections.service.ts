import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  ConflictException,
  Logger,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { SurveysService } from '../surveys/surveys.service';
import { CreateSectionDto } from './dto/create-section.dto';
import { UpdateSectionDto } from './dto/update-section.dto';
import { SectionResponseDto, DeleteSectionResponseDto } from './dto/section-response.dto';

interface AuthenticatedUser {
  id: string;
  role: UserRole;
}

@Injectable()
export class SectionsService {
  private readonly logger = new Logger(SectionsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly surveysService: SurveysService,
  ) {}

  async create(
    surveyId: string,
    dto: CreateSectionDto,
    user: AuthenticatedUser,
  ): Promise<SectionResponseDto> {
    // Verify user owns the survey
    await this.surveysService.verifySurveyOwnership(surveyId, user);

    let section;
    try {
      section = await this.prisma.section.create({
        data: {
          ...(dto.id ? { id: dto.id } : {}),
          surveyId,
          title: dto.title,
          order: dto.order ?? 0,
          ...(dto.sectionTypeKey ? { sectionTypeKey: dto.sectionTypeKey } : {}),
          ...(dto.phraseOutput !== undefined ? { phraseOutput: dto.phraseOutput } : {}),
        },
      });
    } catch (error: any) {
      // Handle duplicate (surveyId, order) conflict (Prisma P2002).
      // This occurs during offline-first sync when forceResyncSurvey re-queues
      // sections that already exist on the server.  Upsert to stay idempotent.
      if (error?.code === 'P2002') {
        const existing = await this.prisma.section.findFirst({
          where: { surveyId, order: dto.order ?? 0 },
        });
        if (existing) {
          section = await this.prisma.section.update({
            where: { id: existing.id },
            data: { title: dto.title },
          });
          this.logger.log(
            'Section upserted (P2002): ' + section.id + ' in survey: ' + surveyId,
          );
          return this.mapToResponse(section);
        }
        throw new ConflictException(
          'Section with this order already exists in the survey',
        );
      }
      throw error;
    }

    this.logger.log('Section created: ' + section.id + ' in survey: ' + surveyId);

    return this.mapToResponse(section);
  }

  async update(
    id: string,
    dto: UpdateSectionDto,
    user: AuthenticatedUser,
  ): Promise<SectionResponseDto> {
    const existingSection = await this.prisma.section.findUnique({
      where: { id },
      include: { survey: { select: { userId: true, deletedAt: true } } },
    });

    if (!existingSection) {
      throw new NotFoundException('Section not found');
    }

    if (existingSection.survey.deletedAt !== null) {
      throw new NotFoundException('Survey not found');
    }

    if (existingSection.survey.userId !== user.id && user.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Access denied to this section');
    }

    const section = await this.prisma.section.update({
      where: { id },
      data: {
        title: dto.title,
        order: dto.order,
        ...(dto.phraseOutput !== undefined ? { phraseOutput: dto.phraseOutput } : {}),
      },
    });

    this.logger.log('Section updated: ' + section.id);

    return this.mapToResponse(section);
  }

  async delete(
    id: string,
    user: AuthenticatedUser,
  ): Promise<DeleteSectionResponseDto> {
    const existingSection = await this.prisma.section.findUnique({
      where: { id },
      include: { survey: { select: { userId: true, deletedAt: true } } },
    });

    if (!existingSection) {
      throw new NotFoundException('Section not found');
    }

    if (existingSection.survey.deletedAt !== null) {
      throw new NotFoundException('Survey not found');
    }

    if (existingSection.survey.userId !== user.id && user.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Access denied to this section');
    }

    await this.prisma.section.delete({
      where: { id },
    });

    this.logger.log('Section deleted: ' + id);

    return {
      success: true,
      id,
    };
  }

  private mapToResponse(section: {
    id: string;
    surveyId: string;
    title: string;
    order: number;
    phraseOutput?: string | null;
    createdAt: Date;
    updatedAt: Date;
  }): SectionResponseDto {
    return {
      id: section.id,
      surveyId: section.surveyId,
      title: section.title,
      order: section.order,
      phraseOutput: section.phraseOutput ?? null,
      createdAt: section.createdAt,
      updatedAt: section.updatedAt,
    };
  }
}
