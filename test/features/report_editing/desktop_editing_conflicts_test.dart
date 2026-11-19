// Remote Editor v1.4 R5, phone side: a screen changed on the computer AND on the phone since they last agreed is decided by the
// owner (never overwritten silently); changes the cloud refused are announced and sent again after a synchronise.
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
import 'package:survey_scriber/features/report_editing/domain/report_blocks_mapper.dart';
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

/// File access never completes inside a widget test's fake clock, so the record is kept in memory.
class _MemStore extends DesktopEditStore {
  _MemStore(LinkVault v) : super(vault: v);
  DesktopEditRecord record = const DesktopEditRecord();
  @override
  Future<DesktopEditRecord> read(String surveyId) async => record;
  @override
  Future<void> saveUploaded(String surveyId, int version, {Map<String, String>? baseline}) async => record = record.copyWith(appVersion: version, baseline: baseline);
  @override
  Future<void> saveSynced(String surveyId, int version, List<Map<String, dynamic>> sections, {Map<String, String>? baseline}) async =>
      record = record.copyWith(appVersion: version, syncedSections: sections, baseline: baseline, kept: const []);
  @override
  Future<void> clearEdits(String surveyId) async => record = record.copyWith(syncedSections: null, kept: const []);
  @override
  Future<void> saveKept(String surveyId, List<String> screenKeys) async => record = record.copyWith(kept: screenKeys);
}

class _Cloud extends ReportEditingApi {
  _Cloud() : super(Dio());
  int? version;
  String? linkId;
  List<Map<String, dynamic>> content = [];

  @override
  Future<CloudReportInfo> uploadSnapshot(String surveyId, {int? baseVersion, required String reportType, required List<Map<String, dynamic>> sections}) async {
    version = (version ?? 0) + 1;
    content = sections;
    return CloudReportInfo(version: version!, status: 'DRAFT', updatedAt: DateTime.now());
  }

  @override
  Future<EditLinkInfo> createLink(String surveyId) async {
    linkId = 'l1';
    return EditLinkInfo(linkId: 'l1', url: 'https://editor.surveyscriber.com/open/Xk3vQ9m2Tt8w0aBcDeFgHiJkLmNoPqRsTuVwXyZ12345', expiresAt: DateTime.now().add(const Duration(hours: 72)));
  }

  @override
  Future<CurrentLink> currentLink(String surveyId) async =>
      linkId == null ? const CurrentLink(active: false) : CurrentLink(active: true, linkId: linkId, expiresAt: DateTime.now().add(const Duration(hours: 70)));

  @override
  Future<CloudReportInfo?> latest(String surveyId) async => version == null ? null : CloudReportInfo(version: version!, status: 'DRAFT', updatedAt: DateTime.now());

  @override
  Future<SyncedReport> sync(String surveyId) async => SyncedReport(version: version!, status: 'DRAFT', sections: content);
}

