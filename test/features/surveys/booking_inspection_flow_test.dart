// Client edit 4 Nov 2026: a booking's inspection, its folder and the week card.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:survey_scriber/core/database/app_database.dart' hide Survey;
import 'package:survey_scriber/core/database/daos/generated_reports_dao.dart';
import 'package:survey_scriber/core/database/daos/surveys_dao.dart';
import 'package:survey_scriber/core/database/database_providers.dart';
import 'package:survey_scriber/core/sync/sync_manager.dart';
import 'package:survey_scriber/core/sync/sync_state.dart';
import 'package:survey_scriber/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:survey_scriber/features/report_export/data/services/export_service.dart';
import 'package:survey_scriber/features/report_export/domain/models/export_config.dart';
import 'package:survey_scriber/features/report_export/presentation/providers/export_providers.dart';
import 'package:survey_scriber/features/scheduling/domain/entities/booking.dart';
import 'package:survey_scriber/features/scheduling/domain/entities/booking_status.dart';
import 'package:survey_scriber/features/scheduling/domain/repositories/scheduling_repository.dart';
import 'package:survey_scriber/features/scheduling/presentation/pages/create_booking_page.dart';
import 'package:survey_scriber/features/surveys/presentation/providers/survey_lifecycle.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';

class _Bookings extends Mock implements SchedulingRepository {}

class _Export extends Mock implements ExportService {}

class _Sync extends StateNotifier<SyncState> with Mock implements SyncStateNotifier {
  _Sync() : super(const SyncState());

  final queued = <({SyncAction action, String id, Map<String, dynamic> payload})>[];

  @override
  Future<void> queueSync({
    required SyncEntityType entityType,
    required String entityId,
    required SyncAction action,
    required Map<String, dynamic> payload,
  }) async {
    expect(entityType, SyncEntityType.survey);
    queued.add((action: action, id: entityId, payload: payload));
  }
}

Survey _survey({SurveyStatus status = SurveyStatus.draft}) => Survey(
      id: 's1',
      title: 'Inspection - R1',
      type: SurveyType.inspection,
      status: status,
      createdAt: DateTime(2026, 11, 1),
    );

Booking _booking(
  DateTime date, {
  BookingStatus status = BookingStatus.pending,
  BookingSurveyType type = BookingSurveyType.homeSurvey,
}) =>
    Booking(
      id: 'b${date.millisecondsSinceEpoch}',
      surveyorId: 'u1',
      date: date,
      startTime: '09:00',
      endTime: '10:00',
      status: status,
      surveyType: type,
      createdById: 'u1',
      createdAt: date,
      updatedAt: date,
    );

