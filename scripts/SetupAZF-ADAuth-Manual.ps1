###############################################################################################################
<#
  This is the "Manual" process to configure AD authentication for Azure Files
     (automated!)
    Assumes you've already created:
  	1) Storage account, and have "owner" rights to manually add roles in portal
  	2) An OU in AD
  	3) You have AAD synced to AD
  	4) Are executing commands on a domain joined VM as a domain admin
 
  Process here: https://docs.microsoft.com/en-us/azure/storage/files/storage-files-identity-auth-active-directory-enable
  Questions - johnkel at Microsoft.com
                or
              kavietme at Microsoft.com

  This code came from a larger script written by John Kelbly I made some minor changes, mostly formatting
  but did add the "Credentials" flag to the "New-ADComputer" for the case when the account running the code 
  lacks sufficient domain privledges (Service Account).

  This version of the script doesn't modify the NTFS ACLs.
#>
###############################################################################################################

# Add this to avoid mistakes - uncomment to run as script
return

# Stop on first error
$ErrorActionPreference = "stop"

# Run from the location of the script during run time
Set-Location $PSscriptroot

# If running line-by-line, use this if you need to be in a certain
# folder location - modify for your environment
Set-Location ../AzureLabs/scripts


###==========================================================================###
###              Get my functions and credentials                            ###
###                                                                          ###

# Credentials  (stored outside the repo)
. '..\..\Certs\resources.ps1'

# Functions (In this repo)
. '.\FunctionLibrary.ps1'

# Imported from "FunctionLibrary.ps1"
# Are we connected to Azure with the corredt SubID?
Check-Login


###==========================================================================###
###              Azure Tenant and local AD information                       ###
###                                                                          ###
<#
I pull these in from my sourced files above, you can uncomment these lines
for your own use
#>
#$AZResourceGroup        = "myresourcegroup"
#$AZStorageAccountName   = "mystorageaccount"
#$ADOUDistinguishedName  = "OU=StorageAccounts,DC=fabrikam,DC=com"
#$AZSubscriptionID       = "xx1xx111-111x-111x-x11x-xx1x11x1111x" 

<# 
  AD Settings:
  You need to run to following to get all the parameters you need
  and check for AD connectivity. 
#>
$Forest = Get-ADforest
$Domain = Get-ADdomain

# Can we reach an AD server?  If not exit.
if ((!($Forest)) -or (!($Domain))) {
    write-error ("Unable to contact AD. Exiting.")
    exit
}


###==========================================================================###
###     Step 1 - Authenticate to Azure Portal                                ###
###                                                                          ###

#---  Need to be authenticated to Azure Portal
#---  Uncomment these - my version using a function call (above) to do this
#Connect-AzAccount

# Select the target subscription for the current session
#Select-AzSubscription -SubscriptionId $AZSubscriptionID


###==========================================================================###
###     Step 2 - Create/Get kerborous key                                    ###
###                                                                          ###

# Remove/comment - just added for testing
$AZStorageAccountName   = "kv82579msix01"

# Uncomment if you want a new key
# BUT - if you reset a key anything using it will have to be updated
#New-AzStorageAccountKey -ResourceGroupName $AZResourceGroup -name $AZStorageAccountName -KeyName kerb1

# Grab key1
# Array index -
# .Value[0] = key1; .Value[1] = key2; .Value[2] = kerb1; .Value[3] = kerb2
$StorageAcctKey = (Get-AzStorageAccountKey -ResourceGroupName $AZResourceGroup -Name $AZStorageAccountName -ListKerbKey).Value[0]

# Create the computer account password using the storage account key
$CompPassword = $StorageAcctKey | ConvertTo-Securestring -asplaintext -force

###==========================================================================###
###     Step 3 - Create Computer Account and SPN and get AD information.     ###
###     This step adds the storage account as a computer account in the      ###
###     domain.                                                              ### 
###                                                                          ###
<# 
  SPN = "Service Principle Name"
  Should look like: cifs/your-storage-account-name-here.file.core.windows.net	

  NOTE - This only works for Azure Commercial
         The DNS domain is different for other Azure clouds!
#>

<#
  "get-credential" will capture the account credentials of the service or 
  admin account used to add computer accounts to the domain.
  IMPORTANT: This can be a different account if the user running the script has insufficient privledges.
  
  This will create a pop-up to allow you to enter the username/password that
  will get stored as a PSObject for later use
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

# Save the PSObject for later - you need the SID for the next step.
$Computer = get-ADComputer $AZStorageAccountName

###==========================================================================###
###     Step 3 - Update Storage Account                                      ### 
###     This step uses the Azure credentials you authenticated with          ###
###     using "Connect-AzAccount"                                            ###
###                                                                          ###

<# 
  This step creates the "link" between the AD computer account added above
  and the Storage Account in Azure.
  It sets the feature flag on the target storage account with:
  "EnableActiveDirectoryDomainServicesForFile"
  NOTE: "SetAzStorageAccount" expects PSObjects
#>

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


###==========================================================================###
### Step 4 Confirm settings                                                  ###
###                                                                          ###

# Get the target storage account
$storageaccount = Get-AzStorageAccount -ResourceGroupName $AZResourceGroup -Name $AZStorageAccountName

# List the directory service of the selected service account
$storageAccount.AzureFilesIdentityBasedAuth.DirectoryServiceOptions

# List the directory domain information if the storage account has enabled AD DS authentication for file shares
$storageAccount.AzureFilesIdentityBasedAuth.ActiveDirectoryProperties
