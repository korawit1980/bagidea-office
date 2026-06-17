# scripts/dev-windowed.ps1
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$GodotProject = Join-Path $Root "godot"
$GodotExe = $null

$Candidates = @()
if ($env:BAGIDEA_GODOT) { $Candidates += $env:BAGIDEA_GODOT }
$Candidates += @(
  "godot",
  "godot.exe",
  "D:\Software\Dev\Godot_v4.6.3-stable_win64.exe",
  "E:\Tools\Godot\Godot_v4.6.3-stable_win64.exe",
  "C:\Program Files\Godot\Godot.exe",
  "C:\Program Files\Godot\godot.exe",
  (Join-Path $Root "Godot_v4.6.3-stable_win64.exe"),
  (Join-Path $Root "godot.exe")
)

foreach ($Candidate in $Candidates) {
  if (-not $Candidate) { continue }
  if (Test-Path -LiteralPath $Candidate -PathType Leaf) {
    $GodotExe = (Resolve-Path -LiteralPath $Candidate).Path
    break
  }

  if (Test-Path -LiteralPath $Candidate -PathType Container) {
    $NestedExe = Get-ChildItem -LiteralPath $Candidate -File -Filter "Godot*_win64.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $NestedExe) {
      $NestedExe = Get-ChildItem -LiteralPath $Candidate -File -Filter "Godot*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    }
    if ($NestedExe) {
      $GodotExe = $NestedExe.FullName
      break
    }
    continue
  }

  $Command = Get-Command $Candidate -CommandType Application -ErrorAction SilentlyContinue
  if ($Command -and (Test-Path -LiteralPath $Command.Source -PathType Leaf)) {
    $GodotExe = $Command.Source
    break
  }
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
