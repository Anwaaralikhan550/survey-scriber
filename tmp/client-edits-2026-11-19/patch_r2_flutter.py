def rw(p, fn):
    t = open(p, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in t else '\n'
    t = fn(t.replace('\r\n', '\n'))
    open(p, 'w', encoding='utf-8', newline='').write(t.replace('\n', nl))


def sub(t, a, b):
    assert t.count(a) == 1, (t.count(a), a[:70])
    return t.replace(a, b, 1)


def api(t):
    t = sub(t, "  Future<EditLinkInfo> createLink(String surveyId) async {", """  /// The original or final PDF/Word document of a report (Remote Editor v1.4). [state] is `ORIGINAL` or `FINAL`.
  Future<StoredReportFile> uploadReportFile(String surveyId, {required String state, required List<int> bytes, required String fileName}) async {
    final form = FormData.fromMap({'state': state, 'file': MultipartFile.fromBytes(bytes, filename: fileName)});
    final b = await _call('POST', 'reports/$surveyId/files', data: form);
    return StoredReportFile(id: b['id'] as String, sha256: b['sha256'] as String, duplicate: b['duplicate'] == true);
  }

  Future<EditLinkInfo> createLink(String surveyId) async {""")
    t = sub(t, "class CloudPhoto {", """/// A report document the cloud now holds.
class StoredReportFile {
  const StoredReportFile({required this.id, required this.sha256, required this.duplicate});
  final String id;
  final String sha256;
  final bool duplicate;
}

class CloudPhoto {""")
    return t


rw('lib/features/report_editing/data/report_editing_api.dart', api)


def store(t):
    t = sub(t, "  const DesktopEditRecord({this.appVersion, this.syncedSections});", "  const DesktopEditRecord({this.appVersion, this.syncedSections, this.files = const {}});")
    t = sub(t, "  bool get hasEdits => syncedSections != null;", "  /// Report documents already stored in the cloud: `<ORIGINAL|FINAL>:<pdf|docx>:<cycle>` -> SHA-256 (empty when the cloud already had one).\n  final Map<String, String> files;\n\n  bool get hasEdits => syncedSections != null;")
    t = sub(t, "        syncedSections: sections == null ? null : [for (final s in sections) Map<String, dynamic>.from(s as Map)],\n      );", "        syncedSections: sections == null ? null : [for (final s in sections) Map<String, dynamic>.from(s as Map)],\n        files: {for (final e in (m['files'] as Map? ?? const {}).entries) '${e.key}': '${e.value}'},\n      );")
    t = sub(t, "jsonEncode({'appVersion': r.appVersion, if (r.syncedSections != null) 'sections': r.syncedSections})", "jsonEncode({'appVersion': r.appVersion, if (r.syncedSections != null) 'sections': r.syncedSections, if (r.files.isNotEmpty) 'files': r.files})")
    t = sub(t, "_write(surveyId, DesktopEditRecord(appVersion: version, syncedSections: r.syncedSections));", "_write(surveyId, DesktopEditRecord(appVersion: version, syncedSections: r.syncedSections, files: r.files));")
    t = sub(t, "      _write(surveyId, DesktopEditRecord(appVersion: version, syncedSections: sections));", "      read(surveyId).then((r) => _write(surveyId, DesktopEditRecord(appVersion: version, syncedSections: sections, files: r.files)));")
    t = sub(t, "    await _write(surveyId, DesktopEditRecord(appVersion: r.appVersion));", "    await _write(surveyId, DesktopEditRecord(appVersion: r.appVersion, files: r.files));")
    t = sub(t, "  Future<void> forget(String surveyId) async {", "  /// A report document was stored in the cloud (or the cloud already had it).\n  Future<void> markFileUploaded(String surveyId, String key, String sha256) async {\n    final r = await read(surveyId);\n    await _write(surveyId, DesktopEditRecord(appVersion: r.appVersion, syncedSections: r.syncedSections, files: {...r.files, key: sha256}));\n  }\n\n  Future<void> forget(String surveyId) async {")
    return t


rw('lib/features/report_editing/data/desktop_edit_store.dart', store)


def exp(t):
    t = sub(t, "import 'dart:io';", "import 'dart:async';\nimport 'dart:io';")
    t = sub(t, "import '../../../report_editing/data/desktop_edit_store.dart';", "import '../../../report_editing/data/desktop_edit_store.dart';\nimport '../../../report_editing/data/report_document_uploader.dart';")
    t = sub(t, "    this.desktopEdits,\n  });", "    this.desktopEdits,\n    this.documentUploader,\n  });")
    t = sub(t, "  final DesktopEditStore? desktopEdits;\n", "  final DesktopEditStore? desktopEdits;\n\n  /// Stores the generated PDF/Word in the cloud as the original or final document (best effort).\n  final ReportDocumentUploader? documentUploader;\n")
    a = "    onProgress?.call(const ExportProgress(\n        stage: 'Complete', percent: 1.0, message: 'Export complete'));"
    t = sub(t, a, "    // The original (or, after finalising, the final) PDF/Word also goes to the cloud. It never holds up the export.\n    final uploader = documentUploader;\n    if (uploader != null) {\n      unawaited(uploader.afterExport(\n        surveyId: surveyId,\n        document: document,\n        bytes: generated.bytes,\n        fileName: outputPath.split(Platform.pathSeparator).last,\n        format: config.format == ExportFormat.pdf ? 'pdf' : 'docx',\n      ));\n    }\n\n" + a)
    return t


rw('lib/features/report_export/data/services/export_service.dart', exp)


def prov(t):
    t = sub(t, "    desktopEdits: ref.watch(desktopEditStoreProvider),\n  );", "    desktopEdits: ref.watch(desktopEditStoreProvider),\n    documentUploader: ReportDocumentUploader(\n      api: ReportEditingApi(ref.watch(dioProvider)),\n      store: ref.watch(desktopEditStoreProvider),\n    ),\n  );")
    return t


rw('lib/features/report_export/presentation/providers/export_providers.dart', prov)
print('ok')
