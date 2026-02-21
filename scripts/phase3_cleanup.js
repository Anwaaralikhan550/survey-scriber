/**
 * Phase 3: Delete V1 code and update remaining imports.
 *
 * Steps:
 * 1. Update imports referencing extracted files (generated_report, pdf_upload_service)
 * 2. Delete V1 files and directories
 * 3. Update router (remove V1 routes)
 */
const fs = require('fs');
const path = require('path');

const ROOT = 'E:\\s\\scriber\\mobile-app';

// ── STEP 1: Update imports for extracted files ──

console.log('=== STEP 1: Update imports for extracted files ===\n');

const importReplacements = [
  // generated_report.dart moved from pdf_report to report_export
  {
    file: 'lib/core/database/app_database.dart',
    old: "import 'package:survey_scriber/features/pdf_report/domain/entities/generated_report.dart';",
    new: "import 'package:survey_scriber/features/report_export/domain/models/generated_report.dart';",
  },
  // Alternative relative import patterns
  {
    file: 'lib/core/database/daos/generated_reports_dao.dart',
    old: "features/pdf_report/domain/entities/generated_report.dart",
    new: "features/report_export/domain/models/generated_report.dart",
  },
  {
    file: 'lib/core/database/database_providers.dart',
    old: "features/pdf_report/domain/entities/generated_report.dart",
    new: "features/report_export/domain/models/generated_report.dart",
  },
  // pdf_upload_service moved from pdf_report to shared/services
  {
    file: 'lib/features/report_export/data/services/export_service.dart',
    old: "pdf_report/data/services/pdf_upload_service.dart",
    new: "../../../../shared/services/pdf_upload_service.dart",
  },
];

for (const r of importReplacements) {
  const filePath = path.join(ROOT, r.file);
  if (!fs.existsSync(filePath)) {
    console.log(`  SKIP (not found): ${r.file}`);
    continue;
  }
  const content = fs.readFileSync(filePath, 'utf8');
  if (content.includes(r.old)) {
    const updated = content.split(r.old).join(r.new);
    fs.writeFileSync(filePath, updated, 'utf8');
    console.log(`  UPDATED: ${r.file}`);
  } else {
    console.log(`  NO MATCH: ${r.file} (pattern: ${r.old.substring(0, 50)}...)`);
  }
}

// ── STEP 2: Delete V1 files ──

console.log('\n=== STEP 2: Delete V1 files ===\n');

// Individual V1 files to delete
const filesToDelete = [
  // V1 pages
  'lib/features/surveys/presentation/pages/section_form_page.dart',
  'lib/features/surveys/presentation/pages/inspection_review_page.dart',
  'lib/features/surveys/presentation/pages/find_inspection_page.dart',
  // V1 providers
  'lib/features/surveys/presentation/providers/section_form_provider.dart',
  'lib/features/surveys/presentation/providers/valuation_linking_provider.dart',
  'lib/features/surveys/presentation/providers/property_summary_provider.dart',
  // V1 models
  'lib/features/surveys/domain/models/inspection_item.dart',
  'lib/features/surveys/domain/models/issue_data.dart',
  'lib/features/surveys/domain/models/room_schedule_data.dart',
  'lib/features/surveys/domain/models/comparable_property_data.dart',
  'lib/features/surveys/domain/models/valuation_adjustment_data.dart',
  'lib/features/surveys/domain/models/final_valuation_data.dart',
  // V1 PDF tests
  'test/features/pdf_report/data/services/pdf_generator_guardrails_test.dart',
];

let deletedCount = 0;
for (const f of filesToDelete) {
  const fullPath = path.join(ROOT, f);
  if (fs.existsSync(fullPath)) {
    fs.unlinkSync(fullPath);
    console.log(`  DELETED: ${f}`);
    deletedCount++;
  } else {
    console.log(`  SKIP (not found): ${f}`);
  }
}

// Delete entire directories
const dirsToDelete = [
  'lib/features/surveys/presentation/widgets',  // 24 V1 widgets
  'lib/features/pdf_report',  // 12 V1 PDF files
];

function deleteDirRecursive(dirPath) {
  if (!fs.existsSync(dirPath)) return 0;
  let count = 0;
  const entries = fs.readdirSync(dirPath, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dirPath, entry.name);
    if (entry.isDirectory()) {
      count += deleteDirRecursive(fullPath);
      fs.rmdirSync(fullPath);
    } else {
      fs.unlinkSync(fullPath);
      count++;
    }
  }
  return count;
}

for (const d of dirsToDelete) {
  const fullPath = path.join(ROOT, d);
  if (fs.existsSync(fullPath)) {
    const count = deleteDirRecursive(fullPath);
    fs.rmdirSync(fullPath);
    console.log(`  DELETED DIR: ${d} (${count} files)`);
    deletedCount += count;
  } else {
    console.log(`  SKIP DIR (not found): ${d}`);
  }
}

console.log(`\n  Total: ${deletedCount} files deleted\n`);

console.log('Phase 3 cleanup complete.');
