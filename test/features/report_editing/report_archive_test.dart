import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/features/report_editing/data/desktop_edit_store.dart';
import 'package:survey_scriber/features/report_editing/data/report_archive_client.dart';
import 'package:survey_scriber/features/report_editing/data/report_editing_api.dart';
import 'package:survey_scriber/features/report_editing/presentation/providers/desktop_editing_controller.dart';
import 'package:survey_scriber/features/report_editing/presentation/providers/desktop_editing_providers.dart';
import 'package:survey_scriber/features/report_editing/presentation/widgets/restore_archive_flow.dart';
import 'package:survey_scriber/features/report_export/domain/models/report_document.dart';

const _survey = '8b0c1a52-3f7e-4d0a-9d52-1c6f1f0f2a10';

class _Vault implements LinkVault {
  @override
  Future<String?> read(String surveyId) async => null;
  @override
  Future<void> write(String surveyId, String? url) async {}
}

/// A cloud that answers the archive calls the way the backend does.
class _Cloud extends ReportEditingApi {
  _Cloud() : super(Dio());

  List<int> zip = [0x50, 0x4b, 3, 4, 1, 2, 3, 4];
  String? sha;
  ReportEditingException? downloadError;
  ReportEditingException? restoreError;
  final restored = <({List<int> bytes, String name})>[];
  bool restoredFlag = false;

  @override
  Future<ArchiveDownload> downloadArchive(String surveyId) async {
    if (downloadError != null) throw downloadError!;
    return ArchiveDownload(bytes: zip, sha256: sha ?? sha256.convert(zip).toString(), fileName: 'surveyscriber-archive-8b0c1a52-2026-11-19.zip');
  }

  @override
  Future<RestoredArchive> restoreArchive(List<int> bytes, String fileName) async {
    if (restoreError != null) throw restoreError!;
    restored.add((bytes: bytes, name: fileName));
    return const RestoredArchive(reportId: _survey, status: 'DRAFT', version: 3, sections: 2, media: 4, documents: 2, importedEvents: 9);
  }

  @override
  Future<CloudReportInfo?> latest(String surveyId) async => CloudReportInfo(version: 3, status: 'DRAFT', updatedAt: DateTime(2026, 11, 19), restoredFromArchive: restoredFlag);

  @override
  Future<CurrentLink> currentLink(String surveyId) async => const CurrentLink(active: false);
}

ReportDocument _doc() => ReportDocument(
      reportType: ReportType.inspection,
      title: 'T',
      generatedAt: DateTime(2026, 11, 19),
      surveyMeta: const SurveyMeta(surveyId: _survey, title: 'T'),
      sections: const [],
    );

