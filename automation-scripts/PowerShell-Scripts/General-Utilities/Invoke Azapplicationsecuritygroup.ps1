<#
.SYNOPSIS
    Invoke Azapplicationsecuritygroup

.DESCRIPTION
    Azure automation
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
    #Region func New-AzApplicationSecurityGroup -ErrorAction Stop
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

