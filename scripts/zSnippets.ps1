###====================================================================================###
<# 
  zSnippets.ps1                   
    Created By: Karl Vietmeier    
                                 
  Description                   
    Misc bits and pieces       
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

# RDP settings
# https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/clients/rdp-files
# Use Update-AzWvdHostPool
Update-AzWvdHostPool -ResourceGroupName ResourceGroupName `
    -Name HostPoolName `
    -LoadBalancerType 'BreadthFirst' `
    -Description 'Description' `
    -FriendlyName 'Friendly Name' `
    -MaxSessionLimit 6 `
    -SsoContext $null `
    -CustomRdpProperty $null `
    -Ring $null `
    -ValidationEnvironment:$false
    
Update-AzWvdHostPool -ResourceGroupName Test-rg -Name Testpool -CustomRdpProperty "audiocapturemode:i:1;use multimon:i:0"
Set-RdsHostPool -TenantName MyTenant -HostPoolName MyPool -CustomRdpProperty "audiocapturemode:i:1;use multimon:i:0"

$properties="audiocapturemode:i:1;use multimon:i:0"
Update-AzWvdHostPool -ResourceGroupName $AZResourceGroup -Name TestPool01 -CustomRdpProperty $properties

$AZResourceGroup = "TempRG-01"
$AppGroup = "TestLogin-DAG"

Get-AzWvdHostPool -ResourceGroupName $AZResourceGroup
Get-AzWvdHostPool -ResourceGroupName $AZResourceGroup -Name TestPool01
Get-AzWvdApplicationGroup -ResourceGroupName $AZResourceGroup
Get-AzWvdApplicationGroup -ResourceGroupName $AZResourceGroup -Name $AppGroup | format-list Name

Get-AzWvdHostPool -ResourceGroupName $AZResourceGroup -Name TestPool01 | format-list Name, CustomRdpProperty


Remove-AzWvdApplicationGroup -ResourceGroupName $AZResourceGroup -Name $AppGroup
Remove-AzWvdHostPool -ResourceGroupName TempRG-01 -Name Foobar02