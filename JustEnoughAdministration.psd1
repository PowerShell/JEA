@{

    # Script module or binary module file associated with this manifest.
    # RootModule = ''

    # Version number of this module.
    ModuleVersion = '1.0.0.0'

    # ID used to uniquely identify this module
    GUID = 'c7c41e83-55c3-4e0f-9c4f-88de602e04db'

    # Author of this module
    Author = 'Microsoft Corporation'

    # Company or vendor of this module
    CompanyName = 'Microsoft Corporation'

    # Copyright statement for this module
    Copyright = '(c) Microsoft Corporation. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'This module contains resources to configure Just Enough Administration endpoints.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules = @(
        'DSCClassResources\JeaEndpoint\JeaEndpoint.psd1'
    )

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @()

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = '*'

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()

    # DSC resources to export from this module
    DscResourcesToExport = @(
        'JeaEndpoint'
    )

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('DesiredStateConfiguration', 'DSC', 'DSCResource')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/PowerShell/JEA/blob/master/LICENSE.txt'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/PowerShell/JEA'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            # ReleaseNotes = ''

        } # End of PSData hashtable

    } # End of PrivateData hashtable
    }
