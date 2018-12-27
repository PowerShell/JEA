Configuration FailingFunctionDefinitions {
    param (
        $Path
    )

    Import-DscResource -ModuleName JeaDsc

    node localhost {

        JeaRoleCapabilities FailingFunctionDefinitions {
            Path = $Path
            Ensure = 'Present'
            FunctionDefinitions = '@{Name = "Get-ExampleData"; ScriptBlock = {Get-Command} }'
        }
    }
}
