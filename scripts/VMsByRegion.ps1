###====================================================================================###
<#   
  FileName: VMsByRegion.ps1
  Created By: Karl Vietmeier

#>
###====================================================================================###

<#
.SYNOPSIS
Will use the PowerShell commands to find VM sizes by region

.DESCRIPTION
Parse list of regions and list Intel v5 instance sizes found.


.NOTES
Needed outcome:
A .csv/excel file with the output of the VMSizes command for each region that has the requested size

NOTE - Good excerise for learning arrays and text manipluation.

Usage:
These commands require you to be authenticated to Azure session

  Connect-AzAccount

The above won't work if MFA is enabled

#>

###====================================================================================###
###      Script
###====================================================================================###
### Here for safety - comment/uncomment as desired
#return

# Stop on first error
$ErrorActionPreference = "stop"

# Run from the location of the script
Set-Location $PSscriptroot

# There are differences between the output of the az cli command vs the PowerShell cmd
#    - Ther az commonamnd includes Global Geography names, staging regions 
#    - and euap preview regions

<# ### Use the az cli command
* Creates Object Array
$Regions = az account list-locations -o table
$Regions = az account list-locations
* Just the reference name
$Regions = az account list-locations --query '[].[name]' -o tsv
#>

<# ### Use the PS command
* Just the reference name
$Regions = Get-AzLocation | Select-Object Location

* Creates Object Array
#$Regions = Get-AzLocation

* Access the results using Object method calls
$Regions.DisplayName
$Regions.Name
$Regions.RegionalDisplayName

* Example
$Regions.Name
#>

<#  Do we have the right number?
$NumRegions= $Regions.Length
$NumRegions.GetType()
$Regions.GetType()
Write-Host "Found $NumRegions Regions"
#>

$num_regions = 0

<# THIS WORKS using the az CLI but is a bit messy
# Loop through the list of regions and check for v5s in each valid region
ForEach ($Region in $Regions) {
  if($Region -notmatch '.*stage') {
    
    # Includes AMD instances
    #Get-AzVMSize -Location $Region -ErrorAction SilentlyContinue | Where-Object { $_.Name -Match 'Standard_D.*s.*v5' }

    # This will exclude AMD instances
    Get-AzVMSize -Location $Region -ErrorAction SilentlyContinue | Where-Object { $_.Name -Match 'Standard_D.[^a]*s.*v5'}
    
    # Output in csv format
    #Get-AzVMSize -Location $Region -ErrorAction SilentlyContinue | Where-Object { $_.Name -Match 'Standard_D.*s.*v5' } | ConvertTo-Csv -NoTypeInformation
    
    if ($?) {
      $num_regions++
      # Will remove these later - need to figure out how to label region output in CSV file
      Write-Host ""
      Write-Host "####======= $Region ========####"
    }
  }
} 
#>

# Will just get the Location but we might want to use other properties
#ForEach ($Region in Get-AzLocation | Select-Object Location)

### Using the Get-AzLocation command - probably a more correct way to do it and a bit cleaner
# Grab the whole PSObject - 
ForEach ($Region in Get-AzLocation)
{

  #Write-Host "Region checked is - $($Region.Location)"
  # Includes AMD instances
  #Get-AzVMSize -Location $Region.Location -ErrorAction SilentlyContinue | Where-Object { $_.Name -Match 'Standard_D.*s.*v5' }

  # This will exclude AMD instances
  Get-AzVMSize -Location $Region.Location -ErrorAction SilentlyContinue | Where-Object { $_.Name -Match 'Standard_D.[^a]*s.*v5'}

  # Output in csv format
  #Get-AzVMSize -Location $Region -ErrorAction SilentlyContinue | Where-Object { $_.Name -Match 'Standard_D.[^a]*s.*v5' } | ConvertTo-Csv -NoTypeInformation
    
  # Exclude non-legit regions
  if ($?) {
      $num_regions++
      # Will remove these later - need to figure out how to label region output in CSV file
      Write-Host ""
      Write-Host "####======= $($Region.DisplayName) ========####"
  } else {
    # In here for info - pull out later
    Write-Host ""
    Write-Host "$($Region.DisplayName) Get-AzVMSize failed"
    Write-Host ""
  }
  
} 


# How many regions are there really? Does this match the complete list?
Write-Host "Command succeed on $num_regions Regions out of $($Regions.Count)"