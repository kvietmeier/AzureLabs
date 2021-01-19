###========================================================================================###
<###  Creating FSLogix Registry Settings
    Written By:  Karl Vietmeier
    
    Purpose: Modifying and adding Registry entries for FSLogix with PowerShell
    
    References:
    * PowerShell
      https://docs.microsoft.com/en-us/powershell/scripting/samples/working-with-registry-entries

    * FSLogix
      https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference
      https://docs.microsoft.com/en-us/fslogix/office-container-configuration-reference

    This is best done through GPO
#>
###========================================================================================###

# Don't run as a script on accident
return

###------ Install FSLogix if required
function InstallFSLogix () {

  $DownloadDir        = "C:\temp"
  $FSLogixExtractDir  = $DownloadDir + "\InstallFSLogix"
  $FSLogixZip         = $DownloadDir + '\InstallFSLogix.zip'
  $FSLogixInstallDir  = $DownloadDir + '\InstallFSLogix\x64\Release'

  # Check to see if C:\temp exists - if not create it
  if (!(Test-Path $DownloadDir))
  {
    Write-Host "Creating C:\temp"
    New-Item -ItemType Directory -Force -Path $DownloadDir
    $RemoveDir = "True" # We created it, so remove it afterward
  }
  elseif (Test-Path $FSLogixExtractDir)
  {
    Write-Host "Removing existing FSLogix download"
    Remove-Item -Recurse $FSLogixExtractDir
  }

  # Download and extract
  Invoke-Webrequest -Uri "https://aka.ms/fslogix_download" -OutFile $FSLogixZip
  Set-Location $DownloadDir
  Expand-Archive .\InstallFSLogix.zip
  Set-Location $FSLogixInstallDir

  # Install - 
  $AgentInstaller = "FSLogixAppsSetup.exe"
  $Switches = "/install /quiet /norestart"
  $OS = (Get-WmiObject Win32_OperatingSystem).Caption

  # Install the FSLogix Apps agent
  Start-Process -Wait ".\$AgentInstaller" -ArgumentList $Switches

  # Cleanup install dir
  if ($RemoveDir -eq "True")
  {
    Write-Host "Removing C:\temp"
    Set-Location "C:\"
    Remove-Item -Recurse $DownloadDir
  }

}
# Uncomment function
InstallFSLogix


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


