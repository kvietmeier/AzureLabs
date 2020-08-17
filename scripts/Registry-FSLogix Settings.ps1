###========================================================================================###
###  Creating FSLogix Registry Settings
#    Written By:  Karl Vietmeier
#    
#    Purpose: Modifying and adding Registry entries for FSLogix with PowerShell
#    
#    References:
#    * PowerShell
#      https://docs.microsoft.com/en-us/powershell/scripting/samples/working-with-registry-entries
#
#    * FSLogix
#      https://docs.microsoft.com/en-us/fslogix/profile-container-configuration-reference
#      https://docs.microsoft.com/en-us/fslogix/office-container-configuration-reference
#
###========================================================================================###

# Don't run as a script on accident
return


# Path to your FSlogix SMB share Link to share/directory permissions
# https://docs.microsoft.com/en-us/fslogix/fslogix-storage-config-ht
# $FSLUNC = "\\server\share"  
$FSLUNC = "\\<storageaccount>.file.core.windows.net\<share>\"

# Registry Keys
$FSLogixKey           = "HKLM:\Software\FSLogix"
$FSLogixUserProfile   = "HKLM:\Software\FSLogix\Profiles"
$ProfileSize          = "1024"

# Add Defender exclusion for FSLogix
Add-MpPreference -ExclusionPath $FSLUNC


###========================================================================================###
#                           FSLogix Profile Registry Settings                               #
###========================================================================================###
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