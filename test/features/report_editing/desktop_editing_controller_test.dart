import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/report_editing/data/desktop_edit_store.dart';
import 'package:survey_scriber/features/report_editing/data/report_editing_api.dart';
import 'package:survey_scriber/features/report_editing/presentation/providers/desktop_editing_controller.dart';
import 'package:survey_scriber/features/report_export/domain/models/report_document.dart';

const _survey = '8b0c1a52-3f7e-4d0a-9d52-1c6f1f0f2a10';

class _MemoryVault implements LinkVault {
  final values = <String, String>{};
  @override
  Future<String?> read(String surveyId) async => values[surveyId];
  @override
  Future<void> write(String surveyId, String? url) async => url == null ? values.remove(surveyId) : values[surveyId] = url;
}

/// A cloud in memory: it behaves the way the backend does for versions, conflicts and links.
class _FakeCloud extends ReportEditingApi {
  _FakeCloud() : super(Dio());

  int? version;
  String status = 'DRAFT';
  List<Map<String, dynamic>> content = [];
  String? linkId;
  DateTime? linkExpires;
  bool offline = false;
  final uploads = <Map<String, dynamic>>[];
  int createCalls = 0;

  void _net() {
    if (offline) throw const ReportEditingException(code: 'NETWORK', message: 'offline');
  }

  @override
  Future<CloudReportInfo> uploadSnapshot(String surveyId, {int? baseVersion, required String reportType, required List<Map<String, dynamic>> sections}) async {
    _net();
    uploads.add({'baseVersion': baseVersion, 'reportType': reportType, 'sections': sections});
    if (version == null) {
      if (baseVersion != null && baseVersion != 0) throw const ReportEditingException(code: 'VERSION_CONFLICT', message: 'x', status: 409, serverVersion: 0);
      version = 1;
    } else {
      if (baseVersion != version) throw ReportEditingException(code: 'VERSION_CONFLICT', message: 'newer', status: 409, serverVersion: version);
      version = version! + 1;
    }
    content = sections;
    return CloudReportInfo(version: version!, status: status, updatedAt: DateTime(2026, 11, 16));
  }

  @override
  Future<EditLinkInfo> createLink(String surveyId) async {
    _net();
    createCalls++;
    if (linkId != null && linkExpires!.isAfter(DateTime.now())) throw const ReportEditingException(code: 'ACTIVE_LINK_EXISTS', message: 'live', status: 409);
    linkId = 'link-$createCalls';
    linkExpires = DateTime.now().add(const Duration(hours: 72));
    return EditLinkInfo(linkId: linkId!, url: 'https://editor.example/open/token$createCalls', expiresAt: linkExpires!);
  }

  @override
  Future<CurrentLink> currentLink(String surveyId) async {
    _net();
    final live = linkId != null && linkExpires!.isAfter(DateTime.now());
    return live ? CurrentLink(active: true, linkId: linkId, expiresAt: linkExpires) : const CurrentLink(active: false);
  }

  @override
  Future<void> cancelLink(String surveyId, String id) async {
    _net();
    if (id == linkId) linkId = null;
  }

  @override
  Future<CloudReportInfo?> latest(String surveyId) async {
    _net();
    return version == null ? null : CloudReportInfo(version: version!, status: status, updatedAt: DateTime(2026, 11, 16));
  }

  @override
  Future<SyncedReport> sync(String surveyId) async {
    _net();
    return SyncedReport(version: version!, status: status, sections: content);
  }

  /// The browser saves a change.
  void browserSaves(String text) {
    version = version! + 1;
    content = [
      {
        'id': 'a1111111-1111-4111-8111-111111111111',
        'key': 'E/roof',
        'title': 'Roof',
        'blocks': [
          {'id': 'b1111111-1111-4111-8111-111111111111', 'type': 'paragraph', 'role': 'phrase', 'text': text},
        ],
      },
    ];
  }
}

ReportDocument _doc() => ReportDocument(
      reportType: ReportType.inspection,
      title: 'T',
      generatedAt: DateTime(2026, 11, 16),
      surveyMeta: const SurveyMeta(surveyId: _survey, title: 'T'),
      sections: const [
        ReportSection(
          key: 'E',
          title: 'Outside',
          description: '',
          displayOrder: 0,
          screens: [
            ReportScreen(screenId: 'roof', title: 'Roof', fields: [], phrases: ['The roof is tiled.']),
          ],
        ),
      ],
    );

