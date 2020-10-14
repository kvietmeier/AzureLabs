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
#>
###====================================================================================###
### Here for safety - comment/uncomment as desired
return

### Get my functions and credentials
# Credentials  (stored outside the repo)
. '..\..\Certs\resources.ps1'

# Functions (In this repo)
. '.\FunctionLibrary.ps1'

# Imported from "FunctionLibrary.ps1"
# Are we connected to Azure with the corredt SubID?
Check-Login

# Need for OneDrive Known Folder Redirection
#$AADTenant = "xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  #your AAD Tenant ID

# This one you can grab -
Invoke-WebRequest -Uri "https://aka.ms/OneDriveWVD-Installer" -Outfile c:\temp\OneDriveSetup.exe

# Uninstall One Drive if it is there
Set-Location $InstallDir
.\OneDriveSetup.exe /uninstall

### Check to see if the registry path/key exist
# Re-Create the key and entry (we are only going to use 64bit versions of everything)
$OneDrivePath = "HKLM:\Software\Microsoft\Onedrive" 

if (!(Test-Path $OneDrivePath)) {
    New-Item -Path $OneDrivePath
}
else {
    New-ItemProperty -Path $OneDrivePath -Name "AllUsersInstall" -Type DWORD -Value 1
}

# Re-Install OneDrive
.\OneDriveSetup.exe /allusers

# Configure OneDrive to start at sign-in for all users
New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" `
    -Name "OneDrive" -PropertyType String `
    -Value "C:\Program Files (x86)\Microsoft OneDrive\OneDrive.exe /background" -Force

<# Using the AADTenent variable from above -  
   Redirect and move Windows known folders to OneDrive
   Make sure to change the AAD ID to match your own AAD!!!!
#>
New-Item -Path "HKLM:\Software\Policies\Microsoft\OneDrive" 
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\OneDrive" `
    -Name "KFMSilentOptIn" -PropertyType String -Value "$AADTenantID" -Force

# Silently configure user accounts
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\OneDrive" `
    -Name "SilentAccountConfig" -PropertyType DWORD -Value 1 -Force

