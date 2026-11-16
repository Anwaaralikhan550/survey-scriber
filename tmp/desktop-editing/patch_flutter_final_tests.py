p = 'E:/survey-scriber/test/features/report_editing/desktop_editing_review_test.dart'
t = open(p, encoding='utf-8', newline='').read()
crlf = '\r\n' in t
if crlf:
    t = t.replace('\r\n', '\n')


def rep(a, b):
    global t
    assert a in t, a[:70]
    t = t.replace(a, b, 1)


rep("  bool reviewFails = false;\n", "  bool reviewFails = false;\n  int cycle = 1;\n  int? finalVersion;\n  DateTime? finalisedAt;\n  List<FinalRound> rounds = [];\n")
rep("        entries: const [],\n      );", "        entries: const [],\n        cycle: cycle,\n        finalVersion: finalVersion,\n        finalisedAt: finalisedAt,\n        rounds: rounds,\n      );")
rep("  @override\n  Future<ReviewInfo> requestChanges(", """  @override
  Future<void> finalise(String surveyId, {required int expectedVersion}) async {
    calls.add('finalise');
    bodies.add({'v': expectedVersion});
    _guard();
    if (expectedVersion != version) throw ReportEditingException(code: 'VERSION_CONFLICT', message: 'newer', status: 409, serverVersion: version);
    status = 'FINALISED';
    finalVersion = version;
    finalisedAt = DateTime(2026, 11, 16, 12);
    rounds = [FinalRound(cycle: cycle, version: version, finalisedAt: finalisedAt!)];
  }

  @override
  Future<void> reopen(String surveyId, {required int expectedVersion, required String reason}) async {
    calls.add('reopen');
    bodies.add({'v': expectedVersion, 'reason': reason});
    _guard();
    final first = rounds.first;
    rounds = [FinalRound(cycle: first.cycle, version: first.version, finalisedAt: first.finalisedAt, reopenedAt: DateTime(2026, 11, 17, 9), reopenReason: reason)];
    cycle += 1;
    status = 'DRAFT';
    ownerApproved = null;
    reviewerApproved = null;
    submitted = null;
  }

  @override
  Future<ReviewInfo> requestChanges(""")

rep("  group('screen', () {", """  group('finalise and reopen: controller', () {
    setUp(() {
      cloud
        ..status = 'OWNER_FINAL_APPROVAL'
        ..ownerApproved = 3;
    });

    test('the owner finalises exactly the version this phone has; the screen shows it locked and the link gone', () async {
      await c.refresh();
      await c.finaliseReport();
      expect(c.state.error, isNull, reason: c.state.error);
      expect(cloud.bodies.single['v'], 3);
      expect(c.state.review!.status, 'FINALISED');
      expect(c.state.review!.finalVersion, 3);
      expect(c.state.finalised, isTrue);
      expect(c.state.linkActive, isFalse);
      expect(c.state.notice, contains('The report is final'));
      expect(await store.vault.read(_survey), isNull);
    });

    test('with newer cloud edits nothing is sent; the owner is told to Synchronise', () async {
      await c.refresh();
      cloud.version = 4;
      await c.refresh();
      cloud.calls.clear();
      await c.finaliseReport();
      expect(c.state.error, contains('Synchronise first'));
      expect(cloud.calls.where((e) => e == 'finalise'), isEmpty);
      await c.reopenReport('why not');
      expect(cloud.calls.where((e) => e == 'reopen'), isEmpty);
    });

    test('if the server says the approval no longer stands, the message is shown and the status refreshed', () async {
      await c.refresh();
      cloud.status = 'SUBMITTED_FOR_REVIEW';
      cloud.failNext = const ReportEditingException(code: 'INVALID_STATE', message: 'The final approval no longer stands for this version. Approve it again.', status: 409);
      await c.finaliseReport();
      expect(c.state.error, contains('no longer stands'));
      expect(c.state.review!.status, 'SUBMITTED_FOR_REVIEW');
    });

    test('reopen sends the trimmed reason and the version; the report is a draft in round 2 with the earlier final kept', () async {
      cloud.status = 'FINALISED';
      cloud.rounds = [FinalRound(cycle: 1, version: 3, finalisedAt: DateTime(2026, 11, 16, 12))];
      await c.refresh();
      await c.reopenReport('  Client asked for a change  ');
      expect(c.state.error, isNull, reason: c.state.error);
      expect(cloud.bodies.single, {'v': 3, 'reason': 'Client asked for a change'});
      expect(c.state.review!.status, 'DRAFT');
      expect(c.state.review!.cycle, 2);
      expect(c.state.review!.rounds.single.reopenReason, 'Client asked for a change');
      expect(c.state.finalised, isFalse);
    });

    test('the history of rounds is read from the review answer', () {
      final r = ReviewInfo.fromJson({
        'status': 'DRAFT',
        'version': 5,
        'reviews': [],
        'finalisation': {
          'cycle': 2,
          'finalVersion': 3,
          'finalisedAt': '2026-11-16T12:00:00.000Z',
          'history': [
            {'cycle': 1, 'version': 3, 'finalisedAt': '2026-11-16T12:00:00.000Z', 'reopenedAt': '2026-11-17T09:00:00.000Z', 'reopenReason': 'Roof wording'},
          ],
        },
      });
      expect(r.cycle, 2);
      expect(r.finalVersion, 3);
      expect(r.rounds.single.reopenReason, 'Roof wording');
      // a link holder's view has no finalisation block
      expect(ReviewInfo.fromJson({'status': 'DRAFT', 'version': 1}).cycle, 1);
    });
  });

  group('screen', () {""")

