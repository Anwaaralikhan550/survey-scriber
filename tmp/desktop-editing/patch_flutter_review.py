import re
root = r'E:/survey-scriber/lib/features/report_editing/'


def patch(path, pairs):
    p = root + path
    t = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert a in t, (path, a[:70])
        t = t.replace(a, b, 1)
    open(p, 'w', encoding='utf-8').write(t)


# ---------------- API ----------------
patch('data/report_editing_api.dart', [
    ("class SyncedReport {", '''/// One decision in the review history.
class ReviewEntry {
  const ReviewEntry({required this.decision, required this.version, required this.by, required this.createdAt, required this.invalidated, this.comment});
  final String decision;
  final int version;
  final String by;
  final DateTime createdAt;
  final bool invalidated;
  final String? comment;
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
  });

  const ReviewInfo.draft(int version) : this(status: 'DRAFT', version: version);

  final String status;
  final int version;
  final int? submittedVersion;
  final int? reviewerApprovalVersion;
  final int? ownerApprovalVersion;
  final ReviewEntry? lastAmendment;
  final List<ReviewEntry> entries;

  bool get finalised => status == 'FINALISING' || status == 'FINALISED';
  bool get ownerApproved => status == 'OWNER_FINAL_APPROVAL';

  static ReviewEntry _entry(Map raw) => ReviewEntry(
        decision: raw['decision'] as String,
        version: raw['version'] as int,
        by: raw['by'] as String,
        createdAt: DateTime.parse(raw['createdAt'] as String),
        invalidated: raw['invalidated'] == true,
        comment: raw['comment'] as String?,
      );

  factory ReviewInfo.fromJson(Map<String, dynamic> b) => ReviewInfo(
        status: b['status'] as String,
        version: b['version'] as int,
        submittedVersion: b['submittedVersion'] as int?,
        reviewerApprovalVersion: (b['reviewerApproval'] as Map?)?['version'] as int?,
        ownerApprovalVersion: (b['ownerApproval'] as Map?)?['version'] as int?,
        lastAmendment: b['lastAmendmentRequest'] == null ? null : _entry(b['lastAmendmentRequest'] as Map),
        entries: [for (final r in (b['reviews'] as List? ?? const [])) _entry(r as Map)],
      );
}

class SyncedReport {'''),
    ("  Future<SyncedReport> sync(String surveyId) async {", '''  Future<ReviewInfo> review(String surveyId) async => ReviewInfo.fromJson(await _call('GET', 'reports/$surveyId/review'));

  /// The owner's final approval of exactly [expectedVersion] (spec section 14: only the owner can do this).
  Future<ReviewInfo> ownerApprove(String surveyId, {required int expectedVersion, String? comment}) async =>
      ReviewInfo.fromJson(await _call('POST', 'reports/$surveyId/owner-approval', data: {'expectedReportVersion': expectedVersion, if (comment != null) 'comment': comment}));

  /// Send the report back with a comment saying what has to change.
  Future<ReviewInfo> requestChanges(String surveyId, {required int expectedVersion, required String comment}) async => ReviewInfo.fromJson(
        await _call('POST', 'reports/$surveyId/review/decision', data: {'expectedReportVersion': expectedVersion, 'decision': 'AMENDMENTS_REQUIRED', 'comment': comment}),
      );

  /// Back to Draft: every approval is withdrawn.
  Future<ReviewInfo> resetReview(String surveyId, {required int expectedVersion}) async =>
      ReviewInfo.fromJson(await _call('POST', 'reports/$surveyId/review/reset', data: {'expectedReportVersion': expectedVersion}));

  Future<SyncedReport> sync(String surveyId) async {'''),
])

