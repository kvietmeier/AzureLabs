<# 
  Tier and untier files.
  Requires Azure FileSync to be installed  

  Will install Agent if required.

#>

function DownloadSync ()
{
    # Gather the OS version
    $osver = [System.Environment]::OSVersion.Version

    # Download the appropriate version of the Azure File Sync agent for your OS.
    if ($osver.Equals([System.Version]::new(10, 0, 17763, 0))) {
        Invoke-WebRequest `
            -Uri https://aka.ms/afs/agent/Server2019 `
            -OutFile "StorageSyncAgent.msi" 
    } elseif ($osver.Equals([System.Version]::new(10, 0, 14393, 0))) {
        Invoke-WebRequest `
            -Uri https://aka.ms/afs/agent/Server2016 `
            -OutFile "StorageSyncAgent.msi" 
    } elseif ($osver.Equals([System.Version]::new(6, 3, 9600, 0))) {
        Invoke-WebRequest `
            -Uri https://aka.ms/afs/agent/Server2012R2 `
            -OutFile "StorageSyncAgent.msi" 
    } else {
        throw [System.PlatformNotSupportedException]::new("Azure File Sync is only supported on Windows Server 2012 R2, Windows Server 2016, and Windows Server 2019")
    }

}

function InstallSync ()
{
    # Install the MSI. Start-Process is used so PowerShell blocks until the operation is complete.
    # Note that the installer currently forces all PowerShell sessions closed - this is a known issue.
    Start-Process -FilePath "StorageSyncAgent.msi" -ArgumentList "/quiet" -Wait
}

# Note that this cmdlet will need to be run in a new session based on the above comment.
# You may remove the temp folder containing the MSI and the EXE installer
Remove-Item -Path ".\StorageSyncAgent.msi" -Recurse -Force

# Import module (after installing agent)
Import-Module "C:\Program Files\Azure\StorageSyncAgent\StorageSync.Management.ServerCmdlets.dll"


# Variables
param (
    #[string]$action,
    [string]$action = "tier",
    [Parameter(Mandatory=$true)][string]$fileshare
 )


Write-Host "$action"

if ($action -match "^tier") {
    # Tier off files
    Write-Host "Invoke-StorageSyncCloudTiering -Path $fileshare"
}
elseif ($action -match "untier") {
    # Bring them back
    Write-Host "Invoke-StorageSyncFileRecall -Path $fileshare"
}
