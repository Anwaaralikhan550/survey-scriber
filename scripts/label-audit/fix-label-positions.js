/**
 * fix-label-positions.js
 *
 * Finds and fixes labels that are clustered together (consecutive)
 * instead of being properly interspersed before their field groups.
 * Uses native XML field ordering as the source of truth.
 */

const fs = require('fs');
const path = require('path');

const TREE_FILE = path.resolve('E:/s/scriber/mobile-app/assets/property_inspection/inspection_tree.json');
const LAYOUT_DIR = path.resolve('E:/s/scriber/mobile-app-old-native/app/src/main/res/layout');
const STRINGS_FILE = path.resolve('E:/s/scriber/mobile-app-old-native/app/src/main/res/values/strings.xml');
const LOG_FILE = path.join(__dirname, 'reposition_log.json');

function loadStringResources() {
  const xml = fs.readFileSync(STRINGS_FILE, 'utf8');
  const map = {};
  const re = /<string\s+name="([^"]+)"[^>]*>([^<]*)<\/string>/g;
  let m;
  while ((m = re.exec(xml)) !== null) {
    map[m[1]] = m[2].trim();
  }
  return map;
}

function parseNativeLayoutSequence(xmlContent, strings) {
  const sequence = [];

  const headingRegex = /<TextView\b([^>]*style="@style\/TextViewItem"[^>]*)(?:\/>|>[^<]*<\/TextView>)/gs;
  let m;
  while ((m = headingRegex.exec(xmlContent)) !== null) {
    const attrs = m[1];
    const textMatch = attrs.match(/android:text="([^"]+)"/);
    if (!textMatch) continue;
    let text = textMatch[1];
    if (text.startsWith('@string/')) {
      text = strings[text.replace('@string/', '')] || text;
    }
    if (text.startsWith('@') || text === '') continue;
    sequence.push({ kind: 'heading', text, offset: m.index });
  }

  const cbRegex = /<CheckBox\b[^>]*android:id="@\+id\/([^"]+)"[^>]*>/gs;
  while ((m = cbRegex.exec(xmlContent)) !== null) {
    sequence.push({ kind: 'field', id: m[1], offset: m.index });
  }

  const actvRegex = /<AutoCompleteTextView\b[^>]*android:id="@\+id\/([^"]+)"[^>]*>/gs;
  while ((m = actvRegex.exec(xmlContent)) !== null) {
    sequence.push({ kind: 'field', id: m[1], offset: m.index });
  }

  const etRegex = /<EditText\b[^>]*android:id="@\+id\/([^"]+)"[^>]*>/gs;
  while ((m = etRegex.exec(xmlContent)) !== null) {
    sequence.push({ kind: 'field', id: m[1], offset: m.index });
  }

  const spRegex = /<Spinner\b[^>]*android:id="@\+id\/([^"]+)"[^>]*>/gs;
  while ((m = spRegex.exec(xmlContent)) !== null) {
    sequence.push({ kind: 'field', id: m[1], offset: m.index });
  }

  sequence.sort((a, b) => a.offset - b.offset);
  return sequence;
}

function main() {
  const strings = loadStringResources();
  const tree = JSON.parse(fs.readFileSync(TREE_FILE, 'utf8'));
  const repositionLog = [];
  let totalMoved = 0;

  function walkNode(node) {
    if (node.type === 'screen' && node.fields && node.fields.length > 0) {
      const labels = node.fields.filter(f => f.type === 'label');
      if (labels.length < 2) return; // Need at least 2 labels to detect clustering

      // Check if labels are clustered (2+ consecutive labels with no fields between)
      const labelPositions = labels.map(l => node.fields.indexOf(l));
      let consecutiveCount = 0;
      for (let i = 1; i < labelPositions.length; i++) {
        if (labelPositions[i] === labelPositions[i - 1] + 1) {
          consecutiveCount++;
        }
      }

      // If most labels are consecutive, they're likely clustered
      if (consecutiveCount < labels.length - 1) return; // Labels are already spread out

      // Find native layout
      const layoutName = node.id.split('__')[0];
      const xmlPath = path.join(LAYOUT_DIR, layoutName + '.xml');
      if (!fs.existsSync(xmlPath)) return;

      const xmlContent = fs.readFileSync(xmlPath, 'utf8');
      const sequence = parseNativeLayoutSequence(xmlContent, strings);

      // Build heading → firstFieldIdAfter map from native
      const headingMap = [];
      for (let i = 0; i < sequence.length; i++) {
        if (sequence[i].kind === 'heading') {
          let firstFieldId = null;
          for (let j = i + 1; j < sequence.length; j++) {
            if (sequence[j].kind === 'field') {
              firstFieldId = sequence[j].id;
              break;
            }
          }
          headingMap.push({
            text: sequence[i].text,
            firstFieldIdAfter: firstFieldId,
          });
        }
      }

      if (headingMap.length === 0) return;

      // Remove labels from current positions
      const removedLabels = [];
      for (const label of labels) {
        const normalizedLabel = label.label.toLowerCase().trim();
        const match = headingMap.find(h =>
          h.text.toLowerCase().trim() === normalizedLabel
        );
        if (match) {
          removedLabels.push({ label, targetFieldId: match.firstFieldIdAfter });
        }
      }

      if (removedLabels.length === 0) return;

      // Remove all matched labels
      node.fields = node.fields.filter(f =>
        f.type !== 'label' || !removedLabels.some(rl => rl.label.id === f.id)
      );

      // Re-insert at correct positions (from back to front to avoid shifts)
      const insertions = [];
      for (const { label, targetFieldId } of removedLabels) {
        if (targetFieldId) {
          const idx = node.fields.findIndex(f => f.id === targetFieldId);
          if (idx >= 0) {
            insertions.push({ position: idx, label });
          } else {
            // Can't find target, put at beginning
            insertions.push({ position: 0, label });
          }
        } else {
          insertions.push({ position: 0, label });
        }
      }

      // Sort by position descending
      insertions.sort((a, b) => b.position - a.position);

      for (const { position, label } of insertions) {
        node.fields.splice(position, 0, label);
        repositionLog.push({
          screenId: node.id,
          labelId: label.id,
          labelText: label.label,
          newPosition: position,
        });
        totalMoved++;
      }
    }

    const kids = node.children || node.nodes || [];
    for (const child of kids) {
      walkNode(child);
    }
  }

  for (const section of tree.sections) {
    for (const node of section.nodes || []) {
      walkNode(node);
    }
  }

  if (totalMoved > 0) {
    fs.writeFileSync(TREE_FILE, JSON.stringify(tree, null, 2));
    console.log(`Repositioned ${totalMoved} labels across ${new Set(repositionLog.map(r => r.screenId)).size} screens`);
  } else {
    console.log('No labels needed repositioning');
  }

  fs.writeFileSync(LOG_FILE, JSON.stringify(repositionLog, null, 2));
}

main();
