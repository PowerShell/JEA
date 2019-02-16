Using Module ..\..\JeaDsc.psd1

Describe "Testing Compare-JeaConfiguration" {

    $Sut = 'Compare-JeaConfiguration'

    Context "Matching configurations" {

        BeforeAll {
            $BasicExistingRoleCapabilities = @{
                VisibleCmdlets = 'Get-Service'
            }
            $ScriptBlockExistingRoleCapabilities = @{
                FunctionDefinitions = @{
                    Name = "Get-ExampleData"
                    ScriptBlock = {Get-Command}
                }
            }
            $ArrayExistingRoleCapabilities = @{
                VisibleCmdlets = 'Get-*', 'DnsServer\*'
            }
            $HashtableExistingRoleCapabilities = @{
                VisibleCmdlets = @{
                    Name = 'Get-DscLocalConfigurationManager'
                    Parameters = @{
                        Name = '*'
                    }
                }
            }
            $ArrayWithHashtableExistingRoleCapabilities = @{
                VisibleCmdlets = @(
                    'Invoke-Cmdlet1'
                    @{
                        Name = 'Invoke-Cmdlet2'
                    }
                )
            }
            $ComplexExistingRoleCapabilities = @{
                VisibleCmdlets = @(
                    'WebAdministration\Get-*'
                    'Start-WebAppPool'
                    'Restart-WebAppPool'
                    'Stop-Website'
                    'Start-Website'
                    'Get-IISSite'
                    'Start-IISSite'
                    'Stop-IISSite'
                    'Get-IISAppPool'
                )
                VisibleAliases = 'Item1', 'Item2'
                ModulesToImport = 'MyCustomModule', @{
                    ModuleName = 'MyCustomModule'
                    ModuleVersion = '1.0.0.0'
                    GUID = '4d30d5f0-cb16-4898-812d-f20a6c596bdf'
                }
                FunctionDefinitions = @{
                    Name = 'MyFunction'
                    ScriptBlock = {
                        param($MyInput)
                        $MyInput
                    }
                }
                VisibleFunctions = 'Invoke-Function1', @{
                    Name = 'Invoke-Function2'
                    Parameters = @(
                        @{
                            Name = 'Parameter1'
                            ValidateSet = 'Item1', 'Item2'
                        }
                        @{
                            Name = 'Parameter2'
                            ValidatePattern = 'L*'
                        }
                    )
                }
            }

            $BasicNewRoleCapabilities = @{
                VisibleCmdlets = 'Get-Service'
            }
            $ScriptBlockNewRoleCapabilities = @{
                FunctionDefinitions = @{
                    Name = "Get-ExampleData"
                    ScriptBlock = {Get-Command}
                }
            }
            $ArrayNewRoleCapabilities = @{
                VisibleCmdlets = 'Get-*', 'DnsServer\*'
            }
            $HashtableNewRoleCapabilities = @{
                VisibleCmdlets = @{
                    Name = 'Get-DscLocalConfigurationManager'
                    Parameters = @{
                        Name = '*'
                    }
                }
            }
            $ArrayWithHashtableNewRoleCapabilities = @{
                VisibleCmdlets = @(
                    'Invoke-Cmdlet1'
                    @{
                        Name = 'Invoke-Cmdlet2'
                    }
                )
            }
            $ComplexNewRoleCapabilities = @{
                VisibleCmdlets = @(
                    'WebAdministration\Get-*'
                    'Start-WebAppPool'
                    'Restart-WebAppPool'
                    'Stop-Website'
                    'Start-Website'
                    'Get-IISSite'
                    'Start-IISSite'
                    'Stop-IISSite'
                    'Get-IISAppPool'
                )
                VisibleAliases = 'Item1', 'Item2'
                ModulesToImport = 'MyCustomModule', @{
                    ModuleName = 'MyCustomModule'
                    ModuleVersion = '1.0.0.0'
                    GUID = '4d30d5f0-cb16-4898-812d-f20a6c596bdf'
                }
                FunctionDefinitions = @{
                    Name = 'MyFunction'
                    ScriptBlock = {
                        param($MyInput)
                        $MyInput
                    }
                }
                VisibleFunctions = 'Invoke-Function1', @{
                    Name = 'Invoke-Function2'
                    Parameters = @(
                        @{
                            Name = 'Parameter1'
                            ValidateSet = 'Item1', 'Item2'
                        }
                        @{
                            Name = 'Parameter2'
                            ValidatePattern = 'L*'
                        }
                    )
                }
            }
        }

        $TestCases = @(
            @{
                Title = 'a single string'
                ReferenceObject = $BasicExistingRoleCapabilities
                DifferenceObject = $BasicNewRoleCapabilities
            }
            @{
                Title = 'an array'
                ReferenceObject = $ArrayExistingRoleCapabilities
                DifferenceObject = $ArrayNewRoleCapabilities
            }
            @{
                Title = 'a hashtable'
                ReferenceObject = $HashtableExistingRoleCapabilities
                DifferenceObject = $HashtableNewRoleCapabilities
            }
            @{
                Title = 'an array with a hashtable in it'
                ReferenceObject = $ArrayWithHashtableExistingRoleCapabilities
                DifferenceObject = $ArrayWithHashtableNewRoleCapabilities
            }
            @{
                Title = 'a number of items, including hashtables, arrays and scriptblocks'
                ReferenceObject = $ComplexExistingRoleCapabilities
                DifferenceObject = $ComplexNewRoleCapabilities
            }
            @{
                Title = 'a scriptblock'
                ReferenceObject = $ScriptBlockExistingRoleCapabilities
                DifferenceObject = $ScriptBlockNewRoleCapabilities
            }
        )

        It "Should match a role capbilities configuration containing <Title>" {
            param (
                $ReferenceObject,
                $DifferenceObject
            )
            &$Sut -ReferenceObject $ReferenceObject -DifferenceObject $DifferenceObject | Should -BeNullOrEmpty
        } -TestCases $TestCases

    }

    Context "Different configurations" {

        BeforeAll {
            $BasicExistingRoleCapabilities = @{
                VisibleCmdlets = 'Get-Service'
            }
            $ScriptBlockExistingRoleCapabilities = @{
                FunctionDefinitions = @{
                    Name = "Get-ExampleData"
                    ScriptBlock = {Get-Command}
                }
            }
            $ArrayExistingRoleCapabilities = @{
                VisibleCmdlets = 'Get-*', 'DnsServer\*'
            }
            $HashtableExistingRoleCapabilities = @{
                VisibleCmdlets = @{
                    Name = 'Get-DscLocalConfigurationManager'
                    Parameters = @{
                        Name = '*'
                    }
                }
            }
            $ArrayWithHashtableExistingRoleCapabilities = @{
                VisibleCmdlets = @(
                    'Invoke-Cmdlet1'
                    @{
                        Name = 'Invoke-Cmdlet2'
                    }
                )
            }
            $ComplexExistingRoleCapabilities = @{
                VisibleCmdlets = @(
                    'WebAdministration\Get-*'
                    'Start-WebAppPool'
                    'Restart-WebAppPool'
                    'Stop-Website'
                    'Start-Website'
                    'Get-IISSite'
                    'Start-IISSite'
                    'Stop-IISSite'
                    'Get-IISAppPool'
                )
                VisibleAliases = 'Item1', 'Item2'
                ModulesToImport = 'MyCustomModule', @{
                    ModuleName = 'MyCustomModule'
                    ModuleVersion = '1.0.0.0'
                    GUID = '4d30d5f0-cb16-4898-812d-f20a6c596bdf'
                }
                FunctionDefinitions = @{
                    Name = 'MyFunction'
                    ScriptBlock = {
                        param($MyInput)
                        $MyInput
                    }
                }
                VisibleFunctions = 'Invoke-Function1', @{
                    Name = 'Invoke-Function2'
                    Parameters = @(
                        @{
                            Name = 'Parameter1'
                            ValidateSet = 'Item1', 'Item2'
                        }
                        @{
                            Name = 'Parameter2'
                            ValidatePattern = 'L*'
                        }
                    )
                }
            }

            $BasicNewRoleCapabilities = @{
                VisibleCmdlets = 'Get-Service2'
            }
            $ScriptBlockNewRoleCapabilities = @{
                FunctionDefinitions = @{
                    Name = "Get-ExampleData"
                    ScriptBlock = {Get-Module}
                }
            }
            $ArrayNewRoleCapabilities = @{
                VisibleCmdlets = 'DnsServer\*'
            }
            $HashtableNewRoleCapabilities = @{
                VisibleCmdlets = @{
                    Name = 'Get-DscLocalConfigurationManager'
                    Parameters = @{
                        Name = 'AsJob'
                    }
                }
            }
            $ArrayWithHashtableNewRoleCapabilities = @{
                VisibleCmdlets = @(
                    @{
                        Name = 'Invoke-Cmdlet'
                    }
                    @{
                        Name = 'Invoke-Cmdlet2'
                    }
                )
            }
            $ComplexNewRoleCapabilities = @{
                VisibleCmdlets = @(
                    'Start-WebAppPool'
                    'Restart-WebAppPool'
                    'Stop-Website'
                    'Start-Website'
                    'Get-IISSite'
                    'Start-IISSite'
                    'Stop-IISSite'
                    'Get-IISAppPool'
                )
                FunctionDefinitions = @{
                    Name = 'MyFunction'
                    ScriptBlock = {
                        param($MyInput)
                        $MyInput + $MyInput
                    }
                }
                VisibleFunctions = 'Invoke-Function1', @{
                    Name = 'Invoke-Function2'
                    Parameters = @(
                        @{
                            Name = 'Parameter1'
                            ValidateSet = 'Item1', 'Item2'
                        }
                        @{
                            Name = 'Parameter2'
                            ValidatePattern = 'L*'
                        }
                    )
                }
            }
        }

        $TestCases = @(
            @{
                Title = 'a single string'
                ReferenceObject = $BasicExistingRoleCapabilities
                DifferenceObject = $BasicNewRoleCapabilities
            }
            @{
                Title = 'an array'
                ReferenceObject = $ArrayExistingRoleCapabilities
                DifferenceObject = $ArrayNewRoleCapabilities
            }
            @{
                Title = 'a hashtable'
                ReferenceObject = $HashtableExistingRoleCapabilities
                DifferenceObject = $HashtableNewRoleCapabilities
            }
            @{
                Title = 'an array with a hashtable in it'
                ReferenceObject = $ArrayWithHashtableExistingRoleCapabilities
                DifferenceObject = $ArrayWithHashtableNewRoleCapabilities
            }
            @{
                Title = 'a number of items, including hashtables, arrays and scriptblocks'
                ReferenceObject = $ComplexExistingRoleCapabilities
                DifferenceObject = $ComplexNewRoleCapabilities
            }
            @{
                Title = 'a scriptblock'
                ReferenceObject = $ScriptBlockExistingRoleCapabilities
                DifferenceObject = $ScriptBlockNewRoleCapabilities
            }
        )

        It "Should not match a role capbilities configuration containing <Title>" {
            param (
                $ReferenceObject,
                $DifferenceObject
            )
            &$Sut -ReferenceObject $ReferenceObject -DifferenceObject $DifferenceObject | Should -Be $false
        } -TestCases $TestCases
    }
}
