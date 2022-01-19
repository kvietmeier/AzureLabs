###====================================================================================###
<# 
  CreateWin10VM.ps1                                                    
    Created By: Karl Vietmeier
                kavietme@microsoft.com                                       
                                                                    
  Description                                                      
    Create a Win10 VM for testing                                 
    Sometimes you just need a VM for testing with some standard defaults and using 
    existing network infrastructure   

  Status:  Working, tested

  To Do:  Setup storage - OS disk, rather than take the defaults.
                                                                
  Resources:
   https://docs.microsoft.com/en-us/powershell/module/az.compute/new-azvm?view=azps-4.6.1
   https://docs.microsoft.com/en-us/powershell/module/az.compute/new-azvmconfig?view=azps-4.7.0
   https://docs.microsoft.com/en-us/azure/virtual-machines/windows/cli-ps-findimage

#>
###====================================================================================###

### Here for safety - comment/uncomment as desired
#return

# Stop on first error
$ErrorActionPreference = "stop"

# Run from the location of the script
Set-Location $PSscriptroot
#Set-Location ../AzureLabs/scripts

###---- Get my functions and credentials ----###
# Credentials  (stored outside the repo)
. 'C:\.info\miscinfo.ps1'

# Functions (In this repo)
. '.\FunctionLibrary.ps1'

# Imported from "FunctionLibrary.ps1"
# Are we connected to Azure with the corredt SubID?

#AZConnectSP $SPAppID $SPSecret

###---- End my functions and credentials ----###

###----   Define parameters for the VM   ----###
<# 
# VM Information - sourced from resources.ps1 - uncomment here to use locally
# in the script
$VMLocalAdminUser = "##########"
$VMLocalAdminSecurePassword = ConvertTo-SecureString "############" -AsPlainText -Force
$VMCred = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
#>

# Create a 4 digit random ID for naming
$RandomID = $(Get-Random -Minimum 1000 -Maximum 2000)

# Use existing network resources: vNet, Subnet, NSG
$Region    = "eastus2"
#$vNetName  = "avdvnet01"
$vNetName  = "k8s-vnet"
$vNetRG    = "k8s-eastus2"
#$NsgName   = "AllowByIP"
$NsgName   = "FilterByIP"

# Resource names  uses RandomID so VMs are unique
$VMPrefix       = "imageprep"
#$StorageAccount = "kv82579TempSA-$RandomID"
$ResourceGroup  = "TempRG-$RandomID"
$ResourceGroup  = "$VMPrefix-eastus2"
$VMName         = "$VMPrefix-$RandomID"
$DNSName        = "$VMPrefix$RandomID"
$PubIP          = "$VMPrefix-PubIP-$RandomID"
$NICId          = "$VMPrefix-NIC-$RandomID"


###=================  Image Definitions  ==================###
# Windows Image and VM Size to Use
#$VMSize         = "Standard_D2_v3"
#$VMSize         = "Standard_D2_v4"
$VMSize         = "Standard_D2s_v5"

# Image: Windows 10 Enterprise 2004 H2
#$PublisherName  = "MicrosoftWindowsDesktop"
#$Offer          = "Windows-10"
#$SKU            = "20h2-entn"
#$Version        = "latest"

# Image: Windows 10 Enterprise 1909
#$PublisherName  = "MicrosoftWindowsDesktop"
#$Offer          = "Windows-10"
#$SKU            = "19h2-ent"
#$Version        = "latest"

# Image: Windows 10 Multi Session 2020 2H w/O365
$PublisherName  = "MicrosoftWindowsDesktop"
$Offer          = "office-365"
#$SKU            = "20h2-evd-o365pp"
# To enable Gen2 - 
$SKU            = "20h2-evd-o365pp-g2"
$Version        = "latest"

<# 
  office-365 SKUs
   1903-evd-o365pp
   19h2-evd-o365pp
   20h1-evd-o365pp
   20h2-evd-o365pp
   20h2-evd-o365pp-g2
  
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
#>

###========= Do Not Edit Below this line - except to modify script logic/flow/bugs ==========###

# If it doesn't exist - Create the resource group for the VM and resources
Get-AzResourceGroup -Name $ResourceGroup -ErrorVariable NotExist -ErrorAction SilentlyContinue
if ($NotExist) {
  New-AzResourceGroup -Name $ResourceGroup -Location $Region
} else { Write-Host "Using Resourcegroup:" $ResourceGroup }


# VM Name and Size
$NewVMConfig = New-AzVMConfig -VMName $VMName -VMSize $VMSize

<###================ Create the NIC Configuration ================###
For this use case we want to spin up a quick test VM leveraging an existing 
vNet, Subnet, and NSG. 
#>

# Use existing network resources: vNet, Subnet, NSG
$vNet      = Get-AzVirtualNetwork -Name $vNetName -ResourceGroupName $vNetRG
$SubNetCfg = Get-AzVirtualNetworkSubnetConfig -ResourceId $vNet.Subnets[1].Id
$NSG       = Get-AzNetworkSecurityGroup -ResourceGroupName $vNetRG -Name $NsgName

# Create a new static Public IP and assign a DNS record
$PIP = New-AzPublicIPAddress `
  -Name $PubIP `
  -ResourceGroupName $ResourceGroup `
  -AllocationMethod Static `
  -DomainNameLabel $DNSName `
  -Location $Region

# Start building the NIC configuration - Subnet and Public IP
$NewIPConfig = New-AzNetworkInterfaceIpConfig -Name "IPConfig-1" -Subnet $SubNetCfg -PublicIpAddress $PIP -Primary 

# Create the NIC using the PS Objects
$VMNIC = New-AzNetworkInterface `
  -Name $NICId `
  -ResourceGroupName $ResourceGroup `
  -Location $Region `
  -NetworkSecurityGroupId $NSG.Id `
  -IpConfiguration $NewIPConfig

# Add the NIC to the VM Configuration
Add-AzVMNetworkInterface -VM $NewVMConfig -Id $VMNIC.Id

###=================== End - NIC Configuration ===================###

###===================    Disk/Storage SetUp   ===================###
# For boot diagnostics - keep it with VM
#$NewVMConfig = Set-AzVMBootDiagnostic `
#  -VM $NewVMConfig `
#  -Enable `
#  -ResourceGroupName $ResourceGroup `
#  -StorageAccountName $StorageAccount



###===================   End - Storage Setup   ===================###

# OS definition and Credentials for user - Credentials are stored
# in an external file.
$NewVMConfig = Set-AzVMOperatingSystem `
  -VM $NewVMConfig `
  -Windows `
  -ComputerName $VMName `
  -Credential $VMCred `
  -ProvisionVMAgent `
  -EnableAutoUpdate

# Source Image
$NewVMConfig = Set-AzVMSourceImage `
  -VM $NewVMConfig `
  -PublisherName $PublisherName `
  -Offer $Offer `
  -Skus $SKU `
  -Version $Version


###----> Create the VM using info in the layered config above
New-AzVM -ResourceGroupName $ResourceGroup -Location $Region -VM $NewVMConfig -Verbose