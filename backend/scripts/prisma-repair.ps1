# prisma-repair.ps1
# Fixes Windows EPERM errors when running prisma generate
# Usage: .\scripts\prisma-repair.ps1

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendDir = Split-Path -Parent $scriptDir

Write-Host "=== Prisma Repair Script ===" -ForegroundColor Cyan
Write-Host "Working directory: $backendDir"

# Change to backend directory
Push-Location $backendDir

try {
    # Step 1: Find and stop any node processes that might be locking Prisma files
    Write-Host "`n[1/4] Checking for processes locking Prisma files..." -ForegroundColor Yellow

    $prismaClientPath = Join-Path $backendDir "node_modules\.prisma\client"
    $queryEnginePath = Join-Path $prismaClientPath "query_engine-windows.dll.node"

    if (Test-Path $queryEnginePath) {
        # Find processes that have the query engine file open
        $lockingProcesses = Get-Process | Where-Object {
            try {
                $_.Modules | Where-Object { $_.FileName -like "*query_engine*" }
            } catch {
                $false
            }
        }

        if ($lockingProcesses) {
            Write-Host "Found processes potentially locking Prisma files:" -ForegroundColor Yellow
            $lockingProcesses | ForEach-Object { Write-Host "  - $($_.ProcessName) (PID: $($_.Id))" }
            Write-Host "Note: These processes may need to be stopped manually if repair fails." -ForegroundColor Yellow
        } else {
            Write-Host "No processes found locking Prisma files." -ForegroundColor Green
        }
    }

    # Step 2: Clean up .tmp files
    Write-Host "`n[2/4] Cleaning up temporary files..." -ForegroundColor Yellow

    if (Test-Path $prismaClientPath) {
        $tmpFiles = Get-ChildItem -Path $prismaClientPath -Filter "*.tmp*" -ErrorAction SilentlyContinue
        if ($tmpFiles) {
            foreach ($tmpFile in $tmpFiles) {
                try {
                    Remove-Item $tmpFile.FullName -Force
                    Write-Host "  Removed: $($tmpFile.Name)" -ForegroundColor Gray
                } catch {
                    Write-Host "  Could not remove: $($tmpFile.Name) - $_" -ForegroundColor Red
                }
            }
        } else {
            Write-Host "  No temporary files found." -ForegroundColor Green
        }
    }

    # Step 3: Run prisma generate with retry logic
    Write-Host "`n[3/4] Running prisma generate..." -ForegroundColor Yellow

    $maxRetries = 3
    $retryCount = 0
    $success = $false

    while (-not $success -and $retryCount -lt $maxRetries) {
        $retryCount++

        if ($retryCount -gt 1) {
            Write-Host "  Retry attempt $retryCount of $maxRetries..." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
        }

        try {
            $output = & npx prisma generate 2>&1
            if ($LASTEXITCODE -eq 0) {
                $success = $true
                Write-Host "  Prisma generate completed successfully!" -ForegroundColor Green
            } else {
                Write-Host "  Prisma generate failed: $output" -ForegroundColor Red

                # If EPERM error, try to clear the cache
                if ($output -match "EPERM") {
                    Write-Host "  Detected EPERM error, clearing Prisma cache..." -ForegroundColor Yellow

                    # Remove the entire .prisma/client folder
                    if (Test-Path $prismaClientPath) {
                        Remove-Item $prismaClientPath -Recurse -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        } catch {
            Write-Host "  Error during prisma generate: $_" -ForegroundColor Red
        }
    }

    if (-not $success) {
        throw "Prisma generate failed after $maxRetries attempts. Please manually stop all Node processes and try again."
    }

    # Step 4: Verify the generated client
    Write-Host "`n[4/4] Verifying generated client..." -ForegroundColor Yellow

    $indexPath = Join-Path $prismaClientPath "index.d.ts"
    if (Test-Path $indexPath) {
        $content = Get-Content $indexPath -Raw

        $checks = @(
            @{ Name = "FieldDefinition with fieldGroup"; Pattern = "fieldGroup" },
            @{ Name = "SectionTypeDefinition model"; Pattern = "SectionTypeDefinition" }
        )

        $allPassed = $true
        foreach ($check in $checks) {
            if ($content -match $check.Pattern) {
                Write-Host "  [OK] $($check.Name)" -ForegroundColor Green
            } else {
                Write-Host "  [FAIL] $($check.Name)" -ForegroundColor Red
                $allPassed = $false
            }
        }

        if (-not $allPassed) {
            throw "Generated Prisma client is missing expected models/fields!"
        }
    } else {
        throw "Generated Prisma client not found at: $indexPath"
    }

    Write-Host "`n=== Prisma repair completed successfully! ===" -ForegroundColor Green
    Write-Host "You may now start the backend server." -ForegroundColor Cyan

} finally {
    Pop-Location
}
