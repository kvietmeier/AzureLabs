###############################################################################################################
#
#  Code inteneded to access a running "gold image" VM and do the following:
#	1)  Shutdown the VM
#	2)  Create a new VHD and VM, SYSPREP shutdown
#	3)  Get the VHD somewhere (Shared image repo?  BLOB?)
#	4)  Stretch goal - create example code to make a WVD Pool
#
#  questions - johnkel at Microsoft.com
#
###############################################################################################################
#
#################################
# Azure Settings & other parms
#################################
#
$AZMasterVMname		= "Win10EntMulti"
$AZResourceGroup 	= "Infrastructure"
$AZSubscriptionID	= "54a24e15-5606-4fab-9ba3-9b5ec918afd9"
$vmNewName		= "1909-multi-o365"

#################################
#  Image Gallery settings 
#  Can change if you would like
#################################
$ImageGalleryName = "OurSharedImages"
$ImageName = "Win10withApps"


#added below for working with Azure Gov
#$ISGov			= $false
$ISGov			= $true


#################################
#Step 1 - Connect to Azure and find the Master Image
#################################
#
if ($ISGov) {
	Connect-AzAccount -EnvironmentName AzureUSGovernment 
} else { 
	Connect-AzAccount 
}

#Select the target subscription for the current session
Select-AzSubscription -SubscriptionId $AZSubscriptionID

$VMMaster = Get-AZVM -name $AZMasterVMname -Status
$Power = $VMMaster.powerstate

write-host "`nMaster Image VM:  $AZMasterVMname in State:  $Power"

while ($VMMaster.powerstate -ne "VM deallocated") {
	write-host "Master Image VM:  $AZMasterVMname Requesting Shutdown of VM"
	stop-AZVM -name $AZMasterVMname -ResourceGroupName $AZResourceGroup -force
	$VMMaster = Get-AZVM -name $AZMasterVMname -Status
	$Power = $VMMaster.powerstate
	write-host "Master Image VM:  $AZMasterVMname in State:  $Power`n"
}
	
#################################
#Step 2 - Create new VM / Snapshot disk / attach to new VM
#################################
# Below section adapted from
# https://dev.to/omiossec/using-powershell-to-rename-move-or-reconnect-an-azure-vm-i00

$NewVmObject = New-AzVMConfig -VMName $vmNewName -VMSize $VMMaster.HardwareProfile.VmSize

$subnetID = (Get-AzNetworkInterface -ResourceId $VMMaster.NetworkProfile.NetworkInterfaces[0].id).IpConfigurations.Subnet.id
$nic = New-AzNetworkInterface -Name "$($vmNewName.ToLower())-0-nic" -ResourceGroupName $VMMaster.ResourceGroupName  -Location $VMMaster.Location -SubnetId $SubnetId 
Add-AzVMNetworkInterface -VM $NewVmObject -Id $nic.Id

$SourceOsDiskSku = (get-azdisk -ResourceGroupName $VMMaster.ResourceGroupName -DiskName $VMMaster.StorageProfile.OsDisk.name).Sku.Name
$SourceOsDiskSnapConfig =  New-AzSnapshotConfig  -SourceUri $VMMaster.StorageProfile.OsDisk.ManagedDisk.Id -Location $VMMaster.Location -CreateOption copy
$SourceOsDiskSnap = New-AzSnapshot -Snapshot $SourceOsDiskSnapConfig  -SnapshotName "$($VMMaster.Name)-os-snap"  -ResourceGroupName $VMMaster.ResourceGroupName

$TargetOsDiskConfig = New-AzDiskConfig -AccountType $SourceOsDiskSku -Location $VMMaster.Location -CreateOption Copy -SourceResourceId $SourceOsDiskSnap.Id
$TargetOsDisk = New-AzDisk -Disk $TargetOsDiskConfig -ResourceGroupName $VMMaster.ResourceGroupName -DiskName "$($vmNewName.ToLower())-os-vhd"
Set-AzVMOSDisk -VM $NewVmObject -ManagedDiskId $TargetOsDisk.Id -CreateOption Attach -Windows

Foreach ($SourceDataDisk in $VMMaster.StorageProfile.DataDisks) { 
    $SourceDataDiskSku = (get-azdisk -ResourceGroupName $VMMaster.ResourceGroupName -DiskName $SourceDataDisk.name).Sku.Name
    $SourceDataDiskSnapConfig =  New-AzSnapshotConfig  -SourceUri $SourceDataDisk.ManagedDisk.Id -Location $VMMaster.Location -CreateOption copy
    $SourceDataDiskSnap = New-AzSnapshot -Snapshot $SourceDataDiskSnapConfig  -SnapshotName "$($VMMaster.Name)-$($SourceDataDisk.name)-snap"  -ResourceGroupName $VMMaster.ResourceGroupName
    $TargetDataDiskConfig = New-AzDiskConfig -AccountType $SourceDataDiskSku -Location $VMMaster.Location -CreateOption Copy -SourceResourceId $SourceDataDiskSnap.Id
    $TargetDataDisk = New-AzDisk -Disk $TargetDataDiskConfig -ResourceGroupName $VMMaster.ResourceGroupName -DiskName "$($vmNewName.ToLower())-$($SourceDataDisk.lun)-vhd"
    Add-AzVMDataDisk -VM $NewVmObject -Name "$($vmNewName.ToLower())-$($SourceDataDisk.lun)-vhd" -ManagedDiskId $TargetDataDisk.Id -Lun $SourceDataDisk.lun -CreateOption "Attach"
}

