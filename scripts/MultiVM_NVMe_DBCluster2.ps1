###===================================================================================###
#   Copyright (C) 2022 Intel Corporation
#   SPDX-License-Identifier: Apache-2.0
###====================================================================================###
<# 
  Created By: Karl Vietmeier
                                                                    
  Status:  Working, tested
#>
###====================================================================================###
<#
.SYNOPSIS
Create a group of indentical Linux VMs with the following characteristics
 * NVME Enabled
 * UltraSSD attached
 * Public IP w/DNS name
 * In a Proximity Placement Group
 * Uses a detailed cloud-init file for OS configuration - takes at least 4-5 minutes to complete
 * Using existing resouces:
   - Dedicated vNet peered to a hub vnet
   - NSG that filters on incoming IP address
 * This version creates an additional "mgmt" VM.

.DESCRIPTION
Will prompt the user to choose an Instance type and a number of VMs with a fixed number of data disks
The script then builds a set of VMs to be used for a DB cluster.

.EXAMPLE
Run the script to be prompted

.NOTES
General notes
*** This script assumes you are already authenticated to Azure in your PowerShell console ***
    - I configure $VMCred as an environment variable
    - You can uncomment the $VMCred section to configure it in this script 
  
Resources:
  https://docs.microsoft.com/en-us/powershell/module/az.compute/new-azvm?view=azps-4.6.1
  https://docs.microsoft.com/en-us/powershell/module/az.compute/new-azvmconfig?view=azps-4.7.0
  https://docs.microsoft.com/en-us/azure/virtual-machines/windows/cli-ps-findimage

The logic of this may seem odd - but with PowerShell you create the components of the VM then update 
a VMConfiguration as a PSObect with each component then at the end you roll it all up in one 
simple "Create VM" commamd.

This is a common PS method for Azure resources - you create a configuration object then use that 
configuration to create one or more instances of the object/s.

#>

# Push old output up the screen a llittle
foreach($i in 1..10){
  Write-Host ""
}

# Stop on first error
$ErrorActionPreference = "stop"

# Run from the location of the script
Set-Location $PSscriptroot


###====================================================================================###
###            Create Menus to choose instance type and Num DB Nodes                   ###
###====================================================================================###
# Looping Variables - number of VMs and Disks Pick an instance type amd number of VMs
# Setup Menu
#$NumberOfVMs=@("1", "2", "3", "4", "5", "6", "7", "8", "9", "10")
#$NumDisks=@("1", "2", "3")

# Instances Menu - 
$Instances=@("Standard_E2bds_v5", "Standard_E4bds_v5", "Standard_E8bds_v5", "Standard_E16bds_v5", "Standard_E32bds_v5")
$global:selection = $null
do {
  Write-Host "What Instance Type are we using?"
  
  for ($i=0; $i -lt $Instances.count; $i++) {
    Write-Host -ForegroundColor Cyan " $($i+1)." $Instances[$i]
  }
  
  Write-Host
  $global:ans = (Read-Host 'Choose an Instance') -as [int]


} while ((-not $ans) -or (0 -gt $ans) -or ($Instances.count -lt $ans))

$global:selection = $Instances[$ans - 1]
$VMSize = $global:selection

# How many VMs?
Write-Host ""
$VMPrompt = "How Many Database Nodes? (choose between 3 and 11)"
#Write-Host "$NumVMs" -ForegroundColor Cyan

$InputBlock = {
  try {

    $InputNumVMs = [int](Read-Host -Prompt $VMPrompt)

    if ($InputNumVMs -le 2) {
      Write-Host "Must be greater than 2 VMs"
      & $Inputblock
    }
    elseif ($InputNumVMs -ge 12) {
      Write-Host "Cluster size is less than 12"
      & $Inputblock
    }
    else {
      $InputNumVMs
    }

  }
  catch {
    Write-Host "Number of VMs has to be a number"
    & $Inputblock
  }
}

