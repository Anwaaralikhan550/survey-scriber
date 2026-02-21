import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { User } from '@prisma/client';

/**
 * Decorator to extract the current authenticated user from the request.
 * Must be used with JwtAuthGuard.
 *
 * @example
 * @Get('profile')
 * @UseGuards(JwtAuthGuard)
 * getProfile(@CurrentUser() user: User) {
 *   return user;
 * }
 */
export const CurrentUser = createParamDecorator(
  (data: keyof User | undefined, ctx: ExecutionContext): User | unknown => {
    const request = ctx.switchToHttp().getRequest();
    const user = request.user as User;

    // If a specific property is requested, return only that property
    if (data) {
      return user?.[data];
    }

    return user;
  },
);
