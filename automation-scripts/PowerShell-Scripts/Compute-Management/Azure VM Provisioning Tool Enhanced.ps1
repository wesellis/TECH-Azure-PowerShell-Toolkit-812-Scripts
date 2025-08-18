<#
.SYNOPSIS
    We Enhanced Azure Vm Provisioning Tool Enhanced

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

$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9\-]{1,62}[a-zA-Z0-9]$')][Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9\-]{1,62}[a-zA-Z0-9]$')][Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEVmName,
    [ValidateSet(" East US", " West US", " Central US", " East US 2", " West US 2")][string]$WELocation = " East US",
    [ValidateSet(" Standard_B1s", " Standard_B2s", " Standard_D2s_v3", " Standard_D4s_v3")][string]$WEVmSize = " Standard_B2s",
    [string]$WEAdminUsername = " azureadmin",
    [securestring]$WEAdminPassword,
    [hashtable]$WETags = @{},
    [switch]$WEEnableBootDiagnostics,
    [switch]$WEWhatIf,
    [switch]$WEForce
)


$modulePath = Join-Path -Path $WEPSScriptRoot -ChildPath " .." -AdditionalChildPath " modules", " AzureAutomationCommon"
if (Test-Path $modulePath) { Import-Module $modulePath -Force }

Show-Banner -ScriptName " Azure VM Provisioning Tool" -Description " Enterprise VM deployment with enhanced features"

try {
    Write-ProgressStep -StepNumber 1 -TotalSteps 6 -StepName " Validation" -Status " Checking Azure connection..."
    if (-not (Test-AzureConnection)) { throw " Azure connection validation failed" }
    
    Write-ProgressStep -StepNumber 2 -TotalSteps 6 -StepName " Resource Group" -Status " Validating resource group..."
    $rg = Invoke-AzureOperation -Operation { Get-AzResourceGroup -Name $WEResourceGroupName -ErrorAction Stop } -OperationName " Get Resource Group"
    Write-Log " ✓ Using resource group: $($rg.ResourceGroupName) in $($rg.Location)" -Level SUCCESS
    
    Write-ProgressStep -StepNumber 3 -TotalSteps 6 -StepName " Network Setup" -Status " Configuring network..."
    $vnet = Get-AzVirtualNetwork -ResourceGroupName $WEResourceGroupName -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $vnet -and -not $WEWhatIf) {
        $vnet = Invoke-AzureOperation -Operation {
            New-AzVirtualNetwork -ResourceGroupName $WEResourceGroupName -Name " $WEResourceGroupName-vnet" -Location $WELocation -AddressPrefix " 10.0.0.0/16"
        } -OperationName " Create Virtual Network"
    }
    
    Write-ProgressStep -StepNumber 4 -TotalSteps 6 -StepName " Security" -Status " Setting up security..."
    if (-not $WEAdminPassword) { $WEAdminPassword = Read-Host " Enter admin password" -AsSecureString }
    $credential = [PSCredential]::new($WEAdminUsername, $WEAdminPassword)
    
    Write-ProgressStep -StepNumber 5 -TotalSteps 6 -StepName " VM Creation" -Status " Creating virtual machine..."
    if ($WEWhatIf) {
        Write-Log " [WHAT-IF] Would create VM: $WEVmName ($WEVmSize) in $WEResourceGroupName" -Level INFO
    } else {
       ;  $defaultTags = @{ CreatedBy = " Azure-Automation-Scripts"; CreatedOn = (Get-Date).ToString(" yyyy-MM-dd"); Script = " Enhanced-VM-Tool" }
        foreach ($tag in $WETags.GetEnumerator()) { $defaultTags[$tag.Key] = $tag.Value }
        
        if (-not $WEForce) {
            $confirm = Read-Host " Create VM '$WEVmName'? (y/N)"
            if ($confirm -notmatch '^[Yy]') { Write-Log " Cancelled by user" -Level WARN; return }
        }
        
        $vmParams = @{
            ResourceGroupName = $WEResourceGroupName
            Name = $WEVmName
            Location = $WELocation
            Size = $WEVmSize
            Credential = $credential
            Image = " Win2022Datacenter"
            Tag = $defaultTags
        }
        
       ;  $vm = Invoke-AzureOperation -Operation { New-AzVM @vmParams } -OperationName " Create VM" -MaxRetries 2
        Write-Log " ✓ VM created successfully: $($vm.Name)" -Level SUCCESS
    }
    
    Write-ProgressStep -StepNumber 6 -TotalSteps 6 -StepName " Complete" -Status " Finalizing..."
    Write-Progress -Activity " VM Provisioning" -Completed
    Write-Log " VM provisioning completed at $(Get-Date)" -Level SUCCESS
    
} catch {
    Write-Progress -Activity " VM Provisioning" -Completed
    Write-Log " VM provisioning failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    throw
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================