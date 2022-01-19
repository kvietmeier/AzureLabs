###====================================================================================###
<# 

  Modify Registry Settings and disable services to Optmize Session Hosts  
  - Session Timeouts
  - Time Zone mapping to client
  - 5K resolution
  - etc.

  ToDos:
  Shutdown event tracker - 
  HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Reliability
    ShutdownReasonOn DWORD
    ShutdownReasonUI DWORD

    <delete> = Disable
    1 = Enable

#>                                                     
###====================================================================================###
return

function SessionTimeouts ()
{
   # Configuring RDP session timeout policies...
    
    # Set registry key and path for commands
    $RegKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
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
    -Name "NoAutoUpdate" -PropertyType "DWORD" -Value "1" `
    -Force

# Enable timezone redirection
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" `
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
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" `
    -Name "TEMP" -Value "%SystemRoot%\TEMP" -PropertyType ExpandString -Force

New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" `
    -Name "TMP" -Value "%SystemRoot%\TEMP" -PropertyType ExpandString -Force


#For feedback hub collection of telemetry data on Windows 10 Enterprise multi-session, run this command
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
    -Name "AllowTelemetry" -PropertyType DWORD -Value 3 `
    -Force

# Fix Watson crashes:
Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\CorporateWerServer*"

# Hide the Azure VM D: drive (Maybe better to do in GPO but can only hide A,B,C,D with Policy)
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
    -Name "NoDrives" -PropertyType DWORD -Value 8 `
    -Force    

# -Value for drives 
<#  
 A –> 1    G –> 64      M –> 4096    S –> 262144     Y –> 16777216
 B –> 2    H –> 128     N –> 8192    T –> 524288     Z–> 33554432
 C –> 4    I –> 256     O –> 16384   U –> 1048576
 D –> 8    J –> 512     P –> 32768   V –> 2097152
 E –> 16   K –> 1024    Q –> 65536   W –> 4194304
 F –> 32   L –> 2048    R –> 131072  X –> 8388608
 #>


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


# Install Chrome - non-interactive
$LocalTempDir = $env:TEMP; $ChromeInstaller = "ChromeInstaller.exe"; (new-object System.Net.WebClient).DownloadFile('http://dl.google.com/chrome/install/375.126/chrome_installer.exe', "$LocalTempDir\$ChromeInstaller"); & "$LocalTempDir\$ChromeInstaller" /silent /install; $Process2Monitor = "ChromeInstaller"; Do { $ProcessesFound = Get-Process | ?{$Process2Monitor -contains $_.Name} | Select-Object -ExpandProperty Name; If ($ProcessesFound) { "Still running: $($ProcessesFound -join ', ')" | Write-Host; Start-Sleep -Seconds 2 } else { rm "$LocalTempDir\$ChromeInstaller" -ErrorAction SilentlyContinue -Verbose } } Until (!$ProcessesFound)

###---- Cosmetic Settings Only but common tweaks (these can be reset by sysprep)
# Desktop Icons and Small Icons; Enable Search/cortana

New-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" `
    -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -PropertyType DWORD -Value 0 -Force
New-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" `
    -Name "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" -PropertyType DWORD -Value 0 ` -Force

# Not Found
<# New-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" `
    -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -PropertyType DWORD -Value 0 -Force
New-Itemproperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" `
    -Name "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" -PropertyType DWORD -Value 0 -Force
#>

New-Itemproperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name TaskbarSmallIcons -PropertyType DWORD -Value 1 -Force
New-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name ShowCortanaButton -PropertyType DWORD -Value 1 -Force
New-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" `
    -Name SearchboxTaskbarMode -PropertyType DWORD -Value 2 -Force

New-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" `
    -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -PropertyType DWORD -Value 0 -Force 
New-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" `
    -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -PropertyType DWORD -Value 0 -Force
New-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" `
    -Name "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" -PropertyType DWORD -Value 0 -Force
New-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" `
    -Name "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" -PropertyType DWORD -Value 0 -Force

New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name TaskbarSmallIcons -PropertyType DWORD -Value 1 -Force
New-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name ShowCortanaButton -PropertyType DWORD -Value 1 -Force

# - missing?
#New-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Search" `
#    -Name SearchboxTaskbarMode -PropertyType DWORD -Value 2 -Force

<# SearchboxTaskbarMode DWORD
    0 = Hidden
    1 = Show search icon
    2 = Show search box
 #>
 
# Need to restart explorer - run seperatly
taskkill /f /im explorer.exe
start explorer.exe

###---- End: Cosmetic Settings Only but common tweaks


### Set the Office Update UI behavior.
reg add HKLM\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate /v hideupdatenotifications /t REG_DWORD /d 1 /f
reg add HKLM\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate /v hideenabledisableupdates /t REG_DWORD /d 1 /f


###--- System Calls and setup:
# Remove the WinHTTP proxy
netsh winhttp reset proxy

# Set the power profile to the High Performance (not working)
powercfg /setactive SCHEME_MIN

# Set time to UTC - timezone mapping will fix it later
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation `
    -Name RealTimeIsUniversal `
    -Value 1 `
    -Type DWord `
    -Force

# Set startup type of the Windows Time (w32time) service to Automatic
Set-Service -Name w32time -StartupType Automatic

# Set services to their defaults - just to be sure
Get-Service -Name BFE, Dhcp, Dnscache, IKEEXT, iphlpsvc, nsi, mpssvc, RemoteRegistry |
  Where-Object StartType -ne Automatic |
    Set-Service -StartupType Automatic

Get-Service -Name Netlogon, Netman, TermService |
  Where-Object StartType -ne Manual |
    Set-Service -StartupType Manual


# Windows Defender Exclusion for profile disks
Add-MpPreference -ExclusionExtension ”.vhd”
Add-MpPreference -ExclusionExtension ”.vhdx”


### Disable IEESC - if IE isn't installed won't work
function Disable-IEESC
{
    $AdminKey = "HKLM:\\SOFTWARE\\Microsoft\\Active Setup\\Installed Components\\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"

    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0

    Stop-Process -Name Explorer

    if ((Get-ItemProperty -Path $AdminKey -Name 'IsInstalled').isinstalled -eq 0) 
    {
        Write-Host “IE Enhanced Security Configuration (ESC) has been disabled.” -ForegroundColor Green
    } else { Write-Host "Failed to disable, use Server Manager"}
}

#Disable-IEESC    