def rw(p, fn):
    t = open(p, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in t else '\n'
    t = fn(t.replace('\r\n', '\n'))
    open(p, 'w', encoding='utf-8', newline='').write(t.replace('\n', nl))


def sub(t, a, b):
    assert t.count(a) == 1, (t.count(a), a[:70])
    return t.replace(a, b, 1)


def sm(t):
    # the version of the cloud report this phone has, sent with changes to a survey that may have been edited on a computer
    t = sub(t, "  final apiClient = ref.watch(apiClientProvider);\n  final syncQueueDao", "  final apiClient = ref.watch(apiClientProvider);\n  final editStore = ref.watch(desktopEditStoreProvider);\n  final syncQueueDao")
    t = sub(t, "    mediaDao: mediaDao,\n    db: db,\n  );\n});", "    mediaDao: mediaDao,\n    db: db,\n    reportVersionFor: (surveyId) async => (await editStore.read(surveyId)).appVersion,\n  );\n});")
    t = sub(t, "            await apiClient.put('surveys/$entityId', data: payload);", "            await apiClient.put('surveys/$entityId', data: payload, options: await _reportVersionOptions(surveyId: entityId));")
    t = sub(t, "            await apiClient.delete('surveys/$entityId');", "            await apiClient.delete('surveys/$entityId', options: await _reportVersionOptions(surveyId: entityId));")
    t = sub(t, "            await apiClient.put('sections/$entityId', data: updatePayload);", "            await apiClient.put('sections/$entityId', data: updatePayload, options: await _reportVersionOptions(surveyId: surveyId, sectionId: entityId));")
    t = sub(t, "            await apiClient.delete('sections/$entityId');", "            await apiClient.delete('sections/$entityId', options: await _reportVersionOptions(surveyId: surveyId, sectionId: entityId));")
    t = sub(t, "            await apiClient.put('answers/$entityId', data: bodyPayload);", "            await apiClient.put('answers/$entityId', data: bodyPayload, options: await _reportVersionOptions(surveyId: surveyIdHint, sectionId: sectionId));")
    t = sub(t, "            await apiClient.delete('answers/$entityId');", "            await apiClient.delete('answers/$entityId', options: await _reportVersionOptions(surveyId: surveyIdHint, sectionId: sectionId));")
    t = sub(t, "  /// Check if error is a 409 conflict.", """  /// The cloud report version this phone has, as the X-Report-Version header (Remote Editor spec v1.4 section 11). The server holds
  /// back a change to a survey that was edited on a computer unless the phone has taken those edits. Null when the phone has no
  /// cloud report for the survey, or the survey cannot be worked out.
  Future<Options?> _reportVersionOptions({String? surveyId, String? sectionId}) async {
    final source = reportVersionFor;
    if (source == null) return null;
    var id = surveyId;
    if (id == null && sectionId != null) {
      id = (await sectionsDao.getSectionById(sectionId))?.surveyId;
    }
    if (id == null) return null;
    final version = await source(id);
    return version == null ? null : Options(headers: {'X-Report-Version': '$version'});
  }

  /// Check if error is a 409 conflict.""")
    return t


rw('lib/core/sync/sync_manager.dart', sm)
print('ok')
