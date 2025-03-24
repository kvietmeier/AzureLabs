# Set your resource group and VM name
$resourceGroup = "karlv-voctesting"
$vmName = "PremiumSSDTesting-01"

# Loop through disks 01 to 32
for ($i = 1; $i -le 32; $i++) {
    # Format disk name with leading zeros
    $diskName = "premiumssdtesting{0:D2}-karlv" -f $i

    # Get VM
    $vm = Get-AzVM -ResourceGroupName $resourceGroup -Name $vmName

    # Check if disk exists in VM
    $disk = $vm.StorageProfile.DataDisks | Where-Object { $_.Name -eq $diskName }
    
    if ($disk) {
        Write-Host "Detaching disk: $diskName from VM: $vmName"
        
        # Remove the disk from VM
        Remove-AzVMDataDisk -VM $vm -Name $diskName
        Update-AzVM -ResourceGroupName $resourceGroup -VM $vm

        # Delete the managed disk
        Write-Host "Deleting disk: $diskName"
        Remove-AzDisk -ResourceGroupName $resourceGroup -DiskName $diskName -Force
    } else {
        Write-Host "Disk $diskName not found on VM: $vmName"
    }
}

Write-Host "All specified disks processed."
