###========================================================================###
<# 
  Script/Filename:  NetworkTroubleShooting.ps1
  Commands to validate/test network connectivity
  Created by:  Karl Vietmeier
    Not really a script but a collection of PowerShell and Azure Tools/Commands
  
   Useful tool NTttcp (like iperf):
   https://gallery.technet.microsoft.com/NTttcp-Version-528-Now-f8b12769/file/159655/1/NTttcp-v5.33.zip
   https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-bandwidth-testing

#>

###========================================================================###

### For safety - comment/uncomment as desired
return
###

###---- Get my functions and credentials ----###

Set-Location ../AzureLabs/scripts

# Credentials  (stored outside the repo)
. '..\..\Certs\resources.ps1'

# Functions (In this repo)
. '.\FunctionLibrary.ps1'

# Imported from "FunctionLibrary.ps1"
# Are we connected to Azure with the corredt SubID?
Login-NoPrompt

###---- End my functions and credentials ----###

# Install required and useful PS Modules for administration - script in this directory
. .\SetupPowerShellModules.ps1

# Imported from "resources.ps1" - uncomment and set yourself
#$SubID = "SubID of Subscription"
#$SubName = "Subscription Name"


# Enable ICMPv4-In without disabling Windows Firewall
New-NetFirewallRule –DisplayName "Allow ICMPv4-In" –Protocol ICMPv4

###--- What WVD Gateway will I hit from my current client?
# Desktop Client
Invoke-RestMethod -Uri "https://afd-rdgateway-r1.wvd.microsoft.com/api/health" | Select-Object -ExpandProperty RegionUrl 

# Web Client
Invoke-RestMethod -Uri "https://rdweb.wvd.microsoft.com/api/health" | Select-Object -ExpandProperty RegionUrl 


###--- Basic Networking
<# 
  "Test-NetConnection"
  https://docs.microsoft.com/en-us/powershell/module/nettcpip/test-netconnection?view=win10-ps
  
  NOTE - The WVD Gateway and all other Azure services will not respond to an ICMP echo request
    So 

  Common Question - 
  https://docs.microsoft.com/en-us/azure/virtual-network/what-is-ip-address-168-63-129-16
#>

# On the VM
# Find a list of DCs in the domain:
nltest /dclist:<domainname>

# Example - 
PS C:\Users\kavietme> nltest /dclist:northamerica
Get list of DCs in domain 'northamerica' from '\\CY1-NA-DC-08'.
    HUM-NA-DC-03.northamerica.corp.microsoft.com        [DS] Site: NA-PR-HUM
    HUM-NA-DC-04.northamerica.corp.microsoft.com        [DS] Site: NA-PR-HUM
    CO1-NA-DC-97.northamerica.corp.microsoft.com        [DS] Site: NA-US-BCDR
    CY1-NA-DC-97.northamerica.corp.microsoft.com        [DS] Site: NA-US-BCDR
    CO1-NA-DC-05.northamerica.corp.microsoft.com [PDC]  [DS] Site: NA-WA-TUKDC
    CO1-NA-DC-06.northamerica.corp.microsoft.com        [DS] Site: NA-WA-TUKDC
    CO1-NA-DC-07.northamerica.corp.microsoft.com        [DS] Site: NA-WA-TUKDC
    CO1-NA-DC-08.northamerica.corp.microsoft.com        [DS] Site: NA-WA-TUKDC
    CY1-NA-DC-05.northamerica.corp.microsoft.com        [DS] Site: NA-WA-TUKDC
    CY1-NA-DC-07.northamerica.corp.microsoft.com        [DS] Site: NA-WA-TUKDC
    CY1-NA-DC-08.northamerica.corp.microsoft.com        [DS] Site: NA-WA-TUKDC
    CY1-NA-DC-06.northamerica.corp.microsoft.com        [DS] Site: NA-WA-TUKDC
    HUM-NA-DC-01.northamerica.corp.microsoft.com        [DS] Site: NA-PR-HUM
                                 AzureADKerberos [RODC]
The command completed successfully

### ICMP Based Tools - ping etc
# Always the first place to start - they test the resolver too. 

###--- Built-in Windows commands
# Works like tracert
pathping.exe
# https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/pathping

# As you expect
tracert.exe
# https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/tracert 


