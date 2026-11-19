import 'package:dio/dio.dart';

/// A failed desktop-editing call. [code] is the backend's error code (spec section 16), or `NETWORK`.
class ReportEditingException implements Exception {
  const ReportEditingException({required this.code, required this.message, this.status = 0, this.serverVersion});

  final String code;
  final String message;
  final int status;

  /// Set for `VERSION_CONFLICT`: the version the cloud report is at now.
  final int? serverVersion;

  bool get isConflict => code == 'VERSION_CONFLICT';
  bool get isNetwork => code == 'NETWORK';

  @override
  String toString() => 'ReportEditingException($code, $message)';
}

class EditLinkInfo {
  const EditLinkInfo({required this.linkId, required this.url, required this.expiresAt});
  final String linkId;
  final String url;
  final DateTime expiresAt;
}

class CurrentLink {
  const CurrentLink({required this.active, this.linkId, this.expiresAt});
  final bool active;
  final String? linkId;
  final DateTime? expiresAt;
}

class CloudReportInfo {
  const CloudReportInfo({required this.version, required this.status, required this.updatedAt});
  final int version;
  final String status;
  final DateTime updatedAt;
}

/// A report document the cloud now holds.
class StoredReportFile {
  const StoredReportFile({required this.id, required this.sha256, required this.duplicate});
  final String id;
  final String sha256;
  final bool duplicate;
}

class CloudPhoto {
  const CloudPhoto({required this.id, required this.fileName, required this.mimeType, required this.size, required this.caption, required this.sectionKey, required this.sortOrder, required this.deleted});
  final String id;
  final String fileName;
  final String mimeType;
  final int size;
  final String? caption;
  final String? sectionKey;
  final int sortOrder;
  final bool deleted;
}

class CloudPhotos {
  const CloudPhotos({required this.version, required this.photos});
  final int version;
  final List<CloudPhoto> photos;
}

/// One decision in the review history.
class ReviewEntry {
  const ReviewEntry({required this.decision, required this.version, required this.by, required this.createdAt, required this.invalidated, this.comment, this.reviewerName});
  final String decision;
  final int version;
  final String by;
  final DateTime createdAt;
  final bool invalidated;
  final String? comment;

  /// The name a link holder typed (never verified). Null for the owner and for a link holder who gave none.
  final String? reviewerName;

  /// "Omar Khan (name not verified)" for a link holder with a name, otherwise [fallback].
  String who({String fallback = 'a reviewer'}) => by == 'owner' ? 'you' : (reviewerName == null ? fallback : '$reviewerName (name not verified)');
}

/// One edit round that reached a final version. Reopening keeps it, with who reopened and why.
class FinalRound {
  const FinalRound({required this.cycle, required this.version, required this.finalisedAt, this.reopenedAt, this.reopenReason});
  final int cycle;
  final int version;
  final DateTime finalisedAt;
  final DateTime? reopenedAt;
  final String? reopenReason;
}

/// Where the review workflow stands (spec section 14): status, the versions involved, and who decided what.
class ReviewInfo {
  const ReviewInfo({
    required this.status,
    required this.version,
    this.submittedVersion,
    this.reviewerApprovalVersion,
    this.ownerApprovalVersion,
    this.lastAmendment,
    this.entries = const [],
    this.cycle = 1,
    this.finalVersion,
    this.finalisedAt,
    this.rounds = const [],
    this.reviewerApprovalName,
  });

  const ReviewInfo.draft(int version) : this(status: 'DRAFT', version: version);

  final String status;
  final int version;
  final int? submittedVersion;
  final int? reviewerApprovalVersion;

  /// The name the approving link holder typed (not verified).
  final String? reviewerApprovalName;
  final int? ownerApprovalVersion;
  final ReviewEntry? lastAmendment;
  final List<ReviewEntry> entries;

  /// Edit round (1 for a first report; +1 each time a final report is reopened).
  final int cycle;
  final int? finalVersion;
  final DateTime? finalisedAt;
  final List<FinalRound> rounds;

  bool get finalised => status == 'FINALISING' || status == 'FINALISED';
  bool get ownerApproved => status == 'OWNER_FINAL_APPROVAL';

  static ReviewEntry _entry(Map raw) => ReviewEntry(
        decision: raw['decision'] as String,
        version: raw['version'] as int,
        by: raw['by'] as String,
        createdAt: DateTime.parse(raw['createdAt'] as String),
        invalidated: raw['invalidated'] == true,
        comment: raw['comment'] as String?,
        reviewerName: raw['reviewerName'] as String?,
      );

  static FinalRound _round(Map raw) => FinalRound(
        cycle: raw['cycle'] as int,
        version: raw['version'] as int,
        finalisedAt: DateTime.parse(raw['finalisedAt'] as String),
        reopenedAt: raw['reopenedAt'] == null ? null : DateTime.parse(raw['reopenedAt'] as String),
        reopenReason: raw['reopenReason'] as String?,
      );

