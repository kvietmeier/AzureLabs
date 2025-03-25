param (
    [string]$ResourceGroup,
    [string]$VMName,
    [int]$DiskSizeGB = 128,  # Default disk size
    [string]$DiskType = "Premium_LRS" # Default disk type
)

# Validate input
if (-not $ResourceGroup -or -not $VMName) {
    Write-Host "Usage: .\ManageDisks.ps1 -ResourceGroup <ResourceGroupName> -VMName <VMName> [-DiskSizeGB <Size>] [-DiskType <Type>]"
    exit 1
}

# Ask user for action: Attach or Delete
$action = Read-Host "Do you want to (1) Detach & Delete or (2) Recreate & Attach disks? Enter 1 or 2"

if ($action -ne "1" -and $action -ne "2") {
    Write-Host "Invalid input. Please enter 1 to detach & delete or 2 to recreate & attach disks."
    exit 1
}

# Ask how many disks to manage
$DiskCount = Read-Host "Enter the number of disks to manage (1-32)"
if ($DiskCount -lt 1 -or $DiskCount -gt 32) {
    Write-Host "Invalid input. Please enter a number between 1 and 32."
    exit 1
}

# Get VM
$vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $VMName -ErrorAction SilentlyContinue

if (-not $vm) {
    Write-Host "VM $VMName not found in Resource Group $ResourceGroup"
    exit 1
}

if ($action -eq "1") {
    # --------------------- DETACH & DELETE DISKS ---------------------
    Write-Host "`nDetaching and deleting $DiskCount disks from VM: $VMName"
    
    $attachedDisks = $vm.StorageProfile.DataDisks
    $diskDetached = $false

    # Step 1: Detach disks
    for ($i = 1; $i -le $DiskCount; $i++) {
        $diskName = "premiumssdtesting{0:D2}-karlv" -f $i
        $disk = $attachedDisks | Where-Object { $_.Name -eq $diskName }

        if ($disk) {
            Write-Host "Detaching disk: $diskName"
            Remove-AzVMDataDisk -VM $vm -Name $diskName | Out-Null
            $diskDetached = $true
        } else {
            Write-Host "Disk $diskName not found on VM: $VMName"
        }
    }

    # Step 2: Update VM after detaching
    if ($diskDetached) {
        Update-AzVM -ResourceGroupName $ResourceGroup -VM $vm
        Write-Host "VM updated after disk detachments."
    }

    # Step 3: Delete Disks
    for ($i = 1; $i -le $DiskCount; $i++) {
        $diskName = "premiumssdtesting{0:D2}-karlv" -f $i
        $diskExists = Get-AzDisk -ResourceGroupName $ResourceGroup -DiskName $diskName -ErrorAction SilentlyContinue

        if ($diskExists) {
            Write-Host "Deleting disk: $diskName"
            Remove-AzDisk -ResourceGroupName $ResourceGroup -DiskName $diskName -Force
        }
    }

    Write-Host "All specified disks have been detached and deleted successfully."

} elseif ($action -eq "2") {
    # --------------------- RECREATE & ATTACH DISKS ---------------------
    Write-Host "`nRecreating and attaching $DiskCount disks to VM: $VMName"

    # Step 1: Recreate Disks
    $createdDisks = @()
    for ($i = 1; $i -le $DiskCount; $i++) {
        $diskName = "premiumssdtesting{0:D2}-karlv" -f $i

        Write-Host "Creating new disk: $diskName with size $DiskSizeGB GB and type $DiskType"

        $diskConfig = New-AzDiskConfig -Location (Get-AzResourceGroup -Name $ResourceGroup).Location `
                                       -CreateOption Empty `
                                       -DiskSizeGB $DiskSizeGB `
                                       -SkuName $DiskType

        $newDisk = New-AzDisk -ResourceGroupName $ResourceGroup -DiskName $diskName -Disk $diskConfig
        $createdDisks += $newDisk
    }

    # Step 2: Attach the New Disks to the VM
    for ($disk in $createdDisks) {
        Write-Host "Attaching disk: $($disk.Name) to VM: $VMName"
        $vm = Add-AzVMDataDisk -VM $vm -Name $disk.Name -CreateOption Attach -ManagedDiskId $disk.Id -Lun ($createdDisks.IndexOf($disk))
    }

    # Step 3: Update the VM with the new disks
    Update-AzVM -ResourceGroupName $ResourceGroup -VM $vm
    Write-Host "All $DiskCount disks have been recreated and attached to VM $VMName successfully."
}
