###====================================================================================###
<#   
  FileName: InstallAndConfigureWSLinVM.ps1
  Created By: Karl Vietmeier
    
  Description:
   Install/Enable WSL in an Image

  Docs/Links: 
   Manually download/install Distros - 
   https://docs.microsoft.com/en-us/windows/wsl/install-manual
  
   Full Docs - 
   https://docs.microsoft.com/en-us/windows/wsl/install-win10


  Store Images:
  https://aka.ms/wslstore
  
  Kernel Update
  https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi


#>
###====================================================================================###
### Here for safety - comment/uncomment as desired
# This is not a runable script
return

# Install Windows Terminal (need msix bundle) - not working - 
#DISM /Online /Add-ProvisionedAppxPackage /PackagePath:<path to msixbundle> /SkipLicense

# Step 1: Enable the feature
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# Step 2: For WSL 2 - need HyperV bits
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

###---- Reboot at this point ----###

# Step 3: Update to WSL 2.0 -
wsl --set-default-version 2

# Step 4: Download kernel update and install
$TempDir        = "C:\temp"
$KernelMSI      = "wsl_update_x64.msi"
$KernelDownload = $TempDir + "\" + $KernelMSI
$KernelURI      = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"

# Check to see if C:\temp exists - if not create it
if (!(Test-Path $DownloadDir))
{
  Write-Host "Creating C:\temp"
  New-Item -ItemType Directory -Force -Path $DownloadDir
  $RemoveDir = "True" # We created it, so remove it afterward
}

# Download the kernel update
Invoke-Webrequest -Uri $KernelURI -OutFile $KernelDownload

# Install the update
Set-Location $TempDir
.\wsl_update_x64.msi /quiet /n 

# Step 5: Set WSL to Version 2
wsl --set-default-version 2


###---- On/In Session Host As a user download the Distro and install ----###

Set-Location .\Downloads
wsl --set-default-version 2
Invoke-WebRequest -Uri https://aka.ms/wslubuntu2004 -OutFile Ubuntu-20-04.appx -UseBasicParsing
Add-AppxPackage .\Ubuntu-20-04.appx
Get-AppxPackage | Where-Object -Property Name -Like '*Ubuntu*'

# Windows Terminal
Invoke-WebRequest https://github.com/microsoft/terminal/releases/download/v1.5.3242.0/Microsoft.WindowsTerminalPreview_1.5.3242.0_8wekyb3d8bbwe.msixbundle -OutFile Microsoft.WindowsTerminalPreview_1.5.3242.0_8wekyb3d8bbwe.msixbundle
Add-AppPackage -Path .\Microsoft.WindowsTerminalPreview_1.5.3242.0_8wekyb3d8bbwe.msixbundle

# GWSL
Invoke-WebRequest https://github.com/Opticos/GWSL-Source/releases/download/v1.3.7/GWSL.Traditional.137.release.x64.exe -OutFile GWSL.Traditional.137.release.x64.exe


