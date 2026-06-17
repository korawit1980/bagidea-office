# scripts/codex.ps1
param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]] $CodexArgs
)

$ErrorActionPreference = "Stop"

function Resolve-Codex {
  $Candidates = @()

  if ($env:BAGIDEA_CODEX) { $Candidates += $env:BAGIDEA_CODEX }

  $Candidates += @(
    "codex",
    "codex.exe",
    "codex.cmd",
    (Join-Path $env:APPDATA "npm\codex.cmd"),
    (Join-Path $env:APPDATA "npm\codex.exe")
  )

  $ExtensionRoots = @(
    (Join-Path $env:USERPROFILE ".vscode\extensions"),
    (Join-Path $env:USERPROFILE ".vscode-insiders\extensions")
  )

  foreach ($Root in $ExtensionRoots) {
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) { continue }
    $Candidates += Get-ChildItem -LiteralPath $Root -Directory -Filter "openai.chatgpt-*" -ErrorAction SilentlyContinue |
      Sort-Object Name -Descending |
      ForEach-Object { Join-Path $_.FullName "bin\windows-x86_64\codex.exe" }
  }

  foreach ($Candidate in $Candidates) {
    if (-not $Candidate) { continue }

    if (Test-Path -LiteralPath $Candidate -PathType Leaf) {
      return (Resolve-Path -LiteralPath $Candidate).Path
    }

    $Command = Get-Command $Candidate -CommandType Application -ErrorAction SilentlyContinue
    if ($Command -and (Test-Path -LiteralPath $Command.Source -PathType Leaf)) {
      return $Command.Source
    }
  }

  throw @"
Codex CLI was not found.

Install Codex CLI globally, open this project through the OpenAI/Codex extension, or set BAGIDEA_CODEX to the full executable path.

Examples:
  `$env:BAGIDEA_CODEX = "$env:USERPROFILE\.vscode\extensions\openai.chatgpt-<version>-win32-x64\bin\windows-x86_64\codex.exe"
  npm run codex:login
"@
}

$CodexExe = Resolve-Codex

if (-not $CodexArgs -or $CodexArgs.Count -eq 0) {
  $CodexArgs = @("--help")
}

& $CodexExe @CodexArgs
