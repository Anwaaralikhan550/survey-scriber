import '../../../core/database/app_database.dart';
import 'models/inspection_models.dart';

/// The tiles an inspection section page shows for [parentNodeId]
/// (null = the section's top level), in display order.
///
/// Moved verbatim from InspectionSectionPage so the whole tree can be walked
/// in tests exactly the way a surveyor sees it. Inline header screens are not
/// tiles (they render at the top of their group page), and the "legacy parity"
/// rules below hide or re-pick tiles on specific pages.
///
/// 1 Nov 2026 sweep: removed the rules for Water, Heating, Woodwork, Other
/// Outside Property > Repairs > External structures / Porch Canopy and Other
/// External Area > Other. They named screens that no longer exist and hid
/// real screens (Water Tank, About Heating System, Creaking Stairs, Hand rails,
/// Retaining walls...) whose PDF paragraphs could therefore never be written.
List<InspectionV2Screen> visibleSectionNodes({
  required String sectionKey,
  required String? parentNodeId,
  required List<InspectionV2Screen> nodes,
  required Map<String, InspectionNodeDefinition> nodeMap,
}) {
  final visibleNodes = nodes.where((node) {
    if (node.parentId != parentNodeId) return false;
    if (node.nodeType != 'screen') return true;
    final definition = nodeMap[node.screenId];
    return definition?.inlinePosition != 'header';
  }).toList();

  // Legacy parity: remove rogue outside-property group from
  // Inside Property top-level menu.
  if (sectionKey == 'F' && parentNodeId == null) {
    visibleNodes.removeWhere((node) =>
        node.screenId ==
        'group_outside_property_other_joinery_and_finishes_main_screen_80');
  }

  // Legacy parity: E9 "Other area" menu should only expose
  // Repairs + Not inspected, with Note/Condition Rating via
  // the inline header screen.
  if (parentNodeId == 'group_e9_other_area_32') {
    visibleNodes.retainWhere((node) =>
        node.screenId == 'group_other_area_33' ||
        node.screenId == 'group_repairs_42' ||
        node.screenId ==
            'activity_outside_property_other_not_inspected');
  }
  if (parentNodeId == 'group_other_area_33') {
    visibleNodes.retainWhere((node) =>
        node.screenId ==
            'activity_outside_property_other_communal_area' ||
        node.screenId == 'group_other_external_area_34');
  }
  if (parentNodeId == 'group_carport_35') {
    // Legacy parity: Carport should show only these screens.
    const allowed = <String>{
      'activity_outside_property_other_other_external', // Construction
      'activity_outside_property_other_other_roof', // Roof
      'activity_outside_property_other_floors', // Floor
      'activity_outside_property_other_drains', // Drains
      'activity_out_side_other_external_area_condition', // Condition
    };
    visibleNodes
        .retainWhere((node) => allowed.contains(node.screenId));
  }
  if (parentNodeId == 'group_porch_canopy_36') {
    // Legacy parity: Porch Canopy should show only these screens.
    const allowed = <String>{
      'activity_outside_property_other_other_external__construction', // Construction
      'activity_outside_property_other_other_roof__roof', // Roof
      'activity_out_side_other_external_area_condition__condition', // Condition
    };
    visibleNodes
        .retainWhere((node) => allowed.contains(node.screenId));
  }
  if (parentNodeId == 'group_roof_terrace_37') {
    // Legacy parity: Roof Terrace excludes Wall Construction.
    const allowed = <String>{
      'activity_outside_property_other_other_external__construction__2', // Construction
      'activity_outside_property_other_other_roof__roof__2', // Roof
      'activity_outside_property_other_floors__floor__2', // Floor
      'activity_outside_property_other_handrails__handrails__2', // Handrails
      'activity_outside_property_other_drains__drains__2', // Drains
      'activity_outside_property_other_overloaded__overloaded__2', // Overloaded
      'activity_outside_property_other_no_safety_glass__no_safety_glass__2', // No safety glass
      'activity_out_side_other_external_area_condition__condition__2', // Condition
    };
    visibleNodes
        .retainWhere((node) => allowed.contains(node.screenId));
  }
  if (parentNodeId == 'group_balcony_38') {
    // Legacy parity: Balcony excludes Roof and Wall Construction.
    const allowed = <String>{
      'activity_outside_property_other_other_external__construction__3', // Construction
      'activity_outside_property_other_floors__floor__3', // Floor
      'activity_outside_property_other_handrails__handrails__3', // Handrails
      'activity_outside_property_other_drains__drains__3', // Drains
      'activity_outside_property_other_overloaded__overloaded__3', // Overloaded
      'activity_outside_property_other_no_safety_glass__no_safety_glass__3', // No safety glass
      'activity_out_side_other_external_area_condition__condition__3', // Condition
    };
    visibleNodes
        .retainWhere((node) => allowed.contains(node.screenId));
  }
  if (parentNodeId == 'group_juliet_balcony_39') {
    // Legacy parity: Juliet Balcony excludes Roof and Wall Construction.
    const allowed = <String>{
      'activity_outside_property_other_other_external__construction__4', // Construction
      'activity_outside_property_other_floors__floor__4', // Floor
      'activity_outside_property_other_handrails__handrails__4', // Handrails
      'activity_outside_property_other_drains__drains__4', // Drains
      'activity_outside_property_other_overloaded__overloaded__4', // Overloaded
      'activity_outside_property_other_no_safety_glass__no_safety_glass__4', // No safety glass
      'activity_out_side_other_external_area_condition__condition__4', // Condition
    };
    visibleNodes
        .retainWhere((node) => allowed.contains(node.screenId));
  }
  if (parentNodeId == 'group_external_stairs_40') {
    // Legacy parity: External Stairs excludes Drains and Wall Construction.
    const allowed = <String>{
      'activity_outside_property_other_other_external__construction__5', // Construction
      'activity_outside_property_other_other_roof__roof__5', // Roof
      'activity_outside_property_other_floors__floor__5', // Floor
      'activity_outside_property_other_handrails__handrails__5', // Handrails
      'activity_outside_property_other_overloaded__overloaded__5', // Overloaded
      'activity_outside_property_other_no_safety_glass__no_safety_glass__5', // No safety glass
      'activity_out_side_other_external_area_condition__condition__5', // Condition
    };
    visibleNodes
        .retainWhere((node) => allowed.contains(node.screenId));
  }
  return visibleNodes;
}
