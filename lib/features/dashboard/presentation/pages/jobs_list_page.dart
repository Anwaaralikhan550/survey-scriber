import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../shared/presentation/widgets/empty_state.dart';
import '../../../../shared/presentation/widgets/survey_card.dart';
import '../providers/dashboard_provider.dart';

/// Filtered list of jobs opened from a dashboard metric card or the
/// "This week" card. Scoped to one segment (Home Surveys / Valuations) and
/// one status filter (live / in progress / completed / this week).
///
/// Reuses the existing [SurveyCard] and [EmptyState] widgets so the screen is
/// visually identical to the rest of the app — no new styling introduced.
class JobsListPage extends ConsumerWidget {
  const JobsListPage({
    required this.segment,
    required this.filter,
    super.key,
  });

  final HomeSegment segment;
  final JobFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final jobsAsync = ref.watch(
      jobsListProvider((segment: segment, filter: filter)),
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              filter.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              segment.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: jobsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(
            child: EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Could not load jobs',
              description: 'Pull to refresh or try again shortly',
            ),
          ),
          data: (surveys) {
            if (surveys.isEmpty) {
              return EmptyState(
                icon: Icons.assignment_outlined,
                title: 'No ${filter.title.toLowerCase()}',
                description:
                    'There are no ${segment.label.toLowerCase()} in this list yet',
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(
                  jobsListProvider((segment: segment, filter: filter)),
                );
                await ref.read(
                  jobsListProvider((segment: segment, filter: filter)).future,
                );
              },
              color: theme.colorScheme.primary,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                itemCount: surveys.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final survey = surveys[index];
                  return SurveyCard(
                    survey: survey,
                    onTap: () =>
                        context.push(Routes.surveyDetailPath(survey.id)),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
