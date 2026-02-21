/**
 * extract-native-headings.js
 *
 * Parses all native Android layout XML files and extracts hardcoded
 * section heading TextViews (style="@style/TextViewItem").
 *
 * Output: native_headings.json — { layoutName: [{ text, position }] }
 */

const fs = require('fs');
const path = require('path');

const LAYOUT_DIR = path.resolve('E:/s/scriber/mobile-app-old-native/app/src/main/res/layout');
const STRINGS_FILE = path.resolve('E:/s/scriber/mobile-app-old-native/app/src/main/res/values/strings.xml');
const OUTPUT_FILE = path.join(__dirname, 'native_headings.json');

// ── Load string resources ────────────────────────────────────────────

function loadStringResources() {
  const xml = fs.readFileSync(STRINGS_FILE, 'utf8');
  const map = {};
  // Match <string name="key">value</string>
  const re = /<string\s+name="([^"]+)"[^>]*>([^<]*)<\/string>/g;
  let m;
  while ((m = re.exec(xml)) !== null) {
    map[m[1]] = m[2].trim();
  }
  return map;
}

// ── Extract heading TextViews from a layout ──────────────────────────

function extractHeadings(xmlContent, strings) {
  const headings = [];

  // Match standalone <TextView> with style="@style/TextViewItem" and android:text
  // These are section heading dividers, NOT spinners or input fields.
  //
  // Key patterns:
  //   <TextView style="@style/TextViewItem" ... android:text="Location" />
  //   <TextView style="@style/TextViewItem" ... android:text="@string/key" />
  //
  // We EXCLUDE: AutoCompleteTextView, EditText, CheckBox (which may also use TextViewItem style)

  // Split into individual XML elements for analysis
  // Use regex to find all <TextView ...> blocks with TextViewItem style
  const tvRegex = /<TextView\b([^>]*style="@style\/TextViewItem"[^>]*)(?:\/>|>[^<]*<\/TextView>)/gs;
  let match;
  let position = 0;

  while ((match = tvRegex.exec(xmlContent)) !== null) {
    const attrs = match[1];

    // Extract android:text attribute
    const textMatch = attrs.match(/android:text="([^"]+)"/);
    if (!textMatch) continue;

    let text = textMatch[1];

    // Resolve @string/ references
    if (text.startsWith('@string/')) {
      const key = text.replace('@string/', '');
      text = strings[key] || key;
    }

    // Skip generic/utility texts that aren't section headings
    if (text === '' || text.startsWith('@') || text.startsWith('$')) continue;

    // Check if this is inside a TextInputLayout (which means it's a styled field, not heading)
    // Simple heuristic: headings don't have android:id typically, or if they do it's rare
    // Actually, the main distinguisher is: headings have android:text, fields have android:hint
    // We already filter for android:text, so this should be fine.

    headings.push({
      text: text,
      position: position++,
      // Store the raw match position for ordering context
      xmlOffset: match.index,
    });
  }

  return headings;
}

// ── Track field elements between headings ────────────────────────────

function extractFieldsBetweenHeadings(xmlContent) {
  // Extract all input elements to understand field ordering
  const fields = [];

  // Checkboxes
  const cbRegex = /<CheckBox\b[^>]*android:id="@\+id\/([^"]+)"[^>]*>/g;
  let m;
  while ((m = cbRegex.exec(xmlContent)) !== null) {
    fields.push({ type: 'checkbox', id: m[1], xmlOffset: m.index });
  }

  // AutoCompleteTextView (spinners/dropdowns)
  const spRegex = /<AutoCompleteTextView\b[^>]*android:id="@\+id\/([^"]+)"[^>]*>/g;
  while ((m = spRegex.exec(xmlContent)) !== null) {
    const attrs = m[0];
    const hint = attrs.match(/android:hint="([^"]+)"/);
    fields.push({
      type: 'dropdown',
      id: m[1],
      hint: hint ? hint[1] : '',
      xmlOffset: m.index
    });
  }

  // EditText
  const etRegex = /<EditText\b[^>]*android:id="@\+id\/([^"]+)"[^>]*>/g;
  while ((m = etRegex.exec(xmlContent)) !== null) {
    const attrs = m[0];
    const hint = attrs.match(/android:hint="([^"]+)"/);
    fields.push({
      type: 'text',
      id: m[1],
      hint: hint ? hint[1] : '',
      xmlOffset: m.index
    });
  }

  // Spinner
  const spinRegex = /<Spinner\b[^>]*android:id="@\+id\/([^"]+)"[^>]*>/g;
  while ((m = spinRegex.exec(xmlContent)) !== null) {
    fields.push({ type: 'spinner', id: m[1], xmlOffset: m.index });
  }

  return fields.sort((a, b) => a.xmlOffset - b.xmlOffset);
}

