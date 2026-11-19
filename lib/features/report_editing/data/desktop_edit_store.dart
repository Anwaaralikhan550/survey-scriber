import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// What the phone remembers about a survey's desktop editing.
class DesktopEditRecord {
  const DesktopEditRecord({this.appVersion, this.syncedSections, this.files = const {}, this.baseline = const {}, this.kept = const []});

  /// The cloud version this phone's copy matches: set by an upload and by a synchronise.
  final int? appVersion;

  /// The browser's edits from the last synchronise. Null when none are applied to the report.
  final List<Map<String, dynamic>>? syncedSections;

  /// Report documents already stored in the cloud: `<ORIGINAL|FINAL>:<pdf|docx>:<cycle>` -> SHA-256 (empty when the cloud already had one).
  final Map<String, String> files;

  /// What each report screen said when this phone and the cloud last agreed (an upload or a synchronise): screen key -> its text.
  /// A screen changed on the computer AND on the phone since then is a conflict the owner decides.
  final Map<String, String> baseline;

  /// Screens where the owner chose to keep the phone's own wording instead of the computer's.
  final List<String> kept;

  bool get hasEdits => syncedSections != null;

  DesktopEditRecord copyWith({
    Object? appVersion = _keep,
    Object? syncedSections = _keep,
    Map<String, String>? files,
    Map<String, String>? baseline,
    List<String>? kept,
  }) =>
      DesktopEditRecord(
        appVersion: identical(appVersion, _keep) ? this.appVersion : appVersion as int?,
        syncedSections: identical(syncedSections, _keep) ? this.syncedSections : syncedSections as List<Map<String, dynamic>>?,
        files: files ?? this.files,
        baseline: baseline ?? this.baseline,
        kept: kept ?? this.kept,
      );

  static const Object _keep = Object();
}

/// The saved link address. It is a bearer secret, so it goes to the secure store, not to a plain file.
abstract class LinkVault {
  Future<String?> read(String surveyId);
  Future<void> write(String surveyId, String? url);
}

class SecureLinkVault implements LinkVault {
  SecureLinkVault([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  String _key(String id) => 'desktop_edit_link_$id';

  @override
  Future<String?> read(String surveyId) => _storage.read(key: _key(surveyId));

  @override
  Future<void> write(String surveyId, String? url) async {
    if (url == null) {
      await _storage.delete(key: _key(surveyId));
    } else {
      await _storage.write(key: _key(surveyId), value: url);
    }
  }
}

/// Local, per-survey desktop editing state: cloud version of this phone's copy, the synced edits, the link address.
class DesktopEditStore {
  DesktopEditStore({Future<Directory> Function()? directory, LinkVault? vault})
      : _directory = directory ?? getApplicationDocumentsDirectory,
        vault = vault ?? SecureLinkVault();

  final Future<Directory> Function() _directory;
  final LinkVault vault;

  Future<File> _file(String surveyId) async => File('${(await _directory()).path}/desktop_edit_$surveyId.json');

  Future<DesktopEditRecord> read(String surveyId) async {
    final f = await _file(surveyId);
    if (!await f.exists()) return const DesktopEditRecord();
    try {
      final m = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      final sections = m['sections'] as List?;
      return DesktopEditRecord(
        appVersion: m['appVersion'] as int?,
        syncedSections: sections == null ? null : [for (final s in sections) Map<String, dynamic>.from(s as Map)],
        files: {for (final e in (m['files'] as Map? ?? const {}).entries) '${e.key}': '${e.value}'},
        baseline: {for (final e in (m['baseline'] as Map? ?? const {}).entries) '${e.key}': '${e.value}'},
        kept: [for (final k in (m['kept'] as List? ?? const [])) '$k'],
      );
    } on FormatException {
      return const DesktopEditRecord();
    }
  }

  Future<void> _write(String surveyId, DesktopEditRecord r) async {
    final f = await _file(surveyId);
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(
      jsonEncode({
        'appVersion': r.appVersion,
        if (r.syncedSections != null) 'sections': r.syncedSections,
        if (r.files.isNotEmpty) 'files': r.files,
        if (r.baseline.isNotEmpty) 'baseline': r.baseline,
        if (r.kept.isNotEmpty) 'kept': r.kept,
      }),
      flush: true,
    );
    await tmp.rename(f.path); // never leave a half-written file
  }

  /// This phone's copy was just uploaded as [version]. The synced edits stay: the upload already contained them.
  /// [baseline] is what each screen said in that upload.
  Future<void> saveUploaded(String surveyId, int version, {Map<String, String>? baseline}) async {
    final r = await read(surveyId);
    await _write(surveyId, r.copyWith(appVersion: version, baseline: baseline));
  }

  /// The phone took the cloud report at [version], browser edits included. [baseline] is what each screen says now; the
  /// owner's earlier "keep mine" choices belong to the previous synchronise and are cleared.
  Future<void> saveSynced(String surveyId, int version, List<Map<String, dynamic>> sections, {Map<String, String>? baseline}) async {
    final r = await read(surveyId);
    await _write(surveyId, r.copyWith(appVersion: version, syncedSections: sections, baseline: baseline, kept: const []));
  }

  /// Stop applying the browser's edits to the report. The version stays, so the app still knows where it is.
  Future<void> clearEdits(String surveyId) async {
    final r = await read(surveyId);
    await _write(surveyId, r.copyWith(syncedSections: null, kept: const []));
  }

  /// The owner chose to keep the phone's own wording on these screens after a synchronise.
  Future<void> saveKept(String surveyId, List<String> screenKeys) async {
    final r = await read(surveyId);
    await _write(surveyId, r.copyWith(kept: screenKeys));
  }

  /// A report document was stored in the cloud (or the cloud already had it).
  Future<void> markFileUploaded(String surveyId, String key, String sha256) async {
    final r = await read(surveyId);
    await _write(surveyId, r.copyWith(files: {...r.files, key: sha256}));
  }

  Future<void> forget(String surveyId) async {
    final f = await _file(surveyId);
    if (await f.exists()) await f.delete();
    await vault.write(surveyId, null);
  }
}
