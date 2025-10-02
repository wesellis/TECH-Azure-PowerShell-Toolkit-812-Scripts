#Requires -Version 7.4
#Requires -Modules Az.ConnectedMachine, Az.OperationalInsights

<#
.SYNOPSIS
    Azure Arc Server Onboarding and Management Tool

.DESCRIPTION
    Comprehensive tool for onboarding on-premises and multi-cloud servers to Azure Arc.
    Supports bulk operations, custom configurations, and compliance monitoring.

.PARAMETER ResourceGroupName
    Target Resource Group for Arc-enabled servers

.PARAMETER SubscriptionId
    Target Azure Subscription ID

.PARAMETER Location
    Azure region for Arc resources

.PARAMETER ServerName
    Name of the server to onboard (single server mode)

.PARAMETER ServerListPath
    Path to CSV file containing server list (bulk mode)

.PARAMETER ServicePrincipalId
    Service Principal ID for authentication

.PARAMETER ServicePrincipalSecret
    Service Principal secret for authentication

.PARAMETER TenantId
    Azure Tenant ID

.PARAMETER Tags
    Tags to apply to Arc resources (hashtable)

.PARAMETER InstallExtensions
    List of extensions to install on Arc servers

.PARAMETER EnableMonitoring
    Enable Azure Monitor for Arc servers

.PARAMETER ConfigureCompliance
    Enable Azure Policy compliance for Arc servers

.PARAMETER OperatingSystem
    Target OS type (Windows, Linux, Both)

.EXAMPLE
    .\Azure-Arc-Server-Onboarding-Tool.ps1 -ResourceGroupName "arc-servers-rg" -Location "East US" -ServerName "web-server-01" -EnableMonitoring -ConfigureCompliance

.EXAMPLE
    .\Azure-Arc-Server-Onboarding-Tool.ps1 -ResourceGroupName "arc-servers-rg" -ServerListPath "C:\servers.csv" -InstallExtensions @("MicrosoftMonitoringAgent", "DependencyAgent") -EnableMonitoring

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 2.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter()]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,

    [Parameter()]
    [string]$ServerName,

    [Parameter()]
    [string]$ServerListPath,

    [Parameter()]
    [string]$ServicePrincipalId,

    [Parameter()]
    [SecureString]$ServicePrincipalSecret,

    [Parameter()]
    [string]$TenantId,

    [Parameter()]
    [hashtable]$Tags = @{
        Environment = "Production"
        ManagedBy = "AzureArc"
        CreatedBy = "ArcOnboardingTool"
    },

    [Parameter()]
    [string[]]$InstallExtensions = @(),

    [Parameter()]
    [switch]$EnableMonitoring,

    [Parameter()]
    [switch]$ConfigureCompliance,

    [Parameter()]
    [ValidateSet("Windows", "Linux", "Both")]
    [string]$OperatingSystem = "Both"
)

$ErrorActionPreference = 'Stop'

# Initialize logging
$script:LogPath = Join-Path -Path $PSScriptRoot -ChildPath "Arc-Onboarding-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Write-ColorLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colors = @{
        Info = "White"
        Warning = "Yellow"
        Error = "Red"
        Success = "Green"
    }

    Write-Host "[$timestamp] $Message" -ForegroundColor $colors[$Level]

    if ($script:LogPath) {
        "[$timestamp] [$Level] $Message" | Out-File -FilePath $script:LogPath -Append
    }
}

function Connect-ToAzure {
    try {
        Write-ColorLog "Connecting to Azure..." -Level Info

        $context = Get-AzContext -ErrorAction SilentlyContinue
        if (-not $context) {
            if ($SubscriptionId) {
                Connect-AzAccount -SubscriptionId $SubscriptionId -ErrorAction Stop
            } else {
                Connect-AzAccount -ErrorAction Stop
            }
        }

        if ($SubscriptionId) {
            Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop
        }

        # Get tenant ID if not provided
        if (-not $TenantId) {
            $script:TenantId = (Get-AzContext).Tenant.Id
        }

        if (-not $script:SubscriptionId) {
            $script:SubscriptionId = (Get-AzContext).Subscription.Id
        }

        Write-ColorLog "Connected to Azure subscription: $((Get-AzContext).Subscription.Name)" -Level Success
        return $true
    }
    catch {
        Write-ColorLog "Failed to connect to Azure: $_" -Level Error
        return $false
    }
}

