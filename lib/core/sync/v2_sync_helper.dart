import 'package:uuid/uuid.dart';

/// Deterministic UUID generation for V2 survey entities.
///
/// Uses UUID v5 (SHA-1 based, deterministic) so the same entity always
/// gets the same sync UUID without storing extra columns. This enables
/// the SyncQueueDao to find and merge existing queue entries by entityId.
class V2SyncHelper {
  V2SyncHelper._();

  static const _uuid = Uuid();

  /// Generate a deterministic UUID for a V2 section.
  ///
  /// The backend `Section` model requires a UUID primary key. V2 sections
  /// are identified by string keys (e.g., "E", "F"), so we generate a
  /// stable UUID from the surveyId + sectionKey combination.
  static String sectionSyncId(String surveyId, String sectionKey) =>
      _uuid.v5(Uuid.NAMESPACE_URL, 'v2_section_${surveyId}_$sectionKey');

  /// Generate a deterministic UUID for a V2 answer.
  ///
  /// The backend `Answer` model requires a UUID primary key. V2 answers
  /// use composite string IDs locally, so we generate a stable UUID from
  /// the surveyId + screenId + fieldKey combination.
  static String answerSyncId(
    String surveyId,
    String screenId,
    String fieldKey,
  ) =>
      _uuid.v5(
        Uuid.NAMESPACE_URL,
        'v2_answer_${surveyId}_${screenId}_$fieldKey',
      );
}
