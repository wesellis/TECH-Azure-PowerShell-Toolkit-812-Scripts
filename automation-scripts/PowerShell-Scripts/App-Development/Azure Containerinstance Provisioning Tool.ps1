<#
.SYNOPSIS
    Azure Containerinstance Provisioning Tool

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
    We Enhanced Azure Containerinstance Provisioning Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEContainerGroupName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEImage,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    [string]$WEOsType = " Linux" ,
    [double]$WECpu = 1.0,
    [double]$WEMemory = 1.5,
    [array]$WEPorts = @(80),
    [hashtable]$WEEnvironmentVariables = @{},
    [string]$WERestartPolicy = " Always"
)

Write-WELog " Provisioning Container Instance: $WEContainerGroupName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"
Write-WELog " Location: $WELocation" " INFO"
Write-WELog " Container Image: $WEImage" " INFO"
Write-WELog " OS Type: $WEOsType" " INFO"
Write-WELog " CPU: $WECpu cores" " INFO"
Write-WELog " Memory: $WEMemory GB" " INFO"
Write-WELog " Ports: $($WEPorts -join ', ')" " INFO"
Write-WELog " Restart Policy: $WERestartPolicy" " INFO"


$WEPortObjects = @()
foreach ($WEPort in $WEPorts) {
    $WEPortObjects = $WEPortObjects + New-AzContainerInstancePortObject -Port $WEPort -Protocol TCP
}


$WEEnvVarObjects = @()
if ($WEEnvironmentVariables.Count -gt 0) {
    Write-WELog " `nEnvironment Variables:" " INFO"
    foreach ($WEEnvVar in $WEEnvironmentVariables.GetEnumerator()) {
        Write-WELog "  $($WEEnvVar.Key): $($WEEnvVar.Value)" " INFO"
        $WEEnvVarObjects = $WEEnvVarObjects + New-AzContainerInstanceEnvironmentVariableObject -Name $WEEnvVar.Key -Value $WEEnvVar.Value
    }
}

; 
$WEContainer = New-AzContainerInstanceObject -ErrorAction Stop `
    -Name $WEContainerGroupName `
    -Image $WEImage `
    -RequestCpu $WECpu `
    -RequestMemoryInGb $WEMemory `
    -Port $WEPortObjects

if ($WEEnvVarObjects.Count -gt 0) {
    $WEContainer.EnvironmentVariable = $WEEnvVarObjects
}


Write-WELog " `nCreating Container Instance..." " INFO" ; 
$WEContainerGroup = New-AzContainerGroup -ErrorAction Stop `
    -ResourceGroupName $WEResourceGroupName `
    -Name $WEContainerGroupName `
    -Location $WELocation `
    -Container $WEContainer `
    -OsType $WEOsType `
    -RestartPolicy $WERestartPolicy `
    -IpAddressType Public

Write-WELog " `nContainer Instance $WEContainerGroupName provisioned successfully" " INFO"
Write-WELog " Public IP Address: $($WEContainerGroup.IpAddress)" " INFO"
Write-WELog " FQDN: $($WEContainerGroup.Fqdn)" " INFO"
Write-WELog " Provisioning State: $($WEContainerGroup.ProvisioningState)" " INFO"


Write-WELog " `nContainer Status:" " INFO"
foreach ($WEContainerStatus in $WEContainerGroup.Container) {
    Write-WELog "  Container: $($WEContainerStatus.Name)" " INFO"
    Write-WELog "  State: $($WEContainerStatus.InstanceView.CurrentState.State)" " INFO"
    Write-WELog "  Restart Count: $($WEContainerStatus.InstanceView.RestartCount)" " INFO"
}

if ($WEContainerGroup.IpAddress -and $WEPorts) {
    Write-WELog " `nAccess URLs:" " INFO"
    foreach ($WEPort in $WEPorts) {
        Write-WELog "  http://$($WEContainerGroup.IpAddress):$WEPort" " INFO"
    }
}

Write-WELog " `nContainer Instance provisioning completed at $(Get-Date)" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
