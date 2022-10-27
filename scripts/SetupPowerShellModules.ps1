###=================================================================================###
<# 
  Filename: SetupPowerShellModules.ps1
  
  Description:
  PowerShell commands to install the modules you need for working in Azure and
  with Windows Virtual Desktop. 
      
  Written By: Karl Vietmeier                                             
                                                                            
  These are common modules for Azure AD, Azure, AzureFiles, WVD, and GPO
  *** Includes code to non-interatively install AZFiles Module       
#>
###=================================================================================###
#return

# Need to be Admin to run.

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

function AZModules () {
  # Install Azure Az modules - probably have these but this will upgrade them
  Install-Module -Name "Az" `
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
  
  # AZ Network module - seem to need this for other modules
  Install-Module -Name "Az.Network" `
      -Repository 'PSGallery' `
      -Confirm:$false `
      -AllowClobber -Force -Verbose

  # End Function
}

function OptionalModules () {
  # Azure Stack Module
  Install-Module -Name "Az.StackHCI" `
      -Repository 'PSGallery' `
      -Confirm:$false `
      -AllowClobber -Force -Verbose

  # I needed this to do some GPO work - optional
  Install-Module -Name "GPRegistryPolicy" `
      -Repository 'PSGallery' `
      -Confirm:$false `
      -AllowClobber -Force -Verbose
      
  # End Function
}

function ADModules () {
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

  # End Function
}

# Required
PreReqs

# Pick the ones you need
AZModules
OptionalModules
ADModules
