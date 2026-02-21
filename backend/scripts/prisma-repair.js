#!/usr/bin/env node

/**
 * prisma-repair.js
 * Cross-platform script to fix Prisma generate issues (EPERM on Windows)
 *
 * Usage: node scripts/prisma-repair.js
 *   or:  npm run prisma:repair
 */

const { execSync, spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const isWindows = process.platform === 'win32';
const backendDir = path.resolve(__dirname, '..');
const prismaClientDir = path.join(backendDir, 'node_modules', '.prisma', 'client');

console.log('=== Prisma Repair Script ===');
console.log(`Platform: ${process.platform}`);
console.log(`Working directory: ${backendDir}`);

process.chdir(backendDir);

/**
 * Step 1: Clean up temporary files
 */
function cleanupTempFiles() {
  console.log('\n[1/3] Cleaning up temporary files...');

  if (!fs.existsSync(prismaClientDir)) {
    console.log('  Prisma client directory does not exist yet.');
    return;
  }

  try {
    const files = fs.readdirSync(prismaClientDir);
    let cleaned = 0;

    for (const file of files) {
      if (file.includes('.tmp')) {
        const filePath = path.join(prismaClientDir, file);
        try {
          fs.unlinkSync(filePath);
          console.log(`  Removed: ${file}`);
          cleaned++;
        } catch (err) {
          console.log(`  Could not remove ${file}: ${err.message}`);
        }
      }
    }

    if (cleaned === 0) {
      console.log('  No temporary files found.');
    } else {
      console.log(`  Cleaned ${cleaned} temporary file(s).`);
    }
  } catch (err) {
    console.log(`  Error reading directory: ${err.message}`);
  }
}

/**
 * Step 2: Run prisma generate with retry logic
 */
function runPrismaGenerate() {
  console.log('\n[2/3] Running prisma generate...');

  const maxRetries = 3;
  let lastError = null;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    if (attempt > 1) {
      console.log(`  Retry attempt ${attempt} of ${maxRetries}...`);
      // Wait a bit before retry
      const waitMs = 2000;
      const end = Date.now() + waitMs;
      while (Date.now() < end) {
        // Busy wait (sync delay)
      }
    }

    try {
      const result = execSync('npx prisma generate', {
        cwd: backendDir,
        encoding: 'utf-8',
        stdio: ['pipe', 'pipe', 'pipe'],
      });

      console.log('  Prisma generate completed successfully!');
      return true;
    } catch (err) {
      lastError = err;
      const stderr = err.stderr || err.message || '';

      console.log(`  Attempt ${attempt} failed: ${stderr.split('\n')[0]}`);

      // If EPERM error on Windows, try to clear the entire .prisma/client folder
      if (stderr.includes('EPERM') && fs.existsSync(prismaClientDir)) {
        console.log('  Detected EPERM error, removing Prisma client folder...');
        try {
          fs.rmSync(prismaClientDir, { recursive: true, force: true });
          console.log('  Prisma client folder removed.');
        } catch (rmErr) {
          console.log(`  Could not remove folder: ${rmErr.message}`);
        }
      }
    }
  }

  console.error(`\n  ERROR: Prisma generate failed after ${maxRetries} attempts.`);
  console.error('  Please try:');
  console.error('    1. Stop all running Node.js processes');
  console.error('    2. Close your IDE (VS Code, etc.)');
  console.error('    3. Run this script again');

  if (isWindows) {
    console.error('\n  On Windows, you can stop Node processes with:');
    console.error('    taskkill /F /IM node.exe');
  }

  throw new Error('Prisma generate failed');
}

/**
 * Step 3: Verify the generated client
 */
function verifyGeneratedClient() {
  console.log('\n[3/3] Verifying generated client...');

  const indexPath = path.join(prismaClientDir, 'index.d.ts');

  if (!fs.existsSync(indexPath)) {
    throw new Error(`Generated Prisma client not found at: ${indexPath}`);
  }

  const content = fs.readFileSync(indexPath, 'utf-8');

  const checks = [
    { name: 'FieldDefinition with fieldGroup', pattern: 'fieldGroup' },
    { name: 'SectionTypeDefinition model', pattern: 'SectionTypeDefinition' },
    { name: 'FieldType enum', pattern: 'FieldType' },
  ];

  let allPassed = true;

  for (const check of checks) {
    if (content.includes(check.pattern)) {
      console.log(`  [OK] ${check.name}`);
    } else {
      console.log(`  [FAIL] ${check.name}`);
      allPassed = false;
    }
  }

  if (!allPassed) {
    throw new Error('Generated Prisma client is missing expected models/fields!');
  }
}

/**
 * Main execution
 */
async function main() {
  try {
    cleanupTempFiles();
    runPrismaGenerate();
    verifyGeneratedClient();

    console.log('\n=== Prisma repair completed successfully! ===');
    console.log('You may now start the backend server.');
    process.exit(0);
  } catch (err) {
    console.error(`\nFATAL: ${err.message}`);
    process.exit(1);
  }
}

main();