idx = t.rindex("  });\n}")
t = t[:idx] + """
    testWidgets('an approved report offers Finalise; it names the version, then shows the final card without the link card', (tester) async {
      cloud
        ..status = 'OWNER_FINAL_APPROVAL'
        ..ownerApproved = 3;
      await open(tester);
      expect(find.byKey(const Key('finalise_report')), findsOneWidget);
      expect(find.byKey(const Key('final_card')), findsNothing);
      await _shot(tester, '16_phone_ready_to_finalise');
      await tester.tap(find.byKey(const Key('finalise_report')));
      await tester.pumpAndSettle();
      expect(find.text('Finalise version 3?'), findsOneWidget);
      await _shot(tester, '17_phone_finalise_dialog');
      await tester.tap(find.text('Not yet'));
      await tester.pumpAndSettle();
      expect(cloud.calls.where((e) => e == 'finalise'), isEmpty);
      await tester.tap(find.byKey(const Key('finalise_report')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_finalise')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('final_card')), findsOneWidget);
      expect(find.textContaining('Version 3 is final, finalised on 16 Nov 2026'), findsOneWidget);
      expect(find.byKey(const Key('generate_link')), findsNothing);
      expect(find.byKey(const Key('finalise_report')), findsNothing);
      expect(find.byKey(const Key('approve_final')), findsNothing);
      expect(find.byKey(const Key('export_final')), findsOneWidget);
      expect(find.byKey(const Key('reopen_report')), findsOneWidget);
      await _shot(tester, '18_phone_finalised');
    });

    testWidgets('Export opens the existing PDF / Word sheet for this report', (tester) async {
      cloud
        ..status = 'FINALISED'
        ..finalVersion = 3
        ..finalisedAt = DateTime(2026, 11, 16, 12);
      await open(tester);
      expect(tester.widget<FilledButton>(find.byKey(const Key('export_final'))).onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('export_final')));
      await tester.pumpAndSettle();
      expect(find.byType(ExportBottomSheet), findsOneWidget);
    });

    testWidgets('Reopen asks why (3 letters at least), then shows the draft and the earlier final version', (tester) async {
      cloud
        ..status = 'FINALISED'
        ..finalVersion = 3
        ..finalisedAt = DateTime(2026, 11, 16, 12)
        ..rounds = [FinalRound(cycle: 1, version: 3, finalisedAt: DateTime(2026, 11, 16, 12))];
      await open(tester);
      await tester.tap(find.byKey(const Key('reopen_report')));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(find.byKey(const Key('confirm_reopen'))).onPressed, isNull);
      await tester.enterText(find.byKey(const Key('reopen_reason')), 'ab');
      await tester.pump();
      expect(tester.widget<FilledButton>(find.byKey(const Key('confirm_reopen'))).onPressed, isNull);
      await tester.enterText(find.byKey(const Key('reopen_reason')), 'Client asked for a change to the roof wording');
      await tester.pump();
      await _shot(tester, '19_phone_reopen_dialog');
      await tester.tap(find.byKey(const Key('confirm_reopen')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('final_card')), findsNothing);
      expect(find.text('Draft'), findsOneWidget);
      expect(find.byKey(const Key('earlier_rounds')), findsOneWidget);
      expect(find.textContaining('Client asked for a change to the roof wording'), findsOneWidget);
      expect(find.byKey(const Key('generate_link')), findsOneWidget);
      await _shot(tester, '20_phone_reopened');
    });

    testWidgets('final card with newer cloud edits: export and reopen are off and the page says why', (tester) async {
      cloud.status = 'FINALISED';
      await open(tester);
      cloud.version = 4;
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('final_needs_sync')), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byKey(const Key('export_final'))).onPressed, isNull);
      expect(tester.widget<OutlinedButton>(find.byKey(const Key('reopen_report'))).onPressed, isNull);
    });
""" + t[idx:]
rep("import 'package:survey_scriber/features/report_export/domain/models/report_document.dart';", "import 'package:survey_scriber/features/report_export/domain/models/report_document.dart';\nimport 'package:survey_scriber/features/report_export/presentation/widgets/export_bottom_sheet.dart';")
if crlf:
    t = t.replace('\n', '\r\n')
open(p, 'w', encoding='utf-8', newline='').write(t)
print('ok')
