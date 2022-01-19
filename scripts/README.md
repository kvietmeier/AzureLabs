## Scripts for working with Azure objects

Collection of scripts for working within Azure and with Azure Virtual Desktop. 


## Project Directories
```
├───scripts
│   ├───AVD Scripts
│   ├───examples
│   └───users
```
AVD Scripts: Scripts related to AVD<br>
users: Has a script I grabbed off GitHub to add users to AD.<br>
examples: Code snippets and scripts I have downloaded - most are not mine.<br> 


### Usage
My scripts are "." sourcing 2 files, one is outside the repo and has variables with sensitive information
like GUIDs, SubscriptionIDs/Names, and certificates. The other is in this repo and is a library of common 
functions.

They are accessed like this:
https://devblogs.microsoft.com/scripting/how-to-reuse-windows-powershell-functions-in-scripts/
```
. 'C:\.miscinfo.ps1'
. '.\FunctionLibrary.ps1'
```


An example of the variables stored in the "resources.ps1" file:
```
# Subscription Information
$SubID = "xxxxxxxx-xxxx-xxxx-xxxxxxxxxxxxxxxxx"
$SubName = "ASubscriptionName"
$AIAuser = "user@contoso.com"
$AIAPassword = "really should encrypt this"
```

The script:
```
scripts/SetupPowerShellModules.ps1
```
Will setup your laptop/workstation to run PowerShell scripts/snippets and access Azure/AAD resources.

<br>
Some of these "scripts" aren't meant to be run as a single script but are collections of useful 
commands and code snippets to be run interactively using the ISE or VSC.
At some point I will merge them into larger scripts as functions but for now they exist as seperate utilities.

Especially - 
```
scripts/NetworkTroubleshooting.ps1
```
This file is a collection of various Powershell and OS commands/utilities for troubleshooting networks.

## Author

Karl Vietmeier
[@KarlVietmeier](https://twitter.com/karlvietmeier)

## Acknowledgments
My colleagues on the Windows Virtual Desktop GBB Team and PowerShell Guris at MSFT-<br>
  Adam Whitlach<br>
  John Kelbly<br>
  Marc Wolfson<br>
  John Jenner<br>
  Tim Dunn<br>


## References
Inspiration, code snippets, etc.
* [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)