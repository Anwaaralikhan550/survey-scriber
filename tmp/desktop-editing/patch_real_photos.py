p = r'E:/survey-scriber/test/features/report_editing/desktop_editing_real_backend_test.dart'
t = open(p, encoding='utf-8').read()

t = t.replace(
    "import 'package:survey_scriber/features/report_editing/data/desktop_edit_store.dart';",
    "import 'package:survey_scriber/features/report_editing/data/desktop_edit_store.dart';\nimport 'package:survey_scriber/features/report_editing/data/photo_sync_service.dart';",
    1,
)

helper = '''class _LocalPhotos implements LocalPhotos {
  _LocalPhotos(this.dir);
  final Directory dir;
  final rows = <String, LocalPhoto>{};
  int n = 0;
  @override
  Future<List<LocalPhoto>> forSurvey(String surveyId) async => rows.values.toList();
  @override
  Future<void> insert(LocalPhoto photo, {required int fileSize}) async => rows[photo.id] = photo;
  @override
  Future<void> update(String id, {String? caption, int? sortOrder, String? sectionId}) async {
    final o = rows[id]!;
    rows[id] = LocalPhoto(
      id: o.id,
      surveyId: o.surveyId,
      sectionId: sectionId ?? o.sectionId,
      localPath: o.localPath,
      remoteId: o.remoteId,
      caption: caption == null ? o.caption : (caption.isEmpty ? null : caption),
      sortOrder: sortOrder ?? o.sortOrder,
      synced: o.synced,
    );
  }

  @override
  Future<void> delete(String id) async {
    final f = File(rows[id]!.localPath);
    if (f.existsSync() && !f.path.contains('fixtures')) f.deleteSync();
    rows.remove(id);
  }

  @override
  Future<String> newFilePath(String surveyId, String extension) async => '${dir.path}/photo_${n++}.$extension';
}

void main() {'''
t = t.replace('void main() {', helper, 1)
t = t.replace(
    "  final enabled = url != null && token != null && surveyId != null;",
    "  final surveyId2 = Platform.environment['REAL_SURVEY_ID_2'];\n  final enabled = url != null && token != null && surveyId != null;",
    1,
)

new_test = open(r'E:/survey-scriber/tmp/desktop-editing/real_photos_test_body.dart.txt', encoding='utf-8').read()
t = t.rstrip()
assert t.endswith('}')
t = t[:-1] + new_test + '}\n'
open(p, 'w', encoding='utf-8').write(t)
print('ok')
