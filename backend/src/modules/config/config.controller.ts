import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
  ParseUUIDPipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiQuery,
} from '@nestjs/swagger';
import { UserRole, User } from '@prisma/client';
import { ConfigService } from './config.service';
import {
  CreatePhraseCategoryDto,
  UpdatePhraseCategoryDto,
  PhraseCategoryResponseDto,
  PhraseCategoryWithPhrasesDto,
  CreatePhraseDto,
  UpdatePhraseDto,
  ReorderPhrasesDto,
  PhraseResponseDto,
  CreateFieldDefinitionDto,
  UpdateFieldDefinitionDto,
  ReorderFieldsDto,
  FieldDefinitionResponseDto,
  FieldDefinitionWithOptionsDto,
  CreateSectionTypeDto,
  UpdateSectionTypeDto,
  ReorderSectionTypesDto,
  SectionTypeResponseDto,
  ConfigVersionResponseDto,
  FullConfigResponseDto,
  UpdateUserRoleDto,
  UserAdminResponseDto,
  UsersQueryDto,
  UsersListResponseDto,
  UploadV2TreeDto,
  V2TreeUploadResponseDto,
  V2TreeLatestResponseDto,
} from './dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { Public } from '../auth/decorators/public.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

// ============================================
// Public Config Endpoints (Read-Only)
// ============================================

@ApiTags('Config (Public)')
@Controller('config')
export class ConfigPublicController {
  constructor(private readonly configService: ConfigService) {}

  @Public()
  @Get('version')
  @ApiOperation({ summary: 'Get current config version' })
  @ApiResponse({ status: 200, type: ConfigVersionResponseDto })
  async getVersion(): Promise<ConfigVersionResponseDto> {
    return this.configService.getConfigVersion();
  }

  @Public()
  @Get('all')
  @ApiOperation({ summary: 'Get full configuration (categories, phrases, fields)' })
  @ApiResponse({ status: 200, type: FullConfigResponseDto })
  async getFullConfig(): Promise<FullConfigResponseDto> {
    return this.configService.getFullConfig();
  }

  @Public()
  @Get('phrases/:categorySlug')
  @ApiOperation({ summary: 'Get phrases by category slug' })
  @ApiResponse({ status: 200, type: PhraseCategoryWithPhrasesDto })
  async getPhrasesByCategory(
    @Param('categorySlug') categorySlug: string,
  ): Promise<PhraseCategoryWithPhrasesDto> {
    return this.configService.findCategoryBySlug(categorySlug);
  }

  @Public()
  @Get('fields/:sectionType')
  @ApiOperation({ summary: 'Get field definitions by section type' })
  @ApiResponse({ status: 200, type: [FieldDefinitionWithOptionsDto] })
  async getFieldsBySection(
    @Param('sectionType') sectionType: string,
  ): Promise<FieldDefinitionWithOptionsDto[]> {
    return this.configService.findFieldsBySection(sectionType);
  }
}

// ============================================
// Admin Config Endpoints (ADMIN Only)
// ============================================

@ApiTags('Config (Admin)')
@Controller('admin/config')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
@ApiBearerAuth('JWT-auth')
export class ConfigAdminController {
  constructor(private readonly configService: ConfigService) {}

  // ----------------------------------------
  // Phrase Categories
  // ----------------------------------------

  @Get('categories')
  @ApiOperation({ summary: 'List all phrase categories' })
  @ApiQuery({ name: 'includeInactive', required: false, type: Boolean })
  @ApiResponse({ status: 200, type: [PhraseCategoryResponseDto] })
  async listCategories(
    @Query('includeInactive') includeInactive?: string,
  ): Promise<PhraseCategoryResponseDto[]> {
    return this.configService.findAllCategories(includeInactive === 'true');
  }

  @Get('categories/:slug')
  @ApiOperation({ summary: 'Get a phrase category with its phrases' })
  @ApiResponse({ status: 200, type: PhraseCategoryWithPhrasesDto })
  async getCategory(
    @Param('slug') slug: string,
  ): Promise<PhraseCategoryWithPhrasesDto> {
    return this.configService.findCategoryBySlug(slug);
  }

  @Post('categories')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a new phrase category' })
  @ApiResponse({ status: 201, type: PhraseCategoryResponseDto })
  async createCategory(
    @Body() dto: CreatePhraseCategoryDto,
    @CurrentUser() user: Omit<User, 'passwordHash'>,
  ): Promise<PhraseCategoryResponseDto> {
    return this.configService.createCategory(dto, user.id);
  }

  @Put('categories/:id')
  @ApiOperation({ summary: 'Update a phrase category' })
  @ApiResponse({ status: 200, type: PhraseCategoryResponseDto })
  async updateCategory(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdatePhraseCategoryDto,
    @CurrentUser() user: Omit<User, 'passwordHash'>,
  ): Promise<PhraseCategoryResponseDto> {
    return this.configService.updateCategory(id, dto, user.id);
  }

