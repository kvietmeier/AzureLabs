###############################################################################################################
#  This is the "Manual" process to configure AD authentication for Azure Files
#  (automated!)
#  Assumes you've already created:
#	1) storage account, and have "owner" rights to manually add roles in portal
#	2) an OU in AD
#	3) you have AAD synced to AD
#	4) are executing commands ona domain joined VM with computer account add rights
# 
# Process here:  		https://docs.microsoft.com/en-us/azure/storage/files/storage-files-identity-auth-active-directory-enable
#  questions - johnkel at Microsoft.com
###############################################################################################################
#
#################################
# Azure Settings & other parms
#################################
#
$AZResourceGroup 	= "myresourcegroup"
$AZStorageAccountName	= "mystorageaccount"
$ADOUDistinguishedName 	= "OU=StorageAccounts,DC=fabrikam,DC=com"
$AZSubscriptionID	= "xx1xx111-111x-111x-x11x-xx1x11x1111x"

$ShareName		= "profiles"
$drive 			= "Y:"

#AD Settings - You will want to run to following to get all the parameters you need:
$Forest = get-adforest
$Domain = get-ADdomain

#################################
#Step 1 - create kerb key
#################################
#
Connect-AzAccount
#Select the target subscription for the current session
Select-AzSubscription -SubscriptionId $AZSubscriptionID

#New-AzStorageAccountKey -ResourceGroupName $AZResourceGroup -name $AZStorageAccountName -KeyName kerb1
$Keys = get-azstorageaccountkey -ResourceGroupName $AZResourceGroup -Name $AZStorageAccountName -listkerbkey
$kerbkey = $keys | where-object {$_.keyname -eq 'kerb1'} 
$CompPassword = $kerbkey.value | ConvertTo-Securestring -asplaintext -force

#################################
# Step 2 Create Computer Account and SPN, and get AD information
#################################

#
# SPN should look like:		cifs/your-storage-account-name-here.file.core.windows.net	
#
#NOTE - that only works for Azure Commercial - the DNS domain is different for other Azure clouds!
#       also note that I've done NO ERROR CHECKING / REOVERY!
#

<# 
Capture the account credetials of the service account for adding computer accounts - or admin
if the user running the script has insufficient prviledges
#>
$usercreds = get-credential

new-ADComputer `
    -name $AZStorageAccountName `
    -path $ADOUDistinguishedName `
	-Description "DO NOT DELETE - Azure File Share" `
	-ServicePrincipalNames "cifs/$AZStorageAccountName.file.core.windows.net" `
	-PasswordNeverExpires $true `
	-OperatingSystem "Azure Files" `
    -AccountPassword $CompPassword
    -Credentials $usercreds  # Needed if the current user has insufficient privledges

$Computer = get-ADComputer $AZStorageAccountName

#################################
# Step 3 update Storage account
#################################

# Set the feature flag on the target storage account and provide the required AD domain information
Set-AzStorageAccount `
        -ResourceGroupName $AZResourceGroup `
        -Name $AZStorageAccountName `
        -EnableActiveDirectoryDomainServicesForFile $true `
        -ActiveDirectoryDomainName $Domain.dnsroot `
        -ActiveDirectoryNetBiosDomainName $Domain.netbiosname `
        -ActiveDirectoryForestName $Forest.name `
	    -ActiveDirectoryDomainGuid $Domain.ObjectGUID `
        -ActiveDirectoryDomainsid $Domain.DomainSID `
        -ActiveDirectoryAzureStorageSid $Computer.sid


#################################
#Step 4 Confirm settings
#################################
#
# Get the target storage account
$storageaccount = Get-AzStorageAccount -ResourceGroupName $AZResourceGroup -Name $AZStorageAccountName

# List the directory service of the selected service account
$storageAccount.AzureFilesIdentityBasedAuth.DirectoryServiceOptions

# List the directory domain information if the storage account has enabled AD DS authentication for file shares
$storageAccount.AzureFilesIdentityBasedAuth.ActiveDirectoryProperties
