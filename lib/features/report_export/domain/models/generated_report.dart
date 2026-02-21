import 'package:equatable/equatable.dart';

/// Domain entity for a locally generated report.
class GeneratedReport extends Equatable {
  const GeneratedReport({
    required this.id,
    required this.surveyId,
    required this.surveyTitle,
    required this.filePath,
    required this.fileName,
    required this.sizeBytes,
    required this.generatedAt,
    this.moduleType = 'inspection',
    this.format = 'pdf',
    this.remoteUrl,
    this.checksum = '',
  });

  final String id;
  final String surveyId;
  final String surveyTitle;
  final String filePath;
  final String fileName;
  final int sizeBytes;
  final DateTime generatedAt;
  final String moduleType;
  final String format;
  final String? remoteUrl;
  final String checksum;

  bool get isPdf => format == 'pdf';

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  List<Object?> get props => [
        id, surveyId, filePath, generatedAt,
        moduleType, format, remoteUrl, checksum,
      ];
}
