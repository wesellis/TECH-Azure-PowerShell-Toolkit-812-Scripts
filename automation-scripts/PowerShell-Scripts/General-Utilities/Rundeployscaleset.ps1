<#
.SYNOPSIS
    We Enhanced Rundeployscaleset

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

$args=@{
    'scalesetDNSPrefix'='s'+[System.Guid]::NewGuid().toString();
    'newStorageAccountName'=[System.Guid]::NewGuid().toString().Replace('-','').Substring(1,24);
    'resourceGroupName'='ssrg1';
    'location'='northeurope';
    'scaleSetName'='windowscustom';
    'scaleSetVMSize'='Standard_DS1';
    'newStorageAccountType'='Premium_LRS';
}

.\deployscaleset.ps1 @args 


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================