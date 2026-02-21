import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import {
  BookingChangeRequestType,
  BookingChangeRequestStatus,
  BookingStatus,
  UserRole,
  NotificationType,
  RecipientType,
  ActorType,
  AuditEntityType,
} from '@prisma/client';
import { AuditService, AuditActions } from '../audit/audit.service';
import { PrismaService } from '../prisma/prisma.service';
import { WebhookDispatcherService } from '../webhooks/webhook-dispatcher.service';
import {
  CreateBookingChangeRequestDto,
  ClientBookingChangeRequestsQueryDto,
  StaffBookingChangeRequestsQueryDto,
  BookingChangeRequestDto,
  BookingChangeRequestsListResponseDto,
} from './dto';

interface AuthenticatedUser {
  id: string;
  email: string;
  role: UserRole;
}

@Injectable()
export class BookingChangeRequestsService {
  private readonly logger = new Logger(BookingChangeRequestsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AuditService,
    private readonly webhookDispatcher: WebhookDispatcherService,
  ) {}

  // ===========================
  // Client Methods
  // ===========================

  /**
   * Create a new booking change request (client)
   */
  async createChangeRequest(
    clientId: string,
    dto: CreateBookingChangeRequestDto,
  ): Promise<BookingChangeRequestDto> {
    // Verify booking exists and belongs to client
    const booking = await this.prisma.booking.findFirst({
      where: {
        id: dto.bookingId,
        clientId,
      },
    });

    if (!booking) {
      throw new NotFoundException(
        'Booking not found or does not belong to you',
      );
    }

    // Check booking is not already cancelled or completed
    if (
      booking.status === BookingStatus.CANCELLED ||
      booking.status === BookingStatus.COMPLETED
    ) {
      throw new BadRequestException(
        `Cannot request changes for a ${booking.status.toLowerCase()} booking`,
      );
    }

    // Check for existing pending change request for this booking
    const existingRequest = await this.prisma.bookingChangeRequest.findFirst({
      where: {
        bookingId: dto.bookingId,
        status: BookingChangeRequestStatus.REQUESTED,
      },
    });

    if (existingRequest) {
      throw new BadRequestException(
        'There is already a pending change request for this booking',
      );
    }

    // Validate reschedule request has required fields
    if (dto.type === BookingChangeRequestType.RESCHEDULE) {
      if (!dto.proposedDate || !dto.proposedStartTime || !dto.proposedEndTime) {
        throw new BadRequestException(
          'Reschedule requests require proposedDate, proposedStartTime, and proposedEndTime',
        );
      }

      const proposedDate = new Date(dto.proposedDate);
      if (proposedDate < new Date()) {
        throw new BadRequestException('Proposed date must be in the future');
      }
    }

    const changeRequest = await this.prisma.bookingChangeRequest.create({
      data: {
        bookingId: dto.bookingId,
        clientId,
        type: dto.type,
        proposedDate: dto.proposedDate ? new Date(dto.proposedDate) : null,
        proposedStartTime: dto.proposedStartTime,
        proposedEndTime: dto.proposedEndTime,
        reason: dto.reason,
        status: BookingChangeRequestStatus.REQUESTED,
      },
      include: {
        booking: {
          select: {
            id: true,
            date: true,
            startTime: true,
            endTime: true,
            status: true,
            propertyAddress: true,
          },
        },
        client: true,
      },
    });

    // Notify staff of new change request
    await this.notifyStaffOfNewRequest(changeRequest);

    // Audit log
    await this.auditService.log({
      actorType: ActorType.CLIENT,
      actorId: clientId,
      action: AuditActions.CHANGE_REQUEST_CREATED,
      entityType: AuditEntityType.BOOKING_CHANGE_REQUEST,
      entityId: changeRequest.id,
      metadata: { bookingId: dto.bookingId, type: dto.type },
    });

    this.logger.log(
      `Client ${clientId} created ${dto.type} request ${changeRequest.id} for booking ${dto.bookingId}`,
    );

    return this.mapToDto(changeRequest);
  }

