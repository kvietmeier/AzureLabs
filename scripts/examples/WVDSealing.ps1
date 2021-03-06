<#
From Cortek
.Version
    2.1
    Integrated Karl Vietmeier's  WVD Registry-SystemSettings.ps1 script into this script

.Synopsis  
    This script automate the FSLogix install and configuration in WVD

.Description  
     This script will help automate the WVD process. You need to provide the FSLogix UNC, the workspace id and workspace key for the monitor agents. If you provide your azure tenant id, OneDrive is configured using that information.

.Parameter FSLogixUNC
    This is the UNC Path to your FSLogix profile share

.Parameter TempFolder
    This is the temporary folder that will be used to download the installers.

.Parameter AzureTenantId
    This is used to configure OneDrive
    configure to "true" in parameters if you want to force entry of AAD tenant, otherwise it is skipped for OneDrive configuration

#>  
 
 Param(
        [Parameter(Mandatory=$false)][string]$WorkSpaceID = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
        [Parameter(Mandatory=$false)][string]$WorkSpaceKey = '----------------------------------------------------------------------------------------',
        [Parameter(Mandatory=$false)][string]$StorageAccountShareName = 'fslogix',
        [Parameter(Mandatory=$false)][string]$StorageAccountName = 'storageacct',
		[Parameter(Mandatory=$false)][string]$StorageAccountKey = '----------------------------------------------------------------------------------------',
        [Parameter(Mandatory=$false)][string]$StorageAccountURL = 'https://' + $StorageAccountName + '.blob.core.windows.net/scripts/',
        [Parameter(Mandatory=$false)][string]$StorageAccountUNC = '\\' + $StorageAccountName + '.file.core.windows.net\' + $StorageAccountShareName,
        [Parameter(Mandatory=$false)][string]$StorageAccountUser = 'Azure\' + $StorageAccountName,
		[Parameter(Mandatory=$false)][string]$FSLogixUNC = '\\storageacct.file.core.windows.net\fslogix\Profiles',
        [Parameter(Mandatory=$false)][bool]$RunSysprep = $false
)

# Start logging the actions
Start-Transcript -Path C:\ProgramData\Coretek\WVDSealing.txt -NoClobber

# Disabled - using GPO to map drive as USER
# Create scheduled task to Map Drive fir FSLogix Profiles

# $ScheduledTaskAction = New-ScheduledTaskAction -Execute "C:\ProgramData\Coretek\netuse.bat"
# $ScheduleTaskTime = New-ScheduledTaskTrigger -AtStartup
# $ScheduledTaskAccount = New-ScheduledTaskPrincipal "nt authority\system"
# $ScheduledTask = New-ScheduledTask -Action $ScheduledTaskAction -Principal $ScheduledTaskAccount -Trigger $ScheduleTaskTime
# Register-ScheduledTask -TaskName "WVD - Net Use Scheduled Task" -InputObject $ScheduledTask

function Get-FileURL($Url,$Output)
{

$start_time = Get-Date
$null = Invoke-WebRequest -Uri $Url.AbsoluteUri -OutFile $Output
Write-Output "Downloaded: $((Get-Date).Subtract($start_time).Seconds) second(s)"
}

# Disable IEESC
function Disable-IEESC
{
& 'C:\Program Files\Internet Explorer\iexplore.exe'
$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force -ErrorAction SilentlyContinue
Stop-Process -Name IExplore
Write-Host " IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
}

Disable-IEESC

Write-Output " Disabling Automatic Windows Updates..."
& reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU /v NoAutoUpdate /t REG_DWORD /d 1 /f


# Configure session timeout policies
Write-Output " Configuring session timeout policies..."
& reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v RemoteAppLogoffTimeLimit /t REG_DWORD /d 0 /f
& reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fResetBroken /t REG_DWORD /d 1 /f
& reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v MaxConnectionTime /t REG_DWORD /d 57600000 /f
& reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v RemoteAppLogoffTimeLimit /t REG_DWORD /d 0 /f
& reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v MaxDisconnectionTime /t REG_DWORD /d 7200000 /f
& reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v MaxIdleTime /t REG_DWORD /d 7200000 /f


# Time zone configuration

#set time zone to EST
#Set-TimeZone -Name "eastern standard time"

#set time zone to IST
#Set-TimeZone -Name "India Standard Time"

# Enable timezone redirection
Write-Output " Enabling time zone redirection..."
& reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v fEnableTimeZoneRedirection /t REG_DWORD /d 1 /f

# Set Coordinated Universal Time (UTC) time for Windows 
Write-Output " Setting UTC for Windows..."
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

# Remove the WinHTTP proxy
& netsh winhttp reset proxy

# Make sure that the environmental variables TEMP and TMP are set to their default values
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -name "TEMP" -Value "%SystemRoot%\TEMP" -Type ExpandString -force
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -name "TMP" -Value "%SystemRoot%\TEMP" -Type ExpandString -force

