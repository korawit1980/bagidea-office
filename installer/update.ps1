# BagIdea Office updater. Two modes, auto-detected:
#   • DEV checkout (.git present)  → git pull + rebuild shell if changed
#   • Installed build (no .git)    → re-run install.ps1 with the latest zip
#     (BAGIDEA_RELEASE_URL); user data is preserved by the installer.
# Run via:  bagidea update  |  the in-app 🔄 button  |  directly.
$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host ""
Write-Host "  ===== BagIdea Office — UPDATE =====" -ForegroundColor Cyan

# 1) Stop the running suite (shell + wallpaper + daemon).
Write-Host "  [1/4] หยุดโปรแกรม..." -ForegroundColor DarkCyan
Get-CimInstance Win32_Process | Where-Object {
  ($_.Name -eq "node.exe" -and $_.CommandLine -match "server\.js") -or
  $_.Name -eq "bagidea-office-shell.exe" -or $_.Name -like "Godot*"
} | ForEach-Object { taskkill /PID $_.ProcessId /T /F 2>$null | Out-Null }
Start-Sleep 2

# Installed build (no git): pull a fresh release zip and re-install over it.
if (-not (Test-Path (Join-Path $root ".git"))) {
  $url = $env:BAGIDEA_RELEASE_URL
  if (-not $url) { Write-Host "  ! ไม่พบ BAGIDEA_RELEASE_URL — ตั้งค่า URL ของ release zip ก่อน" -ForegroundColor Yellow; exit 1 }
  Write-Host "  [2/2] อัปเดตจาก release ล่าสุด..." -ForegroundColor DarkCyan
  & (Join-Path $PSScriptRoot "install.ps1") -Zip $url
  exit 0
}

# 2) DEV: pull the latest code.
Write-Host "  [2/4] ดึงโค้ดล่าสุด..." -ForegroundColor DarkCyan
$before = git rev-parse HEAD
git pull --ff-only
$after = git rev-parse HEAD
if ($before -eq $after) { Write-Host "  - เป็นเวอร์ชันล่าสุดอยู่แล้ว" -ForegroundColor DarkGray }

# 3) Rebuild the shell only when its source changed (and cargo exists).
$shellChanged = git diff --name-only $before $after -- shell/ | Measure-Object -Line
if ($shellChanged.Lines -gt 0) {
  $cargo = Get-Command cargo -ErrorAction SilentlyContinue
  if ($cargo) {
    Write-Host "  [3/4] คอมไพล์ shell ใหม่ (โค้ดส่วน shell เปลี่ยน)..." -ForegroundColor DarkCyan
    Push-Location (Join-Path $root "shell")
    cargo build --release
    Pop-Location
  } else {
    Write-Host "  [3/4] ! โค้ด shell เปลี่ยนแต่ไม่มี Rust toolchain - ใช้ exe เดิมไปก่อน" -ForegroundColor Yellow
    Write-Host "        ติดตั้ง:  winget install Rustlang.Rustup  แล้วรัน bagidea update อีกครั้ง" -ForegroundColor Yellow
  }
} else {
  Write-Host "  [3/4] shell ไม่เปลี่ยน - ข้ามการคอมไพล์" -ForegroundColor DarkGray
}

# 4) Relaunch.
Write-Host "  [4/4] เปิดโปรแกรมอีกครั้ง..." -ForegroundColor DarkCyan
$exe = Join-Path $root "shell\target\release\bagidea-office-shell.exe"
if (Test-Path $exe) {
  Start-Process -FilePath $exe -WorkingDirectory (Split-Path $exe)
  Write-Host ""
  Write-Host "  อัปเดตเสร็จแล้ว -> $(git rev-parse --short HEAD)" -ForegroundColor Green
} else {
  Write-Host "  ! ไม่พบ shell exe - รัน cargo build --release ใน shell/ ก่อน" -ForegroundColor Red
}
