/**
 * Phase 2: Rename V2 files, classes, providers, routes, and imports
 * Handles content replacements across the codebase and physical file renames.
 */
const fs = require('fs');
const path = require('path');

const ROOT = 'E:\\s\\scriber\\mobile-app';

// Files to EXCLUDE from content replacements (database layer)
const EXCLUDE_PATHS = [
  'lib\\core\\database\\tables\\',
  'lib\\core\\database\\app_database.g.dart',
];

function shouldExclude(filePath) {
  const rel = path.relative(ROOT, filePath);
  return EXCLUDE_PATHS.some(ex => rel.startsWith(ex));
}

// ── Content Replacements (ordered from most specific to least specific) ──

const replacements = [
  // ─── A: Import directory paths ───
  ['features/inspection_v2/', 'features/property_inspection/'],
  ['features/valuation_v2/', 'features/property_valuation/'],
  ['assets/inspection_v2/', 'assets/property_inspection/'],
  ['assets/valuation_v2/', 'assets/property_valuation/'],

  // ─── B: Snake_case file names in imports (longest first) ───
  // Inspection files
  ['inspection_v2_compass_page', 'inspection_compass_page'],
  ['inspection_v2_overview_page', 'inspection_overview_page'],
  ['inspection_v2_phrase_engine', 'inspection_phrase_engine'],
  ['inspection_v2_screen_page', 'inspection_screen_page'],
  ['inspection_v2_section_page', 'inspection_section_page'],
  ['inspection_v2_repository', 'inspection_repository'],
  ['inspection_v2_providers', 'inspection_providers'],
  ['inspection_v2_models', 'inspection_models'],
  ['inspection_v2_fields', 'inspection_fields'],
  ['inspection_v2_tree', 'inspection_tree'],
  // Valuation files
  ['valuation_v2_overview_page', 'valuation_overview_page'],
  ['valuation_v2_phrase_engine', 'valuation_phrase_engine'],
  ['valuation_v2_screen_page', 'valuation_screen_page'],
  ['valuation_v2_section_page', 'valuation_section_page'],
  ['valuation_v2_repository', 'valuation_repository'],
  ['valuation_v2_providers', 'valuation_providers'],
  ['valuation_v2_tree', 'valuation_tree'],
  // Report export files
  ['v2_docx_generator_service', 'docx_generator_service'],
  ['v2_pdf_generator_service', 'pdf_generator_service'],
  ['v2_report_data_service', 'report_data_service'],
  ['v2_report_builder', 'report_builder'],
  ['v2_report_document', 'report_document'],
  ['v2_export_bottom_sheet', 'export_bottom_sheet'],
  ['v2_export_providers', 'export_providers'],
  ['v2_export_service', 'export_service'],
  ['v2_export_dialog', 'export_dialog'],
  // Admin files
  ['v2_admin_repository', 'tree_admin_repository'],
  ['v2_admin_providers', 'tree_admin_providers'],
  ['v2_tree_browser_page', 'tree_browser_page'],
  // AI files
  ['ai_v2_data_formatter', 'ai_data_formatter'],
  ['ai_v2_consistency_sheet', 'ai_consistency_sheet'],
  ['ai_v2_risk_sheet', 'ai_risk_sheet'],
  ['ai_v2_providers', 'ai_inspection_providers'],
  ['ai_v2_client', 'ai_client'],

  // ─── C: URL route paths ───
  ['/inspection-v2', '/inspection'],
  ['/valuation-v2', '/valuation'],
  ['/admin/v2-trees', '/admin/trees'],

  // ─── D: PascalCase class names (most specific first) ───
  ['V2ReportDataService', 'ReportDataService'],
  ['V2DocxGeneratorService', 'DocxGeneratorService'],
  ['V2PdfGeneratorService', 'PdfGeneratorService'],
  ['V2ExportBottomSheet', 'ExportBottomSheet'],
  ['V2ReportDocument', 'ReportDocument'],
  ['V2ReportBuilder', 'ReportBuilder'],
  ['V2ExportService', 'ExportService'],
  ['V2ExportConfig', 'ExportConfig'],
  ['V2ExportDialog', 'ExportDialog'],
  ['V2AdminRepository', 'TreeAdminRepository'],
  ['AiV2DataFormatter', 'AiDataFormatter'],
  ['AiV2Client', 'AiInspectionClient'],
  // Catch-all for remaining InspectionV2* and ValuationV2* class names
  ['InspectionV2', 'Inspection'],
  ['ValuationV2', 'Valuation'],

  // ─── E: camelCase provider/variable names (most specific first) ───
  ['v2ReportDataService', 'reportDataService'],
  ['v2ReportBuilder', 'reportBuilder'],
  ['v2ReportDocument', 'reportDocument'],
  ['v2ExportService', 'exportService'],
  ['v2ExportProvider', 'exportProvider'],
  ['v2ExportConfig', 'exportConfig'],
  ['v2Export', 'export'],
  ['v2Report', 'report'],
  ['v2AdminRepository', 'treeAdminRepository'],
  ['v2AdminSelected', 'treeAdminSelected'],
  ['v2Admin', 'treeAdmin'],
  ['aiV2DataFormatter', 'aiDataFormatter'],
  ['aiV2Client', 'aiInspectionClient'],
  ['aiV2', 'aiInspection'],

  // ─── F: Route constant names (camelCase) ───
  ['inspectionV2Detail', 'inspectionDetail'],
  ['inspectionV2Section', 'inspectionSection'],
  ['inspectionV2Node', 'inspectionNode'],
  ['inspectionV2Screen', 'inspectionScreen'],
  ['inspectionV2Compass', 'inspectionCompass'],
  ['valuationV2Detail', 'valuationDetail'],
  ['valuationV2Section', 'valuationSection'],
  ['valuationV2Node', 'valuationNode'],
  ['valuationV2Screen', 'valuationScreen'],
  ['adminV2Trees', 'adminTrees'],
  // Catch-all camelCase (after specific ones above)
  ['inspectionV2', 'inspection'],
  ['valuationV2', 'valuation'],

  // ─── G: Comment/string cleanups ───
  ['Inspection V2', 'Inspection'],
  ['Valuation V2', 'Valuation'],
  ['inspection v2', 'inspection'],
  ['valuation v2', 'valuation'],
  ['// V2 ', '// '],
  ['V2 Trees', 'Survey Trees'],
  ['V2 trees', 'survey trees'],
  ['V2 tree', 'survey tree'],
];

