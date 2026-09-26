import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../shared/presentation/widgets/empty_state.dart';
import '../../../../shared/presentation/widgets/survey_card.dart';
import '../providers/dashboard_provider.dart';

/// Filtered list of jobs opened from a dashboard metric card, the "This week"
/// card, or a Survey Folder card. Scoped to one segment (Home Surveys /
/// Valuations).
///
/// When [showFilterBar] is true (the Survey Folder "View all" path), a
/// status-filter selector is shown offering exactly All / Live / In Progress /
/// Completed — per the client's App-Edit brief. When false (a metric card), a
/// single fixed [initialFilter] is shown with no selector, as before.
///
/// Reuses the existing [SurveyCard] and [EmptyState] widgets so the screen is
/// visually identical to the rest of the app — no new styling introduced.
class JobsListPage extends ConsumerStatefulWidget {
  const JobsListPage({
    required this.segment,
    required this.initialFilter,
    this.showFilterBar = false,
    super.key,
  });

  final HomeSegment segment;
  final JobFilter initialFilter;
  final bool showFilterBar;

  /// The status filters offered by the "View all" selector, in order.
  static const List<JobFilter> filterBarOptions = <JobFilter>[
    JobFilter.all,
    JobFilter.live,
    JobFilter.inProgress,
    JobFilter.completed,
  ];

  @override
  ConsumerState<JobsListPage> createState() => _JobsListPageState();
}

class _JobsListPageState extends ConsumerState<JobsListPage> {
  late JobFilter _filter = widget.initialFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jobsAsync = ref.watch(
      jobsListProvider((segment: widget.segment, filter: _filter)),
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.showFilterBar ? widget.segment.label : _filter.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              widget.showFilterBar ? 'Survey Folder' : widget.segment.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        bottom: widget.showFilterBar
            ? PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: _FilterBar(
                  selected: _filter,
                  onChanged: (f) => setState(() => _filter = f),
                ),
              )
            : null,
      ),
      body: SafeArea(
        top: false,
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
                title: 'No ${_filter.title.toLowerCase()}',
                description:
                    'There are no ${widget.segment.label.toLowerCase()} in this list yet',
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(
                  jobsListProvider(
                      (segment: widget.segment, filter: _filter)),
                );
                await ref.read(
                  jobsListProvider((segment: widget.segment, filter: _filter))
                      .future,
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

/// The All / Live / In Progress / Completed selector for the Survey Folder
/// "View all" list. Uses [ChoiceChip]s so it inherits the app theme.
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final JobFilter selected;
  final ValueChanged<JobFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: JobsListPage.filterBarOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = JobsListPage.filterBarOptions[index];
          // "Live Bookings" is a long label; shorten to "Live" in the chip.
          final label =
              option == JobFilter.live ? 'Live' : option.title;
          return ChoiceChip(
            label: Text(label),
            selected: option == selected,
            onSelected: (_) => onChanged(option),
          );
        },
      ),
    );
  }
}
