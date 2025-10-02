#Requires -Version 7.4
#Requires -Modules Az.RecoveryServices

<#
.SYNOPSIS
    Store Job Details

.DESCRIPTION
    Store Job Details operation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [PSObject]$JobDetails
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

$properties = $JobDetails.properties
$properties

if ($properties.ContainsKey("Target Storage Account Name")) {
    $storageAccountName = $properties["Target Storage Account Name"]
    $storageAccountName
}

if ($properties.ContainsKey("Config Blob Container Name")) {
    $containerName = $properties["Config Blob Container Name"]
    $containerName
}

if ($properties.ContainsKey("Template Blob Uri")) {
    $templateBlobURI = $properties["Template Blob Uri"]
    $templateBlobURI
    $Templatename = $templateBlobURI -split "/"
    $Templatename = $Templatename[4]
    $Templatename
}

[PSCustomObject]@{
    StorageAccountName = $storageAccountName
    ContainerName = $containerName
    TemplateBlobURI = $templateBlobURI
    TemplateName = $Templatename
}