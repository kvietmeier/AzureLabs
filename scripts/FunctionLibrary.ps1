###============== Library of Common Functions ===================###
<#

  Call with "." sourcing
  . "path_to_library.ps1"

  Functions:
   InstallPSModules - Install modules you may need
   Check-Login: Check to see if you are already connected to Azure, if not, 
                prompt for Credentials and connect

#>

###=====================  Are you logged in?  ===================###        
function Check-Login ()
{

    $context = Get-AzContext
    Write-Host "Is my AZ Account Connected?" 

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
}

### Login Creds - an insecure hack
# - In an external file - edit for your use here
#$AIAuser
#$AIApassword
function Login-NoPrompt ($AIAPassword, $AIAuser)
{
    $context = Get-AzContext
    Write-Host "" 
    Write-Host "Is my AZ Account Connected?" 

    if (!$context -or ($context.Subscription.Id -ne $SubID)) 
    {
        # Use credentials stored in a secure variable sourced from another file
        $securepasswd = ConvertTo-SecureString $AIAPassword -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ($AIAuser, $securepasswd)
        Connect-AzAccount -Credential $cred -Subscription $SubID
        
        # Change subscription context (May not need this)
        Select-AzSubscription -SubscriptionId $SubName
    } 
    else 
    {
        Write-Host "SubscriptionId '$SubID' already connected"
        Write-Host "" 
    }
}

function Install-PSModules ()
{

    Write-Host ""
    Write-Host "Installing Some useful PowerShell Modules"
    Write-Host ""

    # Run these as an Admin:
    # Standard: You might need to set this - (set it back later if you need to)
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force

    # May need to Upgrade PowerShellGet and other modules so just do it - upgrade NuGet first
    # - you will need this min version (as of 10/15/2020) to run/install Set-PSRepository
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force 
  
    # Trust the Gallery - So we don't get prompted all the time
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
  
    # Install upgrade PowerShellGet
    Install-Module -Name PowerShellGet -AllowClobber -Force -Verbose

    # Install Azure Az modules - probably have these but this will upgrade them
    Install-Module -Name "Az" `
       -Repository 'PSGallery' `
       -Scope 'CurrentUser' `
       -Confirm:$false `
       -AllowClobber -Force -Verbose

    # Azure AD Module    
    Install-Module -Name "AzureAD" `
       -Repository 'PSGallery' `
       -Scope 'CurrentUser' `
       -Confirm:$false `
       -AllowClobber -Force -Verbose

    # Azure AD Preview Module    
    Install-Module -Name "AzureADPreview" `
        -Repository 'PSGallery' `
        -Scope 'CurrentUser' `
        -Confirm:$false `
        -AllowClobber -Force -Verbose

    # WVD Module
    Install-Module -Name "Az.DesktopVirtualization" `
        -Repository 'PSGallery' `
        -RequiredVersion 2.0.0 `
        -SkipPublisherCheck `
        -Confirm:$false `
        -AllowClobber -Force -Verbose

    # I needed this to do some GPO work - optional
    Install-Module -Name "GPRegistryPolicy" `
        -Repository 'PSGallery' `
        -Confirm:$false `
        -AllowClobber -Force -Verbose

}
