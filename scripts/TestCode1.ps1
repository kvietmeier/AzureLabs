<#   
###====================================================================================###
  FileName: TestCode.ps1
  Created By: Karl Vietmeier
    
  Description:
    Use for testing a concept

###====================================================================================###
#>


### Here for safety - comment/uncomment as desired
#return

# Stop on first error
$ErrorActionPreference = "stop"

# Run from the location of the script
Set-Location $PSscriptroot

#Use existing network resources: vNet, Subnet, NSG - set to your own
$Region         = "westus2"
$ResourceGroup  = "TMP-VoltTesting"
$Zone           = "1"                   # Need for UltraSSD
$PPGName        = "Foobar"

[string[]] $sizes = `
   @("Standard_E96a_v4",`
     "Standard_E48a_v4",`
     "Standard_E64a_v4")


$Instances=@("Standard_E2bds_v5", "Standard_E4bds_v5", "Standard_E8bds_v5", "Standard_E16bds_v5", "Standard_E32bds_v5")

#[string[]]$Instances=@("Standard_E2bds_v5", "Standard_E4bds_v5", "Standard_E8bds_v5", "Standard_E16bds_v5", "Standard_E32bds_v5")
$AllowedVMSizes = [string[]]$Instances



# For DB testing we need a Proximity Group - Zone requires defining VM sizes
New-AzProximityPlacementGroup `
  -Location $Region `
  -Name $PPGName `
  -ResourceGroupName $ResourceGroup `
  -ProximityPlacementGroupType Standard `
  -IntentVMSizeList $AllowedVMSizes `
  -Zone $Zone
