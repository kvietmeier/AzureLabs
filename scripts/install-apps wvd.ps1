<----------------#OPTION 1#---------------------->

#Install-Apps
$DownloadPath = "C:\"
$Sa = "https://buildscriptswvd.blob.core.windows.net/buildscript/wvdimgbuild.zip"
$Blob = "buildscript"
New-Item -Path $DownloadPath - Directory -Force | Out-Null
Invoke-WebRequest -Uri "$Sa/$Blob/input.csv" -Outfile "$DownloadPath\input.csv"
$Packages = import-csv "$DownloadPath\input.csv"
ForEach ($Package in $Packages){
$AppName = $(package.AppName)
$ZipName = $(package.ZipName)
$CommandLine = $(package.CommandLine)
$Arguments = $(package.Arguments)
Write-Host $AppName $ZipName
Invoke-WebRequest -Uri "$Sa/$Blob/ZipName.zip" -OutFile "$DownloadPath\$ZipName.zip"
Expand-Archive -Path "$DownloadPath\$ZipName.zip" -DestinationPath "$DownloadPath" -Force
Write-Host "$DownloadPath\$ZipName\$CommandLine" "$Arguments" "$DownloadPath\$ZipName"
Start-Process "$CommandLine" -WorkingDirectory "$DownloadPath\$ZipName" -Wait -ArgumentList "$Arguments"
}


<----------------#OPTION 2#---------------------->

### Download Application Packages
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
New-Item -Path 'C:\temp' -ItemType Directory -Force | Out-Null
Invoke-WebRequest -Uri "https://wvdapplications.blob.core.windows.net/applications/wvdimgbuild.zip" -OutFile "c:\temp\wvdimgbuild.zip"
Expand-Archive -Path 'C:\temp\wvdimgbuild.zip' -DestinationPath 'C:\temp' -Force

$username = 'azureadmin'
$password = "P@ssword2019"
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential $username, $securePassword
Start-Process "C:\temp\sepago\Azure Monitor for WVD\ITPC-LogAnalyticsAgent.exe" -Wait -ArgumentList '-install'

#Install Applications for Azure Image Builder script
Write-Host "Install Microsoft Edge 77"
Start-Process msiexec.exe -ArgumentList "/I c:\temp\files\MicrosoftEdgeEnterpriseX64.msi /quiet"
Write-Host "Install Notepad++"
Start-Process "c:\temp\files\npp.7.7.1.Installer.exe" -Wait -ArgumentList '/S'
Write-Host "Install FSLogix Agent"
Start-Process "c:\temp\FSLogix\x64\Release\FSLogixAppsSetup.exe" -Wait -ArgumentList '/install /quiet'
Write-Host "Install FSLogix Rule Editor"
Start-Process "c:\temp\FSLogix\x64\Release\FSLogixAppsRuleEditorSetup.exe" -Wait -ArgumentList '/install /quiet'
Write-Host "Install FSLogix Java Editor"
Start-Process "c:\temp\FSLogix\x64\Release\FSLogixAppsJavaRuleEditorSetup.exe" -Wait -ArgumentList '/install /quiet'
Write-Host "Install Office"
Start-Process "c:\temp\files\Setup.exe" -Wait -ArgumentList '/configure c:\temp\files\configurationwvd.xml'
Write-Host "Install OneDrive"
Start-Process "c:\temp\files\OneDriveSetup.exe" -Wait -ArgumentList '/allusers'
Write-Host "Install Sepago"
Start-Process "C:\temp\sepago\Azure Monitor for WVD\ITPC-LogAnalyticsAgent.exe" -Wait -ArgumentList '-install'
Write-Host "Install Service Map"
Start-Process "c:\temp\files\InstallDependencyAgent-Windows.exe" -Wait -ArgumentList '/S'