# Get the correct number
$NumVMs = & $InputBlock


# Going to hard code number of disks for now
Write-Host ""
[int]$NumDataDisks = "2"

# Output Summary - using -NoNewLine lets you use more than one color on a line
Write-Host "Creating a DB cluster with:" -ForegroundColor Green
Write-Host "   Instance Type   = " -NoNewline 
Write-Host "$VMSize" -ForegroundColor Cyan
Write-Host "   Number of nodes = " -NoNewline
Write-Host "$NumVMs" -ForegroundColor Cyan
Write-Host "Number of NVME SSD = " -NoNewline
Write-Host "$NumDataDisks" -ForegroundColor Cyan


###====================================================================================###
###                                    End Menus                                       ###
###====================================================================================###

<#
###====================================================================================###
###                              Variable Definitions                                  ###
###====================================================================================###

# Use existing network resources: vNet, Subnet, NSG - set to your own
$Region         = "westus2"
$vNetName       = "testingvnet01-wsu2"
$vNetRG         = "CommonResources-WestUS2"
$NsgName        = "WUS2-InboundNSG"
$NsgRG          = "z_nsg-WUS2-Managed"

# Image Definitions
# Ubuntu - add "-gen2" to create a Gen2 VM
$PublisherName  = "Canonical"
$Offer          = "0001-com-ubuntu-server-focal"
$SKU            = "20_04-lts-gen2"
$Version        = "latest"

# VM Config Parameters 
$ResourceGroup  = "TMP-VoltTesting"
#$VMSize         = "Standard_E2bds_v5"   # E#bds is required for NVMe
#$VMSize         = "Standard_E4bds_v5"
$VMSize         = "Standard_E8bds_v5"
#$VMSize         = "Standard_E16bds_v5"
#$VMSize         = "Standard_E32bds_v5"
$DiskController = "NVMe"                # Choices - "SCSI" and "NVMe"
$VMPrefix       = "vdb"
#$MgmtVMName     = "voltmgmt"
$MgmtVMSize     = "Standard_D2ds_v5"
$DiskPrefix     = "datadisk"
$Zone           = "1"                   # Need for UltraSSD
$PPGName        = "VoltPPG"

# You have to define VMs sizes for the PG if you use a zone.
$VMSizesGP      = "Standard_D2ds_v5"
$VMSizes2       = "Standard_E2bds_v5"
$VMSizes4       = "Standard_E4bds_v5"
$VMSizes8       = "Standard_E8bds_v5"
$VMSizes16      = "Standard_E16bds_v5"
$VMSizes32      = "Standard_E32bds_v5"

# Process a cloud-init file
# Use the one I use for Terraform
$CloudinitFile  = "C:\Users\ksvietme\repos\Terraform\azure\secrets\cloud-init.voltdb"
$Bytes          = [System.Text.Encoding]::Unicode.GetBytes((Get-Content -raw $CloudinitFile))
$CloudInit      = (Get-Content -raw $CloudinitFile)


###====================================================================================###
###              You shouldn't need to modify the script below this line.              ###
###                                                                                    ###
###                                                                                    ###


###====================================================================================###
###           Proximity Placement Group, Resource Group and Storage Account            ###
###====================================================================================###

# If it doesn't exist - Create the resource group for the VM and resources
Get-AzResourceGroup -Name $ResourceGroup `
  -ErrorVariable NotExist `
  -ErrorAction SilentlyContinue

if ($NotExist) {
  New-AzResourceGroup -Name $ResourceGroup -Location $Region | Out-Null
} else { Write-Host "Using Resourcegroup:" $ResourceGroup }

# SAs have to be unique
$RandomStorageACCT = $(Get-Random -Minimum 10000 -Maximum 90000)

# Create a throw away SA for boot diags amd managed disks
New-AzStorageAccount -ResourceGroupName $ResourceGroup `
  -Name deleteme${RandomStorageACCT} `
  -Location $Region `
  -SkuName Standard_LRS `
  -Kind StorageV2 | Out-Null

