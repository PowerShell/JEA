$Module = Resolve-Path -Path "$PSScriptRoot\..\..\DSCClassResources\JeaRoleCapabilities\JeaRoleCapabilities.psd1"
Import-Module $module -Force

Describe "Testing JeaRoleCapabilities" {

    InModuleScope JeaRoleCapabilities {
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
                ,$Output[0].Parameters | Should -BeOfType [Array]
                $Output[0].Parameters[0] | Should -BeOfType [Hashtable]
                $Output[0].Parameters[1] | Should -BeOfType [Hashtable]
                $Output[0].Parameters[0].Name | Should -Be 'Parameter1'
                $Output[1] | Should -BeOfType [Hashtable]
                $Output[1].Name | Should -Be 'Invoke-Cmdlet2'
            }

            It "Should return a single string when passed only one cmdlet" {
                $Output = Convert-StringToObject -InputString "'Invoke-Cmdlet'"

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
        }
    }
}
