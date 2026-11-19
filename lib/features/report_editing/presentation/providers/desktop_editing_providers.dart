import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_providers.dart';
import '../../../../core/network/api_client.dart';
import '../../../report_export/presentation/providers/export_providers.dart';
import '../../data/media_dao_photos.dart';
import '../../data/photo_sync_service.dart';
import '../../data/report_archive_client.dart';
import '../../data/report_editing_api.dart';
import 'desktop_edit_store_provider.dart';
import 'desktop_editing_controller.dart';

export 'desktop_edit_store_provider.dart';

final reportEditingApiProvider = Provider<ReportEditingApi>((ref) => ReportEditingApi(ref.watch(dioProvider)));

final reportArchiveClientProvider = Provider<ReportArchiveClient>((ref) => ReportArchiveClient(ref.watch(reportEditingApiProvider)));

/// Where downloaded archives are kept on the phone.
Future<Directory> archivesDirectory() async => Directory(p.join((await getApplicationDocumentsDirectory()).path, 'archives'));

final photoSyncServiceProvider = Provider<PhotoSyncService>((ref) {
  return PhotoSyncService(
    api: ref.watch(reportEditingApiProvider),
    local: MediaDaoPhotos(ref.watch(mediaDaoProvider), () async => Directory(p.join((await getApplicationDocumentsDirectory()).path, 'media'))),
  );
});

class DesktopEditingArgs {
  const DesktopEditingArgs({required this.surveyId, required this.isValuation});
  final String surveyId;
  final bool isValuation;

  @override
  bool operator ==(Object other) => other is DesktopEditingArgs && other.surveyId == surveyId && other.isValuation == isValuation;

  @override
  int get hashCode => Object.hash(surveyId, isValuation);
}

final desktopEditingProvider = StateNotifierProvider.autoDispose.family<DesktopEditingController, DesktopEditingState, DesktopEditingArgs>((ref, args) {
  return DesktopEditingController(
    surveyId: args.surveyId,
    reportType: args.isValuation ? 'VALUATION' : 'L2',
    api: ref.watch(reportEditingApiProvider),
    store: ref.watch(desktopEditStoreProvider),
    photos: ref.watch(photoSyncServiceProvider),
    buildDocument: () => ref.read(exportServiceProvider).buildDocumentForEditing(args.surveyId, valuation: args.isValuation),
    archive: ref.watch(reportArchiveClientProvider),
    archiveDir: archivesDirectory,
    heldBack: () async => (await _heldBackItems(ref, args.surveyId)).length,
    releaseHeldBack: () async {
      final dao = ref.read(syncQueueDaoProvider);
      for (final item in await _heldBackItems(ref, args.surveyId)) {
        await dao.resolveConflictKeepLocal(item.id);
      }
    },
  );
});

/// Changes of this survey that the cloud refused because the report was edited on a computer first. They wait in the queue
/// (status conflict), nothing is lost; after a synchronise they are put back to be sent.
Future<List<SyncQueueData>> _heldBackItems(Ref ref, String surveyId) async {
  final items = await ref.read(syncQueueDaoProvider).getConflictItems();
  bool ofThisSurvey(SyncQueueData item) {
    if (item.entityType == 'survey') return item.entityId == surveyId;
    try {
      final payload = jsonDecode(item.payload);
      return payload is Map && payload['surveyId'] == surveyId;
    } on FormatException {
      return false;
    }
  }

  return items.where(ofThisSurvey).toList();
}
