###====================================================================================###
<#   
  FileName: VMsByRegion.ps1
  Created By: Karl Vietmeier
    
  Description:
  Parse list of VM sizes by region and generate a .csv file

#>
###====================================================================================###

<#
.SYNOPSIS
Will use the az cli to find VM sizes by region

.DESCRIPTION
Long description

.EXAMPLE
An example

.NOTES
General notes
#>

### Here for safety - comment/uncomment as desired
#return

# Stop on first error
$ErrorActionPreference = "stop"

###====================================================================================###
###     Auth Code - remove/modify as needed
###====================================================================================###
# Run from the location of the script
Set-Location $PSscriptroot

### Get my functions and credentials
# Credentials  (stored outside the repo)
. 'C:\.info\miscinfo.ps1'

# Functions (In this repo)
. '.\FunctionLibrary.ps1'

# Imported from "FunctionLibrary.ps1"
# Are we connected to Azure with the corredt SubID?
#Check-Login


###====================================================================================###
###      Script
###====================================================================================###

<### Need to get the regions
  Access the results using Object method calls
  $Regions.DisplayName
  $Regions.Name
  $Regions.RegionalDisplayName
#>
#$Regions = az account list-locations -o table
#$Regions = az account list-locations

# We just need the reference name
$Regions = az account list-locations --query '[].[name]' -o tsv

# Do we have the right number?
#$NumRegions= $Regions.count
#$NumRegions.GetType()
#$Regions.GetType()
#Write-Host "Found $NumRegions Regions"

<# # ForEach (item In collection) {code block}
ForEach ($Region in $Regions) {

    if($Region -notmatch '.*stage') {
      Write-Output "$($Region)"
    }
    # See  if we can lookup the Display Name - doesn't work
    #az account list-locations --query "[?name=='$Item'].[DisplayName]" -o tsv
}
#>
$num_regions = 0

# Loop through the list of regions and check for v5s in each valid region
ForEach ($Region in $Regions) {
  if($Region -notmatch '.*stage') {
    Get-AzVMSize -Location $Region -ErrorAction SilentlyContinue | Where-Object { $_.Name -Match 'Standard_D.*s.*v5' }
    #Get-AzVMSize -Location $Region -ErrorAction SilentlyContinue | Where-Object { $_.Name -Match 'Standard_D.*s.*v5' } | ConvertTo-Csv -NoTypeInformation
    if ($?) {
      $num_regions++
      # Will remove these later - need to figure out how to label treguion output in CSV file
      Write-Host ""
      Write-Host "####======= $Region ========####"
    }
  }
}

# How many regions are there really? Does this match the complete list?
Write-Host "Checked $num_regions Regions"