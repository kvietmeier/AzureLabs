<#
Code to Map some network drives on my laptop using the SA Key
Docs:
  https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/remove-psdrive
  https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/new-psdrive
#>

return

#$StorageAccount = kv82579msix01
#$ShareName      = msixpkgs
#$KerbKey = "VXfFRncTdhzarSjGqoRSrbsxjLz7ziyaVkwuYPcdyu+Gpqnf7CzSvXT2tsXGwkHyfF6b/RFmXJ3VlPwMVJ/rSw=="

<####
     Mount MSIX Package Share
####>
$connectTestResult = Test-NetConnection -ComputerName kv82579msix01.file.core.windows.net -Port 445
if ($connectTestResult.TcpTestSucceeded) {
    # Save the password so the drive will persist on reboot
    cmd.exe /C "cmdkey /add:`"kv82579msix01.file.core.windows.net`" /user:`"Azure\kv82579msix01`" /pass:`"VXfFRncTdhzarSjGqoRSrbsxjLz7ziyaVkwuYPcdyu+Gpqnf7CzSvXT2tsXGwkHyfF6b/RFmXJ3VlPwMVJ/rSw==`""
    # Mount the drive
    New-PSDrive -Name P -PSProvider FileSystem -Root "\\kv82579msix01.file.core.windows.net\msixpkgs"
} else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}

<####
     Mount MSIX VHD Share
####>
$connectTestResult = Test-NetConnection -ComputerName kv82579msix01.file.core.windows.net -Port 445
if ($connectTestResult.TcpTestSucceeded) {
    # Save the password so the drive will persist on reboot
    cmd.exe /C "cmdkey /add:`"kv82579msix01.file.core.windows.net`" /user:`"Azure\kv82579msix01`" /pass:`"VXfFRncTdhzarSjGqoRSrbsxjLz7ziyaVkwuYPcdyu+Gpqnf7CzSvXT2tsXGwkHyfF6b/RFmXJ3VlPwMVJ/rSw==`""
    # Mount the drive
    New-PSDrive -Name N -PSProvider FileSystem -Root "\\kv82579msix01.file.core.windows.net\vhdshare"
} else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}

### Get rid of them - 
Remove-PSDrive -Name M
Remove-PSDrive -Name N