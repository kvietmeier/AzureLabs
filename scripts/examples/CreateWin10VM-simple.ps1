###====================================================================================###
<# 
  CreateWin10VM-simple.ps1                                                    
    Created By: Karl Vietmeier                                        
                                                                    
  Description                                                      
    Create a Win10 VM for testing                                 
    Sometimes you just need a VM for testing with some standard defaults 
    It will create a new vnet and subnet but use an existing NSG

    Note - this method will create new resources like vnets etc in the ResourceGroup.
    
  Status:  Working, tested
                                                                
  Resources:
   https://docs.microsoft.com/en-us/powershell/module/az.compute/new-azvm?view=azps-4.6.1
   https://docs.microsoft.com/en-us/powershell/module/az.compute/new-azvmconfig?view=azps-4.7.0
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

###----   Define parameters for the VM   ----###
<# 
# VM Information - sourced from resources.ps1 - uncomment here to use locally
# in the script
$VMLocalAdminUser = "##########"
$VMLocalAdminSecurePassword = ConvertTo-SecureString "############" -AsPlainText -Force
$VMCred = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
#>

# Create a 4 digit random ID for naming
$RandomID  = $(Get-Random -Minimum 1000 -Maximum 2000)

# Region and VM Image parameters
$ResourceGroup  = "TempRG-$RandomID"
$VMName         = "Win10VM-$RandomID"
$Region         = "westus2"
$VMSize         = "Standard_D2_v3"
$Image          = "Win2019Datacenter"
#$Image          = "Win10"

# Create/Use network resources. 
# For this use case I want to spin up a quick test VM leveraging existing 
# vNets and Subnets, but go ahead and create a Public IP.
$SubNet = "subnet02"
$vNet   = "VnetCore"
$PubIP  = "PubIP-$RandomID"
$NSG    = "AllowRemoteByIP"

# Put the VM Parameters in a hash table to pass to "New-AzVM"
# I use a defined NSG that opens port 3389 to only one IP, swap the
# comments if you want to let the ARM process create one for you.
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
    SecurityGroupName   = $NSG
    #OpenPorts           = "3389"
}

# Create the VM using info in the hash above
$NewVM = New-AzVM @vmParams

# Enable BGInfo
Set-AzVMBgInfoExtension `
  -ResourceGroupName $ResourceGroup `
  -VMName $VMName `
  -Name "ExtensionName" `
  -TypeHandlerVersion "2.1" `
  -Location $Region

$NewVM