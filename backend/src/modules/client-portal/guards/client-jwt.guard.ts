import { Injectable, ExecutionContext } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

/**
 * Guard that uses the 'client-jwt' strategy.
 * Use this guard on all client portal endpoints.
 */
@Injectable()
export class ClientJwtGuard extends AuthGuard('client-jwt') {
  /**
   * Can be extended to add additional checks if needed.
   */
  canActivate(context: ExecutionContext) {
    return super.canActivate(context);
  }
}
