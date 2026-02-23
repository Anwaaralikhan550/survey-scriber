import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/models/inspection_models.dart';
import '../../domain/field_phrase_processor.dart';
import '../providers/inspection_providers.dart';
import '../widgets/inspection_fields.dart';

class InspectionSectionPage extends ConsumerWidget {
  const InspectionSectionPage({
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
      inspectionNodesProvider((surveyId: surveyId, sectionKey: sectionKey)),
    );
    final nodeMapAsync = ref.watch(inspectionNodeMapProvider);

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
            final nodeMap = nodeMapAsync.maybeWhen(
              data: (value) => value,
              orElse: () => const <String, InspectionNodeDefinition>{},
            );
            final visibleNodes = nodes
                .where((node) {
                  if (node.parentId != parentNodeId) return false;
                  if (node.nodeType != 'screen') return true;
                  final definition = nodeMap[node.screenId];
                  return definition?.inlinePosition != 'header';
                })
                .toList();

            if (visibleNodes.isEmpty) {
              return const Center(child: Text('No screens yet.'));
            }

            final showHeaderInline = parentNodeId != null && nodeMap[parentNodeId!]?.type == InspectionNodeType.group;
            final itemCount = visibleNodes.length + (showHeaderInline ? 1 : 0);

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: itemCount,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (showHeaderInline && index == 0) {
                  return _GroupInlineHeader(
                    surveyId: surveyId,
                    sectionKey: sectionKey,
                    parentNodeId: parentNodeId!,
                  );
                }
                final offsetIndex = showHeaderInline ? index - 1 : index;
                final node = visibleNodes[offsetIndex];
                if (node.nodeType == 'group') {
                  return _GroupTile(
                    title: node.title,
                    sectionColor: sectionColor,
                    icon: _inspectionIconForTitle(node.title, node.screenId),
                    onTap: () => context.push(
                      Routes.inspectionNodePath(surveyId, sectionKey, node.screenId),
                    ),
                  );
                }

                final screen = node;
                return _ScreenTile(
                  screen: screen,
                  sectionColor: sectionColor,
                  iconData: _inspectionIconForTitle(screen.title, screen.screenId),
                  onTap: () => context.push(
                    Routes.inspectionScreenPath(surveyId, sectionKey, screen.screenId),
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
        'A' => 'About Inspection',
        'D' => 'About the Property',
        'E' => 'Outside the Property',
        'F' => 'Inside the Property',
        'G' => 'Services',
        'H' => 'Grounds',
        'I' => 'Issues for Legal Advisers',
        'J' => 'Risks',
        'K' => 'Floor/Site Plan Sketches',
        'R' => 'Room Details',
        'O' => 'Overall Opinion',
        _ => 'Section $key',
      };

  Color _sectionColor(String key, ThemeData theme) => switch (key) {
        'A' => theme.colorScheme.primary,
        'D' => theme.colorScheme.primary,
        'E' => theme.colorScheme.tertiary,
        'F' => theme.colorScheme.secondary,
        'G' => const Color(0xFF00796B),
        'H' => const Color(0xFF2E7D32),
        'I' => const Color(0xFFE65100),
        'J' => theme.colorScheme.error,
        'K' => theme.colorScheme.primary,
        'R' => theme.colorScheme.secondary,
        _ => theme.colorScheme.primary,
      };
}

/// Maps screen / group titles (and optionally screen IDs) to unique,
/// context-relevant Material 3 icons via keyword matching.
IconData _inspectionIconForTitle(String title, [String screenId = '']) {
  final t = title.toLowerCase().replaceFirst(RegExp(r'^[a-z]\d+\s+'), '');
  final id = screenId.toLowerCase();

  // ── Property & general info ──
  if (t.contains('property type')) return Icons.home_work_outlined;
  if (t.contains('property built')) return Icons.calendar_today_outlined;
  if (t.contains('year extended') || t.contains('property extended')) return Icons.home_repair_service_outlined;
  if (t.contains('year converted') || t.contains('property converted')) return Icons.autorenew_outlined;
  if (t.contains('flat') && (t.contains('maisonette') || id.contains('flate'))) return Icons.apartment_outlined;
  if (t.contains('listed building')) return Icons.account_balance_outlined;
  if (t.contains('energy')) return Icons.bolt_outlined;
  if (t.contains('property location') || t.contains('density')) return Icons.location_on_outlined;
  if (t.contains('facilit')) return Icons.store_outlined;
  if (t.contains('local environment')) return Icons.park_outlined;
  if (t.contains('private road')) return Icons.alt_route_outlined;
  if (t.contains('noisy')) return Icons.volume_up_outlined;
  if (t.contains('topography')) return Icons.terrain_outlined;
  if (t.contains('party disclosure')) return Icons.people_outlined;
  if (t.contains('weather')) return Icons.cloud_outlined;
  if (t.contains('property status')) return Icons.info_outlined;
  if (t.contains('overall') || t.contains('over all') || t.contains('opinion')) return Icons.rate_review_outlined;
  if (t.contains('property facing')) return Icons.explore_outlined;
  if (t == 'property' && id.contains('construction')) return Icons.construction_outlined;
  if (t.contains('estated') || t.contains('estate')) return Icons.location_city_outlined;
  if (t.contains('other service')) return Icons.miscellaneous_services_outlined;

  // ── Roof ──
  if (t.contains('roof structure')) return Icons.roofing_outlined;
  if (t.contains('roof covering')) return Icons.layers_outlined;
  if (t.contains('roof flashing')) return Icons.flash_on_outlined;
  if (t.contains('roof spreading')) return Icons.open_in_full_outlined;
  if (t.contains('heavy roof')) return Icons.straighten_outlined;
  if (t.contains('flat roof')) return Icons.horizontal_rule_outlined;
  if (t.contains('roof terrace')) return Icons.deck_outlined;
  if (t.contains('roof space')) return Icons.space_dashboard_outlined;
  if (t.contains('poor roof')) return Icons.warning_outlined;
  if (t.contains('roof') && t.contains('timber')) return Icons.forest_outlined;
  if (t.contains('about') && t.contains('roof')) return Icons.roofing_outlined;
  if (t.contains('parapet')) return Icons.fence_outlined;
  if (t.contains('ridge') || t.contains('hip tile')) return Icons.grid_on_outlined;
  if (t.contains('deflection') || t.contains('undulat')) return Icons.show_chart_outlined;
  if (t.contains('verge')) return Icons.straight_outlined;
  if (t == 'pitched') return Icons.change_history_outlined;
  if (t == 'flat' && id.contains('roof')) return Icons.horizontal_rule_outlined;
  if (t == 'mansard') return Icons.roofing_outlined;
  if (t.contains('roof')) return Icons.roofing_outlined;

  // ── Chimney ──
  if (t.contains('chimney') && t.contains('leaning')) return Icons.trending_down_outlined;
  if (t.contains('chimney') && t.contains('removed')) return Icons.delete_outlined;
  if (t.contains('chimney') && t.contains('disrepair')) return Icons.warning_outlined;
  if (t.contains('chimney') && t.contains('shared')) return Icons.groups_outlined;
  if (t.contains('chimney') && t.contains('partial')) return Icons.visibility_outlined;
  if (t.contains('chimney') && t.contains('pot')) return Icons.filter_hdr_outlined;
  if (t.contains('chimney') && t.contains('repoint')) return Icons.construction_outlined;
  if (t.contains('chimney')) return Icons.fireplace_outlined;
  if (t.contains('flaunching')) return Icons.construction_outlined;
  if (t.contains('stacks')) return Icons.view_column_outlined;

  // ── Walls ──
  if (t.contains('external wall')) return Icons.view_quilt_outlined;
  if (t.contains('internal wall')) return Icons.view_column_outlined;
  if (t.contains('wall construction')) return Icons.grid_view_outlined;
  if (t.contains('solid brick')) return Icons.grid_4x4_outlined;
  if (t.contains('cavity brick')) return Icons.view_week_outlined;
  if (t.contains('cavity block')) return Icons.view_module_outlined;
  if (t.contains('cavity stud')) return Icons.view_column_outlined;
  if (t.contains('cavity') && t.contains('insulation')) return Icons.shield_outlined;
  if (t.contains('main wall')) return Icons.grid_4x4_outlined;
  if (t.contains('wall tie')) return Icons.link_outlined;
  if (t.contains('wall sealing')) return Icons.format_paint_outlined;
  if (t.contains('thin') && t.contains('wall')) return Icons.straighten_outlined;
  if (t.contains('slim') && t.contains('wall')) return Icons.straighten_outlined;
  if (t.contains('removed wall') || (t.contains('removed') && t.contains('wall'))) return Icons.content_cut_outlined;
  if (t.contains('party wall')) return Icons.horizontal_split_outlined;
  if (t.contains('walls') && t.contains('partition')) return Icons.view_column_outlined;
  if (t.contains('about') && t.contains('wall')) return Icons.grid_view_outlined;
  if (t.contains('cladding')) return Icons.view_quilt_outlined;
  if (t.contains('dpc')) return Icons.layers_outlined;
  if (t.contains('pointing')) return Icons.touch_app_outlined;
  if (t.contains('render')) return Icons.format_paint_outlined;
  if (t.contains('spalling')) return Icons.broken_image_outlined;
  if (t.contains('movement') && !t.contains('crack')) return Icons.open_in_full_outlined;
  if (t.contains('damp') && id.contains('wall')) return Icons.water_damage_outlined;
  if (t == 'walls' || t == 'wall') return Icons.grid_view_outlined;

  // ── Windows & Doors ──
  if (t.contains('velux')) return Icons.window_outlined;
  if (t.contains('safety glass')) return Icons.shield_outlined;
  if (t.contains('sill projection')) return Icons.horizontal_rule_outlined;
  if (t.contains('failed glazing')) return Icons.broken_image_outlined;
  if (t.contains('fire escape')) return Icons.warning_outlined;
  if (t.contains('about window') || t.contains('about') && id.contains('window')) return Icons.window_outlined;
  if (t.contains('window')) return Icons.window_outlined;
  if (t.contains('garage door')) return Icons.garage_outlined;
  if (t.contains('patio door')) return Icons.door_sliding_outlined;
  if (t.contains('rear door')) return Icons.sensor_door_outlined;
  if (t.contains('side door')) return Icons.door_sliding_outlined;
  if (t.contains('main door')) return Icons.door_front_door_outlined;
  if (t.contains('other door')) return Icons.door_front_door_outlined;
  if (t.contains('outside door')) return Icons.door_front_door_outlined;
  if (t == 'pvc' || t == 'timber' || t == 'steel' || t == 'aluminium') {
    if (id.contains('door')) return Icons.door_front_door_outlined;
  }
  if (t.contains('door')) return Icons.door_front_door_outlined;
  if (t.contains('lintel')) return Icons.horizontal_rule_outlined;
  if (t.contains('glazing')) return Icons.window_outlined;

  // ── Fireplaces ──
  if (t.contains('blocked fireplace')) return Icons.block_outlined;
  if (t.contains('damage') && t.contains('grate')) return Icons.broken_image_outlined;
  if (t.contains('damage') && t.contains('surround')) return Icons.crop_square_outlined;
  if (t.contains('wood burning')) return Icons.local_fire_department_outlined;
  if (t.contains('electric fire')) return Icons.electric_bolt_outlined;
  if (t.contains('gas fire')) return Icons.gas_meter_outlined;
  if (t.contains('open fire')) return Icons.fireplace_outlined;
  if (t.contains('imitation')) return Icons.style_outlined;
  if (t.contains('flue')) return Icons.air_outlined;
  if (t.contains('fireplace') || t.contains('fire place')) return Icons.fireplace_outlined;
  if (t.contains('removed cb') || t.contains('removed chimney')) return Icons.delete_outlined;

  // ── Floors ──
  if (t.contains('capture') && (t.contains('floor') || t.contains('plan'))) return Icons.draw_outlined;
  if (t.contains('loose floorboard')) return Icons.view_day_outlined;
  if (t.contains('sloping')) return Icons.trending_down_outlined;
  if (t.contains('floor vibration') || t.contains('vibration')) return Icons.vibration_outlined;
  if (t.contains('floor ventilation')) return Icons.air_outlined;
  if (t.contains('laminate') || t.contains('wood floor')) return Icons.view_day_outlined;
  if (t.contains('timber decay')) return Icons.forest_outlined;
  if (t.contains('timber infest')) return Icons.pest_control_outlined;
  if (t.contains('creaking')) return Icons.volume_off_outlined;
  if (t.contains('tiles')) return Icons.grid_on_outlined;
  if (t.contains('select floor')) return Icons.layers_outlined;
  if (t.contains('about floor')) return Icons.view_agenda_outlined;
  if (t.contains('floor') && t.contains('repair')) return Icons.build_outlined;
  if (t.contains('floors') || t == 'floor') return Icons.view_agenda_outlined;

  // ── Ceilings ──
  if (t.contains('asbestos') && id.contains('ceiling')) return Icons.warning_amber_outlined;
  if (t.contains('polystyrene')) return Icons.layers_outlined;
  if (t.contains('heavy paper')) return Icons.layers_outlined;
  if (t.contains('ornamental')) return Icons.auto_awesome_outlined;
  if (t.contains('ceiling') && t.contains('crack')) return Icons.broken_image_outlined;
  if (t.contains('ceiling') && t.contains('repair')) return Icons.build_outlined;
  if (t.contains('about ceiling')) return Icons.flip_outlined;
  if (t.contains('ceiling')) return Icons.flip_outlined;

  // ── Rooms & Areas ──
  if (t.contains('garage')) return Icons.garage_outlined;
  if (t.contains('front garden')) return Icons.yard_outlined;
  if (t.contains('rear garden')) return Icons.grass_outlined;
  if (t.contains('side garden')) return Icons.fence_outlined;
  if (t.contains('communal garden') || t.contains('common garden')) return Icons.nature_people_outlined;
  if (t.contains('garden') || t.contains('residential')) return Icons.yard_outlined;
  if (t.contains('parking') || t.contains('commercial')) return Icons.local_parking_outlined;
  if (t.contains('cellar')) return Icons.foundation_outlined;
  if (t.contains('basement')) return Icons.foundation_outlined;
  if (t.contains('bathroom') && t.contains('repair')) return Icons.build_outlined;
  if (t.contains('bathroom')) return Icons.bathtub_outlined;
  if (t.contains('conservatory') && t.contains('porch')) return Icons.deck_outlined;
  if (t.contains('conservatory')) return Icons.deck_outlined;
  if (t.contains('porch') && t.contains('canopy')) return Icons.door_sliding_outlined;
  if (t.contains('porch')) return Icons.door_sliding_outlined;
  if (t.contains('communal area')) return Icons.groups_outlined;
  if (t.contains('loft')) return Icons.warehouse_outlined;
  if (t.contains('balcony')) return Icons.balcony_outlined;
  if (t.contains('carport')) return Icons.directions_car_outlined;
  if (t.contains('external stair') || t.contains('stair')) return Icons.stairs_outlined;

  // ── Services ──
  if (t.contains('solar')) return Icons.solar_power_outlined;
  if (t.contains('electricity') || t.contains('electrical')) return Icons.electrical_services_outlined;
  if (t.contains('gas meter') && t.contains('repair')) return Icons.build_outlined;
  if (t.contains('mains gas') || t.contains('gas and oil') || t.contains('gas') && t.contains('oil')) return Icons.gas_meter_outlined;
  if (t.contains('gas') && !t.contains('glass') && !t.contains('fire')) return Icons.gas_meter_outlined;
  if (t.contains('oil') && !t.contains('soil') && !t.contains('boil')) return Icons.oil_barrel_outlined;
  if (t.contains('water heating') || t.contains('hot water') || t.contains('communal hot')) return Icons.water_drop_outlined;
  if (t.contains('water tank') || t.contains('disused') && t.contains('tank')) return Icons.storage_outlined;
  if (t.contains('main water') || (t == 'water' && !id.contains('heating'))) return Icons.water_outlined;
  if (t.contains('old boiler')) return Icons.thermostat_outlined;
  if (t.contains('about heating') || t.contains('heating system')) return Icons.thermostat_outlined;
  if (t.contains('radiator') || t.contains('underfloor')) return Icons.thermostat_outlined;
  if (t.contains('heating')) return Icons.thermostat_outlined;
  if (t.contains('drainage') || t.contains('drain')) return Icons.plumbing_outlined;
  if (t.contains('common service') || t.contains('shared service')) return Icons.hub_outlined;
  if (t.contains('insulation')) return Icons.shield_outlined;

  // ── Issues & Conditions ──
  if (t.contains('damp') || t.contains('dampness')) return Icons.water_damage_outlined;
  if (t.contains('condensation')) return Icons.thermostat_outlined;
  if (t.contains('movement crack') || t.contains('crack')) return Icons.broken_image_outlined;
  if (t.contains('timber') && (t.contains('rot') || t.contains('decay'))) return Icons.forest_outlined;
  if (t.contains('infestation') || t.contains('insect')) return Icons.pest_control_outlined;
  if (t.contains('asbestos')) return Icons.warning_amber_outlined;
  if (t.contains('flooding') || t.contains('flooded')) return Icons.water_damage_outlined;
  if (t.contains('knotweed')) return Icons.spa_outlined;
  if (t.contains('nearby tree')) return Icons.nature_outlined;
  if (t.contains('shrinkable clay')) return Icons.landscape_outlined;
  if (t.contains('safety hazard')) return Icons.health_and_safety_outlined;
  if (t.contains('legal')) return Icons.gavel_outlined;
  if (t.contains('mould') || t.contains('moulding')) return Icons.cleaning_services_outlined;
  if (t.contains('leak') || t.contains('seepage')) return Icons.water_damage_outlined;
  if (t.contains('sealant')) return Icons.format_paint_outlined;
  if (t.contains('wood rot')) return Icons.forest_outlined;
  if (t.contains('joists') && t.contains('decay')) return Icons.broken_image_outlined;
  if (t.contains('emf')) return Icons.cell_tower_outlined;

  // ── Repairs & Status ──
  if (t == 'repairs' || t.contains('repair')) return Icons.build_outlined;
  if (t.contains('not inspected') || t.contains('no access')) return Icons.visibility_off_outlined;
  if (t.contains('limitation')) return Icons.block_outlined;
  if (t.contains('not in use')) return Icons.do_not_disturb_outlined;
  if (t.contains('not habitable')) return Icons.dangerous_outlined;
  if (t.contains('condition')) return Icons.assessment_outlined;

  // ── Room detail floors ──
  if (t.contains('lower ground')) return Icons.arrow_downward_outlined;
  if (t == 'ground') return Icons.home_outlined;
  if (t == 'first') return Icons.looks_one_outlined;
  if (t == 'second') return Icons.looks_two_outlined;
  if (t == 'third') return Icons.looks_3_outlined;

  // ── Assessment ──
  if (t.contains('regulation')) return Icons.policy_outlined;
  if (t.contains('guarantee')) return Icons.verified_outlined;
  if (t.contains('other matters')) return Icons.more_horiz_outlined;
  if (t.contains('risk')) return Icons.warning_outlined;
  if (t.contains('improve')) return Icons.trending_up_outlined;

  // ── Misc ──
  if (t.contains('built in fitting') || t.contains('built in fittings')) return Icons.kitchen_outlined;
  if (t.contains('fitting') && t.contains('repair')) return Icons.build_outlined;
  if (t.contains('fitting')) return Icons.kitchen_outlined;
  if (t.contains('woodwork') || t.contains('wood work')) return Icons.handyman_outlined;
  if (t.contains('cupboard')) return Icons.storage_outlined;
  if (t.contains('extractor') || t.contains('extractor fan')) return Icons.air_outlined;
  if (t.contains('joinery') || t.contains('finishes')) return Icons.format_paint_outlined;
  if (t.contains('construction')) return Icons.construction_outlined;
  if (t.contains('rwg') || t.contains('rainwater') || t.contains('gutter')) return Icons.water_outlined;
  if (t.contains('blocked')) return Icons.block_outlined;
  if (t.contains('handrail') || t.contains('hand rail')) return Icons.fence_outlined;
  if (t.contains('steps') || t.contains('landing')) return Icons.stairs_outlined;
  if (t.contains('decoration') || t.contains('perished')) return Icons.format_paint_outlined;
  if (t.contains('overloaded')) return Icons.warning_outlined;
  if (t.contains('aerial') || t.contains('satellite') || t.contains('dish') || t.contains('ariel')) return Icons.satellite_alt_outlined;
  if (t.contains('shared') || t.contains('communal')) return Icons.groups_outlined;
  if (t.contains('fence')) return Icons.fence_outlined;
  if (t.contains('shed')) return Icons.house_siding_outlined;
  if (t.contains('outbuilding')) return Icons.cottage_outlined;
  if (t.contains('right of way')) return Icons.directions_outlined;
  if (t.contains('retaining')) return Icons.view_sidebar_outlined;
  if (t.contains('lift')) return Icons.elevator_outlined;
  if (t.contains('lock')) return Icons.lock_outlined;
  if (t.contains('balusters')) return Icons.view_week_outlined;
  if (t.contains('timber')) return Icons.forest_outlined;
  if (t.contains('open to building')) return Icons.open_in_new_outlined;
  if (t.contains('chamber')) return Icons.view_in_ar_outlined;
  if (t.contains('roots')) return Icons.nature_outlined;
  if (t.contains('soil') && t.contains('vent')) return Icons.air_outlined;
  if (t.contains('flashing')) return Icons.flash_on_outlined;
  if (t.contains('about')) return Icons.info_outlined;
  if (t.contains('summary')) return Icons.summarize_outlined;
  if (t.contains('location')) return Icons.pin_drop_outlined;
  if (t.contains('waterproofing')) return Icons.water_outlined;
  if (t.contains('capture')) return Icons.camera_alt_outlined;
  if (t.contains('water')) return Icons.water_outlined;
  if (t.contains('other area') || t.contains('external area')) return Icons.map_outlined;
  if (t.contains('area')) return Icons.map_outlined;
  if (t.contains('ground')) return Icons.terrain_outlined;
  if (t.contains('removed')) return Icons.delete_outlined;
  if (t.contains('poor')) return Icons.warning_outlined;
  if (t.contains('used as')) return Icons.home_outlined;
  if (t.contains('safety')) return Icons.shield_outlined;
  if (t.contains('other')) return Icons.more_horiz_outlined;
  if (t.contains('fire')) return Icons.fireplace_outlined;

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

class _GroupInlineHeader extends ConsumerWidget {
  const _GroupInlineHeader({
    required this.surveyId,
    required this.sectionKey,
    required this.parentNodeId,
  });

  final String surveyId;
  final String sectionKey;
  final String parentNodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(inspectionChildScreensProvider(parentNodeId));

    return childrenAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (children) {
        final headerScreens =
            children.where((child) => child.inlinePosition == 'header').toList();
        if (headerScreens.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            for (final screen in headerScreens) ...[
              _InlineHeaderForm(
                surveyId: surveyId,
                sectionKey: sectionKey,
                screen: screen,
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _InlineHeaderForm extends ConsumerWidget {
  const _InlineHeaderForm({
    required this.surveyId,
    required this.sectionKey,
    required this.screen,
  });

  final String surveyId;
  final String sectionKey;
  final InspectionNodeDefinition screen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (surveyId: surveyId, screenId: screen.id);
    final state = ref.watch(inspectionScreenProvider(params));
    final notifier = ref.read(inspectionScreenProvider(params).notifier);
    final phraseEngine = ref.watch(inspectionPhraseEngineProvider);

    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    final answers = state.answers;
    final visibleFields = filterLonelyLabels(
        screen.fields.where((field) => shouldShowInspectionField(field, answers)).toList());
    final enginePhrases = phraseEngine?.buildPhrases(screen.id, answers) ?? const <String>[];
    final fieldPhrases = FieldPhraseProcessor.buildFieldPhrases(screen.fields, answers);
    final phrases = [...enginePhrases, ...fieldPhrases];

    if (visibleFields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        for (final field in visibleFields) ...[
          InspectionFieldInput(
            field: field,
            value: answers[field.id] ?? '',
            onChanged: (next) async {
              notifier.setAnswer(field.id, next);
              await notifier.saveDraft();
            },
          ),
          const SizedBox(height: 12),
        ],
        if (phrases.isNotEmpty) ...[
          InspectionPhrasePreview(
            phraseText: phrases.join('\n\n'),
            isEdited: false,
            userNote: '',
            onUserNoteChanged: (_) {},
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
