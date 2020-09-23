###====================================================================================###
<#   
  FileName: CreateWin10VM.ps1
  Created By: Karl Vietmeier
    
  Description:
    Create VM - Trying to get a good - quick standup of VM script.

#>
###====================================================================================###

### Here for safety - comment/uncomment as desired
return

### Get my functions and credentials
# Credentials  (stored outside the repo)
. '..\..\Certs\resources.ps1'

# Functions (In this repo)
. '.\FunctionLibrary.ps1'

# Imported from "FunctionLibrary.ps1"
# Are we connected to Azure with the corredt SubID?
Check-Login


# Define variables for networking part
$ResourceGroup  = ""
$Location       = ""
$vNetName       = ""
$AddressSpace   = "" # Format 10.10.0.0/16
$SubnetIPRange  = "" # Format 10.10.1.0/24
$SubnetName     = ""
$nsgName        = ""
$StorageAccount = "" # Name must be unique. Name availability can be check using PowerShell command Get-AzStorageAccountNameAvailability -Name ""

<#
# Create Resource Groups and Storage Account for diagnostic
New-AzResourceGroup -Name $ResourceGroup -Location $Location
New-AzStorageAccount -Name $StorageAccount -ResourceGroupName $ResourceGroup -Location $Location -SkuName Standard_LRS

# Create Virtual Network and Subnet
$vNetwork = New-AzVirtualNetwork -ResourceGroupName $ResourceGroup -Name $vNetName -AddressPrefix $AddressSpace -Location $location
Add-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $vNetwork -AddressPrefix $SubnetIPRange
Set-AzVirtualNetwork -VirtualNetwork $vNetwork

# Create Network Security Group
$nsgRuleVMAccess = New-AzNetworkSecurityRuleConfig -Name 'allow-vm-access' -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22,3389 -Access Allow
New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroup -Location $location -Name $nsgName -SecurityRules $nsgRuleVMAccess
#>

# Define Variables needed for Virtual Machine
$vNet       = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroup -Name $vNetName
$Subnet     = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $vNet
$nsg        = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroup -Name $NsgName
$vmName 	= "centOS-01"
$pubName	= "OpenLogic"
$offerName	= "centOS"
$skuName	= "7.5"
$vmSize 	= "Standard_B1s"
$pipName    = "$vmName-pip" 
$nicName    = "$vmName-nic"
$osDiskName = "$vmName-OsDisk"
$osDiskSize = "30"
$osDiskType = "Premium_LRS"

###--- Create some variables for the new VM.
$ResourceGroup = "TempRG-01"
$Region = "westus2"
$VMSize = "Standard_DS3"

# Set-AzureRmVMBgInfoExtension -ResourceGroupName "ContosoRG" -VMName "ContosoVM" -Name "ExtensionName" -TypeHandlerVersion "2.1" -Location "West Europe"

# VM Information
$VMLocalAdminUser = "azureadmin"
$VMLocalAdminSecurePassword = ConvertTo-SecureString "Chalc0pyrite" -AsPlainText -Force
$VMCred = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);


# Create VM and PubIP names with random 4 digit number.
$VMName= "Win10VM-$(Get-Random -Minimum 1000 -Maximum 2000)"
$Image = "Windows-10"

# Create/Use network resources.
$SubNet = "subnet02"
$vNet = "VnetCore"
$PubIP = "PubIP-$(Get-Random -Minimum 1000 -Maximum 2000)"


# Create Admin Credentials
$adminUsername = Read-Host 'Admin username'
$adminPassword = Read-Host -AsSecureString 'Admin password with least 12 characters'
$adminCreds    = New-Object PSCredential $adminUsername, $adminPassword

# Create a public IP and NIC
$pip = New-AzPublicIpAddress -Name $PubIP -ResourceGroupName $ResourceGroup -Location $location -AllocationMethod Static 
$nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $ResourceGroup -Location $location -SubnetId $Subnet.Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

# Set VM Configuration
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize
Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id

# Set VM operating system parameters
Set-AzVMOperatingSystem -VM $vmConfig `
    -Linux -ComputerName $vmName `
    -Credential $adminCreds

# Set boot diagnostic storage account
Set-AzVMBootDiagnostics -Enable -ResourceGroupName $ResourceGroup `
    -VM $vmConfig `
    -StorageAccountName $StorageAccount

# Set virtual machine source image
Set-AzVMSourceImage -VM $vmConfig `
    -PublisherName $pubName `
    -Offer $offerName `
    -Skus $skuName `
    -Version 'latest'

# Set OsDisk configuration
Set-AzVMOSDisk -VM $vmConfig `
    -Name $osDiskName `
    -DiskSizeInGB $osDiskSize `
    -StorageAccountType $osDiskType `
    -CreateOption fromImage

# Create the VM
New-AzVM -ResourceGroupName $ResourceGroup -Location $location -VM $vmConfig
