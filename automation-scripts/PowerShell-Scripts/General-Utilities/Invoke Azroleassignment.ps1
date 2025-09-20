<#
.SYNOPSIS
    Invoke Azroleassignment

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
function Invoke-AzRoleAssignment {
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Invoke-AzRoleAssignment {
    #Region func New-AzRoleAssignment -ErrorAction Stop
    #Post Deployment Configuration #2
    $UsersGroupName = "Azure VM - Standard User"
    #Store the Object ID in a var
$ObjectID = (Get-AzADGroup -SearchString $UsersGroupName).ID
    #Store the Resource Type of the VM
$vmtype = (Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName).Type
    #Create a new AZ Role Assignment at the Azure RBAC Level for that VM for Standard users
    New-AzRoleAssignment -ObjectId $ObjectID -RoleDefinitionName 'Virtual Machine User Login' -ResourceGroupName $ResourceGroupName -ResourceName $VMName -ResourceType $vmtype
    #endRegion func New-AzRoleAssignment -ErrorAction Stop
}

