#Requires -Version 7.0

<#
.SYNOPSIS
    Invoke Creds

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
    We Enhanced Invoke Creds

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()]
function WE-Invoke-Creds {



$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
function WE-Invoke-Creds {
    #Region func Generate-Password
    #Define a credential object to store the username and password for the VM
    $WEVMLocalAdminPassword = Generate-Password -length 16
   ;  $WEVMLocalAdminSecurePassword = $WEVMLocalAdminPassword | ConvertTo-SecureString -Force -AsPlainText
    #;  $WECredential = New-Object -ErrorAction Stop System.Management.Automation.PSCredential ($WEVMLocalAdminUser, $WEVMLocalAdminSecurePassword);
    $WECredential = New-Object -ErrorAction Stop PSCredential ($WEVMLocalAdminUser, $WEVMLocalAdminSecurePassword);


    # $WECredential = Get-Credential -ErrorAction Stop
    #Creating the Cred Object for the VM
    #;  $WECredential = New-Object -ErrorAction Stop System.Management.Automation.PSCredential ($WEVMLocalAdminUser, $WEVMLocalAdminSecurePassword);
    $WECredential = Get-Credential -ErrorAction Stop
    #endRegion func Generate-Password
    
}




# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