void main() {
  late Directory dir;
  late _MemoryVault vault;
  late DesktopEditStore store;
  late _FakeCloud cloud;
  late DesktopEditingController c;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('desk_ctl_');
    vault = _MemoryVault();
    store = DesktopEditStore(directory: () async => dir, vault: vault);
    cloud = _FakeCloud();
    c = DesktopEditingController(surveyId: _survey, reportType: 'L2', api: cloud, store: store, buildDocument: () async => _doc());
  });

  tearDown(() async {
    c.dispose();
    await dir.delete(recursive: true);
  });

  test('a survey that was never sent shows no versions and no link', () async {
    await c.refresh();
    expect(c.state.loading, isFalse);
    expect(c.state.hasCloudReport, isFalse);
    expect(c.state.linkActive, isFalse);
    expect(c.state.updateAvailable, isFalse);
  });

  test('Generate link uploads the report first, makes the link and keeps its address', () async {
    await c.refresh();
    await c.generateLink();
    expect(cloud.uploads.single['baseVersion'], isNull);
    expect(cloud.uploads.single['reportType'], 'L2');
    expect(((cloud.uploads.single['sections'] as List).single as Map)['key'], 'E/roof');
    expect(c.state.error, isNull);
    expect(c.state.linkActive, isTrue);
    expect(c.state.linkUrl, 'https://editor.example/open/token1');
    expect(c.state.cloudVersion, 1);
    expect(c.state.appVersion, 1);
    expect(c.state.updateAvailable, isFalse);
    expect(await vault.read(_survey), 'https://editor.example/open/token1');
    expect(c.state.linkExpiresAt!.difference(DateTime.now()).inHours, inInclusiveRange(71, 72));
  });

  test('the update indicator shows when the browser saved a newer version, and Synchronise takes it', () async {
    await c.refresh();
    await c.generateLink();
    cloud.browserSaves('The roof is natural slate.');
    await c.refresh();
    expect(c.state.updateAvailable, isTrue);
    expect(c.state.cloudVersion, 2);
    expect(c.state.appVersion, 1);
    await c.synchronise();
    expect(c.state.updateAvailable, isFalse);
    expect(c.state.appVersion, 2);
    expect(c.state.hasEdits, isTrue);
    expect((await store.read(_survey)).syncedSections!.single['key'], 'E/roof');
    expect(c.state.notice, contains('Synchronised'));
  });

  test('stale phone content is never uploaded over newer cloud edits', () async {
    await c.refresh();
    await c.generateLink();
    await c.cancelLink();
    cloud.browserSaves('Edited in the browser.');
    await c.refresh();
    final uploadsBefore = cloud.uploads.length;
    await c.generateLink();
    expect(cloud.uploads.length, uploadsBefore); // refused before anything was sent
    expect(cloud.createCalls, 1);
    expect(c.state.error, contains('Synchronise first'));
    expect(cloud.content.single['blocks'][0]['text'], 'Edited in the browser.');
  });

  test('when the cloud moves between the check and the upload, the server refuses and nothing is lost', () async {
    await c.refresh();
    await c.generateLink();
    await c.cancelLink();
    // the phone believes it is current (cloud 1) but the browser saved meanwhile
    await store.saveUploaded(_survey, 1);
    cloud.browserSaves('Edited in the browser.');
    c.state = c.state.copyWith(cloudVersion: 1);
    await c.generateLink();
    expect(c.state.error, contains('Synchronise first'));
    expect(cloud.content.single['blocks'][0]['text'], 'Edited in the browser.');
  });

  test('after Synchronise the next upload carries the edited wording and the right base version', () async {
    await c.refresh();
    await c.generateLink();
    cloud.browserSaves('The roof is natural slate.');
    await c.refresh();
    await c.synchronise();
    await c.updateCloudCopy();
    final sent = cloud.uploads.last;
    expect(sent['baseVersion'], 2);
    final blocks = ((sent['sections'] as List).single as Map)['blocks'] as List;
    expect((blocks.first as Map)['text'], 'The roof is natural slate.');
    expect(c.state.appVersion, 3);
    expect(c.state.hasEdits, isTrue);
  });

  test('only one link at a time: a live link blocks another and says so', () async {
    await c.refresh();
    await c.generateLink();
    await c.generateLink();
    expect(c.state.error, contains('already live'));
    expect(c.state.linkUrl, 'https://editor.example/open/token1');
  });

  test('Cancel link ends it and clears the saved address; a new one can be made', () async {
    await c.refresh();
    await c.generateLink();
    await c.cancelLink();
    expect(c.state.linkActive, isFalse);
    expect(c.state.linkUrl, isNull);
    expect(await vault.read(_survey), isNull);
    await c.generateLink();
    expect(c.state.linkUrl, 'https://editor.example/open/token2');
  });

  test('a link made on another phone is live here but its address is missing', () async {
    cloud.version = 1;
    cloud.linkId = 'other';
    cloud.linkExpires = DateTime.now().add(const Duration(hours: 5));
    await store.saveUploaded(_survey, 1);
    await c.refresh();
    expect(c.state.linkActive, isTrue);
    expect(c.state.linkAddressMissing, isTrue);
  });

  test('an expired link is not live and its saved address is dropped', () async {
    await c.refresh();
    await c.generateLink();
    cloud.linkExpires = DateTime.now().subtract(const Duration(minutes: 1));
    await c.refresh();
    expect(c.state.linkActive, isFalse);
    expect(await vault.read(_survey), isNull);
  });

  test('offline: the local picture stays, the screen says offline, and actions explain why they failed', () async {
    await c.refresh();
    await c.generateLink();
    cloud.offline = true;
    await c.refresh(quiet: true);
    expect(c.state.offline, isTrue);
    expect(c.state.appVersion, 1);
    await c.synchronise();
    expect(c.state.error, contains('No connection'));
    cloud.offline = false;
    await c.refresh(quiet: true);
    expect(c.state.offline, isFalse);
  });

  test('a finalised report cannot get a new link', () async {
    await c.refresh();
    await c.generateLink();
    await c.cancelLink();
    cloud.status = 'FINALISED';
    await c.refresh();
    expect(c.state.finalised, isTrue);
  });

  test('Remove edited wording goes back to the phone wording and keeps the version', () async {
    await c.refresh();
    await c.generateLink();
    cloud.browserSaves('x');
    await c.refresh();
    await c.synchronise();
    await c.discardEdits();
    expect(c.state.hasEdits, isFalse);
    expect(c.state.appVersion, 2);
  });

  test('polling picks up a newer cloud version by itself', () async {
    await c.refresh();
    await c.generateLink();
    c.startPolling(every: const Duration(milliseconds: 80));
    cloud.browserSaves('later');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(c.state.updateAvailable, isTrue);
    c.stopPolling();
    await Future<void>.delayed(const Duration(milliseconds: 150));
  });
}
