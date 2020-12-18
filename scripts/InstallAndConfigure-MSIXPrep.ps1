###====================================================================================###
<#   
  FileName: InstallAndConfigure-MSIXPrep.ps1
  Created By: Karl Vietmeier
    
  Description:
   Prepare a WVD Session Host for using MSIX App-Attach

#>
###====================================================================================###
### Here for safety - comment/uncomment as desired
return

# Stop on first error
$ErrorActionPreference = "stop"

# Run from the location of the script
Set-Location $PSscriptroot

# Make sure there isn't an update pending or running
Get-ScheduledTask -TaskPath "\Microsoft\Windows\WindowsUpdate\" | Disable-ScheduledTask

Write-Host "Disable Store auto update:"
New-Item -Path "HKLM:\Software\Policies\Microsoft\WindowsStore" 
New-Itemproperty "HKLM:\Software\Policies\Microsoft\WindowsStore" `
    -Name AutoDownload -PropertyType DWORD -Value 0 -Force

<# Fails:
Schtasks : ERROR: The specified task name "\Microsoft\Windows\WindowsUpdate\Automatic App Update" does not exist in the system.
Schtasks /Change /Tn "\Microsoft\Windows\WindowsUpdate\Automatic app update" /Disable
#>

# Works but don't need it due to above Get-ScheduledTask command
#Schtasks /Change /Tn "\Microsoft\Windows\WindowsUpdate\Scheduled Start" /Disable

# Disable App updates
Write-Host "Disable Content Delivery auto download apps that they want to promote to users:"
$ContDelMgrPath      = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
$ContDelMgrDebugPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Debug"

New-Item -Path $ContDelMgrPath
New-ItemProperty $ContDelMgrPath `
    -Name PreInstalledAppsEnabled `
    -PropertyType DWORD -Value 0 -Force

New-Item -Path $ContDelMgrDebugPath
New-ItemProperty $ContDelMgrDebugPath `
    -Name ContentDeliveryAllowedOverride `
    -PropertyType DWORD -Value 0x2 -Force


# Disable Services
Write-Host "Stop and disable Windows Update:"
Stop-Service wuauserv
Set-Service -Name wuauserv -StartupType Disabled

# We disable WindowsUpdate folder again, because wuauserv service could have enabled it meanwhile
Get-ScheduledTask -TaskPath "\Microsoft\Windows\WindowsUpdate\" | Disable-ScheduledTask

# Enable Hyper-V (On Session Host Image)
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All


<# 
$val = Get-ItemProperty -Path hklm:software\microsoft\windows\currentversion\policies\system -Name "EnableLUA"
if($val.EnableLUA -ne 0)
{
 set-itemproperty -Path hklm:software\microsoft\windows\currentversion\policies\system -Name "EnableLUA" -value 0
} 
#>