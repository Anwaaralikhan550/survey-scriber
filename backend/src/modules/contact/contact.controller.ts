import { Body, Controller, HttpCode, HttpStatus, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { User } from '@prisma/client';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ContactService } from './contact.service';
import { ContactDto } from './dto/contact.dto';

@ApiTags('Contact')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('contact')
export class ContactController {
  constructor(private readonly contact: ContactService) {}

  @Post()
  @HttpCode(HttpStatus.OK)
  @Throttle({ long: { limit: 5, ttl: 3600000 } }) // 5 messages an hour per address
  @ApiOperation({ summary: 'Send a message to support (Contact Us)' })
  send(@CurrentUser() user: User, @Body() dto: ContactDto) {
    return this.contact.send(user, dto);
  }
}
