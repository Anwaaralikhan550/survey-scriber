import '../../../core/utils/logger.dart';
import '../../report_export/domain/models/report_document.dart';
import '../domain/report_blocks_mapper.dart';
import 'desktop_edit_store.dart';
import 'report_editing_api.dart';

/// Stores the generated PDF and Word files in the cloud (Remote Editor spec v1.4 sections 5 and 11): the first ones made
/// after the inspection become the ORIGINAL documents (together with the original report snapshot), the ones made after the
/// owner finalised become the FINAL documents of that edit cycle. Best effort: it never stops an export; what could not be
/// sent is tried again at the next export. What was already stored is remembered so it is not sent twice.
class ReportDocumentUploader {
  ReportDocumentUploader({required this.api, required this.store});

  final ReportEditingApi api;
  final DesktopEditStore store;

  /// Returns the state that was stored (`ORIGINAL` or `FINAL`), or null when nothing was sent.
  Future<String?> afterExport({
    required String surveyId,
    required ReportDocument document,
    required List<int> bytes,
    required String fileName,
    required String format,
  }) async {
    try {
      var info = await api.latest(surveyId);
      if (info == null) {
        final sections = ReportBlocksMapper.toSections(document);
        if (sections.isEmpty) return null;
        info = await api.uploadSnapshot(
          surveyId,
          reportType: document.reportType == ReportType.valuation ? 'VALUATION' : 'L2',
          sections: sections,
        );
        await store.saveUploaded(surveyId, info.version);
      }
      var state = 'ORIGINAL';
      var cycle = 1;
      if (info.status == 'FINALISED') {
        state = 'FINAL';
        cycle = (await api.review(surveyId)).cycle;
      } else if (info.version != 1) {
        return null; // changed in the cloud since: what was just made is no longer the original report
      }
      final key = '$state:$format:$cycle';
      final record = await store.read(surveyId);
      if (record.files.containsKey(key)) return null;
      try {
        final stored = await api.uploadReportFile(surveyId, state: state, bytes: bytes, fileName: fileName);
        await store.markFileUploaded(surveyId, key, stored.sha256);
      } on ReportEditingException catch (e) {
        if (e.code != 'FILE_EXISTS') rethrow;
        await store.markFileUploaded(surveyId, key, ''); // the cloud already holds one: nothing more to send
      }
      return state;
    } on Exception catch (e) {
      AppLogger.w('ReportDocuments', 'Could not store the report document in the cloud (will retry): $e');
      return null;
    }
  }
}
