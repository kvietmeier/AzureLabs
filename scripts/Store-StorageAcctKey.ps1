# Store your storage account credentials locally.
#
# The cmdkey utility is a command-line (rather than PowerShell) tool. We use Invoke-Expression to allow us to 
# consume the appropriate values from the storage account variables. The value given to the add parameter of the
# cmdkey utility is the host address for the storage account, <storage-account>.file.core.windows.net for Azure 
# Public Regions. $storageAccount.Context.FileEndpoint is used because non-Public Azure regions, such as sovereign 
# clouds or Azure Stack deployments, will have different hosts for Azure file shares (and other storage resources).
#
# These commands require you to be logged into your Azure account, run Login-AzAccount if you haven't
# already logged in.

$AZResourceGroup = Read-Host 'your-resource-group-name'
$storageAccountName = Read-Host 'your-storage-account-name'

$storageAccount = Get-AzStorageAccount -ResourceGroupName $AZResourceGroup -Name $storageAccountName
$storageAccountKeys = Get-AzStorageAccountKey -ResourceGroupName $AZResourceGroup -Name $storageAccountName

Invoke-Expression -Command ("cmdkey /add:$([System.Uri]::new($storageAccount.Context.FileEndPoint).Host) " + `
    "/user:AZURE\$($storageAccount.StorageAccountName) /pass:$($storageAccountKeys[0].Value)")