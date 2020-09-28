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
# - In secrets.ps1
#$AIAuser
#$AIApassword
function Check-Login-noprompt ($AIAPassword, $AIAuser)
{
    $securepasswd = ConvertTo-SecureString $AIAPassword -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ($AIAuser, $securepasswd)
    Connect-AzAccount -Credential $cred -Subscription $SubID

}

function Install-PSModules ()
{
    Write-Host ""
    Write-Host "Installing Some PowerShell Modules"
    Write-Host ""

    ### You are going to need some modules - of course :)
    # Run these as an Admin:
    # You might need to set this - (set it back later if you need to)
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force
    
    # Trust the Gallery - so we don't get prompted all the time
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

    # May need to Upgrade PowerShellGet and other modules - upgrade NuGet first
    Install-PackageProvider -Name NuGet -Force
    Install-Module -Name PowerShellGet -Force

    # Azure and AD Modules - probably have these
    Install-Module -Name "Az" -Repository 'PSGallery' -Scope 'CurrentUser' -AllowClobber -Force -Verbose
    Install-Module -Name "AzureAD" -Repository 'PSGallery' -Scope 'CurrentUser' -AllowClobber -Force -Verbose

    # I needed this to do some GPO work
    Install-Module -Name GPRegistryPolicy

    # WVD Modules
    Install-Module -Name Az.DesktopVirtualization -RequiredVersion 2.0.0 -SkipPublisherCheck
}
