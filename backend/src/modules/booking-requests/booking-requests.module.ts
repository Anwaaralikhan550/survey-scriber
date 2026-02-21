import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { WebhooksModule } from '../webhooks/webhooks.module';
import { BookingRequestsService } from './booking-requests.service';
import { ClientBookingRequestsController } from './client-booking-requests.controller';
import { StaffBookingRequestsController } from './staff-booking-requests.controller';

@Module({
  imports: [PrismaModule, WebhooksModule],
  controllers: [
    ClientBookingRequestsController,
    StaffBookingRequestsController,
  ],
  providers: [BookingRequestsService],
  exports: [BookingRequestsService],
})
export class BookingRequestsModule {}
