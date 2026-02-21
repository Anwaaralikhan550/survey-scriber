import { Module } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { NotificationEmailService } from './notification-email.service';
import { NotificationsController } from './notifications.controller';
import { BookingEventHandler } from './handlers/booking-event.handler';
import { InvoiceEventHandler } from './handlers/invoice-event.handler';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [NotificationsController],
  providers: [
    NotificationsService,
    NotificationEmailService,
    BookingEventHandler,
    InvoiceEventHandler,
  ],
  exports: [NotificationsService, NotificationEmailService],
})
export class NotificationsModule {}
