###====================================================================================###
<#   
  FileName: InstallAndConfigureWSLinVM.ps1
  Created By: Karl Vietmeier
    
  Description:
   Install/Enable WSL in an Image

   
#>
###====================================================================================###
### Here for safety - comment/uncomment as desired
return

# Enable the feature
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# For WSL 2 - need HyperV bits
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

