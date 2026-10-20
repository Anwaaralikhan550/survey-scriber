import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:survey_scriber/app/router/routes.dart';
import 'package:survey_scriber/core/sync/sync_manager.dart';
import 'package:survey_scriber/core/sync/sync_state.dart';
import 'package:survey_scriber/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:survey_scriber/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:survey_scriber/features/scheduling/domain/entities/booking.dart';
import 'package:survey_scriber/features/scheduling/domain/entities/booking_status.dart';
import 'package:survey_scriber/features/scheduling/domain/repositories/scheduling_repository.dart';
import 'package:survey_scriber/features/surveys/domain/repositories/survey_repository.dart';
import 'package:survey_scriber/features/surveys/presentation/providers/survey_providers.dart';
import 'package:survey_scriber/shared/domain/entities/survey.dart';

class _Surveys implements SurveyRepository {
  _Surveys(this.all);
  final List<Survey> all;
  @override
  Future<List<Survey>> getAllSurveys() async => all;
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}

class _Sync extends StateNotifier<SyncState> implements SyncStateNotifier {
  _Sync() : super(SyncState.initial);
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

Booking _booking(BookingStatus s, BookingSurveyType t) => Booking(
      id: '${s.name}-${t.name}-${DateTime.now().microsecondsSinceEpoch}',
      surveyorId: 's',
      date: DateTime(2026, 7, 25),
      startTime: '09:00',
      endTime: '10:00',
      status: s,
      surveyType: t,
      createdById: 'u',
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1),
    );

class _Repo implements SchedulingRepository {
  _Repo(this.byStatus);
  final Map<BookingStatus, List<Booking>> byStatus;
  final calls = <String>[];

  @override
  Future<List<Booking>> getMyBookings({
    BookingStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    calls.add('${status?.name}:$page:$limit');
    final all = byStatus[status] ?? const <Booking>[];
    final from = (page - 1) * limit;
    if (from >= all.length) return const [];
    return all.sublist(from, (from + limit).clamp(0, all.length));
  }

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}

void main() {
  group('countLiveBookings', () {
    test('counts pending + confirmed per segment and ignores completed/cancelled', () async {
      final repo = _Repo({
        BookingStatus.pending: [
          _booking(BookingStatus.pending, BookingSurveyType.homeSurvey),
          _booking(BookingStatus.pending, BookingSurveyType.valuation),
        ],
        BookingStatus.confirmed: [
          _booking(BookingStatus.confirmed, BookingSurveyType.homeSurvey),
        ],
        BookingStatus.completed: [
          _booking(BookingStatus.completed, BookingSurveyType.homeSurvey),
        ],
      });
      final counts = await countLiveBookings(repo);
      expect(counts[HomeSegment.homeSurveys], 2);
      expect(counts[HomeSegment.valuations], 1);
      expect(repo.calls.any((c) => c.startsWith('completed')), isFalse);
    });

    test('pages through more than 100 bookings', () async {
      final repo = _Repo({
        BookingStatus.pending: List.generate(
            105, (_) => _booking(BookingStatus.pending, BookingSurveyType.homeSurvey)),
      });
      final counts = await countLiveBookings(repo);
      expect(counts[HomeSegment.homeSurveys], 105);
      expect(repo.calls.where((c) => c.startsWith('pending')).length, 2);
    });
  });

  group('Dashboard Total card (App-Edit: Total = live bookings)', () {
    Survey draft(String id, SurveyType t) => Survey(
          id: id,
          title: 'J$id',
          type: t,
          status: SurveyStatus.draft,
          createdAt: DateTime.now(),
        );

    Widget host(Future<Map<HomeSegment, int>?> Function() live) {
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (c, s) => const DashboardPage()),
        GoRoute(path: Routes.liveBookings, builder: (c, s) => const Scaffold(body: Text('LIVE BOOKINGS TAB'))),
      ]);
      return ProviderScope(
        overrides: [
          localSurveyRepositoryProvider.overrideWithValue(_Surveys([
            draft('1', SurveyType.inspection),
            draft('2', SurveyType.inspection),
            draft('3', SurveyType.inspection),
            draft('4', SurveyType.inspection),
            draft('5', SurveyType.inspection),
            draft('6', SurveyType.valuation),
          ])),
          syncStateProvider.overrideWith((ref) => _Sync()),
          liveBookingCountsProvider.overrideWith((ref) => live()),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    void phone(WidgetTester t) {
      t.view.physicalSize = const Size(412, 1000);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() {
        t.view.resetPhysicalSize();
        t.view.resetDevicePixelRatio();
      });
    }

    testWidgets('Total follows the live bookings of the selected segment', (tester) async {
      phone(tester);
      await tester.pumpWidget(host(() async => {HomeSegment.homeSurveys: 3, HomeSegment.valuations: 7}));
      await tester.pumpAndSettle();
      // 5 draft home surveys exist, but Total shows the 3 live bookings
      expect(find.text('3'), findsWidgets);
      expect(find.text('5'), findsNothing);

      await tester.tap(find.text('Valuations').first);
      await tester.pumpAndSettle();
      expect(find.text('7'), findsWidgets);
    });

    testWidgets('falls back to the survey count when bookings cannot be loaded', (tester) async {
      phone(tester);
      await tester.pumpWidget(host(() async => null));
      await tester.pumpAndSettle();
      expect(find.text('5'), findsWidgets); // 5 draft home surveys
    });

    testWidgets('tapping Total opens the Live Bookings tab', (tester) async {
      phone(tester);
      await tester.pumpWidget(host(() async => {HomeSegment.homeSurveys: 3, HomeSegment.valuations: 0}));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Total'));
      await tester.pumpAndSettle();
      expect(find.text('LIVE BOOKINGS TAB'), findsOneWidget);
    });
  });
}
