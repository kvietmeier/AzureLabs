###====================================================================================###
<#   
  FileName: InstallAndConfigureOneDrive.ps1
  Created By: Karl Vietmeier
    
  Description:
   Install OneDrive for WVD

   By Default One-drive installs for single users
   Download the latest OneDriveSetup.exe from Micrsoft's site:
   https://products.office.com/en-us/onedrive/download
   
   Place in a temp folder - NOTE:  Change the folder path to your copy of OneDriveSetup.exe
   OneDriveSetup also uninstalls. 

  !!!NOT Tested!!!
#>
###====================================================================================###
### Here for safety - comment/uncomment as desired
return

# Run from the location of the script
Set-Location $PSscriptroot
#Set-Location ../AzureLabs/scripts

###---- Get my functions and credentials ----###
# Credentials  (stored outside the repo)
. 'C:\.info\miscinfo.ps1'

# Functions (In this repo)
. '.\FunctionLibrary.ps1'

# Imported from "FunctionLibrary.ps1"
# Are we connected to Azure with the corredt SubID?
Check-Login

################   Re-install/Setup One Drive    ########################
<# 
   By Default One-drive installs for single users
   Uninstall OneDrive 
   Download the latest OneDriveSetup.exe from Micrsoft's site https://products.office.com/en-us/onedrive/download
   Place in a temp folder - NOTE:  Change the folder path to your copy of OneDriveSetup.exe
   OneDriveSetup also uninstalls. 
 #>
 ###################################################################

# This one you can grab -
Invoke-WebRequest -Uri "https://aka.ms/OneDriveWVD-Installer" -Outfile c:\temp\OneDriveSetup.exe

# Uninstall One Drive
Set-Location $InstallDir
.\OneDriveSetup.exe /uninstall


# Re-Create the key and entry (we are only going to use 64bit versions of everything)
# Already exists -
#New-Item -Path "HKLM:\Software\Microsoft\Onedrive" 
New-ItemProperty -Path "HKLM:\Software\Microsoft\Onedrive" -Name "AllUsersInstall" -Type DWORD -Value 1

# Re- Install OneDrive
$InstallDir\OneDriveSetup.exe /allusers


# Configure OneDrive to start at sign-in for all users
New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" `
    -Name "OneDrive" -PropertyType String `
    -Value "C:\Program Files (x86)\Microsoft OneDrive\OneDrive.exe /background" -Force

# Uses the AADTenent variable above #Redirect and move Windows known 
# folders to OneDrive - Make sure to change the AAD ID to match your own AAD!!!! 
New-Item -Path "HKLM:\Software\Policies\Microsoft\OneDrive" 
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\OneDrive" `
    -Name "KFMSilentOptIn" -PropertyType String -Value "$AADTenantID" -Force

# Silently configure user accounts
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\OneDrive" `
    -Name "SilentAccountConfig" -PropertyType DWORD -Value 1 -Force

