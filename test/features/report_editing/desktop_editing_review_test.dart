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
  final values = <String, String>{};
  @override
  Future<String?> read(String surveyId) async => values[surveyId];
  @override
  Future<void> write(String surveyId, String? url) async => url == null ? values.remove(surveyId) : values[surveyId] = url;
}

class _Store extends DesktopEditStore {
  _Store(LinkVault v) : super(vault: v);
  DesktopEditRecord record = const DesktopEditRecord();
  @override
  Future<DesktopEditRecord> read(String surveyId) async => record;
  @override
  Future<void> saveUploaded(String surveyId, int version) async => record = DesktopEditRecord(appVersion: version, syncedSections: record.syncedSections);
  @override
  Future<void> saveSynced(String surveyId, int version, List<Map<String, dynamic>> sections) async => record = DesktopEditRecord(appVersion: version, syncedSections: sections);
  @override
  Future<void> clearEdits(String surveyId) async => record = DesktopEditRecord(appVersion: record.appVersion);
}

/// A cloud with the review rules of the backend, in memory.
class _Cloud extends ReportEditingApi {
  _Cloud() : super(Dio());
  int version = 3;
  String status = 'SUBMITTED_FOR_REVIEW';
  int? submitted = 3;
  int? reviewerApproved;
  int? ownerApproved;
  String? amendComment;
  bool offline = false;
  bool reviewFails = false;
  final calls = <String>[];
  final bodies = <Map<String, dynamic>>[];
  ReportEditingException? failNext;

  ReviewInfo _info() => ReviewInfo(
        status: status,
        version: version,
        submittedVersion: submitted,
        reviewerApprovalVersion: reviewerApproved,
        ownerApprovalVersion: ownerApproved,
        lastAmendment: amendComment == null ? null : ReviewEntry(decision: 'AMENDMENTS_REQUIRED', version: version, by: 'reviewer', createdAt: DateTime(2026, 11, 16, 10), invalidated: false, comment: amendComment),
        entries: const [],
      );

  void _guard() {
    if (offline) throw const ReportEditingException(code: 'NETWORK', message: 'offline');
    final f = failNext;
    if (f != null) {
      failNext = null;
      throw f;
    }
  }

  @override
  Future<CloudReportInfo?> latest(String surveyId) async {
    calls.add('latest');
    _guard();
    return CloudReportInfo(version: version, status: status, updatedAt: DateTime(2026, 11, 16));
  }

  @override
  Future<CurrentLink> currentLink(String surveyId) async => const CurrentLink(active: false);

  @override
  Future<ReviewInfo> review(String surveyId) async {
    calls.add('review');
    if (reviewFails) throw const ReportEditingException(code: 'SERVER', message: 'boom', status: 500);
    _guard();
    return _info();
  }

  @override
  Future<ReviewInfo> ownerApprove(String surveyId, {required int expectedVersion, String? comment}) async {
    calls.add('ownerApprove');
    bodies.add({'v': expectedVersion, 'comment': comment});
    _guard();
    if (expectedVersion != version) throw ReportEditingException(code: 'VERSION_CONFLICT', message: 'newer', status: 409, serverVersion: version);
    status = 'OWNER_FINAL_APPROVAL';
    ownerApproved = version;
    return _info();
  }

  @override
  Future<ReviewInfo> requestChanges(String surveyId, {required int expectedVersion, required String comment}) async {
    calls.add('requestChanges');
    bodies.add({'v': expectedVersion, 'comment': comment});
    _guard();
    status = 'AMENDMENTS_REQUIRED';
    amendComment = comment;
    reviewerApproved = null;
    return _info();
  }

  @override
  Future<ReviewInfo> resetReview(String surveyId, {required int expectedVersion}) async {
    calls.add('reset');
    bodies.add({'v': expectedVersion});
    _guard();
    status = 'DRAFT';
    reviewerApproved = null;
    ownerApproved = null;
    submitted = null;
    return _info();
  }

  @override
  Future<SyncedReport> sync(String surveyId) async => SyncedReport(version: version, status: status, sections: const []);
}

