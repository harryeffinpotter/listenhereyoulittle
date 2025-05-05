# init.ps1
# Run via iex (Invoke-Expression) to install and configure automatic audio fixing.
param()
$ErrorActionPreference = 'Stop'

# ---------- Paths ----------
$basePath       = Join-Path $env:APPDATA 'listenhereyoulittle'
if (-not (Test-Path $basePath)) {
    New-Item -ItemType Directory -Path $basePath | Out-Null
}
$configPath     = Join-Path $basePath 'defaults.json'
$fixScript      = Join-Path $basePath 'fix.ps1'
$watchScript    = Join-Path $basePath 'watch.ps1'
$killScript     = Join-Path $basePath 'kill-watch.ps1'
$removeScript   = Join-Path $basePath 'remove-task.ps1'
$svvZipUrl      = 'https://www.nirsoft.net/utils/soundvolumeview-x64.zip'
$svvExe         = Join-Path $basePath 'soundvolumeview.exe'

# Start Menu folder for shortcuts
$startMenuProg  = [Environment]::GetFolderPath('Programs')
$smFolder       = Join-Path $startMenuProg 'ListenHereYouLittle'
if (-not (Test-Path $smFolder)) {
    New-Item -ItemType Directory -Path $smFolder | Out-Null
}

# Download and extract SoundVolumeView if not present
if (-not (Test-Path $svvExe)) {
    Write-Host 'Downloading SoundVolumeView...'
    $zip = Join-Path $basePath 'svv.zip'
    Invoke-WebRequest -Uri $svvZipUrl -OutFile $zip -UseBasicParsing
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::ExtractToDirectory($zip, $basePath)
    Remove-Item $zip
}

# ---------- Helpers ----------
function Ask-YesNo($prompt) {
    do { $r = Read-Host "$prompt (y/n)" } while ($r -notmatch '^[yYnN]$')
    return $r -match '^[yY]$'
}

function Select-Device($devices, $type) {
    Write-Host "`nSelect $type device:`n"
    for ($i=0; $i -lt $devices.Count; $i++) {
        $d = $devices[$i]
        Write-Host "[$i] $($d.'Device Name') - $($d.'Command-Line Friendly ID')"
    }
    do {
        $index = Read-Host "Enter index (0-$($devices.Count - 1))"
    } while ($index -notmatch '^[0-9]+$' -or [int]$index -ge $devices.Count)
    return $devices[[int]$index].'Command-Line Friendly ID'
}

# ---------- Gather Preferences ----------
$allDevices     = & "$svvExe" /sjson | ConvertFrom-Json
$outputs        = $allDevices | Where-Object { $_.Direction -eq 'Render'  -and $_.Type -eq 'Device' }
$inputs         = $allDevices | Where-Object { $_.Direction -eq 'Capture' -and $_.Type -eq 'Device' }
$prefOut        = Select-Device $outputs 'output'
$prefIn         = Select-Device $inputs  'input'
$forceComm      = Ask-YesNo 'Also force default communication device?'
$disableCtl     = Ask-YesNo 'Disable Wireless Controller devices?'
$installWatcher = Ask-YesNo 'Install lightweight background watcher (runs every 30s) to auto-fix audio if your preferred device gets disabled?'
$nuclearOption  = Ask-YesNo 'Enable NUCLEAR option: disable ALL audio devices except your selected input/output?'

# Save preferences
@{
    preferred_output            = $prefOut
    preferred_input             = $prefIn
    force_communication         = $forceComm
    disable_wireless_controller = $disableCtl
    install_watcher             = $installWatcher
    nuclear_mode                = $nuclearOption
} | ConvertTo-Json -Depth 3 | Set-Content -Encoding UTF8 $configPath

