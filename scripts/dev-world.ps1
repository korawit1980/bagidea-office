# scripts/dev-world.ps1
param()

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$GodotProject = Join-Path $Root "godot"
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

function Resolve-Godot {
  foreach ($Candidate in $Candidates) {
    if (-not $Candidate) { continue }
    if (Test-Path -LiteralPath $Candidate -PathType Leaf) {
      return (Resolve-Path -LiteralPath $Candidate).Path
    }

    if (Test-Path -LiteralPath $Candidate -PathType Container) {
      $NestedExe = Get-ChildItem -LiteralPath $Candidate -File -Filter "Godot*_win64.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
      if (-not $NestedExe) {
        $NestedExe = Get-ChildItem -LiteralPath $Candidate -File -Filter "Godot*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
      }
      if ($NestedExe) { return $NestedExe.FullName }
      continue
    }

    $Command = Get-Command $Candidate -CommandType Application -ErrorAction SilentlyContinue
    if ($Command -and (Test-Path -LiteralPath $Command.Source -PathType Leaf)) {
      return $Command.Source
    }
  }
  throw @"
Godot executable was not found.

Install Godot 4.6+, add it to PATH, or set BAGIDEA_GODOT to the full executable path.

Example:
  `$env:BAGIDEA_GODOT = "D:\Software\Dev\Godot_v4.6.3-stable_win64.exe"
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
