// Mark Complete on EVERY inspection screen (1 Nov 2026 sweep).
//
// The client found screens that could not be completed only where she happened
// to work. This drives the real InspectionScreenNotifier (real repository,
// in-memory database) for all screens in the bundled tree, twice:
//   A. nothing selected   -> must complete (non-applicable options are optional)
//   B. everything filled  -> every checkbox ticked (including "Other"), first
//      dropdown option, every text/number box filled -> must complete
// Any screen that refuses is listed with the message the surveyor would see.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:survey_scriber/core/database/app_database.dart';
import 'package:survey_scriber/core/database/database_providers.dart';
import 'package:survey_scriber/features/property_inspection/data/inspection_repository.dart';
import 'package:survey_scriber/features/property_inspection/domain/models/inspection_models.dart';
import 'package:survey_scriber/features/property_inspection/presentation/providers/inspection_providers.dart';

String _fillValue(InspectionFieldDefinition f) {
  switch (f.type) {
    case InspectionFieldType.checkbox:
      return 'true';
    case InspectionFieldType.dropdown:
      return (f.options ?? const <String>[]).isEmpty ? '' : f.options!.first;
    case InspectionFieldType.number:
      return '1';
    case InspectionFieldType.text:
      return 'Test text';
    default:
      return '';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every screen can be marked complete (empty and fully filled)', () async {
    final tree = InspectionTreePayload.fromJson(
      File('assets/property_inspection/inspection_tree.json').readAsStringSync(),
    );
    final screens = [
      for (final s in tree.sections)
        for (final n in s.nodes)
          if (n.type == InspectionNodeType.screen) n,
    ];

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      inspectionRepositoryProvider.overrideWithValue(InspectionRepository(db)),
    ]);
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    final failures = <String>[];
    for (final screen in screens) {
      for (final mode in ['empty', 'filled']) {
        final params = (surveyId: 'sweep-$mode', screenId: screen.id);
        final sub = container.listen(inspectionScreenProvider(params), (_, __) {});
        try {
          final notifier = container.read(inspectionScreenProvider(params).notifier);
          for (var i = 0; i < 400 && container.read(inspectionScreenProvider(params)).isLoading; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 5));
          }
          if (mode == 'filled') {
            for (final f in screen.fields) {
              final v = _fillValue(f);
              if (v.isNotEmpty) notifier.setAnswer(f.id, v);
            }
          }
          final ok = await notifier.markComplete();
          if (!ok) {
            final msg = container.read(inspectionScreenProvider(params)).errorMessage;
            failures.add('[$mode] ${screen.id} "${screen.title}": $msg');
          }
        } finally {
          sub.close();
        }
      }
    }

    // ignore: avoid_print
    print('Screens checked: ${screens.length} x 2. Refused: ${failures.length}\n  ${failures.join('\n  ')}');
    expect(failures, isEmpty);
  }, timeout: const Timeout(Duration(minutes: 15)));
}
