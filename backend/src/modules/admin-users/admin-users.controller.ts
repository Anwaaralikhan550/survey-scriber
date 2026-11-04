import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { User, UserRole } from '@prisma/client';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { AdminUsersService } from './admin-users.service';
import {
  AdminUserResponseDto,
  AdminUsersListDto,
  AdminUsersQueryDto,
  CreateAdminUserDto,
  UpdateAdminUserDto,
} from './dto/admin-user.dto';

type Actor = Omit<User, 'passwordHash'>;

@ApiTags('Admin Users')
@Controller('admin/users')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN, UserRole.MANAGER)
@ApiBearerAuth('JWT-auth')
export class AdminUsersController {
  constructor(private readonly users: AdminUsersService) {}

  @Get()
  @ApiOperation({ summary: 'List users. A sub admin sees field users only.' })
  @ApiResponse({ status: 200, type: AdminUsersListDto })
  list(@Query() query: AdminUsersQueryDto, @CurrentUser() actor: Actor): Promise<AdminUsersListDto> {
    return this.users.list(query, actor);
  }

  @Post()
  @ApiOperation({ summary: 'Add a user. Without a password they get an email to set their own.' })
  @ApiResponse({ status: 201, type: AdminUserResponseDto })
  @ApiResponse({ status: 409, description: 'Email already in use' })
  create(@Body() dto: CreateAdminUserDto, @CurrentUser() actor: Actor): Promise<AdminUserResponseDto> {
    return this.users.create(dto, actor);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Edit name, phone or role' })
  @ApiResponse({ status: 200, type: AdminUserResponseDto })
  update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateAdminUserDto,
    @CurrentUser() actor: Actor,
  ): Promise<AdminUserResponseDto> {
    return this.users.update(id, dto, actor);
  }

  @Post(':id/deactivate')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Stop the account signing in; ends its sessions at once' })
  @ApiResponse({ status: 200, type: AdminUserResponseDto })
  deactivate(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() actor: Actor): Promise<AdminUserResponseDto> {
    return this.users.setActive(id, false, actor);
  }

  @Post(':id/activate')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Let a deactivated account sign in again' })
  @ApiResponse({ status: 200, type: AdminUserResponseDto })
  activate(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() actor: Actor): Promise<AdminUserResponseDto> {
    return this.users.setActive(id, true, actor);
  }

  @Post(':id/send-password-email')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Email the user a link to set a new password' })
  @ApiResponse({ status: 200, type: AdminUserResponseDto })
  sendPasswordEmail(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() actor: Actor): Promise<AdminUserResponseDto> {
    return this.users.sendPasswordEmail(id, actor);
  }
}
