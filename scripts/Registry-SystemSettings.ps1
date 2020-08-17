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


###--- System Calls:
# Remove the WinHTTP proxy
netsh winhttp reset proxy

# Set the power profile to the High Performance
powercfg /setactive SCHEME_MIN

# Set startup type of the Windows Time (w32time) service to Automatic
Set-Service -Name w32time -StartupType Automatic



