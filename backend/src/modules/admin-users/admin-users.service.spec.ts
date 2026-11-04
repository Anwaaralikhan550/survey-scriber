import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { UserRole } from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { AuthService } from '../auth/auth.service';
import { PrismaService } from '../prisma/prisma.service';
import { AdminUsersService } from './admin-users.service';

describe('AdminUsersService', () => {
  let service: AdminUsersService;
  const admin = { id: 'admin-1', role: UserRole.ADMIN };
  const sub = { id: 'sub-1', role: UserRole.MANAGER };

  const prisma = {
    user: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      count: jest.fn(),
    },
  };
  const auth = {
    sendAccountInvite: jest.fn(async () => true),
    sendAdminPasswordReset: jest.fn(async () => true),
    revokeAllUserTokens: jest.fn(),
  };
  const audit = { log: jest.fn() };

  const user = (over: Record<string, unknown> = {}) => ({
    id: 'u1',
    email: 'u@example.com',
    passwordHash: 'secret-hash',
    firstName: 'Jane',
    lastName: null,
    phone: null,
    role: UserRole.SURVEYOR,
    isActive: true,
    lastLoginAt: null,
    createdAt: new Date(),
    ...over,
  });

  beforeEach(async () => {
    jest.clearAllMocks();
    prisma.user.findMany.mockResolvedValue([]);
    prisma.user.count.mockResolvedValue(0);
    prisma.user.create.mockImplementation(async ({ data }: any) => user({ ...data, id: 'new' }));
    prisma.user.update.mockImplementation(async ({ where, data }: any) => ({
      ...user({ id: where.id }),
      ...Object.fromEntries(Object.entries(data).filter(([, v]) => v !== undefined)),
    }));
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AdminUsersService,
        { provide: PrismaService, useValue: prisma },
        { provide: AuthService, useValue: auth },
        { provide: AuditService, useValue: audit },
        { provide: ConfigService, useValue: { get: () => 4 } },
      ],
    }).compile();
    service = module.get(AdminUsersService);
  });

  describe('list', () => {
    it('a sub admin sees field users only, whatever they ask for', async () => {
      await service.list({ group: 'staff' }, sub);
      expect(prisma.user.findMany.mock.calls[0][0].where.role).toEqual({
        in: [UserRole.SURVEYOR, UserRole.VIEWER],
      });
    });

    it('an administrator can list staff and field users', async () => {
      await service.list({ group: 'staff' }, admin);
      expect(prisma.user.findMany.mock.calls[0][0].where.role).toEqual({
        in: [UserRole.ADMIN, UserRole.MANAGER],
      });
      await service.list({ group: 'field' }, admin);
      expect(prisma.user.findMany.mock.calls[1][0].where.role).toEqual({
        in: [UserRole.SURVEYOR, UserRole.VIEWER],
      });
    });

    it('pages and never returns the password hash', async () => {
      prisma.user.findMany.mockResolvedValue([user()]);
      prisma.user.count.mockResolvedValue(57);
      const result = await service.list({ page: 3, limit: 20 }, admin);
      expect(prisma.user.findMany.mock.calls[0][0]).toMatchObject({ skip: 40, take: 20 });
      expect(result.meta).toEqual({ page: 3, limit: 20, total: 57, totalPages: 3 });
      expect(JSON.stringify(result)).not.toContain('secret-hash');
    });

    it('searches name, email and phone', async () => {
      await service.list({ q: ' ann ' }, admin);
      const { OR } = prisma.user.findMany.mock.calls[0][0].where;
      expect(OR).toHaveLength(4);
      expect(OR[0].email.contains).toBe('ann');
    });
  });

  describe('create', () => {
    const dto = { email: 'New@Example.com', firstName: ' Jane ', role: UserRole.SURVEYOR };

    it('without a password the user gets an invite and a password nobody knows', async () => {
      prisma.user.findUnique.mockResolvedValue(null);
      const result = await service.create(dto as any, admin);
      expect(auth.sendAccountInvite).toHaveBeenCalledTimes(1);
      expect(result.emailSent).toBe(true);
      const { data } = prisma.user.create.mock.calls[0][0];
      expect(data.email).toBe('new@example.com');
      expect(data.firstName).toBe('Jane');
      expect(data.passwordHash).toMatch(/^\$2/);
    });

    it('with a password no invite goes out', async () => {
      prisma.user.findUnique.mockResolvedValue(null);
      const result = await service.create({ ...dto, password: 'Abcdef1!' } as any, admin);
      expect(auth.sendAccountInvite).not.toHaveBeenCalled();
      expect(result.emailSent).toBeUndefined();
    });

    it('a duplicate email is refused', async () => {
      prisma.user.findUnique.mockResolvedValue(user());
      await expect(service.create(dto as any, admin)).rejects.toThrow('already exists');
    });

    it.each([UserRole.ADMIN, UserRole.MANAGER])('a sub admin cannot add a %s', async (role) => {
      await expect(service.create({ ...dto, role } as any, sub)).rejects.toThrow('field users');
      expect(prisma.user.create).not.toHaveBeenCalled();
    });

    it('is audited without personal details', async () => {
      prisma.user.findUnique.mockResolvedValue(null);
      await service.create(dto as any, admin);
      expect(audit.log.mock.calls[0][0]).toMatchObject({
        actorId: 'admin-1',
        action: 'user.created',
        metadata: { role: UserRole.SURVEYOR },
      });
    });
  });

  describe('update', () => {
    it('saves and can empty a field', async () => {
      prisma.user.findUnique.mockResolvedValue(user({ phone: '123' }));
      await service.update('u1', { firstName: 'New', phone: null } as any, admin);
      expect(prisma.user.update.mock.calls[0][0].data).toMatchObject({ firstName: 'New', phone: null });
    });

    it('a sub admin cannot touch staff', async () => {
      prisma.user.findUnique.mockResolvedValue(user({ role: UserRole.MANAGER }));
      await expect(service.update('u1', { firstName: 'X' } as any, sub)).rejects.toThrow('field users');
    });

    it('a sub admin cannot change a role', async () => {
      prisma.user.findUnique.mockResolvedValue(user());
      await expect(
        service.update('u1', { role: UserRole.VIEWER } as any, sub),
      ).rejects.toThrow('Only an administrator');
    });

    it('nobody changes their own role', async () => {
      prisma.user.findUnique.mockResolvedValue(user({ id: 'admin-1', role: UserRole.ADMIN }));
      await expect(
        service.update('admin-1', { role: UserRole.MANAGER } as any, admin),
      ).rejects.toThrow('your own role');
    });

    it('the last administrator keeps the role', async () => {
      prisma.user.findUnique.mockResolvedValue(user({ role: UserRole.ADMIN }));
      prisma.user.count.mockResolvedValue(0);
      await expect(
        service.update('u1', { role: UserRole.MANAGER } as any, admin),
      ).rejects.toThrow('last administrator');
    });

    it('a role change is audited with both roles', async () => {
      prisma.user.findUnique.mockResolvedValue(user());
      await service.update('u1', { role: UserRole.MANAGER } as any, admin);
      expect(audit.log.mock.calls[0][0]).toMatchObject({
        action: 'user.role_changed',
        metadata: { oldRole: UserRole.SURVEYOR, newRole: UserRole.MANAGER },
      });
    });
  });

  describe('deactivate and activate', () => {
    it('deactivating ends the sessions', async () => {
      prisma.user.findUnique.mockResolvedValue(user());
      const result = await service.setActive('u1', false, sub);
      expect(result.isActive).toBe(false);
      expect(auth.revokeAllUserTokens).toHaveBeenCalledWith('u1');
      expect(audit.log.mock.calls[0][0].action).toBe('user.deactivated');
    });

    it('activating needs no session work', async () => {
      prisma.user.findUnique.mockResolvedValue(user({ isActive: false }));
      const result = await service.setActive('u1', true, admin);
      expect(result.isActive).toBe(true);
      expect(auth.revokeAllUserTokens).not.toHaveBeenCalled();
    });

    it('nobody deactivates themselves', async () => {
      prisma.user.findUnique.mockResolvedValue(user({ id: 'admin-1', role: UserRole.ADMIN }));
      await expect(service.setActive('admin-1', false, admin)).rejects.toThrow('your own account');
    });

    it('the last active administrator stays', async () => {
      prisma.user.findUnique.mockResolvedValue(user({ role: UserRole.ADMIN }));
      prisma.user.count.mockResolvedValue(0);
      await expect(service.setActive('u1', false, admin)).rejects.toThrow('last administrator');
    });

    it('a sub admin cannot deactivate staff', async () => {
      prisma.user.findUnique.mockResolvedValue(user({ role: UserRole.ADMIN }));
      await expect(service.setActive('u1', false, sub)).rejects.toThrow('field users');
    });

    it('an unknown user is not found', async () => {
      prisma.user.findUnique.mockResolvedValue(null);
      await expect(service.setActive('nope', false, admin)).rejects.toThrow('User not found');
    });
  });

  describe('password email', () => {
    it('goes out and is audited', async () => {
      prisma.user.findUnique.mockResolvedValue(user());
      const result = await service.sendPasswordEmail('u1', admin);
      expect(result.emailSent).toBe(true);
      expect(audit.log.mock.calls[0][0].action).toBe('user.password_email_sent');
    });

    it('a deactivated account must be activated first', async () => {
      prisma.user.findUnique.mockResolvedValue(user({ isActive: false }));
      await expect(service.sendPasswordEmail('u1', admin)).rejects.toThrow('deactivated');
      expect(auth.sendAdminPasswordReset).not.toHaveBeenCalled();
    });
  });
});
