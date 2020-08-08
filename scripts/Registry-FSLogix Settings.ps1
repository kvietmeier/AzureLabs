###========================================================================================###
###  Creating FSLogix Registry Settings
#    Written By:  Karl Vietmeier
#    
#    Purpose: Modifying and adding Registry entries for FSLogix with PowerShell
#    
#    Reference:
#    https://docs.microsoft.com/en-us/powershell/scripting/samples/working-with-registry-entries
#
#    To Do:
#      Paramertize and collapse the redundant text into a real script
###========================================================================================###

# don't run on accident
return


# Path to your FSlogix SMB share Link to share/directory permissions
# https://docs.microsoft.com/en-us/fslogix/fslogix-storage-config-ht
# $FSLUNC = "\\server\share"  
$FSLUNC = "\\<storageaccount>.file.core.windows.net\<share>\"

# Registry Keys
$FSLogixUserProfile   = "HKLM:\Software\FSLogix\Profiles"
$FSLogixOfficeProfile = "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" 
$ProfileSize          = "1024"


########################################
#      FSLogix Profile Settings        #
########################################
# Be sure to set the FSLogix Variable above

# We need to create the "Profiles" and "profiles\Apps folders first
New-Item -Path HKLM:\Software\FSLogix\ `
    -Name Profiles `
    -Force

# And the Apps folder for later use
New-Item -Path HKLM:\Software\FSLogix\Profiles\ `
    -Name Apps `
    -Force

# Enbable the use of FSLogix Profile containers.
Set-ItemProperty -Path HKLM:\Software\FSLogix\Profiles `
    -Name "Enabled" `
    -Type "Dword" `
    -Value "1"

# IMPORTANT - Tell FSLogix where the profiles live
New-ItemProperty -Path HKLM:\Software\FSLogix\Profiles `
    -Name "VHDLocations" `
    -Value $FSLUNC `
    -PropertyType MultiString -Force

# Size odf the Profle VHDx 10GB in MB - always better to oversize
# FSlogix Overwrites deleted blocks first then new blocks. Should be higher if not using OneDrive 
Set-ItemProperty -Path HKLM:\Software\FSLogix\Profiles `
    -Name "SizeInMBs" `
    -Type "Dword" `
    -Value "10240"  

# NOTE:  this should be set to "vhd" for Win 7 and Sever 2102R2
Set-ItemProperty -Path HKLM:\Software\FSLogix\Profiles `
    -Name "VolumeType" `
    -Type String `
    -Value "vhdx"

# Machine should try to take the RW role and if it can't, it should fall back to a RO role.
Set-ItemProperty -Path HKLM:\Software\FSLogix\Profiles `
    -Name "ProfileType" `
    -Type "Dword" `
    -Value "3"  

# Cosmetic change the way each user folder is created
Set-ItemProperty -Path HKLM:\Software\FSLogix\Profiles `
    -Name "FlipFlopProfileDirectoryName" `
    -Type "Dword" `
    -Value "1"  

# Force deletion of local profile
# OPTIONAL 0 = no deleton - 1 = deletion - This will deliete existing profiles
Set-ItemProperty -Path HKLM:\Software\FSLogix\Profiles `
    -Name "DeleteLocalProfileWhenVHDShouldApply"  `
    -Type "Dword" `
    -Value "0"

# Optional FSLogix Settings
# Concurrent sessions if you want to use the same profile for published apps & Desktop Should log into Desktop session first
Set-ItemProperty -Path HKLM:\Software\FSLogix\Profiles `
    -Name "ConcurrentUserSessions" `
    -Type "Dword" `
    -Value "1"   

# This should only be used if Concurrent User Settings is set
# Machine should try to take the RW role and if it can't, it should fall back to a RO role.
Set-ItemProperty -Path HKLM:\Software\FSLogix\Profiles `
    -Name "ProfileType" `
    -Type "Dword" `
    -Value "3"

# Only for Server 2012R2 and Server 2016 Leave Defaul to 0
New-ItemProperty -Path HKLM:\Software\FSLogix\Profiles\Apps `
    -Name "RoamSearch" `
    -Type "Dword" `
    -Value "2"

# Only for Server 2012R2 and Server 2016 Leave Defaul to 0
Set-ItemProperty -Path HKLM:\Software\FSLogix\Profiles `
    -Name "RoamSearch" `
    -Type "Dword" `
    -Value "2"  


###---------------- Setup FSX Office Container
Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\FSLogix\ODFC `
    -Name "Enabled" `
    -Type "Dword" `
    -Value "1"
New-ItemProperty -Path HKLM:\SOFTWARE\Policies\FSLogix\ODFC `
    -Name "VHDLocations" `
    -Value $FSLUNC `
    -PropertyType MultiString `
    -Force

# 25GBin MB - always better to oversize - FSlogix Overwrites deleted blocks first then new blocks 
Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\FSLogix\ODFC `
    -Name "SizeInMBs" `
    -Type "Dword" `
    -Value "25600"

# This shoudl be set to "vhd" for Win 7 and Sever 2102R2
Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\FSLogix\ODFC `
    -Name "VolumeType" `
    -Type String `
    -Value "vhdx"

Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\FSLogix\ODFC `
    -Name "FlipFlopProfileDirectoryName" `
    -Type "Dword" `
    -Value "1" 

# 0 = no deletion; 1 = yes deletion
Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\FSLogix\ODFC `
    -Name "DeleteLocalProfileWhenVHDShouldApply" `
    -Type "Dword" `
    -Value "0"