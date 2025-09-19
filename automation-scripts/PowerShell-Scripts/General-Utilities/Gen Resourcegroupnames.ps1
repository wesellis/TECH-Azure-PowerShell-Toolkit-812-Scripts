#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Gen Resourcegroupnames

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Gen Resourcegroupnames

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#
This script will generate the resource group names for deployment and check for prereqs

If specified, the prereq and the sample resource group name will be the same - this is required by some samples, but should not be the default



[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [string] $WEResourceGroupNamePrefix = " azdo" ,
    [string] $sampleFolder
)

#region Functions


$settingsFilePath = " $sampleFolder\prereqs\.settings.json"

if(Test-Path " $settingsFilePath" ){
    Write-WELog " Found settings file... $settingsFilePath" " INFO"
    $settings = Get-Content -Path " $settingsFilePath" -Raw | ConvertFrom-Json
    Write-Information $settings
}


if($settings.psobject.Members.Name -contains " PrereqResourceGroupNameSuffix" ){
    $WEPrereqResourceGroupNameSuffix = $settings.PrereqResourceGroupNameSuffix
}
else{
   ;  $WEPrereqResourceGroupNameSuffix = " -prereqs" # by default we will deploy to a separate resource group - it's a more thorough test on resourceIds
}

; 
$resourceGroupName = " $WEResourceGroupNamePrefix-$(New-Guid)"
Write-WELog " ##vso[task.setvariable variable=resourceGroup.name]$resourceGroupName" " INFO"
Write-WELog " ##vso[task.setvariable variable=prereq.resourceGroup.name]$resourceGroupName$WEPrereqResourceGroupNameSuffix" " INFO"



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
