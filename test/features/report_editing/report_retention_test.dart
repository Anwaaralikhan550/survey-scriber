import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/report_editing/data/desktop_edit_store.dart';
import 'package:survey_scriber/features/report_editing/data/report_editing_api.dart';
import 'package:survey_scriber/features/report_editing/presentation/pages/desktop_editing_page.dart';
import 'package:survey_scriber/features/report_editing/presentation/providers/desktop_editing_controller.dart';
import 'package:survey_scriber/features/report_editing/presentation/providers/desktop_editing_providers.dart';
import 'package:survey_scriber/features/report_export/domain/models/report_document.dart';

const _survey = '8b0c1a52-3f7e-4d0a-9d52-1c6f1f0f2a10';

class _Vault implements LinkVault {
  @override
  Future<String?> read(String surveyId) async => null;
  @override
  Future<void> write(String surveyId, String? url) async {}
}

class _MemStore extends DesktopEditStore {
  _MemStore() : super(vault: _Vault());
  @override
  Future<DesktopEditRecord> read(String surveyId) async => const DesktopEditRecord();
}

class _Cloud extends ReportEditingApi {
  _Cloud() : super(Dio());

  String status = 'DRAFT';
  ReportRetentionInfo info = const ReportRetentionInfo(policy: 'DRAFT', deleteAt: null, daysLeft: 30, warningDays: [20, 25, 28]);
  bool unreadable = false;
  final holds = <String>[];

  @override
  Future<CloudReportInfo?> latest(String surveyId) async => CloudReportInfo(version: 2, status: status, updatedAt: DateTime(2026, 11, 19));

  @override
  Future<CurrentLink> currentLink(String surveyId) async => const CurrentLink(active: false);

  @override
  Future<ReportRetentionInfo?> retention(String surveyId) async {
    if (unreadable) throw const ReportEditingException(code: 'NETWORK', message: 'offline');
    return info;
  }

  @override
  Future<void> placeLegalHold(String surveyId, String reason) async {
    holds.add('place:$reason');
    info = ReportRetentionInfo(policy: info.policy, deleteAt: info.deleteAt, daysLeft: info.daysLeft, holdActive: true, holdReason: reason, holdByRole: 'MANAGER');
  }

  @override
  Future<void> releaseLegalHold(String surveyId, String reason) async {
    holds.add('release:$reason');
    info = ReportRetentionInfo(policy: info.policy, deleteAt: info.deleteAt, daysLeft: info.daysLeft, warningDays: info.warningDays, graceUntil: DateTime.utc(2026, 11, 26));
  }
}

ReportDocument _doc() => ReportDocument(
      reportType: ReportType.inspection,
      title: 'T',
      generatedAt: DateTime(2026, 11, 19),
      surveyMeta: const SurveyMeta(surveyId: _survey, title: 'T'),
      sections: const [],
    );

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<ByteData> bytes(String name) async => ByteData.sublistView(Uint8List.fromList(await File('$dir/$name').readAsBytes()));
  final roboto = FontLoader('Roboto');
  for (final f in ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']) {
    if (File('$dir/$f').existsSync()) roboto.addFont(bytes(f));
  }
  await roboto.load();
  final icons = FontLoader('MaterialIcons')..addFont(bytes('MaterialIcons-Regular.otf'));
  await icons.load();
}

final _shotKey = GlobalKey();

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final boundary = _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    final out = Directory('tmp/desktop-editing/proof')..createSync(recursive: true);
    await File('${out.path}/r8_$name.png').writeAsBytes(data.buffer.asUint8List());
  });
}

