###====================================================================================###
###                 Modify Registry Settings to Optmize Session Hosts                  ###
###                   For Session Timeouts and other key settings                      ###
###                                                                                    ###
###====================================================================================###
return

function SessionTimeouts ()
{
   # Configuring session timeout policies...
    
    # Set registry key and path for commands
    $RegKey = "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
    set-location -Path $RegKey

    # Registry settings
    New-ItemProperty -Path "." -Name "RemoteAppLogoffTimeLimit" -PropertyType "DWORD" -Value "0" -Force 
    New-ItemProperty -Path "." -Name "fResetBroken" -PropertyType "DWORD" -Value "1" -Force 
    New-ItemProperty -Path "." -Name "MaxConnectionTime" -PropertyType "DWORD" -Value "28800000" # 8hrs -Force 
    New-ItemProperty -Path "." -Name "RemoteAppLogoffTimeLimit" -PropertyType "DWORD" -Value "0" -Force 
    New-ItemProperty -Path "." -Name "MaxDisconnectionTime" -PropertyType "DWORD" -Value "14400000" # 4hrs -Force 
    New-ItemProperty -Path "." -Name "MaxIdleTime" -PropertyType "DWORD" -Value "7200000" # 2hrs -Force
}

SessionTimeouts


###--- Misc System Settings 

# Disable Automatic Updates
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" `
    -Name "NoAutoUpdate" -PropertyType "REG_DWORD" -Value "1" `
    -Force

# Enable timezone redirection
New-ItemProperty -Path "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" `
    -Name "fEnableTimeZoneRedirection" -PropertyType "DWORD" -Value "1" `
    -Force

# Set Coordinated Universal Time (UTC) time for Windows 
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' `
    -name "RealTimeIsUniversal" -Value "1" -Type DWord `
    -Force

# Disable Storage Sense
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" `
    -Name "01" -PropertyType "DWORD" -Value "0" `
    -Force

# Make sure that the environmental variables TEMP and TMP are set to their default values
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" `
    -Name "TEMP" -Value "%SystemRoot%\TEMP" -PropertyType ExpandString -Force

Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" `
    -Name "TMP" -Value "%SystemRoot%\TEMP" -PropertyType ExpandString -Force


#For feedback hub collection of telemetry data on Windows 10 Enterprise multi-session, run this command
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
    -Name "AllowTelemetry" -PropertyType DWORD -Value 3 `
    -Force

# Fix Watson crashes:
Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\CorporateWerServer*"

### 5K Resolution
# Enter the following commands into the registry editor to fix 5k resolution support
Set-Location "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
New-ItemProperty -Path "." -Name "MaxMonitors" -PropertyType DWORD -Value 4
New-ItemProperty -Path "." -Name "MaxXResolution" -PropertyType DWORD -Value "5120"
New-ItemProperty -Path "." -Name "MaxYResolution" -PropertyType DWORD -Value "2880"

# No key present - need to create it
New-Item -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\Winstations\rdp-sxs" 
Set-Location "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs"
New-ItemProperty -Path "." -Name "MaxMonitors" -PropertyType DWORD -Value 4
New-ItemProperty -Path "." -Name "MaxXResolution" -PropertyType DWORD -Value "5120"
New-ItemProperty -Path "." -Name "MaxYResolution" -PropertyType DWORD -Value "2880"

###--- End 5K Support


# Install Chrome
$LocalTempDir = $env:TEMP; $ChromeInstaller = "ChromeInstaller.exe"; (new-object System.Net.WebClient).DownloadFile('http://dl.google.com/chrome/install/375.126/chrome_installer.exe', "$LocalTempDir\$ChromeInstaller"); & "$LocalTempDir\$ChromeInstaller" /silent /install; $Process2Monitor = "ChromeInstaller"; Do { $ProcessesFound = Get-Process | ?{$Process2Monitor -contains $_.Name} | Select-Object -ExpandProperty Name; If ($ProcessesFound) { "Still running: $($ProcessesFound -join ', ')" | Write-Host; Start-Sleep -Seconds 2 } else { rm "$LocalTempDir\$ChromeInstaller" -ErrorAction SilentlyContinue -Verbose } } Until (!$ProcessesFound)


### Cosmetic Only but common tweaks

# Desktop Icons and Small Icons; Enable Search/cortana
# Need to redo as powershell commands
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" /t REG_DWORD /d 0
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" /v "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" /t REG_DWORD /d 0
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /V TaskbarSmallIcons /T REG_DWORD /D 1 /F
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /V SearchboxTaskbarMode /T REG_DWORD /D 0 /F
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /V ShowCortanaButton /T REG_DWORD /D 1 /F

REG ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0
REG ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0
REG ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" /t REG_DWORD /d 0
REG ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" /v "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" /t REG_DWORD /d 0
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /V TaskbarSmallIcons /T REG_DWORD /D 1 /F
REG ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\Search" /V SearchboxTaskbarMode /T REG_DWORD /D 1 /F
REG ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /V ShowCortanaButton /T REG_DWORD /D 1 /F

taskkill /f /im explorer.exe
start explorer.exe
 

### rem Set the Office Update UI behavior.
reg add HKLM\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate /v hideupdatenotifications /t REG_DWORD /d 1 /f
reg add HKLM\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate /v hideenabledisableupdates /t REG_DWORD /d 1 /f


###--- System Calls and setup:
# Remove the WinHTTP proxy
netsh winhttp reset proxy

# Set the power profile to the High Performance (not working)
powercfg /setactive SCHEME_MIN

# Set startup type of the Windows Time (w32time) service to Automatic
Set-Service -Name w32time -StartupType Automatic

# Set services to their defaluts - just to be sure
Get-Service -Name BFE, Dhcp, Dnscache, IKEEXT, iphlpsvc, nsi, mpssvc, RemoteRegistry |
  Where-Object StartType -ne Automatic |
    Set-Service -StartupType Automatic

Get-Service -Name Netlogon, Netman, TermService |
  Where-Object StartType -ne Manual |
    Set-Service -StartupType Manual

# Windows Defender Exclusion for profile disks
Add-MpPreference -ExclusionExtension ”.vhd”
Add-MpPreference -ExclusionExtension ”.vhdx”