# ---------- Self-elevation for task creation ----------
function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
if ($installWatcher -and -not (Test-IsAdmin)) {
    Write-Host 'Scheduling your background watcher requires admin rights.'
    Write-Host 'Relaunching elevated…'
    $cmd = "-NoProfile -ExecutionPolicy Bypass -File `"$MyInvocation.MyCommand.Path`""
    Start-Process powershell.exe -Verb RunAs -ArgumentList $cmd
    exit
}

# ---------- Create fix.ps1 (single-shot) ----------
$fixTemplate = @'
param()
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'

$svv    = Join-Path (Split-Path $MyInvocation.MyCommand.Path) 'soundvolumeview.exe'
$config = Get-Content (Join-Path (Split-Path $MyInvocation.MyCommand.Path) 'defaults.json') -Raw | ConvertFrom-Json
$devs   = & $svv /sjson | ConvertFrom-Json

# Disable controllers if requested
if ($config.disable_wireless_controller) {
    Write-Host 'Disabling Wireless Controllers...'
    $devs |
      Where-Object { $_.'Command-Line Friendly ID' -like '*Wireless Controller*' } |
      ForEach-Object {
        Write-Host "-> Disabling $($_.'Command-Line Friendly ID')"
        & $svv /Disable $_.'Command-Line Friendly ID' | Out-Null
      }
}

# NUCLEAR mode: disable all non-preferred devices
if ($config.nuclear_mode) {
    Write-Host 'Applying NUCLEAR mode: disabling all non-preferred devices...'
    $devs |
      Where-Object {
        $_.Type -eq 'Device' -and (
          ($_.Direction -eq 'Render' -and $_.'Command-Line Friendly ID' -ne $config.preferred_output) -or
          ($_.Direction -eq 'Capture' -and $_.'Command-Line Friendly ID' -ne $config.preferred_input)
        )
      } |
      ForEach-Object {
        Write-Host "-> Disabling $($_.'Command-Line Friendly ID')"
        & $svv /Disable $_.'Command-Line Friendly ID' | Out-Null
      }
}

# Gather current defaults
$playDev   = $devs | Where-Object { $_.Direction -eq 'Render'  -and $_.Default }               | Select-Object -First 1
$cplayDev  = $devs | Where-Object { $_.Direction -eq 'Render'  -and $_.'Default Communications' } | Select-Object -First 1
$recDev    = $devs | Where-Object { $_.Direction -eq 'Capture' -and $_.Default }               | Select-Object -First 1
$crecDev   = $devs | Where-Object { $_.Direction -eq 'Capture' -and $_.'Default Communications' } | Select-Object -First 1

$defaults = @{
  Playback      = $playDev.'Command-Line Friendly ID'
  CommPlayback  = $cplayDev.'Command-Line Friendly ID'
  Recording     = $recDev.'Command-Line Friendly ID'
  CommRecording = $crecDev.'Command-Line Friendly ID'
}

foreach ($k in $defaults.Keys) {
  $keybase  = ($k -replace 'Comm','') -replace 'Recording','input' -replace 'Playback','output'
  $expected = $config.("preferred_$keybase")
  Write-Host ("DEBUG {0}: current='{1}', expected='{2}'" -f $k, $defaults[$k], $expected)
}

function Set-IfChanged([string]$path, [int]$flag, [string]$current) {
  if ($path -and $path -ne $current) {
    Write-Host ("Setting {0} (flag {1})" -f $path, $flag)
    & $svv /Enable $path | Out-Null
    & $svv /SetDefault $path $flag | Out-Null
  }
}

Set-IfChanged $config.preferred_output 0 $defaults.Playback
if ($config.force_communication) { Set-IfChanged $config.preferred_output 2 $defaults.CommPlayback }
Set-IfChanged $config.preferred_input 0 $defaults.Recording
if ($config.force_communication) { Set-IfChanged $config.preferred_input 2 $defaults.CommRecording }
'@
$fixTemplate | Set-Content -Encoding UTF8 $fixScript

# ---------- Create watch.ps1 (daemon) ----------
$watchTemplate = @'
param()
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path $MyInvocation.MyCommand.Path
$fixPath   = Join-Path $scriptDir 'fix.ps1'
while ($true) {
    & $fixPath
    Start-Sleep -Seconds 30
}
'@
$watchTemplate | Set-Content -Encoding UTF8 $watchScript

# ---------- Create kill-watch.ps1 (stop only processes) ----------
$killTemplate = @'
param()
# Stop any running watch processes started by the Watch Audio shortcut
Get-Process -Name powershell -ErrorAction SilentlyContinue |
  Where-Object { $_.StartInfo.Arguments -match 'watch\.ps1' } |
  Stop-Process -Force -ErrorAction SilentlyContinue
Write-Host 'Audio watcher processes stopped.'
'@
$killTemplate | Set-Content -Encoding UTF8 $killScript

# ---------- Create remove-task.ps1 (requires elevation) ----------
$removeTemplate = @'
param()
function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
if (-not (Test-IsAdmin)) {
    Write-Host 'Removing scheduled task requires admin rights.'
    Write-Host 'Relaunching elevated…'
    $cmd = "-NoProfile -ExecutionPolicy Bypass -File `"$MyInvocation.MyCommand.Path`""
    Start-Process powershell.exe -Verb RunAs -ArgumentList $cmd
    exit
}
Unregister-ScheduledTask -TaskName 'EnforcePreferredAudio' -Confirm:$false -ErrorAction SilentlyContinue
Write-Host 'Scheduled task.EnforcePreferredAudio removed.'
'@
$removeTemplate | Set-Content -Encoding UTF8 $removeScript

# ---------- Schedule watcher or shortcuts ----------
$taskName = 'EnforcePreferredAudio'
if ($installWatcher) {
    $action   = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$watchScript`""
    $trigger  = New-ScheduledTaskTrigger -AtLogOn
    $settings = New-ScheduledTaskSettingsSet -Hidden
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Set-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings
    } else {
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Force
    }
}

# ---------- Create shortcuts in Start Menu folder ----------
$shell = New-Object -ComObject WScript.Shell

# Fix Audio shortcut
$linkFix = $shell.CreateShortcut((Join-Path $smFolder 'Fix Audio.lnk'))
$linkFix.TargetPath = 'powershell.exe'
$linkFix.Arguments  = "-NoProfile -ExecutionPolicy Bypass -File `"$fixScript`""
$linkFix.Save()

# Watch Audio shortcut (invisible)
$linkWatch = $shell.CreateShortcut((Join-Path $smFolder 'Watch Audio.lnk'))
$linkWatch.TargetPath = 'powershell.exe'
$linkWatch.Arguments  = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$watchScript`""
$linkWatch.Save()

# Kill Watcher shortcut
$linkKill = $shell.CreateShortcut((Join-Path $smFolder 'Kill Watcher.lnk'))
$linkKill.TargetPath = 'powershell.exe'
$linkKill.Arguments  = "-NoProfile -ExecutionPolicy Bypass -File `"$killScript`""
$linkKill.Save()

# Remove Scheduled Task shortcut (only if watcher installed)
if ($installWatcher) {
    $linkRemove = $shell.CreateShortcut((Join-Path $smFolder 'Remove Scheduled Task.lnk'))
    $linkRemove.TargetPath = 'powershell.exe'
    $linkRemove.Arguments  = "-NoProfile -ExecutionPolicy Bypass -File `"$removeScript`""
    $linkRemove.Save()
}

# ---------- Summary ----------
Write-Host "Setup complete. Shortcuts placed in Start Menu > Programs > ListenHereYouLittle"
pause
