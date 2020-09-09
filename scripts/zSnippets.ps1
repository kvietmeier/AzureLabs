###====================================================================================###
<# 
  zSnippets.ps1                   
    Created By: Karl Vietmeier    
                                 
  Description                   
    Misc bits and pieces       
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

# RDP settings
# https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/clients/rdp-files
# Use Update-AzWvdHostPool
Update-AzWvdHostPool -ResourceGroupName ResourceGroupName `
    -Name HostPoolName `
    -LoadBalancerType 'BreadthFirst' `
    -Description 'Description' `
    -FriendlyName 'Friendly Name' `
    -MaxSessionLimit 6 `
    -SsoContext $null `
    -CustomRdpProperty $null `
    -Ring $null `
    -ValidationEnvironment:$false
    
Update-AzWvdHostPool -ResourceGroupName Test-rg -Name Testpool -CustomRdpProperty "audiocapturemode:i:1;use multimon:i:0"
Set-RdsHostPool -TenantName MyTenant -HostPoolName MyPool -CustomRdpProperty "audiocapturemode:i:1;use multimon:i:0"

$properties="audiocapturemode:i:1;use multimon:i:0"
Update-AzWvdHostPool -ResourceGroupName $AZResourceGroup -Name TestPool01 -CustomRdpProperty $properties

$AZResourceGroup = "TempRG-01"
$AppGroup = "TestLogin-DAG"

Get-AzWvdHostPool -ResourceGroupName $AZResourceGroup
Get-AzWvdHostPool -ResourceGroupName $AZResourceGroup -Name TestPool01
Get-AzWvdApplicationGroup -ResourceGroupName $AZResourceGroup
Get-AzWvdApplicationGroup -ResourceGroupName $AZResourceGroup -Name $AppGroup | format-list Name

Get-AzWvdHostPool -ResourceGroupName $AZResourceGroup -Name TestPool01 | format-list Name, CustomRdpProperty


Remove-AzWvdApplicationGroup -ResourceGroupName $AZResourceGroup -Name $AppGroup
Remove-AzWvdHostPool -ResourceGroupName TempRG-01 -Name Foobar02


### Remove OneDrive Components
Taskkill.exe /F /IM "OneDrive.exe"
Taskkill.exe /F /IM "Explorer.exe"`

if (Test-Path "C:\\Windows\\System32\\OneDriveSetup.exe") {
    Start-Process "C:\\Windows\\System32\\OneDriveSetup.exe"`
     -ArgumentList "/uninstall"`
     -Wait
}
if (Test-Path "C:\\Windows\\SysWOW64\\OneDriveSetup.exe") {
    Start-Process "C:\\Windows\\SysWOW64\\OneDriveSetup.exe"`
      -ArgumentList "/uninstall"`
      -Wait 
}

Remove-Item -Path "C:\\Windows\\ServiceProfiles\\LocalService\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\Programs\\OneDrive.lnk" -Force

# Remove the automatic start item for OneDrive from the default user profile registry hive
Remove-Item -Path "C:\\Windows\\ServiceProfiles\\NetworkService\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\Programs\\OneDrive.lnk" -Force 
Start-Process C:\\Windows\\System32\\Reg.exe -ArgumentList "Load HKLM\\Temp C:\\Users\\Default\\NTUSER.DAT" -Wait
Start-Process C:\\Windows\\System32\\Reg.exe -ArgumentList "Delete HKLM\\Temp\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run /v OneDriveSetup /f" -Wait
Start-Process C:\\Windows\\System32\\Reg.exe -ArgumentList "Unload HKLM\\Temp" -Wait Start-Process -FilePath C:\\Windows\\Explorer.exe -Wait