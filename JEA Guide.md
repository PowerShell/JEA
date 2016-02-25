# Just Enough Administration (JEA) Infrastructure: An Introduction

## Table of Contents
After reading this document, you should be able to author, deploy, use, maintain, and audit a Just Enough Administration (JEA) deployment on Windows Server 2016 PP1.  Here are the topics we will cover:  

1.	[Introduction](## Introduction): Briefly review why you should care about JEA

2.	[Prerequisites](## Prerequisites): Set up your environment

3.	[Using JEA](## Using JEA): Start by understanding the operator experience of using JEA

4.	[Remake the Demo](## Remake the Demo Endpoint): Create a JEA Session Configuration from scratch

5.	[Role Capabilities](## Role Capabilities): Learn about how to customize JEA capabilities with Role Capability Files

6.	[End to End - Active Directory](## End to End - Active Directory): Make a whole new endpoint for managing Active Directory

7.	[Multi-machine Deployment and Maintenance](## Multi-machine Deployment and Maintenance): Discover how deployment and authoring changes with scale

8.	[Reporting on JEA](## Reporting on JEA): Discover how to audit and report on all JEA actions and infrastructure

9.	[Appendix](## Appendix): Important skills and discussion points

## Introduction

### Motivation
When you grant someone privileged access to your systems, you extend your trust boundary to that person.  This is a risk; administrators are an attack surface.  Insider attacks and stolen credentials are both real and common.

This is not a new problem.  You are probably very familiar with the principle of least privilege, and you might use some form of role based access control (RBAC) with applications that provide it.  However, limited scope and large grained control limit the effectiveness and manageability of these solutions.  Furthermore, there are gaps in RBAC coverage.  For example, in Windows, privileged access is largely a binary switch, forcing you to give unnecessary permissions when adding users to the Administrator group.

Just Enough Administration (JEA) provides a RBAC platform through Windows PowerShell.   *It allows specific users to perform specific administrative tasks on servers without giving them administrator rights.*  This allows you to fill in the gaps between your existing RBAC solutions, and simplifies management of those settings.  

### Scope of this Guide
The initial release of JEA, called xJEA, consisted of experimental DSC resources.  Our experiences with xJEA helped us refine the JEA concept.  Now, many of the capabilities from xJEA are moving into the underlying PowerShell infrastructure.  Instead of building JEA *on top* of PowerShell Session Configurations, we are building JEA capabilities *into* PowerShell Session Configurations.  Windows Server 2016 PP1 marks the first release of these new capabilities.  **This experience guide is solely concerned with this new underlying infrastructure.**  

## Prerequisites

### Initial State
Before starting this section, please ensure the following:

1.	You have either:

	a.	An instance of Windows Server 2016 TP4 instance running 

	b.	An instance of Windows Server 2012 or 2012R2 with WMF 5.0 RTM

2.	You have administrative rights on the server

3.	The server is domain joined.  See the [Creating a Domain Controller](### Creating a Domain Controller) section for instructions on creating a standalone domain.

### Enable PowerShell Remoting
Management with JEA occurs through PowerShell Remoting.  Run the following in an Administrator PowerShell window to ensure that this process is set up.

```PowerShell
Enable-PSRemoting 
```

### Identify Your Users or Groups
To show JEA in action, you need to identify the non-administrator users and groups you are going to use throughout this guide.
  
If you’re using an existing domain, please identify or create some non-administrator users and groups.  You will give these non-administrators access to JEA.  Anytime you see the *$NonAdministrator* variable at the top of a script, assign it to your selected non-administrator users or groups. 

If you created a new domain from scratch, it’s much easier.  Please use the [Set Up Users and Groups](### Set Up Users and Groups) section in the appendix to create a non-administrator users and groups.  The default values of *$NonAdministrator* will be the groups created in that section.

### Set Up Maintenance Role Capability File
Run the following commands to create the demo "role capability" file we will be using for the next section.  Later in this guide, you will learn about what this file does.

```PowerShell
$powerShellPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0" 

# Fields in the role capability
$MaintenanceRoleCapabilityCreationParams = @{
    Author =
        "Contoso Admin"
    ModulesToImport=
        "Microsoft.PowerShell.Core"
    VisibleCmdlets=
        "Restart-Service"
    CompanyName=
        "Contoso"
    FunctionDefinitions = @{ Name = 'Get-UserInfo'; ScriptBlock = {$PSSenderInfo}}
        }

# Create the demo module, which will contain the demo Role Capability File
New-Item -Path "$env:ProgramFiles\WindowsPowerShell\Modules\Demo_Module" -ItemType Directory
New-ModuleManifest -Path "$env:ProgramFiles\WindowsPowerShell\Modules\Demo_Module\Demo_Module.psd1"
New-Item -Path "$env:ProgramFiles\WindowsPowerShell\Modules\Demo_Module\RoleCapabilities" -ItemType Directory 

# Create the Role Capability file
New-PSRoleCapabilityFile -Path "$env:ProgramFiles\WindowsPowerShell\Modules\Demo_Module\RoleCapabilities\Maintenance.psrc" @MaintenanceRoleCapabilityCreationParams 
```
  
### Create and Register Demo Session Configuration File
Run the following commands to create and register the demo "session configuration" file we will be using for the next section.  Later in this guide, you will learn about what this file does.

```PowerShell
#Determine domain
$domain = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain

#Replace with your non-admin group name
$NonAdministrator = "$domain\JEA_NonAdmin_Operator"

$JEAConfigParams = @{
        SessionType= "RestrictedRemoteServer" 
        RunAsVirtualAccount = $true
        RoleDefinitions = @{ $NonAdministrator = @{RoleCapabilities = 'Maintenance'}}
        TranscriptDirectory = "$env:ProgramData\JEAConfiguration\Transcripts"
        }
     
if(-not (Test-Path "$env:ProgramData\JEAConfiguration"))
{
    New-Item -Path "$env:ProgramData\JEAConfiguration" -ItemType Directory
}

$sessionName = "JEA_Demo"

if(Get-PSSessionConfiguration -Name $sessionName -ErrorAction SilentlyContinue)
{
    Unregister-PSSessionConfiguration -Name $sessionName -ErrorAction Stop
}

New-PSSessionConfigurationFile -Path "$env:ProgramData\JEAConfiguration\JEADemo.pssc" @JEAConfigParams
#endregion

#region Register the session configuration

Register-PSSessionConfiguration -Name $sessionName -Path "$env:ProgramData\JEAConfiguration\JEADemo.pssc"
Restart-Service WinRM 

#endregion
```
 
### [Optional] Enable PowerShell Module Logging
This enables logging for all PowerShell actions on your system.  You don’t need to enable this for JEA to work, but it will be useful in the [Reporting on JEA](## Reporting on JEA) section.

STEP 1: Open the local group policy editor

STEP 2: Navigate to "Computer Configuration\Administrative Templates\Windows Components\Windows PowerShell"

STEP 3: Double Click on "Turn on Module Logging"

STEP 4: Click "Enabled"

STEP 5: In the Options section, click on "Show" next to Module Names

STEP 6: Type "*" in the pop up window.  This means PowerShell will log commands from all modules

STEP 7: Click OK and apply the policy

Note: you can also enable system-wide PowerShell transcription through Group Policy.

**Congratulations, you have now configured your server and are ready to get started with JEA!**

## Using JEA
This section focuses on understanding the end user experience of *using JEA*.  In the prerequisites section, you created a demo JEA endpoint.  We will use this demo to show JEA in action.  In later sections, the guide will work backwards -- introducing the actions and files that made that end user experience possible.

### Using JEA as a Non-Administrator
STEP 1: To show JEA in action, you will need to use PowerShell remoting as though you were a non-administrator user.  Run the following command in a new PowerShell window:   

```PowerShell
$NonAdminCred = Get-Credential 
```

Enter the credentials for your non-administrator account when prompted.  If you followed the [Set Up Users and Groups](### Set Up Users and Groups) section, they will be this:
-	Username = "OperatorUser"
-	Password = "pa$$w0rd"

This creates and saves a PSCredential object for an unprivileged user that was created in the prerequisites section.  

STEP 2: Run the following command in your PowerShell window:

```PowerShell
Enter-PSSession -ComputerName . -ConfigurationName JEA_Demo -Credential $NonAdminCred 
```

You have now entered an interactive remote PowerShell session against the local machine.  By using the "Credential" parameter, you have connected *as though you were* NonAdminUser.  The change in the prompt indicates that you are operating against a remote session.  

STEP 3: Run the following in your remote command prompt:

```PowerShell
Get-Command 
```

This shows the commands that are available to the operator connecting this JEA endpoint.  As you can tell, this is a very limited subset of the command available in a normal PowerShell window (over 1520 commands on my machine).  

STEP 4: Run the following command in the remote session:

```PowerShell
Get-UserInfo
```
 
This custom command shows the "ConnectedUser" as well as the "RunAsUser."  The connected user is the account that connected to the remote session (e.g. your account).  The connected user does not need to have administrator privileges.  The "Run As" account is the account actually performing the privileged actions.  By connecting as one user, and running as a privileged user, we allow non-privileged users to preform specific administrative tasks without giving them administrative rights.

STEP 5: Run the following command in the remote session:

```PowerShell
Restart-Service -Name Spooler -Verbose
```

Restart-Service is one of the commands listed in the above configuration.  Normally, this command requires administrator privileges to run.

STEP 6: Try to run a PowerShell command that was not listed in STEP 3, such as:

```PowerShell
Restart-Computer 
```

JEA restricts which commands can be run as a privileged user.  The operator is restricted to only those commands listed in STEP 3.

STEP 7: Run the following command in the remote session:

```PowerShell
Exit-PSSession 
```

This disconnects you from the remote PowerShell session.

### Key Concepts
**PowerShell Remoting**:  PowerShell remoting allows you to run PowerShell commands against remote machines.  You can operate against one or many computers, and use either temporary or persistent connections.  In this demo, you remoted into your local machine with an interactive session.  JEA restricts the functionality available through PowerShell remoting.  For more information about PowerShell remoting, run the following command:

```PowerShell
Get-Help about_Remote 
```

**"RunAs" User**: When using JEA, a non-administrator "runs as" a privileged "Virtual Account."  The Virtual Account only lasts the duration of the remote session.  That is to say, it is created when a user connects to the endpoint, and destroyed when the user ends the session.  By default, the Virtual Account is a member of the local administrators group.  On a domain controller, it is also a member of Domain Administrators.   

**"Connected" User**: The non-administrator user who runs as the "RunAs" user through PowerShell remoting.

## Remake the Demo Endpoint
In this section, you will learn how to generate an exact replica of the demo endpoint you used in the above section.  This will introduce core concepts that are necessary to understand JEA, including PowerShell Session Configurations.  

### PowerShell Session Configurations
When you used JEA in the above section, you started by running the following command:

```PowerShell
Enter-PSSession -ComputerName . -ConfigurationName JEA_Demo -Credential $NonAdminCred
```

While most of the parameters are self-explanatory, the *ConfigurationName* parameter may seem confusing at first.  That parameter specified the PowerShell Session Configuration, or Endpoint, to which you were connecting. 

*PowerShell Session Configuration* is a fancy term for PowerShell Endpoint.  It is the figurative "place" where users connect and get access to PowerShell functionality.  Based on how you set up a Session Configuration, it can provide different functionality to connecting users.  For JEA, we use Session Configurations to restrict PowerShell to a limited set of functionality and to "RunAs" a privileged Virtual Account.

You already have several registered PowerShell Session Configurations on your machine, each set up slightly differently.  Most of them come with Windows, but the "JEADemo" Session Configuration was set up in the Prerequisites section.  You can see all registered Session Configurations by running the following command in an Administrator PowerShell prompt:

```PowerShell
Get-PSSessionConfiguration  
```

### PowerShell Session Configuration Files
You can make new Session Configurations by registering new *PowerShell Session Configuration Files*.  Session Configuration Files have ".pssc" file extensions.  You can generate Session Configuration Files with the New-PSSessionConfigurationFile command.  

Next, you are going to create and register a new Session Configuration for JEA. 

### Generate and Modify your PowerShell Session Configuration
STEP 1: Run the following script to generate a blank PowerShell Session Configuration file.

```PowerShell
New-PSSessionConfigurationFile -Path "$env:ProgramData\JEAConfiguration\JEADemo2.pssc"
```

This generates a blank Session Configuration File called "JEADemo2.pssc"  

STEP 2: Open it in PowerShell ISE, or your favorite text editor.

```PowerShell
ise "$env:ProgramData\JEAConfiguration\JEADemo2.pssc" 
```

STEP 3: You need to set the certain fields to make this Session Configuration File define a JEA Endpoint.  Specifically, please set the following lines to the following values (replace this with the name of your non-administrator group): 

```PowerShell
# Line 16
# Old value
SessionType = 'Default'

# New value
SessionType = 'RestrictedRemoteServer'

# Line 19
# Old value
TranscriptDirectory = 'C:\Transcripts\'

# New value
TranscriptDirectory = "C:\ProgramData\JEAConfiguration\Transcripts"

# Line 22
# Old value
RunAsVirtualAccount = $true

# New value
RunAsVirtualAccount = $true
RoleDefinitions = @{ 'CONTOSO\SqlAdmins' = @{ RoleCapabilities = 'SqlAdministration' }; 'CONTOSO\ServerMonitors' = @{ VisibleCmdlets = 'Get-Process' } }|RoleDefinitions = @{'Contoso\JEA_NonAdmin_Operator' = @{ RoleCapabilities =  'Maintenance' }}
```

Here is what each of those entries mean:

1.	The *SessionType* field defines preset default settings to use with this endpoint. *RestrictedRemoteServer* defines the minimal settings necessary for remote management.  By default, a *RestrictedRemoteServer* endpoint will expose Get-Command, Get-FormatData, Select-Object, Get-Help, Measure-Object, Exit-PSSession, Clear-Host, and Out-Default.  It will set the *ExecutionPolicy* to *RemoteSigned*, and the *LanguageMode* to *NoLanguage*.  The net effect of these settings is a secure and minimal starting point for configuring your endpoint. 

2.	The *RoleDefinitions* field gives *RoleCapabilities* to specific groups.  It defines who can do what as a privileged account.  With this field, you can specify the functionality available to any connecting user based on group membership.  This is the core of JEA’s RBAC functionality.  In this example, you are exposing the pre-made "Demo" RoleCapability to members of the "Contoso\JEA_NonAdmin_Operator" group.

3.	The *RunAsVirtualAccount* field indicates that PowerShell should "run as" a Virtual Account at this endpoint.  By default, the Virtual Account is a member of the built in Administrators group.  On a domain controller, it is also a member of the Domain Administrators group by default.  Later in this guide, you will learn how to customize the privileges of the Virtual Account.

4.	The *TranscriptDirectory* field defines where "over-the-shoulder" PowerShell transcripts are saved after each remote session.  These transcripts allow you to inspect the actions taken in each session in a readable way.  For more information about PowerShell transcripts, check out this [blog post](http://blogs.msdn.com/b/powershell/archive/2015/06/09/powershell-the-blue-team.aspx).  Note: regular Windows Eventing also captures information about what each user ran with PowerShell.  Transcripts are just a bit more readable.  

STEP 4: Save JEADemo2.pssc

### Apply the PowerShell Session Configuration 

To create a Session Configuration from a Session Configuration file, you need to register the file.  This requires a few pieces of information:

1.	The path to the Session Configuration File.

2.	The name of your registered Session Configuration.  This is the argument users provide to the "ConfigurationName" parameter when they connect to your endpoint.

3.	[Optional] A custom SDDL that defines access conditions for this Session Configuration.  This is only required for scenarios like two factor authentication.  Otherwise, PowerShell uses the "RoleDefinitions" field to determine access.  See [this section](### On SDDL Generation and Maintenance) in the appendix for more information. 

To register the Session Configuration on your local machine, run the following command:

```PowerShell
Register-PSSessionConfiguration -Name JEADemo2 -Path "$env:ProgramData\JEAConfiguration\JEADemo2.pssc"
```

Congratulations!  You have set up your first JEA endpoint.

### Test Out Your Endpoint
Re-run the steps listed in the [Using JEA](## Using JEA) section against your endpoint to confirm that your endpoint is operating as intended.

To ensure you are operating against your new endpoint, run the following command instead of STEP 2:

```PowerShell
Enter-PSSession -ComputerName . -ConfigurationName JEADemo2 -Credential $NonAdminCred
```

### Key Concepts
**PowerShell Session Configuration**:  Sometimes referred to as *PowerShell Endpoint*, the figurative "place" where users connect and get access to PowerShell functionality.  You can list the registered Session Configurations on your system by running Get-PSSessionConfiguration.  When configured in a specific way, a PowerShell Session Configuration can be called a *JEA Endpoint*.

**PowerShell Session Configuration File (.pssc)**:  A file that, when registered, defines settings for a PowerShell Session Configuration.  It contains specifications for user roles that can connect to the endpoint, the "run as" Virtual Account, and more.      

**Role Definitions**: The field in a Session Configuration File that defines the Role Capabilities granted to connecting users.  It defines who can do what as a privileged account.  This is the core of JEA’s RBAC capabilities.

**SessionType**: A field in a Session Configuration File that represents default settings for a Session Configuration.  For JEA Endpoints, this must be set to RestrictedRemoteServer.

**Security Descriptor Definition Language (SDDL)**: The SDDL defines who has access to an Endpoint, and is set when an Endpoint is registered.  By default, access to an endpoint is limited to the groups listed in Role Definitions.

**PowerShell Transcript**: A file containing an "over-the-shoulder" view of a PowerShell session.  You can set PowerShell to generate transcripts for JEA sessions using the TranscriptDirectory field.  For more information on transcripting, check out this blog post.

## Role Capabilities

### Overview
In the above section, you learned that the RoleDefinitions field defined which groups had access to which Role Capabilities.  You may have wondered, "What are Role Capabilities?"  This section will answer that question.  

## Introducing PowerShell Role Capabilities
PowerShell Role Capabilities define "what" a user can do at a JEA endpoint.  They detail a whitelist of things like visible commands, visible applications, and more.  Role Capabilities are defined by files with a ".psrc" extension.  

## Role Capability Contents
We will start by examining and modifying the demo Role Capability file you used before.  Imagine you have deployed your Session Configuration across your environment, but you have gotten feedback that you need to change the capabilities exposed to users.  Operators need the ability to restart machines, and they also want to be able to get information about network settings.  In addition, the security team has told you that allowing users to run "Restart-Service" without any restrictions is not acceptable.  You need to restrict the services that operators can restart.

STEP 1: Using PowerShell ISE running as an Administrator, open the following file:

"C:\Program Files\WindowsPowerShell\Modules\Demo_Module\RoleCapabilities\Maintenance.psrc" 

STEP 2: You need to set the certain fields implement the changes you want to make: 

```PowerShell
# Line 25
# Old value
VisibleCmdlets = 'Restart-Service'

# New value
VisibleCmdlets =   'Restart-Computer’, @{ Name = 'Restart-Service'; Parameters = @{ Name = 'Name'; ValidateSet = 'Spooler’ }}, 'NetTCPIP\Get-*' 

# Line 32
# Old value
VisibleExternalCommands = 'Item1', 'Item2'

# New value
VisibleExternalCommands = 'C:\Windows\system32\ipconfig.exe’
```

This contains a few interesting examples:

1.	You have restricted Restart-Service.  Operators will only be able to use Restart-Service with the -Name parameter, and they will only be allowed to provide "Spooler" as an argument to that parameter.  If you wanted to, you could also restrict the arguments using a regular expression using a "ValidatePattern". 

2.	You have exposed all commands with the "Get" verb from the NetTCPIP module.  Because "Get" commands typically don’t change system state, this is a relatively safe action.  That being said, we strongly encourage examining every command you expose through JEA.

3.	You have expose an executable (ipconfig) using VisibleExternalCommands.  You can also expose scripts with this field.

STEP 3: Save the file.

STEP 4: Re-run the steps listed in the [Using JEA](## Using Jea) section against your endpoint to confirm that your endpoint is operating as intended. 

Because you only modified the Role Capability file, you do not need to re-register the Session Configuration.  This is an important point to make; PowerShell will find your updated Role Capability when a user connects.
To ensure you are operating against your new endpoint, run the following command instead of STEP 2:

```PowerShell
Enter-PSSession -ComputerName . -ConfigurationName JEADemo2 -Credential $NonAdminCred
```

STEP 5: Confirm that you can restart the computer by running Restart-Computer with the -WhatIf parameter (unless you actually want to restart the computer).

```PowerShell
Restart-Computer -WhatIf 
```

STEP 6: Confirm that you can run "ipconfig"  

```PowerShell
ipconfig 
```

STEP 7: Confirm that Restart-Service only works for the Spooler service.

```PowerShell
Restart-Service Spooler #this should work
Restart-Service WSearch #this should fail 
```

STEP 8: Exit the session as before.

```PowerShell
Exit-PSSession 
```

### Role Capability Creation
In the next session, you will create a Session Configuration for AD Help Desk users.  To prepare, we will create a blank Role Capability file to fill in for that section.  In order to make this work, you will create a new module that will contain the role capability.  In order for PowerShell to detect Role Capabilities automatically, you must put them in a "RoleCapabilities" folder in this module.

PowerShell Modules are essentially packages of PowerShell functionality.  They can contain PowerShell functions, cmdlets, DSC Resources, Role Capabilities, and more.  

STEP 1: Create a "Contoso_AD_Module" folder the modules directory.  

```PowerShell
New-Item -Path "C:\Program Files\WindowsPowerShell\Modules\Contoso_AD_Module" -ItemType Directory 
```

STEP 2: Create a blank module manifest.  This module manifest will contain metadata about the module you are creating.

```PowerShell
New-ModuleManifest -Path 'C:\Program Files\WindowsPowerShell\Modules\Contoso_AD_Module\Contoso_AD_Module.psd1’ -RootModule Contoso_AD_Module.psm1 
```

STEP 3: Create a blank script module.  You’ll use this file for custom functions in the next section.

```PowerShell
New-Item -Path "C:\Program Files\WindowsPowerShell\Modules\Contoso_AD_Module\Contoso_AD_Module.psm1" -ItemType File 
```

STEP 4: Create a RoleCapabilities folder in the AD_Module folder.  PowerShell can only automatically discover Role Capabilities that are located in a "RoleCapabilities" folder within a module.

```PowerShell
New-Item -Path "C:\Program Files\WindowsPowerShell\Modules\Contoso_AD_Module\RoleCapabilities" -ItemType Directory 
```

STEP 5: Create a blank Role Capability in your RoleCapabilities folder.  Running this command without any additional parameters just creates a blank template.

```PowerShell
New-PSRoleCapabilityFile -Path 'C:\Program Files\WindowsPowerShell\Modules\Contoso_AD_Module\RoleCapabilities\ADHelpDesk.psrc’ 
```

Congratulations, you have created a blank Role Capability File.  It will be used in the next section.

### Key Concepts
**Role Capability (.psrc)**: A file that define "what" a user can do at a JEA endpoint.  It details a whitelist of things like visible commands, visible applications, and more.  In order for PowerShell to detect Role Capabilities automatically, you must put them in a "RoleCapabilities" folder in a valid PowerShell module.

**PowerShell Module**: A package of PowerShell functionality.  It can contain PowerShell functions, cmdlets, DSC Resources, Role Capabilities, and more.  In order to be automatically loaded, PowerShell Modules must be located on $env:PSModulePath. 

## End to End - Active Directory
Imagine the scope of your program has increased.  You are now responsible for adding JEA to Domain Controllers to perform Active Directory actions.  The help desk people are going to use JEA to unlock accounts, reset passwords, and do other similar actions.

You need to expose a completely new set of commands to a different group of people.  On top of that, you have a bunch of existing active directory scripts you need to expose.  This section will walk through how to author a Session Configuration and Role Capability for this task.  

### Prerequisites
To follow this section step-by-step, you’ll need to be operating on a domain controller.  If you don’t have access to your domain controller, don’t worry.  Try to follow along with by working against some other scenario or role with which you are familiar.  

### Steps to Making a New Role Capability and Session Configuration

Making a new role capability can seem daunting at first, but it’s can be broken into fairly simple steps:

1.	Identify the tasks you need to enable

2.	Restrict those tasks as necessary

3.	Confirm they work with JEA

4.	Put them in a Role Capability File

5.	Register a Session Configuration that exposes that Role Capability

### Step 1: Identify What Needs to Be Exposed
Before you make a new Role Capability or Session Configuration, you need to identify all of the things users will need to do through the JEA endpoint, as well as how to do them through PowerShell.  This will involve a fair amount of requirement gathering and research.
How you go about this process will be dependent on your organization and goals.  It is important to call out requirement gathering and research as a critical part of the real world process.  This may be the most difficult step in the process of adopting JEA.

#### Find Resources
Here is a set of online resources that might have come up in your research on creating an Active Directory Toolkit:
-	[Active Directory PowerShell Overview](http://blogs.msdn.com/b/adpowershell/archive/2009/03/05/active-directory-powershell-overview.aspx) 
-	[CMD to PowerShell Guide for Active Directory](http://blogs.technet.com/b/ashleymcglone/archive/2013/01/02/free-download-cmd-to-powershell-guide-for-ad.aspx)

#### Make a List
Here is a set of ten actions that you will be working from in the remainder of this section.  Keep in mind this is simply an example, your organizations requirements may be different:

|Action                                                         |PowerShell Command                                         |
|---------------------------------------------------------------|-----------------------------------------------------------|
|Account Unlock                                                 |Unlock-ADAccount                                           |
|Password Reset                                                 |Set-ADAccountPassword and Set-ADUser -ChangePasswordAtLogon|
|Change a User’s Title                                          |Set-ADUser -Title                                          |  
|Find AD Accounts that are locked out, disabled, inactive, etc. |Search-ADAccount                                           | 
|Add User to Group                                              |Add-ADGroupMember -Identity (with whitelist) -Members      | 
|Remove User from Group                                         |Remove-ADGroupMember -Identity (with whitelist) -Members   | 
|Enable a user account                                          |Enable-ADAccount                                           |
|Disable a user account                                         |Disable-ADAccount                                          |

### Step 2: Restrict Tasks as Necessary

Now that you have your list of actions, you need to think through the capabilities of each command.  There are two important reasons to do this:

1.	It is easy to expose give users more capabilities than you intend.  For example, Set-ADUser is an incredibly powerful and flexible command.  You may not want to expose everything it can do to help desk users.  

2.	Even worse, it’s possible to expose commands that allow users to escape JEA’s restrictions.  If this happens, JEA ceases to function as a security boundary.  Please be careful when selecting commands.  For example, Invoke-Expression will allow users to run unrestricted code.  For more discussion on this topic, check out the Considerations When Restricting Commands section.

After reviewing each command, you decide to restrict the following:

1.	Set-ADUser should only be allowed to run with the "-Title" parameter 

2.	Add-ADGroupMember and Remove-ADGroupMember should only work with certain groups

### Step 3: Confirm the Tasks Work with JEA
Actually using those cmdlets may not be straightforward in the restricted JEA environment.  JEA runs in *No Language* mode which, among other things, prevents users from using variables.  In order to ensure that end users have a smooth experience, it’s important to check for a few things.

As an example, consider Set-ADAccountPassword.  The -NewPassword parameter requires a secure string.  Most of the time, I would create a secure string and pass it in as a variable (as below):

```PowerShell
$newPassword = (Read-Host -Prompt "Provide New Password" -AsSecureString)
Set-ADAccountPassword -Identity mollyd -NewPassword $newPassword -Reset
```

However, No Language mode prevents the usage of variables.  You can get around this restriction in two ways:

1.	You can require users run the command without assigning variables.  This is easy to configure, but can be painful for the operators using the endpoint.  Who wants to type this out every time you reset a password?
```PowerShell
Set-ADAccountPassword -Identity mollyd -NewPassword (Read-Host -Prompt "Provide New Password" -AsSecureString) -Reset
```

2.	You can wrap the complexity in a script or a function that you expose to end users.  Scripts and functions that you expose run in an unrestricted context; you can write functions that use variables and call several other commands without any issue.  This approach simplifies the end user experience, prevents errors, reduces required PowerShell knowledge, and reduces unintentionally exposing excess functionality.  The only downside is the cost of authoring and maintaining the function.  

#### Aside: Adding a Function to Your Module
Taking approach #2, you are going to write a PowerShell function called Reset-ContosoUserPassword.  This function is going to do everything that needs to happen when you reset a user’s password.  In your organization, this may involve doing fancy and complicated things.  Because this is just an example, your command will just reset the password and require the user change the password at logon.  We will put it in the Contoso_AD_Module module you made in the last section.  

STEP 1: In PowerShell ISE, open "Contoso_AD_Module.psm1"
```PowerShell
ISE 'C:\Program Files\WindowsPowerShell\Modules\Contoso_AD_Module\Contoso_AD_Module.psm1' 
```

STEP 2: Press Crtl+J to open the snippets menu.

STEP 3: Key down until you find "function" and press enter.  This puts up a super basic skeleton of a function.

STEP 4: Rename the function "Reset-ContosoUserPassword".  

STEP 5: Rename one of the parameters "Identity" and delete the second.

STEP 6: Copy the following into the body of the function.
```PowerShell
# Get the new password
$NewPassword = Read-Host -Prompt "Provide New Password" -AsSecureString
# Reset the password
Set-ADAccountPassword -Identity $Identity -NewPassword $NewPassword -Reset
# Require the user to reset at next logon
Set-ADUser -Identity $Identity -ChangePasswordAtLogon
```

STEP 7: Save the file.  You should end up with something that looks like this:
```PowerShell
function Reset-ContosoUserPassword ($Identity)
{
# Get the new password
$NewPassword = Read-Host -Prompt "Provide New Password" -AsSecureString
# Reset the password
Set-ADAccountPassword -Identity $Identity -NewPassword $NewPassword -Reset
# Require the user to reset at next logon
Set-ADUser -Identity $Identity -ChangePasswordAtLogon
} 
```

Congratulations, you now have a bare bones function that gets the job done!

### Step 4: Edit the Role Capability File
In the [Role Capability Creation](## Role Capability Creation) section, you created a blank Role Capability file.  In this section, you will fill in the values in that file.

STEP 1: Open the role capability file in ISE.
```PowerShell
ISE 'C:\Program Files\WindowsPowerShell\Modules\Contoso_AD_Module\RoleCapabilities\ADHelpDesk.psrc' 
```
STEP 2: Please set the following fields:
```PowerShell
# Line 19
# Old value
ModulesToImport = 'MyCustomModule', @{ ModuleName = 'MyCustomModule2'; ModuleVersion = '1.0.0.0'; GUID = '4d30d5f0-cb16-4898-812d-f20a6c596bdf' }	

# New value
ModulesToImport = 'Contoso_AD_Module', 'ActiveDirectory'

# Line 25
# Old value
VisibleCmdlets = 'Invoke-Cmdlet1', @{ Name = 'Invoke-Cmdlet2'; Parameters = @{ Name = 'Parameter1'; ValidateSet = 'Item1', 'Item2' }, @{ Name = 'Parameter2'; ValidatePattern = 'L*' } }
 
# New value	
VisibleCmdlets = 'Unlock-ADAccount', 
       @{ Name = 'Set-ADUser'; Parameters = @{ Name = 'Title'; ValidateSet = 'Manager', 'Engineer' }},
                 'Search-ADAccount',
       @{ Name = 'Add-ADGroupMember'; Parameters = 
                          @{Name = 'Identity'; ValidateSet = 'TestGroup'},
                          @{Name = 'Members'}},
       @{ Name = 'Remove-ADGroupMember'; Parameters = 
                          @{Name = 'Identity'; ValidateSet = 'TestGroup'},
                          @{Name = 'Members'}},
                  'Enable-ADAccount',
                  'Disable-ADAccount' 
  
# Line 28
# Old value
VisibleFunctions = 'Invoke-Function1', @{ Name = 'Invoke-Function2'; Parameters = @{ Name = 'Parameter1'; ValidateSet = 'Item1', 'Item2' }, @{ Name = 'Parameter2'; ValidatePattern = 'L*' } }	

# New value
VisibleFunctions = 'Reset-ContosoUserPassword' 
```
There are a few things to note about the above:
1.	Listing the modules, you are using in ModulesToImport is not mandatory, but is considered a best practice.  Without it, PowerShell will auto-load modules for commands found in VisibleCmdlets and VisibleFunctions.
2.	If you aren’t sure if a command is a cmdlet or a function, run Get-Command and look at the "CommandType."
3.	The ValidatePattern allows you to use a regular expression to restrict parameter arguments.

### Step 5: Register a New Session Configuration
Next, you will create a new session configuration file that will expose your new role capability to members of the JEA_NonAdmin_HelpDesk group. 

STEP 1: Create and open a new blank Session Configuration File in PowerShell ISE.
```PowerShell
New-PSSessionConfigurationFile -Path "$env:ProgramData\JEAConfiguration\HelpDeskDemo.pssc" 
ISE "$env:ProgramData\JEAConfiguration\HelpDeskDemo.pssc"
```
STEP 2: Modify the following fields to the following values.  If you are working in your own environment, replace this with your own non-administrator user or group:
```PowerShell
# Line 13
# Old value
Description = ''

# New value
Description = 'An endpoint for active directory tasks.' 

# Line 16
# Old value
SessionType = 'Default'

# New value
SessionType = 'RestrictedRemoteServer'

# Line 19 
# Old value
TranscriptDirectory = 'C:\Transcripts\'

# New value
TranscriptDirectory = "C:\ProgramData\JEAConfiguration\Transcripts"

# Line 22
# Old value
RunAsVirtualAccount = $true
RunAsVirtualAccountGroups = 'Remote Desktop Users', 'Remote Management Users' 

# New value
RunAsVirtualAccount = $true 
RunAsVirtualAccountGroups # TODO: incomplete

# Line 31
# Old value
RoleDefinitions = @{ 'CONTOSO\SqlAdmins' = @{ RoleCapabilities = 'SqlAdministration' }; 'CONTOSO\ServerMonitors' = @{ VisibleCmdlets = 'Get-Process' } }

# New value
RoleDefinitions = @{'Contoso\JEA_NonAdmin_HelpDesk' = @{ RoleCapabilities =  'ADHelpDesk' }} 
```
STEP 3: Save and Register the Session Configuration
```PowerShell
Register-PSSessionConfiguration -Name ADHelpDesk -Path "$env:ProgramData\JEAConfiguration\HelpDeskDemo.pssc" 
```
### Test It Out!
STEP 1: Get your non-administrator user credentials. 
```PowerShell
$HelpDeskCred = Get-Credential 
```
If you followed the Set Up Users and Groups section, they will be this:
-	Username = "HelpDeskUser"
-	Password = "pa$$w0rd"

STEP 2: Remote into the machine as you did before.  
```PowerShell
Enter-PSSession -ComputerName . -ConfigurationName ADHelpDesk -Credential $HelpDeskCred 
```
STEP 3: Use Set-ADUser to reset a user’s title.
```PowerShell
Set-ADUser -Identity OperatorUser -Title Engineer 
```
STEP 4: Verify that the title has changed.
```PowerShell
Get-ADUser -Identity OperatorUser -Property Title 
```
STEP 5: Use Add-ADGroupMember to add a user to the TestGroup.  Note: make sure you’ve created the TestGroup beforehand.
```PowerShell
Add-ADGroupMember TestGroup -Member OperatorUser -Verbose 
```
STEP 6: Exit the session:
```PowerShell
Exit-PSSession 
```
### Key Concepts
**NoLanguage Mode**: When PowerShell is in "NoLanguage" mode, users may only run commands; they cannot use any language elements.  For more information, run 
```PowerShell
Get-Help about_Language_Modes
```
**RunAsVirtualAccountGroups**: You can use this element to set the permissions of the "RunAs" Virtual Account.  The token created for the Virtual Account will appear to 	

**PowerShell Functions**: PowerShell functions are bits of PowerShell code that you can call by name.  For more information, run Get-Help about_Functions. 

**ValidateSet/ValidatePattern**:  When exposing a command, you can restrict valid arguments for specific parameters.  A ValidateSet is a specific list of valid commands.  A ValidatePattern is a regular expression that the arguments for that parameter must match.

## Multi-machine Deployment and Maintenance
At this point, you have deployed JEA to local systems several times.  Because your production environment probably consists of more than one machine, it’s important to walk through the critical steps in the deployment process.

### High Level Steps:
1.	Copy your modules (with role capabilities) to each node.
2.	Copy your session configuration files to each node.
3.	Run Register-PSSessionConfiguration with your session configuration.
4.	Keep a copy of your session configuration and toolkits in a secure location. As you make modifications, it’s good to have a "single source of truth."

### Example Script
Here’s an example script for deployment.  To use it in your environment, you’ll have to use the names/paths of real file shares and modules.  
```PowerShell
# First, copy the session configuration and modules (containing role capability files) onto a file share you have access to.
Copy-Item -Path 'C:\Demo\Demo.pssc' -Destination '\\FileShare\JEA\Demo.pssc'
Copy-Item -Path 'C:\Program Files\WindowsPowerShell\Modules\SomeModule\' -Recurse -Destination '\\FileShare\JEA\SomeModule'

# Second, author a setup script (C:\JEA\Deploy.ps1) to run on each individual node
    # Contents of C:\JEA\Deploy.ps1
    New-Item -ItemType Directory -Path C:\JEADeploy
    Copy-Item -Path '\\FileShare\JEA\Demo.pssc' -Destination 'C:\JEADeploy\'
    Copy-Item -Path '\\FileShare\JEA\SomeModule' -Recurse -Destination 'C:\Program Files\WindowsPowerShell\Modules' # Remember, Role Capability Files are found in modules
    if(Get-PSSessionConfiguration -Name JEADemo -ErrorAction SilentlyContinue)
    {
        Unregister-PSSessionConfiguration -Name JEADemo -ErrorAction Stop
    } 

    Register-PSSessionConfiguration -Name JEADemo -Path 'C:\JEADeploy\Demo.pssc' -SecurityDescriptorSddl 'SDDL From Single Machine Deployment Here'
    Restart-Service 'WinRM'
    Remove-Item -Path 'C:\JEADeploy' #Don't forget to clean up!

# Third, invoke the script on all of the target machines.
# Note: this requires PowerShell Remoting be enabled on each machine. Enabling PowerShell remoting is a requirement to use JEA as well.
Invoke-Command –ComputerName 'Node1', 'Node2', 'Node3', 'NodeN' -FilePath 'C:\JEA\Deploy.ps1'

# Finally, delete the session configuration and role capability files from the file share.
Remove-Item -Path '\\FileShare\JEA\Demo.pssc'
Remove-Item -Path '\\FileShare\JEA\SomeModule' -Recurse 
```
### Modifying Capabilities
When dealing with many machines, it’s important that modifications are rolled out in a consistent manner.  Once JEA has DSC Resources, this will help ensure your environment is in sync.  Until that time, we highly recommend you keep a master copy of your session configurations and redeploy each time you make a modification.

### Removing Capabilities
To remove JEA from your systems, use the following command on each machine:
```PowerShell
Unregister-PSSessionConfiguration -Name JEADemo 
```
## Reporting on JEA
Because JEA allows non-privileged users to run in a privileged context, logging and auditing are extremely important.  In this section, we’ll run through the tools you can use to help you with logging and reporting.

### Reporting on JEA Actions
#### Over-the-Shoulder Transcription
One of the quickest ways to get a summary of what’s happening in a PowerShell session is to look over the shoulder of the person typing. You see their commands, the output of those commands, and all is well. Or it’s not, but at least you’ll know.  PowerShell Transcription is designed to give you a similar view after the fact.

When using the "TranscriptDirectory" field in your session configuration, PowerShell will automatically record a transcript of all actions taken in a given session.  You can find transcripts from your sessions in this document here: "$env:ProgramData\JEAConfiguration\Transcripts"

As you can tell, the transcript records information about the "Connected" user, the "Run As" user, the commands run in the session, and more.  For more information about PowerShell transcription, check out [this blog post](http://blogs.msdn.com/b/powershell/archive/2015/06/09/powershell-the-blue-team.aspx).

#### PowerShell Event Logs
When you have module logging turned on, all PowerShell actions are also recorded in regular Windows Event logs.  This is slightly messier to deal with when compared to transcripts, but the level of detail it gives you can be useful.

In the "PowerShell" operational log, Event ID 4104 will record each command invoked if you have enabled module logging.

#### Other Event Logs
Unlike PowerShell logs and transcripts, other logging mechanisms will not capture the "Connected User".  You will need to do some correlation between other logs and PowerShell logs to match up actions taken.

In the "Windows Remote Management" operational log, Event ID 193 will record the Connecting User’s SID and Name, as well as the RunAs Virtual Account’s SID to assist with this correlation.  You may have also noticed that the name of the RunAs Virtual Account 

### Reporting on JEA Configuration
#### Get-PSSessionConfiguration
In order to accurately report on the state of your environment, it’s critical that you be able to report on the number of JEA endpoints you have set up.  "Get-PSSessionConfiguration" does this on each machine. 
#### Get-PSSessionCapability
Manually reporting on the capabilities of any given user through a JEA endpoint can be quite complex.  You would potentially need to inspect several role capabilities.  Fortunately, the "Get-PSSessionCapability" cmdlet does this.

To test this out, run the following command from an administrator PowerShell prompt:
```PowerShell
Get-PSSessionCapability -Username OperatorUser -ConfigurationName JEADemo2 
```
## Conclusion 
After completing this guide, you should have the tools and vocabulary to create your own JEA endpoint. Thanks for reading!

## Appendix

### Creating a Domain Controller

This document assumes that your machine is domain joined.  If you currently don’t
In the Making a Toolkit section, you will explore creating an Active Directory toolkit as an example.  In the first few sections, you will grant unprivileged users capabilities based on AD group membership.  Both of these require your machine a domain controller.  The rest of this document assumes that your machine is the domain controller of a "Contoso" domain.
There are many ways to set up a domain.  For example, you could use Server Manager.  Below are some instructions on how to do it with PowerShell Desired State Configuration (DSC). 

#### Prerequisites

1.	The machine is on an internal network

2.	The machine is not joined to an existing domain

3.	The machine has the "xActiveDirectory" module [installed](### How to Install xActiveDirectory)

#### DSC Instructions

Copy the following script in PowerShell to make your machine a Domain Controller in a new domain.
**AUTHORS NOTE: THERE IS A KNOWN ISSUE WITH THE CREDENTIALS PROVIDED NOT BEING USED.  TO BE SAFE, DON’T FORGET YOUR LOCAL ADMIN PASSWORD.**

```PowerShell
Set-Item WSMan:\localhost\Client\TrustedHosts -Value $env:COMPUTERNAME -Force 

# This "MetaConfiguration" sets the DSC Engine to automatically reboot if required
[DscLocalConfigurationManager()]
Configuration MetaConfiguration
{
    Node $env:Computername
    {
        Settings
        {
            RebootNodeIfNeeded = $true
        }
    }
    
}

MetaConfiguration
# Apply the MetaConfiguration
Set-DscLocalConfigurationManager .\MetaConfiguration

# Configure a domain controller of a new "Contoso" domain
configuration DomainController
{
    param
    (
        $node,
        $cred
    )
    Import-DscResource -ModuleName xActiveDirectory

    Node $node
    {
        WindowsFeature ADDS
        {
            Ensure = 'Present'
            Name = 'AD-Domain-Services'
        }

        xADDomain Contoso
        {
            DomainName = 'contoso.com'
            DomainAdministratorCredential = $cred
            SafemodeAdministratorPassword = $cred
            DependsOn = '[WindowsFeature]ADDS'
        }

        file temp
        {
            DestinationPath = 'C:\temp.txt'
            Contents = 'Domain has been created'
            DependsOn = '[xADDomain]Contoso'
        }
    }
}

$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = $env:Computername
            PSDscAllowPlainTextPassword = $true
        }
    )
}

# Enter your desired password for the domain administrator (note, this will be stored as plain text)
DomainController -cred (Get-Credential -Message "Enter desired credential for domain administrator") -node $env:Computername -configurationData $ConfigData
# Apply the configuration to create the domain controller
Start-DSCConfiguration -path .\DomainController -ComputerName $env:Computername -Wait -Force -Verbose
```
Your machine will restart a few times.  You will know the process is complete once you see a file called "C:\temp.txt" containing "Domain has been created." 

### How to Install xActiveDirectory
If your machine has an active internet connection, run the following command in an Administrator PowerShell window:
```PowerShell
Install-Module xActiveDirectory -Force 
```
If you do not have an internet connection, install xActiveDirectory to another machine and then copy the xActiveDirectory folder to the "C:\Program Files\WindowsPowerShell\Modules" folder on your TP3 machine.
To confirm the installation, run the following command:
```PowerShell
Get-Module xActiveDirectory -ListAvailable
``` 

### Set up Users and Groups
If you created a domain from scratch (as per the Creating a Domain Controller section), you can use this section to create a few non-administrator groups and users.
```PowerShell
#Make Groups
$NonAdminOperatorGroup = New-ADGroup -Name "JEA_NonAdmin_Operator" -GroupScope DomainLocal -PassThru
$NonAdminHelpDeskGroup = New-ADGroup -Name "JEA_NonAdmin_HelpDesk" -GroupScope DomainLocal -PassThru
$TestGroup = New-ADGroup -Name "Test_Group" -GroupScope DomainLocal -PassThru
#Make Users
$OperatorUser = New-ADUser -Name "OperatorUser" -AccountPassword (ConvertTo-SecureString "pa`$`$w0rd" -AsPlainText -Force) -PassThru
Enable-ADAccount -Identity $OperatorUser
$HelpDeskUser = New-ADUser -name "HelpDeskUser" -AccountPassword (ConvertTo-SecureString "pa`$`$w0rd" -AsPlainText -Force) -PassThru
Enable-ADAccount -Identity $HelpDeskUser
#Add Users to Groups
Add-ADGroupMember -Identity $NonAdminOperatorGroup -Members $OperatorUser
Add-ADGroupMember -Identity $NonAdminHelpDeskGroup -Members $HelpDeskUser 
New-ADGroup TestGroup -GroupScope DomainLocal 
```

### On Blacklisting
After playing around with JEA, many customers ask about blacklisting commands.  This is an understandable request, but it is not going to happen anytime soon.  There are three primary reasons for this.
1.	We designed JEA to limit operators to only the actions they need to do.  A blacklist is the opposite.

2.	PowerShell command authors did not design PowerShell commands with the JEA in mind.  On a fresh install of Windows Server 2016 TP3, there are about 1520 commands immediately available. The threat models for these commands did not include the possibility that a user would be running commands as a more privileged account.  For example, certain commands allow for code injection by design (e.g. Add-Type and Invoke-Command in the core PowerShell module).  JEA can warn you when you expose the specific commands we know about, but we have not re-assessed every other command in Windows based on the new threat model.   You must understand the capabilities of the commands you exposing through JEA.  

3.	Furthermore, even if JEA blocked all commands with code-injection vulnerabilities, there is no guarantee that a malicious user would not be able to carry out a blacklisted action with another related command.  Unless you understand all of the commands that you are exposing – it is impossible for you to guarantee that a certain action is not possible.
The burden is on you to understand what commands you are exposing, whether they are using a whitelist or a blacklist.  The number of commands a blacklist would expose is unmanageable, so JEA does not allow blacklists.

### On SDDL Generation and Maintenance
By default, PowerShell will only allow to users or groups access to an endpoint if they are listed in "RoleDefinitions" in the session configuration file.  It does this by auto-generating a SDDL that defines access to the endpoint. This works well, until you consider situations like Multi-Factor Authentication.  In those situations, you might want to put additional conditions on those users and groups.  For example, they might need to be a member of a security group representing smart card verification.  
For these advanced scenarios, you can still use JEA.  You’ll just need to create the SDDL yourself.  To do this use the "-ShowSecurityDescriptorUI" parameter of Register-PSSessionConfiguration.  Then follow these steps:

1.	Click on the "Advanced" button

2.	Remove the two default groups

3.	Click the "Add" button

4.	Click "Select a Principle" and choose the user or group you want to give access

5.	Click "Add a Condition" with whatever condition you wish to add

6.	Click Okay

7.	Repeat steps 3-6 for each user/group that needs access to the endpoint

The registered endpoint will have a customized SDDL that restricts access in a conditional way.  To actually see that SDDL, just run:
```PowerShell
(Get-PSSessionConfiguration -Name ConfigurationName).SecurityDescriptorSddl 
```
To use that same SDDL on other endpoints, you can provide it as an argument to Register-PSSessionConfiguration:
```PowerShell
Register-PSSessionConfiguration -Name UsingSDDL -SecurityDescriptorSddl "<Your SDDL Here>" 
```
### Considerations When Limiting Commands
There is one important point to make about this step.  It is critical that all capabilities exposed through JEA are located in administrator-restricted areas.  Non-administrator users should not have the capability to modify the scripts used through JEA endpoints.  In this example, I placed the scripts within the module so that you could deploy both in a single step.

On a related note, it is critical that you do not give JEA users the ability to overwrite these scripts through JEA Endpoints.  Be extremely careful with exposing commands like Copy-Item!

### Common Role Capability Pitfalls
You may run into a few common pitfalls into you go through this process yourself.  Here is a quick guide explaining how to identify and remediate these issues when modifying or creating a new toolkit.

#### Functions vs. Cmdlets
PowerShell commands written in PowerShell are PowerShell Functions.  PowerShell commands written as specialed .NET classes are PowerShell Cmdlets.  Typically, built in commands are Cmdlets, but it is best to check the command type by running Get-Command.
#### VisibleProviders 
You will need to expose the providers your command need.  The most common is the FileSystem provider, but you may also need to expose others, like the Registry provider.  For an introduction to providers, I recommend this [Hey, Scripting Guy blog post](http://blogs.technet.com/b/heyscriptingguy/archive/2015/04/20/find-and-use-windows-powershell-providers.aspx) 

