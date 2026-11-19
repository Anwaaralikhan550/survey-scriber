def rw(p, fn):
    t = open(p, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in t else '\n'
    t = fn(t.replace('\r\n', '\n'))
    open(p, 'w', encoding='utf-8', newline='').write(t.replace('\n', nl))


def sub(t, a, b):
    assert t.count(a) == 1, (t.count(a), a[:70])
    return t.replace(a, b, 1)


# ---- mapper: screen texts (for the three-way comparison) and "keep mine" when applying the browser's edits
def mapper(t):
    t = sub(t, "  /// The document with the browser's edits in it. Screens the editor does not know about stay as they are.\n  static ReportDocument applyEdits(ReportDocument doc, List<Map<String, dynamic>> edited) {\n    final byKey = {for (final s in edited) s['key'] as String: s};",
            """  /// What each screen says, as one text: section key -> its blocks in order. Used to tell what changed where.
  static Map<String, String> screenTexts(List<Map<String, dynamic>> sections) {
    String blockText(Map<String, dynamic> b) {
      switch (b['type']) {
        case 'rating':
          return 'rating:${b['rating']}|${b['text'] ?? ''}';
        case 'table':
          return 'table:${jsonEncode(b['table'])}';
        default:
          return '${b['text'] ?? ''}';
      }
    }

    return {
      for (final s in sections)
        if (s['key'] != scheduleKey && s['key'] != matrixKey)
          s['key'] as String: [for (final b in (s['blocks'] as List? ?? const [])) blockText(b as Map<String, dynamic>)].join('\\n'),
    };
  }

  /// The document with the browser's edits in it. Screens the editor does not know about stay as they are.
  /// Screens in [keep] stay as the phone made them (the owner chose to keep them after a synchronise).
  static ReportDocument applyEdits(ReportDocument doc, List<Map<String, dynamic>> edited, {Set<String> keep = const {}}) {
    final byKey = {for (final s in edited) if (!keep.contains(s['key'])) s['key'] as String: s};""")
    t = sub(t, "import 'package:uuid/uuid.dart';", "import 'dart:convert';\n\nimport 'package:uuid/uuid.dart';")
    return t


rw('lib/features/report_editing/domain/report_blocks_mapper.dart', mapper)


def export(t):
    return sub(t, "    return ReportBlocksMapper.applyEdits(document, record.syncedSections!);", "    return ReportBlocksMapper.applyEdits(document, record.syncedSections!, keep: record.kept.toSet());")


rw('lib/features/report_export/data/services/export_service.dart', export)


# ---- controller
def ctrl(t):
    t = sub(t, "    this.hasEdits = false,\n    this.checkedAt,\n    this.review,\n  });", "    this.hasEdits = false,\n    this.checkedAt,\n    this.review,\n    this.heldBackChanges = 0,\n    this.conflicts = const [],\n  });")
    t = sub(t, "  /// The review workflow state of the cloud report (null until it has been read).\n  final ReviewInfo? review;\n", "  /// The review workflow state of the cloud report (null until it has been read).\n  final ReviewInfo? review;\n\n  /// Changes made on the phone that the cloud refused because the report was edited on a computer first (kept, not lost).\n  final int heldBackChanges;\n\n  /// After a synchronise: screens changed on the computer AND on the phone since they last agreed. The owner decides each.\n  final List<ScreenConflict> conflicts;\n")
    t = sub(t, "    Object? review = _keep,\n  }) {", "    Object? review = _keep,\n    int? heldBackChanges,\n    List<ScreenConflict>? conflicts,\n  }) {")
    t = sub(t, "      review: identical(review, _keep) ? this.review : review as ReviewInfo?,\n    );", "      review: identical(review, _keep) ? this.review : review as ReviewInfo?,\n      heldBackChanges: heldBackChanges ?? this.heldBackChanges,\n      conflicts: conflicts ?? this.conflicts,\n    );")
    t = sub(t, "class DesktopEditingController extends StateNotifier<DesktopEditingState> {", """/// One report screen that was changed both on the computer and on the phone since they last agreed.
class ScreenConflict {
  const ScreenConflict({required this.key, required this.title});
  final String key;
  final String title;
}

class DesktopEditingController extends StateNotifier<DesktopEditingState> {""")
    t = sub(t, "    this.photos,\n    DateTime Function()? now,\n  })", "    this.photos,\n    this.heldBack,\n    this.releaseHeldBack,\n    DateTime Function()? now,\n  })")
    t = sub(t, "  final PhotoSyncService? photos;\n  final DateTime Function() _now;", "  final PhotoSyncService? photos;\n\n  /// How many of this survey's changes the cloud refused (stale push), and a way to send them again. Null in tests.\n  final Future<int> Function()? heldBack;\n  final Future<void> Function()? releaseHeldBack;\n  final DateTime Function() _now;")
    # baseline recorded at upload
    t = sub(t, "    await store.saveUploaded(surveyId, up.version);\n    // File the phone's uploaded photos", "    await store.saveUploaded(surveyId, up.version, baseline: ReportBlocksMapper.screenTexts(ReportBlocksMapper.toSections(doc)));\n    // File the phone's uploaded photos")
    # synchronise: three-way comparison, release held back changes
    old = t[t.index("  /// Take the cloud report, with the browser's edits, as this phone's copy (spec section 12).\n  Future<void> synchronise() async {"):t.index("  static const _approveNeedsSync")]
    new = """  /// Take the cloud report, with the browser's edits, as this phone's copy (spec section 12). A screen changed on the computer AND
  /// on the phone since they last agreed is listed in [DesktopEditingState.conflicts] for the owner to decide; nothing is
  /// overwritten silently. Changes the cloud refused earlier are sent again afterwards.
  Future<void> synchronise() async {
    PhotoSyncSummary? summary;
    await _guarded(() async {
      final before = await store.read(surveyId);
      final synced = await api.sync(surveyId);
      final theirs = ReportBlocksMapper.screenTexts(synced.sections);
      final conflicts = <ScreenConflict>[];
      if (before.baseline.isNotEmpty) {
        final mine = ReportBlocksMapper.screenTexts(ReportBlocksMapper.toSections(await buildDocument()));
        final titles = {for (final s in synced.sections) s['key'] as String: '${s['title'] ?? s['key']}'};
        for (final key in theirs.keys) {
          final base = before.baseline[key];
          if (base == null) continue;
          final computerChanged = theirs[key] != base;
          final phoneChanged = mine[key] != null && mine[key] != base;
          if (computerChanged && phoneChanged && mine[key] != theirs[key]) conflicts.add(ScreenConflict(key: key, title: titles[key] ?? key));
        }
      }
      await store.saveSynced(surveyId, synced.version, synced.sections, baseline: theirs);
      await releaseHeldBack?.call();
      _set(state.copyWith(cloudVersion: synced.version, cloudStatus: synced.status, appVersion: synced.version, hasEdits: true, heldBackChanges: 0, conflicts: conflicts));
      summary = await photos?.pull(surveyId);
    }, done: 'Synchronised. Your PDF and Word reports now use the edited wording.');
    final s = summary;
    if (s != null && s.changedAnything && state.error == null) {
      _set(state.copyWith(notice: '${state.notice ?? 'Synchronised.'} Photos: ${s.describe()}.'));
    } else if (s != null && s.failed > 0 && state.error == null) {
      _set(state.copyWith(notice: '${state.notice ?? 'Synchronised.'} ${s.describe()}. Synchronise again to retry.'));
    }
  }

  /// The owner's decision for the screens in [DesktopEditingState.conflicts]: the ones in [keepMine] keep the phone's wording,
  /// the others take the computer's.
  Future<void> resolveConflicts(Set<String> keepMine) async {
    await store.saveKept(surveyId, keepMine.toList());
    final kept = keepMine.length;
    final taken = state.conflicts.length - kept;
    _set(state.copyWith(
      conflicts: const [],
      notice: 'Done. $kept screen${kept == 1 ? '' : 's'} keep your wording, $taken take${taken == 1 ? 's' : ''} the computer\\'s.',
    ));
  }

"""
    t = t.replace(old, new)
    return t


rw('lib/features/report_editing/presentation/providers/desktop_editing_controller.dart', ctrl)
print('ok')
