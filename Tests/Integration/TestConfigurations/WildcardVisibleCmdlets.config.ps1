Configuration WildcardVisibleCmdlets {
    param (
        $Path
    )

    Import-DscResource -ModuleName JeaDsc

    node localhost {

        JeaRoleCapabilities WildcardVisibleCmdlets {
            Path = $Path
            Ensure = 'Present'
            VisibleCmdlets = 'Get-*','DnsServer\*'
        }
    }
}