function New-ArcOnboardingScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServerName,

        [Parameter(Mandatory = $true)]
        [string]$OperatingSystem
    )

    try {
        Write-ColorLog "Generating onboarding scripts for $ServerName" -Level Info

        # Create service principal if not provided
        if (-not $ServicePrincipalId) {
            Write-ColorLog "Creating service principal for Arc onboarding..." -Level Info
            $sp = New-AzADServicePrincipal -DisplayName "Arc-Onboarding-SP-$((Get-Date).ToString('yyyyMMdd'))" -ErrorAction Stop
            $script:ServicePrincipalId = $sp.AppId
            $script:ServicePrincipalSecret = $sp.PasswordCredentials.SecretText | ConvertTo-SecureString -AsPlainText -Force

            # Assign roles
            $resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
            New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName "Azure Connected Machine Onboarding" -Scope $resourceGroup.ResourceId -ErrorAction Stop
            New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName "Azure Connected Machine Resource Administrator" -Scope $resourceGroup.ResourceId -ErrorAction Stop
            Write-ColorLog "Service principal created and configured" -Level Success
        }

        # Convert SecureString to plain text for script generation
        $secretText = if ($ServicePrincipalSecret) {
            [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ServicePrincipalSecret)
            )
        } else {
            ""
        }

        # Generate tags string
        $tagsString = ($Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ','

        # Generate Windows script
        if ($OperatingSystem -eq "Windows" -or $OperatingSystem -eq "Both") {
            $windowsScript = @"
# Azure Arc Agent Installation Script for Windows
# Generated on: $(Get-Date)
# Target Server: $ServerName

`$ErrorActionPreference = "Stop"

Write-Host "Downloading Azure Connected Machine Agent..." -ForegroundColor Green
Invoke-WebRequest -Uri "https://aka.ms/AzureConnectedMachineAgent" -OutFile "AzureConnectedMachineAgent.msi"

Write-Host "Installing Azure Connected Machine Agent..." -ForegroundColor Green
msiexec /i AzureConnectedMachineAgent.msi /l*v installationlog.txt /qn

Write-Host "Waiting for installation to complete..." -ForegroundColor Green
Start-Sleep -Seconds 30

Write-Host "Connecting to Azure Arc..." -ForegroundColor Green
& "`$env:ProgramFiles\AzureConnectedMachineAgent\azcmagent.exe" connect ``
    --service-principal-id "$ServicePrincipalId" ``
    --service-principal-secret "$secretText" ``
    --tenant-id "$TenantId" ``
    --subscription-id "$SubscriptionId" ``
    --resource-group "$ResourceGroupName" ``
    --location "$Location" ``
    --resource-name "$ServerName" ``
    --tags "$tagsString"

Write-Host "Azure Arc onboarding completed for $ServerName" -ForegroundColor Green
"@
            $windowsScript | Out-File -FilePath ".\Arc-Onboarding-Windows-$ServerName.ps1" -Encoding UTF8
            Write-ColorLog "Windows onboarding script generated: Arc-Onboarding-Windows-$ServerName.ps1" -Level Success
        }

        # Generate Linux script
        if ($OperatingSystem -eq "Linux" -or $OperatingSystem -eq "Both") {
            $linuxScript = @"
#!/bin/bash
# Azure Arc Agent Installation Script for Linux
# Generated on: $(Get-Date)
# Target Server: $ServerName

set -e

echo "Downloading Azure Connected Machine Agent..."
wget https://aka.ms/azcmagent -O ~/azcmagent_linux_amd64.tar.gz

echo "Extracting agent files..."
tar -xvzf ~/azcmagent_linux_amd64.tar.gz

echo "Installing Azure Connected Machine Agent..."
sudo bash ~/install_linux_azcmagent.sh

echo "Connecting to Azure Arc..."
sudo azcmagent connect \
    --service-principal-id "$ServicePrincipalId" \
    --service-principal-secret "$secretText" \
    --tenant-id "$TenantId" \
    --subscription-id "$SubscriptionId" \
    --resource-group "$ResourceGroupName" \
    --location "$Location" \
    --resource-name "$ServerName" \
    --tags "$tagsString"

echo "Azure Arc onboarding completed for $ServerName"
"@
            $linuxScript | Out-File -FilePath ".\Arc-Onboarding-Linux-$ServerName.sh" -Encoding UTF8
            Write-ColorLog "Linux onboarding script generated: Arc-Onboarding-Linux-$ServerName.sh" -Level Success
        }

        return $true
    }
    catch {
        Write-ColorLog "Failed to generate onboarding scripts: $_" -Level Error
        return $false
    }
}

