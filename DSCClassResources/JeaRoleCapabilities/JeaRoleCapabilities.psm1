enum Ensure
{
    Present
    Absent
}

[DscResource()]
class JeaRoleCapabilities {

    [DscProperty()]
    [Ensure]$Ensure = [Ensure]::Present

    # Where to store the file.
    [DscProperty(Key)]
    [String]$Path

    # Specifies the modules that are automatically imported into sessions that use the role capability file.
    # By default, all of the commands in listed modules are visible. When used with VisibleCmdlets or VisibleFunctions,
    # the commands visible from the specified modules can be restricted. Hashtable with keys ModuleName, ModuleVersion and GUID.
    [DscProperty()]
    [Hashtable]$ModulesToImport

    # Limits the aliases in the session to those aliases specified in the value of this parameter,
    # plus any aliases that you define in the AliasDefinition parameter. Wildcard characters are supported.
    # By default, all aliases that are defined by the Windows PowerShell engine and all aliases that modules export are
    # visible in the session.
    [DscProperty()]
    [String[]]$VisibleAliases

    # Limits the cmdlets in the session to those specified in the value of this parameter.
    # Wildcard characters and Module Qualified Names are supported.
    [DscProperty()]
    [String[]]$VisibleCmdlets

    #  Limits the functions in the session to those specified in the value of this parameter,
    # plus any functions that you define in the FunctionDefinitions parameter. Wildcard characters are supported.
    [DscProperty()]
    [String[]]$VisibleFunctions

    # Limits the external binaries, scripts and commands that can be executed in the session to those specified in
    # the value of this parameter. Wildcard characters are supported.
    [DscProperty()]
    [String[]]$VisibleExternalCommands

    # Limits the Windows PowerShell providers in the session to those specified in the value of this parameter.
    # Wildcard characters are supported.
    [DscProperty()]
    [String[]]$VisibleProviders

    # Specifies scripts to add to sessions that use the role capability file.
    [DscProperty()]
    [Hashtable]$ScriptsToProcess

    # Adds the specified aliases to sessions that use the role capability file.
    # Hashtable with keys Name, Value, Description and Options.
    [DscProperty()]
    [Hashtable]$AliasDefinitions

    # Adds the specified functions to sessions that expose the role capability.
    # Hashtable with keys Name, Scriptblock and Options.
    [DscProperty()]
    [Hashtable]$FunctionDefinitions

    # Specifies variables to add to sessions that use the role capability file.
    # Hashtable with keys Name, Value, Options.
    [DscProperty()]
    [Hashtable]$VariableDefinitions

    # Specifies the environment variables for sessions that expose this role capability file.
    # Hashtable of environment variables.
    [DscProperty()]
    [Hashtable]$EnvironmentVariables

    # Specifies type files (.ps1xml) to add to sessions that use the role capability file.
    # The value of this parameter must be a full or absolute path of the type file names.
    [DscProperty()]
    [Hashtable]$TypesToProcess

    # Specifies the formatting files (.ps1xml) that run in sessions that use the role capability file.
    # The value of this parameter must be a full or absolute path of the formatting files.
    [DscProperty()]
    [String[]]$FormatsToProcess

    # Specifies the assemblies to load into the sessions that use the role capability file.
    [DscProperty()]
    [String[]]$AssembliesToLoad

    Hidden [Hashtable] ConvertToHashtable() {
        $Parameters = @{}
        foreach ($Parameter in $this.PSObject.Properties.Where({$_.Value})) {
            $Parameters.Add($Parameter.Name,$Parameter.Value)
        }

        return $Parameters
    }

    Hidden [Boolean] ValidatePath() {
        $FileObject = [System.IO.FileInfo]::new($this.Path)
        if ($FileObject.Extension -ne '.psrc') {
            return $false
        }

        if ($FileObject.Directory.Name -ne 'RoleCapabilities') {
            return $false
        }

        if ($FileObject.FullName -notmatch (([Regex]::Escape($env:PSModulePath)) -replace ';', '|')) {
            return $false
        }

        return $true
    }

    [JeaRoleCapabilities] Get() {
        if (Test-Path -Path $this.Path) {
            $CurrentState = Import-PowerShellDataFile -Path $this.Path
            foreach ($Property in $CurrentState.Keys) {
                $this.$Property = $CurrentState[$Property]
            }
            $this.Ensure = [Ensure]::Present
        }
        else {
            $this.Ensure = [Ensure]::Absent
        }
        return $this
    }

    [void] Set() {
        if ($this.Ensure -eq [Ensure]::Present) {

            $Parameters = $this.ConvertToHashtable()
            $Parameters.Remove('Ensure')

            $null = New-Item -Path $this.Path -ItemType File -Force

            New-PSRoleCapabilityFile @Parameters
        }
        elseif ($this.Ensure -eq [Ensure]::Absent -and (Test-Path -Path $this.Path)) {
            Remove-Item -Path $this.Path -Confirm:$False
        }

    }

    [bool] Test() {
        if (-not ($this.ValidatePath())) {
            Write-Error -Message "Invalid path specified. It must point to a Module folder, be a psrc file and the parent folder must be called RoleCapabilities"
            return $false
        }
        if ($this.Ensure -eq [Ensure]::Present -and -not (Test-Path -Path $this.Path)) {
            return $false
        }
        elseif ($this.Ensure -eq [Ensure]::Present -and (Test-Path -Path $this.Path)) {
            $CurrentState = $this.Get()

            $Parameters = $this.ConvertToHashtable()
            $Compare = FindMismatchedHashtableValue -ActualValue $CurrentState -ExpectedValue $Parameters

            if ($null-eq $Compare) {
                return $true
            }
            else {
                return $false
            }
        }
        elseif ($this.Ensure -eq [Ensure]::Absent -and (Test-Path -Path $this.Path)) {
            return $false
        }
        elseif ($this.Ensure -eq [Ensure]::Absent -and -not (Test-Path -Path $this.Path)) {
            return $true
        }

        return $false
    }
 }

 function Compare-Hashtable($ActualValue, $ExpectedValue) {
    # Based on FindMisMatchedHashtableValue by Stuart Leeks
    # https://github.com/stuartleeks/PesterMatchHashtable
    foreach($expectedKey in $ExpectedValue.Keys) {
        if (-not($ActualValue.Keys -contains $expectedKey)){
            return "Expected key: {$expectedKey}, but missing in actual"
        }
        $expectedItem = $ExpectedValue[$expectedKey]
        $actualItem = $ActualValue[$expectedKey]
        if (-not ($actualItem -eq $expectedItem)) {
            return "Value differs for key {$expectedKey}. Expected value: {$expectedItem}, actual value: {$actualItem}"
        }
    }

    foreach($actualKey in $ActualValue.Keys) {
        if (-not($ExpectedValue.Keys -contains $actualKey)){
            return "Actual key: {$actualKey}, but missing in expected"
        }
        $expectedItem = $ExpectedValue[$actualKey]
        $actualItem = $ActualValue[$actualKey]
        if (-not ($actualItem -eq $expectedItem)) {
            return "Value differs for key {$actualKey}. Expected value: {$expectedItem}, actual value: {$actualItem}"
        }
    }
}
