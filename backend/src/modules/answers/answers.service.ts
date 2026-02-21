import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  ConflictException,
  Logger,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateAnswerDto } from './dto/create-answer.dto';
import { UpdateAnswerDto } from './dto/update-answer.dto';
import { AnswerResponseDto, DeleteAnswerResponseDto } from './dto/answer-response.dto';

interface AuthenticatedUser {
  id: string;
  role: UserRole;
}

@Injectable()
export class AnswersService {
  private readonly logger = new Logger(AnswersService.name);

  constructor(private readonly prisma: PrismaService) {}

  async create(
    sectionId: string,
    dto: CreateAnswerDto,
    user: AuthenticatedUser,
  ): Promise<AnswerResponseDto> {
    // Verify section exists and user owns the parent survey
    const section = await this.prisma.section.findUnique({
      where: { id: sectionId },
      include: { survey: { select: { userId: true, deletedAt: true } } },
    });

    if (!section) {
      throw new NotFoundException('Section not found');
    }

    if (section.survey.deletedAt !== null) {
      throw new NotFoundException('Survey not found');
    }

    if (section.survey.userId !== user.id && user.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Access denied to this section');
    }

    let answer;
    try {
      answer = await this.prisma.answer.create({
        data: {
          ...(dto.id ? { id: dto.id } : {}),
          sectionId,
          questionKey: dto.questionKey,
          value: dto.value,
        },
      });
    } catch (error: any) {
      // Handle duplicate (sectionId, questionKey) conflict (Prisma P2002).
      // This occurs during offline-first sync when forceResyncSurvey re-queues
      // answers that already exist on the server.  Upsert to stay idempotent.
      if (error?.code === 'P2002') {
        const existing = await this.prisma.answer.findFirst({
          where: { sectionId, questionKey: dto.questionKey },
        });
        if (existing) {
          answer = await this.prisma.answer.update({
            where: { id: existing.id },
            data: { value: dto.value },
          });
          this.logger.log(
            'Answer upserted (P2002): ' + answer.id + ' in section: ' + sectionId,
          );
          return this.mapToResponse(answer);
        }
        throw new ConflictException(
          'Answer with this questionKey already exists in the section',
        );
      }
      throw error;
    }

    this.logger.log('Answer created: ' + answer.id + ' in section: ' + sectionId);

    return this.mapToResponse(answer);
  }

  async update(
    id: string,
    dto: UpdateAnswerDto,
    user: AuthenticatedUser,
  ): Promise<AnswerResponseDto> {
    const existingAnswer = await this.prisma.answer.findUnique({
      where: { id },
      include: {
        section: {
          include: { survey: { select: { userId: true, deletedAt: true } } },
        },
      },
    });

    if (!existingAnswer) {
      throw new NotFoundException('Answer not found');
    }

    if (existingAnswer.section.survey.deletedAt !== null) {
      throw new NotFoundException('Survey not found');
    }

    if (existingAnswer.section.survey.userId !== user.id && user.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Access denied to this answer');
    }

    const answer = await this.prisma.answer.update({
      where: { id },
      data: {
        questionKey: dto.questionKey,
        value: dto.value,
      },
    });

    this.logger.log('Answer updated: ' + answer.id);

    return this.mapToResponse(answer);
  }

  async delete(
    id: string,
    user: AuthenticatedUser,
  ): Promise<DeleteAnswerResponseDto> {
    const existingAnswer = await this.prisma.answer.findUnique({
      where: { id },
      include: {
        section: {
          include: { survey: { select: { userId: true, deletedAt: true } } },
        },
      },
    });

    if (!existingAnswer) {
      throw new NotFoundException('Answer not found');
    }

    if (existingAnswer.section.survey.deletedAt !== null) {
      throw new NotFoundException('Survey not found');
    }

    if (existingAnswer.section.survey.userId !== user.id && user.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Access denied to this answer');
    }

    await this.prisma.answer.delete({
      where: { id },
    });

    this.logger.log('Answer deleted: ' + id);

    return {
      success: true,
      id,
    };
  }

  private mapToResponse(answer: {
    id: string;
    sectionId: string;
    questionKey: string;
    value: string;
    createdAt: Date;
    updatedAt: Date;
  }): AnswerResponseDto {
    return {
      id: answer.id,
      sectionId: answer.sectionId,
      questionKey: answer.questionKey,
      value: answer.value,
      createdAt: answer.createdAt,
      updatedAt: answer.updatedAt,
    };
  }
}
