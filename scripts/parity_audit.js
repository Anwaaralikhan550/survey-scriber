const fs = require('fs');
const path = require('path');
// No XML parser needed - we just check screen existence

// Load V2 tree
const tree = JSON.parse(fs.readFileSync('E:/s/scriber/mobile-app/assets/inspection_v2/inspection_v2_tree.json', 'utf8'));

// Build a map of V2 screen ID -> screen data
const v2Map = {};
const sectionKeys = ['E', 'F', 'G', 'H'];
for (const sec of tree.sections) {
  if (!sectionKeys.includes(sec.key)) continue;
  for (const node of sec.nodes) {
    if (node.type === 'screen') {
      v2Map[node.id] = { section: sec.key, title: node.title, fields: node.fields || [], parentId: node.parentId };
    }
  }
}

// List old native layout files for property inspection
const layoutDir = 'E:/s/scriber/mobile-app-old-native/app/src/main/res/layout';
const allLayouts = fs.readdirSync(layoutDir).filter(f => f.endsWith('.xml'));

// Filter to only property inspection layouts
const inspPrefixes = [
  'activity_outside_property', 'outside_property_',
  'activity_inside_property', 'activity_in_side_property', 'inside_property_',
  'activity_services_', 'activity_service_', 'services_',
  'activity_grounds_', 'activity_ground_', 'activity_garage',
  'activity_front_garden', 'activity_rear_garden', 'activity_communal_garden',
  'activity_garden', 'activity_rwg_', 'activity_other_repair',
  'activity_out_side_', 'activity_pid_garage', 'activity_pid_rainwater'
];

const inspLayouts = allLayouts.filter(f =>
  inspPrefixes.some(prefix => f.startsWith(prefix))
);

// Check which old native layouts have matching V2 screens
let matched = 0, missing = 0;
const missingInV2 = [];
const matchedScreens = [];

for (const layout of inspLayouts) {
  const screenId = layout.replace('.xml', '');
  if (v2Map[screenId]) {
    matched++;
    matchedScreens.push(screenId);
  } else {
    missing++;
    missingInV2.push(screenId);
  }
}

// Check V2 screens that don't have old native layouts
const v2Only = [];
for (const [id, data] of Object.entries(v2Map)) {
  const layoutFile = id + '.xml';
  if (!inspLayouts.includes(layoutFile)) {
    v2Only.push({ id, title: data.title, section: data.section });
  }
}

console.log('=== SCREEN MAPPING SUMMARY ===');
console.log('Old native inspection layouts:', inspLayouts.length);
console.log('V2 inspection screens:', Object.keys(v2Map).length);
console.log('Matched (old->V2):', matched);
console.log('Missing in V2 (old native has, V2 does not):', missing);
console.log('V2 only (V2 has, no old native layout):', v2Only.length);
console.log();
console.log('=== MISSING IN V2 (old native screens NOT in V2 tree) ===');
missingInV2.forEach(s => console.log('  MISSING:', s));
console.log();
console.log('=== V2-ONLY SCREENS (exist in V2 but no matching old layout) ===');
v2Only.forEach(s => console.log('  V2-ONLY [' + s.section + ']:', s.id, '-', s.title));
