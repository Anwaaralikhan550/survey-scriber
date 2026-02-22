#!/usr/bin/env node
/**
 * Client feedback fixes — JSON tree modifications
 * Run: node scripts/client-feedback-fixes.js
 */
const fs = require('fs');
const path = require('path');

const TREE_PATH = path.join(__dirname, '..', 'assets', 'property_inspection', 'inspection_tree.json');

const tree = JSON.parse(fs.readFileSync(TREE_PATH, 'utf-8'));

let changeCount = 0;

function findNode(nodes, id) {
  for (const node of nodes) {
    if (node.id === id) return node;
  }
  return null;
}

function findScreen(sectionNodes, screenId) {
  for (const node of sectionNodes) {
    if (node.id === screenId) return node;
  }
  return null;
}

function findFieldInScreen(screen, fieldId) {
  if (!screen || !screen.fields) return null;
  return screen.fields.find(f => f.id === fieldId);
}

function removeFieldFromScreen(screen, fieldId) {
  if (!screen || !screen.fields) return false;
  const idx = screen.fields.findIndex(f => f.id === fieldId);
  if (idx >= 0) {
    screen.fields.splice(idx, 1);
    return true;
  }
  return false;
}

function addFieldAfter(screen, afterFieldId, newField) {
  if (!screen || !screen.fields) return false;
  const idx = screen.fields.findIndex(f => f.id === afterFieldId);
  if (idx >= 0) {
    screen.fields.splice(idx + 1, 0, newField);
    return true;
  }
  return false;
}

function getAllScreens() {
  const screens = [];
  for (const section of tree.sections) {
    for (const node of section.nodes) {
      if (node.type === 'screen' && node.fields) {
        screens.push(node);
      }
    }
  }
  return screens;
}

// ========================================================
// 1. LIMITATIONS: "Inspection Area:" → "Limitations:"
// ========================================================
for (const section of tree.sections) {
  for (const node of section.nodes) {
    if (node.fields) {
      const field = findFieldInScreen(node, 'label_inspection_area');
      if (field) {
        field.label = 'Limitations:';
        console.log(`[1] Changed "Inspection Area:" to "Limitations:" in ${node.id}`);
        changeCount++;
      }
    }
  }
}

// ========================================================
// 2. GATED COMMUNITY: Remove garden labels
// ========================================================
for (const section of tree.sections) {
  const screen = findScreen(section.nodes, 'activity_gated_community');
  if (screen) {
    for (const labelId of ['label_front_garden_5', 'label_rear_garden_5', 'label_communal_garden_5']) {
      if (removeFieldFromScreen(screen, labelId)) {
        console.log(`[2] Removed garden label ${labelId} from Gated Community`);
        changeCount++;
      }
    }
    break;
  }
}

// ========================================================
// 3. SPELLING: "South east" → "Southeast"
// ========================================================
for (const screen of getAllScreens()) {
  for (const field of screen.fields) {
    if (field.options && Array.isArray(field.options)) {
      const idx = field.options.indexOf('South east');
      if (idx >= 0) {
        field.options[idx] = 'Southeast';
        console.log(`[3] Changed "South east" to "Southeast" in ${screen.id}.${field.id}`);
        changeCount++;
      }
    }
  }
}

// ========================================================
// 4. SPELLING: "Suspended bean and block" → "Suspended Beam and Block"
// ========================================================
for (const screen of getAllScreens()) {
  for (const field of screen.fields) {
    if (field.label === 'Suspended bean and block') {
      field.label = 'Suspended Beam and Block';
      console.log(`[4] Fixed "Suspended bean" → "Suspended Beam" in ${screen.id}.${field.id}`);
      changeCount++;
    }
  }
}

// ========================================================
// 5. SPELLING: "Sloppy" → "Sloping" in dropdown options
// ========================================================
for (const screen of getAllScreens()) {
  for (const field of screen.fields) {
    if (field.options && Array.isArray(field.options)) {
      const idx = field.options.indexOf('Sloppy');
      if (idx >= 0) {
        field.options[idx] = 'Sloping';
        console.log(`[5] Changed "Sloppy" to "Sloping" in ${screen.id}.${field.id}`);
        changeCount++;
      }
    }
  }
}

// ========================================================
// 6. FLOOR: "Build Type" → "Composition"
// ========================================================
for (const section of tree.sections) {
  for (const node of section.nodes) {
    if (node.fields) {
      for (const field of node.fields) {
        // Floor screen's Build Type dropdown
        if (field.id === 'android_material_design_spinner' && field.label === 'Build Type') {
          field.label = 'Composition';
          console.log(`[6] Floor: "Build Type" → "Composition" in ${node.id}`);
          changeCount++;
        }
      }
    }
  }
}

