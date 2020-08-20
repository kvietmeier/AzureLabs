<#
From: (not mine)
https://www.christopherkibble.com/making-registry-changes-users-powershell/

*******************************************************************************************************************************
** All code is for demonstration only and should be used at your own risk. I cannot accept liability for unexpected results. **
*******************************************************************************************************************************

Use: You're welcome to use, modify, and distribute this script.  I'd love to hear about how you're using it or 
modifications you've made in the comments section of the original post over at ChristopherKibble.com.

--- More than I need but interesting
#>

# This key contains all of the profiles on the machine (including non-user profiles)
$profileList = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"

# This key contains the path to the folder that contains all the profiles (typically c:\users)
$profileFolder = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList').ProfilesDirectory

# This key contains the path to the default user profile (e.g. C:\Users\Default).  This is **NOT** HKEY_USERS\.DEFAULT!
# We don't do anything with it in this sample script, but it can be loaded and modified just like any other profile.
$defaultFolder = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList').Default

# HKEY_USER key is not loaded into PowerShell by default and we'll need it, so we'll create new PSDrive to reference it.
New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null

$profileList | % {
	
	$profileKeys = Get-ItemProperty $_.PSPath
	
	$sid = $profileKeys.PSChildName
	$profilePath = $profileKeys.ProfileImagePath
	
	# This is an easy way to exclude profiles outside of the default USERS profile folder, e.g. LocalSystem.
	# You may or may not want to do this depending on your requirements.
	if ($profilePath -like "$($profileFolder)*") {
		
		# Check if the profile is already loaded.		
		if (Get-ChildItem "HKU:\$sid" -ErrorAction SilentlyContinue) {
			$profileLoaded = $true
		} else {
			$profileLoaded = $false
		}
		
		Write-Output "$sid `t $profilePath `t $profileLoaded"
		
		# Load the key if necessary
		if ($profileLoaded) {
			$userKeyPath = "HKU:\$sid"
		} else {
			$userKeyPath = "HKLM:\TempHive_$sid"
			& reg.exe load "HKLM\TempHive_$sid" "$profilePath\ntuser.dat"
		}
		
		# DO SOMETHING WITH $USERKEYPATH HERE.
		
		if (!$profileLoaded) {
			& reg.exe unload "HKLM\TempHive_$sid"
		}
		
	}
}

#reg load 

#New-ItemProperty -Path "HKU:\Environment\foobar" -Name "NoAutoUpdate" -PropertyType "REG_DWORD" -Value "1" `
#-Force


Remove-PSDrive -Name HKU