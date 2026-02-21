import * as crypto from 'crypto';
import {
  Injectable,
  NotFoundException,
  ConflictException,
  ForbiddenException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Prisma, UserRole, ActorType, AuditEntityType } from '@prisma/client';
import { AuditService, AuditActions } from '../audit/audit.service';
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
  CategoryWithPhrasesDto,
  FieldConfigDto,
  UserAdminResponseDto,
  UsersQueryDto,
  UsersListResponseDto,
  UploadV2TreeDto,
  V2TreeUploadResponseDto,
  V2TreeLatestResponseDto,
} from './dto';

@Injectable()
export class ConfigService {
  private readonly logger = new Logger(ConfigService.name);

  /**
   * In-memory cache for full config (Redis-ready pattern)
   * TTL: 5 minutes as safety backup; primarily invalidated on config updates
   */
  private configCache: {
    data: FullConfigResponseDto | null;
    timestamp: number;
  } = { data: null, timestamp: 0 };
  private readonly CONFIG_CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AuditService,
  ) {}

  /**
   * Invalidate the full config cache.
   * Called whenever config data is modified.
   */
  private invalidateConfigCache(): void {
    this.configCache = { data: null, timestamp: 0 };
    this.logger.debug('Config cache invalidated');
  }

  /**
   * Check if cached config is still valid
   */
  private isCacheValid(): boolean {
    if (!this.configCache.data) return false;
    const age = Date.now() - this.configCache.timestamp;
    return age < this.CONFIG_CACHE_TTL_MS;
  }

  // ============================================
  // Config Version
  // ============================================

  async getConfigVersion(): Promise<ConfigVersionResponseDto> {
    const config = await this.prisma.configVersion.findFirst();
    if (!config) {
      return { version: 1, updatedAt: new Date() };
    }
    return {
      version: config.version,
      updatedAt: config.updatedAt,
    };
  }

  private async incrementConfigVersion(updatedBy?: string): Promise<void> {
    await this.prisma.configVersion.updateMany({
      data: {
        version: { increment: 1 },
        updatedBy,
      },
    });
    // Invalidate cache when config version changes
    this.invalidateConfigCache();
  }

  // ============================================
  // Phrase Categories
  // ============================================

  async findAllCategories(includeInactive = false): Promise<PhraseCategoryResponseDto[]> {
    const categories = await this.prisma.phraseCategory.findMany({
      where: { ...(includeInactive ? {} : { isActive: true }), deletedAt: null },
      orderBy: { displayOrder: 'asc' },
      include: {
        _count: { select: { phrases: true } },
      },
    });

    return categories.map((c) => ({
      id: c.id,
      slug: c.slug,
      displayName: c.displayName,
      description: c.description ?? undefined,
      isSystem: c.isSystem,
      isActive: c.isActive,
      displayOrder: c.displayOrder,
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
      phraseCount: c._count.phrases,
    }));
  }

  async findCategoryBySlug(slug: string): Promise<PhraseCategoryWithPhrasesDto> {
    const category = await this.prisma.phraseCategory.findUnique({
      where: { slug },
      include: {
        phrases: {
          where: { isActive: true },
          orderBy: { displayOrder: 'asc' },
        },
      },
    });

    if (!category) {
      throw new NotFoundException(`Category with slug "${slug}" not found`);
    }

    return {
      id: category.id,
      slug: category.slug,
      displayName: category.displayName,
      description: category.description ?? undefined,
      isSystem: category.isSystem,
      isActive: category.isActive,
      displayOrder: category.displayOrder,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
      phrases: category.phrases.map((p) => ({
        id: p.id,
        categoryId: p.categoryId,
        value: p.value,
        displayOrder: p.displayOrder,
        isActive: p.isActive,
        isDefault: p.isDefault,
        metadata: p.metadata as Record<string, unknown> | undefined,
        createdAt: p.createdAt,
        updatedAt: p.updatedAt,
      })),
    };
  }

  async createCategory(dto: CreatePhraseCategoryDto, userId?: string): Promise<PhraseCategoryResponseDto> {
    const existing = await this.prisma.phraseCategory.findUnique({
      where: { slug: dto.slug },
    });

    if (existing) {
      throw new ConflictException(`Category with slug "${dto.slug}" already exists`);
    }

    const category = await this.prisma.phraseCategory.create({
      data: {
        slug: dto.slug,
        displayName: dto.displayName,
        description: dto.description,
        displayOrder: dto.displayOrder ?? 0,
        isSystem: false, // User-created categories are never system
      },
    });

    await this.incrementConfigVersion(userId);
    this.logger.log(`Category created: ${dto.slug}`);

    return {
      id: category.id,
      slug: category.slug,
      displayName: category.displayName,
      description: category.description ?? undefined,
      isSystem: category.isSystem,
      isActive: category.isActive,
      displayOrder: category.displayOrder,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
    };
  }

  async updateCategory(id: string, dto: UpdatePhraseCategoryDto, userId?: string): Promise<PhraseCategoryResponseDto> {
    const existing = await this.prisma.phraseCategory.findUnique({
      where: { id },
    });

    if (!existing) {
      throw new NotFoundException(`Category with ID "${id}" not found`);
    }

    const category = await this.prisma.phraseCategory.update({
      where: { id },
      data: {
        displayName: dto.displayName,
        description: dto.description,
        displayOrder: dto.displayOrder,
        isActive: dto.isActive,
      },
    });

    await this.incrementConfigVersion(userId);
    this.logger.log(`Category updated: ${category.slug}`);

    return {
      id: category.id,
      slug: category.slug,
      displayName: category.displayName,
      description: category.description ?? undefined,
      isSystem: category.isSystem,
      isActive: category.isActive,
      displayOrder: category.displayOrder,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
    };
  }

  async deleteCategory(id: string, userId?: string): Promise<void> {
    const category = await this.prisma.phraseCategory.findUnique({
      where: { id },
    });

    if (!category) {
      throw new NotFoundException(`Category with ID "${id}" not found`);
    }

    if (category.isSystem) {
      throw new ForbiddenException('Cannot delete system categories');
    }

    // Soft-delete via deletedAt timestamp (separate from isActive toggle).
    // Phrases are NOT touched — they remain intact for undo/restore.
    await this.prisma.phraseCategory.update({
      where: { id },
      data: { deletedAt: new Date() },
    });

    await this.incrementConfigVersion(userId);
    this.logger.log(`Category deleted (soft): ${category.slug}`);
  }

  async restoreCategory(id: string, userId?: string): Promise<void> {
    const category = await this.prisma.phraseCategory.findUnique({
      where: { id },
    });

    if (!category) {
      throw new NotFoundException(`Category with ID "${id}" not found`);
    }

    if (!category.deletedAt) {
      return; // Not deleted — nothing to restore
    }

    await this.prisma.phraseCategory.update({
      where: { id },
      data: { deletedAt: null },
    });

    await this.incrementConfigVersion(userId);
    this.logger.log(`Category restored: ${category.slug}`);
  }

  // ============================================
  // Phrases
  // ============================================

  async findPhrasesByCategory(categoryId: string, includeInactive = false): Promise<PhraseResponseDto[]> {
    const phrases = await this.prisma.phrase.findMany({
      where: {
        categoryId,
        ...(includeInactive ? {} : { isActive: true }),
      },
      orderBy: { displayOrder: 'asc' },
    });

    return phrases.map((p) => ({
      id: p.id,
      categoryId: p.categoryId,
      value: p.value,
      displayOrder: p.displayOrder,
      isActive: p.isActive,
      isDefault: p.isDefault,
      metadata: p.metadata as Record<string, unknown> | undefined,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    }));
  }

  async createPhrase(dto: CreatePhraseDto, userId?: string): Promise<PhraseResponseDto> {
    const category = await this.prisma.phraseCategory.findUnique({
      where: { id: dto.categoryId },
    });

    if (!category) {
      throw new NotFoundException(`Category with ID "${dto.categoryId}" not found`);
    }

    // Check for duplicate value in same category
    const existing = await this.prisma.phrase.findUnique({
      where: {
        categoryId_value: {
          categoryId: dto.categoryId,
          value: dto.value,
        },
      },
    });

    if (existing) {
      throw new ConflictException(`Phrase "${dto.value}" already exists in this category`);
    }

    // Get max display order
    const maxOrder = await this.prisma.phrase.aggregate({
      where: { categoryId: dto.categoryId },
      _max: { displayOrder: true },
    });

    const phrase = await this.prisma.phrase.create({
      data: {
        categoryId: dto.categoryId,
        value: dto.value,
        displayOrder: dto.displayOrder ?? (maxOrder._max.displayOrder ?? 0) + 1,
        isDefault: dto.isDefault ?? false,
      },
    });

    await this.incrementConfigVersion(userId);
    this.logger.log(`Phrase created: ${dto.value} in category ${category.slug}`);

    return {
      id: phrase.id,
      categoryId: phrase.categoryId,
      value: phrase.value,
      displayOrder: phrase.displayOrder,
      isActive: phrase.isActive,
      isDefault: phrase.isDefault,
      metadata: phrase.metadata as Record<string, unknown> | undefined,
      createdAt: phrase.createdAt,
      updatedAt: phrase.updatedAt,
    };
  }

  async updatePhrase(id: string, dto: UpdatePhraseDto, userId?: string): Promise<PhraseResponseDto> {
    const existing = await this.prisma.phrase.findUnique({
      where: { id },
    });

    if (!existing) {
      throw new NotFoundException(`Phrase with ID "${id}" not found`);
    }

    // If changing value, check for duplicates
    if (dto.value && dto.value !== existing.value) {
      const duplicate = await this.prisma.phrase.findUnique({
        where: {
          categoryId_value: {
            categoryId: existing.categoryId,
            value: dto.value,
          },
        },
      });

      if (duplicate) {
        throw new ConflictException(`Phrase "${dto.value}" already exists in this category`);
      }
    }

    const phrase = await this.prisma.phrase.update({
      where: { id },
      data: {
        value: dto.value,
        displayOrder: dto.displayOrder,
        isActive: dto.isActive,
        isDefault: dto.isDefault,
      },
    });

    await this.incrementConfigVersion(userId);
    this.logger.log(`Phrase updated: ${phrase.value}`);

    return {
      id: phrase.id,
      categoryId: phrase.categoryId,
      value: phrase.value,
      displayOrder: phrase.displayOrder,
      isActive: phrase.isActive,
      isDefault: phrase.isDefault,
      metadata: phrase.metadata as Record<string, unknown> | undefined,
      createdAt: phrase.createdAt,
      updatedAt: phrase.updatedAt,
    };
  }

  async deletePhrase(id: string, userId?: string): Promise<void> {
    const phrase = await this.prisma.phrase.findUnique({
      where: { id },
    });

    if (!phrase) {
      throw new NotFoundException(`Phrase with ID "${id}" not found`);
    }

    // Soft delete
    await this.prisma.phrase.update({
      where: { id },
      data: { isActive: false },
    });

    await this.incrementConfigVersion(userId);
    this.logger.log(`Phrase deleted: ${phrase.value}`);
  }

  async reorderPhrases(dto: ReorderPhrasesDto, userId?: string): Promise<void> {
    // Validate: category must exist
    const category = await this.prisma.phraseCategory.findUnique({
      where: { id: dto.categoryId },
    });

    if (!category) {
      throw new NotFoundException(`Category with ID "${dto.categoryId}" not found`);
    }

    // Validate: no empty array
    if (!dto.phraseIds || dto.phraseIds.length === 0) {
      throw new BadRequestException('Phrase IDs array cannot be empty');
    }

    // Validate: no duplicate IDs
    const uniqueIds = new Set(dto.phraseIds);
    if (uniqueIds.size !== dto.phraseIds.length) {
      throw new BadRequestException('Duplicate phrase IDs in reorder request');
    }

    // Validate: all phrases exist AND belong to the specified category
    const existingPhrases = await this.prisma.phrase.findMany({
      where: {
        id: { in: dto.phraseIds },
      },
      select: { id: true, categoryId: true },
    });

    // Check all IDs were found
    if (existingPhrases.length !== dto.phraseIds.length) {
      const foundIds = new Set(existingPhrases.map((p) => p.id));
      const missingIds = dto.phraseIds.filter((id) => !foundIds.has(id));
      throw new NotFoundException(
        `Phrases not found: ${missingIds.join(', ')}`,
      );
    }

    // Check all phrases belong to the specified category
    const wrongCategoryPhrases = existingPhrases.filter(
      (p) => p.categoryId !== dto.categoryId,
    );
    if (wrongCategoryPhrases.length > 0) {
      throw new BadRequestException(
        `Phrases do not belong to category ${dto.categoryId}: ${wrongCategoryPhrases.map((p) => p.id).join(', ')}`,
      );
    }

    // Perform the reorder in a transaction
    await this.prisma.$transaction(async (tx) => {
      for (let i = 0; i < dto.phraseIds.length; i++) {
        await tx.phrase.update({
          where: { id: dto.phraseIds[i] },
          data: { displayOrder: i },
        });
      }
    });

    await this.incrementConfigVersion(userId);
    this.logger.log(`Phrases reordered in category ${dto.categoryId}`);
  }

  // ============================================
  // Field Definitions
  // ============================================

  async findAllFields(includeInactive = false): Promise<FieldDefinitionResponseDto[]> {
    const fields = await this.prisma.fieldDefinition.findMany({
      where: includeInactive ? {} : { isActive: true },
      orderBy: [{ sectionType: 'asc' }, { displayOrder: 'asc' }],
    });

    return fields.map((f) => this.mapFieldDefinition(f));
  }

  async findFieldsBySection(sectionType: string): Promise<FieldDefinitionWithOptionsDto[]> {
    const fields = await this.prisma.fieldDefinition.findMany({
      where: { sectionType, isActive: true },
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

    return fields.map((f) => ({
      ...this.mapFieldDefinition(f),
      options: f.phraseCategory?.phrases.map((p) => p.value),
    }));
  }

  async createFieldDefinition(dto: CreateFieldDefinitionDto, userId?: string): Promise<FieldDefinitionResponseDto> {
    // Check for duplicate
    const existing = await this.prisma.fieldDefinition.findUnique({
      where: {
        sectionType_fieldKey: {
          sectionType: dto.sectionType,
          fieldKey: dto.fieldKey,
        },
      },
    });

    if (existing) {
      throw new ConflictException(
        `Field "${dto.fieldKey}" already exists in section "${dto.sectionType}"`,
      );
    }

    // Validate phrase category if provided
    if (dto.phraseCategoryId) {
      const category = await this.prisma.phraseCategory.findUnique({
        where: { id: dto.phraseCategoryId },
      });
      if (!category) {
        throw new NotFoundException(`Phrase category with ID "${dto.phraseCategoryId}" not found`);
      }
    }

    // Get max display order
    const maxOrder = await this.prisma.fieldDefinition.aggregate({
      where: { sectionType: dto.sectionType },
      _max: { displayOrder: true },
    });

    const field = await this.prisma.fieldDefinition.create({
      data: {
        sectionType: dto.sectionType,
        fieldKey: dto.fieldKey,
        fieldType: dto.fieldType,
        label: dto.label,
        placeholder: dto.placeholder,
        hint: dto.hint,
        isRequired: dto.isRequired ?? false,
        displayOrder: dto.displayOrder ?? (maxOrder._max.displayOrder ?? 0) + 1,
        phraseCategoryId: dto.phraseCategoryId,
        validationRules: dto.validationRules as Prisma.InputJsonValue | undefined,
        maxLines: dto.maxLines,
        fieldGroup: dto.fieldGroup,
        conditionalOn: dto.conditionalOn,
        conditionalValue: dto.conditionalValue,
        description: dto.description,
      },
    });

    await this.incrementConfigVersion(userId);
    this.logger.log(`Field created: ${dto.fieldKey} in section ${dto.sectionType}`);

    return this.mapFieldDefinition(field);
  }

  async updateFieldDefinition(id: string, dto: UpdateFieldDefinitionDto, userId?: string): Promise<FieldDefinitionResponseDto> {
    const existing = await this.prisma.fieldDefinition.findUnique({
      where: { id },
    });

    if (!existing) {
      throw new NotFoundException(`Field definition with ID "${id}" not found`);
    }

    // Validate phrase category if provided
    if (dto.phraseCategoryId) {
      const category = await this.prisma.phraseCategory.findUnique({
        where: { id: dto.phraseCategoryId },
      });
      if (!category) {
        throw new NotFoundException(`Phrase category with ID "${dto.phraseCategoryId}" not found`);
      }
    }

    const field = await this.prisma.fieldDefinition.update({
      where: { id },
      data: {
        fieldType: dto.fieldType,
        label: dto.label,
        placeholder: dto.placeholder,
        hint: dto.hint,
        isRequired: dto.isRequired,
        displayOrder: dto.displayOrder,
        phraseCategoryId: dto.phraseCategoryId,
        validationRules: dto.validationRules as Prisma.InputJsonValue | undefined,
        maxLines: dto.maxLines,
        fieldGroup: dto.fieldGroup,
        conditionalOn: dto.conditionalOn,
        conditionalValue: dto.conditionalValue,
        description: dto.description,
        isActive: dto.isActive,
      },
    });

    await this.incrementConfigVersion(userId);
    this.logger.log(`Field updated: ${field.fieldKey}`);

    return this.mapFieldDefinition(field);
  }

  async deleteFieldDefinition(id: string, userId?: string): Promise<void> {
    const field = await this.prisma.fieldDefinition.findUnique({
      where: { id },
    });

    if (!field) {
      throw new NotFoundException(`Field definition with ID "${id}" not found`);
    }

    // Soft delete
    await this.prisma.fieldDefinition.update({
      where: { id },
      data: { isActive: false },
    });

    await this.incrementConfigVersion(userId);
    this.logger.log(`Field deleted: ${field.fieldKey}`);
  }

  async reorderFields(dto: ReorderFieldsDto, userId?: string): Promise<void> {
    // Validate: no empty array
    if (!dto.fieldIds || dto.fieldIds.length === 0) {
      throw new BadRequestException('Field IDs array cannot be empty');
    }

    // Validate: no duplicate IDs
    const uniqueIds = new Set(dto.fieldIds);
    if (uniqueIds.size !== dto.fieldIds.length) {
      throw new BadRequestException('Duplicate field IDs in reorder request');
    }

    // Validate: all fields exist AND belong to the specified section
    const existingFields = await this.prisma.fieldDefinition.findMany({
      where: {
        id: { in: dto.fieldIds },
      },
      select: { id: true, sectionType: true },
    });

    // Check all IDs were found
    if (existingFields.length !== dto.fieldIds.length) {
      const foundIds = new Set(existingFields.map((f) => f.id));
      const missingIds = dto.fieldIds.filter((id) => !foundIds.has(id));
      throw new NotFoundException(
        `Field definitions not found: ${missingIds.join(', ')}`,
      );
    }

    // Check all fields belong to the specified section
    const wrongSectionFields = existingFields.filter(
      (f) => f.sectionType !== dto.sectionType,
    );
    if (wrongSectionFields.length > 0) {
      throw new BadRequestException(
        `Fields do not belong to section ${dto.sectionType}: ${wrongSectionFields.map((f) => f.id).join(', ')}`,
      );
    }

    // Perform the reorder in a transaction
    await this.prisma.$transaction(async (tx) => {
      for (let i = 0; i < dto.fieldIds.length; i++) {
        await tx.fieldDefinition.update({
          where: { id: dto.fieldIds[i] },
          data: { displayOrder: i },
        });
      }
    });

    await this.incrementConfigVersion(userId);
    this.logger.log(`Fields reordered in section ${dto.sectionType}`);
  }

  // ============================================
  // Section Type Definitions
  // ============================================

  /**
   * Seed all standard section types into the database if they don't exist.
   * Idempotent: existing rows are skipped via `skipDuplicates`.
   * Called on module init so the whitelist is never empty.
   */
  async seedDefaultSectionTypes(): Promise<void> {
    // Survey type constants for section classification
    const INSPECTION = ['LEVEL_2', 'LEVEL_3', 'SNAGGING', 'INSPECTION'];
    const VALUATION = ['VALUATION'];
    const SHARED = [...INSPECTION, ...VALUATION];

    const defaults: { key: string; label: string; displayOrder: number; surveyTypes: string[] }[] = [
      // Inspection-specific sections
      { key: 'about-inspection', label: 'About Inspection', displayOrder: 0, surveyTypes: INSPECTION },
      { key: 'external-items', label: 'External Items', displayOrder: 3, surveyTypes: INSPECTION },
      { key: 'internal-items', label: 'Internal Items', displayOrder: 4, surveyTypes: INSPECTION },
      { key: 'issues-and-risks', label: 'Issues and Risks', displayOrder: 9, surveyTypes: INSPECTION },
      // Valuation-specific sections
      { key: 'about-valuation', label: 'About Valuation', displayOrder: 13, surveyTypes: VALUATION },
      { key: 'property-summary', label: 'Property Summary', displayOrder: 14, surveyTypes: VALUATION },
      { key: 'market-analysis', label: 'Market Analysis', displayOrder: 15, surveyTypes: VALUATION },
      { key: 'comparables', label: 'Comparables', displayOrder: 16, surveyTypes: VALUATION },
      { key: 'adjustments', label: 'Adjustments', displayOrder: 17, surveyTypes: VALUATION },
      { key: 'valuation', label: 'Valuation', displayOrder: 18, surveyTypes: VALUATION },
      { key: 'summary', label: 'Summary', displayOrder: 19, surveyTypes: VALUATION },
      // Inspection-only sections (not used by valuation which has its own equivalents)
      { key: 'about-property', label: 'About Property', displayOrder: 1, surveyTypes: INSPECTION },
      { key: 'construction', label: 'Construction', displayOrder: 2, surveyTypes: INSPECTION },
      // NOTE: 'exterior' and 'interior' are legacy keys superseded by
      // 'external-items' and 'internal-items'. They are no longer seeded.
      // Existing rows are deactivated by migration 20260131100000.
      { key: 'rooms', label: 'Rooms', displayOrder: 7, surveyTypes: INSPECTION },
      { key: 'services', label: 'Services', displayOrder: 8, surveyTypes: INSPECTION },
      // Shared sections (used by both inspection and valuation)
      { key: 'photos', label: 'Photos', displayOrder: 10, surveyTypes: SHARED },
      { key: 'notes', label: 'Notes', displayOrder: 11, surveyTypes: INSPECTION },
      { key: 'signature', label: 'Signature', displayOrder: 12, surveyTypes: SHARED },
    ];

    const result = await this.prisma.sectionTypeDefinition.createMany({
      data: defaults.map((d) => ({
        key: d.key,
        label: d.label,
        displayOrder: d.displayOrder,
        surveyTypes: d.surveyTypes,
      })),
      skipDuplicates: true,
    });

    // Update surveyTypes for existing rows that were seeded with empty arrays
    // OR with legacy values from SQL migrations ('homebuyer', 'building', 'valuation').
    // Legacy values don't match the current SurveyType enum, so we normalize them.
    for (const d of defaults) {
      await this.prisma.sectionTypeDefinition.updateMany({
        where: {
          key: d.key,
          OR: [
            { surveyTypes: { isEmpty: true } },
            { surveyTypes: { hasSome: ['homebuyer', 'building', 'valuation'] } },
          ],
        },
        data: { surveyTypes: d.surveyTypes },
      });
    }

    // Fix rows that were previously seeded as SHARED but should be INSPECTION-only.
    // This removes VALUATION from their surveyTypes so valuation surveys don't
    // get inspection-only sections (about-property, construction, rooms, etc.).
    const inspectionOnlyKeys = ['about-property', 'construction', 'rooms', 'services', 'notes'];
    for (const key of inspectionOnlyKeys) {
      await this.prisma.sectionTypeDefinition.updateMany({
        where: {
          key,
          surveyTypes: { hasSome: ['VALUATION'] },
        },
        data: { surveyTypes: INSPECTION },
      });
    }

    if (result.count > 0) {
      this.logger.log(`Seeded ${result.count} default section types`);
    } else {
      this.logger.debug('All default section types already exist');
    }
  }

  async findAllSectionTypes(includeInactive = false): Promise<SectionTypeResponseDto[]> {
    const sectionTypes = await this.prisma.sectionTypeDefinition.findMany({
      where: { ...(includeInactive ? {} : { isActive: true }), deletedAt: null },
      orderBy: [{ displayOrder: 'asc' }, { createdAt: 'asc' }],
    });

    return sectionTypes.map((st) => ({
      id: st.id,
      key: st.key,
      label: st.label,
      description: st.description ?? undefined,
      icon: st.icon ?? undefined,
      displayOrder: st.displayOrder,
      surveyTypes: st.surveyTypes,
      isActive: st.isActive,
      createdAt: st.createdAt,
      updatedAt: st.updatedAt,
    }));
  }

  async createSectionType(dto: CreateSectionTypeDto, userId?: string): Promise<SectionTypeResponseDto> {
    const existing = await this.prisma.sectionTypeDefinition.findUnique({
      where: { key: dto.key },
    });

    if (existing) {
      throw new ConflictException(`Section type with key "${dto.key}" already exists`);
    }

    // Get max display order
    const maxOrder = await this.prisma.sectionTypeDefinition.aggregate({
      _max: { displayOrder: true },
    });

    const sectionType = await this.prisma.sectionTypeDefinition.create({
      data: {
        key: dto.key,
        label: dto.label,
        description: dto.description,
        icon: dto.icon,
        displayOrder: dto.displayOrder ?? (maxOrder._max.displayOrder ?? 0) + 1,
        surveyTypes: dto.surveyTypes ?? [],
      },
    });

    await this.incrementConfigVersion(userId);
    this.logger.log(`Section type created: ${dto.key}`);

    return {
      id: sectionType.id,
      key: sectionType.key,
      label: sectionType.label,
      description: sectionType.description ?? undefined,
      icon: sectionType.icon ?? undefined,
      displayOrder: sectionType.displayOrder,
      surveyTypes: sectionType.surveyTypes,
      isActive: sectionType.isActive,
      createdAt: sectionType.createdAt,
      updatedAt: sectionType.updatedAt,
    };
  }

  async updateSectionType(id: string, dto: UpdateSectionTypeDto, userId?: string): Promise<SectionTypeResponseDto> {
    const existing = await this.prisma.sectionTypeDefinition.findUnique({
      where: { id },
    });

    if (!existing) {
      throw new NotFoundException(`Section type with ID "${id}" not found`);
    }

    const sectionType = await this.prisma.sectionTypeDefinition.update({
      where: { id },
      data: {
        label: dto.label,
        description: dto.description,
        icon: dto.icon,
        displayOrder: dto.displayOrder,
        surveyTypes: dto.surveyTypes,
        isActive: dto.isActive,
      },
    });

    await this.incrementConfigVersion(userId);
    this.logger.log(`Section type updated: ${sectionType.key}`);

    return {
      id: sectionType.id,
      key: sectionType.key,
      label: sectionType.label,
      description: sectionType.description ?? undefined,
      icon: sectionType.icon ?? undefined,
      displayOrder: sectionType.displayOrder,
      surveyTypes: sectionType.surveyTypes,
      isActive: sectionType.isActive,
      createdAt: sectionType.createdAt,
      updatedAt: sectionType.updatedAt,
    };
  }

  async deleteSectionType(id: string, userId?: string): Promise<void> {
    const sectionType = await this.prisma.sectionTypeDefinition.findUnique({
      where: { id },
    });

    if (!sectionType) {
      throw new NotFoundException(`Section type with ID "${id}" not found`);
    }

    // Soft-delete via deletedAt (separate from isActive toggle)
    await this.prisma.sectionTypeDefinition.update({
      where: { id },
      data: { deletedAt: new Date() },
    });

    await this.incrementConfigVersion(userId);
    this.logger.log(`Section type deleted (soft): ${sectionType.key}`);
  }

  async restoreSectionType(id: string, userId?: string): Promise<void> {
    const sectionType = await this.prisma.sectionTypeDefinition.findUnique({
      where: { id },
    });

    if (!sectionType) {
      throw new NotFoundException(`Section type with ID "${id}" not found`);
    }

    if (!sectionType.deletedAt) {
      return; // Not deleted — nothing to restore
    }

    await this.prisma.sectionTypeDefinition.update({
      where: { id },
      data: { deletedAt: null },
    });

    await this.incrementConfigVersion(userId);
    this.logger.log(`Section type restored: ${sectionType.key}`);
  }

  async reorderSectionTypes(dto: ReorderSectionTypesDto, userId?: string): Promise<void> {
    if (!dto.sectionTypeIds || dto.sectionTypeIds.length === 0) {
      throw new BadRequestException('Section type IDs array cannot be empty');
    }

    const uniqueIds = new Set(dto.sectionTypeIds);
    if (uniqueIds.size !== dto.sectionTypeIds.length) {
      throw new BadRequestException('Duplicate section type IDs in reorder request');
    }

    // Validate all IDs exist
    const existing = await this.prisma.sectionTypeDefinition.findMany({
      where: { id: { in: dto.sectionTypeIds } },
      select: { id: true },
    });

    if (existing.length !== dto.sectionTypeIds.length) {
      const foundIds = new Set(existing.map((s) => s.id));
      const missingIds = dto.sectionTypeIds.filter((id) => !foundIds.has(id));
      throw new NotFoundException(
        `Section types not found: ${missingIds.join(', ')}`,
      );
    }

    await this.prisma.$transaction(async (tx) => {
      for (let i = 0; i < dto.sectionTypeIds.length; i++) {
        await tx.sectionTypeDefinition.update({
          where: { id: dto.sectionTypeIds[i] },
          data: { displayOrder: i },
        });
      }
    });

    await this.incrementConfigVersion(userId);
    this.logger.log(`Section types reordered`);
  }

  // ============================================
  // Full Config (Public API)
  // ============================================

  async getFullConfig(): Promise<FullConfigResponseDto> {
    // Check cache first
    if (this.isCacheValid()) {
      this.logger.debug('Config cache HIT');
      return this.configCache.data!;
    }

    this.logger.debug('Config cache MISS - fetching from database');
    const startTime = Date.now();

    const [configVersion, categories, fieldDefinitions, sectionTypeDefinitions] = await Promise.all([
      this.prisma.configVersion.findFirst(),
      this.prisma.phraseCategory.findMany({
        where: { isActive: true, deletedAt: null },
        orderBy: { displayOrder: 'asc' },
        include: {
          phrases: {
            where: { isActive: true },
            orderBy: { displayOrder: 'asc' },
          },
        },
      }),
      this.prisma.fieldDefinition.findMany({
        where: { isActive: true },
        orderBy: [{ sectionType: 'asc' }, { displayOrder: 'asc' }],
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
      }),
      this.prisma.sectionTypeDefinition.findMany({
        where: { deletedAt: null },
        orderBy: { displayOrder: 'asc' },
      }),
    ]);

    // Map categories
    const categoryMap: CategoryWithPhrasesDto[] = categories.map((c) => ({
      slug: c.slug,
      displayName: c.displayName,
      phrases: c.phrases.map((p) => p.value),
    }));

    // Group fields by section
    const fieldsBySection: Record<string, FieldConfigDto[]> = {};
    for (const f of fieldDefinitions) {
      if (!fieldsBySection[f.sectionType]) {
        fieldsBySection[f.sectionType] = [];
      }
      fieldsBySection[f.sectionType].push({
        key: f.fieldKey,
        label: f.label,
        type: f.fieldType.toLowerCase(),
        hint: f.hint ?? undefined,
        placeholder: f.placeholder ?? undefined,
        required: f.isRequired,
        options: f.phraseCategory?.phrases.map((p) => p.value),
        maxLines: f.maxLines ?? undefined,
        group: f.fieldGroup ?? undefined,
        conditionalOn: f.conditionalOn ?? undefined,
        conditionalValue: f.conditionalValue ?? undefined,
        description: f.description ?? undefined,
      });
    }

    // Map section types
    const sectionTypes = sectionTypeDefinitions.map((st) => ({
      key: st.key,
      label: st.label,
      description: st.description ?? undefined,
      icon: st.icon ?? undefined,
      isActive: st.isActive,
      displayOrder: st.displayOrder,
      surveyTypes: st.surveyTypes,
    }));

    const result: FullConfigResponseDto = {
      version: configVersion?.version ?? 1,
      updatedAt: configVersion?.updatedAt ?? new Date(),
      categories: categoryMap,
      fields: fieldsBySection,
      sectionTypes,
    };

    // Store in cache
    this.configCache = {
      data: result,
      timestamp: Date.now(),
    };

    const duration = Date.now() - startTime;
    this.logger.debug(`Config fetched from database in ${duration}ms`);

    return result;
  }

  // ============================================
  // User Role Management (Admin Only)
  // ============================================

  /**
   * @deprecated Use findUsersPaginated instead. Kept for backward compatibility.
   */
  async findAllUsers(): Promise<UserAdminResponseDto[]> {
    const users = await this.prisma.user.findMany({
      orderBy: [{ role: 'asc' }, { createdAt: 'desc' }],
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        role: true,
        isActive: true,
        createdAt: true,
      },
    });

    return users.map((u) => ({
      id: u.id,
      email: u.email,
      firstName: u.firstName ?? undefined,
      lastName: u.lastName ?? undefined,
      role: u.role,
      isActive: u.isActive,
      createdAt: u.createdAt,
    }));
  }

  /**
   * Find users with pagination and filtering
   */
  async findUsersPaginated(query: UsersQueryDto): Promise<UsersListResponseDto> {
    const page = query.page ?? 1;
    const limit = Math.min(query.limit ?? 20, 100);
    const skip = (page - 1) * limit;

    const where: Prisma.UserWhereInput = {};

    if (query.role) {
      where.role = query.role;
    }

    if (query.isActive !== undefined) {
      where.isActive = query.isActive;
    }

    if (query.q) {
      const searchTerm = query.q.toLowerCase();
      where.OR = [
        { email: { contains: searchTerm, mode: 'insensitive' } },
        { firstName: { contains: searchTerm, mode: 'insensitive' } },
        { lastName: { contains: searchTerm, mode: 'insensitive' } },
      ];
    }

    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        orderBy: [{ role: 'asc' }, { createdAt: 'desc' }],
        skip,
        take: limit,
        select: {
          id: true,
          email: true,
          firstName: true,
          lastName: true,
          role: true,
          isActive: true,
          createdAt: true,
        },
      }),
      this.prisma.user.count({ where }),
    ]);

    const totalPages = Math.ceil(total / limit);

    return {
      data: users.map((u) => ({
        id: u.id,
        email: u.email,
        firstName: u.firstName ?? undefined,
        lastName: u.lastName ?? undefined,
        role: u.role,
        isActive: u.isActive,
        createdAt: u.createdAt,
      })),
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

  async updateUserRole(userId: string, newRole: UserRole, currentUserId: string): Promise<UserAdminResponseDto> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException(`User with ID "${userId}" not found`);
    }

    // Safety check: cannot demote the last ADMIN
    if (user.role === UserRole.ADMIN && newRole !== UserRole.ADMIN) {
      const adminCount = await this.prisma.user.count({
        where: { role: UserRole.ADMIN, isActive: true },
      });

      if (adminCount <= 1) {
        throw new ForbiddenException(
          'Cannot demote the last active ADMIN. Promote another user to ADMIN first.',
        );
      }
    }

    // Safety check: cannot demote yourself if you're the last ADMIN
    if (userId === currentUserId && user.role === UserRole.ADMIN && newRole !== UserRole.ADMIN) {
      throw new ForbiddenException(
        'You cannot demote yourself from ADMIN. Have another ADMIN demote you.',
      );
    }

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: { role: newRole },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        role: true,
        isActive: true,
        createdAt: true,
      },
    });

    // SEC-002: Audit role changes for SOC2 compliance (no PII in logs)
    this.logger.log(`User ${userId} role changed from ${user.role} to ${newRole} by ${currentUserId}`);

    await this.auditService.log({
      actorType: ActorType.STAFF,
      actorId: currentUserId,
      action: AuditActions.USER_ROLE_CHANGED,
      entityType: AuditEntityType.AUTH,
      entityId: userId,
      metadata: { oldRole: user.role, newRole },
    });

    return {
      id: updated.id,
      email: updated.email,
      firstName: updated.firstName ?? undefined,
      lastName: updated.lastName ?? undefined,
      role: updated.role,
      isActive: updated.isActive,
      createdAt: updated.createdAt,
    };
  }

  // ============================================
  // Helpers
  // ============================================

  private mapFieldDefinition(field: {
    id: string;
    sectionType: string;
    fieldKey: string;
    fieldType: string;
    label: string;
    placeholder: string | null;
    hint: string | null;
    isRequired: boolean;
    displayOrder: number;
    phraseCategoryId: string | null;
    validationRules: unknown;
    maxLines: number | null;
    fieldGroup: string | null;
    conditionalOn: string | null;
    conditionalValue: string | null;
    description: string | null;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
  }): FieldDefinitionResponseDto {
    return {
      id: field.id,
      sectionType: field.sectionType,
      fieldKey: field.fieldKey,
      fieldType: field.fieldType as any,
      label: field.label,
      placeholder: field.placeholder ?? undefined,
      hint: field.hint ?? undefined,
      isRequired: field.isRequired,
      displayOrder: field.displayOrder,
      phraseCategoryId: field.phraseCategoryId ?? undefined,
      validationRules: field.validationRules as Record<string, unknown> | undefined,
      maxLines: field.maxLines ?? undefined,
      fieldGroup: field.fieldGroup ?? undefined,
      conditionalOn: field.conditionalOn ?? undefined,
      conditionalValue: field.conditionalValue ?? undefined,
      description: field.description ?? undefined,
      isActive: field.isActive,
      createdAt: field.createdAt,
      updatedAt: field.updatedAt,
    };
  }

  // ============================================
  // V2 Tree Publishing
  // ============================================

  /**
   * Publish a V2 tree (inspection or valuation) from the mobile admin panel.
   * Creates an immutable version record for audit trail.
   */
  async uploadV2Tree(
    dto: UploadV2TreeDto,
    userId: string,
  ): Promise<V2TreeUploadResponseDto> {
    // Validate tree structure
    this.validateV2TreeStructure(dto.tree);

    // Serialize and compute checksum
    const treeJson = JSON.stringify(dto.tree);
    const sizeBytes = Buffer.byteLength(treeJson, 'utf8');
    const checksum = crypto.createHash('sha256').update(treeJson).digest('hex');

    // Determine next version number
    const latestVersion = await this.prisma.v2TreeVersion.findFirst({
      where: { treeType: dto.treeType },
      orderBy: { version: 'desc' },
      select: { version: true },
    });
    const nextVersion = (latestVersion?.version ?? 0) + 1;

    // Create version record
    const record = await this.prisma.v2TreeVersion.create({
      data: {
        treeType: dto.treeType,
        version: nextVersion,
        treeData: dto.tree as any,
        sizeBytes,
        checksum,
        publishedBy: userId,
      },
    });

    // Increment config version for cache invalidation across clients
    await this.incrementConfigVersion(userId);
    this.invalidateConfigCache();

    // Audit log
    await this.auditService.log({
      actorType: ActorType.STAFF,
      actorId: userId,
      action: 'config.v2_tree_published',
      entityType: AuditEntityType.SURVEY,
      entityId: record.id,
      metadata: {
        treeType: dto.treeType,
        version: nextVersion,
        sizeBytes,
        checksum,
      },
    });

    this.logger.log(
      `V2 tree published: type=${dto.treeType} version=${nextVersion} ` +
      `size=${sizeBytes}B checksum=${checksum.substring(0, 12)}...`,
    );

    return {
      id: record.id,
      treeType: record.treeType,
      version: record.version,
      sizeBytes: record.sizeBytes,
      checksum: record.checksum ?? checksum,
      publishedAt: record.publishedAt,
    };
  }

  /**
   * Get the latest published V2 tree for a given type.
   */
  async getLatestV2Tree(treeType: string): Promise<V2TreeLatestResponseDto> {
    if (!['inspection_v2', 'valuation_v2'].includes(treeType)) {
      throw new BadRequestException('treeType must be "inspection_v2" or "valuation_v2"');
    }

    const latest = await this.prisma.v2TreeVersion.findFirst({
      where: { treeType },
      orderBy: { version: 'desc' },
    });

    if (!latest) {
      throw new NotFoundException(`No published tree found for type "${treeType}"`);
    }

    return {
      treeType: latest.treeType,
      version: latest.version,
      tree: latest.treeData as Record<string, unknown>,
      publishedAt: latest.publishedAt,
      checksum: latest.checksum ?? '',
    };
  }

  /// Valid field types matching the Flutter InspectionFieldType enum
  private static readonly VALID_FIELD_TYPES = [
    'checkbox', 'text', 'dropdown', 'number', 'label',
  ];

  /**
   * Structural validation for V2 tree JSON.
   * Validates sections → nodes → fields to match Flutter client expectations.
   * Mirrors the client-side validateTree() in tree_admin_repository.dart.
   */
  private validateV2TreeStructure(tree: Record<string, unknown>): void {
    const sections = tree['sections'];
    if (!Array.isArray(sections) || sections.length === 0) {
      throw new BadRequestException('Tree must have a non-empty "sections" array');
    }

    const allNodeIds = new Set<string>();

    for (const section of sections) {
      if (typeof section !== 'object' || section === null) {
        throw new BadRequestException('Each section must be an object');
      }
      const s = section as Record<string, unknown>;
      if (!s['key'] || typeof s['key'] !== 'string') {
        throw new BadRequestException('Each section must have a "key" string');
      }
      if (!s['title'] || typeof s['title'] !== 'string') {
        throw new BadRequestException(`Section "${s['key']}" must have a "title" string`);
      }
      const nodes = s['nodes'];
      if (!Array.isArray(nodes)) {
        throw new BadRequestException(`Section "${s['key']}" must have a "nodes" array`);
      }

      for (const node of nodes) {
        if (typeof node !== 'object' || node === null) {
          throw new BadRequestException(`Section "${s['key']}" contains invalid node`);
        }
        const n = node as Record<string, unknown>;
        if (!n['id'] || typeof n['id'] !== 'string') {
          throw new BadRequestException(`Node in section "${s['key']}" must have an "id" string`);
        }
        if (!n['type'] || !['screen', 'group'].includes(n['type'] as string)) {
          throw new BadRequestException(
            `Node "${n['id']}" must have a "type" of "screen" or "group"`,
          );
        }

        // Detect duplicate node IDs
        if (allNodeIds.has(n['id'] as string)) {
          throw new BadRequestException(`Duplicate node ID: "${n['id']}"`);
        }
        allNodeIds.add(n['id'] as string);

        // Validate fields on screen nodes
        if (n['type'] === 'screen') {
          this.validateNodeFields(n);
        }

        // Recursively validate children for group nodes
        if (n['type'] === 'group' && Array.isArray(n['children'])) {
          this.validateGroupChildren(n['children'] as unknown[], n['id'] as string, allNodeIds);
        }
      }
    }
  }

  /**
   * Validate fields array within a screen node.
   */
  private validateNodeFields(node: Record<string, unknown>): void {
    const fields = node['fields'];
    if (!Array.isArray(fields)) {
      return; // Screens may have no fields array (e.g., group navigation screens)
    }

    const fieldIds = new Set<string>();

    for (const field of fields) {
      if (typeof field !== 'object' || field === null) {
        throw new BadRequestException(
          `Screen "${node['id']}" contains invalid field entry`,
        );
      }
      const f = field as Record<string, unknown>;

      // Every field must have an id
      if (!f['id'] || typeof f['id'] !== 'string') {
        throw new BadRequestException(
          `Field in screen "${node['id']}" has empty or missing "id"`,
        );
      }

      // Every field must have a valid type
      if (!f['type'] || !ConfigService.VALID_FIELD_TYPES.includes(f['type'] as string)) {
        throw new BadRequestException(
          `Field "${f['id']}" in screen "${node['id']}" has invalid type "${f['type']}". ` +
          `Valid types: ${ConfigService.VALID_FIELD_TYPES.join(', ')}`,
        );
      }

      // Detect duplicate field IDs within the same screen
      if (fieldIds.has(f['id'] as string)) {
        throw new BadRequestException(
          `Duplicate field ID "${f['id']}" in screen "${node['id']}"`,
        );
      }
      fieldIds.add(f['id'] as string);

      // Dropdown fields must have non-empty options array
      if (f['type'] === 'dropdown') {
        const options = f['options'];
        if (!Array.isArray(options) || options.length === 0) {
          throw new BadRequestException(
            `Dropdown field "${f['id']}" in screen "${node['id']}" has no options`,
          );
        }
      }
    }
  }

  /**
   * Recursively validate children nodes in a group.
   */
  private validateGroupChildren(
    children: unknown[],
    parentId: string,
    allNodeIds: Set<string>,
  ): void {
    for (const child of children) {
      if (typeof child !== 'object' || child === null) {
        throw new BadRequestException(`Group "${parentId}" contains invalid child node`);
      }
      const c = child as Record<string, unknown>;
      if (!c['id'] || typeof c['id'] !== 'string') {
        throw new BadRequestException(`Child node in group "${parentId}" must have an "id" string`);
      }
      if (!c['type'] || !['screen', 'group'].includes(c['type'] as string)) {
        throw new BadRequestException(
          `Child node "${c['id']}" in group "${parentId}" must have a "type" of "screen" or "group"`,
        );
      }

      if (allNodeIds.has(c['id'] as string)) {
        throw new BadRequestException(`Duplicate node ID: "${c['id']}"`);
      }
      allNodeIds.add(c['id'] as string);

      if (c['type'] === 'screen') {
        this.validateNodeFields(c);
      }

      if (c['type'] === 'group' && Array.isArray(c['children'])) {
        this.validateGroupChildren(c['children'] as unknown[], c['id'] as string, allNodeIds);
      }
    }
  }
}