function profileregistry () {
  # Path to your FSlogix SMB share Link to share/directory permissions
  # https://docs.microsoft.com/en-us/fslogix/fslogix-storage-config-ht
  # $FSLUNC = "\\fileserver\sharename"  
  # Use this dummy value or set it to the correct value, a later GPO will 
  # overwrite or you can update later 
  $FSLUNC = "\\storageaccount.file.core.windows.net\share\"

  # Registry Keys
  $FSLogixKey           = "HKLM:\Software\FSLogix"
  $FSLogixUserProfile   = "HKLM:\Software\FSLogix\Profiles"
  $ProfileSize          = "25000"

  ###========================================================================================###
  #                           FSLogix Profile Registry Settings                               #
  ###========================================================================================###
  # Be sure to set the FSLogix Variable $FSLUNC above
  <# 
  Recommended values
  Enabled                                     "1"
  VHDLocations                                "$FSLUNC"
  VolumeType                                  "vhdx"
  SizeInMBs                                   "15000"
  ProfileType                                 "3"
  FlipFlopProfileDirectoryName                "1"
  DeleteLocalProfileWhenVHDShouldApply        "1"
  #>

  ###---  Profile Container Settings
  # We need to create the "Profiles" and "profiles\Apps folders first
  New-Item -Path "$FSLogixKey" -Name Profiles -Force

  # Jump into the Reg Hive
  Set-Location "$FSLogixUserProfile"

  # Add the Apps folder for later use
  New-Item -Path "." -Name Apps -Force

  # Enable the use of FSLogix Profile containers.
  New-ItemProperty -Path "." -Name "Enabled" -PropertyType "DWORD" -Value "1"

  # IMPORTANT - Tell FSLogix where the profiles live (use Set-Item if you are modifying)
  New-ItemProperty -Path "." -Name "VHDLocations" -Value "$FSLUNC" -PropertyType MultiString -Force

  # NOTE: This should be set to "vhd" for Win 7 and Sever 2102R2 - default is vhdx
  New-ItemProperty -Path "." -Name "VolumeType" -PropertyType String -Value "vhdx" 

  # Size of the Profle VHDx 10GB in MB - always better to oversize
  # FSlogix Overwrites deleted blocks first then new blocks. Should be higher if not using OneDrive 
  New-ItemProperty -Path "." -Name "SizeInMBs" -PropertyType "DWORD" -Value "$ProfileSize"  

  # Machine should try to take the RW role and if it can't, it should fall back to a RO role.
  New-ItemProperty -Path "." -Name "ProfileType" -PropertyType "DWORD" -Value "3"  

  # Keep more logfiles
  New-ItemProperty -Path "." -Name "LogFileKeepingPeriod" -PropertyType "DWORD" -Value "7"  

  # Cosmetic - change the way each user folder is created
  New-ItemProperty -Path "." -Name "FlipFlopProfileDirectoryName" -PropertyType "DWORD" -Value "1"  

  # Force deletion of local profile: 0 = no deletion - 1 = deletion
  New-ItemProperty -Path "." -Name "DeleteLocalProfileWhenVHDShouldApply" -PropertyType "DWORD" -Value "0"

  ###--- Optional Settings ---###
  # Concurrent sessions: If you want to use the same profile for published 
  # Apps & Desktop; user should log into Desktop session first.
  New-ItemProperty -Path "." -Name "ConcurrentUserSessions" -PropertyType "DWORD" -Value "1"   

  # This should only be used if Concurrent User Settings is set
  # Machine should try to take the RW role and if it can't, it should fall back to a RO role.
  # If the VHD isn't accessed concurrently, ProfileType should be 0
  #New-ItemProperty -Path "." -Name "ProfileType" -PropertyType "DWORD" -Value "0"

  # Only for Server 2012R2 and Server 2016 Leave Defaul to 0
  #New-ItemProperty -Path "." -Name "RoamSearch" -PropertyType "DWORD" -Value "2"  

  # Only for Server 2012R2 and Server 2016 Leave Default to 0
  #New-ItemProperty -Path HKLM:\Software\FSLogix\Profiles\Apps -Name "RoamSearch" -PropertyType "DWORD" -Value "2"

}

# Configure User Profile Settings - function call
#profileregistry

function OProfileRegistry () {
  ###--------------------------------------------------------------------------------###
  ###---  Office Container Settings: Only required if Office profiles are in use  ---###
  ###--------------------------------------------------------------------------------###
  $FSLogixOfficeProfile = "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" 
  New-Location "$FSLogixOfficeProfile"

  # Enable Container: 1 = enable; 0 = disable
  New-ItemProperty -Path "." -Name "Enabled" -PropertyType "DWORD" -Value "1"

  # IMPORTANT - Tell FSLogix where the profiles live
  New-ItemProperty -Path "." -Name "VHDLocations" -Value $FSLUNC -PropertyType MultiString -Force

  # This should be set to "vhd" for Win 7 and Sever 2102R2
  New-ItemProperty -Path "." -Name "VolumeType" -PropertyType String -Value "vhdx"

  # 25GBin MB - always better to oversize - FSlogix Overwrites deleted blocks first then new blocks 
  New-ItemProperty -Path "." -Name "SizeInMBs" -PropertyType "DWORD" -Value "25600" 

  # Cosmetic change the way each user folder is created
  New-ItemProperty -Path "." -Name "FlipFlopProfileDirectoryName" -PropertyType "DWORD" -Value "1" 

  # Delete the local profile if it exists: 0 = no deletion; 1 = yes deletion
  New-ItemProperty -Path "." -Name "DeleteLocalProfileWhenVHDShouldApply" -PropertyType "DWORD" -Value "0"

}

# Uncomment as needed
#OProfileRegistry 

###====================================================
#### - testing this 
<# if ((Get-Item -Path ".").Property -contains 'Enabled')
{
    Set-ItemProperty -Path "." -Name  "Enabled" -PropertyType "DWORD" -Value "1"
}
else {
    New-ItemProperty -Path "." -Name  "Enabled" -PropertyType "DWORD" -Value "1"
} #>
