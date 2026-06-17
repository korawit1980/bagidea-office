# scripts/dev-world.ps1
param()

$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$GodotProject = Join-Path $Root "godot"
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

function Resolve-Godot {
  foreach ($Candidate in $Candidates) {
    if (-not $Candidate) { continue }
    $Command = Get-Command $Candidate -ErrorAction SilentlyContinue
    if ($Command) { return $Command.Source }
    if (Test-Path -LiteralPath $Candidate) { return (Resolve-Path -LiteralPath $Candidate).Path }
  }
  throw @"
Godot executable was not found.

Install Godot 4.6+, add it to PATH, or set BAGIDEA_GODOT to the full executable path.

Example:
  `$env:BAGIDEA_GODOT = "E:\Tools\Godot\Godot_v4.6.3-stable_win64.exe"
  npm run dev:world
"@
}

$GodotExe = Resolve-Godot

Write-Host ""
Write-Host "Opening BagIdea Office Godot world in windowed mode" -ForegroundColor Cyan
Write-Host "- Godot: $GodotExe" -ForegroundColor DarkCyan
Write-Host "- Project: $GodotProject" -ForegroundColor DarkCyan
Write-Host ""

& $GodotExe --path $GodotProject
