###====================================================================================###
<# 
  Name: CleanupUnattachedDisks.ps1                                                                 
  Created By: Karl Vietmeier                                                     

  Status:  Working

  Description:
    Find and delete disks - copied from:
    https://docs.microsoft.com/en-us/azure/virtual-machines/windows/find-unattached-disks


    Notes -     
    Added error checking for restricted blob stores

    08/13/21: 
        Added code to check for/remove NICs
        Fixed incorrect $null references

    ToDo:
    Need to rename - no longer just disks
    Need to make this runnable interactively with a parameter to "show/remove".

#>                                                                        
###====================================================================================###

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
Check-Login


###----- End my template

<### NOTE:

You will need to be logged into your Azure Subscription to run these commands.
Use these commands -
$AZCred = New-Object System.Management.Automation.PSCredential ($AIAuser, $SecurePasswd)
Connect-AzAccount -Credential $AZCred -Subscription $SubID

#>

function CheckManagedDisks () {

    Write-Host ""
    Write-Host "Checking for unattached Managed Disks"
    Write-Host ""

    # Set deleteUnattachedDisks=1 if you want to delete unattached Managed Disks
    # Set deleteUnattachedDisks=0 if you want to see the Id of the unattached Managed Disks
    $DeleteUnattachedDisks=0
    $ManagedDisks = Get-AzDisk
    foreach ($Disk in $ManagedDisks) {
        # ManagedBy property stores the Id of the VM to which Managed Disk is attached to
        # If ManagedBy property is $null then it means that the Managed Disk is not attached to a VM
        if($null = $Disk.ManagedBy) {
            if($DeleteUnattachedDisks -eq 1) {
                Write-Host "Deleting unattached Managed Disk with Id: $($Disk.Id)"
                $md | Remove-AzDisk -Force
                Write-Host "Deleted unattached Managed Disk with Id: $($Disk.Id) "
            }else{
                $Disk.Id
            }
        }
    }

# End Function
}

CheckManagedDisks

function CheckVHDInBlob () {
    Write-Host ""
    Write-Host "Checking for unattached VHD in blob storage"
    Write-Host ""

    ### Unmanaged Disks - 
    # Set deleteUnattachedVHDs=$true if you want to delete unattached VHDs
    # Set deleteUnattachedVHDs=$false if you want to see the Uri of the unattached VHDs
    $deleteUnattachedVHDs=$false
    $storageAccounts = Get-AzStorageAccount
    foreach($storageAccount in $storageAccounts){
        $storageKey = (Get-AzStorageAccountKey -ResourceGroupName $storageAccount.ResourceGroupName -Name $storageAccount.StorageAccountName)[0].Value
        $context = New-AzStorageContext -StorageAccountName $storageAccount.StorageAccountName -StorageAccountKey $storageKey
        
        $containers = Get-AzStorageContainer -Context $context -ErrorAction SilentlyContinue -ErrorVariable AccessError

        if ($AccessError) { Write-Output ($storageAccount.StorageAccountName + ":   Access Denied") }

        foreach($container in $containers){
            $blobs = Get-AzStorageBlob -Container $container.Name -Context $context
            #Fetch all the Page blobs with extension .vhd as only Page blobs can be attached as disk to Azure VMs
            $blobs | Where-Object {$_.BlobType -eq 'PageBlob' -and $_.Name.EndsWith('.vhd')} | ForEach-Object { 
                #If a Page blob is not attached as disk then LeaseStatus will be unlocked
                if($_.ICloudBlob.Properties.LeaseStatus -eq 'Unlocked'){
                        if($deleteUnattachedVHDs){
                            Write-Host "Deleting unattached VHD with Uri: $($_.ICloudBlob.Uri.AbsoluteUri)"
                            $_ | Remove-AzStorageBlob -Force
                            Write-Host "Deleted unattached VHD with Uri: $($_.ICloudBlob.Uri.AbsoluteUri)"
                        }
                        else{
                            $_.ICloudBlob.Uri.AbsoluteUri
                        }
                }
            } 
        }
    }

# End Function
}

CheckVHDInBlob

#---  Find NICs
function FindUnattachedNICs () {
    # Set deleteUnattachedNics=1 if you want to delete unattached NICs
    # Set deleteUnattachedNics=0 if you want to see the Id(s) of the unattached NICs
    $DeleteUnattachedNics=1

    $NICS = Get-AzNetworkInterface

    foreach ($NIC in $NICS) {
        if($null = $NIC.VirtualMachine) {
            if($deleteUnattachedNICS -eq 1){
                Write-Host "Deleting unattached NIC with Id: $($NIC.Id)"
                $NIC | Remove-AzDisk -Force
                Write-Host "Deleted unattached NIC with Id: $($NIC.Id)"
            }
            else{ $NIC.Id }
        # end if    
        }
    # end foreach    
    }

# End Function
}

FindUnattachedNICs