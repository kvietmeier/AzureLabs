###====================================================================================###
<# 
  InstallTeamsInVM.ps1
    Created By: Karl Vietmeier      
                                    
  Description                      
    Install Teams for WVD - non-interactively

    Make sure to check for the latest Teams client version.

  #>                                            
###====================================================================================###
### Here for safety - comment/uncomment as desired
#return

# These might need updating
$DownloadDir  = "C:\temp"
$TeamsVer     = "1.3.00.21759"
$WebRTCVer    = "RE4AQBt"

# These are fixed or derived from the previous 2
# Overkill?  Edit in one place in case things change.
$TeamsURL     = "https://statics.teams.cdn.office.net/production-windows-x64/"
$TeamsMSI     = "/Teams_windows_x64.msi"
$TeamsURI     = $TeamsURL + $TeamsVer + $TeamsMSI 
$TeamsOut     = $DownloadDir + "\installteams.msi"
$WebRTCURL    = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/"
$WebRTCMSI    = "\installwebrtc.msi"
$WebRTCURI    = $WebRTCURL + $WebRTCVer
$WebRTCOut    = $DownloadDir + $WebRTCMSI

# Check to see if C:\temp exists - if not create it
if (!(Test-Path $DownloadDir))
{
  Write-Host "Creating C:\temp"
  New-Item -ItemType Directory -Force -Path $DownloadDir
  $removeDir = "True" # We created it, so remove it afterward
}

# Download Teams Installer (Verify version)
Invoke-WebRequest -URI $TeamsURI -OutFile $TeamsOut

# Change to download dir
Set-Location $DownloadDir

# Download Web Socket (For media redirection)
Invoke-WebRequest -URI $WebRTCURI -OutFile $WebRTCOut

# Install WebSocket
.\installwebrtc.msi /quiet

# Enable Teams for VDI so you can install in Machine mode and redirect video
New-Item -Path "HKLM:\Software\Microsoft\Teams" 
New-ItemProperty -Path "HKLM:\Software\Microsoft\Teams" `
    -Name "IsWVDEnvironment" -PropertyType DWORD -Value 1 `
    -Force

# Install the app in "Per Machine Mode"
msiexec /i installteams.msi /l*v teamslog.txt ALLUSER=1 /quiet

# Remove C:\temp if we created it
if ($removeDir = "True")
{
  Write-Host "Removing C:\temp"
  Set-Location "C:\"
  Remove-Item -Recurse $DownloadDir
}




