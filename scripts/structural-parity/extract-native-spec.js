/**
 * Extract Native App Structural Spec
 *
 * Parses every native layout XML + strings.xml + Java activity files
 * to produce a normalized structural spec for comparison with V2.
 *
 * Output: scripts/structural-parity/native-spec.json
 */
const fs = require('fs');
const path = require('path');

const NATIVE_ROOT = path.resolve('E:/s/scriber/mobile-app-old-native/app/src/main');
const LAYOUT_DIR = path.join(NATIVE_ROOT, 'res/layout');
const STRINGS_PATH = path.join(NATIVE_ROOT, 'res/values/strings.xml');
const ACTIVITY_DIR = path.join(NATIVE_ROOT, 'java/com/surveyscriber/android/activity');
const OUTPUT_PATH = path.join(__dirname, 'native-spec.json');

// --- Step 1: Parse strings.xml ---
function parseStringsXml() {
  const content = fs.readFileSync(STRINGS_PATH, 'utf-8');

  const strings = {};
  const stringArrays = {};

  // Parse <string name="X">value</string>
  const stringRegex = /<string name="([^"]+)">([\s\S]*?)<\/string>/g;
  let m;
  while ((m = stringRegex.exec(content)) !== null) {
    strings[m[1]] = m[2].trim();
  }

  // Parse <string-array name="X"><item>...</item>...</string-array>
  const arrayRegex = /<string-array name="([^"]+)">([\s\S]*?)<\/string-array>/g;
  while ((m = arrayRegex.exec(content)) !== null) {
    const name = m[1];
    const body = m[2];
    const items = [];
    const itemRegex = /<item>([\s\S]*?)<\/item>/g;
    let im;
    while ((im = itemRegex.exec(body)) !== null) {
      items.push(im[1].trim());
    }
    stringArrays[name] = items;
  }

  return { strings, stringArrays };
}

// --- Step 2: Classify layout as FORM or NAVIGATION ---
function classifyLayout(xmlContent) {
  const hasFormElements = /AutoCompleteTextView|EditText|TextInputEditText|CheckBox/.test(xmlContent);
  const hasChevronNav = /chevron_right|arrow_right|ic_chevron/.test(xmlContent) ||
    // Navigation screens typically have multiple RelativeLayouts with ImageView + TextView patterns
    // and NO form inputs
    (xmlContent.match(/fd_Rl\d+/g) || []).length > 3;

  if (hasFormElements) return 'FORM';
  if (hasChevronNav && !hasFormElements) return 'NAVIGATION';

  // If it has a submit/next button but no form fields, it might be a simple screen
  if (/al_btnNext|btnSubmit/.test(xmlContent)) return 'FORM';

  return 'NAVIGATION';
}