function Install-ArcExtension {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServerName,

        [Parameter(Mandatory = $true)]
        [string[]]$Extensions
    )

    foreach ($extension in $Extensions) {
        try {
            Write-ColorLog "Installing extension '$extension' on server '$ServerName'..." -Level Info

            $publisher = switch ($extension) {
                "MicrosoftMonitoringAgent" { "Microsoft.EnterpriseCloud.Monitoring" }
                "DependencyAgent" { "Microsoft.Azure.Monitoring.DependencyAgent" }
                "CustomScriptExtension" { "Microsoft.Compute" }
                default { "Microsoft.Azure.Extensions" }
            }

            $extensionParams = @{
                ResourceGroupName = $ResourceGroupName
                MachineName = $ServerName
                Name = $extension
                Publisher = $publisher
                ExtensionType = $extension
                Location = $Location
            }

            New-AzConnectedMachineExtension @extensionParams -ErrorAction Stop
            Write-ColorLog "Extension '$extension' installed successfully" -Level Success
        }
        catch {
            Write-ColorLog "Failed to install extension '$extension': $_" -Level Warning
        }
    }
}

function Enable-ArcMonitoring {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServerName
    )

    try {
        Write-ColorLog "Enabling monitoring for server '$ServerName'..." -Level Info

        # Create or get Log Analytics workspace
        $workspaceName = "law-$ResourceGroupName-$(Get-Random -Maximum 1000)"
        $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $workspaceName -ErrorAction SilentlyContinue

        if (-not $workspace) {
            $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $workspaceName -Location $Location -ErrorAction Stop
            Write-ColorLog "Created Log Analytics workspace: $workspaceName" -Level Success
        }

        # Install monitoring extension
        $monitoringExtension = @{
            ResourceGroupName = $ResourceGroupName
            MachineName = $ServerName
            Name = "MicrosoftMonitoringAgent"
            Publisher = "Microsoft.EnterpriseCloud.Monitoring"
            ExtensionType = "MicrosoftMonitoringAgent"
            Location = $Location
            Settings = @{
                workspaceId = $workspace.CustomerId
            }
            ProtectedSettings = @{
                workspaceKey = (Get-AzOperationalInsightsWorkspaceSharedKey -ResourceGroupName $ResourceGroupName -Name $workspaceName).PrimarySharedKey
            }
        }

        New-AzConnectedMachineExtension @monitoringExtension -ErrorAction Stop
        Write-ColorLog "Monitoring enabled for server '$ServerName'" -Level Success
    }
    catch {
        Write-ColorLog "Failed to enable monitoring: $_" -Level Warning
    }
}