# ---------------- controller ----------------
patch('presentation/providers/desktop_editing_controller.dart', [
    ("    this.hasEdits = false,\n    this.checkedAt,\n  });", "    this.hasEdits = false,\n    this.checkedAt,\n    this.review,\n  });"),
    ("  final DateTime? checkedAt;\n\n  bool get hasCloudReport", "  final DateTime? checkedAt;\n\n  /// The review workflow state of the cloud report (null until it has been read).\n  final ReviewInfo? review;\n\n  bool get hasCloudReport"),
    ("    bool? hasEdits,\n    DateTime? checkedAt,\n  }) {", "    bool? hasEdits,\n    DateTime? checkedAt,\n    Object? review = _keep,\n  }) {"),
    ("      checkedAt: checkedAt ?? this.checkedAt,\n    );", "      checkedAt: checkedAt ?? this.checkedAt,\n      review: identical(review, _keep) ? this.review : review as ReviewInfo?,\n    );"),
])

t = open(root + 'presentation/providers/desktop_editing_controller.dart', encoding='utf-8').read()

# refresh: read the review state when the report is past Draft (an extra request only when there is something to show)
old = """        next = next.copyWith(
          cloudVersion: cloud.version,
          cloudStatus: cloud.status,"""
new = """        ReviewInfo? review = ReviewInfo(status: cloud.status, version: cloud.version);
        if (cloud.status != 'DRAFT') {
          try {
            review = await api.review(surveyId);
          } on ReportEditingException {
            /* the status from the cheap call is enough to show */
          }
        }
        next = next.copyWith(
          review: review,
          cloudVersion: cloud.version,
          cloudStatus: cloud.status,"""
assert old in t
t = t.replace(old, new, 1)
old = "        next = next.copyWith(cloudVersion: null, cloudStatus: null, linkActive: false, linkExpiresAt: null, linkId: null, offline: false);"
new = "        next = next.copyWith(cloudVersion: null, cloudStatus: null, linkActive: false, linkExpiresAt: null, linkId: null, offline: false, review: null);"
assert old in t
t = t.replace(old, new, 1)

# owner actions
old = "  /// Go back to the wording the phone generates from the answers."
new = '''  static const _approveNeedsSync = 'Synchronise first, so you approve exactly what you have read.';

  void _requireInSync() {
    if (state.updateAvailable || state.appVersion == null || state.cloudVersion == null || state.appVersion != state.cloudVersion) {
      throw const ReportEditingException(code: 'VERSION_CONFLICT', message: _approveNeedsSync);
    }
  }

  void _setReview(ReviewInfo r) => _set(state.copyWith(review: r, cloudStatus: r.status, cloudVersion: r.version));

  /// The owner's final approval of the version this phone has (spec section 14: only the owner can give it).
  Future<void> approveFinal({String? comment}) => _guarded(() async {
        _requireInSync();
        _setReview(await api.ownerApprove(surveyId, expectedVersion: state.cloudVersion!, comment: comment));
      }, done: 'Final approval given for version ${state.cloudVersion}.');

  /// Send the report back to the editors with a note saying what to change.
  Future<void> requestChanges(String comment) => _guarded(() async {
        _requireInSync();
        _setReview(await api.requestChanges(surveyId, expectedVersion: state.cloudVersion!, comment: comment));
      }, done: 'Sent back with your comment.');

  /// Start again from Draft; every approval is withdrawn.
  Future<void> resetReview() => _guarded(() async {
        _requireInSync();
        _setReview(await api.resetReview(surveyId, expectedVersion: state.cloudVersion!));
      }, done: 'The report is a draft again. Earlier approvals no longer stand.');

  /// Go back to the wording the phone generates from the answers.'''
assert old in t
t = t.replace(old, new, 1)
# INVALID_STATE message
old = "      } else if (e.code == 'RATE_LIMITED') {"
new = "      } else if (e.code == 'INVALID_STATE') {\n        await refresh(quiet: true);\n        _set(state.copyWith(busy: false, error: '${e.message} The status was refreshed.'));\n      } else if (e.code == 'RATE_LIMITED') {"
assert old in t
t = t.replace(old, new, 1)
open(root + 'presentation/providers/desktop_editing_controller.dart', 'w', encoding='utf-8').write(t)
print('ok')
