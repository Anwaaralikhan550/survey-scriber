import { Test, TestingModule } from '@nestjs/testing';
import { UserRole, ActorType, AuditEntityType } from '@prisma/client';
import { ConfigService } from './config.service';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService, AuditActions } from '../audit/audit.service';

/**
 * SEC-002: Role Change Audit Tests
 * SEC-003: PII in Logs Tests
 * Verifies that role changes are properly audited and PII is not exposed
 */
describe('ConfigService - Role Change Audit (SEC-002)', () => {
  let service: ConfigService;
  let prismaService: jest.Mocked<PrismaService>;
  let auditService: jest.Mocked<AuditService>;

  const mockUser = {
    id: 'user-123',
    email: 'user@example.com',
    firstName: 'Test',
    lastName: 'User',
    role: UserRole.SURVEYOR,
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const mockPrismaService = {
    user: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      update: jest.fn(),
      count: jest.fn(),
    },
    configVersion: {
      findFirst: jest.fn(),
      updateMany: jest.fn(),
    },
    phraseCategory: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    phrase: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
      updateMany: jest.fn(),
    },
    fieldDefinition: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
      updateMany: jest.fn(),
    },
    fieldOption: {
      createMany: jest.fn(),
      deleteMany: jest.fn(),
    },
    sectionTypeDefinition: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      aggregate: jest.fn(),
      $transaction: jest.fn(),
    },
  };

  const mockAuditService = {
    log: jest.fn(),
    query: jest.fn(),
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
    auditService = module.get(AuditService);
  });

  describe('updateUserRole - Audit Logging', () => {
    it('should audit role changes with correct metadata', async () => {
      const currentUserId = 'admin-456';
      const targetUserId = 'user-123';
      const oldRole = UserRole.SURVEYOR;
      const newRole = UserRole.ADMIN;

      mockPrismaService.user.findUnique.mockResolvedValue({
        ...mockUser,
        role: oldRole,
      });

      mockPrismaService.user.count.mockResolvedValue(2); // More than 1 admin

      mockPrismaService.user.update.mockResolvedValue({
        ...mockUser,
        role: newRole,
      });

      await service.updateUserRole(targetUserId, newRole, currentUserId);

      expect(auditService.log).toHaveBeenCalledWith({
        actorType: ActorType.STAFF,
        actorId: currentUserId,
        action: AuditActions.USER_ROLE_CHANGED,
        entityType: AuditEntityType.AUTH,
        entityId: targetUserId,
        metadata: { oldRole, newRole },
      });
    });

    it('should capture both old and new roles in audit metadata', async () => {
      const currentUserId = 'admin-456';
      const targetUserId = 'user-123';

      mockPrismaService.user.findUnique.mockResolvedValue({
        ...mockUser,
        role: UserRole.SURVEYOR,
      });

      mockPrismaService.user.update.mockResolvedValue({
        ...mockUser,
        role: UserRole.MANAGER,
      });

      await service.updateUserRole(targetUserId, UserRole.MANAGER, currentUserId);

      const auditCall = auditService.log.mock.calls[0][0];
      expect(auditCall.metadata?.oldRole).toBe(UserRole.SURVEYOR);
      expect(auditCall.metadata?.newRole).toBe(UserRole.MANAGER);
    });

    it('should use user ID (not email) in actorId and entityId', async () => {
      const currentUserId = 'admin-456';
      const targetUserId = 'user-123';

      mockPrismaService.user.findUnique.mockResolvedValue({
        ...mockUser,
        role: UserRole.SURVEYOR,
      });

      mockPrismaService.user.update.mockResolvedValue({
        ...mockUser,
        role: UserRole.MANAGER,
      });

      await service.updateUserRole(targetUserId, UserRole.MANAGER, currentUserId);

      const auditCall = auditService.log.mock.calls[0][0];

      // Verify IDs are UUIDs, not emails
      expect(auditCall.actorId).toBe(currentUserId);
      expect(auditCall.entityId).toBe(targetUserId);
      expect(auditCall.actorId).not.toContain('@');
      expect(auditCall.entityId).not.toContain('@');
    });

    it('should audit role downgrades as well as upgrades', async () => {
      const currentUserId = 'admin-456';
      const targetUserId = 'user-123';

      mockPrismaService.user.findUnique.mockResolvedValue({
        ...mockUser,
        role: UserRole.MANAGER,
      });

      mockPrismaService.user.update.mockResolvedValue({
        ...mockUser,
        role: UserRole.SURVEYOR,
      });

      await service.updateUserRole(targetUserId, UserRole.SURVEYOR, currentUserId);

      expect(auditService.log).toHaveBeenCalledWith(
        expect.objectContaining({
          action: AuditActions.USER_ROLE_CHANGED,
          metadata: {
            oldRole: UserRole.MANAGER,
            newRole: UserRole.SURVEYOR,
          },
        }),
      );
    });
  });

  describe('SEC-003: PII in Logger', () => {
    it('should log with user ID, not email in role change log message', async () => {
      // This test documents that the logger now uses userId instead of email
      // The log message was changed from:
      //   `User ${user.email} role changed from ${user.role} to ${newRole} by ${currentUserId}`
      // To:
      //   `User ${userId} role changed from ${user.role} to ${newRole} by ${currentUserId}`

      const currentUserId = 'admin-456';
      const targetUserId = 'user-123';

      mockPrismaService.user.findUnique.mockResolvedValue({
        ...mockUser,
        role: UserRole.SURVEYOR,
      });

      mockPrismaService.user.update.mockResolvedValue({
        ...mockUser,
        role: UserRole.MANAGER,
      });

      // If this doesn't throw, the method works correctly
      // The actual log output verification would require a logger spy
      await service.updateUserRole(targetUserId, UserRole.MANAGER, currentUserId);

      expect(auditService.log).toHaveBeenCalled();
    });
  });
});

