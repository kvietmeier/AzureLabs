Write-Host "Disable Store auto update:"

#reg add HKLM\Software\Policies\Microsoft\WindowsStore /v AutoDownload /t REG_DWORD /d 0 /f
New-Item -Path "HKLM:\Software\Policies\Microsoft\WindowsStore" 
New-Itemproperty "HKLM:\Software\Policies\Microsoft\WindowsStore" `
    -Name AutoDownload -PropertyType DWORD -Value 0 -Force

<# Fails:
Schtasks : ERROR: The specified task name "\Microsoft\Windows\WindowsUpdate\Automatic App Update" does not exist in the system.
Schtasks /Change /Tn "\Microsoft\Windows\WindowsUpdate\Automatic app update" /Disable
#>

# Works
Schtasks /Change /Tn "\Microsoft\Windows\WindowsUpdate\Scheduled Start" /Disable

Write-Host "Disable Content Delivery auto download apps that they want to promote to users:"

#reg add HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager /v PreInstalledAppsEnabled /t REG_DWORD /d 0 /f
New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" 
New-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
    -Name PreInstalledAppsEnabled -PropertyType DWORD -Value 0 -Force

#reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Debug /v ContentDeliveryAllowedOverride /t REG_DWORD /d 0x2 /f
New-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Debug" 
New-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Debug" `
    -Name ContentDeliveryAllowedOverride -PropertyType DWORD -Value 0x2 -Force

Write-Host "Disable Windows Update:"
sc config wuauserv start=disabled


# Enable Hyper-V (On Session Host Image)
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All