#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Invoke Azapplicationsecuritygroup

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
function Invoke-AzApplicationSecurityGroup {
}
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Invoke-AzApplicationSecurityGroup {
    #region func-New-AzApplicationSecurityGroup -ErrorAction Stop
    #Creating the Application Security Group
    $ASGName = -join (" $VMName" , "_ASG1" )
$newAzApplicationSecurityGroupSplat = @{
        ResourceGroupName = " $ResourceGroupName"
        Name              = " $ASGName"
        Location          = " $LocationName"
        Tag               = $Tags
    }
$ASG = New-AzApplicationSecurityGroup -ErrorAction Stop @newAzApplicationSecurityGroupSplat
    #endRegion func New-AzApplicationSecurityGroup -ErrorAction Stop
}


