$ErrorActionPreference = 'Stop'

function Install-DataDriveMirrorTask {
    [CmdletBinding()]
    param (
        [string]$PackageParameters
    )

    # Parse parameters (assumes parameters come in the form --key=value separated by spaces)
    $mode = 'local'
    $username = $null
    $password = $null
    $gmsaAccount = $null

    if ($PackageParameters) {
        $params = $PackageParameters -split '\s+' | ForEach-Object {
            if ($_ -match '^--([^=]+)=(.+)$') {
                @{ Name = $matches[1].ToLower(); Value = $matches[2] }
            }
        } | Where-Object { $_ }

        foreach ($param in $params) {
            switch ($param.Name) {
                'mode'     { $mode = $param.Value.ToLower() }
                'username' { $username = $param.Value }
                'password' { $password = $param.Value }
                'gmsa'     { $gmsaAccount = $param.Value }
            }
        }
    }

    # Define the scheduled task name.
    $taskName = "RobocopyTask"

    # Define the robocopy command and its arguments.
    # This is a mock call; adjust the source, destination and parameters as needed.
    $robocopyExe  = "robocopy.exe"
    $robocopyArgs = "C:\source \\destination\dest /MIR"

    # Create the scheduled task action.
    $action = New-ScheduledTaskAction -Execute $robocopyExe -Argument $robocopyArgs

    # Create a daily trigger that fires at 02:00 AM.
    $trigger = New-ScheduledTaskTrigger -Daily -At "02:00"

    switch ($mode) {
        'explicit' {
            if (-not $username -or -not $password) {
                throw "For 'explicit' mode you must provide both --username and --password parameters."
            }
            # Create a PSCredential object (not used directly by Register-ScheduledTask, but shown for illustration).
            $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
            $credential = New-Object System.Management.Automation.PSCredential($username, $securePassword)

            # Create the scheduled task using explicit credentials.
            Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -User $username -Password $password -RunLevel Highest
            Write-Output "Scheduled task '$taskName' has been created to run as $username (explicit credentials)."
        }
        'local' {
            # In local mode, the scheduled task runs under the current user's context.
            Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -RunLevel Highest
            Write-Output "Scheduled task '$taskName' has been created to run under the current local user account."
        }
        'gmsa' {
            if (-not $gmsaAccount) {
                throw "For 'gmsa' mode you must provide the --gmsa parameter (e.g. DOMAIN\gMSAName$)."
            }
            # Create the scheduled task using the gMSA account. No password is needed.
            Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -User $gmsaAccount -RunLevel Highest
            Write-Output "Scheduled task '$taskName' has been created to run with the gMSA account $gmsaAccount."
        }
        default {
            throw "Unknown mode '$mode'. Allowed values are 'explicit', 'local', or 'gmsa'."
        }
    }

    Write-Output "Deployment complete."
}

# In a Chocolatey package the parameters are passed in the environment variable.
$packageParams = $env:chocolateyPackageParameters
Install-DataDriveMirrorTask -PackageParameters $packageParams