// --- Step 3: Extract fields from layout XML ---
function extractFieldsFromXml(xmlContent, stringsData) {
  const fields = [];
  const lines = xmlContent.split('\n');

  // Track visibility context - which container wraps each field
  let currentContainerId = null;
  let containerVisibility = {}; // containerId -> 'gone' | 'visible'

  // We'll process XML line by line to maintain order
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    // Track container visibility (LinearLayout with visibility="gone")
    const containerMatch = line.match(/android:id="@\+id\/([^"]+)"/);
    if (containerMatch) {
      const nextLines = lines.slice(i, Math.min(i + 5, lines.length)).join('\n');
      if (/android:visibility="gone"/.test(nextLines) && /LinearLayout/.test(nextLines)) {
        containerVisibility[containerMatch[1]] = 'gone';
      }
    }

    // Section headers: <TextView style="@style/ModernSectionHeader" ... android:text="X"/>
    if (/TextView/.test(line)) {
      const chunk = lines.slice(i, Math.min(i + 8, lines.length)).join(' ');
      if (/ModernSectionHeader/.test(chunk)) {
        let text = '';
        const textMatch = chunk.match(/android:text="([^"]+)"/);
        if (textMatch) {
          text = resolveString(textMatch[1], stringsData);
        }
        if (text) {
          fields.push({ type: 'label', label: text });
        }
      }
    }

    // AutoCompleteTextView (dropdown)
    if (/AutoCompleteTextView/.test(line)) {
      const chunk = lines.slice(Math.max(0, i - 10), Math.min(i + 8, lines.length)).join(' ');
      const idMatch = chunk.match(/android:id="@\+id\/([^"]+)"/);
      // Get hint from enclosing TextInputLayout
      const hintMatch = chunk.match(/android:hint="([^"]+)"/);
      if (idMatch) {
        const field = {
          type: 'dropdown',
          id: idMatch[1],
          label: hintMatch ? resolveString(hintMatch[1], stringsData) : ''
        };
        // Check for static visibility="gone" on parent
        const parentGone = /android:visibility="gone"/.test(
          lines.slice(Math.max(0, i - 8), i + 1).join(' ')
        );
        if (parentGone) {
          field.staticVisibility = 'gone';
        }
        fields.push(field);
      }
    }

    // EditText / TextInputEditText
    if (/(EditText|TextInputEditText)/.test(line) && !/AutoCompleteTextView/.test(line)) {
      const chunk = lines.slice(Math.max(0, i - 10), Math.min(i + 8, lines.length)).join(' ');
      const idMatch = chunk.match(/android:id="@\+id\/([^"]+)"/);
      const hintMatch = chunk.match(/android:hint="([^"]+)"/);
      const inputTypeMatch = chunk.match(/android:inputType="([^"]+)"/);
      if (idMatch) {
        const fieldType = (inputTypeMatch && inputTypeMatch[1] === 'number') ? 'number' : 'text';
        const field = {
          type: fieldType,
          id: idMatch[1],
          label: hintMatch ? resolveString(hintMatch[1], stringsData) : ''
        };
        // Check for static visibility="gone"
        const selfGone = /android:visibility="gone"/.test(chunk);
        if (selfGone) {
          field.staticVisibility = 'gone';
        }
        fields.push(field);
      }
    }

    // CheckBox
    if (/CheckBox/.test(line) && !/AutoCompleteTextView|EditText/.test(line)) {
      const chunk = lines.slice(i, Math.min(i + 10, lines.length)).join(' ');
      const idMatch = chunk.match(/android:id="@\+id\/([^"]+)"/);
      const textMatch = chunk.match(/android:text="([^"]+)"/);
      if (idMatch) {
        const field = {
          type: 'checkbox',
          id: idMatch[1],
          label: textMatch ? resolveString(textMatch[1], stringsData) : ''
        };
        const selfGone = /android:visibility="gone"/.test(chunk);
        if (selfGone) {
          field.staticVisibility = 'gone';
        }
        fields.push(field);
      }
    }
  }

  return fields;
}

function resolveString(value, stringsData) {
  if (value.startsWith('@string/')) {
    const key = value.replace('@string/', '');
    return stringsData.strings[key] || value;
  }
  return value;
}

// --- Step 4: Extract dropdown arrays from Java activities ---
function extractDropdownArraysFromJava(javaContent) {
  const arrays = {};

  // Match patterns like: getResources().getStringArray(R.array.Property_Type)
  // Associated with view IDs via adapter setups
  const arrayRegex = /getStringArray\(R\.array\.(\w+)\)/g;
  let m;
  const foundArrays = [];
  while ((m = arrayRegex.exec(javaContent)) !== null) {
    foundArrays.push({ name: m[1], index: m.index });
  }

  // Try to associate arrays with view IDs
  // Pattern: Find the variable name for the adapter, then find which view it's set on
  // Common patterns:
  //   final String[] data = getResources().getStringArray(R.array.X);
  //   ... adapter = new ArrayAdapter<>(ctx, layout, data);
  //   spView.setAdapter(adapter);
  //
  // Or look for field references near the array call
  for (const arr of foundArrays) {
    // Look in a window around the array reference for spinner IDs
    const contextStart = Math.max(0, arr.index - 500);
    const contextEnd = Math.min(javaContent.length, arr.index + 1000);
    const context = javaContent.substring(contextStart, contextEnd);

    // Find field IDs (R.id.X) in this context
    const idMatches = context.match(/R\.id\.(\w+)/g);
    if (idMatches) {
      // Filter to likely spinner IDs (not toolbar, button, etc.)
      const spinnerIds = idMatches
        .map(id => id.replace('R.id.', ''))
        .filter(id => /spinner|actv|sp[A-Z]/.test(id) || /android_material_design_spinner/.test(id));

      if (spinnerIds.length > 0) {
        // Associate with the first spinner found in context
        arrays[spinnerIds[0]] = arr.name;
      }
    }
  }

  return arrays;
}

