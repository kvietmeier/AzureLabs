### Script to convert a VM to use an NVME controller
#
#   From:
#    https://learn.microsoft.com/en-us/azure/virtual-machines/enable-nvme-faqs
#

# Vars - 
$subscription_id = $Env:ARM_SUBSCRIPTION_ID  # Set as env variable elsewhere
$resource_group_name = 'your-resource-group-name'
$vm_name = 'your-vm-name'
$os_disk_name = (Get-AzVM -ResourceGroupName $resource_group_name -Name $vm_name).StorageProfile.OsDisk.Name

# To change up
$disk_controller_change_to = 'NVMe'
$vm_size_change_to = 'Standard_E2bds_v5'  # E#bds_v5 are the nvme enabled instances


# Use direct API call to update the VM supported controllers to include nvme
$uri = 'https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Compute/disks/{2}?api-version=2022-07-02' -f $subscription_id, $resource_group_name, $os_disk_name

$access_token = (Get-AzAccessToken).Token

$auth_header = @{

  'Content-Type'  = 'application/json'

  'Authorization' = 'Bearer ' + $access_token
                                                    }
$body = @'
          {
"properties": {

"supportedCapabilities": {

  "diskControllerTypes":"SCSI, NVMe"

    }
    }
    }
'@

$get_supported_capabilities = (Invoke-WebRequest -uri $uri -Method Get -Headers $auth_header | ConvertFrom-Json).properties.supportedCapabilities

# Stop and deallocate the VM
Stop-AzVM -ResourceGroupName $resource_group_name -Name $vm_name -Force

# Add NVMe supported capabilities to the OS disk
$Update_Supported_Capabilities = (Invoke-WebRequest -uri $uri -Method PATCH -body $body -Headers $auth_header | ConvertFrom-Json)

# Get VM configuration
$vm = Get-AzVM -ResourceGroupName $resource_group_name -Name $vm_name

# Build a configuration with updated VM size
$vm.HardwareProfile.VmSize = $vm_size_change_to

# Build a configuration with updated disk controller type
$vm.StorageProfile.DiskControllerType = $disk_controller_change_to

# Change the VM size and VM’s disk controller type
Update-AzVM -ResourceGroupName $resource_group_name -VM $vm

# Start the VM
Start-AzVM -ResourceGroupName $resource_group_name -Name $vm_name