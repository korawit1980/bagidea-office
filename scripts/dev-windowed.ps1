# scripts/dev-windowed.ps1
param()

$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$GodotProject = Join-Path $Root "godot"
$GodotExe = $null

$Candidates = @()
if ($env:BAGIDEA_GODOT) { $Candidates += $env:BAGIDEA_GODOT }
$Candidates += @(
  "godot",
  "godot.exe",
  "E:\Tools\Godot\Godot_v4.6.3-stable_win64.exe",
  "C:\Program Files\Godot\Godot.exe",
  "C:\Program Files\Godot\godot.exe",
  (Join-Path $Root "Godot_v4.6.3-stable_win64.exe"),
  (Join-Path $Root "godot.exe")
)

foreach ($Candidate in $Candidates) {
  if (-not $Candidate) { continue }
  $Command = Get-Command $Candidate -ErrorAction SilentlyContinue
  if ($Command) { $GodotExe = $Command.Source; break }
  if (Test-Path -LiteralPath $Candidate) { $GodotExe = (Resolve-Path -LiteralPath $Candidate).Path; break }
}

if (-not $GodotExe) {
  throw "Godot executable was not found. Set BAGIDEA_GODOT to the full Godot executable path."
}

Write-Host ""
Write-Host "BagIdea Office dev windowed mode" -ForegroundColor Cyan
Write-Host "- Daemon: http://127.0.0.1:8787" -ForegroundColor DarkCyan
Write-Host "- Godot: windowed project at $GodotProject" -ForegroundColor DarkCyan
Write-Host "- Stop: Ctrl+C in this terminal" -ForegroundColor DarkCyan
Write-Host ""

$Godot = $null
try {
  $Godot = Start-Process -FilePath $GodotExe -ArgumentList @("--path", $GodotProject) -WorkingDirectory $Root -PassThru
  Push-Location $Root
  try {
    & node "daemon/server.js"
  } finally {
    Pop-Location
  }
} finally {
  if ($Godot -and -not $Godot.HasExited) {
    Write-Host ""
    Write-Host "Stopping Godot window..." -ForegroundColor Yellow
    Stop-Process -Id $Godot.Id -Force -ErrorAction SilentlyContinue
  }
}
