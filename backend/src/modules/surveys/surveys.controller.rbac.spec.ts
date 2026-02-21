import { Test, TestingModule } from '@nestjs/testing';
import { ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UserRole } from '@prisma/client';
import { SurveysController } from './surveys.controller';
import { SurveysService } from './surveys.service';
import { NotificationEmailService } from '../notifications/notification-email.service';
import { RolesGuard } from '../auth/guards/roles.guard';
import { ROLES_KEY } from '../auth/decorators/roles.decorator';

/**
 * RBAC Tests: SurveysController
 *
 * Verifies that role-based access control is correctly configured.
 * These tests ensure:
 * - ADMIN has full access
 * - MANAGER has full access (H3 fix)
 * - SURVEYOR has full access
 * - VIEWER has read-only access (H4 fix)
 *
 * @see H3/H4 issues - Missing MANAGER and VIEWER roles
 */
describe('SurveysController RBAC', () => {
  let reflector: Reflector;

  beforeAll(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [SurveysController],
      providers: [
        {
          provide: SurveysService,
          useValue: {},
        },
        {
          provide: NotificationEmailService,
          useValue: {},
        },
        Reflector,
      ],
    }).compile();

    reflector = module.get<Reflector>(Reflector);
  });

  /**
   * Helper to get roles from controller method
   */
  function getRolesForMethod(methodName: keyof SurveysController): UserRole[] {
    const method = SurveysController.prototype[methodName] as (...args: unknown[]) => unknown;
    return Reflect.getMetadata(ROLES_KEY, method) || [];
  }

  describe('Read operations (should include VIEWER)', () => {
    it('GET /surveys should allow ADMIN, MANAGER, SURVEYOR, VIEWER', () => {
      const roles = getRolesForMethod('findAll');

      expect(roles).toContain(UserRole.ADMIN);
      expect(roles).toContain(UserRole.MANAGER);
      expect(roles).toContain(UserRole.SURVEYOR);
      expect(roles).toContain(UserRole.VIEWER);
    });

    it('GET /surveys/:id should allow ADMIN, MANAGER, SURVEYOR, VIEWER', () => {
      const roles = getRolesForMethod('findOne');

      expect(roles).toContain(UserRole.ADMIN);
      expect(roles).toContain(UserRole.MANAGER);
      expect(roles).toContain(UserRole.SURVEYOR);
      expect(roles).toContain(UserRole.VIEWER);
    });
  });

  describe('Write operations (should NOT include VIEWER)', () => {
    it('POST /surveys should allow ADMIN, MANAGER, SURVEYOR but NOT VIEWER', () => {
      const roles = getRolesForMethod('create');

      expect(roles).toContain(UserRole.ADMIN);
      expect(roles).toContain(UserRole.MANAGER);
      expect(roles).toContain(UserRole.SURVEYOR);
      expect(roles).not.toContain(UserRole.VIEWER);
    });

    it('PUT /surveys/:id should allow ADMIN, MANAGER, SURVEYOR but NOT VIEWER', () => {
      const roles = getRolesForMethod('update');

      expect(roles).toContain(UserRole.ADMIN);
      expect(roles).toContain(UserRole.MANAGER);
      expect(roles).toContain(UserRole.SURVEYOR);
      expect(roles).not.toContain(UserRole.VIEWER);
    });

    it('DELETE /surveys/:id should allow ADMIN, MANAGER, SURVEYOR but NOT VIEWER', () => {
      const roles = getRolesForMethod('remove');

      expect(roles).toContain(UserRole.ADMIN);
      expect(roles).toContain(UserRole.MANAGER);
      expect(roles).toContain(UserRole.SURVEYOR);
      expect(roles).not.toContain(UserRole.VIEWER);
    });

    it('POST /surveys/:id/report-pdf should allow ADMIN, MANAGER, SURVEYOR but NOT VIEWER', () => {
      const roles = getRolesForMethod('uploadReportPdf');

      expect(roles).toContain(UserRole.ADMIN);
      expect(roles).toContain(UserRole.MANAGER);
      expect(roles).toContain(UserRole.SURVEYOR);
      expect(roles).not.toContain(UserRole.VIEWER);
    });

    it('POST /surveys/:id/send-report should allow ADMIN, MANAGER, SURVEYOR but NOT VIEWER', () => {
      const roles = getRolesForMethod('sendReport');

      expect(roles).toContain(UserRole.ADMIN);
      expect(roles).toContain(UserRole.MANAGER);
      expect(roles).toContain(UserRole.SURVEYOR);
      expect(roles).not.toContain(UserRole.VIEWER);
    });
  });

  describe('MANAGER role access (H3 fix verification)', () => {
    it('MANAGER should have access to all survey endpoints', () => {
      const endpoints: (keyof SurveysController)[] = ['findAll', 'findOne', 'create', 'update', 'remove', 'uploadReportPdf', 'sendReport'];

      for (const method of endpoints) {
        const roles = getRolesForMethod(method);
        expect(roles).toContain(UserRole.MANAGER);
      }
    });
  });

  describe('VIEWER role access (H4 fix verification)', () => {
    it('VIEWER should have access to read-only endpoints', () => {
      const readMethods: (keyof SurveysController)[] = ['findAll', 'findOne'];

      for (const method of readMethods) {
        const roles = getRolesForMethod(method);
        expect(roles).toContain(UserRole.VIEWER);
      }
    });

    it('VIEWER should NOT have access to write endpoints', () => {
      const writeMethods: (keyof SurveysController)[] = ['create', 'update', 'remove', 'uploadReportPdf', 'sendReport'];

      for (const method of writeMethods) {
        const roles = getRolesForMethod(method);
        expect(roles).not.toContain(UserRole.VIEWER);
      }
    });
  });
});
