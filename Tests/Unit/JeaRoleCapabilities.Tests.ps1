Using Module ..\..\JeaDsc.psd1

InModuleScope JeaRoleCapabilities {
    Describe "Testing JeaRoleCapabilities" {

        BeforeAll {
            Mock -CommandName Import-PowerShellDataFile -MockWith {
                @{
                    Copyright = 'Copyright'
                    GUID = 'GUID'
                    Author = 'Example Author'
                    CompanyName = 'Example Company'
                    VisibleFunctions = @(
                        'Get-Service','Get-Command','Get-Help'
                    )
                    VisibleProviders = @(
                        'Registry','FileSystem'
                    )
                }
            }
            Mock -CommandName New-PSRoleCapabilityFile -MockWith {}
            Mock -CommandName Test-Path -MockWith { $true } -ParameterFilter {
                $Path -eq 'TestDrive:\ModuleFolder\RoleCapabilities\ExampleRole.psrc' -or
                $Path -eq 'C:\ModuleFolder\RoleCapabilities\ExampleRole.psrc'
            }
            Mock -CommandName Test-Path -MockWith { $false }
            Mock -CommandName Write-Error -MockWith {}
            Mock -CommandName New-Item -MockWith {}
            Mock -CommandName Remove-Item -MockWith {}

            $Env:PSModulePath += ";TestDrive:\;C:\ModuleFolder;C:\OtherModule"
        }

        BeforeEach {
            $class = [JeaRoleCapabilities]::New()
            $class.Path = 'C:\ModuleFolder\RoleCapabilities\ExampleRole.psrc'
        }

        Context "Testing ValidatePath method" {

            It "Should return false when the path doesn't end in .psrc" {
                $class.Path = 'C:\Fake\Path\file.txt'

                $class.ValidatePath() | Should -Be $false
            }

            It "Should return false when the path doesn't have RoleCapabilities as the parent folder of the target file" {
                $class.Path = 'C:\Fake\Path\file.psrc'

                $class.ValidatePath() | Should -Be $false
            }

            It "Should return false when the path isn't in the Env:PsModulePath" {
                $class.Path = 'C:\Fake\Path\RoleCapabilities\File.psrc'

                $class.ValidatePath() | Should -Be $false
            }

            It "Should return true when the path is a valid path located in Env:PsModulePath, file has a psrc extension and it's parent folder is called RoleCapabilites" {
                $class.Path = 'C:\Program Files\WindowsPowerShell\Modules\RoleCapabilities\File.psrc'

                $class.ValidatePath() | Should -Be $true
            }
        }

        Context "Testing Get method" {

            It "Should populate class with current state from psrc file" {
                $output = $class.Get()

                $output.Ensure | Should -Be 'Present'
                $output.VisibleFunctions | Should -Be 'Get-Service','Get-Command','Get-Help'
                $output.VisibleProviders | Should -Be 'Registry','FileSystem'
            }

            It "Should not populate class with state if the psrc file is not available" {
                $class.Path = 'TestDrive:\OtherFolder\RoleCapabilities\ExampleRole.psrc'

                $output = $class.Get()

                $output.Ensure | Should -Be 'Absent'
                $output.VisibleFunctions | Should -Not -Be 'Get-Service','Get-Command','Get-Help'
                $output.VisibleProviders | Should -Not -Be 'Registry','FileSystem'

            }
        }

        Context "Testing Test method" {

            It "Should write an error and return false when an invalid path is provided" {
                $class.Path = 'C:\Fake\Path\file.psrc'
                $class.Test() | Should -Be $false
                Assert-MockCalled -CommandName Write-Error -Times 1 -Scope It

            }

            It "Should return false when Ensure is Present and the Path does not exist" {
                $class.Path = 'C:\OtherModule\RoleCapabilities\ExampleRole.psrc'

                $class.Test() | Should -Be $false

            }

            It "Should return false when Ensure is Present, the Path exists but the properties don't match" {
                $class.Test() | Should -Be $false
                Assert-MockCalled -CommandName Write-Error -Times 0 -Scope It
            }

            It "Should return true when Ensure is Present, the Path exists and the properties match" {
                $class.VisibleFunctions = 'Get-Service','Get-Command','Get-Help'
                $class.VisibleProviders = 'Registry','FileSystem'
                $class.Test() | Should -Be $true
                Assert-MockCalled -CommandName Write-Error -Times 0 -Scope It
            }

            It "Should return false when Ensure is Absent and the Path exists" {
                $class.Ensure = [Ensure]::Absent

                $class.Test() | Should -Be $false
            }

            It "Should return True when Ensure is Absent and the Path does not exist" {
                $class.Ensure = [Ensure]::Absent
                $class.Path = 'C:\OtherModule\RoleCapabilities\ExampleRole.psrc'

                $class.Test() | Should -Be $true
            }
        }

        Context "Testing Set method" {

            It "Should remove the role capabilities file when Ensure is set to Absent" {
                $class.Ensure = [Ensure]::Absent
                $class.Set()

                Assert-MockCalled -CommandName Remove-Item -Times 1 -Scope It
            }

            It "Should create a new RoleCapbailities folder and populate with a psrc file with 1 visible function when Ensure is set to Present" {
                $class.VisibleFunctions = 'Get-Service'
                $class.Set()

                Assert-MockCalled -CommandName New-Item -Times 1 -Scope It
                Assert-MockCalled -CommandName New-PSRoleCapabilityFile -Times 1 -Scope 1 -ParameterFilter {
                    $VisibleFunctions -eq 'Get-Service'
                }
            }

            It "Should create a new psrc with 1 visible function and all Get cmdlets visible when Ensure is set to Present" {
                $class.VisibleCmdlets = 'Get-*'
                $class.VisibleFunctions = 'New-Example'
                $class.Set()

                Assert-MockCalled -CommandName New-Item -Times 1 -Scope It
                Assert-MockCalled -CommandName New-PSRoleCapabilityFile -Times 1 -Scope 1 -ParameterFilter {
                    $VisibleFunctions -eq 'New-Example' -and $VisibleCmdlets -eq 'Get-*'
                }
            }
        }
    }
}