ReportDocument _doc() => ReportDocument(
      reportType: ReportType.inspection,
      title: 'T',
      generatedAt: DateTime(2026, 11, 16),
      surveyMeta: const SurveyMeta(surveyId: _survey, title: 'T'),
      sections: const [],
    );

final _shotKey = GlobalKey();

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

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.runAsync(() async {
    final boundary = _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    final out = Directory('tmp/desktop-editing/proof')..createSync(recursive: true);
    await File('${out.path}/d5_$name.png').writeAsBytes(data.buffer.asUint8List());
  });
}

void main() {
  late _Cloud cloud;
  late _Store store;
  late DesktopEditingController c;

  setUpAll(_loadFonts);

  setUp(() {
    cloud = _Cloud();
    store = _Store(_Vault())..record = const DesktopEditRecord(appVersion: 3);
    c = DesktopEditingController(surveyId: _survey, reportType: 'L2', api: cloud, store: store, buildDocument: () async => _doc());
  });
  tearDown(() => c.dispose());

  group('API', () {
    test('review view is read with versions, approvals and the last request for changes', () {
      final r = ReviewInfo.fromJson({
        'status': 'AMENDMENTS_REQUIRED',
        'version': 5,
        'submittedVersion': 4,
        'reviewerApproval': null,
        'ownerApproval': null,
        'lastAmendmentRequest': {'decision': 'AMENDMENTS_REQUIRED', 'version': 5, 'by': 'reviewer', 'createdAt': '2026-11-16T10:00:00.000Z', 'invalidated': false, 'comment': 'Check the roof'},
        'reviews': [
          {'decision': 'SUBMITTED', 'version': 4, 'by': 'reviewer', 'createdAt': '2026-11-16T09:00:00.000Z', 'invalidated': false, 'comment': null},
        ],
      });
      expect(r.status, 'AMENDMENTS_REQUIRED');
      expect(r.submittedVersion, 4);
      expect(r.reviewerApprovalVersion, isNull);
      expect(r.lastAmendment!.comment, 'Check the roof');
      expect(r.entries.single.decision, 'SUBMITTED');
      expect(r.finalised, isFalse);
      expect(const ReviewInfo.draft(2).status, 'DRAFT');
    });
  });

  group('controller', () {
    test('a draft report needs no extra request; a later status reads the review', () async {
      cloud.status = 'DRAFT';
      await c.refresh();
      expect(c.state.review!.status, 'DRAFT');
      expect(cloud.calls, ['latest']);
      cloud.calls.clear();
      cloud.status = 'SUBMITTED_FOR_REVIEW';
      await c.refresh();
      expect(cloud.calls, ['latest', 'review']);
      expect(c.state.review!.submittedVersion, 3);
    });

    test('a failing review read does not break the screen: the cheap status is shown', () async {
      cloud
        ..status = 'UNDER_REVIEW'
        ..reviewFails = true;
      await c.refresh();
      expect(c.state.error, isNull);
      expect(c.state.review!.status, 'UNDER_REVIEW');
      expect(c.state.cloudVersion, 3);
    });

    test('final approval is for the exact version this phone has, and the screen follows', () async {
      await c.refresh();
      await c.approveFinal();
      expect(c.state.error, isNull, reason: c.state.error);
      expect(cloud.bodies.single['v'], 3);
      expect(c.state.review!.status, 'OWNER_FINAL_APPROVAL');
      expect(c.state.review!.ownerApprovalVersion, 3);
      expect(c.state.notice, 'Final approval given for version 3.');
    });

    test('the owner must have read what is approved: with newer cloud edits nothing is sent', () async {
      await c.refresh();
      cloud.version = 4; // a colleague saved
      await c.refresh();
      expect(c.state.updateAvailable, isTrue);
      cloud.calls.clear();
      await c.approveFinal();
      expect(c.state.error, contains('Synchronise first'));
      expect(cloud.calls.where((e) => e == 'ownerApprove'), isEmpty);
      await c.requestChanges('x');
      await c.resetReview();
      expect(cloud.calls.where((e) => e != 'latest' && e != 'review'), isEmpty);
    });

    test('if the cloud moves just before the approval, the server refuses and the owner is told to Synchronise', () async {
      await c.refresh();
      cloud.version = 4; // moved after the last refresh: the phone does not know yet
      await c.approveFinal();
      expect(c.state.error, contains('Synchronise first'));
      expect(cloud.status, 'SUBMITTED_FOR_REVIEW');
    });

    test('sending back stores the comment; the report goes to Changes requested', () async {
      await c.refresh();
      await c.requestChanges('Please re-check the roof sentence');
      expect(cloud.bodies.single['comment'], 'Please re-check the roof sentence');
      expect(c.state.review!.status, 'AMENDMENTS_REQUIRED');
      expect(c.state.review!.lastAmendment!.comment, 'Please re-check the roof sentence');
      expect(c.state.notice, 'Sent back with your comment.');
    });

    test('Back to Draft withdraws every approval', () async {
      cloud
        ..status = 'OWNER_FINAL_APPROVAL'
        ..ownerApproved = 3
        ..reviewerApproved = 3;
      await c.refresh();
      expect(c.state.review!.ownerApproved, isTrue);
      await c.resetReview();
      expect(c.state.review!.status, 'DRAFT');
      expect(c.state.review!.ownerApprovalVersion, isNull);
    });

    test('a step that is no longer possible is explained and the status refreshed', () async {
      await c.refresh();
      cloud.failNext = const ReportEditingException(code: 'INVALID_STATE', message: 'That is not possible while the report is draft.', status: 409);
      cloud.status = 'DRAFT';
      await c.requestChanges('x');
      expect(c.state.error, contains('not possible while the report is draft'));
      expect(c.state.error, contains('refreshed'));
      expect(c.state.review!.status, 'DRAFT');
    });

    test('offline: the owner action explains why and nothing changes', () async {
      await c.refresh();
      cloud.offline = true;
      await c.approveFinal();
      expect(c.state.error, contains('No connection'));
      expect(c.state.review!.status, 'SUBMITTED_FOR_REVIEW');
    });

    test('a browser edit after approval shows up as the approval no longer standing', () async {
      cloud
        ..status = 'OWNER_FINAL_APPROVAL'
        ..ownerApproved = 3;
      await c.refresh();
      expect(c.state.review!.ownerApproved, isTrue);
      cloud
        ..version = 4
        ..status = 'SUBMITTED_FOR_REVIEW'
        ..ownerApproved = null;
      await c.refresh();
      expect(c.state.review!.status, 'SUBMITTED_FOR_REVIEW');
      expect(c.state.review!.ownerApprovalVersion, isNull);
      expect(c.state.updateAvailable, isTrue);
    });
  });

  group('screen', () {
    Widget app() => ProviderScope(
          overrides: [
            desktopEditingProvider.overrideWith(
              (ref, args) => DesktopEditingController(surveyId: args.surveyId, reportType: 'L2', api: cloud, store: store, buildDocument: () async => _doc()),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF24566A), fontFamily: 'Roboto'),
            home: RepaintBoundary(key: _shotKey, child: const DesktopEditingPage(surveyId: _survey, isValuation: false, surveyTitle: '54 Gas Lane, Dartford')),
          ),
        );

    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(780, 1800);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
    }

    testWidgets('shows the status, what it means, the versions and the owner buttons', (tester) async {
      cloud.reviewerApproved = null;
      await open(tester);
      expect(find.byKey(const Key('review_card')), findsOneWidget);
      expect(find.text('Submitted for review'), findsOneWidget);
      expect(find.textContaining('Submitted for review at version 3'), findsOneWidget);
      expect(find.byKey(const Key('approve_final')), findsOneWidget);
      expect(find.byKey(const Key('request_changes')), findsOneWidget);
      expect(find.byKey(const Key('reset_review')), findsOneWidget);
      expect(find.byKey(const Key('approve_needs_sync')), findsNothing);
      expect(tester.widget<FilledButton>(find.byKey(const Key('approve_final'))).onPressed, isNotNull);
      await _shot(tester, '10_phone_submitted');
    });

    testWidgets('a draft offers only the final approval (no reviewer is needed)', (tester) async {
      cloud.status = 'DRAFT';
      cloud.submitted = null;
      await open(tester);
      expect(find.textContaining('Nobody has asked for a review yet'), findsOneWidget);
      expect(find.byKey(const Key('approve_final')), findsOneWidget);
      expect(find.byKey(const Key('request_changes')), findsNothing);
      expect(find.byKey(const Key('reset_review')), findsNothing);
    });

    testWidgets('final approval asks first, names the version, then shows the result', (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const Key('approve_final')));
      await tester.pumpAndSettle();
      expect(find.text('Give final approval to version 3?'), findsOneWidget);
      await _shot(tester, '11_phone_approve_dialog');
      await tester.tap(find.text('Not yet'));
      await tester.pumpAndSettle();
      expect(cloud.calls.where((e) => e == 'ownerApprove'), isEmpty);
      await tester.tap(find.byKey(const Key('approve_final')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_approve')));
      await tester.pumpAndSettle();
      expect(find.text('Final approval given'), findsOneWidget);
      expect(find.textContaining('You gave final approval to version 3'), findsOneWidget);
      expect(find.byKey(const Key('approve_final')), findsNothing);
      expect(find.byKey(const Key('notice_banner')), findsOneWidget);
      await _shot(tester, '12_phone_approved');
    });

    testWidgets('sending back needs a comment, and the comment is shown with the new status', (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const Key('request_changes')));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(find.byKey(const Key('confirm_changes'))).onPressed, isNull);
      await tester.enterText(find.byKey(const Key('changes_comment')), '   ');
      await tester.pump();
      expect(tester.widget<FilledButton>(find.byKey(const Key('confirm_changes'))).onPressed, isNull);
      await tester.enterText(find.byKey(const Key('changes_comment')), 'Please re-check the roof wording.');
      await tester.pump();
      await _shot(tester, '13_phone_send_back_dialog');
      await tester.tap(find.byKey(const Key('confirm_changes')));
      await tester.pumpAndSettle();
      expect(find.text('Changes requested'), findsOneWidget);
      expect(find.byKey(const Key('review_amend')), findsOneWidget);
      expect(find.textContaining('Please re-check the roof wording.'), findsOneWidget);
      await _shot(tester, '14_phone_changes_requested');
    });

    testWidgets('Back to Draft asks first and withdraws the approvals', (tester) async {
      cloud
        ..status = 'OWNER_FINAL_APPROVAL'
        ..ownerApproved = 3;
      await open(tester);
      expect(find.text('Final approval given'), findsOneWidget);
      await tester.tap(find.byKey(const Key('reset_review')));
      await tester.pumpAndSettle();
      expect(find.text('Start the review again?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm_reset')));
      await tester.pumpAndSettle();
      expect(find.text('Draft'), findsOneWidget);
      expect(find.byKey(const Key('approve_final')), findsOneWidget);
    });

    testWidgets('with newer edits in the cloud the owner buttons are off and the page says why', (tester) async {
      await open(tester);
      cloud.version = 4;
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('approve_needs_sync')), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byKey(const Key('approve_final'))).onPressed, isNull);
      expect(tester.widget<OutlinedButton>(find.byKey(const Key('request_changes'))).onPressed, isNull);
      expect(find.textContaining('this phone has 3'), findsOneWidget);
      await _shot(tester, '15_phone_must_sync');
    });

    testWidgets('a finalised report shows the status and no buttons', (tester) async {
      cloud.status = 'FINALISED';
      await open(tester);
      expect(find.text('Finalised'), findsWidgets);
      expect(find.byKey(const Key('approve_final')), findsNothing);
      expect(find.byKey(const Key('request_changes')), findsNothing);
      expect(find.byKey(const Key('reset_review')), findsNothing);
    });
  });
}
