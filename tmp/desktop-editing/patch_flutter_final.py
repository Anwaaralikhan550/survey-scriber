root = 'E:/survey-scriber/lib/features/report_editing/'


def patch(path, pairs):
    p = root + path
    t = open(p, encoding='utf-8', newline='').read()
    crlf = '\r\n' in t
    for a, b in pairs:
        a2 = a.replace('\n', '\r\n') if crlf else a
        b2 = b.replace('\n', '\r\n') if crlf else b
        assert a2 in t, (path, a[:70])
        t = t.replace(a2, b2, 1)
    open(p, 'w', encoding='utf-8', newline='').write(t)


# ---------------- API ----------------
patch('data/report_editing_api.dart', [
    ("/// Where the review workflow stands", '''/// One edit round that reached a final version. Reopening keeps it, with who reopened and why.
class FinalRound {
  const FinalRound({required this.cycle, required this.version, required this.finalisedAt, this.reopenedAt, this.reopenReason});
  final int cycle;
  final int version;
  final DateTime finalisedAt;
  final DateTime? reopenedAt;
  final String? reopenReason;
}

/// Where the review workflow stands'''),
    ("    this.lastAmendment,\n    this.entries = const [],\n  });", "    this.lastAmendment,\n    this.entries = const [],\n    this.cycle = 1,\n    this.finalVersion,\n    this.finalisedAt,\n    this.rounds = const [],\n  });"),
    ("  final List<ReviewEntry> entries;\n\n  bool get finalised", "  final List<ReviewEntry> entries;\n\n  /// Edit round (1 for a first report; +1 each time a final report is reopened).\n  final int cycle;\n  final int? finalVersion;\n  final DateTime? finalisedAt;\n  final List<FinalRound> rounds;\n\n  bool get finalised"),
    ("  factory ReviewInfo.fromJson(Map<String, dynamic> b) => ReviewInfo(", '''  static FinalRound _round(Map raw) => FinalRound(
        cycle: raw['cycle'] as int,
        version: raw['version'] as int,
        finalisedAt: DateTime.parse(raw['finalisedAt'] as String),
        reopenedAt: raw['reopenedAt'] == null ? null : DateTime.parse(raw['reopenedAt'] as String),
        reopenReason: raw['reopenReason'] as String?,
      );

  factory ReviewInfo.fromJson(Map<String, dynamic> b) => ReviewInfo('''),
    ("        entries: [for (final r in (b['reviews'] as List? ?? const [])) _entry(r as Map)],\n      );", "        entries: [for (final r in (b['reviews'] as List? ?? const [])) _entry(r as Map)],\n        cycle: ((b['finalisation'] as Map?)?['cycle'] as int?) ?? 1,\n        finalVersion: (b['finalisation'] as Map?)?['finalVersion'] as int?,\n        finalisedAt: (b['finalisation'] as Map?)?['finalisedAt'] == null ? null : DateTime.parse((b['finalisation'] as Map)['finalisedAt'] as String),\n        rounds: [for (final r in ((b['finalisation'] as Map?)?['history'] as List? ?? const [])) _round(r as Map)],\n      );"),
    ("  /// Back to Draft: every approval is withdrawn.", '''  /// Finalise exactly [expectedVersion], the version the owner approved. Locks the report and ends every link.
  Future<void> finalise(String surveyId, {required int expectedVersion}) async {
    await _call('POST', 'reports/$surveyId/finalise', data: {'expectedReportVersion': expectedVersion});
  }

  /// Open a finalised report again as a new edit round. The earlier final version stays on record with [reason].
  Future<void> reopen(String surveyId, {required int expectedVersion, required String reason}) async {
    await _call('POST', 'reports/$surveyId/reopen', data: {'expectedReportVersion': expectedVersion, 'reason': reason});
  }

  /// Back to Draft: every approval is withdrawn.'''),
])

# ---------------- controller ----------------
patch('presentation/providers/desktop_editing_controller.dart', [
    ("  /// Start again from Draft; every approval is withdrawn.", '''  /// The owner finalises the version they approved: the report is locked and every browser link ends.
  Future<void> finaliseReport() => _guarded(() async {
        _requireInSync();
        final version = state.cloudVersion!;
        await api.finalise(surveyId, expectedVersion: version);
        _setReview(await api.review(surveyId));
        _set(state.copyWith(linkActive: false, linkId: null, linkExpiresAt: null, linkUrl: null));
        await store.vault.write(surveyId, null);
      }, done: 'The report is final. Every browser link has ended and nobody can change it unless you reopen it.');

  /// Open a final report again as a new edit round. [reason] is kept with the earlier final version.
  Future<void> reopenReport(String reason) => _guarded(() async {
        _requireInSync();
        await api.reopen(surveyId, expectedVersion: state.cloudVersion!, reason: reason.trim());
        _setReview(await api.review(surveyId));
      }, done: 'The report is open again as a draft. The earlier final version is kept.');

  /// Start again from Draft; every approval is withdrawn.'''),
])
print('ok')