  @Delete('categories/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a phrase category (soft delete via deletedAt)' })
  @ApiResponse({ status: 204 })
  async deleteCategory(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: Omit<User, 'passwordHash'>,
  ): Promise<void> {
    await this.configService.deleteCategory(id, user.id);
  }

  @Post('categories/:id/restore')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Restore a soft-deleted phrase category' })
  @ApiResponse({ status: 204 })
  async restoreCategory(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: Omit<User, 'passwordHash'>,
  ): Promise<void> {
    await this.configService.restoreCategory(id, user.id);
  }

  // ----------------------------------------
  // Phrases
  // ----------------------------------------

  @Get('phrases')
  @ApiOperation({ summary: 'List phrases by category' })
  @ApiQuery({ name: 'categoryId', required: true })
  @ApiQuery({ name: 'includeInactive', required: false, type: Boolean })
  @ApiResponse({ status: 200, type: [PhraseResponseDto] })
  async listPhrases(
    @Query('categoryId') categoryId: string,
    @Query('includeInactive') includeInactive?: string,
  ): Promise<PhraseResponseDto[]> {
    return this.configService.findPhrasesByCategory(categoryId, includeInactive === 'true');
  }

  @Post('phrases')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a new phrase' })
  @ApiResponse({ status: 201, type: PhraseResponseDto })
  async createPhrase(
    @Body() dto: CreatePhraseDto,
    @CurrentUser() user: Omit<User, 'passwordHash'>,
  ): Promise<PhraseResponseDto> {
    return this.configService.createPhrase(dto, user.id);
  }

  @Put('phrases/:id')
  @ApiOperation({ summary: 'Update a phrase' })
  @ApiResponse({ status: 200, type: PhraseResponseDto })
  async updatePhrase(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdatePhraseDto,
    @CurrentUser() user: Omit<User, 'passwordHash'>,
  ): Promise<PhraseResponseDto> {
    return this.configService.updatePhrase(id, dto, user.id);
  }

  @Delete('phrases/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a phrase (soft delete)' })
  @ApiResponse({ status: 204 })
  async deletePhrase(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: Omit<User, 'passwordHash'>,
  ): Promise<void> {
    await this.configService.deletePhrase(id, user.id);
  }

  @Post('phrases/reorder')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Reorder phrases within a category' })
  @ApiResponse({ status: 200 })
  async reorderPhrases(
    @Body() dto: ReorderPhrasesDto,
    @CurrentUser() user: Omit<User, 'passwordHash'>,
  ): Promise<{ success: boolean }> {
    await this.configService.reorderPhrases(dto, user.id);
    return { success: true };
  }

  // ----------------------------------------
  // Field Definitions
  // ----------------------------------------

  @Get('fields')
  @ApiOperation({ summary: 'List all field definitions' })
  @ApiQuery({ name: 'includeInactive', required: false, type: Boolean })
  @ApiResponse({ status: 200, type: [FieldDefinitionResponseDto] })
  async listFields(
    @Query('includeInactive') includeInactive?: string,
  ): Promise<FieldDefinitionResponseDto[]> {
    return this.configService.findAllFields(includeInactive === 'true');
  }

  @Get('fields/:sectionType')
  @ApiOperation({ summary: 'Get field definitions by section type' })
  @ApiResponse({ status: 200, type: [FieldDefinitionWithOptionsDto] })
  async getFieldsBySection(
    @Param('sectionType') sectionType: string,
  ): Promise<FieldDefinitionWithOptionsDto[]> {
    return this.configService.findFieldsBySection(sectionType);
  }

  @Post('fields')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a new field definition' })
  @ApiResponse({ status: 201, type: FieldDefinitionResponseDto })
  async createField(
    @Body() dto: CreateFieldDefinitionDto,
    @CurrentUser() user: Omit<User, 'passwordHash'>,
  ): Promise<FieldDefinitionResponseDto> {
    return this.configService.createFieldDefinition(dto, user.id);
  }

  @Put('fields/:id')
  @ApiOperation({ summary: 'Update a field definition' })
  @ApiResponse({ status: 200, type: FieldDefinitionResponseDto })
  async updateField(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateFieldDefinitionDto,
    @CurrentUser() user: Omit<User, 'passwordHash'>,
  ): Promise<FieldDefinitionResponseDto> {
    return this.configService.updateFieldDefinition(id, dto, user.id);
  }

  @Delete('fields/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a field definition (soft delete)' })
  @ApiResponse({ status: 204 })
  async deleteField(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: Omit<User, 'passwordHash'>,
  ): Promise<void> {
    await this.configService.deleteFieldDefinition(id, user.id);
  }

  @Post('fields/reorder')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Reorder fields within a section' })
  @ApiResponse({ status: 200 })
  async reorderFields(
    @Body() dto: ReorderFieldsDto,
    @CurrentUser() user: Omit<User, 'passwordHash'>,
  ): Promise<{ success: boolean }> {
    await this.configService.reorderFields(dto, user.id);
    return { success: true };
  }

  // ----------------------------------------
  // Section Type Definitions
  // ----------------------------------------

  @Get('section-types')
  @ApiOperation({ summary: 'List all section type definitions' })
  @ApiQuery({ name: 'includeInactive', required: false, type: Boolean })
  @ApiResponse({ status: 200, type: [SectionTypeResponseDto] })
  async listSectionTypes(
    @Query('includeInactive') includeInactive?: string,
  ): Promise<SectionTypeResponseDto[]> {
    return this.configService.findAllSectionTypes(includeInactive === 'true');
  }

  @Post('section-types')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Create a new section type definition' })
  @ApiResponse({ status: 201, type: SectionTypeResponseDto })
  async createSectionType(
    @Body() dto: CreateSectionTypeDto,
    @CurrentUser() user: Omit<User, 'passwordHash'>,
  ): Promise<SectionTypeResponseDto> {
    return this.configService.createSectionType(dto, user.id);
  }

  @Put('section-types/:id')
  @ApiOperation({ summary: 'Update a section type definition' })
  @ApiResponse({ status: 200, type: SectionTypeResponseDto })
  async updateSectionType(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateSectionTypeDto,
    @CurrentUser() user: Omit<User, 'passwordHash'>,
  ): Promise<SectionTypeResponseDto> {
    return this.configService.updateSectionType(id, dto, user.id);
  }

  @Delete('section-types/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a section type definition (soft delete via deletedAt)' })
  @ApiResponse({ status: 204 })
  async deleteSectionType(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: Omit<User, 'passwordHash'>,
  ): Promise<void> {
    await this.configService.deleteSectionType(id, user.id);
  }

  @Post('section-types/:id/restore')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Restore a soft-deleted section type' })
  @ApiResponse({ status: 204 })
  async restoreSectionType(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: Omit<User, 'passwordHash'>,
  ): Promise<void> {
    await this.configService.restoreSectionType(id, user.id);
  }

  @Post('section-types/reorder')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Reorder section type definitions' })
  @ApiResponse({ status: 200 })
  async reorderSectionTypes(
    @Body() dto: ReorderSectionTypesDto,
    @CurrentUser() user: Omit<User, 'passwordHash'>,
  ): Promise<{ success: boolean }> {
    await this.configService.reorderSectionTypes(dto, user.id);
    return { success: true };
  }

  // ----------------------------------------
  // User Management (ADMIN Only)
  // ----------------------------------------

  @Get('users')
  @ApiOperation({ summary: 'List all users with role information (paginated)' })
  @ApiResponse({ status: 200, type: UsersListResponseDto })
  async listUsers(@Query() query: UsersQueryDto): Promise<UsersListResponseDto> {
    return this.configService.findUsersPaginated(query);
  }

  @Put('users/:id/role')
  @ApiOperation({ summary: 'Update user role (promote/demote)' })
  @ApiResponse({ status: 200, type: UserAdminResponseDto })
  @ApiResponse({ status: 403, description: 'Cannot demote the last ADMIN' })
  @ApiResponse({ status: 404, description: 'User not found' })
  async updateUserRole(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateUserRoleDto,
    @CurrentUser() user: Omit<User, 'passwordHash'>,
  ): Promise<UserAdminResponseDto> {
    return this.configService.updateUserRole(id, dto.role, user.id);
  }

  // ----------------------------------------
  // V2 Tree Publishing
  // ----------------------------------------

  @Post('v2-tree/upload')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Publish a V2 tree (inspection or valuation)',
    description:
      'Accepts a full V2 tree JSON from the mobile admin panel, validates its structure, ' +
      'stores an immutable versioned snapshot, and logs the audit event.',
  })
  @ApiResponse({ status: 201, type: V2TreeUploadResponseDto })
  @ApiResponse({ status: 400, description: 'Invalid tree structure' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden — admin only' })
  async uploadV2Tree(
    @Body() dto: UploadV2TreeDto,
    @CurrentUser() user: Omit<User, 'passwordHash'>,
  ): Promise<V2TreeUploadResponseDto> {
    return this.configService.uploadV2Tree(dto, user.id);
  }

  @Get('v2-tree/latest/:treeType')
  @ApiOperation({
    summary: 'Get the latest published V2 tree',
    description: 'Returns the most recently published tree for the given type.',
  })
  @ApiResponse({ status: 200, type: V2TreeLatestResponseDto })
  @ApiResponse({ status: 404, description: 'No published tree found' })
  async getLatestV2Tree(
    @Param('treeType') treeType: string,
  ): Promise<V2TreeLatestResponseDto> {
    return this.configService.getLatestV2Tree(treeType);
  }
}
