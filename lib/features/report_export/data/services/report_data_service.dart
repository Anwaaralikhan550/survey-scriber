import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart' show InspectionV2Screen;
import '../../../../core/database/daos/media_dao.dart';
import '../../../../core/database/daos/signature_dao.dart';
import '../../../../core/database/daos/surveys_dao.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/domain/entities/survey.dart';
import '../../../property_inspection/data/inspection_repository.dart';
import '../../../property_inspection/domain/models/inspection_models.dart';
import '../../../property_valuation/data/valuation_repository.dart';
import '../../../signature/presentation/providers/signature_provider.dart';

/// Raw data bundle before the builder transforms it into a format-agnostic
/// [ReportDocument].
class V2RawReportData {
  const V2RawReportData({
    required this.survey,
    required this.tree,
    required this.allAnswers,
    required this.screenStates,
    required this.photoFilePaths,
    required this.signatureRows,
    this.persistedPhrases = const {},
    this.persistedUserNotes = const {},
  });

  final Survey survey;
  final InspectionTreePayload tree;

  /// screenId → { fieldKey → value }
  final Map<String, Map<String, String>> allAnswers;

  /// screenId → isCompleted
  final Map<String, bool> screenStates;

  final List<String> photoFilePaths;
  final List<SignatureRow> signatureRows;

  /// screenId → persisted phrase list from the `phrase_output` DB column.
  ///
  /// When a surveyor saves a draft or marks a screen complete, the phrase
  /// engine output is JSON-encoded and stored in the DB.  Using these
  /// persisted phrases ensures the exported report matches exactly what
  /// the user saw on-screen (M1 fix: data accuracy).
  ///
  /// Empty map for legacy surveys that predate schema v18.
  final Map<String, List<String>> persistedPhrases;

  /// screenId → surveyor's custom note from the `user_note` DB column.
  ///
  /// Empty map for surveys that predate schema v19.
  final Map<String, String> persistedUserNotes;
}

/// Minimal signature info needed by the builder.
class SignatureRow {
  const SignatureRow({
    required this.signerName,
    required this.signerRole,
    required this.filePath,
    required this.signedAt,
  });

  final String signerName;
  final String signerRole;
  final String filePath;
  final DateTime signedAt;
}

/// Loads all raw data needed to build a V2 report for either
/// Inspection or Valuation surveys.
class ReportDataService {
  ReportDataService({
    required this.inspectionRepo,
    required this.valuationRepo,
    required this.surveysDao,
    required this.mediaDao,
    required this.signatureDao,
  });

  final InspectionRepository inspectionRepo;
  final ValuationRepository valuationRepo;
  final SurveysDao surveysDao;
  final MediaDao mediaDao;
  final SignatureDao signatureDao;

  /// Load all data for an Inspection survey.
  Future<V2RawReportData> loadInspectionData(String surveyId) async {
    final survey = await surveysDao.getSurveyById(surveyId);
    if (survey == null) throw Exception('Survey $surveyId not found');

    // Batch-load: 2 queries instead of ~500 sequential ones
    final results = await Future.wait([
      inspectionRepo.loadTree(),
      inspectionRepo.getAllAnswersForSurvey(surveyId),
      inspectionRepo.getAllScreensForSurvey(surveyId),
      _loadPhotos(surveyId),
      _loadSignatures(surveyId),
    ]);

    final tree = results[0] as InspectionTreePayload;
    final allAnswers = results[1] as Map<String, Map<String, String>>;
    final allScreenRows = results[2] as List<InspectionV2Screen>;
    final photos = results[3] as List<String>;
    final sigs = results[4] as List<SignatureRow>;

    final screenStates = _buildScreenStatesMap(allScreenRows);
    final persistedPhrases = _buildPersistedPhrasesMap(allScreenRows);
    final persistedUserNotes = _buildPersistedUserNotesMap(allScreenRows);

    AppLogger.d('ReportData',
        'Loaded inspection data: ${allAnswers.length} screens, '
        '${photos.length} photos, ${sigs.length} signatures, '
        '${persistedPhrases.length} screens with persisted phrases, '
        '${persistedUserNotes.length} screens with user notes');

    return V2RawReportData(
      survey: survey,
      tree: tree,
      allAnswers: allAnswers,
      screenStates: screenStates,
      photoFilePaths: photos,
      signatureRows: sigs,
      persistedPhrases: persistedPhrases,
      persistedUserNotes: persistedUserNotes,
    );
  }

