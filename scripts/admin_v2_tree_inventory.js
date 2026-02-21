#!/usr/bin/env node
/**
 * admin_v2_tree_inventory.js
 *
 * Reads both V2 tree JSON files (inspection_v2 and valuation_v2),
 * extracts a comprehensive inventory of sections, groups, screens,
 * fields, dropdowns, conditional rules, and unique IDs.
 *
 * Outputs a structured JSON report to admin_v2_mapping_report.json.
 */

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const INSPECTION_TREE = path.join(ROOT, 'assets', 'inspection_v2', 'inspection_v2_tree.json');
const VALUATION_TREE = path.join(ROOT, 'assets', 'valuation_v2', 'valuation_v2_tree.json');
const OUTPUT_FILE = path.join(ROOT, 'admin_v2_mapping_report.json');

// ───────────────────────────────────────────────────────────
// Analyse a single tree and return a structured inventory
// ───────────────────────────────────────────────────────────
function analyseTree(tree) {
  const sections = [];
  let totalGroups = 0;
  let totalScreens = 0;
  let totalFields = 0;
  const fieldsByType = {};
  const dropdownInventory = [];
  const conditionalRules = [];
  const allScreenIds = new Set();
  const allFieldIds = new Set();
  const screens = [];

  // Track unique dropdown option sets (serialised for dedup)
  const uniqueDropdownSets = new Map(); // JSON(options) -> options

  for (const section of tree.sections) {
    let sectionNodeCount = 0;
    let sectionGroupCount = 0;
    let sectionScreenCount = 0;

    for (const node of section.nodes) {
      sectionNodeCount++;

      if (node.type === 'group') {
        totalGroups++;
        sectionGroupCount++;
        continue;
      }

      if (node.type === 'screen') {
        totalScreens++;
        sectionScreenCount++;
        allScreenIds.add(node.id);

        const fieldCount = node.fields ? node.fields.length : 0;
        totalFields += fieldCount;

        screens.push({
          id: node.id,
          title: node.title,
          parentId: node.parentId || null,
          sectionKey: section.key,
          fieldCount,
        });

        if (node.fields) {
          for (const field of node.fields) {
            allFieldIds.add(field.id);

            // Count by type
            const ft = field.type || 'unknown';
            fieldsByType[ft] = (fieldsByType[ft] || 0) + 1;

            // Dropdown inventory
            if (field.type === 'dropdown' && field.options) {
              dropdownInventory.push({
                fieldId: field.id,
                screenId: node.id,
                options: field.options,
              });

              const key = JSON.stringify(field.options);
              if (!uniqueDropdownSets.has(key)) {
                uniqueDropdownSets.set(key, field.options);
              }
            }

            // Conditional rules
            // Inspection tree uses separate props: conditionalOn, conditionalValue, conditionalMode
            // Valuation tree may use combined string: conditionalOn = "fieldId=Value"
            if (field.conditionalOn) {
              const rule = {
                fieldId: field.id,
                screenId: node.id,
                conditionalOn: field.conditionalOn,
              };
              if (field.conditionalValue !== undefined) {
                rule.conditionalValue = field.conditionalValue;
              }
              if (field.conditionalMode !== undefined) {
                rule.conditionalMode = field.conditionalMode;
              }
              conditionalRules.push(rule);
            }
          }
        }
      }
    }

    sections.push({
      key: section.key,
      title: section.title,
      nodeCount: sectionNodeCount,
      groupCount: sectionGroupCount,
      screenCount: sectionScreenCount,
    });
  }

  // Count fields with inlinePosition
  let inlinePositionCount = 0;
  const inlinePositionFields = [];
  for (const section of tree.sections) {
    for (const node of section.nodes) {
      if (node.fields) {
        for (const field of node.fields) {
          if (field.inlinePosition !== undefined) {
            inlinePositionCount++;
            inlinePositionFields.push({
              fieldId: field.id,
              screenId: node.id,
              inlinePosition: field.inlinePosition,
            });
          }
        }
      }
    }
  }

  // Derive unique condition patterns
  const uniqueConditionPatterns = [];
  const patternSet = new Set();
  for (const rule of conditionalRules) {
    let pattern;
    if (rule.conditionalValue !== undefined) {
      pattern = `${rule.conditionalOn}|${rule.conditionalValue}|${rule.conditionalMode || 'default'}`;
    } else {
      // Combined string format (valuation style)
      pattern = rule.conditionalOn;
    }
    if (!patternSet.has(pattern)) {
      patternSet.add(pattern);
      uniqueConditionPatterns.push(pattern);
    }
  }

  return {
    sections,
    totalGroups,
    totalScreens,
    totalFields,
    fieldsByType,
    dropdownInventory,
    uniqueDropdownOptionSets: uniqueDropdownSets.size,
    conditionalRules,
    conditionalRulesCount: conditionalRules.length,
    uniqueConditionPatterns,
    inlinePositionCount,
    inlinePositionFields,
    screens,
    allScreenIds: Array.from(allScreenIds).sort(),
    allFieldIds: Array.from(allFieldIds).sort(),
  };
}

// ───────────────────────────────────────────────────────────
// Main
// ───────────────────────────────────────────────────────────
function main() {
  console.log('Reading inspection V2 tree...');
  const inspectionTree = JSON.parse(fs.readFileSync(INSPECTION_TREE, 'utf8'));

  console.log('Reading valuation V2 tree...');
  const valuationTree = JSON.parse(fs.readFileSync(VALUATION_TREE, 'utf8'));

  console.log('Analysing inspection V2...');
  const inspectionResult = analyseTree(inspectionTree);

  console.log('Analysing valuation V2...');
  const valuationResult = analyseTree(valuationTree);

  const report = {
    generatedAt: new Date().toISOString(),
    inspection_v2: inspectionResult,
    valuation_v2: valuationResult,
  };

  fs.writeFileSync(OUTPUT_FILE, JSON.stringify(report, null, 2), 'utf8');
  console.log(`\nReport written to: ${OUTPUT_FILE}`);

  // ─── Print summary ───
  function printSummary(label, data) {
    console.log(`\n${'='.repeat(60)}`);
    console.log(`  ${label}`);
    console.log('='.repeat(60));
    console.log(`  Sections:              ${data.sections.length}`);
    data.sections.forEach(s => {
      console.log(`    [${s.key}] ${s.title}  -- ${s.nodeCount} nodes (${s.groupCount} groups, ${s.screenCount} screens)`);
    });
    console.log(`  Total groups:          ${data.totalGroups}`);
    console.log(`  Total screens:         ${data.totalScreens}`);
    console.log(`  Total fields:          ${data.totalFields}`);
    console.log(`  Fields by type:`);
    for (const [type, count] of Object.entries(data.fieldsByType).sort((a, b) => b[1] - a[1])) {
      console.log(`    ${type.padEnd(15)} ${count}`);
    }
    console.log(`  Dropdowns:             ${data.dropdownInventory.length}`);
    console.log(`  Unique option sets:    ${data.uniqueDropdownOptionSets}`);
    console.log(`  Conditional rules:     ${data.conditionalRulesCount}`);
    console.log(`  Unique patterns:       ${data.uniqueConditionPatterns.length}`);
    console.log(`  InlinePosition fields: ${data.inlinePositionCount}`);
    console.log(`  Unique screen IDs:     ${data.allScreenIds.length}`);
    console.log(`  Unique field IDs:      ${data.allFieldIds.length}`);
  }

  printSummary('INSPECTION V2', inspectionResult);
  printSummary('VALUATION V2', valuationResult);

  console.log(`\nDone.`);
}

main();
