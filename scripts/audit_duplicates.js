/**
 * Audit script: Find duplicate navigation entries
 *
 * Finds cases where a group and screen share the same title under the same parentId.
 * These create confusing duplicate tiles in the navigation.
 */
const fs = require('fs');
const path = require('path');

const treePath = path.join(__dirname, '..', 'assets', 'inspection_v2', 'inspection_v2_tree.json');
const tree = JSON.parse(fs.readFileSync(treePath, 'utf8'));

const duplicates = [];

for (const section of tree.sections) {
  // Group nodes by parentId
  const byParent = {};
  for (const node of section.nodes) {
    const pid = node.parentId || '__root__';
    if (!byParent[pid]) byParent[pid] = [];
    byParent[pid].push(node);
  }

  // For each parent, find groups and screens with the same title
  for (const [parentId, siblings] of Object.entries(byParent)) {
    const groups = siblings.filter(n => n.type === 'group');
    const screens = siblings.filter(n => n.type === 'screen');

    for (const group of groups) {
      for (const screen of screens) {
        if (group.title === screen.title) {
          duplicates.push({
            section: section.key,
            parentId: parentId === '__root__' ? null : parentId,
            screenId: screen.id,
            screenTitle: screen.title,
            screenOrder: screen.order,
            screenFieldCount: (screen.fields || []).length,
            groupId: group.id,
            groupTitle: group.title,
            groupOrder: group.order,
            hasInlinePosition: !!screen.inlinePosition,
          });
        }
      }
    }
  }
}

console.log(`\nFound ${duplicates.length} duplicate pairs (same-title group+screen siblings):\n`);

for (const dup of duplicates) {
  console.log(`[${dup.section}] Parent: ${dup.parentId}`);
  console.log(`  Screen: ${dup.screenId} (order: ${dup.screenOrder}, fields: ${dup.screenFieldCount})`);
  console.log(`  Group:  ${dup.groupId} (order: ${dup.groupOrder})`);
  console.log(`  Title:  "${dup.screenTitle}"`);
  console.log(`  Already inline: ${dup.hasInlinePosition}`);
  console.log('');
}

// Output as JSON for the fix script
const outputPath = path.join(__dirname, 'audit_duplicates_results.json');
fs.writeFileSync(outputPath, JSON.stringify(duplicates, null, 2));
console.log(`Results saved to ${outputPath}`);
