# Defines the values for the resource's Ensure property.
enum Ensure
{
    # The resource must be absent.    
    Absent
    # The resource must be present.    
    Present
}

[DscResource()]
class JeaConfiguration
{
    # The optional endpoint name.
    [DscProperty(Key)]
    [string] $EndpointName = 'Microsoft.PowerShell'

    # The optional RunAs setting. If this is a group, this will configure
    # the RunAsVirtualAccountGroups setting. If it not, it will configure
    # that account as a GMSA
    [DscProperty()]
    [string] $RunAs

    # The directory for transcripts to be saved to
    [DscProperty()]
    [string] $TranscriptDirectory

    # The security descriptor for the endpoint
    [DscProperty()]
    [string] $SecurityDescriptor

    # The startup script for the endpoint
    [DscProperty()]
    [string] $StartupScript

    [Dscproperty(Mandatory)]
    [System.Collections.Generic.IDictionary] $RoleDefinitions

    # Sets the desired state of the resource.
    [void] Set()
    {
        ## If replacing the default configuration, create alternate "Default"
        ## Create session configuration file
        ## Unregister any existing session configurations
        ## Register created .pssc file
        ## Clean up
    }
    
    # Tests if the resource is in the desired state.
    [bool] Test()
    {
        $currentConfiguration = Get

        ## Virtual account comparison
        ## RoleDefinition comparison
        ## NoLanguageMode
        ## ExecutionPolicy
        ## Any other characteristic that is required for a "JEA" Endpoint

        if(
            ($currentConfiguration.RunAs -eq $this.RunAs) -and
            ($currentConfiguration.TranscriptDirectory -eq $this.TranscriptDirectory) -and
            ($currentConfiguration.SecurityDescriptor -eq $this.SecurityDescriptor) -and
            ($currentConfiguration.StartupScript -eq $this.StartupScript)
            )
        {
            return $true
        }
        else
        {
            return $false
        }
    }

    # Gets the resource's current state.
    [JeaConfiguration] Get()
    {
        $sessionConfiguration = Get-PSSessionConfiguration -Name $this.EndpointName
        $configurationFile = $sessionConfiguration.ConfigFilepath

        ## TODO - Throw error if configuration file doesn't exist
        $configuration = Import-PowerShellDataFile -Path $configurationFile

        $runAsProperty = ""
        if($sessionConfiguration.RunAsVirtualAccount)
        {
            $runAsProperty = "VirtualAccount"
        }

        ## TODO - Add GMSA property when implemented

        $result = [JeaConfiguration] @{
            EndpointName = $this.EndpointName
            RunAs = $runAsProperty
            TranscriptDirectory = $configuration.TranscriptDirectory
            SecurityDescriptor = $sessionConfiguration.SecurityDescriptorSddl
            StartupScript = $configuration.StartupScript
            RoleDefinitions = $configuration.RoleDefinitions
        }

        return $result
    }
} 
