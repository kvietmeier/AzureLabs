###=================================================================================###
<# 
  PowerShell commands to Install some required modules for working in Azure. 
      Written By: Karl Vietmeier                                             
                                                                            
  These Are common modules for AD, Azure, AzureFiles, WVD, and GPO
  *** Includes code to non-interatively install AZFiles Module       
#>
###=================================================================================###
return

### Required PS Modules:
# Check PS Version - 
$PSVersionTable.PSVersion

# You might need to set this - (set it back later if you need to)
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force

# Trust the Gallery - so we don't get prompted all the time
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

# Run these as an Admin:
# May need to Upgrade PowerShellGet and other modules - upgrade NuGet first
Install-PackageProvider -Name NuGet -Force
Install-Module -Name PowerShellGet -Force

# Azure and AD Modules - probably have these but this will upgrade them
Install-Module -Name "Az" `
    -Repository 'PSGallery' `
    -Scope 'CurrentUser' `
    -AllowClobber -Force -Verbose

Install-Module -Name "AzureAD" `
    -Repository 'PSGallery' `
    -Scope 'CurrentUser' `
    -AllowClobber -Force -Verbose

# WVD Modules
Install-Module -Name Az.DesktopVirtualization `
    -RequiredVersion 2.0.0 `
    -SkipPublisherCheck

# I needed this to do some GPO work - optional
Install-Module -Name GPRegistryPolicy

<# 
  For AzureFiles AD Setup - 
  Reference: Download and follow install instructions:
  AzFilesHybrid:   https://github.com/Azure-Samples/azure-files-samples/releases
  Unzip to a folder and run the CopyToPSPath.ps1 script to put the module in the search path.  
  After you unzip and run the copy script you can import the module

  This code will install it for you automatically (Check the version - it could be newer)
#>

$AZFmoduleLoc  = "https://github.com/Azure-Samples/azure-files-samples/releases/download/v0.2.0/AzFilesHybrid.zip"
$AZFZip     = "C:\Users\azureadmin\Downloads\AZFilesPSModule.zip"
$AZFExtractDir = "C:\Users\azureadmin\Downloads\AZFilesPSModule"
$Downloads = "C:\Users\azureadmin\Downloads"
$AZFScript     = "C:\Users\azureadmin\Downloads\AZFilesPSModule\CopyToPSPath.ps1"

Invoke-WebRequest -Uri $AZFmoduleLoc -OutFile $AZFZip
Expand-Archive -LiteralPath $AZFZip -DestinationPath $AZFExtractDir
Set-Location $AZFExtractDir
Invoke-Expression -Command $AZFScript
Import-Module AzFilesHybrid 

# Cleanup
Remove-Item $AZFZip
Set-Location $Downloads
Remove-Item -Recurse $AZFExtractDir


###- Might need this - I needed it in VSC - YMMV
#Unblock-File `
#    -Path C:\Users\wvdadmin01\Documents\WindowsPowerShell\Modules\AzFilesHybrid\0.2.0.0\AzFilesHybrid.psm1


###======== END - PowerShell commands for setting up Azure Files with AD Auth.  ========###