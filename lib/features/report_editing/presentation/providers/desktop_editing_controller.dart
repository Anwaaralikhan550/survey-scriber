import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../report_export/domain/models/report_document.dart';
import '../../data/desktop_edit_store.dart';
import '../../data/photo_sync_service.dart';
import '../../data/report_editing_api.dart';
import '../../domain/report_blocks_mapper.dart';

/// Where the owner's desktop editing stands for one survey (spec section 7 Screen H and section 12).
class DesktopEditingState {
  const DesktopEditingState({
    this.loading = true,
    this.busy = false,
    this.offline = false,
    this.error,
    this.notice,
    this.linkUrl,
    this.linkActive = false,
    this.linkExpiresAt,
    this.linkId,
    this.cloudVersion,
    this.cloudStatus,
    this.appVersion,
    this.hasEdits = false,
    this.checkedAt,
    this.review,
  });

  final bool loading;
  final bool busy;
  final bool offline;
  final String? error;
  final String? notice;

  /// The address to share. Only present on the phone that generated it.
  final String? linkUrl;
  final bool linkActive;
  final DateTime? linkExpiresAt;
  final String? linkId;

  /// Version of the report in the cloud, and of the copy on this phone.
  final int? cloudVersion;
  final String? cloudStatus;
  final int? appVersion;

  /// Browser edits are applied to this phone's PDF/Word.
  final bool hasEdits;
  final DateTime? checkedAt;

  /// The review workflow state of the cloud report (null until it has been read).
  final ReviewInfo? review;

  bool get hasCloudReport => cloudVersion != null;
  bool get updateAvailable => cloudVersion != null && appVersion != null && cloudVersion! > appVersion!;
  bool get finalised => cloudStatus == 'FINALISING' || cloudStatus == 'FINALISED';
  bool get linkAddressMissing => linkActive && linkUrl == null;

  DesktopEditingState copyWith({
    bool? loading,
    bool? busy,
    bool? offline,
    Object? error = _keep,
    Object? notice = _keep,
    Object? linkUrl = _keep,
    bool? linkActive,
    Object? linkExpiresAt = _keep,
    Object? linkId = _keep,
    Object? cloudVersion = _keep,
    Object? cloudStatus = _keep,
    Object? appVersion = _keep,
    bool? hasEdits,
    DateTime? checkedAt,
    Object? review = _keep,
  }) {
    return DesktopEditingState(
      loading: loading ?? this.loading,
      busy: busy ?? this.busy,
      offline: offline ?? this.offline,
      error: identical(error, _keep) ? this.error : error as String?,
      notice: identical(notice, _keep) ? this.notice : notice as String?,
      linkUrl: identical(linkUrl, _keep) ? this.linkUrl : linkUrl as String?,
      linkActive: linkActive ?? this.linkActive,
      linkExpiresAt: identical(linkExpiresAt, _keep) ? this.linkExpiresAt : linkExpiresAt as DateTime?,
      linkId: identical(linkId, _keep) ? this.linkId : linkId as String?,
      cloudVersion: identical(cloudVersion, _keep) ? this.cloudVersion : cloudVersion as int?,
      cloudStatus: identical(cloudStatus, _keep) ? this.cloudStatus : cloudStatus as String?,
      appVersion: identical(appVersion, _keep) ? this.appVersion : appVersion as int?,
      hasEdits: hasEdits ?? this.hasEdits,
      checkedAt: checkedAt ?? this.checkedAt,
      review: identical(review, _keep) ? this.review : review as ReviewInfo?,
    );
  }

  static const Object _keep = Object();
}

class DesktopEditingController extends StateNotifier<DesktopEditingState> {
  DesktopEditingController({
    required this.surveyId,
    required this.reportType,
    required this.api,
    required this.store,
    required this.buildDocument,
    this.photos,
    DateTime Function()? now,
  })  : _now = now ?? DateTime.now,
        super(const DesktopEditingState());

  final String surveyId;

