import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/presentation/widgets/survey_card.dart';
import '../providers/search_provider.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    final theme = Theme.of(context);

    // FIX #1: resizeToAvoidBottomInset handles keyboard properly
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: CustomScrollView(
          // Ensure keyboard doesn't cause overflow
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    _buildSearchField(theme, state),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildFilterSection(context, ref, state, theme),
            ),
            if (state.hasError)
              _buildErrorState(context, state, theme)
            else if (state.isSearching)
              _buildLoadingState(theme)
            else if (!state.hasSearched)
              _buildInitialState()
            else if (!state.hasResults)
              _buildNoResultsState(state.query)
            else
              _buildResultsList(context, state),
            // Bottom padding for navigation bar
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme, SearchState state) => TextField(
        controller: _searchController,
        focusNode: _focusNode,
        onChanged: (value) {
          ref.read(searchProvider.notifier).search(value);
        },
        decoration: InputDecoration(
          hintText: 'Search surveys, clients, addresses...',
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          suffixIcon: state.query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchProvider.notifier).clearSearch();
                  },
                )
              : null,
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      );

  Widget _buildFilterSection(
    BuildContext context,
    WidgetRef ref,
    SearchState state,
    ThemeData theme,
  ) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Filters',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (state.filters.hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${state.filters.activeFilterCount}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ref.read(searchProvider.notifier).clearFilters();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Clear all',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: _getTypeLabel(state.filters.type),
                  icon: Icons.category_rounded,
                  isActive: state.filters.type != SearchFilterType.all,
                  onTap: () => _showTypeFilterSheet(context, ref, state),
                ),
                _FilterChip(
                  label: _getStatusLabel(state.filters.status),
                  icon: Icons.flag_rounded,
                  isActive: state.filters.status != SearchFilterStatus.all,
                  onTap: () => _showStatusFilterSheet(context, ref, state),
                ),
                _FilterChip(
                  label: _getDateLabel(state.filters.dateRange),
                  icon: Icons.calendar_month,
                  isActive: state.filters.dateRange.hasFilter,
                  onTap: () => _showDateFilterSheet(context, ref, state),
                ),
                _FilterChip(
                  label: state.filters.clientName ?? 'Client',
                  icon: Icons.person_rounded,
                  isActive: state.filters.clientName != null && state.filters.clientName!.isNotEmpty,
                  onTap: () => _showClientFilterSheet(context, ref, state),
                ),
              ],
            ),
          ],
        ),
      );

  String _getTypeLabel(SearchFilterType type) => switch (type) {
        SearchFilterType.all => 'Type',
        SearchFilterType.inspection => 'Inspection',
        SearchFilterType.valuation => 'Valuation',
        SearchFilterType.reinspection => 'Re-inspection',
      };

  String _getStatusLabel(SearchFilterStatus status) => switch (status) {
        SearchFilterStatus.all => 'Status',
        SearchFilterStatus.draft => 'Draft',
        SearchFilterStatus.inProgress => 'In Progress',
        SearchFilterStatus.paused => 'Paused',
        SearchFilterStatus.completed => 'Completed',
        SearchFilterStatus.pendingReview => 'Pending Review',
        SearchFilterStatus.approved => 'Approved',
        SearchFilterStatus.rejected => 'Rejected',
      };

  String _getDateLabel(DateRangeFilter dateRange) {
    if (!dateRange.hasFilter) return 'Date';
    final formatter = DateFormat('MMM d');
    if (dateRange.from != null && dateRange.to != null) {
      return '${formatter.format(dateRange.from!)} - ${formatter.format(dateRange.to!)}';
    } else if (dateRange.from != null) {
      return 'From ${formatter.format(dateRange.from!)}';
    } else {
      return 'Until ${formatter.format(dateRange.to!)}';
    }
  }

  // FIX #2: Make Survey Type modal scrollable with isScrollControlled
  void _showTypeFilterSheet(BuildContext context, WidgetRef ref, SearchState state) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true, // Allow sheet to resize properly
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          // Limit max height to avoid overflow
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Survey Type',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Wrap in Flexible + SingleChildScrollView to prevent overflow
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: SearchFilterType.values
                        .map(
                          (type) => RadioListTile<SearchFilterType>(
                            title: Text(_getTypeLabel(type)),
                            value: type,
                            groupValue: state.filters.type,
                            onChanged: (value) {
                              if (value != null) {
                                ref.read(searchProvider.notifier).setTypeFilter(value);
                                Navigator.pop(context);
                              }
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatusFilterSheet(BuildContext context, WidgetRef ref, SearchState state) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Survey Status',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: SearchFilterStatus.values
                      .map(
                        (status) => RadioListTile<SearchFilterStatus>(
                          title: Text(_getStatusLabel(status)),
                          value: status,
                          groupValue: state.filters.status,
                          onChanged: (value) {
                            if (value != null) {
                              ref.read(searchProvider.notifier).setStatusFilter(value);
                              Navigator.pop(context);
                            }
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDateFilterSheet(BuildContext context, WidgetRef ref, SearchState state) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Consumer(
        builder: (consumerContext, consumerRef, _) {
          // Watch the provider to get live updates when dates change
          final currentState = consumerRef.watch(searchProvider);
          final dateRange = currentState.filters.dateRange;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Date Range',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(sheetContext),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _DatePickerButton(
                          label: 'From',
                          date: dateRange.from,
                          onDateSelected: (date) {
                            consumerRef.read(searchProvider.notifier).setDateRange(
                                  date,
                                  dateRange.to,
                                );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DatePickerButton(
                          label: 'To',
                          date: dateRange.to,
                          onDateSelected: (date) {
                            consumerRef.read(searchProvider.notifier).setDateRange(
                                  dateRange.from,
                                  date,
                                );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (dateRange.hasFilter)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          consumerRef.read(searchProvider.notifier).setDateRange(null, null);
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Clear Date Filter'),
                      ),
                    ),
                  if (dateRange.hasFilter) const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Apply'),
                    ),
                  ),
                  // Extra spacing to clear the FAB
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showClientFilterSheet(BuildContext context, WidgetRef ref, SearchState state) {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: state.filters.clientName);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Client Name',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Enter client name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.person_rounded),
                  ),
                  onSubmitted: (value) {
                    ref.read(searchProvider.notifier).setClientFilter(value.trim().isEmpty ? null : value.trim());
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (state.filters.clientName != null && state.filters.clientName!.isNotEmpty)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ref.read(searchProvider.notifier).setClientFilter(null);
                            Navigator.pop(context);
                          },
                          child: const Text('Clear'),
                        ),
                      ),
                    if (state.filters.clientName != null && state.filters.clientName!.isNotEmpty)
                      const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final value = controller.text.trim();
                          ref.read(searchProvider.notifier).setClientFilter(value.isEmpty ? null : value);
                          Navigator.pop(context);
                        },
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) => SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AnimatedShimmerCard(theme: theme, delay: index * 150),
            ),
            childCount: 3,
          ),
        ),
      );

  // FIX #1: Add hasScrollBody: false to prevent overflow with keyboard
  Widget _buildInitialState() => const SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyState(
          icon: Icons.search_rounded,
          title: 'Search surveys',
          description: 'Find surveys by title, client name, or address',
        ),
      );

  Widget _buildNoResultsState(String query) => const SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyState(
          icon: Icons.search_off_rounded,
          title: 'No results found',
          description: 'Try a different search term or adjust filters',
        ),
      );

  Widget _buildErrorState(BuildContext context, SearchState state, ThemeData theme) => SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyState(
          icon: state.errorType == SearchErrorType.network ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
          title: state.errorType == SearchErrorType.network ? 'No connection' : 'Something went wrong',
          description: state.errorMessage ?? 'Please try again',
          action: state.canRetry
              ? FilledButton.icon(
                  onPressed: () => ref.read(searchProvider.notifier).retry(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                )
              : null,
        ),
      );

  Widget _buildResultsList(BuildContext context, SearchState state) =>
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    '${state.totalResults} result${state.totalResults == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                );
              }

              final survey = state.results[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SurveyCard(
                  survey: survey,
                  showProgress: survey.isInProgress,
                  onTap: () {
                    context.push(Routes.surveyDetailPath(survey.id));
                  },
                ),
              );
            },
            childCount: state.results.length + 1,
          ),
        ),
      );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isActive ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Professional Date Picker Button with icon, placeholder, and proper styling
