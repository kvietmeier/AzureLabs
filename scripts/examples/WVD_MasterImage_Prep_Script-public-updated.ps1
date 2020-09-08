#####################################################################
<# 
 Master Script for WVD Image Prep                                
 Script authors:   Adam Whitlatch <adam.whitlatch.microsoft.com>  
                   Chris Nylen <Chris.Nylen@microsoft.com>       
                   John Jenner <John.Jenner@microsoft.com>      
                                                               
 Most Recent Update Date: 04/06/2020                          
 Last Updated By: Adam Whitlatch                             
                                                            
 Last Updated by: Karl Vietmeier (kavietme@microsoft.com)  
            Date: 08/18/2020
            Replaced "reg add" with powershell code
            Updated Office install info with correct paths etc.
#>
#####################################################################



##############################################################################################################################################################
<#  
Below is the process I use to build my master image manually. NOTE, there are many ways to do this. You CAN use tools like SCCM, Azure Image Builder ect to build
this. Azure Image builder being the most automated

NOTE: Windows 10 has a 8 times sysprep limit. Therefore, if you are building a master image in Azure follow this process 
      to maintain a master image file wilout running into the sysprep limit
 1)  Deploy Win 10 base image from Azure Image Gallery, 
 2)  Make modifications, app installs, ect to image, 
       Re-Install Install One drive for all Users
       Install Office
       Install all Apps
       Run BGInfo Script
 3)  Reboot
 4)  Install FSX Agent, Azure Monitor Agent, Dependency Agents, and Sepago Agent
       Install FSX Agent
       Install Monitoring Agent - Do not connect to workspace
           Run Once Code at first login
            #MMDS
                $workspaceKey = "your workspace Key"
                $workspaceId = "Your Workspace ID"
                $mma = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
                $mma.AddCloudWorkspace($workspaceId, $workspaceKey)
                $mma.ReloadConfiguration()
       Install Dependency Agent
       Create Sepago LogAnalytics WS - search for sepago in marketplace - Only needs to be done the first time. Point all other Workspces to the same LA.
           Download Sepago views from github
           Install Views
           Get Workspace Id and Key info
       Install Sepago Agent - ITPC-LogAnalyticsAgent2
           Download the Sepago agent from website
           Extract files
           Copy ITPC-LogAnalyticsAgent2 Folder to Program Files Directory
           Modify Manifest File
              <add key="CustomerId" value="Your LA WokspaceID"/>
              <add key="SharedKey" value="youre workspace Key"/>
           Open Powershell or Command Prompt 
               Run ITPC-LogAnalyticsAgent.exe -test
           Verfy no errors
           Run ITPC-LogAnalyticsAgent.exe -install
 5)  Run Set small Icons Scripts & Desktop Icons Scripts
 6)  Run rest of this script to set common best practices for Master Images
 7)  Set any run at first book commands
 8)  Take Azure Disk Snapshot
 9) sysprep - gnealize and shutdown
 10) Updating Image - mount previous snapshot to a VM, power on, Make changes, re-install Monitoring, dependency & Sepago Agents, reboot, take a azure disk snapshot, sysprep, shutdown
 #>
##############################################################################################################################################################


### Variables
# Added by KarlV
# Get my functions and credentials
. "C:\bin\resources.ps1"

#$FSLUNC = "\\server\share"  # Path to your FSlogix SMB share
#$AADTenant = "xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  #your AAD Tenant ID

# Where you are installing Office Apps from
$InstallDir = "C:\Users\azureadmin\Downloads\test"

# Probably need this
Set-ExecutionPolicy -ExecutionPolicy Unrestricted

###--- End vars


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
$InstallDir\OneDriveSetup.exe /uninstall

# Re-Create the key and entry (we are only going to use 64bit versions of everything)
New-Item -Path "HKLM:\Software\Microsoft\Onedrive" 
New-ItemProperty -Path "HKLM:\Software\Microsoft\Onedrive" -Name "AllUsersInstall" -PropertyType DWORD -Value 1

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



