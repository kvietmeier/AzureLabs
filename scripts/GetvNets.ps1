###====================================================================================###
<#   
  FileName: listvnets.ps1
  Created By: Karl Vietmeier
    
  Description:
   Get vnet information

   Found the original code for this on Stack Exchange

#>
###====================================================================================###

<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.EXAMPLE
An example

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
CheckLogin


$subs = Get-AzSubscription 
foreach ($Sub in $Subs) {
    Write-Host "***************************"
    Write-Host " "
    $Sub.Name 

    $SelectSub = Select-AzSubscription -SubscriptionName $Sub.Name

    $VNETs = Get-AzVirtualNetwork 
    foreach ($VNET in $VNETs) {
        Write-Host "--------------------------"
        Write-Host " "
        Write-Host "   vNet: " $VNET.Name 
        Write-Host "   AddressPrefixes: " ($VNET).AddressSpace.AddressPrefixes

        $vNetExpanded = Get-AzVirtualNetwork -Name $VNET.Name -ResourceGroupName $VNET.ResourceGroupName -ExpandResource 'subnets/ipConfigurations' 

        foreach($subnet in $vNetExpanded.Subnets)
        {
            Write-Host "       Subnet: " $subnet.Name
            Write-Host "          Connected devices " $subnet.IpConfigurations.Count
            foreach($ipConfig in $subnet.IpConfigurations)
            {
                Write-Host "            " $ipConfig.PrivateIpAddress
            }
        }

        Write-Host " " 
    } 
}