class _DatePickerButton extends StatelessWidget {
  const _DatePickerButton({
    required this.label,
    required this.date,
    required this.onDateSelected,
  });

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime?> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd/MM/yyyy');
    final hasDate = date != null;

    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (selectedDate != null) {
          onDateSelected(selectedDate);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: hasDate ? AppColors.primary.withOpacity(0.05) : Colors.white,
          border: Border.all(
            color: hasDate ? AppColors.primary : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Calendar Icon
            const Icon(
              Icons.calendar_month,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            // Label and Date/Placeholder
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label (From / To)
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Date or Placeholder
                  Text(
                    hasDate ? formatter.format(date!) : 'Select Date',
                    style: TextStyle(
                      color: hasDate ? Colors.black87 : Colors.grey.shade400,
                      fontWeight: hasDate ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Allow shrinking for keyboard
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// Animated shimmer card for loading state
class _AnimatedShimmerCard extends StatefulWidget {
  const _AnimatedShimmerCard({
    required this.theme,
    this.delay = 0,
  });

  final ThemeData theme;
  final int delay;

  @override
  State<_AnimatedShimmerCard> createState() => _AnimatedShimmerCardState();
}

class _AnimatedShimmerCardState extends State<_AnimatedShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.theme.colorScheme.outlineVariant.withOpacity(0.4),
          ),
        ),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _shimmerBox(42, 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmerBox(double.infinity, 16),
                        const SizedBox(height: 8),
                        _shimmerBox(120, 12),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _shimmerBox(180, 12),
            ],
          ),
        ),
      );

  Widget _shimmerBox(double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: widget.theme.colorScheme.surfaceContainerHighest
              .withOpacity(_animation.value),
          borderRadius: BorderRadius.circular(6),
        ),
      );
}
