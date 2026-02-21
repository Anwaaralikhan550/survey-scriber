/**
 * Fix script: Reparent duplicate screen siblings as inline headers
 *
 * For each duplicate pair (screen + group with same title under same parent):
 * - Change screen's parentId to point to the sub-group
 * - Set inlinePosition: "header" on the screen
 * - This removes the duplicate tile at the parent level and renders the
 *   screen's fields inline at the top of the sub-group's page
 */
const fs = require('fs');
const path = require('path');

const treePath = path.join(__dirname, '..', 'assets', 'inspection_v2', 'inspection_v2_tree.json');
const tree = JSON.parse(fs.readFileSync(treePath, 'utf8'));

// Load audit results
const auditPath = path.join(__dirname, 'audit_duplicates_results.json');
const duplicates = JSON.parse(fs.readFileSync(auditPath, 'utf8'));

let patchCount = 0;

for (const dup of duplicates) {
  if (dup.hasInlinePosition) {
    console.log(`SKIP (already inline): ${dup.screenId}`);
    continue;
  }

  // Find the section
  const section = tree.sections.find(s => s.key === dup.section);
  if (!section) {
    console.log(`ERROR: Section ${dup.section} not found`);
    continue;
  }

  // Find the screen node
  const screen = section.nodes.find(n => n.id === dup.screenId);
  if (!screen) {
    console.log(`ERROR: Screen ${dup.screenId} not found`);
    continue;
  }

  // Verify the group exists
  const group = section.nodes.find(n => n.id === dup.groupId);
  if (!group) {
    console.log(`ERROR: Group ${dup.groupId} not found`);
    continue;
  }

  const oldParent = screen.parentId;
  screen.parentId = dup.groupId;
  screen.inlinePosition = 'header';

  // Set order to -1 so it sorts before all other children in the group
  screen.order = -1;

  patchCount++;
  console.log(`FIXED: ${dup.screenId}`);
  console.log(`  parentId: ${oldParent} -> ${dup.groupId}`);
  console.log(`  inlinePosition: "header"`);
  console.log('');
}

console.log(`\nTotal patches applied: ${patchCount}`);

// Save the updated tree
fs.writeFileSync(treePath, JSON.stringify(tree, null, 2));
console.log(`Tree saved to ${treePath}`);
