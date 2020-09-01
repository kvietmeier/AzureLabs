###====================================================================================###
<# 

  <scriptname>.ps1 
    Created By: Karl Vietmeier  
                                
  Description                   
  https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/rds_vdi-recommendations-1909

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

###-------- Tuning Parameters
# https://docs.microsoft.com/en-us/windows-server/administration/performance-tuning/

# DisableBandwidthThrottling
# HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters\DisableBandwidthThrottling
# The default is 0
# Consider setting this value to 1

New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters" `
    -Name "DisableBandwidthThrottling" -PropertyType DWORD -Value 1 `
    -Force    

# FileInfoCacheEntriesMax
# HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters\FileInfoCacheEntriesMax
# The default is 64
# Try increasing this value to 1024

New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters" `
    -Name "FileInfoCacheEntriesMax" -PropertyType DWORD -Value 1024 `
    -Force    

# DirectoryCacheEntriesMax
# HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters\DirectoryCacheEntriesMax
# The default is 16
# Consider increasing this value to 1024

New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters" `
    -Name "DirectoryCacheEntriesMax" -PropertyType DWORD -Value 1024 `
    -Force    

# FileNotFoundCacheEntriesMax
# HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters\FileNotFoundCacheEntriesMax
# The default is 128
# Consider increasing this value to 2048

New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters" `
    -Name "FileNotFoundCacheEntriesMax" -PropertyType DWORD -Value 2048 `
    -Force    

# DormantFileLimit
# HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters\DormantFileLimit
# The default is 1023
# Consider reducing this value to 256

New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters" `
    -Name "DormantFileLimit" -PropertyType DWORD -Value 256 `
    -Force    

###---- End Tuning



### Remove OneDrive Components
Taskkill.exe /F /IM "OneDrive.exe"
Taskkill.exe /F /IM "Explorer.exe"`
    if (Test-Path "C:\\Windows\\System32\\OneDriveSetup.exe")`
     { Start-Process "C:\\Windows\\System32\\OneDriveSetup.exe"`
         -ArgumentList "/uninstall"`
         -Wait }
    if (Test-Path "C:\\Windows\\SysWOW64\\OneDriveSetup.exe")`
     { Start-Process "C:\\Windows\\SysWOW64\\OneDriveSetup.exe"`
         -ArgumentList "/uninstall"`
         -Wait }
Remove-Item -Path
"C:\\Windows\\ServiceProfiles\\LocalService\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\Programs\\OneDrive.lnk" -Force

# Remove the automatic start item for OneDrive from the default user profile registry hive
Remove-Item -Path "C:\\Windows\\ServiceProfiles\\NetworkService\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\Programs\\OneDrive.lnk" -Force 
Start-Process C:\\Windows\\System32\\Reg.exe -ArgumentList "Load HKLM\\Temp C:\\Users\\Default\\NTUSER.DAT" -Wait
Start-Process C:\\Windows\\System32\\Reg.exe -ArgumentList "Delete HKLM\\Temp\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run /v OneDriveSetup /f" -Wait
Start-Process C:\\Windows\\System32\\Reg.exe -ArgumentList "Unload HKLM\\Temp" -Wait Start-Process -FilePath C:\\Windows\\Explorer.exe -Wait