###################################################################
<# 
  ######----  Install Office  ----#######
  You need to download and run the deployment tool to get the files you need
  Reference: https://docs.microsoft.com/en-us/azure/virtual-desktop/install-office-on-wvd-master-image
  Source: https://www.microsoft.com/en-us/download/details.aspx?id=49117
  
  Create a custom control XML file - https://config.office.com/
#>
###################################################################

$InstallDir\Setup.exe /configure "$InstallDir\configuration-Office365-x64.xml"  # use a customize Image to control which office apps are installed

# Create C:\temp\apps\Office\OfficeUpdates.bat
# You need to mount the NTUSER.dat registry hive
### .bat file for configuration
### - this needs to fixed to use PowerShell!!!
#<snip>
rem Mount the default user registry hive
reg load HKU\TempDefault C:\Users\Default\NTUSER.DAT

rem Must be executed with default registry hive mounted.
reg add HKU\TempDefault\SOFTWARE\Policies\Microsoft\office\16.0\common /v InsiderSlabBehavior /t REG_DWORD /d 2 /f

rem Set Outlooks Cached Exchange Mode behavior
rem Must be executed with default registry hive mounted.
reg add "HKU\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode" /v enable /t REG_DWORD /d 1 /f
reg add "HKU\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode" /v syncwindowsetting /t REG_DWORD /d 1 /f
reg add "HKU\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode" /v CalendarSyncWindowSetting /t REG_DWORD /d 1 /f
reg add "HKU\TempDefault\software\policies\microsoft\office\16.0\outlook\cached mode" /v CalendarSyncWindowSettingMonths  /t REG_DWORD /d 1 /f

rem Unmount the default user registry hive
reg unload HKU\TempDefault

rem Set the Office Update UI behavior.
reg add HKLM\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate /v hideupdatenotifications /t REG_DWORD /d 1 /f
reg add HKLM\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate /v hideenabledisableupdates /t REG_DWORD /d 1 /f

rem Set default HKCU Icons settings    
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" /t REG_DWORD /d 0
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" /v "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" /t REG_DWORD /d 0
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /V TaskbarSmallIcons /T REG_DWORD /D 1 /F
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /V SearchboxTaskbarMode /T REG_DWORD /D 0 /F
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /V ShowCortanaButton /T REG_DWORD /D 0 /F
#<snip>

### Teams Install
# TBD - need to copy in from my script - Karl V

### Update Edge Browser



#          <<<----------------------------   Proceed Below after all app installs and configs  ---------------------------->>>
# BGInfo - 
# Add Registry Entry to BGinfo
New-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Run" `
    -Name "bginfo" -PropertyType REG_SZ -Force


# Disable Windows Defender Scanning of VHD
# https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-defender-antivirus/configure-extension-file-exclusions-windows-defender-antivirus
#  Change Group Policy Management Editor >> Administrative templates >> Windows components >> Windows Defender Antivirus >> Exclusions
#    Extension Exclusions:  .vhd, .vhdx
#    Turn Off Auto Exclusion: Disabled


# Disable it in the registry
Write-Host "Disabling Automatic Updates..."
New-ItemProperty -Path "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" `
    -Name "NoAutoUpdate" `
    -PropertyType "REG_DWORD" `
    -Value "1" `
    -Force


# Skiprearm for windows activation after sysprepping   (Doesn't work)
#REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\Currentversion\SL" /v ""
#New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\Currentversion\SL" /v ""