# Ensure RDP is enabled
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -Value 0 -Type DWord -force
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -name "fDenyTSConnections" -Value 0 -Type DWord -force

# Set RDP Port to 3389 - Unnecessary for WVD due to reverse connect, but helpful for backdoor administration with a jump box 
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -name "PortNumber" -Value 3389 -Type DWord -force

# Listener is listening on every network interface
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -name "LanAdapter" -Value 0 -Type DWord -force

# Set keep-alive value
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -name "KeepAliveEnable" -Value 1  -Type DWord -force
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -name "KeepAliveInterval" -Value 1  -Type DWord -force
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -name "KeepAliveTimeout" -Value 1 -Type DWord -force

# Reconnect
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services' -name "fDisableAutoReconnect" -Value 0 -Type DWord -force
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -name "fInheritReconnectSame" -Value 1 -Type DWord -force
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -name "fReconnectSame" -Value 0 -Type DWord -force

# Allow WinRM
& REG add "HKLM\SYSTEM\CurrentControlSet\services\WinRM" /v Start /t REG_DWORD /d 2 /f
Start-Service WinRM
Enable-PSRemoting -force
Set-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)" -Enabled True

# Add Defender exclusion for FSLogix
Add-MpPreference -ExclusionPath $FSLogixUNC

# create source directory for Sepago and WVD scripts============================
If(!(Test-Path "C:\ProgramData\Coretek"))
{  
    new-item -path "C:\ProgramData\" -Name "Coretek" -ItemType "Directory" -Force
    new-item -path "C:\Program Files\" -name "Azure Monitor for WVD" -ItemType "Directory" -Force
}

#Install FSLogix Agent
Try {
    $url = $StorageAccountURL + "FSLogixAppsSetup.exe"
    $output = "C:\ProgramData\Coretek\FSLogixAppsSetup.exe"
    Invoke-WebRequest -Uri $url -OutFile $output
 } Catch {
    Write-Error "Failed to download FSLogix file"
}
Start-Sleep -s 10
cd\
cd programdata\Coretek
.\FSLogixAppsSetup.exe /install /quiet /norestart

# Add FSLogix settings
New-Item -Path HKLM:\Software\FSLogix\ -Name Profiles -Force
Set-ItemProperty -Path HKLM:\Software\FSLogix\Profiles -Name "Enabled" -Type "Dword" -Value "1" -Force
New-ItemProperty -Path HKLM:\Software\FSLogix\Profiles -Name "VHDLocations" -Value $FSLogixUNC -PropertyType MultiString -Force
Set-ItemProperty -Path HKLM:\Software\FSLogix\Profiles -Name "SizeInMBs" -Type "Dword" -Value "32768" -Force
Set-ItemProperty -Path HKLM:\Software\FSLogix\Profiles -Name "IsDynamic" -Type "Dword" -Value "1" -Force
Set-ItemProperty -Path HKLM:\Software\FSLogix\Profiles -Name "LockedRetryCount" -Type "Dword" -Value "1" -Force
Set-ItemProperty -Path HKLM:\Software\FSLogix\Profiles -Name "LockedRetryInterval" -Type "Dword" -Value "0" -Force
Set-ItemProperty -Path HKLM:\Software\FSLogix\Profiles -Name "AccessNetworkAsComputerObject" -Type "Dword" -Value "0" -Force
Set-ItemProperty -Path HKLM:\Software\FSLogix\Profiles -Name "FlipFlopProfileDirectoryName" -Type "Dword" -Value "1" -Force

# Windows Store disable setting (this triggers and error because it does not exist)
# New-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore\ -Name "DisableStoreApps" -Type "Dword" -Value "1" -Force

# Disabled - Using GPO
#map network drive
#net use x: $StorageAccountUNC /persistent:yes


#modify OneDrive Settings
& reg add "HKLM\SOFTWARE\Policies\Microsoft\OneDrive" /v FilesOnDemandEnabled /t REG_DWORD /d 00000001 /f
& reg add "HKLM\SYSTEM\CurrentControlSet\Services\CldFlt" /v Start /t REG_DWORD /d 00000002 /f

# Only for reference purposes - using GPO
#write out Net use file
$a="net use x: " + $StorageAccountUNC + " /persistent:yes /u:" + $StorageAccountUser + " " + $StorageAccountKey
out-file -filepath "c:\programdata\Coretek\netuse.bat" -inputobject $a

# START MMA Process---------------------------------------------------------------------------------------------/
# Set the parameters
$FileName = "MMASetup-AMD64.exe"
$SMFileName = "InstallDependencyAgent-Windows.exe"
$AzureMonitorFolder = 'C:\ProgramData\Coretek\'
$MMAFile = $AzureMonitorFolder + "\" + $FileName
$SMFile = $AzureMonitorFolder + "\" + $SMFileName

