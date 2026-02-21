import {
  Injectable,
  Logger,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import {
  BookingRequestStatus,
  UserRole,
  NotificationType,
  RecipientType,
  ActorType,
  AuditEntityType,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService, AuditActions } from '../audit/audit.service';
import { WebhookDispatcherService } from '../webhooks/webhook-dispatcher.service';
import {
  CreateBookingRequestDto,
  ClientBookingRequestsQueryDto,
  StaffBookingRequestsQueryDto,
  BookingRequestDto,
  BookingRequestsListResponseDto,
} from './dto';

interface AuthenticatedClient {
  id: string;
  email: string;
  type: string;
}

interface AuthenticatedUser {
  id: string;
  email: string;
  role: UserRole;
}

/**
 * BookingRequest state machine: defines valid status transitions.
 * REQUESTED → APPROVED (staff approves)
 * REQUESTED → REJECTED (staff rejects)
 * APPROVED → (terminal state)
 * REJECTED → (terminal state)
 */
const BOOKING_REQUEST_TRANSITIONS: Record<BookingRequestStatus, BookingRequestStatus[]> = {
  [BookingRequestStatus.REQUESTED]: [BookingRequestStatus.APPROVED, BookingRequestStatus.REJECTED],
  [BookingRequestStatus.APPROVED]: [], // Terminal state
  [BookingRequestStatus.REJECTED]: [], // Terminal state
};

@Injectable()
export class BookingRequestsService {
  private readonly logger = new Logger(BookingRequestsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AuditService,
    private readonly webhookDispatcher: WebhookDispatcherService,
  ) {}

  /**
   * Validate booking request status transition
   */
  private validateStatusTransition(
    currentStatus: BookingRequestStatus,
    newStatus: BookingRequestStatus,
  ): void {
    // Allow idempotent same-state updates
    if (currentStatus === newStatus) {
      return;
    }

    const allowedTransitions = BOOKING_REQUEST_TRANSITIONS[currentStatus];
    if (!allowedTransitions || !allowedTransitions.includes(newStatus)) {
      throw new BadRequestException(
        `Invalid status transition: ${currentStatus} → ${newStatus}. ` +
        `Allowed transitions from ${currentStatus}: ${allowedTransitions?.length > 0 ? allowedTransitions.join(', ') : 'none (terminal state)'}`,
      );
    }
  }

  // ===========================
  // Client Methods
  // ===========================

  /**
   * Create a new booking request (client)
   */
  async createBookingRequest(
    clientId: string,
    dto: CreateBookingRequestDto,
  ): Promise<BookingRequestDto> {
    // Validate dates
    const startDate = new Date(dto.preferredStartDate);
    const endDate = new Date(dto.preferredEndDate);

    if (startDate > endDate) {
      throw new BadRequestException(
        'Preferred start date must be before or equal to end date',
      );
    }

    if (startDate < new Date()) {
      throw new BadRequestException(
        'Preferred start date must be in the future',
      );
    }

    const bookingRequest = await this.prisma.bookingRequest.create({
      data: {
        clientId,
        propertyAddress: dto.propertyAddress,
        preferredStartDate: startDate,
        preferredEndDate: endDate,
        notes: dto.notes,
        status: BookingRequestStatus.REQUESTED,
      },
      include: {
        client: true,
      },
    });

    // Notify all ADMIN and MANAGER users about the new booking request
    await this.notifyStaffOfNewRequest(bookingRequest.id, bookingRequest.client);

    // Audit log
    await this.auditService.log({
      actorType: ActorType.CLIENT,
      actorId: clientId,
      action: AuditActions.BOOKING_REQUEST_CREATED,
      entityType: AuditEntityType.BOOKING_REQUEST,
      entityId: bookingRequest.id,
      metadata: { propertyAddress: dto.propertyAddress },
    });

    // Dispatch webhook
    await this.webhookDispatcher.dispatchBookingRequestCreated({
      id: bookingRequest.id,
      clientId,
      propertyAddress: dto.propertyAddress,
      preferredStartDate: startDate,
      preferredEndDate: endDate,
    });

    this.logger.log(
      `Client ${clientId} created booking request ${bookingRequest.id}`,
    );

    return this.mapToDto(bookingRequest);
  }

  /**
   * Get client's own booking requests
   */
  async getClientBookingRequests(
    clientId: string,
    query: ClientBookingRequestsQueryDto,
  ): Promise<BookingRequestsListResponseDto> {
    const { status, page = 1, limit = 20 } = query;
    const skip = (page - 1) * limit;

    const where = {
      clientId,
      ...(status && { status }),
    };

    const [requests, total] = await Promise.all([
      this.prisma.bookingRequest.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        include: {
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
      this.prisma.bookingRequest.count({ where }),
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
   * Get a specific booking request (client - own only)
   */
  async getClientBookingRequest(
    clientId: string,
    requestId: string,
  ): Promise<BookingRequestDto> {
    const request = await this.prisma.bookingRequest.findFirst({
      where: {
        id: requestId,
        clientId,
      },
      include: {
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
      throw new NotFoundException('Booking request not found');
    }

    return this.mapToDto(request);
  }

  // ===========================
  // Staff Methods
  // ===========================

  /**
   * Get all booking requests (staff - ADMIN/MANAGER only)
   */
  async getStaffBookingRequests(
    query: StaffBookingRequestsQueryDto,
  ): Promise<BookingRequestsListResponseDto> {
    const { status, clientId, page = 1, limit = 20 } = query;
    const skip = (page - 1) * limit;

    const where = {
      ...(status && { status }),
      ...(clientId && { clientId }),
    };

    const [requests, total] = await Promise.all([
      this.prisma.bookingRequest.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        include: {
          client: {
            select: {
              id: true,
              email: true,
              firstName: true,
              lastName: true,
              phone: true,
              company: true,
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
      this.prisma.bookingRequest.count({ where }),
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
   * Get a specific booking request (staff)
   */
  async getStaffBookingRequest(requestId: string): Promise<BookingRequestDto> {
    const request = await this.prisma.bookingRequest.findUnique({
      where: { id: requestId },
      include: {
        client: {
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
            phone: true,
            company: true,
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
      throw new NotFoundException('Booking request not found');
    }

    return this.mapToDto(request);
  }

  /**
   * Approve a booking request (staff - ADMIN/MANAGER only)
   */
  async approveBookingRequest(
    requestId: string,
    user: AuthenticatedUser,
  ): Promise<BookingRequestDto> {
    const request = await this.prisma.bookingRequest.findUnique({
      where: { id: requestId },
      include: { client: true },
    });

    if (!request) {
      throw new NotFoundException('Booking request not found');
    }

    // Validate state transition using state machine
    this.validateStatusTransition(request.status, BookingRequestStatus.APPROVED);

    const updatedRequest = await this.prisma.bookingRequest.update({
      where: { id: requestId },
      data: {
        status: BookingRequestStatus.APPROVED,
        reviewedAt: new Date(),
        reviewedById: user.id,
      },
      include: {
        client: {
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
            phone: true,
            company: true,
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

    // Notify client of approval
    await this.notifyClientOfDecision(
      updatedRequest.id,
      updatedRequest.clientId,
      updatedRequest.propertyAddress,
      NotificationType.BOOKING_REQUEST_APPROVED,
    );

    // Audit log
    await this.auditService.log({
      actorType: ActorType.STAFF,
      actorId: user.id,
      action: AuditActions.BOOKING_REQUEST_APPROVED,
      entityType: AuditEntityType.BOOKING_REQUEST,
      entityId: requestId,
      metadata: { clientId: updatedRequest.clientId },
    });

    // Dispatch webhook
    await this.webhookDispatcher.dispatchBookingRequestApproved({
      id: requestId,
      clientId: updatedRequest.clientId,
      reviewedById: user.id,
    });

    this.logger.log(
      `Booking request ${requestId} approved by user ${user.id}`,
    );

    return this.mapToDto(updatedRequest);
  }

  /**
   * Reject a booking request (staff - ADMIN/MANAGER only)
   */
  async rejectBookingRequest(
    requestId: string,
    user: AuthenticatedUser,
    reason?: string,
  ): Promise<BookingRequestDto> {
    const request = await this.prisma.bookingRequest.findUnique({
      where: { id: requestId },
      include: { client: true },
    });

    if (!request) {
      throw new NotFoundException('Booking request not found');
    }

    // Validate state transition using state machine
    this.validateStatusTransition(request.status, BookingRequestStatus.REJECTED);

    // Append rejection reason to notes if provided
    const updatedNotes = reason
      ? request.notes
        ? `${request.notes}\n\nRejection reason: ${reason}`
        : `Rejection reason: ${reason}`
      : request.notes;

    const updatedRequest = await this.prisma.bookingRequest.update({
      where: { id: requestId },
      data: {
        status: BookingRequestStatus.REJECTED,
        reviewedAt: new Date(),
        reviewedById: user.id,
        notes: updatedNotes,
      },
      include: {
        client: {
          select: {
            id: true,
            email: true,
            firstName: true,
            lastName: true,
            phone: true,
            company: true,
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
      updatedRequest.id,
      updatedRequest.clientId,
      updatedRequest.propertyAddress,
      NotificationType.BOOKING_REQUEST_REJECTED,
    );

    // Audit log
    await this.auditService.log({
      actorType: ActorType.STAFF,
      actorId: user.id,
      action: AuditActions.BOOKING_REQUEST_REJECTED,
      entityType: AuditEntityType.BOOKING_REQUEST,
      entityId: requestId,
      metadata: { clientId: updatedRequest.clientId, reason },
    });

    this.logger.log(
      `Booking request ${requestId} rejected by user ${user.id}`,
    );

    return this.mapToDto(updatedRequest);
  }

  // ===========================
  // Private Helper Methods
  // ===========================

  private mapToDto(request: any): BookingRequestDto {
    return {
      id: request.id,
      clientId: request.clientId,
      propertyAddress: request.propertyAddress,
      preferredStartDate: request.preferredStartDate,
      preferredEndDate: request.preferredEndDate,
      notes: request.notes ?? undefined,
      status: request.status,
      createdAt: request.createdAt,
      reviewedAt: request.reviewedAt ?? undefined,
      reviewedById: request.reviewedById ?? undefined,
      client: request.client
        ? {
            id: request.client.id,
            email: request.client.email,
            firstName: request.client.firstName ?? undefined,
            lastName: request.client.lastName ?? undefined,
            phone: request.client.phone ?? undefined,
            company: request.client.company ?? undefined,
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
   * Notify all ADMIN and MANAGER users of a new booking request
   */
  private async notifyStaffOfNewRequest(
    bookingRequestId: string,
    client: { email: string; firstName?: string | null; lastName?: string | null },
  ): Promise<void> {
    try {
      // Get all ADMIN and MANAGER users
      const staffUsers = await this.prisma.user.findMany({
        where: {
          role: { in: [UserRole.ADMIN, UserRole.MANAGER] },
          isActive: true,
        },
        select: { id: true },
      });

      const clientName = client.firstName && client.lastName
        ? `${client.firstName} ${client.lastName}`
        : client.email;

      // Create notification for each staff member
      await this.prisma.notification.createMany({
        data: staffUsers.map((user) => ({
          type: NotificationType.BOOKING_REQUEST_CREATED,
          recipientType: RecipientType.USER,
          recipientId: user.id,
          title: 'New Booking Request',
          body: `${clientName} has submitted a new booking request.`,
          bookingRequestId,
        })),
      });

      this.logger.log(
        `Notified ${staffUsers.length} staff members of new booking request ${bookingRequestId}`,
      );
    } catch (error) {
      this.logger.error(`Failed to notify staff of new booking request: ${error}`);
      // Don't throw - notifications should not break main flow
    }
  }

  /**
   * Notify client of booking request decision
   */
  private async notifyClientOfDecision(
    bookingRequestId: string,
    clientId: string,
    propertyAddress: string,
    type: NotificationType,
  ): Promise<void> {
    try {
      const isApproved = type === NotificationType.BOOKING_REQUEST_APPROVED;
      const title = isApproved
        ? 'Booking Request Approved'
        : 'Booking Request Declined';
      const body = isApproved
        ? `Your booking request for ${propertyAddress} has been approved. We will contact you to schedule the appointment.`
        : `Your booking request for ${propertyAddress} has been declined. Please contact us for more information.`;

      await this.prisma.notification.create({
        data: {
          type,
          recipientType: RecipientType.CLIENT,
          recipientId: clientId,
          title,
          body,
          bookingRequestId,
        },
      });

      this.logger.log(
        `Notified client ${clientId} of booking request ${isApproved ? 'approval' : 'rejection'}`,
      );
    } catch (error) {
      this.logger.error(`Failed to notify client of booking request decision: ${error}`);
      // Don't throw - notifications should not break main flow
    }
  }
}
