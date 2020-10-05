###====================================================================================###
<# 
  Name: CleanupDisks.ps1                                                                 
  Created By: Karl Vietmeier                                                     

  Status:  Working

  Description:
    Find and delete disks - copied from:
    https://docs.microsoft.com/en-us/azure/virtual-machines/windows/find-unattached-disks

    Added error checking for restricted blob stores

#>                                                                        
###====================================================================================###

### Here for safety - comment/uncomment as desired
#return

### Get my functions and credentials
# Credentials  (stored outside the repo)
#. '..\..\Certs\resources.ps1'

# Functions (In this repo)
#. '.\FunctionLibrary.ps1'

# Imported from "FunctionLibrary.ps1"
# Are we connected to Azure with the corredt SubID?
#Check-Login

###----- End my template

<### NOTE:

You will need to be logged into your Azure Subscription to run these commands.
Use these commands -
$AZCred = New-Object System.Management.Automation.PSCredential ($AIAuser, $SecurePasswd)
Connect-AzAccount -Credential $AZCred -Subscription $SubID

#>

### Managed Disks - 
Write-Host ""
Write-Host "Checking for unattached Managed Disks"
Write-Host ""

# Set deleteUnattachedDisks=1 if you want to delete unattached Managed Disks
# Set deleteUnattachedDisks=0 if you want to see the Id of the unattached Managed Disks
$deleteUnattachedDisks=0
$managedDisks = Get-AzDisk
foreach ($md in $managedDisks) {
    # ManagedBy property stores the Id of the VM to which Managed Disk is attached to
    # If ManagedBy property is $null then it means that the Managed Disk is not attached to a VM
    if($md.ManagedBy -eq $null){
        if($deleteUnattachedDisks -eq 1){
            Write-Host "Deleting unattached Managed Disk with Id: $($md.Id)"
            $md | Remove-AzDisk -Force
            Write-Host "Deleted unattached Managed Disk with Id: $($md.Id) "
        }else{
            $array = @("$md.ResourceGroupName", "$md.Location", "$md.Name")
            $md.ResourceGroupName
            $md.Location
            $md.Name
            $array
        }
    }
 }

<# 
$deleteUnattachedDisks=0
$managedDisks = Get-AzDisk
foreach ($md in $managedDisks) {
    # ManagedBy property stores the Id of the VM to which Managed Disk is attached to
    # If ManagedBy property is $null then it means that the Managed Disk is not attached to a VM
    if($md.ManagedBy -eq $null){
        if($deleteUnattachedDisks -eq 1){
            Write-Host "Deleting unattached Managed Disk with Id: $($md.Id)"
            $md | Remove-AzDisk -Force
            Write-Host "Deleted unattached Managed Disk with Id: $($md.Id) "
        }else{
            $md.Id
        }
    }
 }
#>

