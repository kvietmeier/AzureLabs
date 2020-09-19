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

### Get my functions and credentials
# Credentials  (stored outside the repo)
. '..\..\Certs\resources.ps1'

# Functions (In this repo)
. '.\FunctionLibrary.ps1'

# Imported from "FunctionLibrary.ps1"
# Are we connected to Azure with the corredt SubID?
Check-Login

###--- Create some variables for the new VM.
$ResourceGroup = "TempRG-01"
$Region = "westus2"
$VMSize = "Standard_DS3"


$VMCred = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword)


# Create VM and PubIP names with random 4 digit number.
$VMName= "Win10VM-$(Get-Random -Minimum 1000 -Maximum 2000)"
$Image = "Windows-10"

# Create/Use network resources.
$SubNet = "subnet02"
$vNet = "VnetCore"
$PubIP = "PubIP-$(Get-Random -Minimum 1000 -Maximum 2000)"


###--- End Vars

# Define VM Parameters
$vmParams = @{
    ResourceGroupName   = "$ResourceGroup"
    Location            = "$Region"
    Credential          = "$VMCred"
    Name                = "$VMName"
    ImageName           = "$Image"
    Size                = "$VMSize"
    VirtualNetworkName  = "$vNet"
    SubnetName          = "$SubNet"
    PublicIpAddressName = "$PubIP"
    OpenPorts           = "3389"
}

# Create VM
$newVM = New-AzVM @vmParams


$newVM