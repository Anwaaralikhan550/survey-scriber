import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'report_editing_api.dart';

/// Complete archive download and restore on the phone (Remote Editor v1.4 section 14). The archive is verified against the SHA-256 the
/// server reported before it is kept, so a damaged download is never offered as a backup.
class ReportArchiveClient {
  ReportArchiveClient(this.api);

  final ReportEditingApi api;

  /// Downloads the archive of [surveyId] into [dir] and returns the saved file.
  Future<File> download(String surveyId, Directory dir) async {
    final a = await api.downloadArchive(surveyId);
    final actual = sha256.convert(a.bytes).toString();
    if (actual != a.sha256) {
      throw const ReportEditingException(code: 'ARCHIVE_DAMAGED', message: 'The download was damaged on the way. Please try again.');
    }
    if (!await dir.exists()) await dir.create(recursive: true);
    final file = File(p.join(dir.path, p.basename(a.fileName)));
    await file.writeAsBytes(a.bytes, flush: true);
    return file;
  }

  /// Sends a chosen archive file to be restored.
  Future<RestoredArchive> restore(File file) async => api.restoreArchive(await file.readAsBytes(), p.basename(file.path));

  /// A plain explanation for the surveyor; nothing technical.
  static String explain(ReportEditingException e) {
    switch (e.code) {
      case 'ARCHIVE_REPORT_ID_COLLISION':
        return 'This report is already in SurveyScriber, so nothing was restored and nothing was overwritten.';
      case 'ARCHIVE_NOT_OWNER':
        return 'This archive belongs to another user. Only its owner can restore it.';
      case 'ARCHIVE_INVALID':
        return 'This is not a complete, unchanged SurveyScriber archive. ${e.message}';
      case 'FILE_TOO_LARGE':
        return 'This archive is too large to restore.';
      case 'NETWORK':
        return 'No connection to SurveyScriber. Try again when you are online.';
      case 'RATE_LIMITED':
        return 'Too many requests at once. Wait a few seconds and try again.';
      default:
        return e.message;
    }
  }
}