void main() {
  group('survey folder follows the work', () {
    late AppDatabase db;
    late _Sync sync;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      sync = _Sync();
      container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        syncStateProvider.overrideWith((ref) => sync),
      ]);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<SurveyStatus> statusNow() async =>
        (await SurveysDao(db).getSurveyById('s1'))!.status;

    test('Live, then In Progress on the first answer, once', () async {
      await SurveysDao(db).upsertSurvey(_survey());
      expect(JobFilter.live.matches(_survey()), isTrue);

      final lifecycle = container.read(surveyLifecycleProvider);
      await lifecycle.markStarted('s1');
      await lifecycle.markStarted('s1');

      expect(await statusNow(), SurveyStatus.inProgress);
      expect(sync.queued, hasLength(1));
      expect(sync.queued.single.action, SyncAction.update);
      // Status only: the whole survey would make the server replace its sections.
      expect(sync.queued.single.payload, {'status': 'IN_PROGRESS'});
    });

    for (final from in [SurveyStatus.draft, SurveyStatus.inProgress, SurveyStatus.paused]) {
      test('the first report moves ${from.name} to Completed', () async {
        await SurveysDao(db).upsertSurvey(_survey(status: from));
        await container.read(surveyLifecycleProvider).markReportGenerated('s1');
        expect(await statusNow(), SurveyStatus.completed);
        expect(sync.queued.single.payload, {'status': 'COMPLETED'});
      });
    }

    test('a completed survey stays Completed through edits and more reports', () async {
      await SurveysDao(db).upsertSurvey(_survey(status: SurveyStatus.completed));
      final lifecycle = container.read(surveyLifecycleProvider);
      await lifecycle.markStarted('s1');
      await lifecycle.markReportGenerated('s1');
      expect(await statusNow(), SurveyStatus.completed);
      expect(sync.queued, isEmpty);
    });

    for (final status in [SurveyStatus.pendingReview, SurveyStatus.approved]) {
      test('a report does not pull ${status.name} back', () async {
        await SurveysDao(db).upsertSurvey(_survey(status: status));
        await container.read(surveyLifecycleProvider).markReportGenerated('s1');
        expect(await statusNow(), status);
      });
    }

    group('exporting a report', () {
      late _Export export;
      late ProviderContainer withExport;

      setUpAll(() => registerFallbackValue(const ExportConfig()));

      setUp(() {
        export = _Export();
        withExport = ProviderContainer(overrides: [
          appDatabaseProvider.overrideWithValue(db),
          syncStateProvider.overrideWith((ref) => _Sync()),
          exportServiceProvider.overrideWithValue(export),
        ]);
      });

      tearDown(() => withExport.dispose());

      test('a report that was made completes the survey', () async {
        await SurveysDao(db).upsertSurvey(_survey());
        when(() => export.exportValuation(any(), any(), onProgress: any(named: 'onProgress')))
            .thenAnswer((_) async => const ExportResult(
                  reportId: 'r1',
                  surveyId: 's1',
                  outputPath: '/r1.pdf',
                  format: ExportFormat.pdf,
                ));
        await withExport.read(exportProvider.notifier).exportValuation('s1');
        expect(await statusNow(), SurveyStatus.completed);
      });

      test('a report that failed leaves the survey where it was', () async {
        await SurveysDao(db).upsertSurvey(_survey());
        when(() => export.exportValuation(any(), any(), onProgress: any(named: 'onProgress')))
            .thenThrow(Exception('no fonts'));
        await withExport.read(exportProvider.notifier).exportValuation('s1');
        expect(await statusNow(), SurveyStatus.draft);
      });
    });

    test('delete removes it from the phone and tells the server', () async {
      await SurveysDao(db).upsertSurvey(_survey(status: SurveyStatus.completed));
      await container.read(surveyLifecycleProvider).delete('s1');
      expect(await SurveysDao(db).getSurveyById('s1'), isNull);
      expect(sync.queued.single.action, SyncAction.delete);
      expect(sync.queued.single.id, 's1');
    });

    test('latest report prefers the newest PDF', () async {
      Future<void> report(String id, String format, DateTime at) =>
          GeneratedReportsDao(db).insertReport(GeneratedReportsCompanion.insert(
            id: id,
            surveyId: 's1',
            filePath: '/$id',
            fileName: id,
            generatedAt: at,
            format: Value(format),
          ));
      final lifecycle = container.read(surveyLifecycleProvider);
      expect(await lifecycle.latestReport('s1'), isNull);
      await report('old', 'pdf', DateTime(2026, 11, 1));
      await report('new', 'pdf', DateTime(2026, 11, 3));
      await report('word', 'docx', DateTime(2026, 11, 4));
      expect((await lifecycle.latestReport('s1'))!.id, 'new');
    });
  });

  group('a survey arriving from the server', () {
    const serverCopy = {'status': 'COMPLETED'};

    final local = Survey(
      id: 's1',
      title: 'Old title',
      type: SurveyType.inspection,
      status: SurveyStatus.inProgress,
      createdAt: DateTime(2026, 11, 1),
      startedAt: DateTime(2026, 11, 2),
      completedAt: DateTime(2026, 11, 3),
      progress: 0.5,
      photoCount: 3,
      noteCount: 2,
      totalSections: 100,
      completedSections: 50,
      reinspectionNumber: 1,
      aiSummary: 'a',
      riskSummary: 'r',
      repairRecommendations: 'p',
      clientName: 'Old client',
    );

    test('takes the server details and keeps what only the phone knows', () {
      final fromServer = Survey(
        id: 's1',
        title: 'New title',
        type: SurveyType.inspection,
        status: SurveyStatus.fromBackendString(serverCopy['status']!),
        createdAt: DateTime(2026, 11, 1),
        address: 'New address',
        inspectionDate: DateTime(2026, 12, 1),
      );
      final merged = keepLocalSurveyFields(fromServer, local);
      expect(merged.title, 'New title');
      expect(merged.status, SurveyStatus.completed);
      expect(merged.address, 'New address');
      expect(merged.inspectionDate, DateTime(2026, 12, 1));
      // A field emptied on the booking is emptied here too.
      expect(merged.clientName, isNull);
      expect(merged.progress, 0.5);
      expect(merged.photoCount, 3);
      expect(merged.noteCount, 2);
      expect(merged.totalSections, 100);
      expect(merged.completedSections, 50);
      expect(merged.startedAt, DateTime(2026, 11, 2));
      expect(merged.completedAt, DateTime(2026, 11, 3));
      expect(merged.reinspectionNumber, 1);
      expect(merged.aiSummary, 'a');
      expect(merged.riskSummary, 'r');
      expect(merged.repairRecommendations, 'p');
    });

    test('a new survey is stored as it came', () {
      expect(identical(keepLocalSurveyFields(local, null), local), isTrue);
    });

    test('the visit date stays that day in every time zone', () {
      final date = parseServerDateOnly('2026-11-10T00:00:00.000Z')!;
      expect([date.year, date.month, date.day], [2026, 11, 10]);
      expect(date.hour, 0);
      expect(parseServerDateOnly(null), isNull);
      expect(parseServerDateOnly(''), isNull);
    });
  });

  group('This week', () {
    late _Bookings repo;
    // Wednesday 4 Nov 2026
    final today = DateTime(2026, 11, 4, 15, 30);

    setUp(() => repo = _Bookings());

    void bookings(List<Booking> list) {
      when(() => repo.getMyBookings(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => list);
    }

    test('counts per day of this week, Monday first', () async {
      bookings([
        _booking(DateTime(2026, 11, 4)),
        _booking(DateTime(2026, 11, 4, 0, 0, 1)),
        _booking(DateTime(2026, 11, 7)),
        _booking(DateTime(2026, 11, 7, 0, 0, 1)),
        _booking(DateTime(2026, 11, 7, 0, 0, 2)),
      ]);
      expect(
        await countWeekBookings(repo, HomeSegment.homeSurveys, today),
        [0, 0, 2, 0, 0, 3, 0],
      );
    });

    test('asks for Monday to Sunday', () async {
      bookings([]);
      await countWeekBookings(repo, HomeSegment.homeSurveys, today);
      verify(() => repo.getMyBookings(
            startDate: DateTime(2026, 11, 2),
            endDate: DateTime(2026, 11, 8),
            page: 1,
            limit: 100,
          )).called(1);
    });

    test('on a Sunday the week is the one ending today', () async {
      bookings([_booking(DateTime(2026, 11, 8)), _booking(DateTime(2026, 11, 2))]);
      expect(
        await countWeekBookings(repo, HomeSegment.homeSurveys, DateTime(2026, 11, 8, 23)),
        [1, 0, 0, 0, 0, 0, 1],
      );
    });

    test('cancelled bookings and the other segment do not count', () async {
      bookings([
        _booking(DateTime(2026, 11, 3), status: BookingStatus.cancelled),
        _booking(DateTime(2026, 11, 3), type: BookingSurveyType.valuation),
        _booking(DateTime(2026, 11, 3), status: BookingStatus.completed),
      ]);
      expect(
        await countWeekBookings(repo, HomeSegment.homeSurveys, today),
        [0, 1, 0, 0, 0, 0, 0],
      );
      expect(
        await countWeekBookings(repo, HomeSegment.valuations, today),
        [0, 1, 0, 0, 0, 0, 0],
      );
    });
  });

  group('estate agent address back into the form', () {
    test('all four parts', () {
      final a = splitAgentAddress('1 Agent St\nLeeds\nLS1 4AB\nWest Yorkshire');
      expect(a.line, '1 Agent St');
      expect(a.city, 'Leeds');
      expect(a.postcode, 'LS1 4AB');
      expect(a.county, 'West Yorkshire');
    });

    test('a part left out leaves the others in their fields', () {
      final noCity = splitAgentAddress('1 Agent St\nLS1 4AB\nWest Yorkshire');
      expect(noCity.line, '1 Agent St');
      expect(noCity.city, '');
      expect(noCity.postcode, 'LS1 4AB');
      expect(noCity.county, 'West Yorkshire');

      final noCounty = splitAgentAddress('1 Agent St\nLeeds\nls14ab');
      expect(noCounty.postcode, 'ls14ab');
      expect(noCounty.county, '');
    });

    test('empty and missing', () {
      expect(splitAgentAddress(null).line, '');
      expect(splitAgentAddress('').postcode, '');
      expect(splitAgentAddress('Just a line').line, 'Just a line');
    });
  });
}