// ── Collect all .dart files + pubspec.yaml ──

function collectFiles(dir, files = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === 'node_modules' || entry.name === '.dart_tool') continue;
      collectFiles(fullPath, files);
    } else if (entry.name.endsWith('.dart')) {
      files.push(fullPath);
    }
  }
  return files;
}

function applyReplacements(content) {
  let result = content;
  for (const [from, to] of replacements) {
    // Use global string replace (not regex, just literal)
    result = result.split(from).join(to);
  }
  return result;
}

// ── STEP 1: Content replacements ──

console.log('=== STEP 1: Content Replacements ===\n');

const dartFiles = [
  ...collectFiles(path.join(ROOT, 'lib')),
  ...collectFiles(path.join(ROOT, 'test')),
];

let filesModified = 0;
let totalReplacements = 0;

for (const filePath of dartFiles) {
  if (shouldExclude(filePath)) {
    console.log(`  SKIP (excluded): ${path.relative(ROOT, filePath)}`);
    continue;
  }

  const original = fs.readFileSync(filePath, 'utf8');
  const modified = applyReplacements(original);

  if (modified !== original) {
    fs.writeFileSync(filePath, modified, 'utf8');
    filesModified++;
    // Count how many replacements were made
    let count = 0;
    for (const [from] of replacements) {
      const matches = original.split(from).length - 1;
      count += matches;
    }
    totalReplacements += count;
    console.log(`  MODIFIED: ${path.relative(ROOT, filePath)} (${count} replacements)`);
  }
}

