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

###---- Get my functions and credentials ----###
# Credentials  (stored outside the repo)
. '..\..\Certs\resources.ps1'

# Functions (In this repo)
. '.\FunctionLibrary.ps1'

# Imported from "FunctionLibrary.ps1"
# Are we connected to Azure with the corredt SubID?
Check-Login
###---- End my functions and credentials ----###

###----   Define parameters for the VM   ----###
<# 
# VM Information - sourced from resources.ps1 - uncomment here to use locally
# in the script
$VMLocalAdminUser = "##########"
$VMLocalAdminSecurePassword = ConvertTo-SecureString "############" -AsPlainText -Force
$VMCred = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
#>

# Region
$Region = "westus2"

# Create a 4 digit random ID for naming
$RandomID = $(Get-Random -Minimum 1000 -Maximum 2000)

# Resource names 
$ResourceGroup  = "TempRG-$RandomID"
$VMName         = "Win10VM-$RandomID"
$DNSName        = "win10vm$RandomID"
$PubIP          = "PubIP-$RandomID"
$NICId          = "NIC-$RandomID"

# Windows Image and VM Size to Use
$VMSize         = "Standard_D2_v3"

###--- Images
# Image: Windows 10 Enterprise 2004
#$PublisherName  = "MicrosoftWindowsDesktop"
#$Offer          = "Windows-10"
#$SKU            = "20h1-entn"
#$Version        = "latest"
# Image: Windows 10 Enterprise 1909
$PublisherName  = "MicrosoftWindowsDesktop"
$Offer          = "Windows-10"
$SKU            = "19h2-ent"
$Version        = "latest"
# Image: Windows 10 Multi Session 2004
#$PublisherName  = "MicrosoftWindowsDesktop"
#$Offer          = "office-365"
#$SKU            = "19h2-evd-o365pp"
#$Version        = "latest"


<###=================  Start Setting up the VM  ==================###
Creating a Virtual Machine is a multi-step process where you build up configuration
PSObjects and apply them all with the "New-AzVM" command
#>

# Create the resource group for the VM and resources
New-AzResourceGroup -Name $ResourceGroup -Location $Region

# VM Name and Size
$NewVMConfig = New-AzVMConfig -VMName $VMName -VMSize $VMSize

<###================ Create the NIC Configuration ================###
For this use case we want to spin up a quick test VM leveraging an existing 
vNet, Subnet, and NSG. 
#>

# Use existing network resources: vNet, Subnet, NSG
$vNetName  = "VnetCore"
$vNetRG    = "CoreInfrastructure-rg"
$NsgName   = "AllowRemoteByIP"
$vNet      = Get-AzVirtualNetwork -Name $vNetName -ResourceGroupName $vNetRG
$SubNetCfg = Get-AzVirtualNetworkSubnetConfig -ResourceId $vNet.Subnets[0].Id
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

# Create the VM using info in the layered config above
New-AzVM -ResourceGroupName $ResourceGroup -Location $Region -VM $NewVMConfig -Verbose