$TempVM = New-AzVM -VM $NewVmObject -ResourceGroupName $VMMaster.ResourceGroupName -Location $VMMaster.Location 


#################################
#Step 3 - Call Powershell Script to Sysprep 
#
#  Code creates a PowerShell script locally and invokes it on the remote VM before deleting the local copy
#
#  The file contains the following command line:
#
#	Start-Process -FilePath C:\Windows\System32\Sysprep\Sysprep.exe -ArgumentList ‘/generalize /oobe /shutdown /quiet’
#
#################################
break

### Build a command that will be run inside the VM.
#$remoteCommand =
#@"
#### Run SysPrep
#Start-Process -FilePath C:\Windows\System32\Sysprep\Sysprep.exe -ArgumentList ‘/generalize /oobe /shutdown /quiet’
#"@
### Save the command to a local file
#Set-Content -Path .\PshellSysprep.PS1 -Value $remoteCommand
### Invoke the command on the VM, using the local file
#Invoke-AzVMRunCommand -Name $vmNewName -ResourceGroupName $VMMaster.ResourceGroupName -CommandId 'RunPowerShellScript' -ScriptPath .\PshellSysprep.PS1
### Clean-up the local file
#Remove-Item .\PshellSysprep.PS1





#################################
#Step 4 - Change the VM state
#
#Have to deallocate the VM so we can update it
#(Sysprep doesn't deallocate when shutsdown) 
#
#################################


### Force Deallocation of VM and set the image to "Generalized"
Stop-AzVM -ResourceGroupName $AZResourceGroup -Name $TempVM.name -Force
Set-AzVm -ResourceGroupName $AZResourceGroup -Name $TempVM.name -Generalized


#################################
#Step 5 - Put image into Private Gallery 
#
#
#
#################################
###  Create image gallery if it is not already there
if ( get-azgallery | where {$_.Name -eq $ImageGalleryName} ) {
	"Gallery Found"
	$gallery = get-azgallery -ResourceGroupName $AZResourceGroup -GalleryName $ImageGalleryName
} Else {
	"Gallery Not Found - will create a new one" 
	$gallery = New-AzGallery  -GalleryName $ImageGalleryName -ResourceGroupName $AZResourceGroup -Location $VMMaster.Location -Description 'Shared Image Gallery for my organization'

### May also need to share the gallery, as per https://docs.microsoft.com/en-us/azure/virtual-machines/shared-images-powershell#share-the-gallery

}

### see if there is already an image / figure out next verion
if (Get-AzGalleryImagedefinition -ResourceGroupName $AZResourceGroup -GalleryName $ImageGalleryName | where {$_.Name -eq $ImageName}) 
{ 
	"An Image with that name already exists, will get version information and icrement..." 
	$imageDefinition = Get-AzGalleryImagedefinition -ResourceGroupName $AZResourceGroup  -GalleryName $ImageGalleryName -Name $ImageName
###
###  Need to pull existing image Version and increment
###  ADD MORE CODE!!!!

	$ImageVersion = '1.1.0'


} else { 
	"No Image Definition found - Creating one" 
	$imageDefinition = New-AzGalleryImageDefinition -GalleryName $gallery.Name -ResourceGroupName $AZResourceGroup -Location $VMMaster.Location -Name $ImageName -OsState Generalized -OsType Windows -Publisher $ImageGalleryName -Offer $ImageName -Sku $ImageName
	$ImageVersion = '1.0.0'
}


### Create Image version - https://docs.microsoft.com/en-us/azure/virtual-machines/image-version-vm-powershell#create-an-image-version
$region1 = @{Name=$VMMaster.Location;ReplicaCount=1}
$targetRegions = @($region1)

$job = $image = New-AzGalleryImageVersion -GalleryImageDefinitionName $imageDefinition.Name -GalleryImageVersionName $ImageVersion -GalleryName $gallery.Name -ResourceGroupName $gallery.ResourceGroupName -Location $gallery.Location -TargetRegion $targetRegions -Source $TempVM.Id.ToString() -PublishingProfileEndOfLifeDate '2020-12-01' -asJob 






Get-AzGalleryImageVersion -ResourceGroupName $AZResourceGroup -GalleryName $ImageGalleryName -GalleryImageDefinitionName $ImageName 


$TempVM = get-azvm -name 1909-multi-o365
$ImageVersion = '1.2.0'
$image = New-AzGalleryImageVersion -GalleryImageDefinitionName $imageDefinition.Name -GalleryImageVersionName $ImageVersion -GalleryName $gallery.Name -ResourceGroupName $gallery.ResourceGroupName -Location $gallery.Location -TargetRegion $targetRegions -Source $TempVM.Id.ToString() -PublishingProfileEndOfLifeDate '2020-12-01'
