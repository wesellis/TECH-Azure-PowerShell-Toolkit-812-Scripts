#Requires -Version 7.0

<#`n.SYNOPSIS
    Invoke Creds

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
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
$VMLocalAdminSecurePassword = $VMLocalAdminPassword | Read-Host -AsSecureString -Prompt "Enter secure value"
    #;  $Credential = New-Object -ErrorAction Stop System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
    $Credential = New-Object -ErrorAction Stop PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
    # $Credential = Get-Credential -ErrorAction Stop
    #Creating the Cred Object for the VM
    #;  $Credential = New-Object -ErrorAction Stop System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
    $Credential = Get-Credential -ErrorAction Stop
    #endRegion func Generate-Password
}
