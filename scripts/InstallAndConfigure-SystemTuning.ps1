###====================================================================================###
<# 

  Name: InstallAndConfigure-SystemTuning.ps1 
  Created By: Karl Vietmeier  
                                
  Description:                   
  Tuning parameters for network/storage performance
  https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/rds_vdi-recommendations-1909

#>
###====================================================================================###

### Here for safety - comment/uncomment as desired
return

###-------- Tuning Parameters

# DisableBandwidthThrottling
# HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters\DisableBandwidthThrottling
# The default is 0
# Consider setting this value to 1

New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters" `
    -Name "DisableBandwidthThrottling" -PropertyType DWORD -Value 1 `
    -Force    

# FileInfoCacheEntriesMax
# HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters\FileInfoCacheEntriesMax
# The default is 64
# Try increasing this value to 1024

New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters" `
    -Name "FileInfoCacheEntriesMax" -PropertyType DWORD -Value 1024 `
    -Force    

# DirectoryCacheEntriesMax
# HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters\DirectoryCacheEntriesMax
# The default is 16
# Consider increasing this value to 1024

New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters" `
    -Name "DirectoryCacheEntriesMax" -PropertyType DWORD -Value 1024 `
    -Force    

# FileNotFoundCacheEntriesMax
# HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters\FileNotFoundCacheEntriesMax
# The default is 128
# Consider increasing this value to 2048

New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters" `
    -Name "FileNotFoundCacheEntriesMax" -PropertyType DWORD -Value 2048 `
    -Force    

# DormantFileLimit
# HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters\DormantFileLimit
# The default is 1023
# Consider reducing this value to 256

New-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters" `
    -Name "DormantFileLimit" -PropertyType DWORD -Value 256 `
    -Force    

###---- End Tuning