// Also update pubspec.yaml
const pubspecPath = path.join(ROOT, 'pubspec.yaml');
const pubspecOriginal = fs.readFileSync(pubspecPath, 'utf8');
const pubspecModified = pubspecOriginal
  .replace('assets/inspection_v2/', 'assets/property_inspection/')
  .replace('assets/valuation_v2/', 'assets/property_valuation/');
if (pubspecModified !== pubspecOriginal) {
  fs.writeFileSync(pubspecPath, pubspecModified, 'utf8');
  console.log('  MODIFIED: pubspec.yaml');
  filesModified++;
}

// Also handle app_database.dart specially - only update non-table imports
// Actually, app_database.dart imports from tables/ which we DON'T rename, so no changes needed there.
// But it does reference 'inspection_v2_screens' as a string in migrations - those should stay.

console.log(`\n  Total: ${filesModified} files modified, ~${totalReplacements} replacements\n`);

// ── STEP 2: Physical file renames ──

console.log('=== STEP 2: Physical File Renames ===\n');

const fileRenames = [
  // property_inspection/
  ['lib/features/property_inspection/data/inspection_v2_repository.dart', 'inspection_repository.dart'],
  ['lib/features/property_inspection/domain/inspection_v2_phrase_engine.dart', 'inspection_phrase_engine.dart'],
  ['lib/features/property_inspection/domain/models/inspection_v2_models.dart', 'inspection_models.dart'],
  ['lib/features/property_inspection/presentation/pages/inspection_v2_compass_page.dart', 'inspection_compass_page.dart'],
  ['lib/features/property_inspection/presentation/pages/inspection_v2_overview_page.dart', 'inspection_overview_page.dart'],
  ['lib/features/property_inspection/presentation/pages/inspection_v2_screen_page.dart', 'inspection_screen_page.dart'],
  ['lib/features/property_inspection/presentation/pages/inspection_v2_section_page.dart', 'inspection_section_page.dart'],
  ['lib/features/property_inspection/presentation/providers/inspection_v2_providers.dart', 'inspection_providers.dart'],
  ['lib/features/property_inspection/presentation/widgets/inspection_v2_fields.dart', 'inspection_fields.dart'],

  // property_valuation/
  ['lib/features/property_valuation/data/valuation_v2_repository.dart', 'valuation_repository.dart'],
  ['lib/features/property_valuation/domain/valuation_v2_phrase_engine.dart', 'valuation_phrase_engine.dart'],
  ['lib/features/property_valuation/presentation/pages/valuation_v2_overview_page.dart', 'valuation_overview_page.dart'],
  ['lib/features/property_valuation/presentation/pages/valuation_v2_screen_page.dart', 'valuation_screen_page.dart'],
  ['lib/features/property_valuation/presentation/pages/valuation_v2_section_page.dart', 'valuation_section_page.dart'],
  ['lib/features/property_valuation/presentation/providers/valuation_v2_providers.dart', 'valuation_providers.dart'],

  // report_export/
  ['lib/features/report_export/data/services/v2_docx_generator_service.dart', 'docx_generator_service.dart'],
  ['lib/features/report_export/data/services/v2_export_service.dart', 'export_service.dart'],
  ['lib/features/report_export/data/services/v2_pdf_generator_service.dart', 'pdf_generator_service.dart'],
  ['lib/features/report_export/data/services/v2_report_builder.dart', 'report_builder.dart'],
  ['lib/features/report_export/data/services/v2_report_data_service.dart', 'report_data_service.dart'],
  ['lib/features/report_export/domain/models/v2_report_document.dart', 'report_document.dart'],
  ['lib/features/report_export/presentation/providers/v2_export_providers.dart', 'export_providers.dart'],
  ['lib/features/report_export/presentation/widgets/v2_export_bottom_sheet.dart', 'export_bottom_sheet.dart'],
  ['lib/features/report_export/presentation/widgets/v2_export_dialog.dart', 'export_dialog.dart'],

  // admin/
  ['lib/features/admin/data/v2_admin_repository.dart', 'tree_admin_repository.dart'],
  ['lib/features/admin/presentation/pages/v2_tree_browser_page.dart', 'tree_browser_page.dart'],
  ['lib/features/admin/presentation/providers/v2_admin_providers.dart', 'tree_admin_providers.dart'],

  // ai/
  ['lib/features/ai/data/services/ai_v2_data_formatter.dart', 'ai_data_formatter.dart'],
  ['lib/features/ai/domain/services/ai_v2_client.dart', 'ai_client.dart'],
  ['lib/features/ai/presentation/providers/ai_v2_providers.dart', 'ai_inspection_providers.dart'],
  ['lib/features/ai/presentation/widgets/ai_v2_consistency_sheet.dart', 'ai_consistency_sheet.dart'],
  ['lib/features/ai/presentation/widgets/ai_v2_risk_sheet.dart', 'ai_risk_sheet.dart'],

  // assets
  ['assets/property_inspection/inspection_v2_tree.json', 'inspection_tree.json'],
  ['assets/property_inspection/inspection_v2_tree.json.backup', 'inspection_tree.json.backup'],
  ['assets/property_inspection/inspection_v2_tree.manual_gap_backup', 'inspection_tree.manual_gap_backup'],
  ['assets/property_inspection/inspection_v2_tree_backup_pre_parity.json', 'inspection_tree_backup_pre_parity.json'],
  ['assets/property_valuation/valuation_v2_tree.json', 'valuation_tree.json'],

  // test files
  ['test/features/report_export/domain/models/v2_report_document_test.dart', 'report_document_test.dart'],
  ['test/features/ai/presentation/providers/ai_v2_providers_test.dart', 'ai_inspection_providers_test.dart'],
];

