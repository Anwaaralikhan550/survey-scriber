import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/database/app_database.dart';
import '../providers/valuation_providers.dart';

class ValuationSectionPage extends ConsumerWidget {
  const ValuationSectionPage({
    required this.surveyId,
    required this.sectionKey,
    this.parentNodeId,
    super.key,
  });

  final String surveyId;
  final String sectionKey;
  final String? parentNodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final nodesAsync = ref.watch(
      valuationNodesProvider((surveyId: surveyId, sectionKey: sectionKey)),
    );

    final sectionColor = _sectionColor(sectionKey, theme);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.canPop()
              ? context.pop()
              : context.go(Routes.surveyDetailPath(surveyId));
        }
      },
      child: Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(Routes.surveyDetailPath(surveyId)),
        ),
        title: Text(_sectionTitle(sectionKey)),
      ),
      body: SafeArea(
        child: nodesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Failed to load screens: $error'),
            ),
          ),
          data: (nodes) {
            final visibleNodes = nodes
                .where((node) => node.parentId == parentNodeId)
                .toList();

            if (visibleNodes.isEmpty) {
              return const Center(child: Text('No screens yet.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: visibleNodes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final node = visibleNodes[index];
                if (node.nodeType == 'group') {
                  return _GroupTile(
                    title: node.title,
                    sectionColor: sectionColor,
                    icon: _valuationIconForTitle(node.title, node.screenId),
                    onTap: () => context.push(
                      Routes.valuationNodePath(surveyId, sectionKey, node.screenId),
                    ),
                  );
                }

                return _ScreenTile(
                  screen: node,
                  sectionColor: sectionColor,
                  iconData: _valuationIconForTitle(node.title, node.screenId),
                  onTap: () => context.push(
                    Routes.valuationScreenPath(surveyId, sectionKey, node.screenId),
                  ),
                );
              },
            );
          },
        ),
      ),
      ),
    );
  }

  String _sectionTitle(String key) => switch (key) {
        'valuation_details' => 'Valuation Details',
        'property_assessment' => 'Property Assessment',
        'property_inspection' => 'Property Inspection',
        'condition_restrictions' => 'Condition & Restrictions',
        'valuation_completion' => 'Valuation & Completion',
        _ => 'Section $key',
      };

  Color _sectionColor(String key, ThemeData theme) => switch (key) {
        'valuation_details' => const Color(0xFF1565C0),
        'property_assessment' => const Color(0xFF00796B),
        'property_inspection' => const Color(0xFF6A1B9A),
        'condition_restrictions' => const Color(0xFFE65100),
        'valuation_completion' => const Color(0xFF2E7D32),
        _ => theme.colorScheme.primary,
      };
}

IconData _valuationIconForTitle(String title, [String screenId = '']) {
  final t = title.toLowerCase();

  // Valuation-specific screens
  if (t.contains('general details')) return Icons.description_outlined;
  if (t.contains('new build')) return Icons.construction_outlined;
  if (t.contains('number of rooms')) return Icons.meeting_room_outlined;
  if (t.contains('accommodation')) return Icons.summarize_outlined;
  if (t.contains('location') || t.contains('amenities')) return Icons.pin_drop_outlined;
  if (t.contains('road')) return Icons.alt_route_outlined;
  if (t.contains('overall condition')) return Icons.assessment_outlined;
  if (t.contains('other matters')) return Icons.more_horiz_outlined;
  if (t.contains('valuation') && !t.contains('details')) return Icons.attach_money_outlined;
  if (t.contains('general remarks')) return Icons.notes_outlined;
  if (t.contains('scan') || t.contains('floor plan')) return Icons.draw_outlined;

  // Outside property PID
  if (t.contains('outside property')) return Icons.roofing_outlined;
  if (t == 'roof') return Icons.roofing_outlined;
  if (t.contains('pitched roof')) return Icons.roofing_outlined;
  if (t.contains('flat roof')) return Icons.crop_square_outlined;
  if (t.contains('other roof')) return Icons.dashboard_outlined;
  if (t.contains('flashing')) return Icons.flash_on_outlined;
  if (t.contains('rainwater')) return Icons.water_outlined;
  if (t.contains('chimney stacks')) return Icons.fireplace_outlined;
  if (t.contains('chimney breasts')) return Icons.fireplace_outlined;
  if (t.contains('walls type') || t.contains('walls internal')) return Icons.grid_view_outlined;
  if (t.contains('wall tie')) return Icons.link_outlined;
  if (t.contains('floor')) return Icons.view_agenda_outlined;
  if (t.contains('dpc')) return Icons.layers_outlined;
  if (t.contains('sub floor')) return Icons.air_outlined;
  if (t.contains('decoration')) return Icons.format_paint_outlined;
  if (t.contains('garage')) return Icons.garage_outlined;
  if (t.contains('outbuilding')) return Icons.cottage_outlined;
  if (t.contains('site')) return Icons.terrain_outlined;
  if (t.contains('drainage')) return Icons.plumbing_outlined;

  // Inside property PID
  if (t.contains('inside property')) return Icons.door_front_door_outlined;
  if (t.contains('roof space')) return Icons.space_dashboard_outlined;
  if (t.contains('external joinery')) return Icons.handyman_outlined;
  if (t.contains('ceiling')) return Icons.flip_outlined;
  if (t.contains('internal fitting')) return Icons.kitchen_outlined;
  if (t.contains('damp')) return Icons.water_damage_outlined;
  if (t.contains('timber')) return Icons.forest_outlined;
  if (t.contains('electric')) return Icons.electrical_services_outlined;
  if (t.contains('gas')) return Icons.gas_meter_outlined;
  if (t.contains('water')) return Icons.water_outlined;
  if (t.contains('hot water') || t.contains('central heating')) return Icons.thermostat_outlined;
  if (t.contains('smoke')) return Icons.sensors_outlined;

  return Icons.article_outlined;
}

class _ScreenTile extends StatelessWidget {
  const _ScreenTile({
    required this.screen,
    required this.sectionColor,
    required this.iconData,
    required this.onTap,
  });

  final InspectionV2Screen screen;
  final Color sectionColor;
  final IconData iconData;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isComplete = screen.isCompleted;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isComplete
                  ? sectionColor.withOpacity(0.4)
                  : theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isComplete
                            ? sectionColor.withOpacity(0.15)
                            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          iconData,
                          size: 20,
                          color: isComplete
                              ? sectionColor
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (isComplete)
                      Positioned(
                        right: -3,
                        bottom: -3,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: sectionColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 11,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  screen.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.title,
    required this.sectionColor,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final Color sectionColor;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sectionColor.withOpacity(0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: sectionColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 20,
                    color: sectionColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
