import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ActorType, AuditEntityType, BookingStatus, Prisma, SurveyStatus, User, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';
import { AuditActions, AuditService } from '../audit/audit.service';
import { AuthService } from '../auth/auth.service';
import { PrismaService } from '../prisma/prisma.service';
import {
  AdminSummaryDto,
  AdminUserResponseDto,
  AdminUsersListDto,
  AdminUsersQueryDto,
  CreateAdminUserDto,
  UpdateAdminUserDto,
} from './dto/admin-user.dto';

const FIELD_ROLES: UserRole[] = [UserRole.SURVEYOR, UserRole.VIEWER];
const STAFF_ROLES: UserRole[] = [UserRole.ADMIN, UserRole.MANAGER];

/** The signed-in administrator or sub admin. */
type Actor = Pick<User, 'id' | 'role'>;

/**
 * Accounts as the web admin manages them. An administrator manages everyone; a
 * sub admin (MANAGER) manages field users only. Users are deactivated, never
 * deleted: deleting a user would delete their surveys with them.
 */
@Injectable()
export class AdminUsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auth: AuthService,
    private readonly audit: AuditService,
    private readonly config: ConfigService,
  ) {}

  private canManage(actor: Actor, role: UserRole): boolean {
    return actor.role === UserRole.ADMIN || FIELD_ROLES.includes(role);
  }

  private toResponse(user: User, emailSent?: boolean): AdminUserResponseDto {
    return {
      id: user.id,
      email: user.email,
      firstName: user.firstName ?? undefined,
      lastName: user.lastName ?? undefined,
      phone: user.phone ?? undefined,
      role: user.role,
      isActive: user.isActive,
      lastLoginAt: user.lastLoginAt ?? undefined,
      createdAt: user.createdAt,
      ...(emailSent === undefined ? {} : { emailSent }),
    };
  }

  private async record(actor: Actor, action: string, userId: string, metadata?: Record<string, unknown>) {
    await this.audit.log({
      actorType: ActorType.STAFF,
      actorId: actor.id,
      action,
      entityType: AuditEntityType.AUTH,
      entityId: userId,
      metadata,
    });
  }

  private async findManaged(id: string, actor: Actor): Promise<User> {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundException('User not found');
    if (!this.canManage(actor, user.role)) {
      throw new ForbiddenException('Sub admins can only manage field users');
    }
    return user;
  }

  /** An administrator cannot be taken away if no other active one would be left. */
  private async assertAnotherAdmin(user: User, message: string): Promise<void> {
    if (user.role !== UserRole.ADMIN || !user.isActive) return;
    const others = await this.prisma.user.count({
      where: { role: UserRole.ADMIN, isActive: true, id: { not: user.id } },
    });
    if (others === 0) throw new ForbiddenException(message);
  }

  /** The Dashboard's numbers. The audit trail stays with administrators. */
  async summary(actor: Actor): Promise<AdminSummaryDto> {
    const [users, surveys, bookings, config] = await Promise.all([
      this.prisma.user.groupBy({ by: ['role', 'isActive'], _count: { _all: true } }),
      this.prisma.survey.groupBy({ by: ['status'], where: { deletedAt: null }, _count: { _all: true } }),
      this.prisma.booking.groupBy({ by: ['status'], _count: { _all: true } }),
      this.prisma.configVersion.findFirst(),
    ]);

    const inRole = (role: UserRole) =>
      users.filter((u) => u.role === role).reduce((n, u) => n + u._count._all, 0);
    const active = users.filter((u) => u.isActive).reduce((n, u) => n + u._count._all, 0);
    const total = users.reduce((n, u) => n + u._count._all, 0);

    const byStatus = <T extends string>(all: T[], rows: { status: T; _count: { _all: number } }[]) =>
      Object.fromEntries(
        all.map((status) => [status, rows.find((r) => r.status === status)?._count._all ?? 0]),
      ) as Record<T, number>;

    let recentActivity: AdminSummaryDto['recentActivity'] = [];
    if (actor.role === UserRole.ADMIN) {
      const logs = await this.prisma.auditLog.findMany({
        where: { actorType: ActorType.STAFF, action: { startsWith: 'user.' } },
        orderBy: { createdAt: 'desc' },
        take: 10,
      });
      const ids = [...new Set(logs.map((l) => l.actorId).filter((id): id is string => !!id))];
      const actors = ids.length
        ? await this.prisma.user.findMany({ where: { id: { in: ids } }, select: { id: true, email: true } })
        : [];
      recentActivity = logs.map((l) => ({
        action: l.action,
        actor: actors.find((a) => a.id === l.actorId)?.email ?? null,
        at: l.createdAt,
      }));
    }

    return {
      users: {
        total,
        active,
        inactive: total - active,
        administrators: inRole(UserRole.ADMIN),
        subAdmins: inRole(UserRole.MANAGER),
        fieldUsers: inRole(UserRole.SURVEYOR),
        viewers: inRole(UserRole.VIEWER),
      },
      surveys: byStatus(Object.values(SurveyStatus), surveys),
      bookings: byStatus(Object.values(BookingStatus), bookings),
      configVersion: config?.version ?? 0,
      recentActivity,
    };
  }

  async list(query: AdminUsersQueryDto, actor: Actor): Promise<AdminUsersListDto> {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;

    let roles: UserRole[] | undefined;
    if (actor.role !== UserRole.ADMIN || query.group === 'field') roles = FIELD_ROLES;
    else if (query.group === 'staff') roles = STAFF_ROLES;

    const where: Prisma.UserWhereInput = {
      ...(roles ? { role: { in: roles } } : {}),
      ...(query.isActive === undefined ? {} : { isActive: query.isActive }),
    };
    const q = query.q?.trim();
    if (q) {
      where.OR = [
        { email: { contains: q, mode: 'insensitive' } },
        { firstName: { contains: q, mode: 'insensitive' } },
        { lastName: { contains: q, mode: 'insensitive' } },
        { phone: { contains: q, mode: 'insensitive' } },
      ];
    }

    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        orderBy: [{ firstName: 'asc' }, { email: 'asc' }],
        skip: (page - 1) * limit,
        take: limit,
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      data: users.map((u) => this.toResponse(u)),
      meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }

  async create(dto: CreateAdminUserDto, actor: Actor): Promise<AdminUserResponseDto> {
    if (!this.canManage(actor, dto.role)) {
      throw new ForbiddenException('Sub admins can only add field users');
    }
    const email = dto.email.toLowerCase();
    if (await this.prisma.user.findUnique({ where: { email } })) {
      throw new ConflictException('A user with this email already exists');
    }

    // With no password given, nobody knows this one: the user sets their own by email.
    const secret = dto.password ?? crypto.randomBytes(32).toString('hex') + 'aA1!';
    const rounds = this.config.get<number>('BCRYPT_SALT_ROUNDS') || 12;
    let user: User;
    try {
      user = await this.prisma.user.create({
        data: {
          email,
          passwordHash: await bcrypt.hash(secret, rounds),
          firstName: dto.firstName.trim(),
          lastName: dto.lastName?.trim() || null,
          phone: dto.phone?.trim() || null,
          role: dto.role,
          emailVerified: true,
        },
      });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
        throw new ConflictException('A user with this email already exists');
      }
      throw error;
    }
    await this.record(actor, AuditActions.USER_CREATED, user.id, { role: user.role });

    const emailSent = dto.password ? undefined : await this.auth.sendAccountInvite(user);
    return this.toResponse(user, emailSent);
  }

  async update(id: string, dto: UpdateAdminUserDto, actor: Actor): Promise<AdminUserResponseDto> {
    const user = await this.findManaged(id, actor);

    if (dto.role !== undefined && dto.role !== user.role) {
      if (actor.role !== UserRole.ADMIN) {
        throw new ForbiddenException('Only an administrator can change a role');
      }
      if (user.id === actor.id) {
        throw new ForbiddenException('You cannot change your own role');
      }
      await this.assertAnotherAdmin(user, 'This is the last administrator. Make another administrator first.');
    }

    const updated = await this.prisma.user.update({
      where: { id },
      data: {
        firstName: dto.firstName?.trim(),
        lastName: dto.lastName === undefined ? undefined : dto.lastName?.trim() || null,
        phone: dto.phone === undefined ? undefined : dto.phone?.trim() || null,
        role: dto.role,
      },
    });

    if (updated.role !== user.role) {
      await this.record(actor, AuditActions.USER_ROLE_CHANGED, id, { oldRole: user.role, newRole: updated.role });
    }
    await this.record(actor, AuditActions.USER_UPDATED, id);
    return this.toResponse(updated);
  }

  async setActive(id: string, isActive: boolean, actor: Actor): Promise<AdminUserResponseDto> {
    const user = await this.findManaged(id, actor);
    if (!isActive) {
      if (user.id === actor.id) {
        throw new ForbiddenException('You cannot deactivate your own account');
      }
      await this.assertAnotherAdmin(user, 'This is the last administrator. Make another administrator first.');
    }

    const updated = await this.prisma.user.update({ where: { id }, data: { isActive } });
    if (!isActive) await this.auth.revokeAllUserTokens(id);
    await this.record(actor, isActive ? AuditActions.USER_ACTIVATED : AuditActions.USER_DEACTIVATED, id);
    return this.toResponse(updated);
  }

  async sendPasswordEmail(id: string, actor: Actor): Promise<AdminUserResponseDto> {
    const user = await this.findManaged(id, actor);
    if (!user.isActive) {
      throw new BadRequestException('This account is deactivated. Activate it first.');
    }
    const emailSent = await this.auth.sendAdminPasswordReset(user);
    await this.record(actor, AuditActions.USER_PASSWORD_EMAIL_SENT, id, { emailSent });
    return this.toResponse(user, emailSent);
  }
}
