###==================================================###
###           NetworkTroubleShooting.ps1
### Commands to validate/test network connectivity
### Created by:  Karl Vietmeier
###    Not really a script
###==================================================###

return
# Get my functions and credentials
. "C:\bin\resources.ps1"

# Need - 
$AZResourceGroup = "WVDLandscape01"
$AZStorageAcct = "kvwvdlocalstorage02"
$AZFileShare = "userprofiles"
$SMBSharePath = "\\kvwvdstorage01.file.core.windows.net\userprofiles\"

# Imported - uncomment and set yourself
#$SubID = "SubID of Subscription"
#$SubName = "Subscription Name"

###-----------------------------------------------------------------------------###
# Check to see if you are alrewady connected to a Sub.
$context = Get-AzContext

if (!$context -or ($context.Subscription.Id -ne $SubID)) 
{
    # Save your creds
    $creds = get-credential
    Connect-AzAccount -Credential $cred -Subscription $SubID
} 
else 
{
    Write-Host "SubscriptionId '$SubID' already connected"
}

###-----------------------------------------------------------------------------###


function InstallPSModules 
{
  ### You are going to need some modules - of course :)
  # Run these as an Admin:
  # You might need to set this - (set it back later if you need to)
  Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force

  # May need to Upgrade PowerShellGet and other modules - upgrade NuGet first
  Install-PackageProvider -Name NuGet -Force
  Install-Module -Name PowerShellGet -Force

  # Azure and AD Modules - probably have these
  Install-Module -Name "Az" -Repository 'PSGallery' -Scope 'CurrentUser' -AllowClobber -Force -Verbose
  Install-Module -Name "AzureAD" -Repository 'PSGallery' -Scope 'CurrentUser' -AllowClobber -Force -Verbose

  # I needed this to do some GPO work
  Install-Module -Name GPRegistryPolicy

  # WVD Modules
  Install-Module -Name Az.DesktopVirtualization -RequiredVersion 0.1.0 -SkipPublisherCheck

}

InstallPSModules

# For AzureFiles AD Setup - download and follow install instructions:
# AzFilesHybrid:   https://github.com/Azure-Samples/azure-files-samples/releases
# Unzip to a folder and run the CopyToPSPath.ps1 script to put the module in the search path.  
# After you unzip and run the copy script - cd out of the directory and just run:
Import-Module AzFilesHybrid 



# Test for Port 445 
# This command requires you to be logged into your Azure account, run Login-AzAccount if you haven't
# already logged in.
# The ComputerName, or host, is <storage-account>.file.core.windows.net for Azure Public Regions.
# $storageAccount.Context.FileEndpoint is used because non-Public Azure regions, such as sovereign clouds
# or Azure Stack deployments, will have different hosts for Azure file shares (and other storage resources).

# Test port 445
Test-NetConnection -ComputerName ([System.Uri]::new($AZStorageAcct.Context.FileEndPoint).Host) -Port 445

## Check the AZF Setup
Debug-AzStorageAccountAuth -StorageAccountName $AZStorageAcct -ResourceGroupName $AZResourceGroup -Verbose

### Basic Networking
# - Note - The WVD Gateway blocks ICMP but you can still test name resolution
#   even if the ping fails.
# Test resolver against known host that responds to ICMP 
ping ya.ru

# Test ICMP echo against known top level DNS server IP
ping 8.8.8.8

### Check the Azure route table - info in the host OS is useless
#
# Get Azure effective route table
# Need Az Module and be connected to your Subscription (see above)
$NIC1 = "wvd-mgmtserver803"
$NIC2 = "testvm-0-nic"
$NIC3 = "testvm-1-nic"
$RGroup1 = "WVDLandscape01" 
$VMName1 = "testvm-1"

# Get NICs if you know the VM
$VM = Get-AzVM -Name $VMName1 -ResourceGroupName $RGroup1 
$VM.NetworkProfile

# Syntax -
#Get-AzEffectiveRouteTable `
#  -NetworkInterfaceName "<Name of NIC resource>" `
#  -ResourceGroupName "<RG Name>" `
#  | Format-Table

# Examples
Get-AzEffectiveRouteTable `
  -NetworkInterfaceName $NIC1  `
  -ResourceGroupName $RGroup1 `
  | Format-Table

Get-AzEffectiveRouteTable `
  -NetworkInterfaceName $NIC2  `
  -ResourceGroupName $RGroup1 `
  | Format-Table

Get-AzEffectiveRouteTable `
  -NetworkInterfaceName $NIC3  `
  -ResourceGroupName $RGroup1 `
  | Format-Table

