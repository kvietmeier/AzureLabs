###========================================================================###
<# 
                   NetworkTroubleShooting.ps1
  Commands to validate/test network connectivity
  Created by:  Karl Vietmeier
    Not really a script
  
   Useful tool NTttcp (like iperf):
   https://gallery.technet.microsoft.com/NTttcp-Version-528-Now-f8b12769/file/159655/1/NTttcp-v5.33.zip
   https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-bandwidth-testing

#>
###========================================================================###

### For safety - comment/uncomment as desired
return
###

### Get my functions and credentials
# Credentials  (stored outside the repo)
. '..\..\Certs\resources.ps1'

# Functions (In this repo)
. '.\FunctionLibrary.ps1'

# Imported from "resources.ps1" - uncomment and set yourself
#$SubID = "SubID of Subscription"
#$SubName = "Subscription Name"

# Imported from "FunctionLibrary.ps1"
# Are we connected to Azure with the corredt SubID?
Check-Login

# Will Need for variousd tests - 
$AZResourceGroup = "WVDLandscape01"
$AZStorageAcct = "kvstor1551"
$AZFileShare = "userprofiles"
$SMBSharePath = "\\kvstor1551.file.core.windows.net\userprofiles\"


# Install a bunch of PS Modules (In FunctionLibrary.ps1)
Install-PSModules

# For AzureFiles AD Setup - download and follow install instructions:
# AzFilesHybrid:   https://github.com/Azure-Samples/azure-files-samples/releases
# Unzip to a folder and run the CopyToPSPath.ps1 script to put the module in the search path.  
# After you unzip and run the copy script - cd out of the directory and just run:
Import-Module AzFilesHybrid 

# Grab and install TTttcp
# <TBD>



### Basic Networking
#   https://docs.microsoft.com/en-us/powershell/module/nettcpip/test-netconnection?view=win10-ps
# - Note - The WVD Gateway blocks ICMP but you can still test name resolution
#   even if the ping fails.
Test-NetConnection

# Test resolver against known host that responds to ICMP 
Test-NetConnection ya.ru

# Test ICMP echo against known top level DNS server IP
Test-NetConnection 8.8.8.8

# Get more detailed information
Test-NetConnection -ComputerName www.contoso.com -DiagnoseRouting -InformationLevel Detailed


### The following commands requires you to be logged into your Azure account, run Connect-AzAccount if you haven't

# Test for Port 445 
# The ComputerName, or host, is <storage-account>.file.core.windows.net for Azure Public Regions.
# $storageAccount.Context.FileEndpoint is used because non-Public Azure regions, such as sovereign clouds
# or Azure Stack deployments, will have different hosts for Azure file shares (and other storage resources).

# Test port 445
Test-NetConnection -ComputerName ([System.Uri]::new($AZStorageAcct.Context.FileEndPoint).Host) -Port 445

## Check the AZF Setup (need AZ Storage Module loaded)
Debug-AzStorageAccountAuth -StorageAccountName $AZStorageAcct -ResourceGroupName $AZResourceGroup -Verbose


###--- Check the Azure route table - in some cases info in the host OS can be misleading/not useful
#   in an "all Azure" infrastructure.
#   Host OS routes - "Get-NetRoute"
#   https://docs.microsoft.com/en-us/powershell/module/nettcpip/get-netroute?view=win10-ps


# Get Azure effective route table
# https://docs.microsoft.com/en-us/powershell/module/az.network/get-azeffectiveroutetable?view=azps-4.6.0
# Need Az Module and be connected to your Subscription (see above)
$NIC1 = "wvd-mgmtserver803"
$NIC2 = "testvm-0-nic"
$NIC3 = "testvm-1-nic"
$RGroup1 = "WVDLandscape01" 
$VMName1 = "testvm-1"

# Get NICs if you know the VM name
$VM = Get-AzVM -Name $VMName1 -ResourceGroupName $RGroup1 
$VM.NetworkProfile

<# 
Syntax -
Get-AzEffectiveRouteTable `
  -NetworkInterfaceName "<Name of NIC resource>" `
  -ResourceGroupName "<RG Name>" `
  | Format-Table
 #>

 # Examples
Get-AzEffectiveRouteTable `
  -NetworkInterfaceName $NIC1  `
  -ResourceGroupName $RGroup1 | Format-Table

Get-AzEffectiveRouteTable `
  -NetworkInterfaceName $NIC2  `
  -ResourceGroupName $RGroup1 ` Format-Table

Get-AzEffectiveRouteTable `
  -NetworkInterfaceName $NIC3  `
  -ResourceGroupName $RGroup1 | Format-Table