###---------- Configure session timeout policies
function SessionTimeouts ()
{
   # Configuring session timeout policies...
    
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


###----------- END: Session Timeout

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


###------ Teams  ------###

# Download Teams Installer
Invoke-WebRequest -URI https://statics.teams.cdn.office.net/production-windows-x64/1.3.00.21759/Teams_windows_x64.msi -OutFile c:\bin\installteams.msi

# Change to download dir
Set-Location c:\bin

# Add - key as a workaround
#'HKLM:\Software\Citrix\PortICA' or 'HKLM\SOFTWARE\VMware, Inc\VMware VDM\Agent'

# Download Web Socket
Invoke-WebRequest -URI https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4AQBt -OutFile c:\bin\installwebrtc.msi

# Install
.\installwebrtc.msi /quiet

# Enable Teams for VDI so you can install in Machine mode and redirect video
New-Item -Path "HKLM:\Software\Microsoft\Teams" 
New-ItemProperty -Path "HKLM:\Software\Microsoft\Teams" `
    -Name "IsWVDEnvironment" -PropertyType DWORD -Value 1 `
    -Force

# Install the app in "Per Machine Mode"
msiexec /i installteams.msi /l*v teamslog.txt ALLUSER=1 /quiet

###----------  End Teams


###----------  Misc system settings to enforce defaults and BKM.
# The following steps are from: https://docs.microsoft.com/en-us/azure/virtual-machines/windows/prepare-for-upload-vhd-image

# Remove the WinHTTP proxy
netsh winhttp reset proxy


# Set the power profile to the High Performance
powercfg /setactive SCHEME_MIN

# Make sure that the environmental variables TEMP and TMP are set to their default values
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' `
    -name "TEMP" -Value "%SystemRoot%\TEMP" -Type ExpandString -force
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' `
    -name "TMP" -Value "%SystemRoot%\TEMP" -Type ExpandString -force

# Set Windows services to defaults
Set-Service -Name w32time -StartupType Automatic
Get-Service -Name BFE, Dhcp, Dnscache, IKEEXT, iphlpsvc, nsi, mpssvc, RemoteRegistry |
  Where-Object StartType -ne Automatic |
    Set-Service -StartupType Automatic

Get-Service -Name Netlogon, Netman, TermService |
  Where-Object StartType -ne Manual |
    Set-Service -StartupType Manual

### Do you need to explicitly confgure RDP?
### Ensure RDP is enabled
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -Value 0 -Type DWord -force
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -name "fDenyTSConnections" -Value 0 -Type DWord -force

# Set RDP Port to 3389 - Unnecessary for WVD due to reverse connect, but helpful for backdoor administration with a jump box 
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -name "PortNumber" -Value 3389 -Type DWord -force

# Listener is listening on every network interface
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -name "LanAdapter" -Value 0 -Type DWord -force

# Configure NLA
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1 -Type DWord -force
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "SecurityLayer" -Value 1 -Type DWord -force
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "fAllowSecProtocolNegotiation" -Value 1 -Type DWord -force

# Set keep-alive value
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -name "KeepAliveEnable" -Value 1  -Type DWord -force
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -name "KeepAliveInterval" -Value 1  -Type DWord -force
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -name "KeepAliveTimeout" -Value 1 -Type DWord -force

# Reconnect
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -name "fDisableAutoReconnect" -Value 0 -Type DWord -force
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -name "fInheritReconnectSame" -Value 1 -Type DWord -force
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -name "fReconnectSame" -Value 0 -Type DWord -force

# Limit number of concurrent sessions
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -name "MaxInstanceCount" -Value 4294967295 -Type DWord -force

# Remove any self signed certs if they exist
if ((Get-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp').Property -contains 'SSLCertificateSHA1Hash')
{
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name SSLCertificateSHA1Hash -Force
}


### Firewall Configuration (required?)
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# Allow WinRM
REG add "HKLM\SYSTEM\CurrentControlSet\services\WinRM" /v Start /t REG_DWORD /d 2 /f
net start WinRM
Enable-PSRemoting -force
Set-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)" -Enabled True

# Allow RDP
Set-NetFirewallRule -DisplayGroup "Remote Desktop" -Enabled True

# Enable File and Printer sharing for ping
Set-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -Enabled True




#For feedback hub collection of telemetry data on Windows 10 Enterprise multi-session, run this command
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 3 /f


# Fix Watson crashes:
Remove-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\CorporateWerServer*"

# Enter the following commands into the registry editor to fix 5k resolution support
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v MaxMonitors /t REG_DWORD /d 4 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v MaxXResolution /t REG_DWORD /d 5120 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v MaxYResolution /t REG_DWORD /d 2880 /f

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs" /v MaxMonitors /t REG_DWORD /d 4 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs" /v MaxXResolution /t REG_DWORD /d 5120 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\rdp-sxs" /v MaxYResolution /t REG_DWORD /d 2880 /f

#workaround for win10 BiSrv issue
schtasks /change /tn "\Microsoft\Windows\BrokerInfrastructure\BgTaskRegistrationMaintenanceTask" /disable



# Cosmetic Only for my environment

# Desktop Icons and Small Icons, Remove Search/cortana

REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0
REG ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0
REG ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0

REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" /t REG_DWORD /d 0
REG ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" /t REG_DWORD /d 0
REG ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" /v "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" /t REG_DWORD /d 0
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" /v "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" /t REG_DWORD /d 0

REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /V TaskbarSmallIcons /T REG_DWORD /D 1 /F
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /V TaskbarSmallIcons /T REG_DWORD /D 1 /F
REG ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\Search" /V SearchboxTaskbarMode /T REG_DWORD /D 1 /F
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /V SearchboxTaskbarMode /T REG_DWORD /D 1 /F

REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /V ShowCortanaButton /T REG_DWORD /D 0 /F
REG ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /V ShowCortanaButton /T REG_DWORD /D 0 /F
taskkill /f /im explorer.exe
start explorer.exe

#Specify Start Layout for Win 10
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v SpecialRoamingOverrideAllowed /t REG_DWORD /d 1 /f



###========================================================================================###
#                           FSLogix Profile Registry Settings                               #
###========================================================================================###
# Add Defender exclusion for FSLogix
# Need Path Path to your FSlogix SMB share
#
# FSLogix Docs
#  https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference
#  https://docs.microsoft.com/en-us/fslogix/office-container-configuration-reference
#  https://docs.microsoft.com/en-us/fslogix/fslogix-storage-config-ht
#
###========================================================================================###

# $FSLUNC = "\\server\share"  
$FSLUNC = "\\<storageaccount>.file.core.windows.net\<share>\"

# Add Defender exclusion for FSLogix
<# 
If Windows Defender is configured in the VM, make sure it’s configured to not scan VHD and VHDX
files during attachment. Fxlogix use virtual hard discs to store profiles. They are mounted 
on login. Defender can sometimes interfere the mount resulting in unstable profiles.
Settings:
Add-MpPreference -ExclusionExtension ”.vhd”
Add-MpPreference -ExclusionExtension ”.vhdx”
Add-MpPreference -ExclusionPath ”$PATH”
#>
Add-MpPreference -ExclusionPath $FSLUNC
Add-MpPreference -ExclusionExtension ”.vhd”
Add-MpPreference -ExclusionExtension ”.vhdx”

# Registry Keys
$FSLogixKey           = "HKLM:\Software\FSLogix"
$FSLogixUserProfile   = "HKLM:\Software\FSLogix\Profiles"
$ProfileSize          = "1024"

# Be sure to set the FSLogix Variable $FSLUNC above

###---  Profile Container Settings
# We need to create the "Profiles" and "profiles\Apps folders first
New-Item -Path "$FSLogixKey" -Name Profiles -Force

# Jump into the Reg Hive
Set-Location "$FSLogixUserProfile"

# Add the Apps folder for later use
New-Item -Path "." -Name Apps -Force

# Enable the use of FSLogix Profile containers.
Set-ItemProperty -Path "." -Name "Enabled" -Type "Dword" -Value "1"

# IMPORTANT - Tell FSLogix where the profiles live (use Set-Item if you are modifying)
#Set-ItemProperty -Path "." -Name "VHDLocations" -Value "$FSLUNC" -PropertyType MultiString -Force
New-ItemProperty -Path "." -Name "VHDLocations" -Value "$FSLUNC" -PropertyType MultiString -Force

# NOTE: This should be set to "vhd" for Win 7 and Sever 2102R2 - default is vhdx
Set-ItemProperty -Path "." -Name "VolumeType" -Type String -Value "vhdx" 

# Size of the Profle VHDx 10GB in MB - always better to oversize
# FSlogix Overwrites deleted blocks first then new blocks. Should be higher if not using OneDrive 
Set-ItemProperty -Path "." -Name "SizeInMBs" -Type "Dword" -Value "10240"  

# Machine should try to take the RW role and if it can't, it should fall back to a RO role.
Set-ItemProperty -Path "." -Name "ProfileType" -Type "Dword" -Value "3"  

# Cosmetic - change the way each user folder is created
Set-ItemProperty -Path "." -Name "FlipFlopProfileDirectoryName" -Type "Dword" -Value "1"  

# Force deletion of local profile: 0 = no deletion - 1 = deletion
Set-ItemProperty -Path "." -Name "DeleteLocalProfileWhenVHDShouldApply" -Type "Dword" -Value "0"

###--- Optional Settings ---###
# Concurrent sessions: If you want to use the same profile for published 
# Apps & Desktop; user should log into Desktop session first.
Set-ItemProperty -Path "." -Name "ConcurrentUserSessions" -Type "Dword" -Value "1"   

# This should only be used if Concurrent User Settings is set
# Machine should try to take the RW role and if it can't, it should fall back to a RO role.
# If the VHD isn't accessed concurrently, ProfileType should be 0
Set-ItemProperty -Path "." -Name "ProfileType" -Type "Dword" -Value "3"

# Only for Server 2012R2 and Server 2016 Leave Defaul to 0
Set-ItemProperty -Path "." -Name "RoamSearch" -Type "Dword" -Value "2"  

# Only for Server 2012R2 and Server 2016 Leave Default to 0
New-ItemProperty -Path HKLM:\Software\FSLogix\Profiles\Apps -Name "RoamSearch" -Type "Dword" -Value "2"

###--------------------------------------------------------------------------------###
###---  Office Container Settings: Only required if Office profiles are in use  ---###
###--------------------------------------------------------------------------------###
$FSLogixOfficeProfile = "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" 
Set-Location "$FSLogixOfficeProfile"

# Enable Container: 1 = enable; 0 = disable
Set-ItemProperty -Path "." -Name "Enabled" -Type "Dword" -Value "1"

# IMPORTANT - Tell FSLogix where the profiles live
New-ItemProperty -Path "." -Name "VHDLocations" -Value $FSLUNC -PropertyType MultiString -Force

# This should be set to "vhd" for Win 7 and Sever 2102R2
Set-ItemProperty -Path "." -Name "VolumeType" -Type String -Value "vhdx"

# 25GBin MB - always better to oversize - FSlogix Overwrites deleted blocks first then new blocks 
Set-ItemProperty -Path "." -Name "SizeInMBs" -Type "Dword" -Value "25600" 

# Cosmetic change the way each user folder is created
Set-ItemProperty -Path "." -Name "FlipFlopProfileDirectoryName" -Type "Dword" -Value "1" 

# Delete the local profile if it exists: 0 = no deletion; 1 = yes deletion
Set-ItemProperty -Path "." -Name "DeleteLocalProfileWhenVHDShouldApply" -Type "Dword" -Value "0"

# Launch Sysprep
# Write-Host "We'll now launch Sysprep."
# C:\Windows\System32\Sysprep\Sysprep.exe /generalize /oobe /shutdown

<------------------------------------------------------------------------------------------->





