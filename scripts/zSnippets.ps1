###====================================================================================###
<# 
  Snippets.ps1                   
    Created By: Karl Vietmeier    
                                 
  Description                   
    Misc bits and pieces       
#>           
###====================================================================================###

### Here for safety - comment/uncomment as desired
return

### Get my functions and credentials
Set-Location  $AzScriptDir
# Credentials  (stored outside the repo)
. 'C:\.info\miscinfo.ps1'

# Functions (In this repo)
. '.\FunctionLibrary.ps1'

# In my profile scripts - 
# Are we connected to Azure with the corredt SubID?
AZConnectSP

###====================================================================================###

#### - testing this 
<# if ((Get-Item -Path ".").Property -contains 'Enabled')
{
    Set-ItemProperty -Path "." -Name  "Enabled" -PropertyType "DWORD" -Value "1"
}
else {
    New-ItemProperty -Path "." -Name  "Enabled" -PropertyType "DWORD" -Value "1"
} #>

# Use a range 
$range = 1..100
ForEach ($number in $range) {
    $samaccountname = "user{0:00}" -f $number
    $samaccountname
}

# Checking env variables using "Test-Path"
if (-not (Test-Path env:FOO)) { $env:FOO = 'bar' }
if (-not (Test-Path env:FOO)) {
   continue
}
else { 
    Remove-Item Env:FOO
    Write-Host "Unsetting FOO"
}



# Make sure you have the latest WVD PowerShell module installed
Install-Module -Name Az.DesktopVirtualization -MinimumVersion 2.1.0

###====================================================================================###
###----- RDP settings
# https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/clients/rdp-files

$AZResourceGroup = "TempRG-01"
$AppGroup = "TestLogin-DAG"


# Use Update-AzWvdHostPool
Update-AzWvdHostPool -ResourceGroupName ResourceGroupName `
    -Name HostPoolName `
    -LoadBalancerType 'BreadthFirst' `
    -Description 'Description' `
    -FriendlyName 'Friendly Name' `
    -MaxSessionLimit 6 `
    -SsoContext $null `
    -CustomRdpProperty $null `
    -Ring $null `
    -ValidationEnvironment:$false


Update-AzWvdHostPool -ResourceGroupName Test-rg -Name Testpool -CustomRdpProperty "audiocapturemode:i:1;use multimon:i:0"
 # Or - 
$properties="audiocapturemode:i:1;use multimon:i:0"
Update-AzWvdHostPool -ResourceGroupName $AZResourceGroup -Name TestPool01 -CustomRdpProperty $properties

# Clear everything
Get-AzWvdHostPool -ResourceGroupName $AZResourceGroup -Name TestPool01 | format-list Name, CustomRdpProperty

###====================================================================================###
###--- Misc HostPool Commands
###====================================================================================###
Get-AzWvdHostPool -ResourceGroupName $AZResourceGroup
Get-AzWvdHostPool -ResourceGroupName $AZResourceGroup -Name TestPool01
Get-AzWvdApplicationGroup -ResourceGroupName $AZResourceGroup
Get-AzWvdApplicationGroup -ResourceGroupName $AZResourceGroup -Name $AppGroup | format-list Name
Remove-AzWvdApplicationGroup -ResourceGroupName $AZResourceGroup -Name $AppGroup
Remove-AzWvdHostPool -ResourceGroupName TempRG-01 -Name Foobar02

$ResourceGroup  = "WVDLandscape02-WSL"
$HostPool       = "PersonalDesktops"

###--- For enabling Start VM on Connect use the following:
Update-AzWvdHostPool `
    -ResourceGroupName $ResourceGroup `
    -Name $HostPool `
    -StartVMOnConnect:$true

