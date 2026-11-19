import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_manager.dart';
import '../../data/report_archive_client.dart';
import '../../data/report_editing_api.dart';
import '../providers/desktop_editing_providers.dart';

/// Lets the surveyor choose an archive ZIP. Null when nothing was chosen.
typedef ArchivePicker = Future<File?> Function();

Future<File?> pickArchiveFile() async {
  final r = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['zip'], dialogTitle: 'Choose a SurveyScriber archive');
  final path = r?.files.single.path;
  return path == null ? null : File(path);
}

/// "Restore archived report" (Remote Editor v1.4 section 14.2): choose a ZIP, SurveyScriber checks it completely, and the report comes
/// back, visibly marked as restored. A report that still exists is never overwritten.
Future<void> restoreArchivedReport(BuildContext context, WidgetRef ref, {ArchivePicker picker = pickArchiveFile}) async {
  final messenger = ScaffoldMessenger.of(context);
  final file = await picker();
  if (file == null || !context.mounted) return;
  final client = ref.read(reportArchiveClientProvider);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
      key: Key('restore_progress'),
      content: Row(children: [SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 16), Expanded(child: Text('Checking and restoring the archive...'))]),
    ),
  );
  RestoredArchive? restored;
  String? problem;
  try {
    restored = await client.restore(file);
  } on ReportEditingException catch (e) {
    problem = ReportArchiveClient.explain(e);
  } on FileSystemException {
    problem = 'The file could not be read.';
  }
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();
  if (restored == null) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('restore_failed'),
        title: const Text('Report not restored'),
        content: Text(problem ?? 'The archive could not be restored.'),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
      ),
    );
    return;
  }
  ref.read(syncStateProvider.notifier).syncNow(); // brings the restored survey onto this phone
  messenger.showSnackBar(
    SnackBar(
      key: const Key('restore_done'),
      content: Text(
        'Report restored from archive: ${restored.sections} sections, ${restored.media} pictures, ${restored.documents} documents, ${restored.importedEvents} earlier changes shown as imported history. It will appear in your reports after the sync.',
      ),
      duration: const Duration(seconds: 8),
    ),
  );
}