// ── Interleave headings with fields to get heading-to-fields mapping ─

function buildHeadingFieldMap(headings, fields) {
  // Merge and sort by XML offset
  const all = [
    ...headings.map(h => ({ ...h, kind: 'heading' })),
    ...fields.map(f => ({ ...f, kind: 'field' })),
  ].sort((a, b) => a.xmlOffset - b.xmlOffset);

  const groups = [];
  let currentHeading = null;
  let currentFields = [];

  for (const item of all) {
    if (item.kind === 'heading') {
      if (currentHeading || currentFields.length > 0) {
        groups.push({
          heading: currentHeading,
          fieldCount: currentFields.length,
          firstFieldId: currentFields[0]?.id,
        });
      }
      currentHeading = item.text;
      currentFields = [];
    } else {
      currentFields.push(item);
    }
  }

  // Push last group
  if (currentHeading || currentFields.length > 0) {
    groups.push({
      heading: currentHeading,
      fieldCount: currentFields.length,
      firstFieldId: currentFields[0]?.id,
    });
  }

  return groups;
}

// ── Main ─────────────────────────────────────────────────────────────

function main() {
  console.log('Loading string resources...');
  const strings = loadStringResources();
  console.log(`  Loaded ${Object.keys(strings).length} string entries`);

  console.log('Scanning native layout files...');
  const files = fs.readdirSync(LAYOUT_DIR).filter(f => f.endsWith('.xml'));
  console.log(`  Found ${files.length} layout files`);

  const result = {};
  let totalHeadings = 0;
  let layoutsWithHeadings = 0;

  for (const file of files) {
    const layoutName = file.replace('.xml', '');
    const content = fs.readFileSync(path.join(LAYOUT_DIR, file), 'utf8');

    const headings = extractHeadings(content, strings);
    if (headings.length === 0) continue;

    const fields = extractFieldsBetweenHeadings(content);
    const groups = buildHeadingFieldMap(headings, fields);

    result[layoutName] = {
      headings: headings.map(h => h.text),
      headingDetails: groups.filter(g => g.heading != null).map(g => ({
        text: g.heading,
        fieldsAfter: g.fieldCount,
        firstFieldId: g.firstFieldId || null,
      })),
    };

    totalHeadings += headings.length;
    layoutsWithHeadings++;
  }

  fs.writeFileSync(OUTPUT_FILE, JSON.stringify(result, null, 2));

  console.log('\n=== RESULTS ===');
  console.log(`Layouts with headings: ${layoutsWithHeadings} / ${files.length}`);
  console.log(`Total headings found: ${totalHeadings}`);
  console.log(`Output: ${OUTPUT_FILE}`);

  // Print summary of all unique heading texts
  const allTexts = {};
  for (const [layout, data] of Object.entries(result)) {
    for (const h of data.headings) {
      allTexts[h] = (allTexts[h] || 0) + 1;
    }
  }

  console.log(`\nUnique heading texts (${Object.keys(allTexts).length}):`);
  const sorted = Object.entries(allTexts).sort((a, b) => b[1] - a[1]);
  for (const [text, count] of sorted) {
    console.log(`  ${count}x "${text}"`);
  }
}

main();
