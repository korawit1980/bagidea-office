# scripts/dev-windowed.ps1
param()

$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$GodotProject = Join-Path $Root "godot"
$GodotExe = if ($env:BAGIDEA_GODOT) { $env:BAGIDEA_GODOT } else { "godot" }

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
