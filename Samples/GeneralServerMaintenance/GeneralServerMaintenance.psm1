function Get-SystemInfo {
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem -Property Name, Domain, Workgroup, Manufacturer, Model
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -Property Caption, Version

    $result = [ordered] @{
        'OS Name' = $os.Caption
        'OS Version' = $os.Version
        'System Name' = $cs.Name
        'Domain' = $cs.Domain
        'Workgroup' = $cs.Workgroup
        'System Manufacturer' = $cs.Manufacturer
        'System Model' = $cs.Model
    }

    Format-Table -InputObject $result -AutoSize -HideTableHeaders
}