/**
 * PHASE 1: Deep Heading Extraction
 *
 * Parses ALL native XML layouts and extracts headings (TextViewItem) plus
 * input field IDs in exact DOM order, producing a complete structural map.
 *
 * This handles:
 * - TextViewItem headings (both inline text and @string/ references)
 * - Visibility="gone" on headings AND their parent containers
 * - Headings inside navigation rows (RelativeLayout with chevrons) — excluded
 * - Spinner, EditText, CheckBox, TextInputLayout field IDs
 * - Nested LinearLayout containers with visibility toggles
 */
const fs = require('fs');
const path = require('path');

const layoutDir = 'E:/s/scriber/mobile-app-old-native/app/src/main/res/layout';
const stringsPath = 'E:/s/scriber/mobile-app-old-native/app/src/main/res/values/strings.xml';

// Load strings.xml for @string/ resolution
const stringsContent = fs.readFileSync(stringsPath, 'utf8');
const stringMap = {};
const stringRegex = /<string name="([^"]+)">([\s\S]*?)<\/string>/g;
let match;
while ((match = stringRegex.exec(stringsContent)) !== null) {
  stringMap[match[1]] = match[2].replace(/\\n/g, '\n').replace(/\\'/g, "'").trim();
}

// Get all activity XML files
const files = fs.readdirSync(layoutDir).filter(f => f.startsWith('activity_') && f.endsWith('.xml'));

function resolveText(text) {
  if (!text) return null;
  if (text.startsWith('@string/')) {
    const key = text.replace('@string/', '');
    return stringMap[key] || text;
  }
  return text;
}

/**
 * Determine if a position in the XML is inside a gone parent container.
 * We look backwards for the nearest unclosed LinearLayout/RelativeLayout
 * and check if it has visibility="gone".
 */
function isInsideGoneContainer(content, position) {
  // Look backwards from position for parent containers
  const before = content.substring(0, position);

  // Track open/close LinearLayout tags
  let depth = 0;
  const tags = [];

  // Find all LinearLayout and RelativeLayout opens/closes before this position
  const tagRegex = /<(\/?)(?:LinearLayout|RelativeLayout|ScrollView|FrameLayout)\b([^>]*?)(?:\/?)>/g;
  let tm;
  while ((tm = tagRegex.exec(before)) !== null) {
    if (tm[1] === '/') {
      // closing tag
      tags.pop();
    } else if (!tm[0].endsWith('/>')) {
      // opening tag (not self-closing)
      tags.push({ pos: tm.index, attrs: tm[2] });
    }
  }

  // Check if any unclosed parent has visibility="gone"
  for (const tag of tags) {
    if (tag.attrs && tag.attrs.includes('android:visibility="gone"')) {
      return true;
    }
  }
  return false;
}

/**
 * Check if position is inside a RelativeLayout (navigation row with chevron).
 * These TextViewItems are navigation labels, not section headings.
 */
function isInsideNavRow(content, position) {
  const before = content.substring(Math.max(0, position - 1000), position);
  // Find the last RelativeLayout opening that's not closed
  const lastRL = before.lastIndexOf('<RelativeLayout');
  if (lastRL < 0) return false;
  const afterRL = before.substring(lastRL);
  // Check if it's closed before our position
  if (afterRL.includes('</RelativeLayout>')) return false;
  // Check for chevron indicators (ImageView with chevron or arrow)
  const chunk = content.substring(position - 1000 < 0 ? 0 : position - 1000, position + 500);
  const rlStart = chunk.lastIndexOf('<RelativeLayout');
  if (rlStart >= 0) {
    const rlEnd = chunk.indexOf('</RelativeLayout>', rlStart);
    if (rlEnd >= 0) {
      const rlContent = chunk.substring(rlStart, rlEnd);
      if (rlContent.includes('ic_chevron') || rlContent.includes('ic_keyboard_arrow') ||
          rlContent.includes('arrow_right') || rlContent.includes('ImageView')) {
        return true;
      }
    }
  }
  return false;
}

const results = {};

for (const file of files) {
  const filePath = path.join(layoutDir, file);
  const content = fs.readFileSync(filePath, 'utf8');
  const screenId = file.replace('.xml', '');

  const elements = [];

  // We need to find all relevant elements in DOM order
  // Use a regex that captures all element types we care about
  const elementRegex = /<(TextView|Spinner|EditText|CheckBox|com\.google\.android\.material\.textfield\.TextInputLayout|AutoCompleteTextView)\b([\s\S]*?)(?:\/>|<\/\1>|<\/com\.google\.android\.material\.textfield\.TextInputLayout>)/g;

  let elemMatch;
  while ((elemMatch = elementRegex.exec(content)) !== null) {
    const tagName = elemMatch[1];
    const block = elemMatch[0];
    const attrs = elemMatch[2];
    const pos = elemMatch.index;

    if (tagName === 'TextView') {
      // Check if it's a TextViewItem heading
      if (!block.includes('TextViewItem')) continue;

      // Skip if the heading itself has visibility="gone"
      if (block.includes('android:visibility="gone"')) continue;

      // Skip if inside a gone parent container
      if (isInsideGoneContainer(content, pos)) continue;

      // Skip if inside a navigation row (RelativeLayout with chevron)
      if (isInsideNavRow(content, pos)) continue;

      // Extract text
      const textMatch = block.match(/android:text="([^"]+)"/);
      if (!textMatch) continue;

      const text = resolveText(textMatch[1]);
      if (!text || text.trim() === '' || text === 'Dashboard') continue;

      elements.push({
        type: 'heading',
        text: text.trim(),
        position: pos,
      });
    } else if (tagName === 'Spinner' || tagName === 'AutoCompleteTextView') {
      // Skip if visibility="gone"
      if (block.includes('android:visibility="gone"')) continue;
      if (isInsideGoneContainer(content, pos)) continue;

      const idMatch = block.match(/android:id="@\+id\/([^"]+)"/);
      if (idMatch) {
        elements.push({
          type: 'field',
          fieldType: 'spinner',
          id: idMatch[1],
          position: pos,
        });
      }
    } else if (tagName === 'com.google.android.material.textfield.TextInputLayout') {
      if (block.includes('android:visibility="gone"')) continue;
      if (isInsideGoneContainer(content, pos)) continue;

      // Extract the nested EditText ID
      const innerIdMatch = block.match(/android:id="@\+id\/([^"]+)"/);
      // Also try to get hint text for identification
      const hintMatch = block.match(/android:hint="([^"]+)"/);

      if (innerIdMatch) {
        elements.push({
          type: 'field',
          fieldType: 'text',
          id: innerIdMatch[1],
          hint: hintMatch ? resolveText(hintMatch[1]) : undefined,
          position: pos,
        });
      }
    } else if (tagName === 'EditText') {
      if (block.includes('android:visibility="gone"')) continue;
      if (isInsideGoneContainer(content, pos)) continue;

      const idMatch = block.match(/android:id="@\+id\/([^"]+)"/);
      if (idMatch) {
        elements.push({
          type: 'field',
          fieldType: 'text',
          id: idMatch[1],
          position: pos,
        });
      }
    } else if (tagName === 'CheckBox') {
      if (block.includes('android:visibility="gone"')) continue;
      if (isInsideGoneContainer(content, pos)) continue;

      const idMatch = block.match(/android:id="@\+id\/([^"]+)"/);
      const textMatch = block.match(/android:text="([^"]+)"/);
      if (idMatch) {
        elements.push({
          type: 'field',
          fieldType: 'checkbox',
          id: idMatch[1],
          text: textMatch ? resolveText(textMatch[1]) : undefined,
          position: pos,
        });
      }
    }
  }

  // Sort by position to ensure DOM order
  elements.sort((a, b) => a.position - b.position);

  // Remove position from output
  const cleaned = elements.map(e => {
    const { position, ...rest } = e;
    return rest;
  });

  if (cleaned.length > 0) {
    results[screenId] = cleaned;
  }
}

const outputPath = path.join(__dirname, 'native-inspection-structure.json');
fs.writeFileSync(outputPath, JSON.stringify(results, null, 2));

// Stats
let totalHeadings = 0;
let totalFields = 0;
let screensWithHeadings = 0;
for (const [id, elements] of Object.entries(results)) {
  const headings = elements.filter(e => e.type === 'heading');
  const fields = elements.filter(e => e.type === 'field');
  totalHeadings += headings.length;
  totalFields += fields.length;
  if (headings.length > 0) screensWithHeadings++;
}

console.log(`Screens parsed: ${Object.keys(results).length}`);
console.log(`Screens with headings: ${screensWithHeadings}`);
console.log(`Total headings extracted: ${totalHeadings}`);
console.log(`Total fields extracted: ${totalFields}`);
console.log(`Saved to ${outputPath}`);