# For disabling Start VM on Connect use the following:
Update-AzWvdHostPool `
    -ResourceGroupName $ResourceGroup `
    -Name $HostPool `
    -StartVMOnConnect:$false

###------------------



###====================================================================================###
### Remove OneDrive Components
###====================================================================================###
Taskkill.exe /F /IM "OneDrive.exe"
Taskkill.exe /F /IM "Explorer.exe"`

if (Test-Path "C:\\Windows\\System32\\OneDriveSetup.exe") {
    Start-Process "C:\\Windows\\System32\\OneDriveSetup.exe"`
     -ArgumentList "/uninstall"`
     -Wait
}
if (Test-Path "C:\\Windows\\SysWOW64\\OneDriveSetup.exe") {
    Start-Process "C:\\Windows\\SysWOW64\\OneDriveSetup.exe"`
      -ArgumentList "/uninstall"`
      -Wait 
}

Remove-Item -Path "C:\\Windows\\ServiceProfiles\\LocalService\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\Programs\\OneDrive.lnk" -Force

# Remove the automatic start item for OneDrive from the default user profile registry hive
Remove-Item -Path "C:\\Windows\\ServiceProfiles\\NetworkService\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\Programs\\OneDrive.lnk" -Force 
Start-Process C:\\Windows\\System32\\Reg.exe -ArgumentList "Load HKLM\\Temp C:\\Users\\Default\\NTUSER.DAT" -Wait
Start-Process C:\\Windows\\System32\\Reg.exe -ArgumentList "Delete HKLM\\Temp\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run /v OneDriveSetup /f" -Wait
Start-Process C:\\Windows\\System32\\Reg.exe -ArgumentList "Unload HKLM\\Temp" -Wait Start-Process -FilePath C:\\Windows\\Explorer.exe -Wait

###----------------


###====================================================================================###
###---- Snapshots
# https://docs.microsoft.com/en-us/azure/virtual-machines/windows/snapshot-copy-managed-disk

# Vars
$ResourceGroupName = 'WVDLandScape01' 
$Region = 'westus2' 
$vmName = 'testvm-1'
$SnapshotName = 'TestSnapshot01'

# Get the VM info
$vm = Get-AzVM `
    -ResourceGroupName $ResourceGroupName `
    -Name $vmName

# Create the SS Config
$snapshot =  New-AzSnapshotConfig `
    -SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id `
    -Location $Region `
    -CreateOption copy

# Take the SS
New-AzSnapshot `
    -Snapshot $snapshot `
    -SnapshotName $SnapshotName `
    -ResourceGroupName $ResourceGroupName



### Create incremental snapshot
$diskName = "yourDiskNameHere>"
$resourceGroupName = "yourResourceGroupNameHere"
$snapshotName = "yourDesiredSnapshotNameHere"

# Get the disk that you need to backup by creating an incremental snapshot
$yourDisk = Get-AzDisk -DiskName $diskName -ResourceGroupName $resourceGroupName

# Create an incremental snapshot by setting the SourceUri property with the value of the Id property of the disk
$snapshotConfig=New-AzSnapshotConfig -SourceUri $yourDisk.Id -Location $yourDisk.Location -CreateOption Copy -Incremental 
New-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snapshotName -Snapshot $snapshotConfig


### List snapshots
$snapshots = Get-AzSnapshot -ResourceGroupName $ResourceGroupName
$snapshots = Get-AzSnapshot -ResourceGroupName WVDLandscape01

$incrementalSnapshots = New-Object System.Collections.ArrayList

foreach ($snapshot in $snapshots)
{
    
    if($snapshot.Incremental -and $snapshot.CreationData.SourceResourceId -eq $yourDisk.Id -and $snapshot.CreationData.SourceUniqueId -eq $yourDisk.UniqueId){

        $incrementalSnapshots.Add($snapshot)
    }
}

$incrementalSnapshots


