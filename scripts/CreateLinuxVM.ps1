###====================================================================================###
<# 
  CreateLinuxVM.ps1                                                    
    Created By: Karl Vietmeier
                karl.vietmeier@intel.com                                       
                                                                    
  Description                                                      
    Create a Linux VM for testing                                 
    Sometimes you just need a VM for testing with some standard defaults and using 
    existing vnets and NSG.   

  Status:  Working, tested

  To Do:  
    Setup storage - OS disk, rather than take the defaults.
    Make interactive - prompt for region, prefix, image, etc.
    Merge with Windows VM script?
                                                                
  Resources:
   https://docs.microsoft.com/en-us/powershell/module/az.compute/new-azvm?view=azps-4.6.1
   https://docs.microsoft.com/en-us/powershell/module/az.compute/new-azvmconfig?view=azps-4.7.0
   https://docs.microsoft.com/en-us/azure/virtual-machines/windows/cli-ps-findimage

#>
###====================================================================================###

### Here for safety - comment/uncomment as desired
#return

<#
.SYNOPSIS
Create a Linux VM

.DESCRIPTION
Will create a Linux VM using the configured parameters that you need to 
modify in this script. Also assumes you are authenticated to your 
subscription.

Generates a random 4 digit ID for resources. 

.EXAMPLE
./CreateLinuxVM.ps1

.NOTES
General notes
#>

### Here for safety - comment/uncomment as desired
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
# Are we connected to Azure with the corredt SubID?
#CheckLogin

###---- End my functions and credentials ----###

# Create a 4 digit random ID for naming
$RandomID = $(Get-Random -Minimum 1000 -Maximum 2000)

<###----   Define parameters for the VM   ----### 
  VM credential information is sourced from miscinfo.ps1
  --- uncomment here to use locally in the script
$VMLocalAdminUser = "<adminusername>"
$VMLocalAdminSecurePassword = ConvertTo-SecureString "<passwordstring>" -AsPlainText -Force
$VMCred = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
#>

### Resource names  uses RandomID so VMs are unique
# - might want to use existing resources
#$StorageAccount = "kv82579TempSA-$RandomID"
#$ResourceGroup  = "TempRG-$RandomID"


# Name the VM and components
$VMPrefix       = "ubuntu"
$VMName         = "$VMPrefix-$RandomID"
$DNSName        = "$VMPrefix$RandomID"
$PubIP          = "$VMPrefix-PubIP-$RandomID"
$NICId          = "$VMPrefix-NIC-$RandomID"

# Use existing network resources: vNet, Subnet, NSG
$StorageAccount = "kv82579bootdiags"
$SAGroup        = "CoreInfra-rg"
$ResourceGroup  = "rg-k8scluster01"
$Region         = "westus2"
$vNetName       = "k8s-vnet"
$vNetRG         = "CoreInfra-rg"
$NsgName        = "RestrictByIP"


###=================  Image Definitions  ==================###
# Image: Centos
#$PublisherName  = "OpenLogic"
#$Offer          = "Centos"
#$SKU            = "8_3"
#$Version        = "latest"

# Ubuntu - add "-gen2" to create a Gen2 VM
$PublisherName  = "Canonical"
$Offer          = "0001-com-ubuntu-server-focal"
$SKU            = "20_04-lts-gen2"
$Version        = "latest"

# VM Size to Use - need 4 vCPU for accelerated networking
$VMSize         = "Standard_D2ds_v4"

<# Common Sizes
Standard_D2ds_v4
Standard_D4ds_v4
Standard_D8ds_v4
Standard_B2s
#>


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

###=================   END: Images   ==================###

<###=================  Start Setting up the VM  ==================###
  Creating a Virtual Machine is a multi-step process where you build up configuration
  PSObjects and apply them all with the "New-AzVM" command
  --- You shouldn't need to modify the script below this line.
#>

# If it doesn't exist - Create the resource group for the VM and resources
Get-AzResourceGroup -Name $ResourceGroup -ErrorVariable NotExist -ErrorAction SilentlyContinue
if ($NotExist) {
  New-AzResourceGroup -Name $ResourceGroup -Location $Region
} else { Write-Host "Using Resourcegroup:" $ResourceGroup }


# VM Name and Size
$NewVMConfig = New-AzVMConfig -VMName $VMName -VMSize $VMSize

<# Add SSH Key to VM (need to integrate)
$VirtualMachine = Get-AzVM -ResourceGroupName "ResourceGroup11" -Name "VirtualMachine07"
$VirtualMachine = Add-AzVMSshPublicKey -VM $VirtualMachine `
  -KeyData "MIIDszCCApugAwIBAgIJALBV9YJCF/tAMA0GCSq12Ib3DQEB21QUAMEUxCzAJBgNV" `
  -Path "/home/admin/.ssh/authorized_keys"
#>

<###================ Create the NIC Configuration ================###
For this use case we want to spin up a quick test VM leveraging an existing 
vNet, Subnet, and NSG. 
#>

$vNet      = Get-AzVirtualNetwork -Name $vNetName -ResourceGroupName $vNetRG
$SubNetCfg = Get-AzVirtualNetworkSubnetConfig -ResourceId $vNet.Subnets[0].Id
$NSG       = Get-AzNetworkSecurityGroup -ResourceGroupName $vNetRG -Name $NsgName

# Create a new static Public IP and assign a DNS record
$PIP = New-AzPublicIPAddress `
  -Name $PubIP `
  -ResourceGroupName $ResourceGroup `
  -Sku Basic `
  -AllocationMethod Dynamic `
  -DomainNameLabel $DNSName `
  -Location $Region

# Start building the NIC configuration - Subnet and Public IP
$NewIPConfig = New-AzNetworkInterfaceIpConfig -Name "IPConfig-1" -Subnet $SubNetCfg -PublicIpAddress $PIP -Primary 

# Create the NIC using the PS Objects - enable accelerated networking
$VMNIC = New-AzNetworkInterface `
  -Name $NICId `
  -ResourceGroupName $ResourceGroup `
  -Location $Region `
  -NetworkSecurityGroupId $NSG.Id `
  -EnableAcceleratedNetworking `
  -IpConfiguration $NewIPConfig

# Add the NIC to the VM Configuration
Add-AzVMNetworkInterface -VM $NewVMConfig -Id $VMNIC.Id

###=================== End - NIC Configuration ===================###

###===================    Disk/Storage SetUp   ===================###
# Use this section to setup boot diagnostics and keep it with VM
# Otherwise it will use an existing storage account in the Region
# which may be what you want.
$NewVMConfig = Set-AzVMBootDiagnostic `
  -VM $NewVMConfig `
  -Enable `
  -ResourceGroupName $SAGroup `
  -StorageAccountName $StorageAccount

# This section needs some work.


###===================   End - Storage Setup   ===================###

# OS definition and Credentials for user - Credentials are stored
# in an external file.
$NewVMConfig = Set-AzVMOperatingSystem `
  -VM $NewVMConfig `
  -Linux `
  -ComputerName $VMName `
  -Credential $VMCred

# Source Image
$NewVMConfig = Set-AzVMSourceImage `
  -VM $NewVMConfig `
  -PublisherName $PublisherName `
  -Offer $Offer `
  -Skus $SKU `
  -Version $Version


###----> Create the VM using info in the layered config above
New-AzVM -ResourceGroupName $ResourceGroup -Location $Region -VM $NewVMConfig -Verbose