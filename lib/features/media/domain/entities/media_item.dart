import 'package:equatable/equatable.dart';

/// Types of media that can be captured
enum MediaType {
  photo,
  audio,
  video,
}

/// Status of media item (for sync)
enum MediaStatus {
  local,      // Only on device
  uploading,  // Being uploaded
  synced,     // Synced to server
  failed,     // Upload failed
}

/// Base class for all media items
abstract class MediaItem extends Equatable {
  const MediaItem({
    required this.id,
    required this.surveyId,
    required this.sectionId,
    required this.type,
    required this.localPath,
    required this.createdAt,
    this.remotePath,
    this.caption,
    this.status = MediaStatus.local,
    this.fileSize,
    this.duration,
  });

  final String id;
  final String surveyId;
  final String sectionId;
  final MediaType type;
  final String localPath;
  final String? remotePath;
  final String? caption;
  final MediaStatus status;
  final DateTime createdAt;
  final int? fileSize; // bytes
  final int? duration; // milliseconds (for audio/video)

  bool get isSynced => status == MediaStatus.synced;
  bool get isLocal => status == MediaStatus.local;
  bool get hasCaption => caption != null && caption!.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        surveyId,
        sectionId,
        type,
        localPath,
        remotePath,
        caption,
        status,
        createdAt,
        fileSize,
        duration,
      ];
}

/// Photo media item
class PhotoItem extends MediaItem {
  const PhotoItem({
    required super.id,
    required super.surveyId,
    required super.sectionId,
    required super.localPath,
    required super.createdAt,
    super.remotePath,
    super.caption,
    super.status,
    super.fileSize,
    this.width,
    this.height,
    this.thumbnailPath,
    this.hasAnnotations = false,
    this.sortOrder = 0,
  }) : super(type: MediaType.photo);

  final int? width;
  final int? height;
  final String? thumbnailPath;
  final bool hasAnnotations;
  final int sortOrder;

  PhotoItem copyWith({
    String? id,
    String? surveyId,
    String? sectionId,
    String? localPath,
    String? remotePath,
    String? caption,
    MediaStatus? status,
    DateTime? createdAt,
    int? fileSize,
    int? width,
    int? height,
    String? thumbnailPath,
    bool? hasAnnotations,
    int? sortOrder,
  }) => PhotoItem(
      id: id ?? this.id,
      surveyId: surveyId ?? this.surveyId,
      sectionId: sectionId ?? this.sectionId,
      localPath: localPath ?? this.localPath,
      remotePath: remotePath ?? this.remotePath,
      caption: caption ?? this.caption,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      fileSize: fileSize ?? this.fileSize,
      width: width ?? this.width,
      height: height ?? this.height,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      hasAnnotations: hasAnnotations ?? this.hasAnnotations,
      sortOrder: sortOrder ?? this.sortOrder,
    );

  @override
  List<Object?> get props => [
        ...super.props,
        width,
        height,
        thumbnailPath,
        hasAnnotations,
        sortOrder,
      ];
}

/// Audio note media item
class AudioItem extends MediaItem {
  const AudioItem({
    required super.id,
    required super.surveyId,
    required super.sectionId,
    required super.localPath,
    required super.createdAt,
    required super.duration,
    super.remotePath,
    super.caption,
    super.status,
    super.fileSize,
    this.waveformData,
    this.transcription,
  }) : super(type: MediaType.audio);

  final List<double>? waveformData; // Amplitude data for visualization
  final String? transcription; // Future: speech-to-text

  String get durationFormatted {
    if (duration == null) return '0:00';
    final seconds = (duration! / 1000).floor();
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  AudioItem copyWith({
    String? id,
    String? surveyId,
    String? sectionId,
    String? localPath,
    String? remotePath,
    String? caption,
    MediaStatus? status,
    DateTime? createdAt,
    int? fileSize,
    int? duration,
    List<double>? waveformData,
    String? transcription,
  }) => AudioItem(
      id: id ?? this.id,
      surveyId: surveyId ?? this.surveyId,
      sectionId: sectionId ?? this.sectionId,
      localPath: localPath ?? this.localPath,
      remotePath: remotePath ?? this.remotePath,
      caption: caption ?? this.caption,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      waveformData: waveformData ?? this.waveformData,
      transcription: transcription ?? this.transcription,
    );

  @override
  List<Object?> get props => [
        ...super.props,
        waveformData,
        transcription,
      ];
}

/// Video clip media item
class VideoItem extends MediaItem {
  const VideoItem({
    required super.id,
    required super.surveyId,
    required super.sectionId,
    required super.localPath,
    required super.createdAt,
    required super.duration,
    super.remotePath,
    super.caption,
    super.status,
    super.fileSize,
    this.width,
    this.height,
    this.thumbnailPath,
  }) : super(type: MediaType.video);

  final int? width;
  final int? height;
  final String? thumbnailPath;

  String get durationFormatted {
    if (duration == null) return '0:00';
    final seconds = (duration! / 1000).floor();
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  VideoItem copyWith({
    String? id,
    String? surveyId,
    String? sectionId,
    String? localPath,
    String? remotePath,
    String? caption,
    MediaStatus? status,
    DateTime? createdAt,
    int? fileSize,
    int? duration,
    int? width,
    int? height,
    String? thumbnailPath,
  }) => VideoItem(
      id: id ?? this.id,
      surveyId: surveyId ?? this.surveyId,
      sectionId: sectionId ?? this.sectionId,
      localPath: localPath ?? this.localPath,
      remotePath: remotePath ?? this.remotePath,
      caption: caption ?? this.caption,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      width: width ?? this.width,
      height: height ?? this.height,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );

  @override
  List<Object?> get props => [
        ...super.props,
        width,
        height,
        thumbnailPath,
      ];
}