// ========================================================
// 7. FLOOR: "Built With" label → "Construction" (floor-specific)
// ========================================================
for (const section of tree.sections) {
  for (const node of section.nodes) {
    if (node.fields) {
      const field = findFieldInScreen(node, 'label_built_with');
      if (field && field.label === 'Built With') {
        field.label = 'Construction';
        console.log(`[7] Floor: "Built With" label → "Construction" in ${node.id}`);
        changeCount++;
      }
    }
  }
}

// ========================================================
// 8. WINDOWS: "Glazzed With" → "Composition"
// ========================================================
for (const screen of getAllScreens()) {
  for (const field of screen.fields) {
    if (field.label === 'Glazzed With') {
      field.label = 'Composition';
      console.log(`[8] Windows: "Glazzed With" → "Composition" in ${screen.id}.${field.id}`);
      changeCount++;
    }
  }
}

// ========================================================
// 9. WINDOWS: "Glazzed Type" → "Glazing"
// ========================================================
for (const screen of getAllScreens()) {
  for (const field of screen.fields) {
    if (field.label === 'Glazzed Type') {
      field.label = 'Glazing';
      console.log(`[9] Windows: "Glazzed Type" → "Glazing" in ${screen.id}.${field.id}`);
      changeCount++;
    }
  }
}

// ========================================================
// 10. WINDOWS: "Window Material" → "Frames"
// ========================================================
for (const screen of getAllScreens()) {
  for (const field of screen.fields) {
    if (field.label === 'Window Material') {
      field.label = 'Frames';
      console.log(`[10] Windows: "Window Material" → "Frames" in ${screen.id}.${field.id}`);
      changeCount++;
    }
  }
}

// ========================================================
// 11. YEAR EXTENDED: Delete Ex.Location dropdown
// ========================================================
for (const section of tree.sections) {
  for (const node of section.nodes) {
    if (node.id === 'activity_year_extended' || (node.title && node.title.includes('Year Extended'))) {
      if (node.fields) {
        // Remove the Ex.Location dropdown
        if (removeFieldFromScreen(node, 'android_material_design_spinner3')) {
          console.log(`[11] Removed Ex.Location dropdown from ${node.id}`);
          changeCount++;
        }
        // Rename Ex.Location label to "Location"
        const label = findFieldInScreen(node, 'label_exlocation');
        if (label) {
          label.label = 'Location';
          console.log(`[11] Renamed "Ex.Location" label to "Location" in ${node.id}`);
          changeCount++;
        }
      }
    }
  }
}

// Also try to find by scanning for the Ex.Location field in any screen
if (changeCount < 12) {
  for (const screen of getAllScreens()) {
    const field = screen.fields.find(f => f.id === 'android_material_design_spinner3' && f.label === 'Ex.Location');
    if (field) {
      removeFieldFromScreen(screen, 'android_material_design_spinner3');
      console.log(`[11-fallback] Removed Ex.Location dropdown from ${screen.id}`);
      changeCount++;
      const label = findFieldInScreen(screen, 'label_exlocation');
      if (label) {
        label.label = 'Location';
        console.log(`[11-fallback] Renamed "Ex.Location" label to "Location" in ${screen.id}`);
        changeCount++;
      }
    }
  }
}

// ========================================================
// 12. PROPERTY BUILT: Remove "Modern construction techniques" label
// ========================================================
for (const screen of getAllScreens()) {
  if (removeFieldFromScreen(screen, 'label_modern_construction_techniques')) {
    console.log(`[12] Removed "Modern construction techniques" label from ${screen.id}`);
    changeCount++;
  }
}

