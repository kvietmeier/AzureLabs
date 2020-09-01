###=========================================================================================###
<# 
 Optimize User Profile Settings - .bat/cmd syntax
  
 Not sure where this came from - there is no "HKLM:\Temp\... branch in the registry
 Good set of optimizations though.

 ying NTUSER.dat 
 #>
###=========================================================================================###
return 

Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -Value 0 -Type DWord -force
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v MaxMonitors /t REG_DWORD /d 4 /f