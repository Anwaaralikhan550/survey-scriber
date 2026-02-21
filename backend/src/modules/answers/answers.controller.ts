import {
  Controller,
  Post,
  Put,
  Delete,
  Body,
  Param,
  HttpCode,
  HttpStatus,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
} from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { AnswersService } from './answers.service';
import { CreateAnswerDto } from './dto/create-answer.dto';
import { UpdateAnswerDto } from './dto/update-answer.dto';
import { AnswerResponseDto, DeleteAnswerResponseDto } from './dto/answer-response.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';

interface AuthenticatedUser {
  id: string;
  email: string;
  role: UserRole;
}

@ApiTags('Answers')
@ApiBearerAuth('JWT-auth')
@Controller()
@UseGuards(JwtAuthGuard, RolesGuard)
export class AnswersController {
  constructor(private readonly answersService: AnswersService) {}

  @Post('sections/:sectionId/answers')
  @Roles(UserRole.ADMIN, UserRole.SURVEYOR)
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a new answer in a section' })
  @ApiParam({
    name: 'sectionId',
    description: 'Section UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 201,
    description: 'Answer created successfully',
    type: AnswerResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Validation error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - not owner or admin' })
  @ApiResponse({ status: 404, description: 'Section not found' })
  async create(
    @Param('sectionId', ParseUUIDPipe) sectionId: string,
    @Body() dto: CreateAnswerDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<AnswerResponseDto> {
    return this.answersService.create(sectionId, dto, user);
  }

  @Put('answers/:id')
  @Roles(UserRole.ADMIN, UserRole.SURVEYOR)
  @ApiOperation({ summary: 'Update an answer' })
  @ApiParam({
    name: 'id',
    description: 'Answer UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Answer updated successfully',
    type: AnswerResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Validation error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - not owner or admin' })
  @ApiResponse({ status: 404, description: 'Answer not found' })
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateAnswerDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<AnswerResponseDto> {
    return this.answersService.update(id, dto, user);
  }

  @Delete('answers/:id')
  @Roles(UserRole.ADMIN, UserRole.SURVEYOR)
  @ApiOperation({ summary: 'Delete an answer' })
  @ApiParam({
    name: 'id',
    description: 'Answer UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Answer deleted successfully',
    type: DeleteAnswerResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - not owner or admin' })
  @ApiResponse({ status: 404, description: 'Answer not found' })
  async delete(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<DeleteAnswerResponseDto> {
    return this.answersService.delete(id, user);
  }
}
