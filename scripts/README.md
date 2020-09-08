## Scripts for working with Azure objects

Collection of scripts for working within Azure and with Windows Virtual Desktop. 


## Project Directories
```
├───scripts
│   └───users
│   └───examples
```

The "users" folder is a script I grabbed off GitHub to add users to AD.<br>
The "examples" folder has code snippets and scripts I have downloaded - they are not mine. 


### Usage
My scripts are "." sourcing 2 files, one is outside the repo and has variables with sensitive information
like GUIDs, SubscriptionIDs/Names, and certificates. The other is in this repo and is a library of common 
functions

They are accesed like this:
```
. '..\..\Certs\resources.ps1'
. '.\FunctionLibrary.ps1'
```

An example of the variables stored in the "resources.ps1" file:
```
# AIA Subscription Information
$SubID = "xxxxxxxx-xxxx-xxxx-xxxxxxxxxxxxxxxxx"
$SubName = "ASubscriptionName"
$AIAuser = "user@contoso.com"
$AIAPassword = "really should encrypt this"
```

Some of these "scripts" aren't meant to be run as a single script but are collections of useful 
commands and code snippets to be run interactively using the ISE or VSC.

Especially - 
```
scripts/NetworkTroubleshooting.ps1
```
and 
```
scripts/Setup PowerShell Modules.ps1
```

## Author

Karl Vietmeier
[@KarlVietmeier](https://twitter.com/karlvietmeier)

## Acknowledgments
My colleagues on the Windows Virtual Desktop GBB Team -<br>
  Adam Whitlach<br>
  John Kelbly<br>
  Marc Wolfson<br>
  John Jenner<br>


## References
Inspiration, code snippets, etc.
* [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)