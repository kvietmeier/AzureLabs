###=====================================================================================###
###                   Modify Registry Settings to Optmize Session Hosts
###=====================================================================================###




function SessionTimeouts ()
{
   # Configuring session timeout policies...
    
    # Set registry key and path for commands
    $RegKey = "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
    set-location -Path $RegKey

    # Registry settings
    New-ItemProperty -Path "." `
        -Name "RemoteAppLogoffTimeLimit" `
        -PropertyType "DWORD" -Value "0" `
        -Force 

    New-ItemProperty -Path "." `
        -Name "fResetBroken" `
        -PropertyType "DWORD" -Value "1" `
        -Force 

    New-ItemProperty -Path "." `
        -Name "MaxConnectionTime" `
        -PropertyType "DWORD" -Value "28800000" ` # 8hrs
        -Force 

    New-ItemProperty -Path "." `
        -Name "RemoteAppLogoffTimeLimit" `
        -PropertyType "DWORD" -Value "0" `
        -Force 

    New-ItemProperty -Path "." `
        -Name "MaxDisconnectionTime" `
        -PropertyType "DWORD" -Value "14400000" ` # 4hrs
        -Force 

    New-ItemProperty -Path "." `
        -Name "MaxIdleTime" `
        -PropertyType "DWORD" -Value "7200000" ` # 2hrs
        -Force

}

# Misc System Settings 
Write-Host "Disabling Automatic Updates..."
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" `
    -Name "NoAutoUpdate" `
    -PropertyType "REG_DWORD" `
    -Value "1" `
    -Force

# Enable timezone redirection
New-ItemProperty -Path "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" `
    -Name "fEnableTimeZoneRedirection" `
    -PropertyType "DWORD" -Value "1" `
    -Force

# Disable Storage Sense
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" `
    -Name "01" `
    -PropertyType "DWORD" -Value "0" `
    -Force