// --- Step 5: Extract visibility rules from Java ---
function extractVisibilityRulesFromJava(javaContent) {
  const rules = [];

  // Pattern: mLlX.setVisibility(View.VISIBLE) or View.GONE
  // Usually inside onItemClick or text change listeners
  const visRegex = /(\w+)\.setVisibility\(View\.(VISIBLE|GONE)\)/g;
  let m;
  while ((m = visRegex.exec(javaContent)) !== null) {
    const viewVar = m[1];
    const visibility = m[2];

    // Look for the view ID by finding the findViewById for this variable
    const findViewRegex = new RegExp(`${viewVar}\\s*=\\s*(?:\\(\\w+\\)\\s*)?findViewById\\(R\\.id\\.(\\w+)\\)`);
    const viewIdMatch = javaContent.match(findViewRegex);

    if (viewIdMatch) {
      // Try to find what condition triggers this visibility change
      const contextStart = Math.max(0, m.index - 800);
      const context = javaContent.substring(contextStart, m.index);

      // Look for the trigger value
      const triggerMatch = context.match(/(?:equals|equalsIgnoreCase)\("([^"]+)"\)/);
      const spinnerTrigger = context.match(/(?:getText|getSelectedItem).*?(\w+)\.(getText|getSelectedItem)/);

      rules.push({
        targetContainer: viewIdMatch[1],
        visibility: visibility.toLowerCase(),
        triggerValue: triggerMatch ? triggerMatch[1] : null,
        raw: m[0]
      });
    }
  }

  return rules;
}

