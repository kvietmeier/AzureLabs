###============== Library of Common Functions ===================###
<#

  Call with "." sourcing
  . "path_to_library.ps1"

  Functions:
   InstallPSModules: Install modules you may need
   CheckLogin: Check to see if you are already connected to Azure, if not, 
                prompt for Credentials and connect



  IDs, passwords, etc, are stored in a file excluded from the 
  GitHub repo with .gitignore or in the root folders

#>

Set-Location $PSscriptroot

# Source my account info
. 'C:\.info\miscinfo.ps1'



###=====================  Are you logged in?  ===================###        
function CheckLogin ()
{
    $context = Get-AzContext
    Write-Host "" 
    Write-Host "================================================================================="
    Write-Host "                        Is my AZ Account Connected?" 
    Write-Host "================================================================================="
    Write-Host "" 

    if (!$context -or ($context.Subscription.Id -ne $SubID)) 
    {
        #Write-Host "SubscriptionId '$SubID' already connected"
        Write-Host "================================================================================="
        Write-Host "                           No Azure Connection"
        Write-Host "================================================================================="
    } 
    else 
    {
        #$SubID = $context.Subscription.Id
        Write-Host "" 
        Write-Host "" 
        Write-Host "=========================================================================================="
        Write-Host "          Yes - $SubName in $AADDomain is logged in"
        Write-Host "=========================================================================================="
        Write-Host "" 
    }
}

#CheckLogin 

### Login Creds - a somewhat insecure hack - hide the credentials
# - In an external file listed in .gitignore - edit for your use here
#$AZUser        = ""
#$AZPassword    = ""
#$SPAppID       = ""
#$SPPassWd      = ""


# Connect to your AZ Sub using a Service Principle - 
# after checking if you are already connected
function AZConnectSP ()
{
    <# This function requires the following variables to be defined 
      $SPAppID
      $SPSecret
      $SubID
      $TenantID 
    #>

    $context = Get-AzContext

    # If I'm not connected/authorized, connect with Service Principle
    if (!$context -or ($context.Subscription.Id -ne $SubID)) 
    {
        Write-Host "" 
        Write-Host "No - Authenticating to $SubID with Service Principle" 
        
        # Script Automation w/Service Principle - no prompts
        $SPPassWd = $SPSecret | ConvertTo-SecureString -AsPlainText -Force 
        $SPCred   = New-Object -TypeName System.Management.Automation.PSCredential($SPAppID, $SPPassWd)
        Connect-AzAccount -ServicePrincipal -Credential $SPCred -Tenant $TenantID
    } 
    else 
    {
        Write-Host ""
        Write-Host "SubscriptionId $SubID is connected - no action required"
        Write-Host ""
    }
}

# Call it to test
#AZConnectSP 

function InstallPSModules ()
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
