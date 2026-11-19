<#
  Runs the SurveyScriber backend and the browser editor on this PC, for trying the editor and the archive/retention features without a server.
  Needs: Node 20+, and a PostgreSQL 16 database. The easiest database is Docker:

    docker run -d --name ss_local_pg -e POSTGRES_USER=ss -e POSTGRES_PASSWORD=ss_pw -e POSTGRES_DB=ss_local -p 15432:5432 postgres:16-alpine

  Then, from any folder:   powershell -ExecutionPolicy Bypass -File tool\desktop_editor\deploy\run-local.ps1
  Open http://localhost:5174 . Stop with Ctrl+C: both programs are closed.

  Throwaway secrets are made up each run, so nothing here is a real secret and nothing is sent anywhere (no AI key, no e-mail server: notices are written to the backend window).
#>
param(
  [string]$DatabaseUrl = $(if ($env:DATABASE_URL) { $env:DATABASE_URL } else { 'postgresql://ss:ss_pw@127.0.0.1:15432/ss_local?schema=public' }),
  [int]$ApiPort = 3099,
  [switch]$Rebuild,
  [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$backend = Join-Path $repo 'backend'
$editor = Join-Path $repo 'tool\desktop_editor'
$editorPort = 5174   # fixed in vite.config.js

function Step($text) { Write-Host "`n== $text" -ForegroundColor Cyan }
function Hex($n) { -join ((1..$n) | ForEach-Object { '{0:x}' -f (Get-Random -Maximum 16) }) }

Step 'Checking'
node --version | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Node.js is not installed (need version 20 or newer).' }
Write-Host "repo      : $repo"
Write-Host "database  : $($DatabaseUrl -replace '://[^@]*@', '://***@')"
Write-Host "backend   : http://localhost:$ApiPort"
Write-Host "editor    : http://localhost:$editorPort"
if ($DryRun) { Write-Host "`nDry run: nothing was started."; return }

$env:DATABASE_URL = $DatabaseUrl
Push-Location $backend
try {
  Step 'Backend: packages, database tables'
  if (-not (Test-Path 'node_modules')) { npm ci }
  npx prisma generate | Out-Null
  npx prisma migrate deploy
  if ($LASTEXITCODE -ne 0) { throw 'The database could not be reached or migrated. Is PostgreSQL running and DATABASE_URL right?' }
  Step 'Backend: build'
  if ($Rebuild -or -not (Test-Path 'dist\src\main.js')) { npx nest build; if ($LASTEXITCODE -ne 0) { throw 'The backend did not build.' } }
} finally { Pop-Location }

Step 'Editor: build'
Push-Location $editor
try {
  if (-not (Test-Path 'node_modules')) { npm ci }
  if ($Rebuild -or -not (Test-Path 'dist\index.html')) { npm run build; if ($LASTEXITCODE -ne 0) { throw 'The editor did not build.' } }
} finally { Pop-Location }

Step 'Starting'
$access = Hex 64
$envs = @{
  NODE_ENV = 'development'; PORT = "$ApiPort"; DATABASE_URL = $DatabaseUrl
  JWT_SECRET = $access; JWT_ACCESS_SECRET = $access; JWT_REFRESH_SECRET = (Hex 64)
  EDITOR_BASE_URL = "http://localhost:$editorPort"
  MEDIA_LOCAL_ROOT = (Join-Path $repo 'storage-local')
  REPORT_RETENTION_ENABLED = 'true'
}
foreach ($k in $envs.Keys) { Set-Item -Path "Env:$k" -Value $envs[$k] }
$api = Start-Process -FilePath node -ArgumentList 'dist\src\main.js' -WorkingDirectory $backend -PassThru -NoNewWindow
$env:EDITOR_API_TARGET = "http://localhost:$ApiPort"
$web = Start-Process -FilePath cmd -ArgumentList '/c', 'npx vite preview' -WorkingDirectory $editor -PassThru -NoNewWindow
try {
  Write-Host "`nRunning. Open http://localhost:$editorPort (the page a reviewer gets is made in the app: Edit on a computer > Generate link)."
  Write-Host 'Press Ctrl+C to stop.'
  Wait-Process -Id $api.Id
} finally {
  foreach ($p in @($api, $web)) { if ($p -and -not $p.HasExited) { & taskkill /PID $p.Id /T /F | Out-Null } }
}
