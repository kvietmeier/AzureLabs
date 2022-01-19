###====================================================================================###
<# 
  Name: Cleanup-UnattachedPubIPs.ps1                                                                 
  Created By: Karl Vietmeier                                                     

  Status:  Working

  Description:
    Find and delete NICs - copied from:
    https://docs.microsoft.com/en-us/azure/virtual-machines/windows/find-unattached-disks

    Notes -     
    11/03/21: 
        Fixed incorrect $null references
        Broke out from disks script

    ToDo:
    Need to make this runnable interactively with a parameter to "show/remove".

#>                                                                        
###====================================================================================###
# Don't run - 
#return

# Stop on first error
$ErrorActionPreference = "stop"

# Run from the location of the script
Set-Location $PSscriptroot

### Get my functions and credentials
# Credentials  (stored outside the repo)
. 'C:\.info\miscinfo.ps1'

# Functions (In this repo)
. '.\FunctionLibrary.ps1'

# Imported from "FunctionLibrary.ps1"
# Are we connected to Azure with the correct SubID?
CheckLogin


###----- End my template

<### NOTE:
You will need to be logged into your Azure Subscription to run these commands.
Use these commands -
$AZCred = New-Object System.Management.Automation.PSCredential ($AIAuser, $SecurePasswd)
Connect-AzAccount -Credential $AZCred -Subscription $SubID
#>


# remove unattached Public IPs (PIP)
$deleteUnattachedPIPs=1
$AttachedIPs = Get-AzPublicIpAddress
foreach ($PIP in $AttachedIPs) {
        if(!$PIP.IpConfiguration) {
          if($deleteUnattachedPIPs -eq 1) {
            Write-Host "Deleting unattached IPs with Id: $($PIP.Id)"
            $PIP | Remove-AzPublicIpAddress -Force
            Write-Host "Deleted unattached IPs with Id: $($PIP.Id) "
            $PIP.id
        }
        else { $PIP.Id }
    }
}
