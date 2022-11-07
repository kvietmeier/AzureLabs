# Test for Port 445 
# The ComputerName, or host, is <storage-account>.file.core.windows.net for Azure Public Regions.
# $storageAccount.Context.FileEndpoint is used because non-Public Azure regions, such as sovereign clouds
# or Azure Stack deployments, will have different hosts for Azure file shares (and other storage resources).

# Get my functions and credentials
. "C:\bin\resources.ps1"


# You might need to set this - (set it back later if you need to)
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force

# Run these as an Admin:
# May need to Upgrade PowerShellGet and other modules - upgrade NuGet first
#Install-PackageProvider -Name NuGet -Force
#Install-Module -Name PowerShellGet -Force

# Azure and AD Modules - probably have these
#Install-Module -Name "Az" -Repository 'PSGallery' -Scope 'CurrentUser' -AllowClobber -Force -Verbose
#Install-Module -Name "AzureAD" -Repository 'PSGallery' -Scope 'CurrentUser' -AllowClobber -Force -Verbose

# Test for Port 445 
# The ComputerName, or host, is <storage-account>.file.core.windows.net for Azure Public Regions.
# $storageAccount.Context.FileEndpoint is used because non-Public Azure regions, such as sovereign clouds
# or Azure Stack deployments, will have different hosts for Azure file shares (and other storage resources).

# Login with creds from sourced file
$context = Get-AzContext

if (!$context -or ($context.Subscription.Id -ne $SubID)) 
{
    # Save your creds
    $cred = get-credential
    Connect-AzAccount -Credential $cred -Subscription $SubID
} 
else 
{
    Write-Host "SubscriptionId '$SubID' already connected"
}


# Start testing code
#$AZResourceGroup = 'your-resource-group-name'
#$StorageAccountName = 'your-storage-account-name'

$AZResourceGroup = 'WVDLandscape01'
$StorageAccountName = 'kvstor1551'

# This command requires you to be logged into your Azure account, run Login-AzAccount if you haven't
# already logged in.
$StorageAccount = Get-AzStorageAccount -ResourceGroupName $AZResourceGroup -Name $StorageAccountName

# Test port 445
Test-NetConnection -ComputerName ([System.Uri]::new($StorageAccount.Context.FileEndPoint).Host) -Port 445