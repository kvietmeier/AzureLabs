<#
###################################################################################
  For AzureFiles AD Setup - 
  Reference: Download and follow install instructions:
  AzFilesHybrid:   https://github.com/Azure-Samples/azure-files-samples/releases
  Unzip to a folder and run the CopyToPSPath.ps1 script to put the module in the search path.  
  After you unzip and run the copy script you can import the module

  This code will install it for you automatically (Check the version - it could be newer)
###################################################################################
#>
# Need to be Admin to run.

# Just to be sure - 
function PreReqs () {
  # Run these as an Admin:
  # Standard: You might need to set this - (set it back later if you need to)
  Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force

  # May need to Upgrade PowerShellGet and other modules so just do it - upgrade NuGet first
  # - you will need this min version (as of 10/15/2020) to run/install Set-PSRepository
  Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force 
  
  # Trust the Gallery - So we don't get prompted all the time
  Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
  
  # Install upgrade PowerShellGet
  Install-Module -Name PowerShellGet `
    -AllowClobber -Force -Verbose
}

# Run PreReqs
PreReqs


# These can change - 
$DownloadDir    = "C:\temp"
$AZFVer         = "v0.2.0"
$AZFUrl         = "https://github.com/Azure-Samples/azure-files-samples/releases/download/"

# These are "fixed" based on first 3
$AZFModuleURL   = $AZFUrl + $AZFVer + '/AzFilesHybrid.zip'
$AZFZip         = $DownloadDir + '\AZFilesPSModule.zip'
$AZFExtractDir  = $DownloadDir + '\AZFilesPSModule'
$AZFScript      = $AZFExtractDir + '\CopyToPSPath.ps1'

# Check to see if C:\temp exists - if not create it
if (!(Test-Path $DownloadDir))
{
  Write-Host "Creating C:\temp"
  New-Item -ItemType Directory -Force -Path $DownloadDir
  $removeDir = "True" # We created it, so remove it afterward
}

Invoke-WebRequest -Uri $AZFModuleURL -OutFile $AZFZip
Expand-Archive -LiteralPath $AZFZip -DestinationPath $AZFExtractDir
Set-Location $AZFExtractDir
Invoke-Expression -Command $AZFScript
Import-Module AzFilesHybrid 

# Cleanup
Remove-Item $AZFZip
Set-Location $DownloadDir
Remove-Item -Recurse $AZFExtractDir

if ($removeDir = "True")
{
  Write-Host "Removing C:\temp"
  Set-Location "C:\"
  Remove-Item -Recurse $DownloadDir
}


###- Might need this - I needed it in VSC - YMMV
#Unblock-File `
#    -Path C:\Users\wvdadmin01\Documents\WindowsPowerShell\Modules\AzFilesHybrid\0.2.0.0\AzFilesHybrid.psm1