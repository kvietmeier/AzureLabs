###====================================================================================###
###  <scriptname>.ps1                                                                  ###
###    Created By: Karl Vietmeier                                                      ###
###                                                                                    ###
###  Description                                                                       ###
###                                                                                    ###
###                                                                                    ###
###====================================================================================###

### Here for safety - comment/uncomment as desired
return

### Get my functions and credentials
# Credentials  (stored outside the repo)
. '..\..\Certs\resources.ps1'

# Functions (In this repo)
. '.\FunctionLibrary.ps1'

# Imported from "FunctionLibrary.ps1"
# Are we connected to Azure with the corredt SubID?
Check-Login

