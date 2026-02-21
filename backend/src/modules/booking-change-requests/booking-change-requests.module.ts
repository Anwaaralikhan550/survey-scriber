import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { WebhooksModule } from '../webhooks/webhooks.module';
import { BookingChangeRequestsService } from './booking-change-requests.service';
import { ClientBookingChangeRequestsController } from './client-booking-change-requests.controller';
import { StaffBookingChangeRequestsController } from './staff-booking-change-requests.controller';

@Module({
  imports: [PrismaModule, WebhooksModule],
  controllers: [
    ClientBookingChangeRequestsController,
    StaffBookingChangeRequestsController,
  ],
  providers: [BookingChangeRequestsService],
  exports: [BookingChangeRequestsService],
})
export class BookingChangeRequestsModule {}
