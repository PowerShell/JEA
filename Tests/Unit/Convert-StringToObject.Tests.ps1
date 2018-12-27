Using Module ..\..\JeaDsc.psd1

Describe "Testing Convert-StringToObject" {
    Context "Test string to hashtable conversion" {

        It "Should return a string and a hashtable when passed as a single string" {
            $Output = Convert-StringToObject -InputString "'Invoke-Cmdlet1', @{ Name = 'Invoke-Cmdlet2'}"

            $Output[0] | Should -Be 'Invoke-Cmdlet1'
            $Output[1] | Should -BeOfType [Hashtable]
            $Output[1].Name | Should -Be 'Invoke-Cmdlet2'
        }

        It "Should return a string and a hashtable when passed as an array of strings" {
            $Output = Convert-StringToObject -InputString 'Invoke-Cmdlet1', "@{'Name' = 'Invoke-Cmdlet2'}"

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

        It "Should return a ScriptBlock when passed one as a value in a hashtable" {
            $Output = Convert-StringToObject -InputString "@{Name = 'Invoke-Function'; ScriptBlock = { Get-Command } }"

            $Output.Name | Should -Be "Invoke-Function"
            $Output.ScriptBlock | Should -BeOfType [ScriptBlock]
        }

        It "Should return a ScriptBlock when passed a multiline string as the value of ScriptBlock property in a hashtable" {
            $Hashtable = @"
            @{Name = 'Invoke-Function'; ScriptBlock = {
                Get-Command
                Get-Help
                Get-Member
            } }
"@
            $Output = Convert-StringToObject -InputString $Hashtable

            $Output.Name | Should -Be "Invoke-Function"
            $Output.ScriptBlock | Should -BeOfType [ScriptBlock]
        }
    }

}
