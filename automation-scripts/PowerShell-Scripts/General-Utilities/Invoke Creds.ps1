<#
.SYNOPSIS
    We Enhanced Invoke Creds

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

function WE-Invoke-Creds {



$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

function WE-Invoke-Creds {
    #Region func Generate-Password
    #Define a credential object to store the username and password for the VM
    $WEVMLocalAdminPassword = Generate-Password -length 16
    $WEVMLocalAdminSecurePassword = $WEVMLocalAdminPassword | ConvertTo-SecureString -Force -AsPlainText
    #;  $WECredential = New-Object System.Management.Automation.PSCredential ($WEVMLocalAdminUser, $WEVMLocalAdminSecurePassword);
    $WECredential = New-Object PSCredential ($WEVMLocalAdminUser, $WEVMLocalAdminSecurePassword);


    # $WECredential = Get-Credential
    #Creating the Cred Object for the VM
    #;  $WECredential = New-Object System.Management.Automation.PSCredential ($WEVMLocalAdminUser, $WEVMLocalAdminSecurePassword);
    $WECredential = Get-Credential
    #endRegion func Generate-Password
    
}




# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================