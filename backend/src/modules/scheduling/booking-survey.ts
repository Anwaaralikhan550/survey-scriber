import { Booking, BookingStatus, Prisma, SurveyStatus, SurveyType } from '@prisma/client';

type BookingSurveyFields = Pick<
  Booking,
  'surveyType' | 'jobRef' | 'clientName' | 'postcode' | 'propertyAddress' | 'date'
>;

const blankToNull = (value: string | null | undefined): string | null =>
  value?.trim() || null;

/**
 * The inspection's details, taken from its booking. Every booking has one
 * inspection, which is where the surveyor works during the visit.
 */
export function surveyFieldsFromBooking(booking: BookingSurveyFields) {
  const isValuation = booking.surveyType === 'valuation';
  const label = isValuation ? 'Valuation' : 'Inspection';
  const titleEnd =
    blankToNull(booking.jobRef) ??
    blankToNull(booking.clientName) ??
    blankToNull(booking.postcode) ??
    booking.date.toLocaleDateString('en-GB', {
      day: 'numeric',
      month: 'short',
      year: 'numeric',
      timeZone: 'UTC',
    });

  return {
    title: `${label} - ${titleEnd}`.slice(0, 255),
    propertyAddress: booking.propertyAddress ?? '',
    type: isValuation ? SurveyType.VALUATION : SurveyType.INSPECTION,
    jobRef: blankToNull(booking.jobRef),
    clientName: blankToNull(booking.clientName),
    inspectionDate: booking.date,
  };
}

/** A cancelled booking takes its inspection along, unless work has started on it. */
export async function retireUnstartedSurvey(
  tx: Prisma.TransactionClient,
  surveyId: string | null,
): Promise<void> {
  if (!surveyId) return;
  await tx.survey.updateMany({
    where: {
      id: surveyId,
      status: SurveyStatus.DRAFT,
      deletedAt: null,
      sections: { none: { answers: { some: {} } } },
    },
    data: { deletedAt: new Date() },
  });
}

/** The first report finishes the job, so the booking leaves the live list. */
export async function completeLinkedBooking(
  tx: Prisma.TransactionClient,
  surveyId: string,
): Promise<void> {
  await tx.booking.updateMany({
    where: {
      surveyId,
      status: { in: [BookingStatus.PENDING, BookingStatus.CONFIRMED] },
    },
    data: { status: BookingStatus.COMPLETED },
  });
}

/** A deleted inspection leaves the booking; the surveyor can start a new one from it. */
export async function unlinkDeletedSurvey(
  tx: Prisma.TransactionClient,
  surveyId: string,
): Promise<void> {
  await tx.booking.updateMany({
    where: { surveyId },
    data: { surveyId: null },
  });
}

/** Creates the inspection for a booking that has none. */
export async function createSurveyForBooking(
  tx: Prisma.TransactionClient,
  booking: BookingSurveyFields & { surveyorId: string },
): Promise<string> {
  const survey = await tx.survey.create({
    data: {
      ...surveyFieldsFromBooking(booking),
      status: SurveyStatus.DRAFT,
      userId: booking.surveyorId,
    },
  });
  return survey.id;
}
