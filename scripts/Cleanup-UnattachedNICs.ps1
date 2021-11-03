###====================================================================================###
<# 
  Name: Cleanup-UnattachedNICs.ps1                                                                 
  Created By: Karl Vietmeier                                                     

  Status:  Not Working

  Description:
    Find and delete NICs - copied from:
    https://docs.microsoft.com/en-us/azure/virtual-machines/windows/find-unattached-disks


    Notes -     
    Added error checking for restricted blob stores

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

#---  Find NICs
function FindUnattachedNICs () {
    # Set deleteUnattachedNics=1 if you want to delete unattached NICs
    # Set deleteUnattachedNics=0 if you want to see the Id(s) of the unattached NICs
    $DeleteUnattachedNics=0

    $NICS = Get-AzNetworkInterface

    foreach ($NIC in $NICS) {
        if(!$NIC.VirtualMachine) {
            if($deleteUnattachedNICS -eq 1){
                Write-Host "Deleting unattached NIC with Id: $($NIC.Id)"
                $NIC | Remove-AzDisk -Force
                Write-Host "Deleted unattached NIC with Id: $($NIC.Id)"
            }
        # end if    
        }
        else{ $NIC.VirtualMachine }
    # end foreach    
    }

# End Function
}

FindUnattachedNICs