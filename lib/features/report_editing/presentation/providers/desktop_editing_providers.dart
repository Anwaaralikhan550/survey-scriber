import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../report_export/presentation/providers/export_providers.dart';
import '../../data/report_editing_api.dart';
import 'desktop_edit_store_provider.dart';
import 'desktop_editing_controller.dart';

export 'desktop_edit_store_provider.dart';

final reportEditingApiProvider = Provider<ReportEditingApi>((ref) => ReportEditingApi(ref.watch(dioProvider)));

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
    buildDocument: () => ref.read(exportServiceProvider).buildDocumentForEditing(args.surveyId, valuation: args.isValuation),
  );
});