###====================================================================================###
###----  Find unattached disks
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
            $md.Id
            $1, $2, $sub, $4, $RG, $6, $7, $8, $DiskID   = $md.Id -split "/", 9
            <# 
            $properties = @{
                DiskName = $DiskID
                ResourceGroup = $RG
                Subscription = $sub
            }
            New-Object -TypeName PSCustomObject -Property $properties | Format-Table
 #>
            #Write-Host ($DiskID, $RG, $sub) -Separator "             "
        }
    }
 }

 
###====================================================================================###
Function GetStorageAcctKeys   
{  
    $ResourceGroup  = "WVDLandScape01"   
    $StorageAccount = "kv82579msix01"

    Write-Host -ForegroundColor Green "Retrieving the storage accounts keys for $StorageAccount..."  

    <# Grab the storage account keys  
         .Value[0] = key1; .Value[1] = key2; .Value[2] = kerb1; .Value[3] = kerb2
    #>
    $StorAccounts  = Get-AzStorageAccount  
    $StorAcctKey1  = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroup -Name $storageAccount -ListKerbKey).Value[0]  
    $StorAcctKey2  = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroup -Name $storageAccount -ListKerbKey).Value[0]  
    $StorAcctKerb1 = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroup -Name $storageAccount -ListKerbKey).Value[0]  
    $StorAcctKerb2 = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroup -Name $storageAccount -ListKerbKey).Value[0]  
  
    Write-Host -ForegroundColor Yellow "Key 1: " $StorAcctKey1  
    Write-Host -ForegroundColor Yellow "Key 2: " $StorAcctKey2  
    Write-Host -ForegroundColor Yellow "Kerb1: " $StorAcctKerb1  
    Write-Host -ForegroundColor Yellow "Kerb2: " $StorAcctKerb2  
  
}
GetStorageAcctKeys

function ResetStorageAcctKeys
{
   # Be very careful with this process - you will need to update the keys everywhere 
   # they are used after this
   $ResourceGroup  = "WVDLandScape01"   
   $StorageAccount = "kv82579msix01"

   Write-Host -ForegroundColor Green "Refreshing the storage accounts key (2)..."  
 
   ## Refresh the storage account key 2  
   New-AzStorageAccountKey -ResourceGroupName $ResourceGroup -Name $StorageAccount -KeyName key2  
 
   ## Retrive the new storage account key 2  
   $StorAcctKey2= (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroup -Name $StorageAccount).Value[1]  
   Write-Host -ForegroundColor Yellow "Storage Account Key 2: " $storAcctKey2          
}


# Uncomment if you want a new key - if you reset kerb1, anything using it will have to be updated
#New-AzStorageAccountKey -ResourceGroupName $AZResourceGroup -name $AZStorageAccountName -KeyName kerb1

<### Grab key1
  .Value[0] = key1; .Value[1] = key2; .Value[2] = kerb1; .Value[3] = kerb2
#>
$StorageAcctKey = (Get-AzStorageAccountKey -ResourceGroupName $AZResourceGroup -Name $AZStorageAccountName -ListKerbKey).Value[0]

# Create the computer account password using the storage account key
$CompPassword = $StorageAcctKey | ConvertTo-Securestring -asplaintext -force

<#
# Use User/Pass credentials stored in a secure variable sourced from another file
$securepasswd = ConvertTo-SecureString $AZPassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($AZUser, $securepasswd)
Connect-AzAccount -Credential $cred -Subscription $SubID
#>
        
# Change subscription context (May not need this)

## OLD Version
function Check-Login ()
{

    $context = Get-AzContext
    Write-Host "Is my AZ Account Connected?" 

    if (!$context -or ($context.Subscription.Id -ne $SubID)) 
    {
        # Save your creds
        $creds = get-credential
        Connect-AzAccount -Credential $creds -Subscription $SubID
        
        # Change subscription context (May not need this)
        Select-AzSubscription -SubscriptionId $SubName
    } 
    else 
    {
        Write-Host "SubscriptionId '$SubID' already connected"
    }
}

Select-AzSubscription -SubscriptionId $SubName

