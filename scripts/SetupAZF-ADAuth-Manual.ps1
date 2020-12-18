<################################################################################################################
This is the "Manual" process to configure AD authentication for Azure Files
   (automated!)
  Assumes you've already created:
	1) Storage account, and have "owner" rights to manually add roles in portal
	2) An OU in AD
	3) You have AAD synced to AD
	4) Are executing commands ona domain joined VM with computer account add rights
 
 Process here: https://docs.microsoft.com/en-us/azure/storage/files/storage-files-identity-auth-active-directory-enable
 Questions - johnkel at Microsoft.com
              or
             kavietme at Microsoft.com

This code came from a larger script written by John Kelbly I made some minor changes, mostly formatting
but did add the "Credentials" flag to the "New-ADComputer" for the case when the account running the code 
lacks sufficient domain privledges (Service Account).

###############################################################################################################-#>
# Add this to avoid mistakes
return


#################################
# Azure Settings & other parms
#################################

$AZResourceGroup        = "myresourcegroup"
$AZStorageAccountName   = "mystorageaccount"
$ADOUDistinguishedName  = "OU=StorageAccounts,DC=fabrikam,DC=com"
$AZSubscriptionID       = "xx1xx111-111x-111x-x11x-xx1x11x1111x"

<# 
  AD Settings
  You need to run to following to get all the parameters you need
  "SetAzStorageAccount" expects a PSObject:
#>
$Forest = Get-ADforest
$Domain = Get-ADdomain

# Can we reach an AD server?  If not exit.
if ((!($Forest)) -or (!($Domain))) {
    write-error ("Unable to contact AD. Exiting.")
    exit
}

#################################
# Step 1 - Create/Get kerborous key
#################################

# Need to be authenticated to Azure Portal
Connect-AzAccount

# Select the target subscription for the current session
Select-AzSubscription -SubscriptionId $AZSubscriptionID

# Uncomment if you want a new key - if you reset kerb1, anything using it will have to be updated
#New-AzStorageAccountKey -ResourceGroupName $AZResourceGroup -name $AZStorageAccountName -KeyName kerb1
$Keys = get-azstorageaccountkey -ResourceGroupName $AZResourceGroup -Name $AZStorageAccountName -listkerbkey
$kerbkey = $keys | where-object {$_.keyname -eq 'kerb1'} 

$StorageAcctKey = `
    (Get-AzStorageAccountKey `
    -ResourceGroupName $AZResourceGroup `
    -Name $AZStorageAcct).Value[0]


# Create the computer account password using the storage account key
$CompPassword = $kerbkey.value | ConvertTo-Securestring -asplaintext -force

#################################
# Step 2 Create Computer Account and SPN, and get AD information
#################################
<# 
  SPN should look like: cifs/your-storage-account-name-here.file.core.windows.net	

  NOTE - That only works for Azure Commercial - the DNS domain is different for other Azure clouds!
         Also note that I've done NO ERROR CHECKING/RECOVERY!
#>

<#
  Capture the account credentials of the service or admin account for adding computer accounts
  if the user running the script has insufficient privledges
#>
$AdminCreds = get-credential

# Computer Account - We are setting the password to never expire since it is the KerbKey for the storage account
New-ADComputer `
    -name $AZStorageAccountName `
    -path $ADOUDistinguishedName `
	  -Description "DO NOT DELETE - Azure File Share" `
  	-ServicePrincipalNames "cifs/$AZStorageAccountName.file.core.windows.net" `
  	-PasswordNeverExpires $true `
  	-OperatingSystem "Azure Files" `
    -AccountPassword $CompPassword
    -Credentials $AdminCreds  # Needed if the current user has insufficient privledges

# Save the PSObject for later
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
