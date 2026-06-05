# Project window manager — tmux-style background sessions on Windows.
# Every project terminal is spawned under conhost with a BAGIDEA_PROJ_<id>
# marker baked into its command line. This script can:
#   sweep        -> print "<id> <visible01>" for every live project window
#   hide <id>    -> hide the window (claude keeps running in the background)
#   show <id>    -> bring the hidden window back (resume)
#   stop <id>    -> kill the whole window tree for real
param([string]$Action = "sweep", [string]$Id = "")

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WU {
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
}
"@

function Find-Win([uint32]$ProcId) {
  $script:tgt = $ProcId
  $script:hit = [IntPtr]::Zero
  $cb = [WU+EnumProc]{ param($h, $l)
    $o = [uint32]0
    [void][WU]::GetWindowThreadProcessId($h, [ref]$o)
    if ($o -eq $script:tgt) { $script:hit = $h }
    return $true
  }
  [void][WU]::EnumWindows($cb, [IntPtr]::Zero)
  return $script:hit
}

$procs = Get-CimInstance Win32_Process -Filter "Name='cmd.exe'" |
  Where-Object { $_.CommandLine -match 'BAGIDEA_PROJ_' }

foreach ($p in $procs) {
  if ($p.CommandLine -notmatch 'BAGIDEA_PROJ_([\w-]+)') { continue }
  $projId = $Matches[1]
  # The console HWND belongs to the cmd itself or its conhost parent.
  $h = Find-Win ([uint32]$p.ProcessId)
  if ($h -eq [IntPtr]::Zero -and $p.ParentProcessId) {
    $h = Find-Win ([uint32]$p.ParentProcessId)
  }
  if ($Action -eq "sweep") {
    $vis = 0
    if ($h -ne [IntPtr]::Zero -and [WU]::IsWindowVisible($h)) { $vis = 1 }
    Write-Output "$projId $vis"
  } elseif ($projId -eq $Id) {
    switch ($Action) {
      "hide" { if ($h -ne [IntPtr]::Zero) { [void][WU]::ShowWindow($h, 0) } }
      "show" {
        if ($h -ne [IntPtr]::Zero) {
          [void][WU]::ShowWindow($h, 9)
          [void][WU]::SetForegroundWindow($h)
        }
      }
      "stop" { taskkill /PID $p.ProcessId /T /F | Out-Null }
    }
  }
}