void main() {
  late _Cloud cloud;

  setUpAll(_loadFonts);
  setUp(() => cloud = _Cloud());

  group('the controller', () {
    DesktopEditingController make() => DesktopEditingController(surveyId: _survey, reportType: 'L2', api: cloud, store: _MemStore(), buildDocument: () async => _doc());

    test('reads the retention state with the report', () async {
      cloud.info = ReportRetentionInfo(policy: 'FINALISED', deleteAt: DateTime.utc(2027, 1, 18), daysLeft: 60, warningDays: const [30, 45, 55]);
      final c = make();
      addTearDown(c.dispose);
      await c.refresh();
      expect(c.state.retention!.policy, 'FINALISED');
      expect(c.state.retention!.daysLeft, 60);
    });

    test('when it cannot be read the page still works and shows no retention card', () async {
      cloud.unreadable = true;
      final c = make();
      addTearDown(c.dispose);
      await c.refresh();
      expect(c.state.hasCloudReport, isTrue);
      expect(c.state.retention, isNull);
      expect(c.state.error, isNull);
    });

    test('placing a legal hold sends the trimmed reason and shows the hold; releasing shows the grace', () async {
      final c = make();
      addTearDown(c.dispose);
      await c.refresh();
      await c.placeLegalHold('  Complaint ref 77  ');
      expect(cloud.holds, ['place:Complaint ref 77']);
      expect(c.state.retention!.holdActive, isTrue);
      expect(c.state.notice, contains('Legal hold placed'));
      await c.releaseLegalHold('Settled');
      expect(cloud.holds.last, 'release:Settled');
      expect(c.state.retention!.holdActive, isFalse);
      expect(c.state.retention!.graceUntil, DateTime.utc(2026, 11, 26));
    });

    test('a refused hold shows why', () async {
      final c = make();
      addTearDown(c.dispose);
      await c.refresh();
      cloud = _RefusingCloud();
      final c2 = DesktopEditingController(surveyId: _survey, reportType: 'L2', api: cloud, store: _MemStore(), buildDocument: () async => _doc());
      addTearDown(c2.dispose);
      await c2.refresh();
      await c2.placeLegalHold('Reason');
      expect(c2.state.error, contains('permission'));
    });
  });

  group('the page', () {
    Widget app({bool canHold = false}) => ProviderScope(
          overrides: [
            desktopEditingProvider.overrideWith(
              (ref, args) => DesktopEditingController(surveyId: args.surveyId, reportType: 'L2', api: cloud, store: _MemStore(), buildDocument: () async => _doc()),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF24566A), fontFamily: 'Roboto'),
            home: RepaintBoundary(key: _shotKey, child: DesktopEditingPage(surveyId: _survey, isValuation: false, surveyTitle: '54 Gas Lane, Dartford', canManageHold: canHold)),
          ),
        );

    Future<void> open(WidgetTester t, {bool canHold = false}) async {
      t.view.physicalSize = const Size(780, 1500);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      await t.pumpWidget(app(canHold: canHold));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(find.byKey(const Key('retention_title')), 300, scrollable: find.byType(Scrollable).first);
    }

    testWidgets('a draft: 30 days after the last change, reminders listed, archive does not extend it', (t) async {
      cloud.info = ReportRetentionInfo(policy: 'DRAFT', deleteAt: DateTime.utc(2026, 12, 19), daysLeft: 30, warningDays: const [20, 25, 28]);
      await open(t);
      expect(find.textContaining('This draft stays until 19 Dec 2026 (30 days left)'), findsOneWidget);
      expect(find.textContaining('opening it does not'), findsOneWidget);
      expect(find.textContaining('Reminders come on day 20, 25, 28.'), findsOneWidget);
      expect(find.byKey(const Key('retention_archive_note')), findsOneWidget);
      expect(find.byKey(const Key('place_hold')), findsNothing); // not an Admin or Manager
      await _shot(t, '01_draft');
    });

    testWidgets('a finalised report with reminders sent', (t) async {
      cloud.status = 'FINALISED';
      cloud.info = ReportRetentionInfo(policy: 'FINALISED', deleteAt: DateTime.utc(2027, 1, 18), daysLeft: 1, warningDays: const [30, 45, 55], warningsSent: const [30, 45, 55]);
      await open(t);
      expect(find.textContaining('This final report stays in SurveyScriber until 18 Jan 2027 (1 day left): 60 days after it was finalised.'), findsOneWidget);
      expect(find.textContaining('(sent: day 30, 45, 55)'), findsOneWidget);
      await _shot(t, '02_finalised_last_warning');
    });

    testWidgets('a review in progress is kept while the work goes on', (t) async {
      cloud.info = const ReportRetentionInfo(protectedReason: 'REVIEW_IN_PROGRESS');
      await open(t);
      expect(find.byKey(const Key('retention_protected')), findsOneWidget);
    });

    testWidgets('a legal hold is shown with its reason, and the date text is gone', (t) async {
      cloud.info = const ReportRetentionInfo(policy: 'FINALISED', holdActive: true, holdReason: 'Complaint to the ombudsman, ref 12', holdByRole: 'ADMIN');
      await open(t);
      expect(find.byKey(const Key('hold_banner')), findsOneWidget);
      expect(find.textContaining('Complaint to the ombudsman, ref 12'), findsOneWidget);
      expect(find.byKey(const Key('retention_text')), findsNothing);
      await _shot(t, '03_legal_hold');
    });

    testWidgets('Admin or Manager: Place legal hold needs a reason of 3 letters, then the hold shows; Release asks again', (t) async {
      cloud.info = ReportRetentionInfo(policy: 'FINALISED', deleteAt: DateTime.utc(2027, 1, 18), daysLeft: 40, warningDays: const [30, 45, 55]);
      await open(t, canHold: true);
      await t.scrollUntilVisible(find.byKey(const Key('place_hold')), 200, scrollable: find.byType(Scrollable).first);
      await t.ensureVisible(find.byKey(const Key('place_hold')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('place_hold')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('hold_dialog')), findsOneWidget);
      expect(t.widget<FilledButton>(find.byKey(const Key('hold_confirm'))).onPressed, isNull);
      await t.enterText(find.byKey(const Key('hold_reason')), 'ab');
      await t.pump();
      expect(t.widget<FilledButton>(find.byKey(const Key('hold_confirm'))).onPressed, isNull);
      await t.enterText(find.byKey(const Key('hold_reason')), 'Client complaint ref 77');
      await t.pump();
      await _shot(t, '04_hold_dialog');
      await t.tap(find.byKey(const Key('hold_confirm')));
      await t.pumpAndSettle();
      expect(cloud.holds, ['place:Client complaint ref 77']);
      expect(find.byKey(const Key('hold_banner'), skipOffstage: false), findsOneWidget);
      await t.scrollUntilVisible(find.byKey(const Key('release_hold')), 200, scrollable: find.byType(Scrollable).first);
      await t.ensureVisible(find.byKey(const Key('release_hold')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('release_hold')));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('hold_reason')), 'Dispute settled');
      await t.pump();
      await t.tap(find.byKey(const Key('hold_confirm')));
      await t.pumpAndSettle();
      expect(cloud.holds.last, 'release:Dispute settled');
      expect(find.byKey(const Key('retention_grace'), skipOffstage: false), findsOneWidget);
      expect(find.textContaining('kept until at least 26 Nov 2026', skipOffstage: false), findsOneWidget);
    });

    testWidgets('Cancel in the hold dialog sends nothing', (t) async {
      await open(t, canHold: true);
      await t.scrollUntilVisible(find.byKey(const Key('place_hold')), 200, scrollable: find.byType(Scrollable).first);
      await t.ensureVisible(find.byKey(const Key('place_hold')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('place_hold')));
      await t.pumpAndSettle();
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(cloud.holds, isEmpty);
    });
  });
}

class _RefusingCloud extends _Cloud {
  @override
  Future<void> placeLegalHold(String surveyId, String reason) async {
    throw const ReportEditingException(code: 'FORBIDDEN', message: 'You do not have permission for this action', status: 403);
  }
}
