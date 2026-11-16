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

class _MemoryVault implements LinkVault {
  final values = <String, String>{};
  @override
  Future<String?> read(String surveyId) async => values[surveyId];
  @override
  Future<void> write(String surveyId, String? url) async => url == null ? values.remove(surveyId) : values[surveyId] = url;
}

/// File access never completes inside a widget test's fake clock, so the page tests keep the record in memory.
class _MemStore extends DesktopEditStore {
  _MemStore(LinkVault v) : super(vault: v);
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

class _Cloud extends ReportEditingApi {
  _Cloud() : super(Dio());
  int? version;
  String? linkId;
  DateTime? expires;
  bool offline = false;
  bool conflictOnUpload = false;
  List<Map<String, dynamic>> content = [];

  void _net() {
    if (offline) throw const ReportEditingException(code: 'NETWORK', message: 'offline');
  }

  @override
  Future<CloudReportInfo> uploadSnapshot(String surveyId, {int? baseVersion, required String reportType, required List<Map<String, dynamic>> sections}) async {
    _net();
    if (conflictOnUpload) throw ReportEditingException(code: 'VERSION_CONFLICT', message: 'newer', status: 409, serverVersion: version);
    version = (version ?? 0) + 1;
    content = sections;
    return CloudReportInfo(version: version!, status: 'DRAFT', updatedAt: DateTime.now());
  }

  @override
  Future<EditLinkInfo> createLink(String surveyId) async {
    _net();
    linkId = 'l1';
    expires = DateTime.now().add(const Duration(hours: 72));
    return EditLinkInfo(linkId: 'l1', url: 'https://editor.surveyscriber.com/open/Xk3vQ9m2Tt8w0aBcDeFgHiJkLmNoPqRsTuVwXyZ12345', expiresAt: expires!);
  }

  @override
  Future<CurrentLink> currentLink(String surveyId) async {
    _net();
    return linkId != null && expires!.isAfter(DateTime.now()) ? CurrentLink(active: true, linkId: linkId, expiresAt: expires) : const CurrentLink(active: false);
  }

  @override
  Future<void> cancelLink(String surveyId, String id) async {
    _net();
    linkId = null;
  }

  @override
  Future<CloudReportInfo?> latest(String surveyId) async {
    _net();
    return version == null ? null : CloudReportInfo(version: version!, status: 'DRAFT', updatedAt: DateTime.now());
  }

  @override
  Future<SyncedReport> sync(String surveyId) async {
    _net();
    return SyncedReport(version: version!, status: 'DRAFT', sections: content);
  }
}

ReportDocument _doc() => ReportDocument(
      reportType: ReportType.inspection,
      title: 'T',
      generatedAt: DateTime(2026, 11, 16),
      surveyMeta: const SurveyMeta(surveyId: _survey, title: 'T'),
      sections: const [
        ReportSection(key: 'E', title: 'Outside', description: '', displayOrder: 0, screens: [
          ReportScreen(screenId: 'roof', title: 'Roof', fields: [], phrases: ['The roof is tiled.']),
        ]),
      ],
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
    await File('${out.path}/d3_$name.png').writeAsBytes(data.buffer.asUint8List());
  });
}

