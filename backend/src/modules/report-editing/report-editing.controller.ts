import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, ParseIntPipe, ParseUUIDPipe, Post, Put, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { Request } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { ReportEditingService, Owner } from './report-editing.service';
import { RestoreVersionDto, UploadSnapshotDto } from './dto/editing.dto';

/** App (owner) endpoints, spec section 16. {id} is the report id, which is the survey id. */
@ApiTags('Report editing')
@ApiBearerAuth('JWT-auth')
@Controller('reports')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN, UserRole.MANAGER, UserRole.SURVEYOR)
export class ReportEditingController {
  constructor(private readonly service: ReportEditingService) {}

  @Put(':id/snapshot')
  uploadSnapshot(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string, @Body() dto: UploadSnapshotDto, @Req() req: Request) {
    return this.service.uploadSnapshot(user, id, dto, req);
  }

  @Post(':id/edit-links')
  createLink(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string, @Req() req: Request) {
    return this.service.createLink(user, id, req);
  }

  @Get(':id/edit-links/current')
  currentLink(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.currentLink(user, id);
  }

  @Delete(':id/edit-links/:linkId')
  @HttpCode(HttpStatus.OK)
  cancelLink(
    @CurrentUser() user: Owner,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('linkId', ParseUUIDPipe) linkId: string,
    @Req() req: Request,
  ) {
    return this.service.cancelLink(user, id, linkId, req);
  }

  @Get(':id/latest')
  latest(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.latest(user, id);
  }

  @Post(':id/sync')
  @HttpCode(HttpStatus.OK)
  sync(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string, @Req() req: Request) {
    return this.service.sync(user, id, req);
  }

  @Get(':id/versions')
  versions(@CurrentUser() user: Owner, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.listVersions(user, id);
  }

  @Post(':id/versions/:version/restore')
  @HttpCode(HttpStatus.OK)
  restore(
    @CurrentUser() user: Owner,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('version', ParseIntPipe) version: number,
    @Body() dto: RestoreVersionDto,
    @Req() req: Request,
  ) {
    return this.service.restoreVersion(user, id, version, dto.baseVersion, req);
  }
}
