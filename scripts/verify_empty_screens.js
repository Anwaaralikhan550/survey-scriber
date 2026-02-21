const fs = require('fs');
const j = JSON.parse(fs.readFileSync('assets/inspection_v2/inspection_v2_tree.json', 'utf8'));
let empty = [];
j.sections.forEach(s => s.nodes.forEach(n => {
  if (n.type === 'screen' && (!n.fields || n.fields.length === 0)) {
    empty.push({ id: n.id, title: n.title, parent: n.parentId });
  }
}));
console.log('Total screens:', j.sections.reduce((sum, s) => sum + s.nodes.filter(n => n.type === 'screen').length, 0));
console.log('Empty screens:', empty.length);
empty.forEach(e => console.log('  -', e.id, '(' + e.title + ') parent:', e.parent));

// Also check the 6 screens we just fixed
const fixed = [
  'activity_internal_wall', 'activity_listed_building',
  'activity_listed_building__listed_building', 'activity_topography',
  'activity_garden', 'activity_other_service',
  'activity_outside_property_other_about_joinery_and_finishes__other_joinery_and_finishes',
  'activity_outside_property_other_joinery_and_finishes_repairs__repairs',
  'activity_outside_property_other_joinery_finishes_not_inspected__not_inspected',
  'activity_over_all_openion'
];
console.log('\nVerification of fixed screens:');
fixed.forEach(id => {
  let found = false;
  j.sections.forEach(s => s.nodes.forEach(n => {
    if (n.id === id) {
      found = true;
      console.log('  ' + (n.fields && n.fields.length > 0 ? 'OK' : 'FAIL') +
        ' ' + id + ': ' + (n.fields ? n.fields.length : 0) + ' fields');
    }
  }));
  if (!found) console.log('  MISSING ' + id);
});