###--- PowerShell - 
# Replacement for ping
Test-NetConnection

# Test resolver against known host that responds to ICMP 
Test-NetConnection ya.ru

# Test ICMP echo against known top level DNS server IP
Test-NetConnection 8.8.8.8

# Get more detailed information on routing (Run as Administrator)
# 2 options - simple traceroute and more detailed routing test
Test-NetConnection -ComputerName www.contoso.com -DiagnoseRouting -InformationLevel Detailed
Test-NetConnection -ComputerName outlook.office365.com -DiagnoseRouting -InformationLevel Detailed
Test-NetConnection -ComputerName outlook.office365.com -TraceRoute -InformationLevel Detailed
Test-NetConnection -ComputerName outlook.office365.com -TraceRoute 

# Test against a specific port
# (Will fail)
Test-NetConnection 168.63.129.16 -port 53

# Works 
Test-NetConnection 8.8.8.8 -port 53

###--- DNS Resolving
# https://docs.microsoft.com/en-us/powershell/module/dnsclient/resolve-dnsname?view=win10-ps
# Use instead of nslookup

# 3 different forms - investigate different record types
Resolve-dnsname -name www.google.com
Resolve-dnsname -name www.google.com -type a
Resolve-dnsname -name www.google.com -type cname

### Use with Private Link
# Running this command should show, the A record that DNS knows
Resolve-dnsname -name filescorecloud.file.core.windows.net -type a

# This command is the A record that will show, if on network/domain, the internal 
# IP address of a private endpoint
Resolve-DnsName -name filescorecloud.privatelink.file.core.windows.net
Resolve-DnsName -name kv82579fslogix02.privatelink.file.core.windows.net
Resolve-DnsName -name kv82579fslogix02.file.core.windows.net

# This command will show the storage account still has a public IP, but how access 
# to the contents is internal
Resolve-DnsName -name filescorecloud.blob.core.windows.net

<# 
  For "in host" routes - what the OS sees use: "Get-NetRoute"
  https://docs.microsoft.com/en-us/powershell/module/nettcpip/get-netroute?view=win10-ps
#>
Find-NetRoute -RemoteIPAddress "10.79.197.200"
  

# To test pereformance - Grab and install TTttcp
# <TBD>



<#
###----------------------------------------------------------------------------------------### 
   The following commands require you to be logged into your Azure account
   Use "Connect-AzAccount" to authenticate

###----------------------------------------------------------------------------------------### 

  To check the routing table from the Azure SDN perspective use: "Get-AzEffectiveRouteTable"
  Requirement: Need Az Module and be connected to your Subscription (see above)
  In some cases info in the host OS can be misleading/not useful especially in an "all Azure" infrastructure.
  https://docs.microsoft.com/en-us/powershell/module/az.network/get-azeffectiveroutetable?view=azps-4.6.0

  ### Virtual Networks docs
  https://docs.microsoft.com/en-us/azure/virtual-machines/windows/ps-common-network-ref
  https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview
  https://docs.microsoft.com/en-us/azure/virtual-network/diagnose-network-routing-problem

#>

# Will Need for various tests - 
$AZResourceGroup  = "WVDLandscape01"
$AZStorageAcct    = "kvstor1551"
$AZFileShare      = "userprofiles"
$SMBSharePath     = "\\kvstor1551.file.core.windows.net\userprofiles\"
$VMName           = "testvm-1"
$Region           = "westus2"


# Dump the AddressSpace/subnets/DHCP Options for vNet
$RGName = "CoreInfrastructure-rg"
$VNetName = "VnetCore"
$vnet = Get-AzVirtualNetwork -Name $VNetName -ResourceGroupName $RGName
Write-Output $vnet.DhcpOptions
Write-Output $vnet.AddressSpace
Write-Output $vnet.Subnets.AddressPrefix 


###--- Network Watcher
<# 
  Azure Native Tool - Like TCPdump for Azure SDN: 
  https://azure.microsoft.com/en-us/services/network-watcher/

  * Remotely capture packet data for your virtual machines
  * Monitor your virtual machine network security using flow logs and security group view
  * Diagnose your VPN connectivity issues