  factory ReviewInfo.fromJson(Map<String, dynamic> b) => ReviewInfo(
        status: b['status'] as String,
        version: b['version'] as int,
        submittedVersion: b['submittedVersion'] as int?,
        reviewerApprovalVersion: (b['reviewerApproval'] as Map?)?['version'] as int?,
        reviewerApprovalName: (b['reviewerApproval'] as Map?)?['reviewerName'] as String?,
        ownerApprovalVersion: (b['ownerApproval'] as Map?)?['version'] as int?,
        lastAmendment: b['lastAmendmentRequest'] == null ? null : _entry(b['lastAmendmentRequest'] as Map),
        entries: [for (final r in (b['reviews'] as List? ?? const [])) _entry(r as Map)],
        cycle: ((b['finalisation'] as Map?)?['cycle'] as int?) ?? 1,
        finalVersion: (b['finalisation'] as Map?)?['finalVersion'] as int?,
        finalisedAt: (b['finalisation'] as Map?)?['finalisedAt'] == null ? null : DateTime.parse((b['finalisation'] as Map)['finalisedAt'] as String),
        rounds: [for (final r in ((b['finalisation'] as Map?)?['history'] as List? ?? const [])) _round(r as Map)],
      );
}

class SyncedReport {
  const SyncedReport({required this.version, required this.status, required this.sections});
  final int version;
  final String status;
  final List<Map<String, dynamic>> sections;
}

/// Owner (app) side of the desktop editing API: snapshot upload, edit link, latest version, synchronise.
/// Uses the app's authenticated Dio, but reads error bodies itself because the spec's error codes matter.
class ReportEditingApi {
  ReportEditingApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> _call(String method, String path, {Object? data}) async {
    final Response<dynamic> res;
    try {
      res = await _dio.request<dynamic>(
        path,
        data: data,
        options: Options(method: method, validateStatus: (_) => true),
      );
    } on DioException catch (e) {
      throw ReportEditingException(code: 'NETWORK', message: e.message ?? 'No connection to SurveyScriber');
    }
    final body = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : <String, dynamic>{};
    final status = res.statusCode ?? 0;
    if (status == 429) throw const ReportEditingException(code: 'RATE_LIMITED', message: 'Too many requests', status: 429);
    if (status >= 400) {
      final details = body['details'];
      throw ReportEditingException(
        code: body['error'] as String? ?? (status == 401 ? 'UNAUTHORIZED' : 'ERROR'),
        message: body['message'] as String? ?? 'Request failed',
        status: status,
        serverVersion: details is Map ? details['serverVersion'] as int? : null,
      );
    }
    return body;
  }

  /// First upload creates the cloud report. Later uploads must name the cloud version they are based on.
  Future<CloudReportInfo> uploadSnapshot(
    String surveyId, {
    int? baseVersion,
    required String reportType,
    required List<Map<String, dynamic>> sections,
  }) async {
    final b = await _call('PUT', 'reports/$surveyId/snapshot', data: {
      if (baseVersion != null) 'baseVersion': baseVersion,
      'reportType': reportType,
      'content': sections,
    });
    return CloudReportInfo(version: b['version'] as int, status: 'DRAFT', updatedAt: DateTime.parse(b['updatedAt'] as String));
  }

  /// The original or final PDF/Word document of a report (Remote Editor v1.4). [state] is `ORIGINAL` or `FINAL`.
  Future<StoredReportFile> uploadReportFile(String surveyId, {required String state, required List<int> bytes, required String fileName}) async {
    final form = FormData.fromMap({'state': state, 'file': MultipartFile.fromBytes(bytes, filename: fileName)});
    final b = await _call('POST', 'reports/$surveyId/files', data: form);
    return StoredReportFile(id: b['id'] as String, sha256: b['sha256'] as String, duplicate: b['duplicate'] == true);
  }

  Future<EditLinkInfo> createLink(String surveyId) async {
    final b = await _call('POST', 'reports/$surveyId/edit-links');
    return EditLinkInfo(linkId: b['linkId'] as String, url: b['url'] as String, expiresAt: DateTime.parse(b['expiresAt'] as String));
  }

  Future<CurrentLink> currentLink(String surveyId) async {
    final b = await _call('GET', 'reports/$surveyId/edit-links/current');
    if (b['active'] != true) return const CurrentLink(active: false);
    return CurrentLink(active: true, linkId: b['linkId'] as String, expiresAt: DateTime.parse(b['expiresAt'] as String));
  }

  Future<void> cancelLink(String surveyId, String linkId) async {
    await _call('DELETE', 'reports/$surveyId/edit-links/$linkId');
  }

