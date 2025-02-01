# chocolateyInstall.ps1
$ErrorActionPreference = 'Stop'

# Retrieve package parameters (sourceFolder and targetFolder must be provided)
if (-not $packageParameters.ContainsKey('sourceFolder') -or -not $packageParameters.ContainsKey('targetFolder')) {
  Write-Error "You must supply both --sourceFolder and --targetFolder as package parameters."
  throw "Missing parameters."
}

$sourceFolder = $packageParameters['sourceFolder']
$targetFolder = $packageParameters['targetFolder']

# Define the installation path for the mirror script
$installPath = "C:\Program Files\MirrorSync"
if (-not (Test-Path $installPath)) {
  New-Item -ItemType Directory -Path $installPath -Force | Out-Null
}

# Copy the MirrorData.ps1 script from the package tools folder to the installation path
$mirrorScriptSource = Join-Path $toolsDir "MirrorData.ps1"
$mirrorScriptDest = Join-Path $installPath "MirrorData.ps1"
Copy-Item $mirrorScriptSource $mirrorScriptDest -Force

Write-Output "MirrorData.ps1 has been installed to $mirrorScriptDest"

# Create the scheduled task that runs the mirror script hourly.
# We use schtasks.exe as it is available on all supported Windows versions.
$taskName = "MirrorSyncTask"
$psExe = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
# Construct the arguments to pass to PowerShell when running the script.
$taskArguments = "-NoProfile -ExecutionPolicy Bypass -File `"$mirrorScriptDest`" -SourceFolder `"$sourceFolder`" -TargetFolder `"$targetFolder`""

# Build the schtasks command.
$cmd = "schtasks /Create /TN `"$taskName`" /TR `"$psExe $taskArguments`" /SC HOURLY /RL HIGHEST /F"

Write-Output "Creating scheduled task with command: $cmd"

try {
  Invoke-Expression $cmd
  Write-Output "Scheduled task '$taskName' created successfully."
} catch {
  Write-Error "Failed to create scheduled task. Error: $_"
  throw $_
}
