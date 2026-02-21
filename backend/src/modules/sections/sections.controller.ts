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
import { SectionsService } from './sections.service';
import { CreateSectionDto } from './dto/create-section.dto';
import { UpdateSectionDto } from './dto/update-section.dto';
import { SectionResponseDto, DeleteSectionResponseDto } from './dto/section-response.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';

interface AuthenticatedUser {
  id: string;
  email: string;
  role: UserRole;
}

@ApiTags('Sections')
@ApiBearerAuth('JWT-auth')
@Controller()
@UseGuards(JwtAuthGuard, RolesGuard)
export class SectionsController {
  constructor(private readonly sectionsService: SectionsService) {}

  @Post('surveys/:surveyId/sections')
  @Roles(UserRole.ADMIN, UserRole.SURVEYOR)
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a new section in a survey' })
  @ApiParam({
    name: 'surveyId',
    description: 'Survey UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 201,
    description: 'Section created successfully',
    type: SectionResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Validation error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - not owner or admin' })
  @ApiResponse({ status: 404, description: 'Survey not found' })
  async create(
    @Param('surveyId', ParseUUIDPipe) surveyId: string,
    @Body() dto: CreateSectionDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<SectionResponseDto> {
    return this.sectionsService.create(surveyId, dto, user);
  }

  @Put('sections/:id')
  @Roles(UserRole.ADMIN, UserRole.SURVEYOR)
  @ApiOperation({ summary: 'Update a section' })
  @ApiParam({
    name: 'id',
    description: 'Section UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Section updated successfully',
    type: SectionResponseDto,
  })
  @ApiResponse({ status: 400, description: 'Validation error' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - not owner or admin' })
  @ApiResponse({ status: 404, description: 'Section not found' })
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateSectionDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<SectionResponseDto> {
    return this.sectionsService.update(id, dto, user);
  }

  @Delete('sections/:id')
  @Roles(UserRole.ADMIN, UserRole.SURVEYOR)
  @ApiOperation({ summary: 'Delete a section' })
  @ApiParam({
    name: 'id',
    description: 'Section UUID',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @ApiResponse({
    status: 200,
    description: 'Section deleted successfully',
    type: DeleteSectionResponseDto,
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - not owner or admin' })
  @ApiResponse({ status: 404, description: 'Section not found' })
  async delete(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<DeleteSectionResponseDto> {
    return this.sectionsService.delete(id, user);
  }
}
