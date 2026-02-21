import { SetMetadata } from '@nestjs/common';
import { UserRole } from '@prisma/client';

export const ROLES_KEY = 'roles';

/**
 * Decorator to specify which roles are allowed to access a route.
 * Must be used with RolesGuard.
 *
 * @example
 * @Roles(UserRole.ADMIN, UserRole.MANAGER)
 * @UseGuards(JwtAuthGuard, RolesGuard)
 * @Get('admin-only')
 * adminOnly() {
 *   return { message: 'Admin access granted' };
 * }
 */
export const Roles = (...roles: UserRole[]) => SetMetadata(ROLES_KEY, roles);
