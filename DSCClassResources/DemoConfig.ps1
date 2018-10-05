Configuration JeaTest
{
    Import-DscResource -Module JeaDsc

    JeaRoleCapabilities DnsAdminRoleCapability
    {
        Path = 'C:\Program Files\WindowsPowerShell\Modules\JeaDsc\RoleCapabilities\DnsAdmin.psrc'
        VisibleCmdlets = @{
            Name = 'Restart-Service'
            Parameters = @{
                Name = 'Name'
                ValidateSet = 'Dns'
            }
        }
    }

    JeaSessionConfiguration Endpoint
    {
        EndpointName = "Microsoft.PowerShell"
        RoleDefinitions = "@{ 'CONTOSO\DnsAdmins' = @{ RoleCapabilities = 'DnsAdmin' } }"
        TranscriptDirectory = 'C:\ProgramData\JeaEndpoint\Transcripts'
        ScriptsToProcess = 'C:\ProgramData\JeaEndpoint\startup.ps1'
        DependsOn = '[JeaRoleCapabilities]DnsAdminRoleCapability'
    }
}