ReportDocument _doc(String roof) => ReportDocument(
      reportType: ReportType.inspection,
      title: 'T',
      generatedAt: DateTime(2026, 11, 19),
      surveyMeta: const SurveyMeta(surveyId: _survey, title: 'T'),
      sections: [
        ReportSection(key: 'E', title: 'Outside', description: '', displayOrder: 0, screens: [
          ReportScreen(screenId: 'roof', title: 'Roof', fields: const [], phrases: [roof]),
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
    final out = Directory('tmp/client-edits-2026-11-19/proof')..createSync(recursive: true);
    await File('${out.path}/r5_$name.png').writeAsBytes(data.buffer.asUint8List());
  });
}

void main() {
  late _Cloud cloud;
  late _MemStore store;
  var phoneRoof = 'The roof is tiled.';
  var held = 0;
  var released = 0;

  setUpAll(_loadFonts);

  setUp(() {
    cloud = _Cloud();
    store = _MemStore(_MemoryVault());
    phoneRoof = 'The roof is tiled.';
    held = 0;
    released = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  });

  Widget app() => ProviderScope(
        overrides: [
          desktopEditingProvider.overrideWith(
            (ref, args) => DesktopEditingController(
              surveyId: args.surveyId,
              reportType: 'L2',
              api: cloud,
              store: store,
              buildDocument: () async => _doc(phoneRoof),
              heldBack: () async => held,
              releaseHeldBack: () async {
                released++;
                held = 0;
              },
            ),
          ),
        ],
        // The boundary is above the app so dialogs are in the picture too.
        child: RepaintBoundary(
          key: _shotKey,
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF24566A), fontFamily: 'Roboto'),
            home: const DesktopEditingPage(surveyId: _survey, isValuation: false, surveyTitle: '54 Gas Lane, Dartford'),
          ),
        ),
      );

  /// The report was sent (baseline = "The roof is tiled."), then the browser saved a new roof text as version 2.
  Future<void> afterBrowserEdit(WidgetTester tester, {required String browserRoof}) async {
    tester.view.physicalSize = const Size(780, 1500);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('generate_link')));
    await tester.pumpAndSettle();
    cloud
      ..version = 2
      ..content = ReportBlocksMapper.toSections(_doc(browserRoof));
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
  }

  group('the three-way comparison', () {
    testWidgets('only the computer changed the screen: it is taken, nobody is asked', (tester) async {
      await afterBrowserEdit(tester, browserRoof: 'The roof is covered with slates.');
      await tester.tap(find.byKey(const Key('synchronise')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('conflict_dialog')), findsNothing);
      expect(store.record.kept, isEmpty);
      expect(store.record.hasEdits, isTrue);
    });

    testWidgets('only the phone changed the screen: nobody is asked either', (tester) async {
      await afterBrowserEdit(tester, browserRoof: 'The roof is tiled.');
      phoneRoof = 'The roof has concrete tiles.';
      await tester.tap(find.byKey(const Key('synchronise')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('conflict_dialog')), findsNothing);
    });

    testWidgets('both made the same change: no question', (tester) async {
      await afterBrowserEdit(tester, browserRoof: 'The roof is covered with slates.');
      phoneRoof = 'The roof is covered with slates.';
      await tester.tap(find.byKey(const Key('synchronise')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('conflict_dialog')), findsNothing);
    });

    testWidgets('both changed the same screen differently: the owner is asked and chooses; the choice is kept', (tester) async {
      await afterBrowserEdit(tester, browserRoof: 'The roof is covered with slates.');
      phoneRoof = 'The roof has concrete tiles.';
      await tester.tap(find.byKey(const Key('synchronise')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('conflict_dialog')), findsOneWidget);
      expect(find.text('Outside / Roof'), findsOneWidget);
      expect(find.text("Use the computer's wording"), findsOneWidget);
      await _shot(tester, '01_conflict_dialog');
      await tester.tap(find.byKey(const Key('keep_E/roof')));
      await tester.pumpAndSettle();
      expect(find.text('Keep my wording'), findsOneWidget);
      await _shot(tester, '02_conflict_keep_mine');
      await tester.tap(find.byKey(const Key('conflicts_apply')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('conflict_dialog')), findsNothing);
      expect(store.record.kept, ['E/roof']);
      expect(find.textContaining('1 screen keep your wording'), findsOneWidget);
    });

    testWidgets("choosing the computer's wording keeps nothing", (tester) async {
      await afterBrowserEdit(tester, browserRoof: 'The roof is covered with slates.');
      phoneRoof = 'The roof has concrete tiles.';
      await tester.tap(find.byKey(const Key('synchronise')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('conflicts_apply')));
      await tester.pumpAndSettle();
      expect(store.record.kept, isEmpty);
      expect(find.textContaining('0 screens keep your wording'), findsOneWidget);
    });

    testWidgets('an older record with no baseline never asks (nothing to compare with)', (tester) async {
      await afterBrowserEdit(tester, browserRoof: 'The roof is covered with slates.');
      store.record = store.record.copyWith(baseline: const {});
      phoneRoof = 'The roof has concrete tiles.';
      await tester.tap(find.byKey(const Key('synchronise')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('conflict_dialog')), findsNothing);
    });
  });

  group('changes the cloud refused', () {
    testWidgets('are announced as kept and not lost; Synchronise sends them again and the notice goes away', (tester) async {
      await afterBrowserEdit(tester, browserRoof: 'The roof is covered with slates.');
      held = 3;
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('held_back_banner')), findsOneWidget);
      expect(find.textContaining('3 of your changes'), findsOneWidget);
      expect(find.textContaining('Nothing is lost'), findsOneWidget);
      await _shot(tester, '03_changes_held_back');
      await tester.tap(find.byKey(const Key('synchronise')));
      await tester.pumpAndSettle();
      expect(released, 1);
      expect(find.byKey(const Key('held_back_banner')), findsNothing);
    });
  });

  group('the mapper', () {
    test('screenTexts makes one text per screen and leaves out the tables the editor does not treat as screens', () {
      final sections = [
        {'key': 'E/roof', 'title': 'Roof', 'blocks': [{'type': 'paragraph', 'text': 'A'}, {'type': 'rating', 'rating': '2', 'text': 'because'}]},
        {'key': 'ACCOMMODATION', 'blocks': [{'type': 'table', 'table': {'rows': []}}]},
        {'key': 'VALUATION_MATRIX', 'blocks': [{'type': 'table', 'table': {'rows': []}}]},
      ];
      expect(ReportBlocksMapper.screenTexts(sections), {'E/roof': 'A\nrating:2|because'});
    });
    test('applyEdits leaves the screens in keep as the phone made them', () {
      final doc = _doc('The roof is tiled.');
      final edited = ReportBlocksMapper.toSections(_doc('Computer wording.'));
      expect(ReportBlocksMapper.applyEdits(doc, edited).sections.single.screens.single.phrases, ['Computer wording.']);
      expect(ReportBlocksMapper.applyEdits(doc, edited, keep: {'E/roof'}).sections.single.screens.single.phrases, ['The roof is tiled.']);
    });
  });
}
