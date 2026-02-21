/**
 * Verify Parity: Re-run comparison after patching
 *
 * Extracts V2 spec from the patched tree, re-runs comparison,
 * and reports on remaining discrepancies.
 *
 * Pass criteria: Zero auto-fixable discrepancies remain.
 */
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const REPORT_PATH = path.join(__dirname, 'discrepancy-report.json');
const VERIFICATION_PATH = path.join(__dirname, 'verification-report.json');
const VERIFICATION_MD_PATH = path.join(__dirname, 'verification-report.md');

function main() {
  console.log('=== Verification Pipeline ===\n');

  // Step 1: Re-extract V2 spec from patched tree
  console.log('Step 1: Re-extracting V2 spec...');
  execSync('node ' + path.join(__dirname, 'extract-v2-spec.js'), { stdio: 'pipe' });
  console.log('  Done.\n');

  // Step 2: Re-run comparison
  console.log('Step 2: Re-running comparison...');
  execSync('node ' + path.join(__dirname, 'compare-parity.js'), { stdio: 'pipe' });
  console.log('  Done.\n');

  // Step 3: Load the new report and compare with expectations
  const report = JSON.parse(fs.readFileSync(REPORT_PATH, 'utf-8'));

  const autoFixable = report.summary.autoFixable;
  const totalDiscrepancies = report.summary.totalDiscrepancies;
  const manualReview = report.summary.manualReview;

  console.log('=== Verification Results ===\n');
  console.log(`Total discrepancies: ${totalDiscrepancies}`);
  console.log(`Auto-fixable remaining: ${autoFixable}`);
  console.log(`Manual review items: ${manualReview}`);
  console.log('');

  // Check pass criteria
  if (autoFixable === 0) {
    console.log('PASS: Zero auto-fixable discrepancies remain.');
  } else {
    console.log(`FAIL: ${autoFixable} auto-fixable discrepancies still remain.`);

    // Show remaining auto-fixable items
    console.log('\nRemaining auto-fixable items:');
    for (const screenReport of report.discrepancies) {
      const autoFix = screenReport.discrepancies.filter(d => d.autoFixable);
      if (autoFix.length > 0) {
        console.log(`\n  ${screenReport.screenId}:`);
        for (const d of autoFix) {
          console.log(`    [Check ${d.check}] ${d.message}`);
        }
      }
    }
  }

  // Breakdown of remaining discrepancies
  console.log('\n--- Remaining Discrepancy Breakdown ---');
  const checkNames = {
    1: 'Field count mismatch',
    2: 'Field order mismatch',
    3: 'Missing section headings',
    4: 'Label text mismatch',
    5: 'Dropdown option mismatch',
    6: 'Missing/wrong conditionals',
    7: 'Missing/extra field IDs'
  };

  for (let i = 1; i <= 7; i++) {
    const count = report.discrepancies.reduce((sum, d) =>
      sum + d.discrepancies.filter(dd => dd.check === i).length, 0);
    const fixable = report.discrepancies.reduce((sum, d) =>
      sum + d.discrepancies.filter(dd => dd.check === i && dd.autoFixable).length, 0);
    if (count > 0) {
      console.log(`  ${i}. ${checkNames[i]}: ${count} (${fixable} auto-fixable)`);
    }
  }

  // Sections summary
  console.log('\n--- By Section ---');
  const sectionDiscs = {};
  for (const sr of report.discrepancies) {
    const section = sr.v2Section || 'unknown';
    if (!sectionDiscs[section]) sectionDiscs[section] = 0;
    sectionDiscs[section] += sr.discrepancies.length;
  }
  for (const [section, count] of Object.entries(sectionDiscs).sort()) {
    console.log(`  ${section}: ${count}`);
  }

  // Generate verification report
  const verification = {
    timestamp: new Date().toISOString(),
    passed: autoFixable === 0,
    summary: {
      totalDiscrepancies,
      autoFixable,
      manualReview,
      matchedScreens: report.summary.matchedScreens,
      nativeOnlyScreens: report.summary.nativeOnlyScreens,
      v2OnlyScreens: report.summary.v2OnlyScreens
    },
    checkBreakdown: {},
    sectionBreakdown: sectionDiscs
  };

  for (let i = 1; i <= 7; i++) {
    const items = report.discrepancies.flatMap(d => d.discrepancies.filter(dd => dd.check === i));
    verification.checkBreakdown[checkNames[i]] = {
      total: items.length,
      autoFixable: items.filter(d => d.autoFixable).length
    };
  }

  fs.writeFileSync(VERIFICATION_PATH, JSON.stringify(verification, null, 2));

  // Write markdown verification report
  const mdLines = [
    '# Verification Report',
    '',
    `Generated: ${verification.timestamp}`,
    '',
    `## Result: ${verification.passed ? 'PASS' : 'FAIL'}`,
    '',
    '## Summary',
    '',
    `| Metric | Count |`,
    `|--------|-------|`,
    `| Auto-fixable remaining | ${autoFixable} |`,
    `| Manual review items | ${manualReview} |`,
    `| Total remaining | ${totalDiscrepancies} |`,
    '',
    '## Check Breakdown',
    '',
    `| Check | Total | Auto-fixable |`,
    `|-------|-------|-------------|`
  ];

  for (const [name, data] of Object.entries(verification.checkBreakdown)) {
    if (data.total > 0) {
      mdLines.push(`| ${name} | ${data.total} | ${data.autoFixable} |`);
    }
  }

  mdLines.push('');
  mdLines.push('## Manual Review Items by Section');
  mdLines.push('');
  for (const [section, count] of Object.entries(sectionDiscs).sort()) {
    mdLines.push(`- **Section ${section}**: ${count} items`);
  }

  fs.writeFileSync(VERIFICATION_MD_PATH, mdLines.join('\n'));
  console.log(`\nVerification report: ${VERIFICATION_PATH}`);
  console.log(`Verification MD: ${VERIFICATION_MD_PATH}`);
}

main();