# Store the PS Object
$VoltStorAcct = Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name deleteme${RandomStorageACCT} 

# For DB testing we need a Proximity Group - Zone requires defining VM sizes
$PPG = New-AzProximityPlacementGroup `
  -Location $Region `
  -Name $PPGName `
  -ResourceGroupName $ResourceGroup `
  -ProximityPlacementGroupType Standard `
  -IntentVMSizeList $VMSizes2, $VMSizes4, $VMSizes8, $VMSizes16, $VMSizes32, $VMSizesGP `
  -Zone $Zone

# Shift forward so the Management VM is -01 (important in later loop)
$NumVMs++

Write-Host ""
Write-Host "###============================================================###" -ForegroundColor DarkBlue
Write-Host "                Creating Resource Group:" $ResourceGroup
Write-Host "               Creating Storage Account:" $VoltStorAcct.StorageAccountName
Write-Host "    Creating Proxinmity Placement Group:" $PPGName
Write-Host "                          Number of VMs:" $NumVMs
Write-Host "            Number of Data Disks per VM:" $NumDataDisks
Write-Host "###============================================================###" -ForegroundColor DarkBlue
Write-Host ""

###===============================  Create Mgmt VM   ================================###
###    Volt needs an "extra" VM                                                      ###
###    This is a hack, the right way would be to create a hash of VM definitions.    ###

### Resource names uses RandomID so VMs are unique
#   Create a 3 digit random ID for naming
$RandomID1 = $(Get-Random -Minimum 100 -Maximum 200)

# Name the VM and components - a little hard coded - we want the mgmt VM to be the first one
$VMName         = "$VMPrefix-01"
$DNSName        = "$VMPrefix-kv01"
$PubIP          = "$VMPrefix-PubIP-$VMName"
$NICId          = "$VMName-NIC-$RandomID1"
$IPConfig       = "$VMName-IPcfg"

Write-Host ""
Write-Host "###============================================================###" -ForegroundColor DarkBlue
Write-Host "    Creating Management VM:" $VMname
Write-Host "###============================================================###" -ForegroundColor DarkBlue
Write-Host ""

# Set basic parameters VM Name and Size for new VM object
# https://learn.microsoft.com/en-us/powershell/module/az.compute/new-azvmconfig?view=azps-10.1.0
# Set -vCPUCountPerCore to 1 to disable hyperthreading
  
$NewVMConfig = New-AzVMConfig -VMName $VMName `
  -VMSize $MgmtVMSize `
  -ProximityPlacementGroupId $PPG.Id `
  -Zone $Zone 


###===================== Create the NIC Configuration ========================###
#               Use existing testing vNet already peered to hub                 #
#                 subnet has an NSG managed through Terraform                   #
  
$vNet      = Get-AzVirtualNetwork -Name $vNetName -ResourceGroupName $vNetRG
$SubNetCfg = Get-AzVirtualNetworkSubnetConfig -ResourceId $vNet.Subnets[0].Id

# The subnet already has an NSFG associated
#$NSG       = Get-AzNetworkSecurityGroup -ResourceGroupName $NsgRG -Name $NsgName

# Create a new static Public IP and assign a DNS record
$PIP = New-AzPublicIPAddress `
  -Name $PubIP `
  -ResourceGroupName $ResourceGroup `
  -Sku Standard `
  -AllocationMethod Static `
  -DomainNameLabel $DNSName `
  -Location $Region `
  -Zone $Zone

# Start building the NIC configuration - Subnet and Public IP
$NewIPConfig = New-AzNetworkInterfaceIpConfig -Name $IPConfig -Subnet $SubNetCfg -PublicIpAddress $PIP -Primary 

