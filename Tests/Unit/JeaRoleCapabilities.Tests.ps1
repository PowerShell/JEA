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
    }
}

Describe "Testing Convert-StringToObject" {
    Context "Test string to hashtable conversion" {

        It "Should return a string and a hashtable" {
            $Output = Convert-StringToObject -InputString "'Invoke-Cmdlet1', @{ Name = 'Invoke-Cmdlet2'}"

            $Output[0] | Should -Be 'Invoke-Cmdlet1'
            $Output[1] | Should -BeOfType [Hashtable]
            $Output[1].Name | Should -Be 'Invoke-Cmdlet2'
        }

        It "Should return 2 hashtables with one having a nested hashtable" {
            $Output = Convert-StringToObject -InputString "@{Name = 'Invoke-Cmdlet'; Parameters = @{Name = 'Parameter1';Value = 'Value1'},@{Name = 'Parameter2'; Value = 'Value2'}},@{Name = 'Invoke-Cmdlet2'}"

            $Output.Count | Should -Be 2
            $Output[0] | Should -BeOfType [Hashtable]
            $Output[0].Name | Should -Be 'Invoke-Cmdlet'
            $Output[0].Parameters.GetType().Name | Should -Be 'Object[]'
            $Output[0].Parameters[0] | Should -BeOfType [Hashtable]
            $Output[0].Parameters[1] | Should -BeOfType [Hashtable]
            $Output[0].Parameters[0].Name | Should -Be 'Parameter1'
            $Output[1] | Should -BeOfType [Hashtable]
            $Output[1].Name | Should -Be 'Invoke-Cmdlet2'
        }

        It "Should return a single string when passed only one cmdlet" {
            $Output = Convert-StringToObject -InputString "Invoke-Cmdlet"

            $Output | Should -Be "Invoke-Cmdlet"
        }

        It "Should return a single hashtable when passed only one hashtable" {
            $Output = Convert-StringToObject -InputString "@{Name = 'Invoke-Cmdlet'}"

            $Output | Should -BeOfType [Hashtable]
            $Output.Name | Should -Be 'Invoke-Cmdlet'
        }

        It "Should return 2 strings when passed 2 comma separated strings in a single string" {
            $Output = Convert-StringToObject -InputString "'Invoke-Cmdlet','Invoke-Cmdlet2'"

            $Output | Should -Be 'Invoke-Cmdlet','Invoke-Cmdlet2'
        }

        It "Should not call New-Item when parsing the string input that contains an escaped subexpression" {
            Mock -CommandName New-Item -MockWith {}
            $null = Convert-StringToObject -InputString "`$(New-Item File.txt),'Invoke-Cmdlet'"

            Assert-MockCalled -CommandName New-Item -Times 0 -Scope It
        }

        It "Should return a single hashtable when passed one with multiple nested properties." {
            $Output = Convert-StringToObject -InputString "@{Name = 'Invoke-Cmdlet'; Parameters = @{Name = 'Parameter1';Value = 'Value1'},@{Name = 'Parameter2'; Value = 'Value2'}}"

            $Output | Should -BeOfType [Hashtable]
            $Output.Parameters.GetType().Name | Should -Be 'Object[]'
            $Output.Parameters[0].Name | Should -Be 'Parameter1'
            $Output.Parameters[0].Value | Should -Be 'Value1'
            $Output.Parameters[1].Name | Should -Be 'Parameter2'
            $Output.Parameters[1].Value | Should -Be 'Value2'
        }

        It "Should write an error when not provided with a hashtable, string or combination" {
            {$Output = Convert-StringToObject -InputString "`$(Get-Help)" -ErrorAction Stop} | Should -Throw
        }
    }

}
