import { Test, TestingModule } from '@nestjs/testing';
import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { ConfigService } from './config.service';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';

describe('ConfigService', () => {
  let service: ConfigService;
  let prismaService: jest.Mocked<PrismaService>;

  const mockAdminUser = {
    id: 'admin-uuid-123',
    email: 'admin@example.com',
    firstName: 'Admin',
    lastName: 'User',
    role: UserRole.ADMIN,
    isActive: true,
    createdAt: new Date('2024-01-01'),
  };

  const mockSurveyorUser = {
    id: 'surveyor-uuid-456',
    email: 'surveyor@example.com',
    firstName: 'Surveyor',
    lastName: 'User',
    role: UserRole.SURVEYOR,
    isActive: true,
    createdAt: new Date('2024-01-01'),
  };

  const mockPrismaService = {
    user: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
      update: jest.fn(),
    },
    configVersion: {
      findFirst: jest.fn(),
      updateMany: jest.fn(),
    },
    phraseCategory: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      update: jest.fn(),
    },
    fieldDefinition: {
      findMany: jest.fn(),
    },
    sectionTypeDefinition: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      update: jest.fn(),
      createMany: jest.fn(),
      updateMany: jest.fn(),
    },
  };

  const mockAuditService = {
    log: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ConfigService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: AuditService, useValue: mockAuditService },
      ],
    }).compile();

    service = module.get<ConfigService>(ConfigService);
    prismaService = module.get(PrismaService);
  });

  describe('updateUserRole - Last Admin Protection', () => {
    it('should throw ForbiddenException when demoting the last active ADMIN', async () => {
      // Arrange: User is an ADMIN, only 1 active ADMIN exists
      mockPrismaService.user.findUnique.mockResolvedValue(mockAdminUser);
      mockPrismaService.user.count.mockResolvedValue(1); // Only 1 admin

      // Act & Assert
      await expect(
        service.updateUserRole(mockAdminUser.id, UserRole.SURVEYOR, 'other-admin-id'),
      ).rejects.toThrow(ForbiddenException);

      await expect(
        service.updateUserRole(mockAdminUser.id, UserRole.SURVEYOR, 'other-admin-id'),
      ).rejects.toThrow('Cannot demote the last active ADMIN');
    });

    it('should throw ForbiddenException when admin tries to demote themselves', async () => {
      // Arrange: User is demoting themselves
      mockPrismaService.user.findUnique.mockResolvedValue(mockAdminUser);
      mockPrismaService.user.count.mockResolvedValue(2); // Multiple admins exist

      // Act & Assert
      await expect(
        service.updateUserRole(mockAdminUser.id, UserRole.SURVEYOR, mockAdminUser.id),
      ).rejects.toThrow(ForbiddenException);

      await expect(
        service.updateUserRole(mockAdminUser.id, UserRole.SURVEYOR, mockAdminUser.id),
      ).rejects.toThrow('You cannot demote yourself from ADMIN');
    });

    it('should allow demoting an ADMIN when multiple ADMINs exist', async () => {
      // Arrange: Multiple admins exist, different admin is doing the demotion
      mockPrismaService.user.findUnique.mockResolvedValue(mockAdminUser);
      mockPrismaService.user.count.mockResolvedValue(3); // Multiple admins
      mockPrismaService.user.update.mockResolvedValue({
        ...mockAdminUser,
        role: UserRole.SURVEYOR,
      });

      // Act
      const result = await service.updateUserRole(
        mockAdminUser.id,
        UserRole.SURVEYOR,
        'different-admin-id',
      );

      // Assert
      expect(result.role).toBe(UserRole.SURVEYOR);
      expect(mockPrismaService.user.update).toHaveBeenCalledWith({
        where: { id: mockAdminUser.id },
        data: { role: UserRole.SURVEYOR },
        select: expect.any(Object),
      });
    });

    it('should allow promoting a SURVEYOR to ADMIN without restrictions', async () => {
      // Arrange
      mockPrismaService.user.findUnique.mockResolvedValue(mockSurveyorUser);
      mockPrismaService.user.update.mockResolvedValue({
        ...mockSurveyorUser,
        role: UserRole.ADMIN,
      });

      // Act
      const result = await service.updateUserRole(
        mockSurveyorUser.id,
        UserRole.ADMIN,
        'admin-id',
      );

      // Assert
      expect(result.role).toBe(UserRole.ADMIN);
      // count() should NOT be called for promotions
      expect(mockPrismaService.user.count).not.toHaveBeenCalled();
    });

    it('should throw NotFoundException when user does not exist', async () => {
      // Arrange
      mockPrismaService.user.findUnique.mockResolvedValue(null);

      // Act & Assert
      await expect(
        service.updateUserRole('nonexistent-id', UserRole.SURVEYOR, 'admin-id'),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('getFullConfig - Caching', () => {
    const mockConfigVersion = { version: 1, updatedAt: new Date(), updatedBy: null };
    const mockCategories = [
      {
        id: 'cat-1',
        slug: 'conditions',
        displayName: 'Conditions',
        isActive: true,
        displayOrder: 1,
        phrases: [
          { id: 'p1', value: 'Good', isActive: true, displayOrder: 1 },
          { id: 'p2', value: 'Fair', isActive: true, displayOrder: 2 },
        ],
      },
    ];
    const mockFieldDefinitions = [
      {
        id: 'field-1',
        fieldKey: 'roof_condition',
        label: 'Roof Condition',
        fieldType: 'DROPDOWN',
        sectionType: 'exterior',
        isActive: true,
        isRequired: true,
        displayOrder: 1,
        hint: null,
        placeholder: null,
        maxLines: null,
        phraseCategory: {
          id: 'cat-1',
          phrases: [{ id: 'p1', value: 'Good' }, { id: 'p2', value: 'Fair' }],
        },
      },
    ];

    beforeEach(() => {
      mockPrismaService.configVersion.findFirst.mockResolvedValue(mockConfigVersion);
      mockPrismaService.phraseCategory.findMany.mockResolvedValue(mockCategories);
      mockPrismaService.fieldDefinition.findMany.mockResolvedValue(mockFieldDefinitions);
      mockPrismaService.sectionTypeDefinition.findMany.mockResolvedValue([]);
    });

    it('should fetch from database on first call (cache miss)', async () => {
      const result = await service.getFullConfig();

      expect(result.version).toBe(1);
      expect(result.categories).toHaveLength(1);
      expect(mockPrismaService.configVersion.findFirst).toHaveBeenCalledTimes(1);
      expect(mockPrismaService.phraseCategory.findMany).toHaveBeenCalledTimes(1);
      expect(mockPrismaService.fieldDefinition.findMany).toHaveBeenCalledTimes(1);
    });

    it('should use cache on second call (cache hit)', async () => {
      // First call - populates cache
      await service.getFullConfig();

      // Clear mock call counts
      jest.clearAllMocks();

      // Second call - should use cache
      const result = await service.getFullConfig();

      expect(result.version).toBe(1);
      expect(result.categories).toHaveLength(1);
      // Database should NOT be hit on second call
      expect(mockPrismaService.configVersion.findFirst).not.toHaveBeenCalled();
      expect(mockPrismaService.phraseCategory.findMany).not.toHaveBeenCalled();
      expect(mockPrismaService.fieldDefinition.findMany).not.toHaveBeenCalled();
    });

    it('should return correct data structure', async () => {
      const result = await service.getFullConfig();

      expect(result).toHaveProperty('version');
      expect(result).toHaveProperty('updatedAt');
      expect(result).toHaveProperty('categories');
      expect(result).toHaveProperty('fields');
      expect(result.categories[0]).toHaveProperty('slug', 'conditions');
      expect(result.categories[0]).toHaveProperty('phrases');
      expect(result.fields).toHaveProperty('exterior');
    });
  });

  describe('deleteSectionType / restoreSectionType', () => {
    const mockSectionType = {
      id: 'st-1',
      key: 'about-property',
      label: 'About Property',
      description: null,
      icon: null,
      displayOrder: 1,
      surveyTypes: [],
      isActive: true,
      deletedAt: null,
      createdAt: new Date('2024-01-01'),
      updatedAt: new Date('2024-01-01'),
    };

    it('should soft-delete a section type by setting deletedAt', async () => {
      mockPrismaService.sectionTypeDefinition.findUnique.mockResolvedValue(mockSectionType);
      mockPrismaService.sectionTypeDefinition.update.mockResolvedValue({
        ...mockSectionType,
        deletedAt: new Date(),
      });
      mockPrismaService.configVersion.updateMany.mockResolvedValue({ count: 1 });

      await service.deleteSectionType('st-1', 'admin-id');

      expect(mockPrismaService.sectionTypeDefinition.update).toHaveBeenCalledWith({
        where: { id: 'st-1' },
        data: { deletedAt: expect.any(Date) },
      });
    });

    it('should throw NotFoundException when deleting non-existent section type', async () => {
      mockPrismaService.sectionTypeDefinition.findUnique.mockResolvedValue(null);

      await expect(
        service.deleteSectionType('non-existent', 'admin-id'),
      ).rejects.toThrow(NotFoundException);
    });

    it('should restore a section type by clearing deletedAt', async () => {
      const deletedSectionType = { ...mockSectionType, deletedAt: new Date() };
      mockPrismaService.sectionTypeDefinition.findUnique.mockResolvedValue(deletedSectionType);
      mockPrismaService.sectionTypeDefinition.update.mockResolvedValue(mockSectionType);
      mockPrismaService.configVersion.updateMany.mockResolvedValue({ count: 1 });

      await service.restoreSectionType('st-1', 'admin-id');

      expect(mockPrismaService.sectionTypeDefinition.update).toHaveBeenCalledWith({
        where: { id: 'st-1' },
        data: { deletedAt: null },
      });
    });

    it('should no-op when restoring a section type that is not deleted', async () => {
      mockPrismaService.sectionTypeDefinition.findUnique.mockResolvedValue(mockSectionType);

      await service.restoreSectionType('st-1', 'admin-id');

      expect(mockPrismaService.sectionTypeDefinition.update).not.toHaveBeenCalled();
    });

    it('should throw NotFoundException when restoring non-existent section type', async () => {
      mockPrismaService.sectionTypeDefinition.findUnique.mockResolvedValue(null);

      await expect(
        service.restoreSectionType('non-existent', 'admin-id'),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('deleteCategory / restoreCategory', () => {
    const mockCategory = {
      id: 'cat-1',
      slug: 'conditions',
      displayName: 'Conditions',
      description: null,
      isSystem: false,
      isActive: true,
      displayOrder: 1,
      deletedAt: null,
      createdAt: new Date('2024-01-01'),
      updatedAt: new Date('2024-01-01'),
    };

    it('should soft-delete a category by setting deletedAt', async () => {
      mockPrismaService.phraseCategory.findUnique.mockResolvedValue(mockCategory);
      mockPrismaService.phraseCategory.update.mockResolvedValue({
        ...mockCategory,
        deletedAt: new Date(),
      });
      mockPrismaService.configVersion.updateMany.mockResolvedValue({ count: 1 });

      await service.deleteCategory('cat-1', 'admin-id');

      expect(mockPrismaService.phraseCategory.update).toHaveBeenCalledWith({
        where: { id: 'cat-1' },
        data: { deletedAt: expect.any(Date) },
      });
    });

    it('should throw ForbiddenException when deleting a system category', async () => {
      const systemCategory = { ...mockCategory, isSystem: true };
      mockPrismaService.phraseCategory.findUnique.mockResolvedValue(systemCategory);

      await expect(
        service.deleteCategory('cat-1', 'admin-id'),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should restore a category by clearing deletedAt', async () => {
      const deletedCategory = { ...mockCategory, deletedAt: new Date() };
      mockPrismaService.phraseCategory.findUnique.mockResolvedValue(deletedCategory);
      mockPrismaService.phraseCategory.update.mockResolvedValue(mockCategory);
      mockPrismaService.configVersion.updateMany.mockResolvedValue({ count: 1 });

      await service.restoreCategory('cat-1', 'admin-id');

      expect(mockPrismaService.phraseCategory.update).toHaveBeenCalledWith({
        where: { id: 'cat-1' },
        data: { deletedAt: null },
      });
    });

    it('should no-op when restoring a category that is not deleted', async () => {
      mockPrismaService.phraseCategory.findUnique.mockResolvedValue(mockCategory);

      await service.restoreCategory('cat-1', 'admin-id');

      expect(mockPrismaService.phraseCategory.update).not.toHaveBeenCalled();
    });
  });

  describe('findAllSectionTypes', () => {
    it('should exclude deleted section types (deletedAt != null)', async () => {
      const activeST = {
        id: 'st-1',
        key: 'exterior',
        label: 'Exterior',
        description: null,
        icon: null,
        displayOrder: 0,
        surveyTypes: [],
        isActive: true,
        deletedAt: null,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      mockPrismaService.sectionTypeDefinition.findMany.mockResolvedValue([activeST]);

      const result = await service.findAllSectionTypes();

      expect(result).toHaveLength(1);
      expect(result[0].key).toBe('exterior');
      // Verify the query filters by deletedAt: null
      expect(mockPrismaService.sectionTypeDefinition.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({ deletedAt: null }),
        }),
      );
    });
  });

  describe('getFullConfig - section type exclusion', () => {
    it('should exclude deleted section types from full config', async () => {
      const mockConfigVersion = { version: 2, updatedAt: new Date(), updatedBy: null };
      mockPrismaService.configVersion.findFirst.mockResolvedValue(mockConfigVersion);
      mockPrismaService.phraseCategory.findMany.mockResolvedValue([]);
      mockPrismaService.fieldDefinition.findMany.mockResolvedValue([]);
      mockPrismaService.sectionTypeDefinition.findMany.mockResolvedValue([
        {
          key: 'exterior',
          label: 'Exterior',
          description: null,
          icon: null,
          isActive: true,
          displayOrder: 0,
          surveyTypes: [],
        },
      ]);

      const result = await service.getFullConfig();

      expect(result.sectionTypes).toHaveLength(1);
      expect(result.sectionTypes[0].key).toBe('exterior');
      // Verify query filters by deletedAt: null
      expect(mockPrismaService.sectionTypeDefinition.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { deletedAt: null },
        }),
      );
    });
  });

  describe('seedDefaultSectionTypes', () => {
    it('should call createMany with skipDuplicates for all standard types (excluding legacy exterior/interior)', async () => {
      mockPrismaService.sectionTypeDefinition.createMany.mockResolvedValue({ count: 18 });
      mockPrismaService.sectionTypeDefinition.updateMany.mockResolvedValue({ count: 0 });

      await service.seedDefaultSectionTypes();

      const call = mockPrismaService.sectionTypeDefinition.createMany.mock.calls[0][0];
      expect(call.skipDuplicates).toBe(true);
      expect(call.data).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ key: 'about-inspection', surveyTypes: expect.arrayContaining(['LEVEL_2', 'INSPECTION']) }),
          // Inspection-only sections (no VALUATION)
          expect.objectContaining({ key: 'about-property', surveyTypes: expect.arrayContaining(['LEVEL_2', 'INSPECTION']) }),
          expect.objectContaining({ key: 'construction', surveyTypes: expect.arrayContaining(['LEVEL_2', 'INSPECTION']) }),
          expect.objectContaining({ key: 'rooms', surveyTypes: expect.arrayContaining(['LEVEL_2', 'INSPECTION']) }),
          expect.objectContaining({ key: 'services', surveyTypes: expect.arrayContaining(['LEVEL_2', 'INSPECTION']) }),
          expect.objectContaining({ key: 'notes', surveyTypes: expect.arrayContaining(['LEVEL_2', 'INSPECTION']) }),
          // Shared sections (both inspection and valuation)
          expect.objectContaining({ key: 'photos', surveyTypes: expect.arrayContaining(['LEVEL_2', 'INSPECTION', 'VALUATION']) }),
          expect.objectContaining({ key: 'signature', surveyTypes: expect.arrayContaining(['LEVEL_2', 'INSPECTION', 'VALUATION']) }),
          // Valuation-only
          expect.objectContaining({ key: 'summary', surveyTypes: ['VALUATION'] }),
          expect.objectContaining({ key: 'about-valuation', surveyTypes: ['VALUATION'] }),
        ]),
      );
      // Inspection-only sections must NOT have VALUATION
      const inspectionOnly = call.data.filter((d: any) =>
        ['about-property', 'construction', 'rooms', 'services', 'notes'].includes(d.key),
      );
      for (const entry of inspectionOnly) {
        expect(entry.surveyTypes).not.toContain('VALUATION');
      }
      // Legacy keys should NOT be seeded
      const keys = call.data.map((d: any) => d.key);
      expect(keys).not.toContain('exterior');
      expect(keys).not.toContain('interior');
    });

    it('should be idempotent — skip existing types', async () => {
      mockPrismaService.sectionTypeDefinition.createMany.mockResolvedValue({ count: 0 });
      mockPrismaService.sectionTypeDefinition.updateMany.mockResolvedValue({ count: 0 });

      await service.seedDefaultSectionTypes();

      expect(mockPrismaService.sectionTypeDefinition.createMany).toHaveBeenCalledWith(
        expect.objectContaining({ skipDuplicates: true }),
      );
    });

    it('should backfill surveyTypes for existing rows with empty or legacy arrays', async () => {
      mockPrismaService.sectionTypeDefinition.createMany.mockResolvedValue({ count: 0 });
      mockPrismaService.sectionTypeDefinition.updateMany.mockResolvedValue({ count: 1 });

      await service.seedDefaultSectionTypes();

      // Should call updateMany for each default section type to backfill empty
      // surveyTypes OR normalize legacy values ('homebuyer', 'building', 'valuation').
      expect(mockPrismaService.sectionTypeDefinition.updateMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: {
            key: 'about-inspection',
            OR: [
              { surveyTypes: { isEmpty: true } },
              { surveyTypes: { hasSome: ['homebuyer', 'building', 'valuation'] } },
            ],
          },
          data: { surveyTypes: expect.arrayContaining(['LEVEL_2', 'LEVEL_3', 'SNAGGING', 'INSPECTION']) },
        }),
      );
      expect(mockPrismaService.sectionTypeDefinition.updateMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: {
            key: 'about-valuation',
            OR: [
              { surveyTypes: { isEmpty: true } },
              { surveyTypes: { hasSome: ['homebuyer', 'building', 'valuation'] } },
            ],
          },
          data: { surveyTypes: ['VALUATION'] },
        }),
      );
    });
  });
});
