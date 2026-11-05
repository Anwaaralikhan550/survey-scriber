import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../app/router/routes.dart';
import '../../../../shared/domain/entities/survey.dart';
import '../../../report_export/domain/models/report_document.dart';
import '../../../report_export/presentation/widgets/export_bottom_sheet.dart';
import '../providers/survey_lifecycle.dart';

enum _FolderAction { view, edit, generate, delete }

/// The menu on a Survey Folder card: View Report, Edit Report, Generate Report,
/// Delete Report. View Report appears once a report exists.
class SurveyFolderMenu extends ConsumerWidget {
  const SurveyFolderMenu({required this.survey, super.key});

  final Survey survey;

  void _say(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _view(BuildContext context, WidgetRef ref) async {
    final report =
        await ref.read(surveyLifecycleProvider).latestReport(survey.id);
    if (!context.mounted) return;
    if (report == null) {
      _say(context, 'No report yet. Use Generate Report first.');
      return;
    }
    final onThisDevice = !kIsWeb && await File(report.filePath).exists();
    final result = onThisDevice ? await OpenFilex.open(report.filePath) : null;
    if (!context.mounted) return;
    if (result?.type != ResultType.done) {
      _say(
        context,
        'The report is no longer on this phone. Use Generate Report to make it again.',
      );
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report?'),
        content: Text(
          'This deletes "${survey.title}", its answers and its reports. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(surveyLifecycleProvider).delete(survey.id);
    if (context.mounted) _say(context, 'Report deleted');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportExists = survey.status != SurveyStatus.draft &&
        survey.status != SurveyStatus.inProgress &&
        survey.status != SurveyStatus.paused;
    return PopupMenuButton<_FolderAction>(
      tooltip: 'Report actions',
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (action) {
        switch (action) {
          case _FolderAction.view:
            _view(context, ref);
          case _FolderAction.edit:
            context.push(Routes.surveyDetailPath(survey.id));
          case _FolderAction.generate:
            ExportBottomSheet.show(
              context,
              surveyId: survey.id,
              surveyTitle: survey.title,
              reportType: survey.type.isValuation
                  ? ReportType.valuation
                  : ReportType.inspection,
            );
          case _FolderAction.delete:
            _delete(context, ref);
        }
      },
      itemBuilder: (context) => [
        if (reportExists)
          const PopupMenuItem(
            value: _FolderAction.view,
            child: _MenuRow(Icons.visibility_outlined, 'View Report'),
          ),
        const PopupMenuItem(
          value: _FolderAction.edit,
          child: _MenuRow(Icons.edit_outlined, 'Edit Report'),
        ),
        const PopupMenuItem(
          value: _FolderAction.generate,
          child: _MenuRow(Icons.picture_as_pdf_outlined, 'Generate Report'),
        ),
        const PopupMenuItem(
          value: _FolderAction.delete,
          child: _MenuRow(Icons.delete_outline_rounded, 'Delete Report'),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(label),
        ],
      );
}