void main() {
  late Directory dir;
  late _Cloud cloud;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('archive_');
    cloud = _Cloud();
  });
  tearDown(() async => dir.delete(recursive: true));

  group('ReportArchiveClient', () {
    test('saves the archive under the name the cloud gave, byte for byte, after checking its SHA-256', () async {
      final file = await ReportArchiveClient(cloud).download(_survey, Directory('${dir.path}/archives'));
      expect(file.path.endsWith('surveyscriber-archive-8b0c1a52-2026-11-19.zip'), isTrue);
      expect(await file.readAsBytes(), cloud.zip);
    });

    test('a download that does not match the checksum is not kept as a backup', () async {
      cloud.sha = 'a' * 64;
      final archives = Directory('${dir.path}/archives');
      await expectLater(ReportArchiveClient(cloud).download(_survey, archives), throwsA(isA<ReportEditingException>().having((e) => e.code, 'code', 'ARCHIVE_DAMAGED')));
      expect(archives.existsSync() ? archives.listSync() : const <FileSystemEntity>[], isEmpty);
    });

    test('an error from the cloud is passed on', () async {
      cloud.downloadError = const ReportEditingException(code: 'FORBIDDEN', message: 'no', status: 403);
      await expectLater(ReportArchiveClient(cloud).download(_survey, dir), throwsA(isA<ReportEditingException>().having((e) => e.code, 'code', 'FORBIDDEN')));
    });

    test('restore sends the chosen file with its own name', () async {
      final f = File('${dir.path}/mine.zip')..writeAsBytesSync([9, 8, 7]);
      final r = await ReportArchiveClient(cloud).restore(f);
      expect(cloud.restored.single.bytes, [9, 8, 7]);
      expect(cloud.restored.single.name, 'mine.zip');
      expect([r.reportId, r.version, r.media, r.importedEvents], [_survey, 3, 4, 9]);
    });

    test('every refusal is explained in plain words', () {
      String say(String code, [String message = 'x']) => ReportArchiveClient.explain(ReportEditingException(code: code, message: message));
      expect(say('ARCHIVE_REPORT_ID_COLLISION'), allOf(contains('already in SurveyScriber'), contains('nothing was overwritten')));
      expect(say('ARCHIVE_NOT_OWNER'), contains('another user'));
      expect(say('ARCHIVE_INVALID', 'Signature does not match.'), allOf(contains('not a complete, unchanged'), contains('Signature does not match.')));
      expect(say('FILE_TOO_LARGE'), contains('too large'));
      expect(say('NETWORK'), contains('No connection'));
      expect(say('SOMETHING', 'Plain message'), 'Plain message');
    });
  });

  group('the controller', () {
    DesktopEditingController make() => DesktopEditingController(
          surveyId: _survey,
          reportType: 'L2',
          api: cloud,
          store: DesktopEditStore(directory: () async => dir, vault: _Vault()),
          buildDocument: () async => _doc(),
          archive: ReportArchiveClient(cloud),
          archiveDir: () async => Directory('${dir.path}/archives'),
        );

    test('Download complete archive returns the saved file and says it is ready', () async {
      final c = make();
      addTearDown(c.dispose);
      final path = await c.downloadArchive();
      expect(path, isNotNull);
      expect(File(path!).readAsBytesSync(), cloud.zip);
      expect(c.state.error, isNull);
      expect(c.state.notice, contains('archive is ready'));
      expect(c.state.busy, isFalse);
    });

    test('a failed download returns nothing and shows why', () async {
      cloud.downloadError = const ReportEditingException(code: 'NETWORK', message: 'offline');
      final c = make();
      addTearDown(c.dispose);
      expect(await c.downloadArchive(), isNull);
      expect(c.state.error, contains('No connection'));
      expect(c.state.busy, isFalse);
    });

    test('a report restored from an archive is marked as such in the state', () async {
      cloud.restoredFlag = true;
      final c = make();
      addTearDown(c.dispose);
      await c.refresh();
      expect(c.state.restoredFromArchive, isTrue);
    });

    test('an ordinary report is not marked', () async {
      final c = make();
      addTearDown(c.dispose);
      await c.refresh();
      expect(c.state.restoredFromArchive, isFalse);
    });
  });

  group('Restore archived report', () {
    Future<void> pump(WidgetTester t, ArchivePicker picker) async {
      await t.pumpWidget(
        ProviderScope(
          overrides: [reportArchiveClientProvider.overrideWithValue(ReportArchiveClient(cloud))],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => TextButton(key: const Key('go'), onPressed: () => restoreArchivedReport(context, ref, picker: picker), child: const Text('go')),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('nothing chosen: nothing is sent', (t) async {
      await pump(t, () async => null);
      await t.tap(find.byKey(const Key('go')));
      await t.pumpAndSettle();
      expect(cloud.restored, isEmpty);
      expect(find.byKey(const Key('restore_failed')), findsNothing);
    });

    testWidgets('a refused archive shows why, in plain words, and a dialog to close', (t) async {
      final f = File('${dir.path}/a.zip')..writeAsBytesSync([1]);
      cloud.restoreError = const ReportEditingException(code: 'ARCHIVE_REPORT_ID_COLLISION', message: 'x', status: 409);
      await pump(t, () async => f);
      await t.runAsync(() async {
        await t.tap(find.byKey(const Key('go')));
        await Future<void>.delayed(const Duration(milliseconds: 300)); // the file is read for real
      });
      await t.pumpAndSettle();
      expect(find.byKey(const Key('restore_failed')), findsOneWidget);
      expect(find.textContaining('already in SurveyScriber'), findsOneWidget);
      await t.tap(find.text('OK'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('restore_failed')), findsNothing);
    });
  });
}
