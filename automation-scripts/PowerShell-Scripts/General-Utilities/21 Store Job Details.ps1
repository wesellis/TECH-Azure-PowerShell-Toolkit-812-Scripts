<#
.SYNOPSIS
    We Enhanced 21  Store Job Details

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

$properties = $details.properties



$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

$properties = $details.properties
$properties

$storageAccountName = $properties[" Target Storage Account Name"]
$storageAccountName

$containerName = $properties[" Config Blob Container Name"]
$containerName

$templateBlobURI = $properties[" Template Blob Uri"]
$templateBlobURI


$WETemplatename = $templateBlobURI -split (" /"); 
$WETemplatename = $WETemplatename[4]
$WETemplatename



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================