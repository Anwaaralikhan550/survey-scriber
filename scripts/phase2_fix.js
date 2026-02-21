/**
 * Phase 2 Fix: Handle remaining V2 references missed by the first pass.
 * Issues: relative import paths, additional class/state/notifier names.
 */
const fs = require('fs');
const path = require('path');

const ROOT = 'E:\\s\\scriber\\mobile-app';

const EXCLUDE_PATHS = [
  'lib\\core\\database\\tables\\',
  'lib\\core\\database\\app_database.g.dart',
];

function shouldExclude(filePath) {
  const rel = path.relative(ROOT, filePath);
  return EXCLUDE_PATHS.some(ex => rel.startsWith(ex));
}

// Remaining replacements (ordered most specific → least specific)
const replacements = [
  // ─── Relative import path directories (not caught by features/ prefix) ───
  // These are relative imports like ../../../inspection_v2/ that don't contain 'features/'
  ['/inspection_v2/', '/property_inspection/'],
  ['/valuation_v2/', '/property_valuation/'],

  // ─── PascalCase classes missed in first pass ───
  // Report document model classes
  ['V2ReportFieldType', 'ReportFieldType'],
  ['V2ReportSignature', 'ReportSignature'],
  ['V2ReportSection', 'ReportSection'],
  ['V2ReportScreen', 'ReportScreen'],
  ['V2ReportField', 'ReportField'],
  ['V2ReportType', 'ReportType'],

  // Export state/notifier
  ['V2ExportNotifier', 'ExportNotifier'],
  ['V2ExportState', 'ExportState'],

  // Admin state/notifier
  ['V2AdminNotifier', 'TreeAdminNotifier'],
  ['V2AdminState', 'TreeAdminState'],

  // AI classes (specific before catch-all)
  ['AiV2RecommendationsNotifier', 'AiRecommendationsNotifier'],
  ['AiV2RecommendationsState', 'AiRecommendationsState'],
  ['AiV2ConsistencyNotifier', 'AiConsistencyNotifier'],
  ['AiV2ConsistencySheet', 'AiConsistencySheet'],
  ['AiV2ConsistencyState', 'AiConsistencyState'],
  ['AiV2ReportNotifier', 'AiReportNotifier'],
  ['AiV2ReportState', 'AiReportState'],
  ['AiV2RiskNotifier', 'AiRiskNotifier'],
  ['AiV2RiskSheet', 'AiRiskSheet'],
  ['AiV2RiskState', 'AiRiskState'],
  ['AiV2FormattedRequest', 'AiFormattedRequest'],
  ['AiV2Result', 'AiResult'],

  // ─── Logger tag strings ───
  ["'V2ReportData'", "'ReportData'"],
  ["'V2PdfGen'", "'PdfGen'"],
  ["'V2DocxGen'", "'DocxGen'"],
  ["'V2Export'", "'Export'"],
  ["'AiV2Report'", "'AiReport'"],
  ["'AiV2Consistency'", "'AiConsistency'"],
  ["'AiV2Risk'", "'AiRisk'"],
  ["'AiV2Recommendations'", "'AiRecommendations'"],
];

function collectDartFiles(dir, files = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === 'node_modules' || entry.name === '.dart_tool') continue;
      collectDartFiles(fullPath, files);
    } else if (entry.name.endsWith('.dart')) {
      files.push(fullPath);
    }
  }
  return files;
}

const dartFiles = [
  ...collectDartFiles(path.join(ROOT, 'lib')),
  ...collectDartFiles(path.join(ROOT, 'test')),
];

let filesModified = 0;

for (const filePath of dartFiles) {
  if (shouldExclude(filePath)) continue;

  const original = fs.readFileSync(filePath, 'utf8');
  let result = original;

  for (const [from, to] of replacements) {
    result = result.split(from).join(to);
  }

  if (result !== original) {
    fs.writeFileSync(filePath, result, 'utf8');
    filesModified++;
    console.log(`FIXED: ${path.relative(ROOT, filePath)}`);
  }
}

console.log(`\nTotal: ${filesModified} files fixed\n`);

// Verify
console.log('=== Verification (excluding database + intentional V2 strings) ===\n');
const checkPatterns = [
  'InspectionV2', 'ValuationV2', 'V2Report', 'V2Export', 'V2Pdf', 'V2Docx',
  'V2Admin', 'AiV2',
];

// These are intentional V2 strings that should remain
const allowedPatterns = [
  "inspection_v2_floor_plan",  // DB key
  "inspection_v2_phrase_texts", // Backend file
  "inspection_v2',",  // Backend API parameter in enum
  "valuation_v2',",   // Backend API parameter in enum
  "valuation_v2_floor_plan", // DB key
];

let issues = 0;
for (const filePath of dartFiles) {
  if (shouldExclude(filePath)) continue;
  if (!fs.existsSync(filePath)) continue;

  const content = fs.readFileSync(filePath, 'utf8');
  for (const pattern of checkPatterns) {
    if (content.includes(pattern)) {
      // Check if it's an allowed pattern
      const lines = content.split('\n');
      for (const line of lines) {
        if (line.includes(pattern)) {
          const isAllowed = allowedPatterns.some(a => line.includes(a));
          if (!isAllowed) {
            console.log(`WARNING: ${path.relative(ROOT, filePath)} — "${line.trim().substring(0, 100)}"`);
            issues++;
          }
        }
      }
      break;
    }
  }
}

if (issues === 0) {
  console.log('All clean! No unexpected V2 references remain.\n');
} else {
  console.log(`\n${issues} remaining V2 references need review.\n`);
}
