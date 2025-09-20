#Requires -Version 7.0

<#`n.SYNOPSIS
    Upload VHD to managed disk

.DESCRIPTION
    Upload VHD file to Azure managed disk using AzCopy


    Author: Wes Ellis (wes@wesellis.com)
#>
$ErrorActionPreference = "Stop"
# Example: Upload VHD to managed disk
# AzCopy.exe copy "c:\somewhere\mydisk.vhd" $diskSas.AccessSAS --blob-type PageBlob

