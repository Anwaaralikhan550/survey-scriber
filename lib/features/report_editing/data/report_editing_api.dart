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

  Future<SyncedReport> sync(String surveyId) async {
    final b = await _call('POST', 'reports/$surveyId/sync');
    return SyncedReport(
      version: b['version'] as int,
      status: b['status'] as String,
      sections: [for (final s in (b['content'] as List)) Map<String, dynamic>.from(s as Map)],
    );
  }
}
