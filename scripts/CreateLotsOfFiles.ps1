
<###====================================================================================###
  CreateLotsOfFiles.ps1                                                             
    Created By: Karl Vietmeier                                                      
                                                                                   
  Description:                                                                     
   Create an arbitrary number of files of any size to generate fileIO             
   Will crank CPU up to 100%                                                    
###====================================================================================###>

# Create a bunch of files with randomn data.
### Variables
$FileSize = "2048"
$TargetDir = "c:\temp"
$NumFiles = "10000"

Get-Location


# Check for $TargetDir
if (!(Test-Path $TargetDir))
{
  Write-Host "Creating C:\temp"
  New-Item -ItemType Directory -Force -Path $TargetDir
  $removeDir = "True" # We created it, so remove it afterward
}

# Create a fixed size byte array for later use.  make it the required file size.
$ByteArray = New-Object byte[] $FileSize

# Create and start a StopWatch object to measure how long it all takes.
$StopWatch = [Diagnostics.StopWatch]::StartNew()

# Create a CSRNG object
$RNGObject = New-Object Security.Cryptography.RNGCryptoServiceProvider

# Set up a loop to run 50000 times
0..$NumFiles | Foreach-Object {

    # create a file stream handle with a name format 'filennnnn'
    $stream = New-Object System.IO.FileStream("$TargetDir\file$("{0:D5}" -f $_)"), Create

    # and a stream writer handle
    $writer = New-Object System.IO.BinaryWriter($stream)

    # Fill our array from the CSRNG
    $RNGObject.GetNonZeroBytes($ByteArray)

    # Append to the current file
    $writer.write($ByteArray)

    # Close the stream
    $stream.close()

}

# Remove the directory we created
if ($removeDir = "True")
{
  Write-Host "Removing C:\temp"
  Set-Location "C:\"
  Remove-Item -Recurse $TargetDir
}


# How long did it all take?
$StopWatch.stop()
$StopWatch