# Check if folder exists, if not, create it
 if (Test-Path $AzureMonitorFolder){
 Write-Host "The folder $AzureMonitorFolder already exists."
 } 
 else 
 {
 Write-Host "The folder $AzureMonitorFolder does not exist, creating..." -NoNewline
 New-Item $AzureMonitorFolder -type Directory | Out-Null
 Write-Host "done!" -ForegroundColor Green
 }

# Change the location to the specified folder
Set-Location $AzureMonitorFolder

# Check if Microsoft Monitoring Agent file exists, if not, download it
 if (Test-Path $FileName){
 Write-Host "The file $FileName already exists."
 }
 else
 {
 Write-Host "The file $FileName does not exist, downloading..." -NoNewline
 $URL = "http://download.microsoft.com/download/1/5/E/15E274B9-F9E2-42AE-86EC-AC988F7631A0/MMASetup-AMD64.exe"
 Invoke-WebRequest -Uri $URl -OutFile $MMAFile | Out-Null
 Write-Host "done!" -ForegroundColor Green
 }

# Check if Service Map Agent exists, if not, download it
 if (Test-Path $SMFileName){
 Write-Host "The file $SMFileName already exists."
 }
 else
 {
 Write-Host "The file $SMFileName does not exist, downloading..." -NoNewline
 $URL = "https://aka.ms/dependencyagentwindows"
 Invoke-WebRequest -Uri $URl -OutFile $SMFile | Out-Null
 Write-Host "done!" -ForegroundColor Green
 } 
 
# Install the Microsoft Monitoring Agent
Write-Host "Installing Microsoft Monitoring Agent.." -nonewline
$ArgumentList = '/C:"setup.exe /qn ADD_OPINSIGHTS_WORKSPACE=1 '+  "OPINSIGHTS_WORKSPACE_ID=$WorkspaceID " + "OPINSIGHTS_WORKSPACE_KEY=$WorkSpaceKey " +'AcceptEndUserLicenseAgreement=1"'
Start-Process $FileName -ArgumentList $ArgumentList -ErrorAction Stop -Wait | Out-Null
Write-Host "done!" -ForegroundColor Green

# Install the Service Map Agent
Write-Host "Installing Service Map Agent.." -nonewline
$ArgumentList = '/C:"InstallDependencyAgent-Windows.exe /S /AcceptEndUserLicenseAgreement:1"'
Start-Process $SMFileName -ArgumentList $ArgumentList -ErrorAction Stop -Wait | Out-Null
Write-Host "done!" -ForegroundColor Green

# Change the location to C: to remove the created folder
Set-Location -Path "C:\"

<#
# Remove the folder with the agent files
 if (-not (Test-Path $AzureMonitorFolder)) {
 Write-Host "The folder $AzureMonitorFolder does not exist."
 } 
 else 
 {
 Write-Host "Removing the folder $AzureMonitorFolder ..." -NoNewline
 Remove-Item $AzureMonitorFolder -Force -Recurse | Out-Null
 Write-Host "done!" -ForegroundColor Green
 }
#>

# END MMA PROCESS -----------------------------------------------------------------------------\

# START Sepago Process-------------------------------------------------------------------------/
# Install Sepago Agent
Download/config/install Sepago Agent
Try {
    $url3 = $StorageAccountURL + "ITPC-LogAnalyticsAgent.zip"
    $output3 = "C:\ProgramData\Coretek\ITPC-LogAnalyticsAgent.zip"
    Invoke-WebRequest -Uri $url3 -OutFile $output3
    Expand-Archive -literalPath "C:\ProgramData\Coretek\ITPC-LogAnalyticsAgent.zip" -DestinationPath "c:\program Files\"

    $ITPCConfig = Select-Xml 'C:\Program Files\Azure Monitor For WVD\ITPC-LogAnalyticsAgent.exe.config' -XPath '//add'

    $c = $ITPCConfig.Node.Count
    for ($i = 0; $i -lt $c; $i++)
        {
        # Write-Output $ITPCConfig.Node[$i].key
        # Write-Output $ITPCConfig.Node[$i].value
        If($ITPCConfig.Node[$i].key -eq "CustomerId")
        {
            $ITPCConfig.Node[$i].Value = $WorkspaceId
        # Write-Output $ITPCConfig.Node[$i].value
        }
        If($ITPCConfig.Node[$i].key -eq "SharedKey")
        {
            $ITPCConfig.Node[$i].Value = $WorkspaceKey
            # Write-Output $ITPCConfig.Node[$i].value
        }

   }
    # Save File
    $ITPCConfig.Node.OwnerDocument.Save($ITPCConfig.Path[0])

 Install Agent
& 'C:\Program Files\Azure Monitor for WVD\ITPC-LogAnalyticsAgent.exe' -install
Start-Sleep -Seconds 60

 } Catch {
    Write-Error "Failed to download and install Sepago"
}
# END Sepago Process------------------------------------------------------------------------------------------------------------------------
Stop-Transcript