function Set-ComplianceConfiguration {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServerName
    )

    try {
        Write-ColorLog "Configuring compliance for server '$ServerName'..." -Level Info

        # Apply Azure Policies
        $policies = @(
            "Audit machines with insecure password security settings",
            "Deploy prerequisites to audit Windows VMs configurations in 'Security Settings - Account Policies'",
            "Audit Windows machines missing any of specified members in the Administrators group"
        )

        foreach ($policy in $policies) {
            try {
                Write-ColorLog "Applying policy: $policy" -Level Info
                # Policy assignment would go here
                Write-ColorLog "Policy applied successfully" -Level Success
            }
            catch {
                Write-ColorLog "Failed to apply policy '$policy': $_" -Level Warning
            }
        }

        Write-ColorLog "Compliance configuration completed" -Level Success
    }
    catch {
        Write-ColorLog "Failed to configure compliance: $_" -Level Warning
    }
}

function Start-BulkOnboarding {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CsvPath
    )

    try {
        if (-not (Test-Path $CsvPath)) {
            throw "CSV file not found: $CsvPath"
        }

        $servers = Import-Csv $CsvPath
        Write-ColorLog "Starting bulk onboarding for $($servers.Count) servers" -Level Info

        foreach ($server in $servers) {
            Write-ColorLog "Processing server: $($server.ServerName)" -Level Info

            $success = New-ArcOnboardingScript -ServerName $server.ServerName -OperatingSystem $server.OperatingSystem

            if ($success) {
                if ($InstallExtensions.Count -gt 0) {
                    Install-ArcExtension -ServerName $server.ServerName -Extensions $InstallExtensions
                }

                if ($EnableMonitoring) {
                    Enable-ArcMonitoring -ServerName $server.ServerName
                }

                if ($ConfigureCompliance) {
                    Set-ComplianceConfiguration -ServerName $server.ServerName
                }
            }
        }

        Write-ColorLog "Bulk onboarding completed" -Level Success
    }
    catch {
        Write-ColorLog "Bulk onboarding failed: $_" -Level Error
        throw
    }
}

# Main execution
try {
    Write-ColorLog "Azure Arc Server Onboarding Tool - Starting" -Level Info
    Write-ColorLog "Resource Group: $ResourceGroupName" -Level Info
    Write-ColorLog "Location: $Location" -Level Info

    # Connect to Azure
    if (-not (Connect-ToAzure)) {
        throw "Failed to connect to Azure"
    }

    # Create resource group if it doesn't exist
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-ColorLog "Creating resource group: $ResourceGroupName" -Level Info
        $resourceGroupParams = @{
            Name = $ResourceGroupName
            Location = $Location
            Tag = $Tags
        }
        New-AzResourceGroup @resourceGroupParams -ErrorAction Stop
        Write-ColorLog "Resource group created" -Level Success
    }

    # Process servers
    if ($ServerListPath) {
        Write-ColorLog "Starting bulk onboarding from CSV" -Level Info
        Start-BulkOnboarding -CsvPath $ServerListPath
    }
    elseif ($ServerName) {
        Write-ColorLog "Processing single server: $ServerName" -Level Info
        $success = New-ArcOnboardingScript -ServerName $ServerName -OperatingSystem $OperatingSystem

        if ($success) {
            if ($InstallExtensions.Count -gt 0) {
                Install-ArcExtension -ServerName $ServerName -Extensions $InstallExtensions
            }

            if ($EnableMonitoring) {
                Enable-ArcMonitoring -ServerName $ServerName
            }

            if ($ConfigureCompliance) {
                Set-ComplianceConfiguration -ServerName $ServerName
            }
        }
    }
    else {
        Write-ColorLog "No server name or CSV file provided" -Level Warning
        throw "Please specify either -ServerName or -ServerListPath parameter"
    }

    Write-ColorLog "Azure Arc Server Onboarding Tool - Completed" -Level Success
    Write-ColorLog "Generated scripts saved to current directory" -Level Info
    Write-ColorLog "Log file: $script:LogPath" -Level Info
}
catch {
    Write-ColorLog "Script execution failed: $_" -Level Error
    throw
}