###====================================================================================###
### CreateWVDHostPool
###    Created By: Karl Vietmeier                                                      ###
###                                                                                    ###
###  Create a FileShare - by generating a random name with a 4 digit random number     ###
###  "Get-Random" creates a random number                                              ###
###                                                                                    ###
###====================================================================================###

# 
# So it won't run on accident
#return

# Get my functions and credentials
. "C:\bin\resources.ps1"


###=====================  Are you logged in?  ===================###        
<# function Login ($context)
{
    $context = Get-AzContext
    Write-Host "$context"
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
} #>

Login

###==============================================================### 

$AZResourceGroup = "WVDLandscape01"

# Create names with random 4 digit number.
$NewHostPool    = "hostpool$(Get-Random -Minimum 1000 -Maximum 2000)"
$NewWorkspace   = "workspace$(Get-Random -Minimum 1000 -Maximum 2000)"
$NewDesktopApp  = "appgrp$(Get-Random -Minimum 1000 -Maximum 2000)"
$PoolType = "Pooled"
$LBType   = "Breadfirst"
$Region   = "westus2"

# Run the following cmdlet to sign in to the Windows Virtual Desktop environment:
# This cmdlet will create the host pool, workspace and desktop app group. Additionally,
# it will register the desktop app group to the workspace. You can either create a 
# workspace with this cmdlet or use an existing workspace.
New-AzWvdHostPool `
    -ResourceGroupName $AZResourceGroup `
    -Name $NewHostPool `
    -WorkspaceName $NewWorkspace `
    -HostPoolType $PoolType `
    -LoadBalancerType $LBType `
    -Location $Region `
    -DesktopAppGroupName $NewDesktopApp

    
# Run the next cmdlet to create a registration token to authorize a session 
# host to join the host pool and save it to a new file on your local computer. 
New-AzWvdRegistrationInfo `
    -ResourceGroupName <resourcegroupname> `
    -HostPoolName <hostpoolname> `
    -ExpirationTime $((get-date).ToUniversalTime().AddDays(1).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ'))

# For example, if you want to create a token that expires in two hours, run this cmdlet:
New-AzWvdRegistrationInfo `
    -ResourceGroupName <resourcegroupname> `
    -HostPoolName <hostpoolname> `
    -ExpirationTime $((get-date).ToUniversalTime().AddHours(2).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ'))

# Run this cmdlet to add Azure Active Directory users to the default desktop 
# app group for the host pool. 
New-AzRoleAssignment `
    -SignInName <userupn> `
    -RoleDefinitionName "Desktop Virtualization User" `
    -ResourceName <hostpoolname+"-DAG"> `
    -ResourceGroupName <resourcegroupname> `
    -ResourceType 'Microsoft.DesktopVirtualization/applicationGroups'

# Run this cmdlet to add Azure Active Directory user groups to the default desktop 
# app group for the host pool. 
New-AzRoleAssignment `
    -ObjectId <usergroupobjectid> `
    -RoleDefinitionName "Desktop Virtualization User" `
    -ResourceName <hostpoolname+"-DAG"> `
    -ResourceGroupName <resourcegroupname> `
    -ResourceType 'Microsoft.DesktopVirtualization/applicationGroups'

    #-RoleDefinitionName "Personal Desktop Users" `

# Working Example    
New-AzRoleAssignment `
    -ObjectId "35b0cbae-aae0-4117-908d-71730ed91d18" `
    -RoleDefinitionName "Desktop Virtualization User" `
    -ResourceGroupName "WVDLandscape01" `
    -ResourceName TestPool01"-DAG" `
    -ResourceType 'Microsoft.DesktopVirtualization/applicationGroups'

# Run the following cmdlet to export the registration token to a variable, which you will
# use later in Register the virtual machines to the Windows Virtual Desktop host pool.   
$token = Get-AzWvdRegistrationInfo -ResourceGroupName <resourcegroupname> -HostPoolName <hostpoolname>


###==============================================================###        


###=================  Remove Account  ================###        
#Remove-AzStorageAccount `
#    -ResourceGroupName $AZResourceGroup `
#    -AccountName $AZStorageAcct.StorageAccountName

