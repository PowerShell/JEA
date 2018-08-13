# Just Enough Administration Samples and Resources
Just Enough Administration (JEA) is a PowerShell security technology that provides a role based access control platform for anything that can be managed with PowerShell.
It enables authorized users to run specific commands in an elevated context on a remote machine, complete with full PowerShell transcription and logging.
JEA is included in PowerShell version 5 and higher on Windows 10 and Windows Server 2016, and older OSes with the Windows Management Framework updates.

This repository contains sample role capabilities created by the Microsoft IT team and the official DSC resource that can be used to deploy JEA across your enterprise.
General information and documentation for JEA has migrated to [MSDN](http://aka.ms/JEAdocs).

## Documentation
JEA documentation has moved to MSDN -- check it out at [http://aka.ms/JEAdocs](http://aka.ms/JEAdocs)!
In addition to making the documentation easier to find and read, you can now [contribute to the documentation](https://github.com/PowerShell/PowerShell-Docs/blob/staging/CONTRIBUTING.md) by submitting pull requests to the *staging* branch.

## DSC Resource
The [JEA DSC resource](./DSC%20Resource) can help you quickly and consistently deploy JEA endpoints across your enterprise.
The *JustEnoughAdministration* DSC resource configures the PowerShell session configurations, which define the mapping of users to roles and general session security settings.
Role capabilities belong to standard PowerShell modules, and can be deployed with the DSC [file resource](https://msdn.microsoft.com/en-us/PowerShell/DSC/fileResource).
Check out the [Demo Config](./DSC Resource/DemoConfig.ps1) for an example of how to deploy a JEA endpoint using these DSC resources.

## Sample Role Capabilities
Microsoft IT have been working with JEA since its inception and have shared some of their role capabilities for general server and IIS maintenance/support.
[Check them out](./Samples) to learn more about how to create role capability files or download them to use in your own environment!

## Contributing
Please see the [DSC contribution guidelines](https://github.com/PowerShell/DscResources/blob/master/CONTRIBUTING.md) for information on contributing to this project.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
