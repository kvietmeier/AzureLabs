<# 
###====================================================================================###
    CreateAzureFileShare.ps1                                                        
    Created By: Karl Vietmeier                                                      
                                                                                    
    Create a FileShare - by generating a random name with a 4 digit random number   
    "Get-Random" creates a random number                                            
                                                                                    
###====================================================================================###
#>

### Here for safety - comment/uncomment as desired
return

# Stop on first error
$ErrorActionPreference = "stop"

# Run from the location of the script $PSscriptroot only works when run as a script
Set-Location $PSscriptroot
#Set-Location ../AzureLabs/scripts

### Get my functions and credentials
# Credentials  (stored outside the repo)
. '..\..\Certs\resources.ps1'

# Functions (In this repo)
. '.\FunctionLibrary.ps1'

# Imported from "FunctionLibrary.ps1"
# Are we connected to Azure with the corredt SubID?
Check-Login


### Storage Account SKUs - 
# Standard_LRS      - Locally-redundant storage.
# Standard_ZRS      - Zone-redundant storage.
# Standard_GRS      - Geo-redundant storage.
# Standard_RAGRS    - Read access geo-redundant storage.
# Premium_LRS       - Premium locally-redundant storage.
# Premium_ZRS       - Premium zone-redundant storage.
# Standard_GZRS     - Geo-redundant zone-redundant storage.
# Standard_RAGZRS   - Read access geo-redundant zone-redundant storage.


###====================   Set Some Variables  ======================###        
# These are sensitive - set here or in a separate file 
#$SubID = ""
#$SubName = ""

# Set as appropriate
$SizeInGB = "100"
$region = "westus2"
$AZResourceGroup = "WVDLandscape01"

# Create name with random 4 digit number.
$RandomID       = $(Get-Random -Minimum 1000 -Maximum 2000)
$StorageAcct    = "kv82579-$RandomID"

# For FSLogix - use the same sharename
$AZFileshare = "profiles"

# SKUs - Choose what you need
$SKUname = "Standard_LRS"

# Create the Account
$AZStorageAcct = New-AzStorageAccount `
    -ResourceGroupName $AZResourceGroup `
    -Name $StorageAcct `
    -SkuName $SKUname `
    -Location $region `
    -Kind StorageV2 `
    #-EnableLargeFileShare

# Create the Share
New-AzRmStorageShare `
    -ResourceGroupName $AZResourceGroup `
    -StorageAccountName $AZStorageAcct.StorageAccountName `
    -Name $AZFileshare `
    -QuotaGiB $SizeInGB | Out-Null


# Tell us it was created:
Write-Host "Created Storage Account: $($AZStorageAcct.StorageAccountName)"


###=================  Remove Account  ================###        
#Remove-AzStorageAccount `
#    -ResourceGroupName $AZResourceGroup `
#    -AccountName $AZStorageAcct.StorageAccountName

