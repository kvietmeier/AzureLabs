### Check for an active session - or prompt login
# I'm using this to work out some kinks in a function to login 
# to my Azure Account

### Here for safety - comment/uncomment as desired
#return

### Get my functions and credentials
# Credentials  (stored outside the repo)
. '..\..\Certs\resources.ps1'

# Functions (In this repo)
. '.\FunctionLibrary.ps1'

# Imported from "FunctionLibrary.ps1"
# Are we connected to Azure with the corredt SubID?
Check-Login

Write-Host "==================================="
Write-Host "Checking if $SubID is logged in"
Write-Host "==================================="