// ========================================================
// 13. ROOF: Remove 'Built With' dropdown + label + checkboxes
// ========================================================
for (const section of tree.sections) {
  const roofScreen = findScreen(section.nodes, 'activity_property_roof');
  if (roofScreen) {
    // Remove Built With dropdown (android_material_design_spinner6)
    if (removeFieldFromScreen(roofScreen, 'android_material_design_spinner6')) {
      console.log(`[13] Removed "Built With" dropdown from Roof`);
      changeCount++;
    }
    // Remove Built With label (label_built_with_2)
    if (removeFieldFromScreen(roofScreen, 'label_built_with_2')) {
      console.log(`[13] Removed "Built With" label from Roof`);
      changeCount++;
    }
    // Remove Built With checkboxes (ch3, ch4, ch5) and text (etBuiltWithOther)
    for (const id of ['ch3', 'ch4', 'ch5', 'etBuiltWithOther']) {
      if (removeFieldFromScreen(roofScreen, id)) {
        console.log(`[13] Removed ${id} from Roof`);
        changeCount++;
      }
    }
    // Remove last 3 fields: etBuiltWithOther1, android_material_design_spinner4, etCoverWithOther
    for (const id of ['etBuiltWithOther1', 'android_material_design_spinner4', 'etCoverWithOther']) {
      if (removeFieldFromScreen(roofScreen, id)) {
        console.log(`[13] Removed ${id} (last 3 built/covered with) from Roof`);
        changeCount++;
      }
    }

    // 14. Add "Mansard/Other" to Roof Types dropdown
    const roofTypesDropdown = roofScreen.fields.find(
      f => f.id === 'android_material_design_spinner5' && f.label === 'Roof Types'
    );
    if (roofTypesDropdown && roofTypesDropdown.options) {
      if (!roofTypesDropdown.options.includes('Mansard/Other')) {
        // Insert before "Other"
        const otherIdx = roofTypesDropdown.options.indexOf('Other');
        if (otherIdx >= 0) {
          roofTypesDropdown.options.splice(otherIdx, 0, 'Mansard/Other');
        } else {
          roofTypesDropdown.options.push('Mansard/Other');
        }
        console.log(`[14] Added "Mansard/Other" to Roof Types`);
        changeCount++;
      }
    }

    // 15. Add Plastic, Asphalt, Polycarbonate to Roof Material checkboxes
    const lastMaterialCheckbox = roofScreen.fields.find(f => f.id === 'ch16'); // "Other" in materials
    if (lastMaterialCheckbox) {
      const materialIds = ['ch_plastic', 'ch_asphalt', 'ch_polycarbonate'];
      const materialLabels = ['Plastic', 'Asphalt', 'Polycarbonate'];
      // Insert before the "Other" checkbox (ch16)
      const ch16Idx = roofScreen.fields.findIndex(f => f.id === 'ch16');
      if (ch16Idx >= 0) {
        for (let i = materialLabels.length - 1; i >= 0; i--) {
          // Check if already exists
          if (!roofScreen.fields.find(f => f.id === materialIds[i])) {
            roofScreen.fields.splice(ch16Idx, 0, {
              id: materialIds[i],
              label: materialLabels[i],
              type: 'checkbox'
            });
            console.log(`[15] Added "${materialLabels[i]}" to Roof Material`);
            changeCount++;
          }
        }
      }
    }

    // 16. Add Slates, Coatings to Cover Type checkboxes
    const coverTypeOther = roofScreen.fields.find(f => f.id === 'ch17'); // "Other" in cover type
    if (coverTypeOther) {
      const coverIds = ['ch_slates', 'ch_coatings'];
      const coverLabels = ['Slates', 'Coatings'];
      const ch17Idx = roofScreen.fields.findIndex(f => f.id === 'ch17');
      if (ch17Idx >= 0) {
        for (let i = coverLabels.length - 1; i >= 0; i--) {
          if (!roofScreen.fields.find(f => f.id === coverIds[i])) {
            roofScreen.fields.splice(ch17Idx, 0, {
              id: coverIds[i],
              label: coverLabels[i],
              type: 'checkbox'
            });
            console.log(`[16] Added "${coverLabels[i]}" to Cover Type`);
            changeCount++;
          }
        }
      }
    }

    break;
  }
}

// ========================================================
// 17. PROPERTY CONVERTED: Add conditional logic
// ========================================================
// Find the Property Converted screen - search by title
for (const screen of getAllScreens()) {
  if (screen.title && (screen.title.toLowerCase().includes('converted') || screen.title.toLowerCase().includes('conversion'))) {
    console.log(`[17] Found potential Property Converted screen: ${screen.id} (${screen.title})`);
    // Will handle conditional logic in Dart code
  }
}

// Also search for "Not converted" in dropdown options
for (const screen of getAllScreens()) {
  for (const field of screen.fields) {
    if (field.options && Array.isArray(field.options)) {
      if (field.options.some(o => o.toLowerCase().includes('not converted') || o.toLowerCase().includes('converted'))) {
        console.log(`[17] Found "converted" dropdown in ${screen.id}.${field.id}: ${JSON.stringify(field.options)}`);
      }
    }
  }
}

// ========================================================
// WRITE OUTPUT
// ========================================================
fs.writeFileSync(TREE_PATH, JSON.stringify(tree, null, 2) + '\n', 'utf-8');
console.log(`\nDone! Applied ${changeCount} changes to inspection_tree.json`);
