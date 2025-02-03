# Load Pester (ensure you have Pester installed)

Describe 'Install-DataDriveMirrorTask' {

    # Import the script to test (dot-source it)
    BeforeAll {
        # Adjust the path as necessary to locate the chocolateyInstall.ps1 file.
        $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\configure-data-drive-mirror\tools\chocolateyInstall.ps1"
        . $scriptPath
    }

    # Mock the New-ScheduledTaskAction and New-ScheduledTaskTrigger commands to return dummy objects.
    BeforeEach {
        Mock -CommandName New-ScheduledTaskAction -MockWith { return @{ Action = 'DummyAction' } }
        Mock -CommandName New-ScheduledTaskTrigger -MockWith { return @{ Trigger = 'DummyTrigger' } }
        # Mock the Register-ScheduledTask to record parameters.
        Mock -CommandName Register-ScheduledTask
    }

    Context 'when mode is explicit' {
        It 'should call Register-ScheduledTask with username and password' {
            $env:chocolateyPackageParameters = "--mode=explicit --username=TESTDOMAIN\testuser --password=TestPassword123"
            # Call the function. Since the function writes output, we capture it.
            $output = Install-DataDriveMirrorTask -PackageParameters $env:chocolateyPackageParameters

            # Assert that Register-ScheduledTask was called once with the correct parameters.
            Assert-MockCalled -CommandName Register-ScheduledTask -Times 1 -ParameterFilter {
                $TaskName -eq 'RobocopyTask' -and
                $User -eq 'TESTDOMAIN\testuser' -and
                $Password -eq 'TestPassword123'
            }
            $output | Should -Match 'explicit credentials'
        }
    }

    Context 'when mode is local' {
        It 'should call Register-ScheduledTask without -User or -Password' {
            $env:chocolateyPackageParameters = "--mode=local"
            $output = Install-DataDriveMirrorTask -PackageParameters $env:chocolateyPackageParameters

            Assert-MockCalled -CommandName Register-ScheduledTask -Times 1 -ParameterFilter {
                ($PSBoundParameters.ContainsKey('User') -eq $false) -and
                ($PSBoundParameters.ContainsKey('Password') -eq $false)
            }
            $output | Should -Match 'current local user'
        }
    }

    Context 'when mode is gmsa' {
        It 'should call Register-ScheduledTask with gMSA account and no password' {
            $env:chocolateyPackageParameters = "--mode=gmsa --gmsa=DOMAIN\gMSAName$"
            $output = Install-DataDriveMirrorTask -PackageParameters $env:chocolateyPackageParameters

            Assert-MockCalled -CommandName Register-ScheduledTask -Times 1 -ParameterFilter {
                $TaskName -eq 'RobocopyTask' -and
                $User -eq 'DOMAIN\gMSAName$' -and
                ($PSBoundParameters.ContainsKey('Password') -eq $false)
            }
            $output | Should -Match 'gMSA account DOMAIN\gMSAName\$'
        }
    }

    Context 'when invalid mode is provided' {
        It 'should throw an error for an unknown mode' {
            $env:chocolateyPackageParameters = "--mode=unknown"
            { Install-DataDriveMirrorTask -PackageParameters $env:chocolateyPackageParameters } | Should -Throw "Unknown mode"
        }
    }

    Context 'when explicit mode is missing credentials' {
        It 'should throw an error if username or password is missing' {
            $env:chocolateyPackageParameters = "--mode=explicit --username=TESTDOMAIN\testuser"
            { Install-DataDriveMirrorTask -PackageParameters $env:chocolateyPackageParameters } | Should -Throw "must provide both --username and --password"
        }
    }

    Context 'when gmsa mode is missing the gmsa parameter' {
        It 'should throw an error if --gmsa is missing' {
            $env:chocolateyPackageParameters = "--mode=gmsa"
            { Install-DataDriveMirrorTask -PackageParameters $env:chocolateyPackageParameters } | Should -Throw "must provide the --gmsa parameter"
        }
    }
}
