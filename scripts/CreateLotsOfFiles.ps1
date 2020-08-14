###====================================================================================###
###  CreateLotsOfFiles.ps1                                                             ###
###    Created By: Karl Vietmeier                                                      ###
###                                                                                    ###
###  Description:                                                                      ###
###   Create an arbitrary number of files of any size to generate fileIO               ###
###                                                                                    ###
###====================================================================================###

# Create a bunch of files with randomn data.
### Variables
$fileSize = "2048"
$tempDir = "c:\temp"
$numFiles = "10000"

# Check for $tempDir

# Create a fixed size byte array for later use.  make it the required file size.
$bytearray = New-Object byte[] $fileSize

# Create and start a stopwatch object to measure how long it all takes.
$stopwatch = [Diagnostics.Stopwatch]::StartNew()

# Create a CSRNG object
$RNGObject = New-Object Security.Cryptography.RNGCryptoServiceProvider

# Set up a loop to run 50000 times
0..$numFiles | Foreach-Object {

    # create a file stream handle with a name format 'filennnnn'
    $stream = New-Object System.IO.FileStream("$tempDir\file$("{0:D5}" -f $_)"), Create

    # and a stream writer handle
    $writer = New-Object System.IO.BinaryWriter($stream)

    # Fill our array from the CSRNG
    $RNGObject.GetNonZeroBytes($bytearray)

    # Append to the current file
    $writer.write($bytearray)

    # Close the stream
    $stream.close()

}

# How long did it all take?
$stopwatch.stop()
$stopwatch