<#
.SYNOPSIS
  Installs the Rockfield-pinned TacticalRMM MCP server for Claude Code (Windows, PowerShell 7).

.DESCRIPTION
  1. Installs Node.js LTS through winget if it's missing (approve the UAC prompt).
  2. Asks for your personal claude-readonly API key, masked, and stores it in your Windows user environment.
  3. Downloads the pinned release, checks its SHA-256 and installs it to %LOCALAPPDATA%\Rockfield\mcp\tacticalrmm.
  4. Registers "tacticalrmm" in ~/.claude.json (user scope), after backing the file up.
  Fully quit and reopen the Claude app afterwards.

.PARAMETER SkipKey
  Keep the TACTICALRMM_API_KEY that is already set.
#>
param([switch]$SkipKey)
$ErrorActionPreference = 'Stop'

$Version = '0.1.0-rf.1'
$Url     = "https://github.com/RockfieldIT/tacticalrmm-mcp-server/releases/download/v$Version/nightsquawktech-tacticalrmm-mcp-server-$Version.tgz"
$Sha256  = '5E8E21954BCF34654C3125653F581304D65697EA9E99A86D3BB70EF5D767F14B'
$BaseUrl = 'https://api.rockfieldit.com'
$Dir     = Join-Path $env:LOCALAPPDATA 'Rockfield\mcp\tacticalrmm'

function Update-SessionPath {
  $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}

# 1. Node.js
Update-SessionPath
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  Write-Host 'Installing Node.js LTS (approve the UAC prompt)...'
  winget install --id OpenJS.NodeJS.LTS --exact --silent --accept-package-agreements --accept-source-agreements
  Update-SessionPath
}
$Node = (Get-Command node).Source
Write-Host "Node $(node --version)"

# 2. API key
if (-not $SkipKey -or -not [Environment]::GetEnvironmentVariable('TACTICALRMM_API_KEY', 'User')) {
  $key = Read-Host 'Your personal claude-readonly TRMM API key' -MaskInput
  if (-not $key) { throw 'No API key entered.' }
  [Environment]::SetEnvironmentVariable('TACTICALRMM_API_KEY', $key.Trim(), 'User')
}
$key = [Environment]::GetEnvironmentVariable('TACTICALRMM_API_KEY', 'User')
try {
  $count = (Invoke-RestMethod "$BaseUrl/clients/" -Headers @{ 'X-API-KEY' = $key }).Count
  Write-Host "API key OK: $count clients visible."
} catch {
  throw "TRMM rejected the API key or could not be reached: $($_.Exception.Message)"
}

# 3. Download, verify, install
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("trmm-mcp-" + [guid]::NewGuid())
New-Item -ItemType Directory $tmp | Out-Null
$tgz = Join-Path $tmp 'pkg.tgz'
Invoke-WebRequest $Url -OutFile $tgz
if ((Get-FileHash $tgz).Hash -ne $Sha256) { throw 'SHA-256 mismatch on the downloaded release. Not installing.' }

if (Test-Path $Dir) { Remove-Item $Dir -Recurse -Force }
New-Item -ItemType Directory -Force $Dir | Out-Null
tar -xzf $tgz -C $tmp
Copy-Item (Join-Path $tmp 'package\*') $Dir -Recurse -Force
Remove-Item $tmp -Recurse -Force
$Entry = Join-Path $Dir 'dist\index.js'
if (-not (Test-Path $Entry)) { throw "Install failed: $Entry missing." }

# 4. Register with Claude Code (user scope)
$cfg = Join-Path $HOME '.claude.json'
if (Test-Path $cfg) { Copy-Item $cfg "$cfg.bak-$(Get-Date -Format yyyyMMdd-HHmmss)" }
$js = @'
const fs = require('fs');
const [p, node, entry, base] = process.argv.slice(1);
const j = fs.existsSync(p) ? JSON.parse(fs.readFileSync(p, 'utf8')) : {};
j.mcpServers = j.mcpServers || {};
j.mcpServers.tacticalrmm = { type: 'stdio', command: node, args: [entry],
  env: { TACTICALRMM_BASE_URL: base, TACTICALRMM_TIMEOUT_MS: '30000' } };
fs.writeFileSync(p, JSON.stringify(j, null, 2));
'@
& $Node -e $js $cfg $Node $Entry $BaseUrl

Write-Host "`nInstalled tacticalrmm MCP $Version. Fully quit and reopen the Claude app, then ask Claude to list TRMM clients."
