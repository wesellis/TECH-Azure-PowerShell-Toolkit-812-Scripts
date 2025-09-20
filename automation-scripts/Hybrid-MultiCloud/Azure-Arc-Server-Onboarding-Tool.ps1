<#
.SYNOPSIS
    Azure Arc Server Onboarding and Management Tool - Enterprise Edition

.DESCRIPTION
    Tool for onboarding on-premises and multi-cloud servers to Azure Arc.
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
    .\Azure-Arc-Server-Onboarding-Tool.ps1 -ResourceGroupName "arc-servers-rg" -Location "East US" -ServerName "web-server-01" -EnableMonitoring -ConfigureCompliance
    .\Azure-Arc-Server-Onboarding-Tool.ps1 -ResourceGroupName "arc-servers-rg" -ServerListPath "C:\servers.csv" -InstallExtensions @("MicrosoftMonitoringAgent", "DependencyAgent") -EnableMonitoring
    Author: Wesley Ellis
    Version: 2.0
    Requires: PowerShell 7.0+, Az.ConnectedMachine module
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,
    [Parameter(Mandatory = $true)]
    [string]$Location,
    [Parameter(Mandatory = $false)]
    [string]$ServerName,
    [Parameter(Mandatory = $false)]
    [string]$ServerListPath,
    [Parameter(Mandatory = $false)]
    [string]$ServicePrincipalId,
    [Parameter(Mandatory = $false)]
    [SecureString]$ServicePrincipalSecret,
    [Parameter(Mandatory = $false)]
    [string]$TenantId,
    [Parameter(Mandatory = $false)]
    [hashtable]$Tags = @{
        Environment = "Production"
        ManagedBy = "AzureArc"
        CreatedBy = "ArcOnboardingTool"
    },
    [Parameter(Mandatory = $false)]
    [string[]]$InstallExtensions = @(),
    [Parameter(Mandatory = $false)]
    [switch]$EnableMonitoring,
    [Parameter(Mandatory = $false)]
    [switch]$ConfigureCompliance,
    [Parameter(Mandatory = $false)]
    [ValidateSet("Windows", "Linux", "Both")]
    [string]$OperatingSystem = "Both"
)
# Import required modules
try {
    Import-Module Az.Accounts -Force -ErrorAction Stop
    Import-Module Az.Resources -Force -ErrorAction Stop
    Import-Module Az.ConnectedMachine -Force -ErrorAction Stop
    Write-Host "Successfully imported required Azure modules"
} catch {
    Write-Error "Failed to import required modules: $($_.Exception.Message)"
    throw
}
# Enhanced logging function
function Write-Verbose
    param(
        [string]$Message,
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
    # Log to file if specified
    if ($script:LogPath) {
        "[$timestamp] [$Level] $Message" | Out-File -FilePath $script:LogPath -Append
    }
}
# Azure Authentication
function Connect-ToAzure {
    try {
        if ($SubscriptionId) {
            Connect-AzAccount -Subscription $SubscriptionId
        } else {
            Connect-AzAccount
        }
        $context = Get-AzContext -ErrorAction Stop
        Write-Verbose
        return $true
    } catch {
        Write-Verbose
        return $false
    }
}
# Generate Arc onboarding script
function New-ArcOnboardingScript -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$ServerName,
        [string]$OperatingSystem
    )
    try {
        # Generate service principal if not provided
        if (-not $ServicePrincipalId) {
            Write-Verbose
            $sp = New-AzADServicePrincipal -DisplayName "Arc-Onboarding-SP-$((Get-Date).ToString('yyyyMMdd'))"
            $ServicePrincipalId = $sp.AppId
            $ServicePrincipalSecret = $sp.PasswordCredentials.SecretText | ConvertTo-SecureString -AsPlainText -Force
            # Assign required permissions
            $resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName
            New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName "Azure Connected Machine Onboarding" -Scope $resourceGroup.ResourceId
            New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName "Azure Connected Machine Resource Administrator" -Scope $resourceGroup.ResourceId
            Write-Verbose
        }
        # Generate onboarding command based on OS
        $secretText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ServicePrincipalSecret))
        if ($OperatingSystem -eq "Windows" -or $OperatingSystem -eq "Both") {
            $windowsScript = @"
# Azure Arc Windows Onboarding Script
# Download and install Azure Connected Machine Agent
Invoke-WebRequest -Uri "https://aka.ms/AzureConnectedMachineAgent" -OutFile "AzureConnectedMachineAgent.msi"
msiexec /i AzureConnectedMachineAgent.msi /l*v installationlog.txt /qn
# Configure and connect to Azure Arc
& "\$env:ProgramFiles\AzureConnectedMachineAgent\azcmagent.exe" connect ``
    --service-principal-id "$ServicePrincipalId" ``
    --service-principal-secret "$secretText" ``
    --tenant-id "$TenantId" ``
    --subscription-id "$SubscriptionId" ``
    --resource-group "$ResourceGroupName" ``
    --location "$Location" ``
    --resource-name "$ServerName" ``
    --tags "$(($Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ',')"
Write-Host "Azure Arc onboarding completed for $ServerName"
"@
            $windowsScript | Out-File -FilePath ".\Arc-Onboarding-Windows-$ServerName.ps1" -Encoding UTF8
            Write-Verbose
        }
        if ($OperatingSystem -eq "Linux" -or $OperatingSystem -eq "Both") {
            $linuxScript = @"
#!/bin/bash
# Azure Arc Linux Onboarding Script
# Download and install Azure Connected Machine Agent
wget https://aka.ms/azcmagent -O ~/azcmagent_linux_amd64.tar.gz
tar -xvzf ~/azcmagent_linux_amd64.tar.gz
sudo bash ~/install_linux_azcmagent.sh
# Configure and connect to Azure Arc
sudo azcmagent connect \
    --service-principal-id "$ServicePrincipalId" \
    --service-principal-secret "$secretText" \
    --tenant-id "$TenantId" \
    --subscription-id "$SubscriptionId" \
    --resource-group "$ResourceGroupName" \
    --location "$Location" \
    --resource-name "$ServerName" \
    --tags "$(($Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ',')"
echo "Azure Arc onboarding completed for $ServerName"
"@
            $linuxScript | Out-File -FilePath ".\Arc-Onboarding-Linux-$ServerName.sh" -Encoding UTF8
            Write-Verbose
        }
    } catch {
        Write-Verbose
        return $false
    }
    return $true
}
# Install Arc extensions
function Install-ArcExtension {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$ServerName,
        [string[]]$Extensions
    )
    foreach ($extension in $Extensions) {
        try {
            Write-Verbose
                    "DependencyAgent" { "Microsoft.Azure.Monitoring.DependencyAgent" }
                    "CustomScriptExtension" { "Microsoft.Compute" }
                    default { "Microsoft.Azure.Extensions" }
                }
                Type = $extension
            }
            New-AzConnectedMachineExtension -ErrorAction Stop @extensionParams
            Write-Verbose
        } catch {
            Write-Verbose
        }
    }
}
# Configure monitoring for Arc servers
function Enable-ArcMonitoring {
    param([string]$ServerName)
    try {
        Write-Verbose
        # Create Log Analytics workspace if it doesn't exist
        $workspaceName = "law-$ResourceGroupName-$(Get-Random -Maximum 1000)"
        $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $workspaceName -ErrorAction SilentlyContinue
        if (-not $workspace) {
            $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $workspaceName -Location $Location
            Write-Verbose
        }
        # Install monitoring agent extension
        $monitoringExtension = @{
            ResourceGroupName = $ResourceGroupName
            MachineName = $ServerName
            Name = "MicrosoftMonitoringAgent"
            Publisher = "Microsoft.EnterpriseCloud.Monitoring"
            Type = "MicrosoftMonitoringAgent"
            Settings = @{
                workspaceId = $workspace.CustomerId
            }
            ProtectedSettings = @{
                workspaceKey = (Get-AzOperationalInsightsWorkspaceSharedKey -ResourceGroupName $ResourceGroupName -Name $workspaceName).PrimarySharedKey
            }
        }
        New-AzConnectedMachineExtension -ErrorAction Stop @monitoringExtension
        Write-Verbose
    } catch {
        Write-Verbose
    }
}
# Configure compliance policies
function Set-ComplianceConfiguration -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$ServerName)
    try {
        Write-Verbose
        # Common compliance policies for Arc servers
        $policies = @(
            "Audit machines with insecure password security settings",
            "Deploy prerequisites to audit Windows VMs configurations in 'Security Settings - Account Policies'",
            "Audit Windows machines missing any of specified members in the Administrators group"
        )
        foreach ($policy in $policies) {
            try {
                # This would typically assign built-in policies - implementation depends on specific compliance requirements
                Write-Verbose
            } catch {
                Write-Verbose
            }
        }
        Write-Verbose
    } catch {
        Write-Verbose
    }
}
# Process bulk server onboarding
function Start-BulkOnboarding {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$CsvPath)
    try {
        if (-not (Test-Path $CsvPath)) {
            throw "CSV file not found: $CsvPath"
        }
        $servers = Import-Csv $CsvPath
        Write-Verbose
        foreach ($server in $servers) {
            Write-Verbose
            # Generate onboarding script
            $success = New-ArcOnboardingScript -ServerName $server.ServerName -OperatingSystem $server.OperatingSystem
            if ($success) {
                # Install extensions if specified
                if ($InstallExtensions.Count -gt 0) {
                    Install-ArcExtension -ServerName $server.ServerName -Extensions $InstallExtensions
                }
                # Configure monitoring if enabled
                if ($EnableMonitoring) {
                    Enable-ArcMonitoring -ServerName $server.ServerName
                }
                # Configure compliance if enabled
                if ($ConfigureCompliance) {
                    Set-ComplianceConfiguration -ServerName $server.ServerName
                }
            }
        }
        Write-Verbose
    } catch {
        Write-Verbose
    }
}
# Main execution
try {
    Write-Verbose
    Write-Verbose
    Write-Verbose
    # Connect to Azure
    if (-not (Connect-ToAzure)) {
        throw
    }
    # Ensure resource group exists
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-Verbose
        $resourcegroupSplat = @{
    Name = $ResourceGroupName
    Location = $Location
    Tag = $Tags
}
New-AzResourceGroup @resourcegroupSplat
        Write-Verbose
    }
    # Process based on mode (single server or bulk)
    if ($ServerListPath) {
        Write-Verbose
        Start-BulkOnboarding -CsvPath $ServerListPath
    } elseif ($ServerName) {
        Write-Verbose
        # Generate onboarding script
        $success = New-ArcOnboardingScript -ServerName $ServerName -OperatingSystem $OperatingSystem
        if ($success) {
            # Install extensions if specified
            if ($InstallExtensions.Count -gt 0) {
                Install-ArcExtension -ServerName $ServerName -Extensions $InstallExtensions
            }
            # Configure monitoring if enabled
            if ($EnableMonitoring) {
                Enable-ArcMonitoring -ServerName $ServerName
            }
            # Configure compliance if enabled
            if ($ConfigureCompliance) {
                Set-ComplianceConfiguration -ServerName $ServerName
            }
        }
    } else {
        Write-Verbose
        throw
    }
    Write-Verbose
    Write-Verbose
    Write-Verbose
} catch {
    Write-Verbose
    throw
}

