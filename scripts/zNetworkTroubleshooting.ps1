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

###  This is NOT a script so make sure we don't accidently try to run it!
return

###
# Stop on first error in case for some reason it gets past line 17
$ErrorActionPreference = "stop"


###---- Get my functions and credentials ----###

# Run from the location of the script
Set-Location $PSscriptroot
#Set-Location ../AzureLabs/scripts

### Get my functions and credentials
# Credentials  (stored outside the repo)
. 'C:\.info\miscinfo.ps1'

# Functions (In this repo)
. '.\FunctionLibrary.ps1'

# Imported from "FunctionLibrary.ps1"
# Are we connected to Azure with the corredt SubID?
Check-Login

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

  Powershell equivalents for common commands
  https://www.msnoob.com/windows-powershell-equivalents-for-common-networking-commands.html

#>

### Active Directory
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
# Replacement for ping and traceroute
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

   VM Level Tests - Azure Context - Get route tables and manipulate NICs

###----------------------------------------------------------------------------------------### 
#>


# You need these for Azure commands so set them here
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


<# 
###----------------------------------------------------------------------------------------### 

   Network Interface Commands - Azure VM or your Laptop

###----------------------------------------------------------------------------------------### 
#>

# List out all of the PowerShell Network Modules availble on your system. 
Get-Command -Module Net* | Group Module
<# Output
Count Name                      Group
----- ----                      -----
   35 NetEventPacketCapture     {Add-NetEventNetworkAdapter, Add-NetEventPacketCaptureProvider, Add-NetEventProvider, Add-NetEventVFPProvider...}
   34 NetworkTransition         {Add-NetIPHttpsCertBinding, Disable-NetDnsTransitionConfiguration, Disable-NetIPHttpsProfile, Disable-NetNatTransitionConfigur...
   13 NetLbfo                   {Add-NetLbfoTeamMember, Add-NetLbfoTeamNic, Get-NetLbfoTeam, Get-NetLbfoTeamMember...}
   13 NetNat                    {Add-NetNatExternalAddress, Add-NetNatStaticMapping, Get-NetNat, Get-NetNatExternalAddress...}
    7 NetSwitchTeam             {Add-NetSwitchTeamMember, Get-NetSwitchTeam, Get-NetSwitchTeamMember, New-NetSwitchTeam...}
   85 NetSecurity               {Copy-NetFirewallRule, Copy-NetIPsecMainModeCryptoSet, Copy-NetIPsecMainModeRule, Copy-NetIPsecPhase1AuthSet...}
   72 NetAdapter                {Disable-NetAdapter, Disable-NetAdapterBinding, Disable-NetAdapterChecksumOffload, Disable-NetAdapterEncapsulatedPacketTaskOff...
   19 NetworkSwitchManager      {Disable-NetworkSwitchEthernetPort, Disable-NetworkSwitchFeature, Disable-NetworkSwitchVlan, Enable-NetworkSwitchEthernetPort...}
   34 NetTCPIP                  {Find-NetRoute, Get-NetCompartment, Get-NetIPAddress, Get-NetIPConfiguration...}
    4 NetworkConnectivityStatus {Get-DAConnectionStatus, Get-NCSIPolicyConfiguration, Reset-NCSIPolicyConfiguration, Set-NCSIPolicyConfiguration}
    2 NetConnection             {Get-NetConnectionProfile, Set-NetConnectionProfile}
    4 NetQos                    {Get-NetQosPolicy, New-NetQosPolicy, Remove-NetQosPolicy, Set-NetQosPolicy}
#>

# Not PowerShell - go old school and list interfaces
netsh int ipv4 show interfaces
<# Output - 
Idx     Met         MTU          State                Name
---  ----------  ----------  ------------  ---------------------------
 17          35        1500  disconnected  Wi-Fi
  1          75  4294967295  connected     Loopback Pseudo-Interface 1
 18          25        1500  disconnected  Local Area Connection* 1
 10          65        1500  disconnected  Bluetooth Network Connection
  7          25        1500  disconnected  Local Area Connection* 2
 11          25        1500  connected     Pluggable Hub Link
  6          25        1500  connected     VirtualBox Host-Only Network
 89          15        1500  connected     vEthernet (WSL)
  4          25        1500  connected     VirtualBox Host-Only Network #2 
#>

# PowerShell - 
Get-NetAdapter
<# Output - 
Name                      InterfaceDescription                    ifIndex Status       MacAddress             LinkSpeed
----                      --------------------                    ------- ------       ----------             ---------
Wi-Fi                     Intel(R) Wi-Fi 6 AX201 160MHz                17 Disconnected D8-F8-83-5F-F1-D6     866.7 Mbps
Ethernet 2                Cisco AnyConnect Secure Mobility Cli...      16 Disabled     00-05-9A-3C-7A-00       995 Mbps
Ethernet                  Intel(R) Ethernet Connection (10) I2...      12 Not Present  54-05-DB-F5-E3-D7          0 bps
Pluggable Hub Link        Plugable Ethernet                            11 Up           8C-AE-4C-F6-9C-D7         1 Gbps
Bluetooth Network Conn... Bluetooth Device (Personal Area Netw...      10 Disconnected D8-F8-83-5F-F1-DA         3 Mbps
vEthernet (WSL)           Hyper-V Virtual Ethernet Adapter             89 Up           00-15-5D-31-A9-E6        10 Gbps
VirtualBox Host-Only N... VirtualBox Host-Only Ethernet Adapter         6 Up           0A-00-27-00-00-06         1 Gbps
VirtualBox Host-Only ...2 VirtualBox Host-Only Ethernet Adap...#2       4 Up           0A-00-27-00-00-04         1 Gbps
#>

# Get more detail on the objects
Get-NetIPConfiguration
Get-NetIPAddress
Get-NetIPAddress | Sort InterfaceIndex | FT InterfaceIndex, InterfaceAlias, AddressFamily, IPAddress, PrefixLength -Autosize
Get-NetIPAddress | ? AddressFamily -eq IPv4 | FT –AutoSize

Get-NetAdapter Wi-Fi | Get-NetIPAddress | FT -AutoSize


Get-NetIPAddress | ? AddressFamily -eq IPv4 | FT -AutoSize
<# Output - 
ifIndex IPAddress       PrefixLength PrefixOrigin SuffixOrigin AddressState PolicyStore
------- ---------       ------------ ------------ ------------ ------------ -----------
6       10.252.142.17             20 Manual       Manual       Preferred    ActiveStore
7       169.254.57.152            16 WellKnown    Link         Tentative    ActiveStore
5       169.254.214.153           16 WellKnown    Link         Tentative    ActiveStore
8       169.254.99.243            16 WellKnown    Link         Tentative    ActiveStore
9       192.168.1.192             24 Dhcp         Dhcp         Preferred    ActiveStore
1       127.0.0.1                  8 WellKnown    WellKnown    Preferred    ActiveStore
#>

Get-NetAdapter
<# Output - 
Name                      InterfaceDescription                    ifIndex Status       MacAddress             LinkSpeed
----                      --------------------                    ------- ------       ----------             ---------
Ethernet                  Intel(R) Ethernet Connection (4) I21...       8 Disconnected 8C-16-45-AC-FD-1C          0 bps
Bluetooth Network Conn... Bluetooth Device (Personal Area Netw...       7 Disconnected 30-24-32-47-E6-B2         3 Mbps
Wi-Fi                     Intel(R) Dual Band Wireless-AC 8265           9 Up           30-24-32-47-E6-AE       780 Mbps
Ethernet 3                Cisco AnyConnect Secure Mobility Cli...       6 Up           00-05-9A-3C-7A-00     862.4 Mbps
#>

Get-NetAdapter -Name *Ethernet*
<# Output - 
Name                      InterfaceDescription                    ifIndex Status       MacAddress             LinkSpeed
----                      --------------------                    ------- ------       ----------             ---------
Ethernet                  Intel(R) Ethernet Connection (4) I21...       8 Disconnected 8C-16-45-AC-FD-1C          0 bps
Ethernet 3                Cisco AnyConnect Secure Mobility Cli...       6 Up           00-05-9A-3C-7A-00     862.4 Mbps
#>

# Test-Netconnection - ping/tracroute replacement
Test-NetConnection www.microsoft.com

# Not really different from previous
Test-NetConnection -ComputerName www.microsoft.com -InformationLevel Detailed

# Limit to just RTT result
Test-NetConnection -ComputerName www.microsoft.com | Select -ExpandProperty PingReplyDetails | FT Address, Status, RoundTripTime

# try 10 times
$RemotePort = "80"
1..10 | % { Test-NetConnection -ComputerName www.microsoft.com -RemotePort $RemotePort } | FT -AutoSize

# Connection to Router?
Test-Netconnection 192.168.1.1
<# Output - 
ComputerName           : 192.168.1.1
RemoteAddress          : 192.168.1.1
InterfaceAlias         : Wi-Fi
SourceAddress          : 192.168.1.247
PingSucceeded          : True
PingReplyDetails (RTT) : 3 ms
#>

# With VPN up
Test-Netconnection
<# Output - note that the attempt fails - can't ping through firewall/proxies
WARNING: Ping to 13.107.4.52 failed with status: TimedOut

ComputerName           : internetbeacon.msedge.net
RemoteAddress          : 13.107.4.52
InterfaceAlias         : Ethernet 2
SourceAddress          : 10.209.173.207
PingSucceeded          : False
PingReplyDetails (RTT) : 0 ms

#>

# DNS Resolution - 
# https://docs.microsoft.com/en-us/powershell/module/dnsclient/resolve-dnsname
Resolve-DnsName

Resolve-DnsName www.microsoft.com
Resolve-DnsName microsoft.com -type SOA
Resolve-DnsName microsoft.com -Server 8.8.8.8 –Type A


# What is my routing table -
# https://docs.microsoft.com/en-us/powershell/module/nettcpip/get-netroute?view=windowsserver2019-ps
Get-NetRoute

Get-NetRoute | Format-List -Property *
Get-NetRoute -AddressFamily IPv6
Get-NetRoute -AddressFamily IPv4
Get-NetRoute -InterfaceIndex 12
Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Select-Object -ExpandProperty "NextHop"
Get-NetRoute | Where-Object -FilterScript { $_.NextHop -Ne "::" } | Where-Object -FilterScript { $_.NextHop -Ne "0.0.0.0" } | Where-Object -FilterScript { ($_.NextHop.SubString(0,6) -Ne "fe80::") }
Get-NetRoute | Where-Object -FilterScript {$_.NextHop -Ne "::"} | Where-Object -FilterScript { $_.NextHop -Ne "0.0.0.0" } | Where-Object -FilterScript { ($_.NextHop.SubString(0,6) -Ne "fe80::") } | Get-NetAdapter
Get-NetRoute | Where-Object -FilterScript { $_.ValidLifetime -Eq ([TimeSpan]::MaxValue) }








