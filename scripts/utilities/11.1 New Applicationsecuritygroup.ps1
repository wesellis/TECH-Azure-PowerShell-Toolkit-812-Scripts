#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Create application security group

.DESCRIPTION
    Create Azure application security group


    Author: Wes Ellis (wes@wesellis.com)
#>
$ErrorActionPreference = "Stop";
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
$newAzApplicationSecurityGroupSplat = @{
    ResourceGroupName = "MyResourceGroup"
    Name = "MyApplicationSecurityGroup"
    Location = "West US"
    Tag = ''
}
New-AzApplicationSecurityGroup -ErrorAction Stop @newAzApplicationSecurityGroupSplat

