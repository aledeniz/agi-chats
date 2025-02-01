# MirrorData.ps1
[CmdletBinding()]
param (
  [Parameter(Mandatory=$true)]
  [string]$SourceFolder,
  [Parameter(Mandatory=$true)]
  [string]$TargetFolder
)

# Initialise exit code (0 indicates success)
$exitCode = 0

try {
  Write-Output "MirrorSync started at $(Get-Date)"
  Write-Output "Source: $SourceFolder"
  Write-Output "Target: $TargetFolder"
  
  # Ensure that the log folder exists
  $logFolder = "C:\Logs"
  if (-not (Test-Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
  }
  
  # Define folders to exclude: the ProgramData folder in both the source and the target.
  $excludeFolders = @("$SourceFolder\ProgramData", "$TargetFolder\ProgramData")
  $xdParam = $excludeFolders | ForEach-Object { "`"$_`"" } | -join " "
  
  # Build robocopy options:
  #   /MIR   : Mirror a complete directory tree.
  #   /COPYALL : Copy all file information (data, attributes, timestamps, NTFS security, owner and auditing info).
  #   /MT:16   : Use 16 threads (adjust as needed).
  #   /XD     : Exclude the specified directories.
  #   /R:3 /W:5 : Retry 3 times with a 5 second wait.
  #   /LOG and /TEE : Log output to file and the console.
  $robocopyOptions = "/MIR /COPYALL /MT:16 /XD $xdParam /R:3 /W:5 /LOG:C:\Logs\robocopy.log /TEE"
  
  $command = "robocopy `"$SourceFolder`" `"$TargetFolder`" $robocopyOptions"
  Write-Output "Executing command: $command"
  
  # Execute the robocopy command.
  Invoke-Expression $command
  Write-Output "MirrorSync completed at $(Get-Date)"
} catch {
  Write-Error "An error occurred during mirroring: $_"
  $exitCode = 1
} finally {
  exit $exitCode
}
