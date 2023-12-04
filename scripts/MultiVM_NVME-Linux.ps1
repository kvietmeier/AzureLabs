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

.DESCRIPTION
Will create multiple identical Linux VMs

.EXAMPLE
./CreateLinuxVM.ps1 -NumVMS 3 -NumDataDisks 2

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

# Looping Variables - number of VMs and Disks
# Set default to 3 VMs, with 2 disks each
param(
  [Parameter(Mandatory=$True,
    HelpMessage="Enter number of VMs to create",  
    Position=0)]
  [int]$NumVMs = "3",
  [Parameter(Mandatory=$True,
    HelpMessage="Enter number of Data Disks to create", 
    Position=1)]
  [int]$NumDataDisks = "2"
)

# Usage:
# ./CreateVoltVMs.ps1 -NumVMs "<num>" -NumDataDisk "<num>"

# Stop on first error
$ErrorActionPreference = "stop"

# Run from the location of the script
Set-Location $PSscriptroot


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
$VMSize         = "Standard_E2bds_v5"   # E#bds is required for NVMe
$DiskController = "NVMe"                # Choices - "SCSI" and "NVMe"
$VMPrefix       = "voltnode"
$DiskPrefix     = "datadisk"
$Zone           = "1"                   # Need for UltraSSD
$PPGName        = "VoltPPG"


#- You have to define VMs sizes for the PG if you use a zone."
#  Convert @Instances array to a "String[]"
$Instances=@("Standard_E2bds_v5", "Standard_E4bds_v5", "Standard_E8bds_v5", "Standard_E16bds_v5", "Standard_E32bds_v5")
$PPGAllowedVMSizes = [string[]]$Instances


# Process a cloud-init file
# Use the one I use for Terraform
$CloudinitFile  = "C:\Users\ksvietme\repos\Terraform\azure\secrets\cloud-init.voltdb"
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
  -IntentVMSizeList $PPGAllowedVMSizes `
  -Zone $Zone


Write-Host ""
Write-Host "###============================================================###" -ForegroundColor DarkBlue
Write-Host "                Creating Resource Group:" $ResourceGroup
Write-Host "               Creating Storage Account:" $VoltStorAcct.StorageAccountName
Write-Host "    Creating Proxinmity Placement Group:" $PPGName
Write-Host "                          Number of VMs:" $NumVMs
Write-Host "            Number of Data Disks per VM:" $NumDataDisks
Write-Host "###============================================================###" -ForegroundColor DarkBlue
Write-Host ""


###====================================================================================###
###                                VM Creation Loop                                    ###
###====================================================================================###

for ($i=1; $i -le $NumVMs; $i++) {
  
  ### Resource names uses RandomID so VMs are unique
  #   Create a 3 digit random ID for naming
  $RandomID = $(Get-Random -Minimum 100 -Maximum 200)

  # Name the VM and components
  $VMName         = "$VMPrefix-0$i"
  $DNSName        = "$VMPrefix-kv0$i"
  $PubIP          = "$VMPrefix-PubIP-0$i"
  $NICId          = "$VMPrefix-NIC-$RandomID"
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
  $NSG       = Get-AzNetworkSecurityGroup -ResourceGroupName $NsgRG -Name $NsgName

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