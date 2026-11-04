import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, Post, Put, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiProperty, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { User, UserRole } from '@prisma/client';
import { IsString, MaxLength } from 'class-validator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { EmailTemplatesService } from './email-templates.service';

export class EmailTemplateEditDto {
  @ApiProperty()
  @IsString()
  @MaxLength(300)
  subject!: string;

  @ApiProperty()
  @IsString()
  @MaxLength(200_000)
  html!: string;

  @ApiProperty()
  @IsString()
  @MaxLength(50_000)
  text!: string;
}

@ApiTags('Admin - Email Templates')
@ApiBearerAuth('JWT-auth')
@Controller('admin/email-templates')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class EmailTemplatesController {
  constructor(private readonly templates: EmailTemplatesService) {}

  @Get()
  @ApiOperation({ summary: 'Every email the system sends' })
  list() {
    return this.templates.list();
  }

  @Get(':key')
  @ApiOperation({ summary: 'One email: the wording in use, its original and its placeholders' })
  get(@Param('key') key: string) {
    return this.templates.get(key);
  }

  @Put(':key')
  @ApiOperation({ summary: 'Save an edit. Placeholders must stay as they are.' })
  save(
    @Param('key') key: string,
    @Body() dto: EmailTemplateEditDto,
    @CurrentUser() user: Omit<User, 'passwordHash'>,
  ) {
    return this.templates.save(key, dto, user);
  }

  @Delete(':key')
  @ApiOperation({ summary: 'Back to the original wording' })
  reset(@Param('key') key: string, @CurrentUser() user: Omit<User, 'passwordHash'>) {
    return this.templates.reset(key, user);
  }

  @Post(':key/preview')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'The email filled in with made-up values' })
  preview(@Param('key') key: string, @Body() dto: EmailTemplateEditDto) {
    return this.templates.preview(key, dto);
  }

  @Post(':key/test')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  @ApiOperation({ summary: 'Send it, with made-up values, to your own email address only' })
  sendTest(
    @Param('key') key: string,
    @Body() dto: EmailTemplateEditDto,
    @CurrentUser() user: Omit<User, 'passwordHash'>,
  ) {
    return this.templates.sendTest(key, dto, user);
  }
}
