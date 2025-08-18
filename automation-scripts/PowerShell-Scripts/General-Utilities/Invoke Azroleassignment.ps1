<#
.SYNOPSIS
    Invoke Azroleassignment

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

<#
.SYNOPSIS
    We Enhanced Invoke Azroleassignment

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()]
function WE-Invoke-AzRoleAssignment {



$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
function WE-Invoke-AzRoleAssignment {

    #Region func New-AzRoleAssignment -ErrorAction Stop
    #Post Deployment Configuration #2
    $WEUsersGroupName = " Azure VM - Standard User"
    #Store the Object ID in a var
   ;  $WEObjectID = (Get-AzADGroup -SearchString $WEUsersGroupName).ID
    #Store the Resource Type of the VM
   ;  $vmtype = (Get-AzVM -ResourceGroupName $WEResourceGroupName -Name $WEVMName).Type
    #Create a new AZ Role Assignment at the Azure RBAC Level for that VM for Standard users
    New-AzRoleAssignment -ObjectId $WEObjectID -RoleDefinitionName 'Virtual Machine User Login' -ResourceGroupName $WEResourceGroupName -ResourceName $WEVMName -ResourceType $vmtype
    #endRegion func New-AzRoleAssignment -ErrorAction Stop
}




# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================