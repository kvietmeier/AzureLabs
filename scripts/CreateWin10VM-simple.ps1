###====================================================================================###
<# 
  CreateWin10VM-simple.ps1                                                    
    Created By: Karl Vietmeier                                        
                                                                    
  Description                                                      
    Create a Win10 VM for testing                                 
    Sometimes you just need a VM for testing with some standard defaults     
                                                                
    Simple version
    https://docs.microsoft.com/en-us/powershell/module/az.compute/new-azvm?view=azps-4.6.1
    https://docs.microsoft.com/en-us/azure/virtual-machines/windows/cli-ps-findimage

#>
###====================================================================================###

### Here for safety - comment/uncomment as desired
return

###---- Get my functions and credentials ----###
# Credentials  (stored outside the repo)
. '..\..\Certs\resources.ps1'

# Functions (In this repo)
. '.\FunctionLibrary.ps1'

# Imported from "FunctionLibrary.ps1"
# Are we connected to Azure with the corredt SubID?
Check-Login
###---- End my functions and credentials ----###


###---- Create some variables for the new VM.
$ResourceGroup = "TempRG-$(Get-Random -Minimum 1000 -Maximum 2000)"
$Region = "westus2"
$VMSize = "Standard_DS3"

# Set-AzureRmVMBgInfoExtension -ResourceGroupName "ContosoRG" -VMName "ContosoVM" -Name "ExtensionName" -TypeHandlerVersion "2.1" -Location "West Europe"

<# 
# VM Information - sourced from resources.ps1 - uncomment here to use locally
# in the script
$VMLocalAdminUser = "##########"
$VMLocalAdminSecurePassword = ConvertTo-SecureString "############" -AsPlainText -Force
$VMCred = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
#>

# Create VM and PubIP names with random 4 digit number.
$VMName= "Win10VM-$(Get-Random -Minimum 1000 -Maximum 2000)"
$Image = "Windows-10"

# Create/Use network resources.
$SubNet = "subnet02"
$vNet = "VnetCore"
$PubIP = "PubIP-$(Get-Random -Minimum 1000 -Maximum 2000)"

###--- End Vars

# Define the VM Parameters in a hash to pass to "New-AzVM"
$vmParams = @{
    ResourceGroupName   = $ResourceGroup
    Location            = $Region
    Credential          = $VMCred
    Name                = $VMName
    ImageName           = $Image
    Size                = $VMSize
    VirtualNetworkName  = $vNet
    SubnetName          = $SubNet
    PublicIpAddressName = $PubIP
    OpenPorts           = "3389"
}

# Create the VM using info in the hash above
$newVM = New-AzVM @vmParams
$newVM

<#
This is placeholder code I'm using to sort out getting the right info for "-Image" 
in the hash above.
###---  Finding Images ---###
# https://docs.microsoft.com/en-us/azure/virtual-machines/windows/cli-ps-findimage

* List the publishers:
Get-AzVMImagePublisher -Location $Region | Select PublisherName

* Fill in your chosen publisher name and list the offers:
$pubName="MicrosoftWindowsDesktop"
$pubName="MicrosoftWindowsDesktop"
Get-AzVMImageOffer -Location $Region -PublisherName $pubName | Select Offer

* Fill in your chosen offer name and list the SKUs:
$offerName="Windows-10"
$offerName="windows-10-2004-vhd-server-prod-stage"
Get-AzVMImageSku -Location $Region -PublisherName $pubName -Offer $offerName | Select Skus

* Fill in your chosen SKU name and get the image version:
$skuName="rs5-pro"
Get-AzVMImage -Location $Region -PublisherName $pubName -Offer $offerName -Sku $skuName | Select Version

#>