  /**
   * Get client's change requests
   */
  async getClientChangeRequests(
    clientId: string,
    query: ClientBookingChangeRequestsQueryDto,
  ): Promise<BookingChangeRequestsListResponseDto> {
    const { type, status, page = 1, limit = 20 } = query;
    const skip = (page - 1) * limit;

    const where = {
      clientId,
      ...(type && { type }),
      ...(status && { status }),
    };

    const [requests, total] = await Promise.all([
      this.prisma.bookingChangeRequest.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        include: {
          booking: {
            select: {
              id: true,
              date: true,
              startTime: true,
              endTime: true,
              status: true,
              propertyAddress: true,
            },
          },
          reviewedBy: {
            select: {
              id: true,
              email: true,
              firstName: true,
              lastName: true,
            },
          },
        },
      }),
      this.prisma.bookingChangeRequest.count({ where }),
    ]);

    return {
      data: requests.map((r) => this.mapToDto(r)),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Get a specific change request (client - own only)
   */
  async getClientChangeRequest(
    clientId: string,
    requestId: string,
  ): Promise<BookingChangeRequestDto> {
    const request = await this.prisma.bookingChangeRequest.findFirst({
      where: {
        id: requestId,
        clientId,
      },
      include: {
        booking: {
          select: {
            id: true,
            date: true,
            startTime: true,
            endTime: true,
            status: true,
            propertyAddress: true,
          },
        },
        reviewedBy: {
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
          },
        },
      },
    });

    if (!request) {
      throw new NotFoundException('Change request not found');
    }

    return this.mapToDto(request);
  }

  // ===========================
  // Staff Methods
  // ===========================

  /**
   * Get all change requests (staff)
   */
  async getStaffChangeRequests(
    query: StaffBookingChangeRequestsQueryDto,
  ): Promise<BookingChangeRequestsListResponseDto> {
    const { type, status, clientId, bookingId, page = 1, limit = 20 } = query;
    const skip = (page - 1) * limit;

    const where = {
      ...(type && { type }),
      ...(status && { status }),
      ...(clientId && { clientId }),
      ...(bookingId && { bookingId }),
    };

    const [requests, total] = await Promise.all([
      this.prisma.bookingChangeRequest.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        include: {
          booking: {
            select: {
              id: true,
              date: true,
              startTime: true,
              endTime: true,
              status: true,
              propertyAddress: true,
            },
          },
          client: {
            select: {
              id: true,
              email: true,
              firstName: true,
              lastName: true,
              phone: true,
            },
          },
          reviewedBy: {
            select: {
              id: true,
              email: true,
              firstName: true,
              lastName: true,
            },
          },
        },
      }),
      this.prisma.bookingChangeRequest.count({ where }),
    ]);

    return {
      data: requests.map((r) => this.mapToDto(r)),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Get a specific change request (staff)
   */
  async getStaffChangeRequest(requestId: string): Promise<BookingChangeRequestDto> {
    const request = await this.prisma.bookingChangeRequest.findUnique({
      where: { id: requestId },
      include: {
        booking: {
          select: {
            id: true,
            date: true,
            startTime: true,
            endTime: true,
            status: true,
            propertyAddress: true,
          },
        },
        client: {
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
            phone: true,
          },
        },
        reviewedBy: {
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
          },
        },
      },
    });

    if (!request) {
      throw new NotFoundException('Change request not found');
    }

    return this.mapToDto(request);
  }

  /**
   * Approve a change request (staff)
   * - RESCHEDULE: updates booking date/time
   * - CANCEL: sets booking status to CANCELLED
   */
  async approveChangeRequest(
    requestId: string,
    user: AuthenticatedUser,
  ): Promise<BookingChangeRequestDto> {
    const request = await this.prisma.bookingChangeRequest.findUnique({
      where: { id: requestId },
      include: {
        booking: true,
        client: true,
      },
    });

    if (!request) {
      throw new NotFoundException('Change request not found');
    }

    if (request.status !== BookingChangeRequestStatus.REQUESTED) {
      throw new BadRequestException(
        `Cannot approve a change request with status ${request.status}`,
      );
    }

    // Use transaction to update both request and booking
    const result = await this.prisma.$transaction(async (tx) => {
      // Apply the change to the booking
      if (request.type === BookingChangeRequestType.RESCHEDULE) {
        await tx.booking.update({
          where: { id: request.bookingId },
          data: {
            date: request.proposedDate!,
            startTime: request.proposedStartTime!,
            endTime: request.proposedEndTime!,
          },
        });
      } else if (request.type === BookingChangeRequestType.CANCEL) {
        await tx.booking.update({
          where: { id: request.bookingId },
          data: {
            status: BookingStatus.CANCELLED,
          },
        });
      }

      // Update the change request
      return tx.bookingChangeRequest.update({
        where: { id: requestId },
        data: {
          status: BookingChangeRequestStatus.APPROVED,
          reviewedAt: new Date(),
          reviewedById: user.id,
        },
        include: {
          booking: {
            select: {
              id: true,
              date: true,
              startTime: true,
              endTime: true,
              status: true,
              propertyAddress: true,
            },
          },
          client: {
            select: {
              id: true,
              email: true,
              firstName: true,
              lastName: true,
              phone: true,
            },
          },
          reviewedBy: {
            select: {
              id: true,
              email: true,
              firstName: true,
              lastName: true,
            },
          },
        },
      });
    });

    // Notify client of approval
    await this.notifyClientOfDecision(
      result,
      NotificationType.BOOKING_CHANGE_REQUEST_APPROVED,
    );

    // Audit log
    await this.auditService.log({
      actorType: ActorType.STAFF,
      actorId: user.id,
      action: AuditActions.CHANGE_REQUEST_APPROVED,
      entityType: AuditEntityType.BOOKING_CHANGE_REQUEST,
      entityId: requestId,
      metadata: { bookingId: result.bookingId, type: result.type },
    });

    // Dispatch webhook
    await this.webhookDispatcher.dispatchBookingChangeApproved({
      id: requestId,
      bookingId: result.bookingId,
      clientId: result.clientId,
      type: result.type,
      reviewedById: user.id,
    });

    this.logger.log(
      `Change request ${requestId} approved by user ${user.id}`,
    );

    return this.mapToDto(result);
  }

  /**
   * Reject a change request (staff)
   */
  async rejectChangeRequest(
    requestId: string,
    user: AuthenticatedUser,
    reason?: string,
  ): Promise<BookingChangeRequestDto> {
    const request = await this.prisma.bookingChangeRequest.findUnique({
      where: { id: requestId },
      include: { client: true },
    });

    if (!request) {
      throw new NotFoundException('Change request not found');
    }

    if (request.status !== BookingChangeRequestStatus.REQUESTED) {
      throw new BadRequestException(
        `Cannot reject a change request with status ${request.status}`,
      );
    }

    // Append rejection reason to existing reason if provided
    const updatedReason = reason
      ? request.reason
        ? `${request.reason}\n\nRejection reason: ${reason}`
        : `Rejection reason: ${reason}`
      : request.reason;

    const updatedRequest = await this.prisma.bookingChangeRequest.update({
      where: { id: requestId },
      data: {
        status: BookingChangeRequestStatus.REJECTED,
        reviewedAt: new Date(),
        reviewedById: user.id,
        reason: updatedReason,
      },
      include: {
        booking: {
          select: {
            id: true,
            date: true,
            startTime: true,
            endTime: true,
            status: true,
            propertyAddress: true,
          },
        },
        client: {
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
            phone: true,
          },
        },
        reviewedBy: {
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
          },
        },
      },
    });

    // Notify client of rejection
    await this.notifyClientOfDecision(
      updatedRequest,
      NotificationType.BOOKING_CHANGE_REQUEST_REJECTED,
    );

    // Audit log
    await this.auditService.log({
      actorType: ActorType.STAFF,
      actorId: user.id,
      action: AuditActions.CHANGE_REQUEST_REJECTED,
      entityType: AuditEntityType.BOOKING_CHANGE_REQUEST,
      entityId: requestId,
      metadata: { bookingId: updatedRequest.bookingId, type: updatedRequest.type, reason },
    });

    this.logger.log(
      `Change request ${requestId} rejected by user ${user.id}`,
    );

    return this.mapToDto(updatedRequest);
  }

  // ===========================
  // Private Helper Methods
  // ===========================

  private mapToDto(request: any): BookingChangeRequestDto {
    return {
      id: request.id,
      bookingId: request.bookingId,
      clientId: request.clientId,
      type: request.type,
      proposedDate: request.proposedDate ?? undefined,
      proposedStartTime: request.proposedStartTime ?? undefined,
      proposedEndTime: request.proposedEndTime ?? undefined,
      reason: request.reason ?? undefined,
      status: request.status,
      createdAt: request.createdAt,
      reviewedAt: request.reviewedAt ?? undefined,
      reviewedById: request.reviewedById ?? undefined,
      booking: request.booking
        ? {
            id: request.booking.id,
            date: request.booking.date,
            startTime: request.booking.startTime,
            endTime: request.booking.endTime,
            status: request.booking.status,
            propertyAddress: request.booking.propertyAddress ?? undefined,
          }
        : undefined,
      client: request.client
        ? {
            id: request.client.id,
            email: request.client.email,
            firstName: request.client.firstName ?? undefined,
            lastName: request.client.lastName ?? undefined,
            phone: request.client.phone ?? undefined,
          }
        : undefined,
      reviewedBy: request.reviewedBy
        ? {
            id: request.reviewedBy.id,
            email: request.reviewedBy.email,
            firstName: request.reviewedBy.firstName ?? undefined,
            lastName: request.reviewedBy.lastName ?? undefined,
          }
        : undefined,
    };
  }

  /**
   * Notify staff of new change request
   */
  private async notifyStaffOfNewRequest(request: any): Promise<void> {
    try {
      const staffUsers = await this.prisma.user.findMany({
        where: {
          role: { in: [UserRole.ADMIN, UserRole.MANAGER] },
          isActive: true,
        },
        select: { id: true },
      });

      const clientName =
        request.client.firstName && request.client.lastName
          ? `${request.client.firstName} ${request.client.lastName}`
          : request.client.email;

      const typeLabel =
        request.type === BookingChangeRequestType.RESCHEDULE
          ? 'reschedule'
          : 'cancellation';

      await this.prisma.notification.createMany({
        data: staffUsers.map((user) => ({
          type: NotificationType.BOOKING_CHANGE_REQUEST_CREATED,
          recipientType: RecipientType.USER,
          recipientId: user.id,
          title: `New ${typeLabel} request`,
          body: `${clientName} has submitted a ${typeLabel} request.`,
          bookingId: request.bookingId,
          bookingChangeRequestId: request.id,
        })),
      });

      this.logger.log(
        `Notified ${staffUsers.length} staff of new change request ${request.id}`,
      );
    } catch (error) {
      this.logger.error(`Failed to notify staff: ${error}`);
    }
  }

  /**
   * Notify client of change request decision
   */
  private async notifyClientOfDecision(
    request: any,
    type: NotificationType,
  ): Promise<void> {
    try {
      const isApproved =
        type === NotificationType.BOOKING_CHANGE_REQUEST_APPROVED;
      const typeLabel =
        request.type === BookingChangeRequestType.RESCHEDULE
          ? 'reschedule'
          : 'cancellation';

      const title = isApproved
        ? `${typeLabel.charAt(0).toUpperCase() + typeLabel.slice(1)} Request Approved`
        : `${typeLabel.charAt(0).toUpperCase() + typeLabel.slice(1)} Request Declined`;

      const body = isApproved
        ? request.type === BookingChangeRequestType.RESCHEDULE
          ? `Your reschedule request has been approved. Your booking has been updated.`
          : `Your cancellation request has been approved. Your booking has been cancelled.`
        : `Your ${typeLabel} request has been declined. Please contact us for more information.`;

      await this.prisma.notification.create({
        data: {
          type,
          recipientType: RecipientType.CLIENT,
          recipientId: request.clientId,
          title,
          body,
          bookingId: request.bookingId,
          bookingChangeRequestId: request.id,
        },
      });

      this.logger.log(
        `Notified client ${request.clientId} of ${isApproved ? 'approval' : 'rejection'}`,
      );
    } catch (error) {
      this.logger.error(`Failed to notify client: ${error}`);
    }
  }
}
