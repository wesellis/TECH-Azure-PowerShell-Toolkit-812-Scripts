<#
.SYNOPSIS
    Store Job Details

.DESCRIPTION
    Store Job Details operation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$properties = $details.properties
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
$properties = $details.properties
$properties
$storageAccountName = $properties["Target Storage Account Name" ]
$storageAccountName
$containerName = $properties["Config Blob Container Name" ]
$containerName
$templateBlobURI = $properties["Template Blob Uri" ]
$templateBlobURI
$Templatename = $templateBlobURI -split (" /" );
$Templatename = $Templatename[4]
$Templatename\n