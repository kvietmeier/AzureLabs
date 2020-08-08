### Check for an active session - or prompt login
# I'm using this to work out some kinks in a function to login 
# to my Azure Account

# Don't run accidently.
return

# Get my functions and credentials
#. "..\..\Certs\resources.ps1"
. 'C:\Users\kavietme\Documents\OneDrive - Microsoft\WindowsPowerShell\resources.ps1'

# Where is the script running from?
$PSScriptRoot

# There is a Login function in the included file.
#Login

# Need the SubID (get it from an external file - above - or set it here)
#$SubID = <subscription ID>

Write-Host "==================================="
Write-Host "Checking if $SubID is logged in"
Write-Host "==================================="

# Not working correctly - 
<# function Login($SubID)
{
    Write-Host "$SubID"
    $context = Get-AzContext
    Get-AzContext

    Write-Host "$context"

    #if (!$context -or ($context.Subscription.Id -ne $SubID)) 
    if ($context.Subscription.Id -ne $SubID) 
    {
        # Save your creds
        Write-Host "$SubID"
        $creds = get-credential
        Connect-AzAccount -Credential $creds -Subscription $SubID
    } 
    else 
    {
        Write-Host "SubscriptionId '$SubID' already connected"
    }
}

Login #>


### Login Creds - an insecure hack
# - In secrets.ps1
#$AIAuser
#$AIApassword

#$securepasswd = ConvertTo-SecureString $AIApassword -AsPlainText -Force
#$cred = New-Object System.Management.Automation.PSCredential ($AIAuser, $securepasswd)
#Connect-AzAccount -Credential $cred -Subscription $SubID

<# 
$context = Get-AzContext

if (!$context -or ($context.Subscription.Id -ne $SubID)) 
{
    # Save your creds
    $creds = get-credential
    Connect-AzAccount -Credential $cred -Subscription $SubID
} 
else 
{
    Write-Host "SubscriptionId '$SubID' already connected"
} #>