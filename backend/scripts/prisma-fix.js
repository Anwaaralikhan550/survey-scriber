const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const PRISMA_CLIENT_PATH = path.join(__dirname, '../node_modules/.prisma/client');
const QUERY_ENGINE_REGEX = /query_engine-windows\.dll\.node/;

/**
 * Robust Prisma Generate Script for Windows
 * Handles EPERM errors by attempting to release file locks or retrying.
 */
async function main() {
  console.log('🚀 Starting robust Prisma generation...');

  try {
    // 1. Try standard generation
    execSync('npx prisma generate', { stdio: 'inherit' });
    console.log('✅ Prisma generation successful!');
  } catch (error) {
    console.warn('⚠️ Standard generation failed. Detecting EPERM/locking issues...');
    
    // 2. Check for locked files
    if (process.platform === 'win32') {
      try {
        console.log('🔄 Attempting to clean up locked files...');
        cleanupLockedFiles();
        
        console.log('🔄 Retrying generation in 2 seconds...');
        await new Promise(r => setTimeout(r, 2000));
        
        execSync('npx prisma generate', { stdio: 'inherit' });
        console.log('✅ Retry successful!');
      } catch (retryError) {
        console.error('❌ Retry failed. You may need to stop the running server manually.');
        console.error('Tip: If "nest start" is running, stop it and try again.');
        process.exit(1);
      }
    } else {
      console.error('❌ Generation failed:', error.message);
      process.exit(1);
    }
  }
}

function cleanupLockedFiles() {
  if (!fs.existsSync(PRISMA_CLIENT_PATH)) return;

  const files = fs.readdirSync(PRISMA_CLIENT_PATH);
  for (const file of files) {
    if (QUERY_ENGINE_REGEX.test(file)) {
      const fullPath = path.join(PRISMA_CLIENT_PATH, file);
      try {
        // Try to rename to .trash to move it out of the way (often works when delete fails)
        const trashPath = fullPath + '.trash.' + Date.now();
        fs.renameSync(fullPath, trashPath);
        // Try to delete the trash (if fails, it's fine, OS will clean up or ignore)
        try { fs.unlinkSync(trashPath); } catch (e) {} 
        console.log(`   - Moved locked file: ${file}`);
      } catch (e) {
        console.warn(`   - Could not move locked file: ${file} (Process likely holding it)`);
      }
    }
  }
}

main();
