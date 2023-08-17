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
Create a Linux VM

.DESCRIPTION
Can create multiple identical Linux VMs with attached SCSI data disks

.EXAMPLE
With Placement group
./CreateLinuxVM.ps1 -NumVMS 1 -NumDataDisks 0 -UsePPG

Without Placement group
./CreateLinuxVM.ps1 -NumVMS 1 -NumDataDisks 0

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
a VMConfiguration as a PSObect then at the end you roll it all up in one simple "Create VM" commamd.

This is a common PS method for Azure resources - you create a configuration object then use that 
configuration to create one or more instances of the object/s.

#>

# Set default to 1 VM, with 0 disks
param(
  [Parameter(Mandatory=$True,
    HelpMessage="Enter number of VMs to create",  
    Position=0)]
  [int]$NumVMs = "1",
  [Parameter(Mandatory=$True,
    HelpMessage="Enter number of Data Disks to create", 
    Position=1)]
  [int]$NumDataDisks = "0",
  [Parameter(Position=2)]
  [switch]$UsePPG = $False
)

# Stop on first error
$ErrorActionPreference = "stop"

# Run from the location of the script
Set-Location $PSscriptroot

###====================================================================================###
###                              Variable Definitions                                  ###
###====================================================================================###

# Looping/switching Variables - number of VMs and Disks and PPG use
#$NumVMs      = 1
#$NumDataDisk = 0
#$UsePPG      = "false"


# Use your existing network resources: vNet, Subnet, NSG
$ResourceGroup  = "TMP-LinuxTesting"
$Region         = "westus2"
$vNetName       = "linuxvnet01-wus2"
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
$VMPrefix       = "labnode"
$DiskPrefix     = "datadisk"
$VMSize         = "Standard_D2ds_v5"    # E#bds is required for NVMe
$DiskController = "SCSI"                # Choices - "SCSI" and "NVMe"
$Zone           = "1"                   # Need for UltraSSD
$PPGName        = "LabTestingPPG"

<# Common VM Sizes
Standard_D2ds_v5
Standard_D4ds_v5
Standard_D8ds_v5
Standard_B2s
#>

# Process a cloud-init file
# Use the one I use for Terraform
$CloudinitFile  = "C:\Users\ksvietme\repos\Terraform\azure\secrets\cloud-init.simple"
$Bytes          = [System.Text.Encoding]::Unicode.GetBytes((Get-Content -raw $CloudinitFile))
$CloudInit      = (Get-Content -raw $CloudinitFile)

###====================================================================================###
###              You shouldn't need to modify the script below this line.              ###
###                                                                                    ###
###                                                                                    ###

# Use existing vNet already peered to hub
$vNet      = Get-AzVirtualNetwork -Name $vNetName -ResourceGroupName $vNetRG
$SubNetCfg = Get-AzVirtualNetworkSubnetConfig -ResourceId $vNet.Subnets[0].Id
$NSG       = Get-AzNetworkSecurityGroup -ResourceGroupName $NsgRG -Name $NsgName


###====================================================================================###
###                        Resource Group and Storage Account                          ###
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
$VMStorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name deleteme${RandomStorageACCT} 

# For DB testing we need a Proximity Group - Zone requires defining VM sizes (Use $VMsize)
$PPG = New-AzProximityPlacementGroup `
  -Location $Region `
  -Name $PPGName `
  -ResourceGroupName $ResourceGroup `
  -ProximityPlacementGroupType Standard `
  -IntentVMSizeList $VMSize `
  -Zone $Zone


Write-Host ""
Write-Host "###============================================================###" -ForegroundColor DarkBlue
Write-Host "                Creating Resource Group:" $ResourceGroup
Write-Host "               Creating Storage Account:" $VMStorageAccount.StorageAccountName
Write-Host "                          Number of VMs:" $NumVMs
Write-Host "            Number of Data Disks per VM:" $NumDataDisks
Write-Host "###============================================================###" -ForegroundColor DarkBlue
Write-Host ""


###====================================================================================###
###                                VM Creation Loop                                    ###
###====================================================================================###

