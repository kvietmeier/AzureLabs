## Scripts for working with Azure objects

Collection of scripts for working within Azure and with Azure Virtual Desktop. 

I don't use this folder as much anymore as I've shifted to Terraform for most of my Azure automation.

## Project Directories

``` shell
├───scripts
│   ├───AVD Scripts
│   ├───examples
│   └───users
```

AVD Scripts: Scripts related to AVD<br>
users: Has a script I grabbed off GitHub to add users to AD (I use Terraform for this now).<br>
examples: Code snippets and scripts I have downloaded - most are not mine.<br> 

### Usage

Many of my scripts are "." sourcing 2 files, one is outside the repo and has variables with sensitive information
like GUIDs, SubscriptionIDs/Names, and certificates. The other is in this repo and is a library of common functions.

They are accessed like this:
<https://devblogs.microsoft.com/scripting/how-to-reuse-windows-powershell-functions-in-scripts/>

``` powershell
. '<A drive somewhere>:\.somestuff.ps1'
. '.\FunctionLibrary.ps1'
```

An example of variables stored in the "somestuff.ps1" file and sourced in your profile:

``` powershell
# Subscription Information
$SubID = "xxxxxxxx-xxxx-xxxx-xxxxxxxxxxxxxxxxx"
$SubName = "ASubscriptionName"

# User Login
$AIAuser = "user@contoso.com"
$AIAPassword = "really should encrypt this"
```

Or use a Service Principle -

```powershell
###--- Tenant Info
$AzureTenantID  = "xxxxxxxx-xxxx-xxxx-xxxxxxxxxxxxxxxxx"
$AzureSubID     = "xxxxxxxx-xxxx-xxxx-xxxxxxxxxxxxxxxxx"
$AzureSubName   = "FOO-BAR-Subscription"
$AzureADDomain  = "foobar.onmicrosoft.com"

#--- Service Principle
$AppID      = "xxxxxxxx-xxxx-xxxx-xxxxxxxxxxxxxxxxx"
$AppSecret  = "xxxxxxxx-xxxx-xxxx-xxxxxxxxxxxxxxxxx"

# Usage:
az login --service-principal `
  -u $AppID `
  -p $AppSecret`
  --tenant $AzureTenantID

```

The script:

``` powershell
scripts/SetupPowerShellModules.ps1
```

Will setup your laptop/workstation to run PowerShell scripts/snippets and access Azure/AAD resources.

<br>
Some of these "scripts" aren't meant to be run as a single script but are collections of useful 
commands and code snippets to be run interactively using the ISE or VSC.
At some point I will merge them into larger scripts as functions but for now they exist as seperate utilities.

Especially - 

``` powershell
scripts/NetworkTroubleshooting.ps1
```

This file is a collection of various Powershell and OS commands/utilities for troubleshooting networks.

## Author

Karl Vietmeier
[@KarlVietmeier](https://twitter.com/karlvietmeier)

## Acknowledgments
My colleagues on the Azure Virtual Desktop GBB Team and PowerShell Gurus at MSFT-<br>
  Adam Whitlach<br>
  John Kelbly<br>
  Marc Wolfson<br>
  John Jenner<br>
  Tim Dunn<br>

## References

Inspiration, code snippets, etc.

* [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)