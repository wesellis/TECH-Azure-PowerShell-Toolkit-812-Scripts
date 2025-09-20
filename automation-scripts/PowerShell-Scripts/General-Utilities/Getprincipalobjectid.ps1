#Requires -Version 7.0
#Requires -Module Az.Resources
    Getprincipalobjectid
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
<# Uncomment and run the following 2 lines of code if you are running the script locally and the AzureAD PowerShell module is not installed:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
$name = "<AAD_Username>"
$null = Connect-AzureAD
$output = (Get-AzAdUser -UserPrincipalName $name).Id
Write-Host "Azure AD principal object ID is: $output"

