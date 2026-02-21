import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/field_phrase_processor.dart';
import '../../../../app/router/routes.dart';
import '../providers/inspection_providers.dart';
import '../widgets/inspection_fields.dart';
import '../../../media/presentation/widgets/photo_grid.dart';

class InspectionScreenPage extends ConsumerWidget {
  const InspectionScreenPage({
    required this.surveyId,
    required this.screenId,
    super.key,
  });

  final String surveyId;
  final String screenId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (surveyId: surveyId, screenId: screenId);
    final state = ref.watch(inspectionScreenProvider(params));
    final notifier = ref.read(inspectionScreenProvider(params).notifier);
    final phraseEngine = ref.watch(inspectionPhraseEngineProvider);

    void goBack() => context.canPop()
        ? context.pop()
        : context.go(Routes.surveyDetailPath(surveyId));

    if (state.isLoading) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) goBack();
        },
        child: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (state.screenDefinition == null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) goBack();
        },
        child: Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: goBack),
            title: const Text('Screen'),
          ),
          body: const Center(child: Text('Screen not found.')),
        ),
      );
    }

    final screen = state.screenDefinition!;
    final visibleFields =
        screen.fields.where((field) => shouldShowInspectionField(field, state.answers)).toList();
    final enginePhrases = phraseEngine?.buildPhrases(screenId, state.answers) ?? const <String>[];
    final fieldPhrases = FieldPhraseProcessor.buildFieldPhrases(screen.fields, state.answers);
    final phrases = [...enginePhrases, ...fieldPhrases];
    final showCompass = screenId == 'activity_property_facing';
    final isFloorPlanCapture = screenId == 'activity_capture_floor_site_plan_sketches';
    final floorPlanSectionId = 'inspection_v2_floor_plan_$surveyId';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) goBack();
      },
      child: Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: goBack),
        title: Text(screen.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: isFloorPlanCapture
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.architecture_outlined,
                              size: 22,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Capture floor/site plan sketches',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add up to 5 photos of floor or site plan sketches.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        PhotoGrid(
                          surveyId: surveyId,
                          sectionId: floorPlanSectionId,
                          maxPhotos: 5,
                          crossAxisCount: 3,
                          showAddButton: true,
                        ),
                      ],
                    )
                  : visibleFields.isEmpty
                      ? const Center(child: Text('No fields defined for this screen yet.'))
                      : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: visibleFields.length + (showCompass ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (showCompass && index == 0) {
                          return FilledButton.tonalIcon(
                            onPressed: () => context.push(Routes.inspectionCompassPath(surveyId)),
                            icon: const Icon(Icons.explore_outlined, size: 20),
                            label: const Text('Open Compass'),
                          );
                        }
                        final fieldIndex = showCompass ? index - 1 : index;
                        final field = visibleFields[fieldIndex];
                        final value = state.answers[field.id] ?? '';
                        return InspectionFieldInput(
                          field: field,
                          value: value,
                          onChanged: (next) => notifier.setAnswer(field.id, next),
                        );
                      },
                    ),
            ),
            if (phrases.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: InspectionPhrasePreview(phrases: phrases),
                ),
              ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: state.isSaving
                              ? null
                              : () async {
                                  final ok = await notifier.saveDraft();
                                  if (ok && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Draft saved')),
                                    );
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.save_outlined,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Save Draft',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: state.isSaving
                              ? null
                              : () async {
                                  final ok = await notifier.markComplete();
                                  if (ok && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Screen completed')),
                                    );
                                    context.pop();
                                  }
                                },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Mark Complete',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