  /// `L2` or `VALUATION`, as the backend names them.
  final String reportType;
  final ReportEditingApi api;
  final DesktopEditStore store;

  /// The phone's report as it would be exported right now.
  final Future<ReportDocument> Function() buildDocument;

  /// Keeps the phone's photos and the cloud's in step. Null where photos are not wanted (tests).
  final PhotoSyncService? photos;
  final DateTime Function() _now;
  Timer? _poll;
  bool _disposed = false;

  static const _cloudAhead = 'The report in SurveyScriber has changes that are not on this phone yet. Tap Synchronise first, so nothing is overwritten.';

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    super.dispose();
  }

  void _set(DesktopEditingState s) {
    if (!_disposed) state = s;
  }

  /// Poll for newer cloud versions while the screen is open (spec section 12).
  void startPolling({Duration every = const Duration(seconds: 30)}) {
    _poll?.cancel();
    _poll = Timer.periodic(every, (_) => refresh(quiet: true));
  }

  void stopPolling() => _poll?.cancel();

  /// Read what the phone and the cloud say. Network failure keeps the local picture and says so.
  Future<void> refresh({bool quiet = false}) async {
    if (!quiet) _set(state.copyWith(loading: true, error: null));
    try {
      await _refresh();
    } on Object catch (e) {
      // A background check must never throw into the timer; say so only when the user asked.
      _set(state.copyWith(loading: false, error: quiet ? state.error : 'Could not read the saved state: $e'));
    }
  }

  Future<void> _refresh() async {
    final record = await store.read(surveyId);
    final url = await store.vault.read(surveyId);
    var next = state.copyWith(appVersion: record.appVersion, hasEdits: record.hasEdits, linkUrl: url, loading: false);
    try {
      final cloud = await api.latest(surveyId);
      if (cloud == null) {
        next = next.copyWith(cloudVersion: null, cloudStatus: null, linkActive: false, linkExpiresAt: null, linkId: null, offline: false, review: null);
      } else {
        final link = await api.currentLink(surveyId);
        if (!link.active && url != null) await store.vault.write(surveyId, null);
        ReviewInfo? review = ReviewInfo(status: cloud.status, version: cloud.version);
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
          cloudStatus: cloud.status,
          linkActive: link.active,
          linkId: link.linkId,
          linkExpiresAt: link.expiresAt,
          linkUrl: link.active ? url : null,
          offline: false,
          checkedAt: _now(),
        );
      }
    } on ReportEditingException catch (e) {
      next = e.isNetwork ? next.copyWith(offline: true) : next.copyWith(error: e.message);
    }
    _set(next);
  }

  /// Upload this phone's report so the cloud copy matches it. Never overwrites cloud edits the phone has not seen.
  Future<CloudReportInfo> _upload() async {
    final cloud = state.cloudVersion;
    final record = await store.read(surveyId);
    if (cloud != null && record.appVersion != cloud) throw const ReportEditingException(code: 'VERSION_CONFLICT', message: _cloudAhead);
    var doc = await buildDocument();
    if (record.hasEdits) doc = ReportBlocksMapper.applyEdits(doc, record.syncedSections!);
    final up = await api.uploadSnapshot(
      surveyId,
      baseVersion: cloud == null ? null : record.appVersion,
      reportType: reportType,
      sections: ReportBlocksMapper.toSections(doc),
    );
    await store.saveUploaded(surveyId, up.version);
    // File the phone's uploaded photos under report sections (only photos nobody organised yet).
    final filed = await photos?.push(surveyId, doc, up.version);
    if (filed != null) {
      await store.saveUploaded(surveyId, filed);
      return CloudReportInfo(version: filed, status: up.status, updatedAt: up.updatedAt);
    }
    return up;
  }

  /// Runs one action. Each action updates the state from the answers it already got, because the API
  /// allows only a few requests a second: no extra "read it all again" round trip afterwards.
  Future<void> _guarded(Future<void> Function() body, {String? done}) async {
    if (state.busy) return;
    _set(state.copyWith(busy: true, error: null, notice: null));
    try {
      await body();
      _set(state.copyWith(busy: false, notice: done));
    } on ReportEditingException catch (e) {
      if (e.isConflict) {
        await refresh(quiet: true);
        _set(state.copyWith(busy: false, error: _cloudAhead));
      } else if (e.code == 'INVALID_STATE') {
        await refresh(quiet: true);
        _set(state.copyWith(busy: false, error: '${e.message} The status was refreshed.'));
      } else if (e.code == 'RATE_LIMITED') {
        _set(state.copyWith(busy: false, error: 'Too many requests at once. Wait a few seconds and try again.'));
      } else if (e.isNetwork) {
        _set(state.copyWith(busy: false, offline: true, error: 'No connection to SurveyScriber. Try again when you are online.'));
      } else if (e.code == 'ACTIVE_LINK_EXISTS') {
        await refresh(quiet: true);
        _set(state.copyWith(busy: false, error: 'A link is already live for this report. Cancel it first to make a new one.'));
      } else if (e.code == 'REPORT_FINALISED') {
        await refresh(quiet: true);
        _set(state.copyWith(busy: false, error: 'This report has been finalised and can no longer be edited.'));
      } else {
        _set(state.copyWith(busy: false, error: e.message));
      }
    } catch (e) {
      _set(state.copyWith(busy: false, error: 'Something went wrong: $e'));
    }
  }

  /// Upload the report, then make the one live link for it.
  Future<void> generateLink() => _guarded(() async {
        final up = await _upload();
        _set(state.copyWith(cloudVersion: up.version, appVersion: up.version));
        final link = await api.createLink(surveyId);
        await store.vault.write(surveyId, link.url);
        _set(state.copyWith(linkActive: true, linkId: link.linkId, linkUrl: link.url, linkExpiresAt: link.expiresAt));
      }, done: 'Link created. Share it with the person who will edit the report.');

  /// Send the phone's latest wording to the cloud while a link is live.
  Future<void> updateCloudCopy() => _guarded(() async {
        final up = await _upload();
        _set(state.copyWith(cloudVersion: up.version, appVersion: up.version));
      }, done: 'The report in SurveyScriber now matches this phone.');

  Future<void> cancelLink() => _guarded(() async {
        final id = state.linkId;
        if (id == null) return;
        await api.cancelLink(surveyId, id);
        await store.vault.write(surveyId, null);
        _set(state.copyWith(linkActive: false, linkId: null, linkUrl: null, linkExpiresAt: null));
      }, done: 'Link cancelled. It no longer opens the report.');

  /// Take the cloud report, with the browser's edits, as this phone's copy (spec section 12).
  Future<void> synchronise() async {
    PhotoSyncSummary? summary;
    await _guarded(() async {
      final synced = await api.sync(surveyId);
      await store.saveSynced(surveyId, synced.version, synced.sections);
      _set(state.copyWith(cloudVersion: synced.version, cloudStatus: synced.status, appVersion: synced.version, hasEdits: true));
      summary = await photos?.pull(surveyId);
    }, done: 'Synchronised. Your PDF and Word reports now use the edited wording.');
    final s = summary;
    if (s != null && s.changedAnything && state.error == null) {
      _set(state.copyWith(notice: '${state.notice ?? 'Synchronised.'} Photos: ${s.describe()}.'));
    } else if (s != null && s.failed > 0 && state.error == null) {
      _set(state.copyWith(notice: '${state.notice ?? 'Synchronised.'} ${s.describe()}. Synchronise again to retry.'));
    }
  }

  static const _approveNeedsSync = 'Synchronise first, so you approve exactly what you have read.';

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

  /// Go back to the wording the phone generates from the answers.
  Future<void> discardEdits() => _guarded(() async {
        await store.clearEdits(surveyId);
        _set(state.copyWith(hasEdits: false));
      }, done: 'Edits removed from this phone. The report is built from your answers again.');
}
