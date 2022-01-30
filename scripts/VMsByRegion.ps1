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

# Run from the location of the script
Set-Location $PSscriptroot

###====================================================================================###
###     Auth Code - remove/modify as needed
###     These commands require you to be authenticated to Azure session
###     
###     Connect-AzAccount
###
###     The above won't work if MFA is enabled
###====================================================================================###

### Get my functions and credentials
# Login Credentials  (stored outside the repo)
. 'C:\.info\miscinfo.ps1'


###====================================================================================###
###      Script
###====================================================================================###

#$Regions = az account list-locations -o table
#$Regions = az account list-locations
# We just need the reference name
#$Regions = az account list-locations --query '[].[name]' -o tsv
<### Need to get the regions
  Access the results using Object method calls
  $Regions.DisplayName
  $Regions.Name
  $Regions.RegionalDisplayName
#>

$Regions = Get-AzLocation | Select-Object Location
#$Regions = Get-AzLocation | Select-Object Location
#$Regions.Location

# Do we have the right number?
$NumRegions= $Regions.Length
#$NumRegions.GetType()
#$Regions.GetType()
#Write-Host "Found $NumRegions Regions"

#$foobar = ($Regions.PSObject.Properties).Value

$num_regions = 0

<# THIS WORKS
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

#ForEach-Object ($Region in $Regions) {
ForEach ($Region in Get-AzLocation | Select-Object Location)
{

  Write-Host $Region
  # Includes AMD instances
  #Get-AzVMSize -Location $Region -ErrorAction SilentlyContinue | Where-Object { $_.Name -Match 'Standard_D.*s.*v5' }
  Get-AzVMSize -Location $Region 

  # This will exclude AMD instances
  #Get-AzVMSize -Location $Region.Location -ErrorAction SilentlyContinue | Where-Object { $Region.Location -Match 'Standard_D.[^a]*s.*v5'}
    

  # Output in csv format
  #Get-AzVMSize -Location $Region -ErrorAction SilentlyContinue | Where-Object { $_.Name -Match 'Standard_D.*s.*v5' } | ConvertTo-Csv -NoTypeInformation
    
  $num_regions++
  # Will remove these later - need to figure out how to label region output in CSV file
  Write-Host ""
  Write-Host "####======= $Region ========####"
} 


# How many regions are there really? Does this match the complete list?
Write-Host "Checked $num_regions Regions"