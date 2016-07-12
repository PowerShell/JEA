# This script will help you deploy and configure the General Server Maintenance roles

$ErrorActionPreference = 'Stop'

# IMPORTANT: Replace these group names with the correct ones for your environment
$GeneralLev1Group = "contoso.com\JEA_General_Lev1"
$GeneralLev2Group = "contoso.com\JEA_General_Lev2"
$IISLev1Group     = "contoso.com\JEA_IIS_Lev1"
$IISLev2Group     = "contoso.com\JEA_IIS_Lev2"

# Specify the session configuration details
$PSSCparams = @{
    Path = 'C:\ProgramData\JEAConfiguration\SampleJEAConfig.pssc'
    Author = 'Microsoft and Microsoft IT'
    Description = 'This session configuration grants users access to the general and IIS server maintenance roles.'
    SessionType = 'RestrictedRemoteServer'
    TranscriptDirectory = 'C:\ProgramData\JEAConfiguration\Transcripts'
    RunAsVirtualAccount = $true
    Full = $true
    RoleDefinitions = @{
        $GeneralLev1Group = @{ RoleCapabilities = 'General-Lev1' }
        $GeneralLev2Group = @{ RoleCapabilities = 'General-Lev1', 'General-Lev2' }
        $IISLev1Group     = @{ RoleCapabilities = 'IIS-Lev1' }
        $IISLev2Group     = @{ RoleCapabilities = 'IIS-Lev1', 'IIS-Lev2' }
    }
}

# Ensure the PSSC path exists
if (-not (Test-Path 'C:\ProgramData\JEAConfiguration')) {
    New-Item 'C:\ProgramData\JEAConfiguration' -ItemType Directory
}

# Create the PSSC
New-PSSessionConfigurationFile @PSSCparams

# Register the PSSC
# Note: you can change the name of the endpoint to anything you want
Register-PSSessionConfiguration -Path $PSSCparams['Path'] -Name 'JEA'

# Try out the JEA endpoint
# Enter-PSSession -ComputerName . -ConfigurationName 'Maintenance' -Credential (Get-Credential)