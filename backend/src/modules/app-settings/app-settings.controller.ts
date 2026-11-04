import { Body, Controller, Get, Put, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiProperty, ApiTags } from '@nestjs/swagger';
import { User, UserRole } from '@prisma/client';
import { IsObject } from 'class-validator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { AppSettingsService } from './app-settings.service';

export class UpdateAppSettingsDto {
  @ApiProperty({ description: 'Setting name -> value. An empty value goes back to the server default.' })
  @IsObject()
  values!: Record<string, unknown>;
}

@ApiTags('Admin - Settings')
@ApiBearerAuth('JWT-auth')
@Controller('admin/settings')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class AppSettingsController {
  constructor(private readonly settings: AppSettingsService) {}

  @Get()
  @ApiOperation({ summary: 'The settings an admin can change. Never includes passwords or keys.' })
  list() {
    return this.settings.list();
  }

  @Put()
  @ApiOperation({ summary: 'Change settings. Takes effect without a restart.' })
  update(@Body() dto: UpdateAppSettingsDto, @CurrentUser() user: Omit<User, 'passwordHash'>) {
    return this.settings.update(dto.values, user);
  }
}
