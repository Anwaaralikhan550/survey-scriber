import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../shared/services/pdf_upload_service.dart';
import '../../domain/models/export_config.dart';
import '../../domain/models/generated_report.dart';
import '../../domain/models/report_document.dart';
import '../providers/export_providers.dart';

/// Lightweight data class that decouples [EmailComposeSheet] from both
/// [GeneratedReport] (report history) and [ExportResult] (fresh export).
class EmailReportInfo {
  const EmailReportInfo({
    required this.surveyId,
    required this.surveyTitle,
    required this.filePath,
    required this.fileName,
    required this.format,
    required this.moduleType,
    required this.generatedAt,
    this.remoteUrl,
    this.sizeBytes,
    this.companyName = 'SurveyScriber',
  });

  final String surveyId;
  final String surveyTitle;
  final String filePath;
  final String fileName;
  final String format; // 'pdf' or 'docx'
  final String moduleType; // 'inspection' or 'valuation'
  final DateTime generatedAt;
  final String? remoteUrl;
  final int? sizeBytes;
  final String companyName;

  bool get isPdf => format == 'pdf';

  String get formattedSize {
    final bytes = sizeBytes;
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Build from a [GeneratedReport] (report history / preview page).
  factory EmailReportInfo.fromGeneratedReport(GeneratedReport r) {
    return EmailReportInfo(
      surveyId: r.surveyId,
      surveyTitle: r.surveyTitle,
      filePath: r.filePath,
      fileName: r.fileName,
      format: r.format,
      moduleType: r.moduleType,
      generatedAt: r.generatedAt,
      remoteUrl: r.remoteUrl,
      sizeBytes: r.sizeBytes,
    );
  }

  /// Build from an [ExportResult] (fresh export dialog).
  factory EmailReportInfo.fromExportResult(
    ExportResult result, {
    required String surveyTitle,
    required ReportType reportType,
  }) {
    final path = result.outputPath;
    final fileName = path.split(Platform.pathSeparator).last;
    final format = result.format == ExportFormat.pdf ? 'pdf' : 'docx';
    final moduleType =
        reportType == ReportType.inspection ? 'inspection' : 'valuation';

    // Read file size (best-effort, non-blocking since file was just created)
    int? sizeBytes;
    try {
      sizeBytes = File(path).lengthSync();
    } catch (_) {}

    return EmailReportInfo(
      surveyId: result.surveyId,
      surveyTitle: surveyTitle,
      filePath: path,
      fileName: fileName,
      format: format,
      moduleType: moduleType,
      generatedAt: DateTime.now(),
      remoteUrl: result.remoteUrl,
      sizeBytes: sizeBytes,
    );
  }
}

/// Bottom sheet for composing and sending a report via email.
///
/// Send strategy:
/// - **"Send Email"** button: Uses backend SMTP (`POST /surveys/:id/send-report`).
///   If the PDF hasn't been uploaded yet, uploads it first. Shows actionable
///   error messages on failure (no silent fallback).
/// - **"Share via other app"** button: Opens the OS share sheet with the file
///   attached. Works for both PDF and DOCX. This is the primary path for DOCX
///   since the backend email API only supports PDF.
class EmailComposeSheet extends ConsumerStatefulWidget {
  const EmailComposeSheet({required this.reportInfo, super.key});

  final EmailReportInfo reportInfo;

  static Future<void> show(
    BuildContext context, {
    required EmailReportInfo reportInfo,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => EmailComposeSheet(reportInfo: reportInfo),
    );
  }

  @override
  ConsumerState<EmailComposeSheet> createState() => _EmailComposeSheetState();
}

class _EmailComposeSheetState extends ConsumerState<EmailComposeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSending = false;
  String? _errorMessage;

  EmailReportInfo get report => widget.reportInfo;

  @override
  void initState() {
    super.initState();
    final moduleLabel =
        report.moduleType == 'valuation' ? 'Valuation' : 'Inspection';
    final formatLabel = report.isPdf ? 'PDF' : 'DOCX';

    _subjectController.text =
        'Property $moduleLabel Report — ${report.surveyTitle}';

    final d = report.generatedAt.day.toString().padLeft(2, '0');
    final m = report.generatedAt.month.toString().padLeft(2, '0');
    final y = report.generatedAt.year;

    _bodyController.text = 'Please find attached the $formatLabel report '
        'for "${report.surveyTitle}".\n\n'
        'Report generated: $d/$m/$y\n'
        'Format: $formatLabel\n\n'
        'Kind regards,\n${report.companyName}';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Send Report via Email',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),

                // Attachment info
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        report.isPdf
                            ? Icons.picture_as_pdf_rounded
                            : Icons.description_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.fileName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (report.formattedSize.isNotEmpty)
                              Text(
                                report.formattedSize,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.attach_file_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Recipient email',
                    hintText: 'client@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: _validateEmail,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),

                // Subject field
                TextFormField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    prefixIcon: Icon(Icons.subject_rounded),
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),

                // Body field
                TextFormField(
                  controller: _bodyController,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: 16),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Send via backend email
                FilledButton.icon(
                  onPressed: _isSending ? null : _send,
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_isSending ? 'Sending...' : 'Send Email'),
                ),
                const SizedBox(height: 8),

                // Share via OS share sheet (explicit alternative)
                TextButton.icon(
                  onPressed: _isSending ? null : _shareViaApp,
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Share via other app'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    // Backend email only supports PDF — direct DOCX users to share
    if (!report.isPdf) {
      setState(() {
        _errorMessage = 'Server-side email is only available for PDF reports. '
            'Use "Share via other app" below to send the DOCX.';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final uploadService = ref.read(pdfUploadServiceProvider);

    try {
      // If the PDF hasn't been uploaded yet, upload it first so the
      // backend has the file to attach to the email.
      if (report.remoteUrl == null) {
        final uploaded = await uploadService.uploadReportPdf(
          surveyId: report.surveyId,
          pdfPath: report.filePath,
        );
        if (!mounted) return;
        if (!uploaded) {
          setState(() {
            _isSending = false;
            _errorMessage =
                'Could not upload the report to the server. '
                'Use "Share via other app" to send manually.';
          });
          return;
        }
      }

      // Send via backend SMTP
      await uploadService.sendReportEmail(
        surveyId: report.surveyId,
        recipientEmail: email,
        format: report.format,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report sent to $email'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on SurveyNotFoundOnServerException {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMessage =
            'This survey has not been synced to the server yet. '
            'Please sync the survey first, then try again.';
      });
    } on PdfUploadNetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMessage = e.isOffline
            ? 'No internet connection. '
              'Use "Share via other app" to send manually.'
            : 'Network error: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMessage = 'Failed to send email: $e';
      });
    }
  }

  /// Opens the OS share sheet with the report file attached.
  /// This is the explicit user-chosen alternative to backend SMTP.
  Future<void> _shareViaApp() async {
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();
    final mimeType = report.isPdf
        ? 'application/pdf'
        : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

    try {
      await Share.shareXFiles(
        [XFile(report.filePath, mimeType: mimeType)],
        subject: subject,
        text: body,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to open share sheet: $e';
      });
    }
  }
}
