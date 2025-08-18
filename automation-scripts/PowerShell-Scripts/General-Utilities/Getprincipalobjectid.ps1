<#
.SYNOPSIS
    We Enhanced Getprincipalobjectid

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

﻿<# Uncomment and run the following 2 lines of code if you are running the script locally and the AzureAD PowerShell module is not installed:

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force




$name = "<AAD_Username>"

$null = Connect-AzureAD
; 
$output = (Get-AzAdUser -UserPrincipalName $name).Id
Write-WELog " Azure AD principal object ID is: $output" " INFO"

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================