void main() {
  late _Cloud cloud;
  late DesktopEditStore store;
  late _MemoryVault vault;
  late List<MethodCall> clipboardCalls;

  setUpAll(_loadFonts);

  setUp(() async {
    cloud = _Cloud();
    vault = _MemoryVault();
    store = _MemStore(vault);
    clipboardCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      clipboardCalls.add(call);
      return null;
    });
  });

  Widget app() => ProviderScope(
        overrides: [
          desktopEditingProvider.overrideWith(
            (ref, args) => DesktopEditingController(surveyId: args.surveyId, reportType: 'L2', api: cloud, store: store, buildDocument: () async => _doc()),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF24566A), fontFamily: 'Roboto'),
          home: RepaintBoundary(
            key: _shotKey,
            child: const DesktopEditingPage(surveyId: _survey, isValuation: false, surveyTitle: '54 Gas Lane, Dartford'),
          ),
        ),
      );

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(780, 1500);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
  }

  testWidgets('a new survey: nothing sent, Generate link is offered, Synchronise is off', (tester) async {
    await open(tester);
    expect(find.text('Not sent yet'), findsNWidgets(2));
    expect(find.text('Generate link'), findsOneWidget);
    expect(find.byKey(const Key('copy_link')), findsNothing);
    expect(tester.widget<FilledButton>(find.byKey(const Key('synchronise'))).onPressed, isNull);
    await _shot(tester, '01_new_survey');
  });

  testWidgets('Generate link shows the address with Copy, Share, Send my latest changes and Cancel, and the versions', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('generate_link')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('link_url')), findsOneWidget);
    expect(find.textContaining('/open/Xk3vQ9m2'), findsOneWidget);
    expect(find.byKey(const Key('copy_link')), findsOneWidget);
    expect(find.byKey(const Key('share_link')), findsOneWidget);
    expect(find.byKey(const Key('cancel_link')), findsOneWidget);
    expect(find.text('Version 1'), findsNWidgets(2));
    expect(find.textContaining('left'), findsOneWidget);
    expect(find.byKey(const Key('notice_banner')), findsOneWidget);
    await _shot(tester, '02_link_live');
  });

  testWidgets('Copy puts the link on the clipboard', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('generate_link')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('copy_link')));
    await tester.pumpAndSettle();
    final set = clipboardCalls.where((c) => c.method == 'Clipboard.setData');
    expect(set, hasLength(1));
    expect((set.single.arguments as Map)['text'], contains('https://editor.surveyscriber.com/open/'));
    expect(find.text('Link copied'), findsOneWidget);
  });

  testWidgets('a newer version from the editor shows the update banner; Synchronise clears it and shows the edited wording', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('generate_link')));
    await tester.pumpAndSettle();
    cloud.version = 2;
    cloud.content = [
      {
        'id': 'a1111111-1111-4111-8111-111111111111',
        'key': 'E/roof',
        'title': 'Roof',
        'blocks': [
          {'id': 'b1111111-1111-4111-8111-111111111111', 'type': 'paragraph', 'role': 'phrase', 'text': 'Edited.'},
        ],
      },
    ];
    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('update_banner')), findsOneWidget);
    expect(find.textContaining('A newer version (2)'), findsOneWidget);
    expect(find.text('Synchronise (version 2)'), findsOneWidget);
    await _shot(tester, '03_update_available');
    await tester.tap(find.byKey(const Key('synchronise')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('update_banner')), findsNothing);
    expect(find.text('Your PDF and Word reports use the edited wording.'), findsOneWidget);
    expect(find.textContaining('Synchronised'), findsOneWidget);
    await _shot(tester, '04_synchronised');
    await tester.scrollUntilVisible(find.byKey(const Key('discard_edits')), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('discard_edits')));
    await tester.pumpAndSettle();
    expect(find.text('Remove the edited wording?'), findsOneWidget);
    await _shot(tester, '05_discard_dialog');
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('discard_edits')), findsNothing);
  });

  testWidgets('Cancel link asks first, then ends the link and offers Generate link again', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('generate_link')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('cancel_link')));
    await tester.tap(find.byKey(const Key('cancel_link')));
    await tester.pumpAndSettle();
    expect(find.text('Cancel the link?'), findsOneWidget);
    await _shot(tester, '06_cancel_dialog');
    await tester.tap(find.text('Keep link'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('link_url')), findsOneWidget);
    await tester.tap(find.byKey(const Key('cancel_link')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel link'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('link_url')), findsNothing);
    expect(find.byKey(const Key('generate_link')), findsOneWidget);
    expect(vault.values, isEmpty);
  });

  testWidgets('when the cloud has newer edits, Generate link refuses with the reason and sends nothing', (tester) async {
    cloud.version = 3;
    await store.saveUploaded(_survey, 1);
    await open(tester);
    expect(find.byKey(const Key('update_banner')), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('generate_link')), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('generate_link')));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 2000));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('error_banner')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('error_banner')), matching: find.textContaining('Synchronise first')), findsOneWidget);
    expect(find.byKey(const Key('link_url')), findsNothing);
    await _shot(tester, '07_refused_stale');
  });

  testWidgets('offline: the screen says so, and an action explains the failure', (tester) async {
    cloud.offline = true;
    await open(tester);
    expect(find.textContaining('You are offline'), findsOneWidget);
    await tester.tap(find.byKey(const Key('generate_link')));
    await tester.pumpAndSettle();
    expect(find.textContaining('No connection to SurveyScriber'), findsOneWidget);
    await _shot(tester, '08_offline');
  });

  testWidgets('a link made on another phone: live, but its address is missing here', (tester) async {
    cloud.version = 1;
    cloud.linkId = 'other';
    cloud.expires = DateTime.now().add(const Duration(hours: 10));
    await store.saveUploaded(_survey, 1);
    await open(tester);
    expect(find.byKey(const Key('address_missing')), findsOneWidget);
    expect(find.byKey(const Key('copy_link')), findsNothing);
    expect(find.byKey(const Key('cancel_link')), findsOneWidget);
    await _shot(tester, '09_address_missing');
  });
}
