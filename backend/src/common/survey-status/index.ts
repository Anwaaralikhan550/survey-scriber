/**
 * Survey Status State Machine
 *
 * Single source of truth for survey status transitions.
 * Used by both REST API (surveys.service.ts) and Sync API (sync.service.ts).
 *
 * State Machine:
 * - DRAFT → IN_PROGRESS (start work)
 * - IN_PROGRESS → PAUSED (pause work), COMPLETED (finish work)
 * - PAUSED → IN_PROGRESS (resume work)
 * - COMPLETED → PENDING_REVIEW (submit for review)
 * - PENDING_REVIEW → APPROVED, REJECTED (manager decision)
 * - APPROVED → (terminal state)
 * - REJECTED → IN_PROGRESS (revise work, cannot go back to DRAFT)
 *
 * @module common/survey-status
 */

import { SurveyStatus, UserRole } from '@prisma/client';
import { BadRequestException, ForbiddenException } from '@nestjs/common';

/**
 * Valid survey status transitions.
 * Maps current status to array of allowed target statuses.
 */
export const SURVEY_STATUS_TRANSITIONS: Record<SurveyStatus, SurveyStatus[]> = {
  [SurveyStatus.DRAFT]: [SurveyStatus.IN_PROGRESS],
  [SurveyStatus.IN_PROGRESS]: [SurveyStatus.PAUSED, SurveyStatus.COMPLETED],
  [SurveyStatus.PAUSED]: [SurveyStatus.IN_PROGRESS],
  [SurveyStatus.COMPLETED]: [SurveyStatus.PENDING_REVIEW],
  [SurveyStatus.PENDING_REVIEW]: [SurveyStatus.APPROVED, SurveyStatus.REJECTED],
  [SurveyStatus.APPROVED]: [], // Terminal state
  [SurveyStatus.REJECTED]: [SurveyStatus.IN_PROGRESS], // Revise only, cannot reset to DRAFT
};

/**
 * Transitions that require manager or admin role.
 */
export const MANAGER_ONLY_TRANSITIONS: Array<{ from: SurveyStatus; to: SurveyStatus }> = [
  { from: SurveyStatus.PENDING_REVIEW, to: SurveyStatus.APPROVED },
  { from: SurveyStatus.PENDING_REVIEW, to: SurveyStatus.REJECTED },
];

/**
 * Check if a status transition is valid according to the state machine.
 *
 * @param currentStatus - Current survey status
 * @param newStatus - Target status
 * @returns true if transition is valid
 */
export function isValidSurveyTransition(
  currentStatus: SurveyStatus,
  newStatus: SurveyStatus,
): boolean {
  if (currentStatus === newStatus) {
    return true; // No-op transition is always valid
  }
  const allowedTransitions = SURVEY_STATUS_TRANSITIONS[currentStatus];
  return allowedTransitions.includes(newStatus);
}

/**
 * Check if a transition requires manager/admin permissions.
 *
 * @param currentStatus - Current survey status
 * @param newStatus - Target status
 * @returns true if transition requires elevated permissions
 */
export function isManagerOnlyTransition(
  currentStatus: SurveyStatus,
  newStatus: SurveyStatus,
): boolean {
  return MANAGER_ONLY_TRANSITIONS.some(
    (t) => t.from === currentStatus && t.to === newStatus,
  );
}

/**
 * Validate a survey status transition and throw if invalid.
 *
 * @param currentStatus - Current survey status
 * @param newStatus - Target status
 * @throws BadRequestException if transition is invalid
 */
export function validateSurveyTransition(
  currentStatus: SurveyStatus,
  newStatus: SurveyStatus,
): void {
  if (currentStatus === newStatus) {
    return; // No-op transition is allowed
  }

  if (!isValidSurveyTransition(currentStatus, newStatus)) {
    const allowedTransitions = SURVEY_STATUS_TRANSITIONS[currentStatus];
    const allowedStr =
      allowedTransitions.length > 0 ? allowedTransitions.join(', ') : 'none (terminal state)';
    throw new BadRequestException(
      `Invalid status transition: ${currentStatus} → ${newStatus}. Allowed transitions from ${currentStatus}: ${allowedStr}`,
    );
  }
}

/**
 * Validate that the user has permission for a status transition.
 *
 * @param currentStatus - Current survey status
 * @param newStatus - Target status
 * @param userRole - Role of the user attempting the transition
 * @throws ForbiddenException if user lacks permission
 */
export function validateTransitionPermission(
  currentStatus: SurveyStatus,
  newStatus: SurveyStatus,
  userRole: UserRole,
): void {
  if (currentStatus === newStatus) {
    return; // No-op is always allowed
  }

  if (isManagerOnlyTransition(currentStatus, newStatus)) {
    if (userRole !== UserRole.ADMIN && userRole !== UserRole.MANAGER) {
      throw new ForbiddenException(
        `Only managers and admins can transition from ${currentStatus} to ${newStatus}`,
      );
    }
  }
}

/**
 * Perform full validation of a survey status transition.
 * Checks both validity and permissions.
 *
 * @param currentStatus - Current survey status
 * @param newStatus - Target status
 * @param userRole - Role of the user attempting the transition
 * @throws BadRequestException if transition is invalid
 * @throws ForbiddenException if user lacks permission
 */
export function validateSurveyStatusChange(
  currentStatus: SurveyStatus,
  newStatus: SurveyStatus,
  userRole: UserRole,
): void {
  validateSurveyTransition(currentStatus, newStatus);
  validateTransitionPermission(currentStatus, newStatus, userRole);
}
