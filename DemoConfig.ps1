Configuration MyConfiguration {

    Node DomainController {

        File StartupScriptforJEA {
            Contents = 'Write-Host "Welcome to my endpoint!"'
            DestinationPath = 'C:\ProgramData\JEA\StartupScript.ps1'
        }

        File CustomModuleWithCommands {
            Contents = 'function Reset-Password { (Get-AdUser $args[0]).ResetPassword()'
            DestinationPath = 'C:\Program Files\WindowsPowerShell\Modules\CustomModuleWithCommands\CustomModuleWithCommands.psm1'
        }

        # Brings in the ADHelpDesk role capability from PSGet
        Package ADCapabilityInstaller {
            Name = 'ADRoleCapabilities'
        }

        # Automatically deployed to target machine in:
        # C:\Program Files\WindowsPowerShell\Modules\JeaDeployment\RoleCapabilities\<ADUserManagement>
        RoleCapability ADUserManagement
        {
            CSVContents = 'C:\OnHostMachine\myCSV.csv'
            VisibleCommands = 
                # Full commands
                'Get-Process', 'CustomModuleWithCommands\Reset-Password',
                
                # Restricted commands (limiting parameters)
                @{ Name = 'Get-Service'; Parameters = 'Name' },
                [CommandRestriction] @{ Name = 'Get-Service'; Parameters = 'OtherParam','Other2' },

                # Super Restricted commands (limiting parameter arguments)
                [CommandRestriction] @{
                    Name = 'Get-Service'
                    Parameters = 'OtherParam'
                    ValidateSet = 'Value1', 'Value2'
                    ValidatePattern = '^a.*q$'
                }
        }

        JeaConfiguration ADConfigurations {
            EndpointName = 'Microsoft.PowerShell' # This is optional
            
            # If this is a group, make a Virtual Account.  If a GMSA, uses GMSA.
            RunAs = 'Contoso\Domain Admins','Administrators' 
            TranscriptDirectory = "\\myshare\share\JEATranscripts\"
            SecurityDescriptor = "O:NSG:BAD:P(A;;GA;;;BA)(A;;GA;;;IU)(AU;SA;GXGW;;;WD)"
            StartupScript = 'C:\ProgramData\JEA\StartupScript.ps1'
            RoleDefinitions = @{
                'Contoso\ADMasters' = 'ADUserManagement','ADHelpDesk','ADReplicationFromPSGet' 
                'Contoso\ADHelpDesk'= 'ADHelpDesk' }
        }
    }
}
