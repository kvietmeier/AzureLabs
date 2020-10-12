###====================================================================================###
<# 
  InstallTeamsInVM.ps1
    Created By: Karl Vietmeier      
                                    
  Description                      
    Install Teams for WVD - non-interactively

    Need to fix the paths - 
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

$DownloadDir = "c:\temp"

# Download Teams Installer (might fail on version)
Invoke-WebRequest -URI https://statics.teams.cdn.office.net/production-windows-x64/1.3.00.21759/Teams_windows_x64.msi -OutFile c:\temp\installteams.msi

# Change to download dir
Set-Location $DownloadDir

# Download Web Socket (For media redirection)
Invoke-WebRequest -URI https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4AQBt -OutFile c:\bin\installwebrtc.msi

# Install WebSocket
.\installwebrtc.msi /quiet

# Enable Teams for VDI so you can install in Machine mode and redirect video
New-Item -Path "HKLM:\Software\Microsoft\Teams" 
New-ItemProperty -Path "HKLM:\Software\Microsoft\Teams" `
    -Name "IsWVDEnvironment" -PropertyType DWORD -Value 1 `
    -Force

# Install the app in "Per Machine Mode"
msiexec /i installteams.msi /l*v teamslog.txt ALLUSER=1 /quiet