# Create the NIC using the PS Objects - enable accelerated networking
# Technically don't need NSG here - it is bound to the existing subnet in use
$VMNIC = New-AzNetworkInterface `
  -Name $NICId `
  -ResourceGroupName $ResourceGroup `
  -Location $Region `
  -EnableAcceleratedNetworking `
  -IpConfiguration $NewIPConfig

# Add the NIC to the VM Configuration
Add-AzVMNetworkInterface -VM $NewVMConfig -Id $VMNIC.Id

###--======================= End NIC Configuration ===========================###
  
# Setup Bootdiags for serial console access
$NewVMConfig = Set-AzVMBootDiagnostic `
 -VM $NewVMConfig `
 -Enable `
 -ResourceGroupName $ResourceGroup `
 -StorageAccountName $VoltStorAcct.StorageAccountName

# OS definition and credentials for user  -Credential are pulled from an $Env variable.
$NewVMConfig = Set-AzVMOperatingSystem `
 -VM $NewVMConfig `
 -Linux `
 -ComputerName $VMName `
 -CustomData $CloudInit `
 -Credential $VMCred

# Source Image
$NewVMConfig = Set-AzVMSourceImage `
 -VM $NewVMConfig `
 -PublisherName $PublisherName `
 -Offer $Offer `
 -Skus $SKU `
 -Version $Version


###----> Create the Management VM using info in the layered config above
 
New-AzVM -ResourceGroupName $ResourceGroup -Location $Region -VM $NewVMConfig | Out-Null
 
###---  END 


###====================================================================================###
###                                VM Creation Loop                                    ###
###                              Create the Cluster VMs                                ###
###====================================================================================###

for ($i=2; $i -le $NumVMs; $i++) {
  
  ### Resource names uses RandomID so VMs are unique
  #   Create a 4 digit random ID for naming
  $RandomID2 = $(Get-Random -Minimum 1000 -Maximum 10000)

  # Name the VM and components
  $VMName         = "$VMPrefix-0$i"
  $DNSName        = "$VMPrefix-kv0$i"
  $PubIP          = "$VMPrefix-PubIP-0$i"
  $NICId          = "$VMName-NIC-$RandomID2"
  $IPConfig       = "$VMPrefix-IPcfg-0$i"

  Write-Host ""
  Write-Host "###============================================================###" -ForegroundColor DarkBlue
  Write-Host "    Creating VM:" $VMname
  Write-Host "###============================================================###" -ForegroundColor DarkBlue
  Write-Host ""

  # Set basic parameters VM Name and Size for newe VM object
  # https://learn.microsoft.com/en-us/powershell/module/az.compute/new-azvmconfig?view=azps-10.1.0
  # Set -vCPUCountPerCore to 1 to disable hyperthreading
  
  $NewVMConfig = New-AzVMConfig -VMName $VMName `
    -VMSize $VMSize `
    -DiskControllerType $DiskController `
    -EnableUltraSSD `
    -ProximityPlacementGroupId $PPG.Id `
    -Zone $Zone 


  ###===================== Create the NIC Configuration ========================###
  #               Use existing testing vNet already peered to hub                 #
  
  $vNet      = Get-AzVirtualNetwork -Name $vNetName -ResourceGroupName $vNetRG
  $SubNetCfg = Get-AzVirtualNetworkSubnetConfig -ResourceId $vNet.Subnets[0].Id

  # Don't need this there is already an NSG attached to the subnet
  #$NSG       = Get-AzNetworkSecurityGroup -ResourceGroupName $NsgRG -Name $NsgName

  # Create a new static Public IP and assign a DNS record
  $PIP = New-AzPublicIPAddress `
    -Name $PubIP `
    -ResourceGroupName $ResourceGroup `
    -Sku Standard `
    -AllocationMethod Static `
    -DomainNameLabel $DNSName `
    -Location $Region `
    -Zone $Zone

  # Start building the NIC configuration - Subnet and Public IP
  $NewIPConfig = New-AzNetworkInterfaceIpConfig -Name $IPConfig -Subnet $SubNetCfg -PublicIpAddress $PIP -Primary 

  # Create the NIC using the PS Objects - enable accelerated networking
  # Technically don't need NSG here - it is bound to the existing subnet in use
  $VMNIC = New-AzNetworkInterface `
    -Name $NICId `
    -ResourceGroupName $ResourceGroup `
    -Location $Region `
    -EnableAcceleratedNetworking `
    -IpConfiguration $NewIPConfig

  # Add the NIC to the VM Configuration
  Add-AzVMNetworkInterface -VM $NewVMConfig -Id $VMNIC.Id

  ###--======================= End NIC Configuration ===========================###
  

  ###===========================================================================###
  ###                         Create Disks For DB                               ###
  ###                        Define, Create, Attach                             ### 
  ###===========================================================================###
  
  # Create disks if $NumDataDisk > 0
  if ( $NumDataDisks -gt 0 ) {
    # Create the disks
    for ($Disk=1; $Disk -le $NumDataDisks; $Disk++) {
  
      $DiskName = "$DiskPrefix-$Disk-$VMName"
      $LUN      = $Disk + 10
    
      # Setup UltraSSD disk configuration "-AccountType UltraSSD_LRS"
      $DataDiskConfig = New-AzDiskConfig `
        -Location $Region `
        -Zone $Zone `
        -AccountType UltraSSD_LRS `
        -CreateOption Empty `
        -DiskSizeGB 256 

      # Create new disk
      $DataDisk = New-AzDisk `
        -ResourceGroupName $ResourceGroup `
        -DiskName $DiskName `
        -Disk $DataDiskConfig
    
      # Add disk to the VM config
      $NewVMConfig = Add-AzVMDataDisk `
        -VM $NewVMConfig `
        -Name $DiskName `
        -CreateOption Attach `
        -Lun $LUN `
        -ManagedDiskId $DataDisk.id
    }
  }

  ###==================== End Create Disks For DB ==============================###
  

  # Setup Bootdiags for serial console access
  $NewVMConfig = Set-AzVMBootDiagnostic `
    -VM $NewVMConfig `
    -Enable `
    -ResourceGroupName $ResourceGroup `
    -StorageAccountName $VoltStorAcct.StorageAccountName

  # OS definition and credentials for user  -Credential are pulled from an $Env variable.
  $NewVMConfig = Set-AzVMOperatingSystem `
    -VM $NewVMConfig `
    -Linux `
    -ComputerName $VMName `
    -CustomData $CloudInit `
    -Credential $VMCred

  # Source Image
  $NewVMConfig = Set-AzVMSourceImage `
    -VM $NewVMConfig `
    -PublisherName $PublisherName `
    -Offer $Offer `
    -Skus $SKU `
    -Version $Version


  ###----> Create the VM using info in the layered config above
  
  New-AzVM -ResourceGroupName $ResourceGroup -Location $Region -VM $NewVMConfig | Out-Null
  
  ###

}
###=============================  END Create VM Loop   ==============================###


Write-Host ""
Write-Host "###====================###" -ForegroundColor Red
Write-Host ""
Write-Host "To delete these resources use: Remove-AzResourceGroup -Name $ResourceGroup -Force"
Write-Host ""
Write-Host "###====================###" -ForegroundColor Red
Write-Host ""


###============================= Misc Notes
<# 
###--- Use an Image from a Shared Image Gallery
# Windows 10 2004 Enterprise
#$ImageGallery   = "/subscriptions/" + $SubID + "/resourceGroups/ImageGallery-rg/providers/Microsoft.Compute/galleries/ClientImages"
#$ImageID        = "/images/Win10Enterprise-Tools/versions/1.0.0"
$GalleryName    = "ClientImages"
$GalleryRG      = "ImageGallery-rg"
$ImageName      = "Win10Enterprise-Tools"

$ImageDefinition = Get-AzGalleryImageDefinition `
   -GalleryName $GalleryName `
   -ResourceGroupName $GalleryRG `
   -Name $ImageName
#>


#>