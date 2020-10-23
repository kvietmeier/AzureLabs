###====================================================================================###
<#   
  FileName: InstallAndConfigureOneDrive.ps1
  Created By: Karl Vietmeier
    
  Description:
   Install OneDrive for WVD

   By Default One-drive installs for single users
   Download the latest OneDriveSetup.exe from Micrsoft's site:
   https://products.office.com/en-us/onedrive/download
   
   Place in a temp folder - NOTE:  Change the folder path to your copy of OneDriveSetup.exe
   OneDriveSetup also uninstalls. 
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