# Start the loop
for ($i=1; $i -le $NumVMs; $i++) {

  ### Resource names use a RandomID so VMs are unique
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

  # Set basic parameters new VM object
  # https://learn.microsoft.com/en-us/powershell/module/az.compute/new-azvmconfig?view=azps-10.1.0
  # Set -vCPUCountPerCore to 1 to disable hyperthreading
  
  # Are we using a PPG?
  if ($UsePPG -eq $False) {
  #if ($UsePPG) {
    Write-Host "    Not using a Proximity Placement Group"

    $NewVMConfig = New-AzVMConfig -VMName $VMName `
    -VMSize $VMSize `
    -DiskControllerType $DiskController `
    -EnableUltraSSD `
    -Zone $Zone
  } 
  else {
    Write-Host "    Using Proximity Placement Group:" $PPGName

    $NewVMConfig = New-AzVMConfig -VMName $VMName `
    -VMSize $VMSize `
    -DiskControllerType $DiskController `
    -EnableUltraSSD `
    -ProximityPlacementGroupId $PPG.Id `
    -Zone $Zone 
  }

  # ToDo: Add SSH Key to VM  - Doing this in cloud-init

  ###===================== Create the NIC Configuration ========================###

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
  # Don't need an NSG if you are using a subnet with one attached.
  $VMNIC = New-AzNetworkInterface `
    -Name $NICId `
    -ResourceGroupName $ResourceGroup `
    -Location $Region `
    -EnableAcceleratedNetworking `
    -IpConfiguration $NewIPConfig

  # Add the NIC to the VM Configuration
  Add-AzVMNetworkInterface -VM $NewVMConfig -Id $VMNIC.Id

  ###--======================= End NIC Configuration ===========================###

  ###======================== Create Disks For DB ==============================###
  #                          Define, Create, Attach                               # 
  
  # Should I create Data Disks?
  if ( $NumDataDisk -gt 0 ) {

    for ($Disk=1; $Disk -le $NumDataDisk; $Disk++) {
  
      $DiskName = "$DiskPrefix-$Disk-$VMName"
      $LUN      = $Disk + 10
      
      # Setup UltraSSD disk configuration "-AccountType UltraSSD_LRS"
      $DataDiskConfig = New-AzDiskConfig `
        -Location $Region `
        -Zone $Zone `
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

  # Use this section to setup boot diagnostics and keep it with VM
  # Otherwise it will use an existing storage account in the Region
  # which may not be what you want.
  $NewVMConfig = Set-AzVMBootDiagnostic `
    -VM $NewVMConfig `
    -Enable `
    -ResourceGroupName $ResourceGroup `
    -StorageAccountName $VMStorageAccount.StorageAccountName

  # OS definition and Credentials for user  -Credential are pulled from an $Env variable.
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

}

Write-Host ""
Write-Host "###====================###" -ForegroundColor Red
Write-Host ""
Write-Host "To delete these resources use: Remove-AzResourceGroup -Name $ResourceGroup -Force"
Write-Host ""
Write-Host "###====================###" -ForegroundColor Red
Write-Host ""

###=============================  END Create VM Loop   ==============================###

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

<# Add SSH Key to VM  - Doing this on cloud-init
$VirtualMachine = Get-AzVM -ResourceGroupName "ResourceGroup11" -Name "VirtualMachine07"
$VirtualMachine = Add-AzVMSshPublicKey -VM $VirtualMachine `
  -KeyData "MIIDszCCApugAwIBAgIJALBV9YJCF/tAMA0GCSq12Ib3DQEB21QUAMEUxCzAJBgNV" `
  -Path "/home/admin/.ssh/authorized_keys"
#>

<# --- uncomment here to use locally in the script
###----   Define Login parameters for the VM   ----### 
# VM credential information is sourced from elsewherer in this script
$VMLocalAdminUser = "<adminusername>"
$VMLocalAdminSecurePassword = ConvertTo-SecureString "<passwordstring>" -AsPlainText -Force
$VMCred = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
#>