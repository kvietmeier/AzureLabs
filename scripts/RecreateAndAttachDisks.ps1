param (
    [string]$ResourceGroup,
    [string]$VMName,
    [int]$DiskSizeGB = 128,  # Default size for new disks
    [string]$DiskType = "Premium_LRS" # Default disk type
)

# Validate input
if (-not $ResourceGroup -or -not $VMName) {
    Write-Host "Usage: .\RecreateAndAttachDisks.ps1 -ResourceGroup <ResourceGroupName> -VMName <VMName> [-DiskSizeGB <Size>] [-DiskType <Type>]"
    exit 1
}

# Get VM
$vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $VMName -ErrorAction SilentlyContinue

if (-not $vm) {
    Write-Host "VM $VMName not found in Resource Group $ResourceGroup"
    exit 1
}

# Get all attached disks
$attachedDisks = $vm.StorageProfile.DataDisks

# Track if VM needs update after detaching disks
$diskDetached = $false

# Step 1: Detach and Delete Disks
for ($i = 1; $i -le 32; $i++) {
    $diskName = "premiumssdtesting{0:D2}-karlv" -f $i

    # Check if the disk is attached to the VM
    $disk = $attachedDisks | Where-Object { $_.Name -eq $diskName }

    if ($disk) {
        Write-Host "Detaching disk: $diskName from VM: $VMName"
        Remove-AzVMDataDisk -VM $vm -Name $diskName | Out-Null
        $diskDetached = $true
    } else {
        Write-Host "Disk $diskName not found on VM: $VMName"
    }
}

# Update VM only if disks were detached
if ($diskDetached) {
    Update-AzVM -ResourceGroupName $ResourceGroup -VM $vm
    Write-Host "VM updated after disk detachments."
}

# Step 2: Delete Disks
for ($i = 1; $i -le 32; $i++) {
    $diskName = "premiumssdtesting{0:D2}-karlv" -f $i
    $diskExists = Get-AzDisk -ResourceGroupName $ResourceGroup -DiskName $diskName -ErrorAction SilentlyContinue

    if ($diskExists) {
        Write-Host "Deleting disk: $diskName"
        Remove-AzDisk -ResourceGroupName $ResourceGroup -DiskName $diskName -Force
    }
}

# Step 3: Recreate Disks
$createdDisks = @()
for ($i = 1; $i -le 32; $i++) {
    $diskName = "premiumssdtesting{0:D2}-karlv" -f $i

    Write-Host "Creating new disk: $diskName with size $DiskSizeGB GB and type $DiskType"

    $diskConfig = New-AzDiskConfig -Location (Get-AzResourceGroup -Name $ResourceGroup).Location `
                                   -CreateOption Empty `
                                   -DiskSizeGB $DiskSizeGB `
                                   -SkuName $DiskType

    $newDisk = New-AzDisk -ResourceGroupName $ResourceGroup -DiskName $diskName -Disk $diskConfig
    $createdDisks += $newDisk
}

# Step 4: Attach the New Disks to the VM
for ($disk in $createdDisks) {
    Write-Host "Attaching disk: $($disk.Name) to VM: $VMName"
    $vm = Add-AzVMDataDisk -VM $vm -Name $disk.Name -CreateOption Attach -ManagedDiskId $disk.Id -Lun ($createdDisks.IndexOf($disk))
}

# Step 5: Update the VM with the new disks
Update-AzVM -ResourceGroupName $ResourceGroup -VM $vm
Write-Host "All disks have been recreated and attached to VM $VMName successfully."
