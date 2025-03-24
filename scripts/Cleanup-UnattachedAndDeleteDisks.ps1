###===========================================================================================###
###
###  Unattach and delete managed disks
###    - This script assumes 32 drives with a specififc name
###    - Usage: .\DetachAndDeleteDisks.ps1 -ResourceGroup <ResourceGroupName> -VMName <VMName>
###
###===========================================================================================###


param (
    [string]$ResourceGroup,
    [string]$VMName
)

# Validate input
if (-not $ResourceGroup -or -not $VMName) {
    Write-Host "Usage: .\DetachAndDeleteDisks.ps1 -ResourceGroup <ResourceGroupName> -VMName <VMName>"
    exit
}

# Loop through disks 01 to 32
for ($i = 1; $i -le 32; $i++) {
    $diskName = "premiumssdtesting{0:D2}-karlv" -f $i

    # Get VM
    $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $VMName -ErrorAction SilentlyContinue

    if ($vm) {
        # Check if disk is attached
        $disk = $vm.StorageProfile.DataDisks | Where-Object { $_.Name -eq $diskName }
        
        if ($disk) {
            Write-Host "Detaching disk: $diskName from VM: $VMName"
            
            # Remove the disk from VM
            Remove-AzVMDataDisk -VM $vm -Name $diskName
            Update-AzVM -ResourceGroupName $ResourceGroup -VM $vm

            # Delete the disk
            Write-Host "Deleting disk: $diskName"
            Remove-AzDisk -ResourceGroupName $ResourceGroup -DiskName $diskName -Force
        } else {
            Write-Host "Disk $diskName not found on VM: $VMName"
        }
    } else {
        Write-Host "VM $VMName not found in Resource Group $ResourceGroup"
        exit
    }
}

Write-Host "All specified disks processed."