  /// Load all data for a Valuation survey.
  Future<V2RawReportData> loadValuationData(String surveyId) async {
    final survey = await surveysDao.getSurveyById(surveyId);
    if (survey == null) throw Exception('Survey $surveyId not found');

    // Batch-load: 2 queries instead of ~500 sequential ones
    final results = await Future.wait([
      valuationRepo.loadTree(),
      valuationRepo.getAllAnswersForSurvey(surveyId),
      valuationRepo.getAllScreensForSurvey(surveyId),
      _loadPhotos(surveyId),
      _loadSignatures(surveyId),
    ]);

    final tree = results[0] as InspectionTreePayload;
    final allAnswers = results[1] as Map<String, Map<String, String>>;
    final allScreenRows = results[2] as List<InspectionV2Screen>;
    final photos = results[3] as List<String>;
    final sigs = results[4] as List<SignatureRow>;

    final screenStates = _buildScreenStatesMap(allScreenRows);
    final persistedPhrases = _buildPersistedPhrasesMap(allScreenRows);
    final persistedUserNotes = _buildPersistedUserNotesMap(allScreenRows);

    AppLogger.d('ReportData',
        'Loaded valuation data: ${allAnswers.length} screens, '
        '${photos.length} photos, ${sigs.length} signatures, '
        '${persistedPhrases.length} screens with persisted phrases, '
        '${persistedUserNotes.length} screens with user notes');

    return V2RawReportData(
      survey: survey,
      tree: tree,
      allAnswers: allAnswers,
      screenStates: screenStates,
      photoFilePaths: photos,
      signatureRows: sigs,
      persistedPhrases: persistedPhrases,
      persistedUserNotes: persistedUserNotes,
    );
  }

  /// Build screenId → isCompleted map from pre-fetched screen rows.
  Map<String, bool> _buildScreenStatesMap(List<InspectionV2Screen> rows) {
    return {for (final row in rows) row.screenId: row.isCompleted};
  }

  /// Extract persisted phrase output from pre-fetched screen rows.
  ///
  /// Each screen's `phraseOutput` column stores a JSON-encoded
  /// `List<String>` written by `_persistPhraseOutput()` on save/complete.
  /// Returns an empty map for legacy surveys (all nulls).
  Map<String, List<String>> _buildPersistedPhrasesMap(
    List<InspectionV2Screen> rows,
  ) {
    final result = <String, List<String>>{};
    for (final row in rows) {
      if (row.phraseOutput != null && row.phraseOutput!.isNotEmpty) {
        try {
          final decoded = jsonDecode(row.phraseOutput!) as List<dynamic>;
          result[row.screenId] = decoded.cast<String>();
        } catch (_) {
          // Malformed JSON — skip this screen, builder will regenerate
        }
      }
    }
    return result;
  }

  /// Extract surveyor custom notes from pre-fetched screen rows.
  ///
  /// Returns screenId → note text. Empty map for surveys pre-v19.
  Map<String, String> _buildPersistedUserNotesMap(
    List<InspectionV2Screen> rows,
  ) {
    final result = <String, String>{};
    for (final row in rows) {
      if (row.userNote != null && row.userNote!.isNotEmpty) {
        result[row.screenId] = row.userNote!;
      }
    }
    return result;
  }

  Future<List<String>> _loadPhotos(String surveyId) async {
    try {
      final mediaItems = await mediaDao.getMediaBySurvey(surveyId);
      return mediaItems
          .where((m) => m.mediaType == 'photo')
          .map((m) => m.localPath)
          .toList();
    } catch (e) {
      AppLogger.w('ReportData', 'Failed to load photos: $e');
      return [];
    }
  }

  Future<List<SignatureRow>> _loadSignatures(String surveyId) async {
    try {
      final sigs = await signatureDao.getSignaturesBySurvey(surveyId);
      final previewService = SignaturePreviewService.instance;
      final result = <SignatureRow>[];

      for (final s in sigs) {
        final item = signatureDao.toSignatureItem(s);
        var filePath = item.previewPath;

        // If no preview PNG exists, try to generate one from stored strokes
        if (filePath == null || !await File(filePath).exists()) {
          if (item.isNotEmpty) {
            try {
              final canvasSize = Size(
                (item.width ?? 800).toDouble(),
                (item.height ?? 300).toDouble(),
              );
              filePath = await previewService.savePreview(
                signatureId: item.id,
                strokes: item.strokes,
                canvasSize: canvasSize,
              );
              // Persist so we don't regenerate next time
              await signatureDao.updatePreviewPath(item.id, filePath);
            } catch (e) {
              AppLogger.w('ReportData',
                  'Failed to generate signature preview: $e');
            }
          }
        }

        // Include signature even without preview — renderers show placeholder
        result.add(SignatureRow(
          signerName: item.signerName ?? 'Unknown',
          signerRole: item.signerRole ?? 'Surveyor',
          filePath: filePath ?? '',
          signedAt: item.createdAt,
        ));
      }

      return result;
    } catch (e) {
      AppLogger.w('ReportData', 'Failed to load signatures: $e');
      return [];
    }
  }
}
