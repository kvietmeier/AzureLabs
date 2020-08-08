###################################################################################################################
###  
###  Name: SetupAzureFilesForAD.ps1
###  Written By:  Karl Vietmeier
###  Source Doc: 
###  https://docs.microsoft.com/en-us/azure/storage/files/storage-files-identity-auth-active-directory-enable
### 
##################################################################################################################

### Here for safety - comment/uncomment as desired
#return

# Get my functions and credentials
. "C:\bin\resources.ps1"

# Funtion in the resources file -
Login

###=================================== Prereqs =======================================###
# 1: The correct set of PowerShell Modules
# 2: An AD environment sync'd to Azure AD
# 3: Domain Admin account sync'd up to AAD
# 4: An Azure storage account
# 5: A fileshare in that account
# 6: Verify port 445 connectivity
# - If you have TLS errors with PS (Server 2016) - you might need this:
# [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls11,Tls12'


###===== Manual Workflow
# 1.) Enable Azure Files AD authentication on your storage account.
# 2.) Assign access permissions for a share to the Azure AD identity 
#     (a user, group, or service principal) that is in sync with the target AD identity.
# 3.) Configure ACLs over SMB for directories and files.
# 4.) Mount an Azure file share from an AD domain joined VM.
# 5.) Rotate AD account password (Optional)

###---------------------------------- Variables -----------------------------------###

### - Sensitive - stored in external file
#$DomainAdmin ="Domain Admin UPN sync'd to Azure Active Directory" 
#$ADOUdistinguishedname = "OU where the Azure File Share computer account should live"
#$SubName = "Subscription Name"
#$SubID = "Subscription ID"

# AD GroupIDs (For WVD)
# AAD FSLogix SMB Elevated Contributor Group
#$ElevContribGroupId = "GUID - not the SID" 
# AAD FSLogix SMB Contributor Group
#$ContribGroupId = "GUID - not the SID"

# Are they set correctly?
Write-Host ""
Write-Host "Account Information"
Write-Host "Domain Admin Account:           $DomainAdmin"
Write-Host "AD OU for Storage Account:      $ADOUdistinguishedname"
Write-Host "Azure SubscriptinID:            $SubID"
Write-Host "Azure Subsription Name:         $SubName"
Write-Host "SMB Elevated Contributor AD Group GUID:   $ElevContribGroupId" 
Write-Host "SMB Contributor AD Group GUID:            $ContribGroupId" 
Write-Host ""


# Not very sensitive, set here to over-ride or comment out to use externally stored values
$AZResourceGroup = "WVDLandscape01"
$AZStorageAcct = "kvstor1551"
$AZFileShare = "profiles"

###--- Set Variables for each of the icacls options and "net use"
# Set to match your AD configuration - you need the SAM Account Name
#  $ElevateContrib = "<domain>\<SAM Account Name of AD Group>"
$ElevateContrib = "gabbro\AZFFSLogixElevatedContributor"
$Contrib = "gabbro\AZFFSLogixContributor"

# Drive letter for share mapping "net use"
$DriveLetter = "O:"

### NOTE: Don't change these - they are the best practices for FSLogix 
#   Profile Shares - set permissions
$Grant = "/grant:r"
$Remove = "/remove"
$ReplaceInherit = "/inheritance:r"
$FullControl = ":(OI)(CI)(F)"
$Modify = ":(OI)(CI)(IO)(M)"
$ModifyContrib = ":(M)"

# Users/Groups - 
$CreatorOwner = "Creator Owner"
$AuthUsers = "Authenticated Users"
$BuiltinUsers = "Builtin\Users"

###---

###====================  Access Azure Tenant  =====================###        
# Are we already connected to our Azure Account?
# If so, continue, otherwise, login

$context = Get-AzContext

if (!$context -or ($context.Subscription.Id -ne $SubID)) 
{
    # Save your creds
    $creds = get-credential
    Connect-AzAccount -Credential $creds -Subscription $SubID
    
    # Change subscription context (May not need this)
    Select-AzSubscription -SubscriptionId $SubName
} 
else 
{
    Write-Host "SubscriptionId '$SubID' already connected"
}

###=================  End - Access Azure Tenant  ================###        


###====================  Enable Storage Account for AD Auth  =====================###        
#   Reason for the script - the step you need PowerShell for. Everything after
#   this can be done in the various GUI tools, Azure Portal, File Explorer, etc.

# Command to run:
# Join-AzStorageAccountForAuth `
#     -ResourceGroupName "<resource-group-name>" `
#     -Name "<storage-account-name>" `
#     -DomainAccountType "ComputerAccount"
#     -OrganizationalUnitDistinguishedName "<ou-distinguishedname-here>" (optional)

# Full command with OU 
Join-AzStorageAccountForAuth `
    -ResourceGroupName $AZResourceGroup `
    -Name $AZStorageAcct `
    -DomainAccountType "ComputerAccount" `
    -OrganizationalUnitDistinguishedName $ADOUdistinguishedname

###================     END - Setup Storage Account for AD Auth  =================###        

###====================         Verification Section         =====================###        
###                   This section has code to verify the setup                   ###

