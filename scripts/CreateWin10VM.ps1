###====================================================================================###
###  <scriptname>.ps1                                                                  ###
###    Created By: Karl Vietmeier                                                      ###
###                                                                                    ###
###  Description                                                                       ###
###    Create a Win10 VM for testing                                                   ###
###    Sometimes you just need a VM with some standard defaults                        ### 
###                                                                                    ###
###    Not Working!!!                                                                  ###
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

# Create some variables for the new VM.
$ResourceGroup = "TempRG-01"
$Region = "westus2"

# Create name with random 4 digit number.
$VMName= "Win10VM-$(Get-Random -Minimum 1000 -Maximum 2000)"

# Create a resource group

# Create the network resources.
$SubNet = "subnet02"
$vNet = "VnetCore"

$PIP = New-AzPublicIpAddress `
        -ResourceGroupName $ResourceGroup `
        -Location $Region `
        -Name "$VMName-PIP" `
        -AllocationMethod Static `
        -IdleTimeoutInMinutes 4

$NSGRuleRDP = New-AzNetworkSecurityRuleConfig `
              -Name NSGAllowRDP  -Protocol Tcp `
              -Direction Inbound `
              -Priority 1000 -SourceAddressPrefix * `
              -SourcePortRange * `
              -DestinationAddressPrefix * `
              -DestinationPortRange 3389 -Access Allow

$NSG  = New-AzNetworkSecurityGroup `
        -ResourceGroupName $resourceGroup `
        -Location $location `
        -Name myNetworkSecurityGroup `
        -SecurityRules $nsgRuleRDP

$NIC  = New-AzNetworkInterface `
        -Name $VMName -ResourceGroupName $ResourceGroup `
        -Location $Region `
        -SubnetId $vnet.Subnets[0].Id `
        -PublicIpAddressId $pip.Id `
        -NetworkSecurityGroupId $nsg.Id


<# $subnetConfig = New-AzVirtualNetworkSubnetConfig -Name mySubnet -AddressPrefix 192.168.1.0/24
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroup -Location $location `
  -Name MYvNET -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig
$pip = New-AzPublicIpAddress -ResourceGroupName $resourceGroup -Location $location `
  -Name "mypublicdns$(Get-Random)" -AllocationMethod Static -IdleTimeoutInMinutes 4
$nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleRDP  -Protocol Tcp `
  -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
  -DestinationPortRange 3389 -Access Allow
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location `
  -Name myNetworkSecurityGroup -SecurityRules $nsgRuleRDP
$nic = New-AzNetworkInterface -Name $vmName -ResourceGroupName $resourceGroup -Location $location `
  -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id
 #>
# Create a virtual machine configuration using $imageVersion.Id to specify the image version.


$vmConfig = New-AzVMConfig -VMName $vmName -VMSize Standard_D1_v2 | `
Set-AzVMSourceImage -Id $galleryImage.Id | `
Add-AzVMNetworkInterface -Id $nic.Id

# Create a virtual machine
New-AzVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig