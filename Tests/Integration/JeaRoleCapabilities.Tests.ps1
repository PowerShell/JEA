Using Module ..\..\JeaDsc.psd1

Describe "Integration testing JeaRoleCapabilities" -Tag Integration {

    BeforeAll {
        $Env:PSModulePath += ';TestDrive:\'
    }

    BeforeEach {
        $class = [JeaRoleCapabilities]::New()
        $class.Path = 'TestDrive:\ModuleFolder\RoleCapabilities\ExampleRole.psrc'
    }

    Context "Testing Set method" {

        It "Should remove the role capabilities file when Ensure is set to Absent" {
            New-Item -Path 'TestDrive:\RemoveMe\RoleCapabilities\ExampleRole.psrc' -Force

            $class.Ensure = [Ensure]::Absent
            $class.Path = 'TestDrive:\RemoveMe\RoleCapabilities\ExampleRole.psrc'
            $class.Set()

            Test-Path -Path 'TestDrive:\RemoveMe\RoleCapabilities\ExampleRole.psrc' | Should -Be $false

        }

        It "Should create a new RoleCapbailities folder and populate with a psrc file with 1 visible function when Ensure is set to Present" {
            $class.VisibleFunctions = 'Get-Service'
            $class.Set()

            Test-Path -Path $class.Path | Should -Be $true
            $result = Import-PowerShellDataFile -Path $class.Path
            $result.VisibleFunctions | Should -Be 'Get-Service'
        }

        It "Should create a new psrc with 1 visible function and all Get cmdlets visible when Ensure is set to Present" {
            $class.VisibleCmdlets = 'Get-*'
            $class.VisibleFunctions = 'New-Example'
            $class.Set()

            Test-Path -Path $class.Path | Should -Be $true
            $result = Import-PowerShellDataFile -Path $class.Path
            $result.VisibleFunctions | Should -Be 'New-Example'
            $result.VisibleCmdlets | Should -Be 'Get-*'
        }

        It "Should create a new psrc with 1 visible function and all cmdlets in DnsServer module and Restart-Service visible when Ensure is set to Present" {
            $class.VisibleCmdlets = 'DnsServer\*', "@{'Name' = 'Restart-Service';'Parameters' = @{'Name' = 'Name';'ValidateSet' = 'Dns' } }"
            $class.VisibleFunctions = 'New-Example'
            $class.Set()

            Test-Path -Path $class.Path | Should -Be $true
            $result = Import-PowerShellDataFile -Path $class.Path
            $result.VisibleFunctions | Should -Be 'New-Example'
            $result.VisibleCmdlets[0] | Should -Be 'DnsServer\*'
            $result.VisibleCmdlets[1] | Should -BeOfType [Hashtable]
            $result.VisibleCmdlets[1].Name | Should -Be 'Restart-Service'
            $result.VisibleCmdlets[1].Parameters.Name | Should -Be 'Name'
            $result.VisibleCmdlets[1].Parameters.ValidateSet | Should -Be 'Dns'
        }
    }

}
