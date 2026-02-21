/**
 * Extract V2 Inspection Tree Structural Spec
 *
 * Parses inspection_v2_tree.json into a normalized format
 * matching the same structure as native-spec.json.
 *
 * Output: scripts/structural-parity/v2-spec.json
 */
const fs = require('fs');
const path = require('path');

const TREE_PATH = path.resolve(__dirname, '../../assets/inspection_v2/inspection_v2_tree.json');
const OUTPUT_PATH = path.join(__dirname, 'v2-spec.json');

function main() {
  console.log('=== V2 Spec Extraction ===\n');

  const tree = JSON.parse(fs.readFileSync(TREE_PATH, 'utf-8'));
  const sections = tree.sections;

  console.log(`Found ${sections.length} sections`);

  const v2Spec = {};
  let totalScreens = 0;
  let totalFields = 0;
  let totalGroups = 0;

  const sectionSummary = [];

  for (const section of sections) {
    let sectionScreens = 0;
    let sectionGroups = 0;
    let sectionFields = 0;

    for (const node of section.nodes) {
      if (node.type === 'group') {
        totalGroups++;
        sectionGroups++;
        continue;
      }

      if (node.type === 'screen') {
        totalScreens++;
        sectionScreens++;

        const fields = (node.fields || []).map((field, index) => {
          const normalized = {
            position: index,
            id: field.id,
            label: field.label || '',
            type: field.type
          };

          if (field.options && field.options.length > 0) {
            normalized.options = field.options;
          }

          if (field.conditionalOn) {
            normalized.conditionalOn = field.conditionalOn;
            normalized.conditionalValue = field.conditionalValue || null;
            normalized.conditionalMode = field.conditionalMode || null;
          }

          return normalized;
        });

        sectionFields += fields.length;
        totalFields += fields.length;

        v2Spec[node.id] = {
          screenId: node.id,
          title: node.title,
          sectionKey: section.key,
          sectionTitle: section.title,
          parentId: node.parentId || null,
          order: node.order || 0,
          fields: fields,
          fieldCount: fields.length
        };
      }
    }

    sectionSummary.push({
      key: section.key,
      title: section.title,
      screens: sectionScreens,
      groups: sectionGroups,
      fields: sectionFields
    });
  }

  console.log(`\nSection Summary:`);
  for (const s of sectionSummary) {
    console.log(`  ${s.key} (${s.title}): ${s.screens} screens, ${s.groups} groups, ${s.fields} fields`);
  }

  console.log(`\nTotal: ${totalScreens} screens, ${totalGroups} groups, ${totalFields} fields`);

  // Detect duplicate screens (screens with __suffix patterns or same base ID)
  const duplicates = {};
  const screenIds = Object.keys(v2Spec);
  for (const id of screenIds) {
    // Check for patterns like: activity_something_123 (numeric suffix)
    // or activity_something__2 (double underscore suffix)
    const baseMatch = id.match(/^(.+?)(?:__\d+|_\d{2,}$)/);
    if (baseMatch) {
      const baseId = baseMatch[1];
      if (!duplicates[baseId]) {
        duplicates[baseId] = [];
      }
      duplicates[baseId].push(id);
    }
  }

  // Only keep entries that actually have a base screen
  const realDuplicates = {};
  for (const [baseId, copies] of Object.entries(duplicates)) {
    if (v2Spec[baseId]) {
      realDuplicates[baseId] = copies;
    }
  }

  if (Object.keys(realDuplicates).length > 0) {
    console.log(`\nDuplicate screen patterns found: ${Object.keys(realDuplicates).length}`);
    for (const [baseId, copies] of Object.entries(realDuplicates)) {
      console.log(`  ${baseId} -> ${copies.join(', ')}`);
    }
  }

  // Field type distribution
  const typeDistribution = {};
  for (const screen of Object.values(v2Spec)) {
    for (const field of screen.fields) {
      typeDistribution[field.type] = (typeDistribution[field.type] || 0) + 1;
    }
  }
  console.log(`\nField type distribution:`);
  for (const [type, count] of Object.entries(typeDistribution).sort((a, b) => b[1] - a[1])) {
    console.log(`  ${type}: ${count}`);
  }

  // Screens with conditionals
  const conditionalScreens = Object.values(v2Spec)
    .filter(s => s.fields.some(f => f.conditionalOn))
    .length;
  console.log(`\nScreens with conditional fields: ${conditionalScreens}`);

  // Screens with dropdown options
  const dropdownScreens = Object.values(v2Spec)
    .filter(s => s.fields.some(f => f.options && f.options.length > 0))
    .length;
  console.log(`Screens with dropdown options: ${dropdownScreens}`);

  // Screens with label fields
  const labelScreens = Object.values(v2Spec)
    .filter(s => s.fields.some(f => f.type === 'label'))
    .length;
  console.log(`Screens with label (section heading) fields: ${labelScreens}`);

  const output = {
    meta: {
      extractedAt: new Date().toISOString(),
      totalScreens,
      totalGroups,
      totalFields,
      sectionSummary,
      fieldTypeDistribution: typeDistribution
    },
    screens: v2Spec,
    duplicates: realDuplicates
  };

  fs.writeFileSync(OUTPUT_PATH, JSON.stringify(output, null, 2));
  console.log(`\nOutput: ${OUTPUT_PATH}`);
}

main();