# You can run the Debug-AzStorageAccountAuth cmdlet to conduct a set of basic checks on your AD 
# configuration with the logged on AD user. This cmdlet is supported on AzFilesHybrid v0.1.2+ version.
# For more details on the checks performed in this cmdlet, see Azure Files Windows troubleshooting guide.
# https://docs.microsoft.com/en-us/azure/storage/files/storage-troubleshoot-windows-file-connection-problems
Debug-AzStorageAccountAuth `
    -StorageAccountName $AZStorageAcct `
    -ResourceGroupName $AZResourceGroup `
    -Verbose

### Grab the storage account info (creates an array) so we can verify a few things alomng the way
# $storageaccount = Get-AzStorageAccount `
#    -ResourceGroupName "<resource-group-name>" `
#    -Name "<storage-account-name>"
$StorageAccount = `
    Get-AzStorageAccount -ResourceGroupName $AZResourceGroup `
    -Name $AZStorageAcct 

# Verify - List the directory service of the selected service account
$StorageAccount.AzureFilesIdentityBasedAuth.DirectoryServiceOptions

# Verify - List the directory domain information if the storage account has enabled AD authentication for file shares
$StorageAccount.AzureFilesIdentityBasedAuth.ActiveDirectoryProperties


###==================== END -   Verification Section         =====================###        


###====================     Assign Roles for the Share       =====================###        
###                This section assigns AIM roles to the share.                   ###

# Set the name of the custom roles in string variables - Use the built-in roles 
# Storage File Data: 
#  SMB Share Reader
#  Storage File Data SMB Share Contributor
#  Storage File Data SMB Share Elevated Contributor
$FileShareContributorRole = `
    Get-AzRoleDefinition "Storage File Data SMB Share Contributor"
$FileShareElevatedContributorRole = `
    Get-AzRoleDefinition "Storage File Data SMB Share Elevated Contributor"

# Constrain the scope of the role assignent to the target file share use variables from above -
$p1 = "subscriptions"
$p2 = "resourceGroups"
$p3 = "providers/Microsoft.Storage/storageAccounts"
$p4 = "fileServices/default/fileshares"

# Shorten commandline for display
$scope = "/$p1/$SubID/$p2/$AZResourceGroup/$p3/$AZStorageAcct/$p4/$AZFileShare"

# Fullength -  very long
#$scope = "/subscriptions/$SubID/resourceGroups/$AZResourceGroup/providers/Microsoft.Storage/storageAccounts/$AZStorageAcct/fileServices/default/fileshares/$AZFileShare"

# Assign the custom role to target identities with the specified scope (you can do this in the portal)
# New-AzRoleAssignment -SignInName <user-principal-name> -RoleDefinitionName $FileShareContributorRole.Name -Scope $scope
# -SignInName is a domain admin account sync'd to your Azure AD directory
# -ObjectId is the GUID of an AAD Group

# Only need to do this once for a stoage account
New-AzRoleAssignment -SignInName $DomainAdmin `
    -RoleDefinitionName $FileShareElevatedContributorRole.Name `
    -Scope $scope
New-AzRoleAssignment -ObjectId $ContribGroupId `
    -RoleDefinitionName $FileShareContributorRole.Name `
    -Scope $scope
New-AzRoleAssignment -ObjectId $ElevContribGroupId `
    -RoleDefinitionName $FileShareElevatedContributorRole.Name `
    -Scope $scope

#--- Verify the assignments:
$roles = Get-AzRoleAssignment
$roles | Format-Table -Property SignInName, DisplayName, RoleDefinitionName

###=============== End:     Assign roles for the share     =====================###        


###=========================  Map Share with "net use"  =========================###        
### Using net use commands

# Get the storage account access key (We get key1)
$StorageAcctKey = `
    (Get-AzStorageAccountKey `
    -ResourceGroupName $AZResourceGroup `
    -Name $AZStorageAcct).Value[0]

# Turns out net use doesn't like keys that start with a "/"
# Generate a new key if we have a key starting with a "/"
# Probably should be a function
if ("/" -match "^"+[regex]::escape($StorageAcctKey[0]))
{
    Write-Host "Need to Generate a new Key - this one starts with a /"
    New-AzStorageAccountKey -ResourceGroupName $AZResourceGroup `
      -Name $AZStorageAcct `
      -KeyName key1
    $StorageAcctKey = `
        (Get-AzStorageAccountKey `
        -ResourceGroupName $AZResourceGroup `
        -Name $AZStorageAcct).Value[0]

}


# Setup and run the "net use" command
$MapPath = "\\"+$AZStorageAcct+".file.core.windows.net\"+$AZFileShare
net use $DriveLetter $MapPath /u:$AZStorageAcct /persistent:no $StorageAcctKey



###====================    Set NTFS Permissions    =====================###        
###                        Using icacls commands                        ###

###--- Run icacls using Invoke-Expression
Invoke-Expression -Command ('icacls $DriveLetter $Remove "${BuiltinUsers}"')
Invoke-Expression -Command ('icacls $DriveLetter $Remove "${AuthUsers}"')
Invoke-Expression -Command ('icacls $DriveLetter $Grant "${CreatorOwner}${Modify}"')
Invoke-Expression -Command ('icacls $DriveLetter $Grant "${ElevateContrib}${FullControl}"')
Invoke-Expression -Command ('icacls $DriveLetter $Grant "${Contrib}${ModifyContrib}"')
Invoke-Expression -Command ('icacls $DriveLetter $Grant "${DomainAdmin}${Modify}"')

icacls :

#$BuiltinBuiltin = "Builtin\Builtin"
#Invoke-Expression -Command ('icacls $DriveLetter $Remove "${BuiltinBuiltin}"')


#net use $DriveLetter /delete