<#
.SYNOPSIS
    Invoke Creds

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
function Invoke-Creds {
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Invoke-Creds {
    #Region func Generate-Password
    #Define a credential object to store the username and password for the VM
    $VMLocalAdminPassword = Generate-Password -length 16
$VMLocalAdminSecurePassword = $VMLocalAdminPassword | ConvertTo-SecureString -Force -AsPlainText
    #;  $Credential = New-Object -ErrorAction Stop System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
    $Credential = New-Object -ErrorAction Stop PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
    # $Credential = Get-Credential -ErrorAction Stop
    #Creating the Cred Object for the VM
    #;  $Credential = New-Object -ErrorAction Stop System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
    $Credential = Get-Credential -ErrorAction Stop
    #endRegion func Generate-Password
}\n