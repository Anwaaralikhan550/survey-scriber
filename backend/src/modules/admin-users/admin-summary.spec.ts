import { Test } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { UserRole } from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { AuthService } from '../auth/auth.service';
import { PrismaService } from '../prisma/prisma.service';
import { AdminUsersService } from './admin-users.service';

describe('AdminUsersService.summary', () => {
  const prisma = {
    user: { groupBy: jest.fn(), findMany: jest.fn() },
    survey: { groupBy: jest.fn() },
    booking: { groupBy: jest.fn() },
    configVersion: { findFirst: jest.fn() },
    auditLog: { findMany: jest.fn() },
  };
  let service: AdminUsersService;

  beforeEach(async () => {
    jest.clearAllMocks();
    prisma.user.groupBy.mockResolvedValue([
      { role: UserRole.ADMIN, isActive: true, _count: { _all: 1 } },
      { role: UserRole.SURVEYOR, isActive: true, _count: { _all: 4 } },
      { role: UserRole.SURVEYOR, isActive: false, _count: { _all: 2 } },
    ]);
    prisma.survey.groupBy.mockResolvedValue([{ status: 'DRAFT', _count: { _all: 3 } }]);
    prisma.booking.groupBy.mockResolvedValue([{ status: 'PENDING', _count: { _all: 5 } }]);
    prisma.configVersion.findFirst.mockResolvedValue({ version: 7 });
    prisma.auditLog.findMany.mockResolvedValue([
      { action: 'user.created', actorId: 'a1', createdAt: new Date('2026-11-04') },
      { action: 'user.created', actorId: null, createdAt: new Date('2026-11-03') },
    ]);
    prisma.user.findMany.mockResolvedValue([{ id: 'a1', email: 'a@example.com' }]);
    const module = await Test.createTestingModule({
      providers: [
        AdminUsersService,
        { provide: PrismaService, useValue: prisma },
        { provide: AuthService, useValue: {} },
        { provide: AuditService, useValue: {} },
        { provide: ConfigService, useValue: { get: () => 4 } },
      ],
    }).compile();
    service = module.get(AdminUsersService);
  });

  it('counts users by role, active only per role, with totals', async () => {
    const result = await service.summary({ id: 'a1', role: UserRole.ADMIN });
    expect(result.users).toEqual({
      total: 7,
      active: 5,
      inactive: 2,
      administrators: 1,
      subAdmins: 0,
      fieldUsers: 6,
      viewers: 0,
    });
  });

  it('every status is present, zero when there are none', async () => {
    const result = await service.summary({ id: 'a1', role: UserRole.ADMIN });
    expect(result.surveys).toEqual({
      DRAFT: 3,
      IN_PROGRESS: 0,
      PAUSED: 0,
      COMPLETED: 0,
      PENDING_REVIEW: 0,
      APPROVED: 0,
      REJECTED: 0,
    });
    expect(result.bookings).toEqual({ PENDING: 5, CONFIRMED: 0, CANCELLED: 0, COMPLETED: 0 });
  });

  it('deleted surveys are not counted', async () => {
    await service.summary({ id: 'a1', role: UserRole.ADMIN });
    expect(prisma.survey.groupBy.mock.calls[0][0].where).toEqual({ deletedAt: null });
  });

  it('activity names who did it, for an administrator', async () => {
    const result = await service.summary({ id: 'a1', role: UserRole.ADMIN });
    expect(result.recentActivity).toEqual([
      { action: 'user.created', actor: 'a@example.com', at: new Date('2026-11-04') },
      { action: 'user.created', actor: null, at: new Date('2026-11-03') },
    ]);
    expect(result.configVersion).toBe(7);
  });

  it('a sub admin gets the counts but not the audit activity', async () => {
    const result = await service.summary({ id: 's1', role: UserRole.MANAGER });
    expect(result.recentActivity).toEqual([]);
    expect(prisma.auditLog.findMany).not.toHaveBeenCalled();
  });

  it('an empty database gives zeros, not errors', async () => {
    prisma.user.groupBy.mockResolvedValue([]);
    prisma.survey.groupBy.mockResolvedValue([]);
    prisma.booking.groupBy.mockResolvedValue([]);
    prisma.configVersion.findFirst.mockResolvedValue(null);
    prisma.auditLog.findMany.mockResolvedValue([]);
    const result = await service.summary({ id: 'a1', role: UserRole.ADMIN });
    expect(result.users.total).toBe(0);
    expect(result.surveys.DRAFT).toBe(0);
    expect(result.configVersion).toBe(0);
  });
});