Install extension in VM - 
Set-AzVMExtension `
  -ResourceGroupName "myResourceGroup1" `
  -Location "WestUS" `
  -VMName "myVM1" `
  -Name "networkWatcherAgent" `
  -Publisher "Microsoft.Azure.NetworkWatcher" `
  -Type "NetworkWatcherAgentWindows" `
  -TypeHandlerVersion "1.4"

#>

<# 
  Test for Port 445 
  The ComputerName, or host, is <storage-account>.file.core.windows.net for Azure Public Regions.
  $storageAccount.Context.FileEndpoint is used because non-Public Azure regions, such as sovereign clouds
  or Azure Stack deployments, will have different hosts for Azure file shares (and other storage resources).
#>
# Is Port 445 open?
Test-NetConnection -ComputerName ([System.Uri]::new($AZStorageAcct.Context.FileEndPoint).Host) -Port 445

# Check the AZF Setup (need AZ Storage Module loaded)
Debug-AzStorageAccountAuth -StorageAccountName $AZStorageAcct -ResourceGroupName $AZResourceGroup -Verbose

<# 
###----------------------------------------------------------------------------------------### 
###----------------------------------------------------------------------------------------### 

   VM Level Tests - Azure Context

###----------------------------------------------------------------------------------------### 
#>


# You need these for Azure commands
$NIC1 = "ubuntu-01989"
$NIC2 = "ubuntu01.nic2"
$NIC3 = ""
$RGgroup1 = "Networktests" 
$VMName1 = "Ubuntu-01"

# Get NICs if you know the VM name
$VM = Get-AzVM -Name $VMName1 -ResourceGroupName $RGgroup1 
$VM.NetworkProfile

<# 
  Routing Information - 
  Syntax -
  Get-AzEffectiveRouteTable `
    -NetworkInterfaceName "<Name of NIC resource>" `
    -ResourceGroupName "<RG Name>" | Format-Table
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


### Get effective NSG security rules
<#
   While you are in the terminal, logged in to Azure, you can get more info without clicking through 
   5 levels of Portal menues:
   https://docs.microsoft.com/en-us/powershell/module/az.network/get-azeffectivenetworksecuritygroup?view=azps-4.6.1 
   
   Get-AzEffectiveNetworkSecurityGroup
     -NetworkInterfaceName <String>
     [-ResourceGroupName <String>]
     [-DefaultProfile <IAzureContextContainer>]
     [<CommonParameters>]

#>

Get-AzEffectiveNetworkSecurityGroup `
  -NetworkInterfaceName "$NIC3"  `
  -ResourceGroupName $RGroup1 | Format-Table



###---   Manipulate NICs - swap primaries 
$NIC1 = "ubuntu-01989"
$NIC2 = "ubuntu01.nic2"
$NIC3 = "ubuntu-0240"
$NIC4 = "ubuntu02-nic2"
$RGgroup1 = "Networktests" 
$VMName1 = "Ubuntu-01"
$VMName2 = "Ubuntu-02"

$VM1 = Get-AzVM -Name $VMName1 -ResourceGroupName $RGroup1
$VM2 = Get-AzVM -Name $VMName2 -ResourceGroupName $RGroup1
$NICS = $VM1.NetworkProfile.NetworkInterfaces
$NICS

# List existing NICs on the VM and find which one is primary
$VM1.NetworkProfile.NetworkInterfaces
$VM2.NetworkProfile.NetworkInterfaces

### These steps make a big mess - might be faster to start over.
# Set NIC [1] to be primary
$VM1.NetworkProfile.NetworkInterfaces[0].Primary = $false
$VM1.NetworkProfile.NetworkInterfaces[1].Primary = $true

# Set NIC [1] to be primary
$VM2.NetworkProfile.NetworkInterfaces[0].Primary = $false
$VM2.NetworkProfile.NetworkInterfaces[1].Primary = $true

# Update the VM state in Azure
Update-AzVM -VM $VM1 -ResourceGroupName $RGroup1
Update-AzVM -VM $VM2 -ResourceGroupName $RGroup1

# Accelerated Networking (VM needs to be deallocated)
$NIC = "ubuntu02-dpdk"
$RGgroup1 = "Networktests" 

$NIC=Get-AzNetworkInterface -Name $NIC -ResourceGroupName $RGgroup1
$NIC.EnableAcceleratedNetworking = $True
$NIC | Set-AzNetworkInterface







