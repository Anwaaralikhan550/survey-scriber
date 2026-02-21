#!/usr/bin/env node

/**
 * kill-port.js
 * Cross-platform script to safely kill processes using a specific port
 *
 * Usage: node scripts/kill-port.js [port]
 *   or:  npm run kill-port
 */

const { execSync } = require('child_process');

const PORT = process.argv[2] || process.env.PORT || 3000;
const isWindows = process.platform === 'win32';

console.log(`Checking for processes using port ${PORT}...`);

function findProcessOnPort() {
  try {
    if (isWindows) {
      // Windows: use netstat to find PID
      const output = execSync(`netstat -ano | findstr ":${PORT}"`, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] });
      const lines = output.trim().split('\n');

      for (const line of lines) {
        if (line.includes('LISTENING')) {
          const parts = line.trim().split(/\s+/);
          const pid = parts[parts.length - 1];
          if (pid && !isNaN(parseInt(pid))) {
            return parseInt(pid);
          }
        }
      }
    } else {
      // Unix/Linux/Mac: use lsof
      const output = execSync(`lsof -i :${PORT} -t`, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] });
      const pid = parseInt(output.trim().split('\n')[0]);
      if (!isNaN(pid)) {
        return pid;
      }
    }
  } catch (err) {
    // No process found on port
    return null;
  }
  return null;
}

function getProcessInfo(pid) {
  try {
    if (isWindows) {
      const output = execSync(`tasklist /FI "PID eq ${pid}" /FO CSV /NH`, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] });
      const parts = output.trim().split(',');
      if (parts.length > 0) {
        return parts[0].replace(/"/g, '');
      }
    } else {
      const output = execSync(`ps -p ${pid} -o comm=`, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] });
      return output.trim();
    }
  } catch (err) {
    return 'unknown';
  }
  return 'unknown';
}

function killProcess(pid) {
  try {
    if (isWindows) {
      execSync(`taskkill /F /PID ${pid}`, { stdio: 'pipe' });
    } else {
      execSync(`kill -9 ${pid}`, { stdio: 'pipe' });
    }
    return true;
  } catch (err) {
    return false;
  }
}

// Main execution
const pid = findProcessOnPort();

if (!pid) {
  console.log(`Port ${PORT} is free. No action needed.`);
  process.exit(0);
}

const processName = getProcessInfo(pid);
console.log(`Found process: ${processName} (PID: ${pid}) using port ${PORT}`);

// Safety check: only kill node processes automatically
const safeProcesses = ['node', 'node.exe'];
const isSafe = safeProcesses.some(p => processName.toLowerCase().includes(p.toLowerCase()));

if (!isSafe) {
  console.log(`WARNING: Process "${processName}" is not a Node.js process.`);
  console.log(`For safety, refusing to kill automatically.`);
  console.log(`Manual kill: ${isWindows ? `taskkill /F /PID ${pid}` : `kill -9 ${pid}`}`);
  process.exit(1);
}

console.log(`Killing ${processName} (PID: ${pid})...`);

if (killProcess(pid)) {
  console.log(`Successfully killed process on port ${PORT}.`);
  process.exit(0);
} else {
  console.error(`Failed to kill process. Try running with administrator/sudo privileges.`);
  process.exit(1);
}