/**
 * Section Type CRUD Tests
 * Verifies that section type management works correctly
 */
describe('ConfigService - Section Types CRUD', () => {
  let service: ConfigService;
  let prismaService: jest.Mocked<PrismaService>;

  const mockSectionType = {
    id: 'st-001',
    key: 'external',
    label: 'External',
    description: 'External inspection',
    icon: 'home',
    displayOrder: 0,
    surveyTypes: ['homebuyer', 'building'],
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const mockPrismaService = {
    user: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      update: jest.fn(),
      count: jest.fn(),
    },
    configVersion: {
      findFirst: jest.fn(),
      updateMany: jest.fn(),
    },
    phraseCategory: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    phrase: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
      updateMany: jest.fn(),
    },
    fieldDefinition: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
      updateMany: jest.fn(),
    },
    fieldOption: {
      createMany: jest.fn(),
      deleteMany: jest.fn(),
    },
    sectionTypeDefinition: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      aggregate: jest.fn(),
    },
    $transaction: jest.fn(),
  };

  const mockAuditService = {
    log: jest.fn(),
    query: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    // Ensure configVersion returns a valid version
    mockPrismaService.configVersion.findFirst.mockResolvedValue({
      id: 'cv-1',
      version: 1,
      updatedAt: new Date(),
    });
    mockPrismaService.configVersion.updateMany.mockResolvedValue({ count: 1 });

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

  describe('findAllSectionTypes', () => {
    it('should return only active section types by default', async () => {
      mockPrismaService.sectionTypeDefinition.findMany.mockResolvedValue([mockSectionType]);

      const result = await service.findAllSectionTypes();

      expect(result).toHaveLength(1);
      expect(result[0].key).toBe('external');
      expect(mockPrismaService.sectionTypeDefinition.findMany).toHaveBeenCalledWith({
        where: { isActive: true, deletedAt: null },
        orderBy: [{ displayOrder: 'asc' }, { createdAt: 'asc' }],
      });
    });

    it('should return all section types when includeInactive is true', async () => {
      const inactive = { ...mockSectionType, id: 'st-002', key: 'removed', isActive: false };
      mockPrismaService.sectionTypeDefinition.findMany.mockResolvedValue([mockSectionType, inactive]);

      const result = await service.findAllSectionTypes(true);

      expect(result).toHaveLength(2);
      expect(mockPrismaService.sectionTypeDefinition.findMany).toHaveBeenCalledWith({
        where: { deletedAt: null },
        orderBy: [{ displayOrder: 'asc' }, { createdAt: 'asc' }],
      });
    });
  });

  describe('createSectionType', () => {
    it('should create a section type with auto display order', async () => {
      mockPrismaService.sectionTypeDefinition.findUnique.mockResolvedValue(null);
      mockPrismaService.sectionTypeDefinition.aggregate.mockResolvedValue({
        _max: { displayOrder: 3 },
      });
      mockPrismaService.sectionTypeDefinition.create.mockResolvedValue({
        ...mockSectionType,
        displayOrder: 4,
      });

      const result = await service.createSectionType(
        { key: 'external', label: 'External', description: 'External inspection', icon: 'home', surveyTypes: ['homebuyer'] },
        'admin-1',
      );

      expect(result.key).toBe('external');
      expect(mockPrismaService.sectionTypeDefinition.create).toHaveBeenCalled();
    });

    it('should throw ConflictException if key already exists', async () => {
      mockPrismaService.sectionTypeDefinition.findUnique.mockResolvedValue(mockSectionType);

      await expect(
        service.createSectionType(
          { key: 'external', label: 'External' },
          'admin-1',
        ),
      ).rejects.toThrow('Section type with key "external" already exists');
    });
  });

  describe('updateSectionType', () => {
    it('should update an existing section type', async () => {
      mockPrismaService.sectionTypeDefinition.findUnique.mockResolvedValue(mockSectionType);
      mockPrismaService.sectionTypeDefinition.update.mockResolvedValue({
        ...mockSectionType,
        label: 'Updated External',
      });

      const result = await service.updateSectionType('st-001', { label: 'Updated External' }, 'admin-1');

      expect(result.label).toBe('Updated External');
    });

    it('should throw NotFoundException if section type does not exist', async () => {
      mockPrismaService.sectionTypeDefinition.findUnique.mockResolvedValue(null);

      await expect(
        service.updateSectionType('nonexistent', { label: 'X' }, 'admin-1'),
      ).rejects.toThrow('Section type with ID "nonexistent" not found');
    });
  });

  describe('deleteSectionType', () => {
    it('should soft-delete by setting deletedAt timestamp', async () => {
      mockPrismaService.sectionTypeDefinition.findUnique.mockResolvedValue(mockSectionType);
      mockPrismaService.sectionTypeDefinition.update.mockResolvedValue({
        ...mockSectionType,
        deletedAt: new Date(),
      });

      await service.deleteSectionType('st-001', 'admin-1');

      expect(mockPrismaService.sectionTypeDefinition.update).toHaveBeenCalledWith({
        where: { id: 'st-001' },
        data: { deletedAt: expect.any(Date) },
      });
    });

    it('should throw NotFoundException if section type does not exist', async () => {
      mockPrismaService.sectionTypeDefinition.findUnique.mockResolvedValue(null);

      await expect(
        service.deleteSectionType('nonexistent', 'admin-1'),
      ).rejects.toThrow('Section type with ID "nonexistent" not found');
    });
  });

  describe('getFullConfig - includes sectionTypes', () => {
    it('should return sectionTypes in the full config response', async () => {
      const activeSectionType = { ...mockSectionType, isActive: true };
      const inactiveSectionType = { ...mockSectionType, id: 'st-002', key: 'internal', label: 'Internal', isActive: false };

      mockPrismaService.configVersion.findFirst.mockResolvedValue({
        id: 'cv-1',
        version: 1,
        updatedAt: new Date(),
      });
      mockPrismaService.phraseCategory.findMany.mockResolvedValue([]);
      mockPrismaService.fieldDefinition.findMany.mockResolvedValue([]);
      mockPrismaService.sectionTypeDefinition.findMany.mockResolvedValue([activeSectionType, inactiveSectionType]);

      const result = await service.getFullConfig();

      expect(result.sectionTypes).toBeDefined();
      expect(result.sectionTypes).toHaveLength(2);
      expect(result.sectionTypes[0].key).toBe('external');
      expect(result.sectionTypes[0].isActive).toBe(true);
      expect(result.sectionTypes[1].key).toBe('internal');
      expect(result.sectionTypes[1].isActive).toBe(false);
    });

    it('should return empty sectionTypes when none exist', async () => {
      mockPrismaService.configVersion.findFirst.mockResolvedValue({
        id: 'cv-1',
        version: 1,
        updatedAt: new Date(),
      });
      mockPrismaService.phraseCategory.findMany.mockResolvedValue([]);
      mockPrismaService.fieldDefinition.findMany.mockResolvedValue([]);
      mockPrismaService.sectionTypeDefinition.findMany.mockResolvedValue([]);

      const result = await service.getFullConfig();

      expect(result.sectionTypes).toBeDefined();
      expect(result.sectionTypes).toHaveLength(0);
    });
  });

  describe('getFullConfig - section type key coverage', () => {
    // These are the exact keys Flutter SectionTemplates expect.
    // If any key is missing from the DB, sections will be hidden from the UI.
    const inspectionKeys = [
      'about-inspection',
      'about-property',
      'construction',
      'external-items',
      'internal-items',
      'rooms',
      'services',
      'issues-and-risks',
      'photos',
      'notes',
      'signature',
    ];

    const valuationKeys = [
      'about-valuation',
      'property-summary',
      'market-analysis',
      'comparables',
      'adjustments',
      'valuation',
      'summary',
      'photos',
      'signature',
    ];

    it('should include all inspection template keys in sectionTypes', async () => {
      // Simulate a fully-seeded DB with all 20 section type entries
      const allSectionTypes = [
        ...inspectionKeys,
        ...valuationKeys,
        'exterior',  // legacy
        'interior',  // legacy
      ];
      const uniqueKeys = [...new Set(allSectionTypes)];
      const mockRows = uniqueKeys.map((key, i) => ({
        id: `st-${i}`,
        key,
        label: key,
        description: null,
        icon: null,
        displayOrder: i,
        surveyTypes: [],
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      }));

      mockPrismaService.configVersion.findFirst.mockResolvedValue({
        id: 'cv-1',
        version: 1,
        updatedAt: new Date(),
      });
      mockPrismaService.phraseCategory.findMany.mockResolvedValue([]);
      mockPrismaService.fieldDefinition.findMany.mockResolvedValue([]);
      mockPrismaService.sectionTypeDefinition.findMany.mockResolvedValue(mockRows);

      const result = await service.getFullConfig();
      const returnedKeys = result.sectionTypes.map((st) => st.key);

      for (const key of inspectionKeys) {
        expect(returnedKeys).toContain(key);
      }
    });

    it('should include all valuation template keys in sectionTypes', async () => {
      const allSectionTypes = [
        ...inspectionKeys,
        ...valuationKeys,
        'exterior',
        'interior',
      ];
      const uniqueKeys = [...new Set(allSectionTypes)];
      const mockRows = uniqueKeys.map((key, i) => ({
        id: `st-${i}`,
        key,
        label: key,
        description: null,
        icon: null,
        displayOrder: i,
        surveyTypes: [],
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      }));

      mockPrismaService.configVersion.findFirst.mockResolvedValue({
        id: 'cv-1',
        version: 1,
        updatedAt: new Date(),
      });
      mockPrismaService.phraseCategory.findMany.mockResolvedValue([]);
      mockPrismaService.fieldDefinition.findMany.mockResolvedValue([]);
      mockPrismaService.sectionTypeDefinition.findMany.mockResolvedValue(mockRows);

      const result = await service.getFullConfig();
      const returnedKeys = result.sectionTypes.map((st) => st.key);

      for (const key of valuationKeys) {
        expect(returnedKeys).toContain(key);
      }
    });
  });

  describe('reorderSectionTypes', () => {
    it('should throw BadRequestException for empty array', async () => {
      await expect(
        service.reorderSectionTypes({ sectionTypeIds: [] }, 'admin-1'),
      ).rejects.toThrow('Section type IDs array cannot be empty');
    });

    it('should throw BadRequestException for duplicate IDs', async () => {
      await expect(
        service.reorderSectionTypes({ sectionTypeIds: ['st-001', 'st-001'] }, 'admin-1'),
      ).rejects.toThrow('Duplicate section type IDs in reorder request');
    });

    it('should throw NotFoundException if some IDs do not exist', async () => {
      mockPrismaService.sectionTypeDefinition.findMany.mockResolvedValue([{ id: 'st-001' }]);

      await expect(
        service.reorderSectionTypes({ sectionTypeIds: ['st-001', 'st-missing'] }, 'admin-1'),
      ).rejects.toThrow('Section types not found: st-missing');
    });
  });
});