  /// Null when this survey has no cloud report yet.
  Future<CloudReportInfo?> latest(String surveyId) async {
    try {
      final b = await _call('GET', 'reports/$surveyId/latest');
      return CloudReportInfo(version: b['version'] as int, status: b['status'] as String, updatedAt: DateTime.parse(b['updatedAt'] as String));
    } on ReportEditingException catch (e) {
      if (e.code == 'NOT_FOUND') return null;
      rethrow;
    }
  }

  /// Photos of the report. With [includeDeleted] the ones removed in the browser are listed too (flagged), so the phone can drop them.
  Future<CloudPhotos> photos(String surveyId, {bool includeDeleted = false}) async {
    final b = await _call('GET', 'reports/$surveyId/photos${includeDeleted ? '?includeDeleted=true' : ''}');
    return CloudPhotos(
      version: b['version'] as int,
      photos: [
        for (final raw in (b['photos'] as List))
          CloudPhoto(
            id: (raw as Map)['id'] as String,
            fileName: raw['fileName'] as String,
            mimeType: raw['mimeType'] as String,
            size: raw['size'] as int,
            caption: raw['caption'] as String?,
            sectionKey: raw['sectionKey'] as String?,
            sortOrder: (raw['sortOrder'] as num?)?.toInt() ?? 0,
            deleted: raw['deleted'] == true,
          ),
      ],
    );
  }

  /// File the phone's photos under report sections. Only photos nobody organised yet are filled in.
  Future<({int version, int changed})> assignPhotos(String surveyId, {required int expectedVersion, required List<Map<String, dynamic>> items}) async {
    final b = await _call('POST', 'reports/$surveyId/photos/assign', data: {'expectedReportVersion': expectedVersion, 'items': items});
    return (version: b['version'] as int, changed: b['changed'] as int);
  }

  /// The drawing made on a photo on the phone, kept with the photo in the cloud (an empty list removes it).
  Future<void> putAnnotations(String surveyId, String remoteId, List<dynamic> elements) async {
    await _call('PUT', 'reports/$surveyId/media/$remoteId/annotations', data: {'annotations': elements});
  }

  /// The picture itself.
  Future<List<int>> downloadPhoto(String remoteId) async {
    final Response<List<int>> res;
    try {
      res = await _dio.get<List<int>>('media/$remoteId/file', options: Options(responseType: ResponseType.bytes, validateStatus: (_) => true));
    } on DioException catch (e) {
      throw ReportEditingException(code: 'NETWORK', message: e.message ?? 'No connection to SurveyScriber');
    }
    final status = res.statusCode ?? 0;
    if (status == 429) throw const ReportEditingException(code: 'RATE_LIMITED', message: 'Too many requests', status: 429);
    if (status >= 400 || res.data == null) throw ReportEditingException(code: 'ERROR', message: 'Could not download the photo', status: status);
    return res.data!;
  }

  Future<ReviewInfo> review(String surveyId) async => ReviewInfo.fromJson(await _call('GET', 'reports/$surveyId/review'));

  /// The owner's final approval of exactly [expectedVersion] (spec section 14: only the owner can do this).
  Future<ReviewInfo> ownerApprove(String surveyId, {required int expectedVersion, String? comment}) async =>
      ReviewInfo.fromJson(await _call('POST', 'reports/$surveyId/owner-approval', data: {'expectedReportVersion': expectedVersion, if (comment != null) 'comment': comment}));

  /// Send the report back with a comment saying what has to change.
  Future<ReviewInfo> requestChanges(String surveyId, {required int expectedVersion, required String comment}) async => ReviewInfo.fromJson(
        await _call('POST', 'reports/$surveyId/review/decision', data: {'expectedReportVersion': expectedVersion, 'decision': 'AMENDMENTS_REQUIRED', 'comment': comment}),
      );

  /// Finalise exactly [expectedVersion], the version the owner approved. Locks the report and ends every link.
  Future<void> finalise(String surveyId, {required int expectedVersion}) async {
    await _call('POST', 'reports/$surveyId/finalise', data: {'expectedReportVersion': expectedVersion});
  }

  /// Open a finalised report again as a new edit round. The earlier final version stays on record with [reason].
  Future<void> reopen(String surveyId, {required int expectedVersion, required String reason}) async {
    await _call('POST', 'reports/$surveyId/reopen', data: {'expectedReportVersion': expectedVersion, 'reason': reason});
  }

  /// Back to Draft: every approval is withdrawn.
  Future<ReviewInfo> resetReview(String surveyId, {required int expectedVersion}) async =>
      ReviewInfo.fromJson(await _call('POST', 'reports/$surveyId/review/reset', data: {'expectedReportVersion': expectedVersion}));

  Future<SyncedReport> sync(String surveyId) async {
    final b = await _call('POST', 'reports/$surveyId/sync');
    return SyncedReport(
      version: b['version'] as int,
      status: b['status'] as String,
      sections: [for (final s in (b['content'] as List)) Map<String, dynamic>.from(s as Map)],
    );
  }
}