// --- Main extraction ---
function main() {
  console.log('=== Native Spec Extraction ===\n');

  // Step 1: Parse strings
  console.log('Parsing strings.xml...');
  const stringsData = parseStringsXml();
  console.log(`  Found ${Object.keys(stringsData.strings).length} strings`);
  console.log(`  Found ${Object.keys(stringsData.stringArrays).length} string arrays`);

  // Step 2: Process all layout XMLs
  console.log('\nProcessing layout XMLs...');
  const layoutFiles = fs.readdirSync(LAYOUT_DIR)
    .filter(f => f.startsWith('activity_') && f.endsWith('.xml'));
  console.log(`  Found ${layoutFiles.length} activity layout files`);

  // Step 3: Process all Java activities
  console.log('\nProcessing Java activities...');
  const javaFiles = fs.readdirSync(ACTIVITY_DIR)
    .filter(f => f.endsWith('.java'));
  console.log(`  Found ${javaFiles.length} Java activity files`);

  // Build Java -> Layout mapping (from setContentView calls)
  const javaLayoutMap = {}; // layoutName -> javaContent
  const javaDropdownMap = {}; // layoutName -> { fieldId: arrayName }
  const javaVisibilityMap = {}; // layoutName -> rules[]

  for (const javaFile of javaFiles) {
    try {
      const javaContent = fs.readFileSync(path.join(ACTIVITY_DIR, javaFile), 'utf-8');

      // Find setContentView(R.layout.X)
      const layoutMatch = javaContent.match(/setContentView\(R\.layout\.(\w+)\)/);
      if (layoutMatch) {
        const layoutName = layoutMatch[1];
        javaLayoutMap[layoutName] = javaContent;

        // Extract dropdown array mappings
        const dropdownArrays = extractDropdownArraysFromJava(javaContent);
        if (Object.keys(dropdownArrays).length > 0) {
          javaDropdownMap[layoutName] = dropdownArrays;
        }

        // Extract visibility rules
        const visRules = extractVisibilityRulesFromJava(javaContent);
        if (visRules.length > 0) {
          javaVisibilityMap[layoutName] = visRules;
        }
      }
    } catch (e) {
      // Skip files that can't be read
    }
  }

  // Step 4: Build native spec
  const nativeSpec = {};
  let formCount = 0;
  let navCount = 0;
  let skipCount = 0;

  for (const layoutFile of layoutFiles) {
    const layoutName = layoutFile.replace('.xml', '');

    try {
      const xmlContent = fs.readFileSync(path.join(LAYOUT_DIR, layoutFile), 'utf-8');
      const classification = classifyLayout(xmlContent);

      if (classification === 'NAVIGATION') {
        navCount++;
        continue;
      }

      formCount++;
      const fields = extractFieldsFromXml(xmlContent, stringsData);

      // Enrich dropdowns with options from string arrays
      const dropdownArrays = javaDropdownMap[layoutName] || {};
      for (const field of fields) {
        if (field.type === 'dropdown') {
          // Check if we found the array mapping from Java
          const arrayName = dropdownArrays[field.id];
          if (arrayName && stringsData.stringArrays[arrayName]) {
            field.options = stringsData.stringArrays[arrayName];
            field.arrayName = arrayName;
          }
        }
      }

      // Try to find screen title from Java
      let screenTitle = layoutName.replace('activity_', '').replace(/_/g, ' ');
      const javaContent = javaLayoutMap[layoutName];
      if (javaContent) {
        // Look for mTvTitle.setText("X")
        const titleMatch = javaContent.match(/mTvTitle\.setText\("([^"]+)"\)/);
        if (titleMatch) {
          screenTitle = titleMatch[1];
        }
      }

      nativeSpec[layoutName] = {
        layoutFile: layoutFile,
        screenTitle: screenTitle,
        classification: classification,
        fields: fields,
        fieldCount: fields.length,
        visibilityRules: javaVisibilityMap[layoutName] || []
      };
    } catch (e) {
      skipCount++;
    }
  }

  console.log(`\n  Form screens: ${formCount}`);
  console.log(`  Navigation screens: ${navCount}`);
  console.log(`  Skipped: ${skipCount}`);
  console.log(`  Total screens in spec: ${Object.keys(nativeSpec).length}`);

  // Step 5: Also include string arrays for reference
  const output = {
    meta: {
      extractedAt: new Date().toISOString(),
      layoutsProcessed: layoutFiles.length,
      formScreens: formCount,
      navigationScreens: navCount,
      stringArrayCount: Object.keys(stringsData.stringArrays).length
    },
    screens: nativeSpec,
    stringArrays: stringsData.stringArrays
  };

  fs.writeFileSync(OUTPUT_PATH, JSON.stringify(output, null, 2));
  console.log(`\nOutput: ${OUTPUT_PATH}`);

  // Print summary of screens with fields
  const screensWithFields = Object.entries(nativeSpec)
    .filter(([_, s]) => s.fields.length > 0)
    .sort((a, b) => b[1].fields.length - a[1].fields.length);

  console.log(`\nTop 20 screens by field count:`);
  screensWithFields.slice(0, 20).forEach(([name, spec]) => {
    const labels = spec.fields.filter(f => f.type === 'label').length;
    const dropdowns = spec.fields.filter(f => f.type === 'dropdown').length;
    const texts = spec.fields.filter(f => f.type === 'text' || f.type === 'number').length;
    const checkboxes = spec.fields.filter(f => f.type === 'checkbox').length;
    console.log(`  ${name}: ${spec.fields.length} fields (${labels}L ${dropdowns}D ${texts}T ${checkboxes}C)`);
  });
}

main();