let filesRenamed = 0;
for (const [oldRelPath, newName] of fileRenames) {
  const oldFullPath = path.join(ROOT, oldRelPath);
  if (!fs.existsSync(oldFullPath)) {
    console.log(`  SKIP (not found): ${oldRelPath}`);
    continue;
  }
  const dir = path.dirname(oldFullPath);
  const newFullPath = path.join(dir, newName);
  fs.renameSync(oldFullPath, newFullPath);
  console.log(`  RENAMED: ${path.basename(oldRelPath)} → ${newName}`);
  filesRenamed++;
}

console.log(`\n  Total: ${filesRenamed} files renamed\n`);

// ── STEP 3: Verify no remaining old references (excluding database) ──

console.log('=== STEP 3: Quick Verification ===\n');

const checkPatterns = [
  'inspection_v2', 'valuation_v2', 'InspectionV2', 'ValuationV2',
  'V2Report', 'V2Export', 'V2Pdf', 'V2Docx', 'V2Admin',
  'AiV2', 'aiV2', 'v2_report', 'v2_export', 'v2_admin', 'ai_v2',
  'inspectionV2', 'valuationV2',
];

let issues = 0;
for (const filePath of dartFiles) {
  if (shouldExclude(filePath)) continue;
  // Skip if file was renamed (no longer exists at old path)
  if (!fs.existsSync(filePath)) continue;

  const content = fs.readFileSync(filePath, 'utf8');
  for (const pattern of checkPatterns) {
    if (content.includes(pattern)) {
      console.log(`  WARNING: ${path.relative(ROOT, filePath)} still contains "${pattern}"`);
      issues++;
      break; // One warning per file
    }
  }
}

if (issues === 0) {
  console.log('  All clean! No remaining V2 references in code.\n');
} else {
  console.log(`\n  ${issues} files still have V2 references (may need manual review)\n`);
}

console.log('Phase 2 rename script complete.');
