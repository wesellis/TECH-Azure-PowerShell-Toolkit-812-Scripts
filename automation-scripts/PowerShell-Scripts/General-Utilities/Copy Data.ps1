#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Copy Data

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
    We Enhanced Copy Data

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


Invoke-WebRequest -Uri "${env:contentUri}" -OutFile " ${env:csvFileName}"


$ctx = New-AzStorageContext -StorageAccountName " ${Env:storageAccountName}" -StorageAccountKey " ${Env:storageAccountKey}"

New-AzStorageContainer -Context $ctx -Name " ${env:containerName}" -Verbose


$params = @{
    File = " ${env:csvFileName}"
    Context = $ctx
    Blob = " ${env:csvFileName}"
    Container = " ${Env:containerName}"
    StandardBlobTier = "Hot"
}
Set-AzStorageBlobContent @params


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
