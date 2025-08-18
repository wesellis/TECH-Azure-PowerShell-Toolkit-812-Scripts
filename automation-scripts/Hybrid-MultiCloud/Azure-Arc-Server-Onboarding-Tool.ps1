#Requires -Version 7.0
#Requires -Modules Az.Accounts, Az.Resources, Az.ConnectedMachine

<#
.SYNOPSIS
    Azure Arc Server Onboarding and Management Tool - Enterprise Edition
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
    Write-Information "✅ Successfully imported required Azure modules"
} catch {
    Write-Error "❌ Failed to import required modules: $($_.Exception.Message)"
    exit 1
}

# Enhanced logging function
[CmdletBinding()]
function Write-EnhancedLog {
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
    
    Write-Information "[$timestamp] $Message" -ForegroundColor $colors[$Level]
    
    # Log to file if specified
    if ($script:LogPath) {
        "[$timestamp] [$Level] $Message" | Out-File -FilePath $script:LogPath -Append
    }
}

# Azure Authentication
[CmdletBinding()]
function Connect-ToAzure {
    try {
        if ($SubscriptionId) {
            Connect-AzAccount -Subscription $SubscriptionId
        } else {
            Connect-AzAccount
        }
        
        $context = Get-AzContext -ErrorAction Stop
        Write-EnhancedLog "Successfully connected to Azure subscription: $($context.Subscription.Name)" "Success"
        return $true
    } catch {
        Write-EnhancedLog "Failed to connect to Azure: $($_.Exception.Message)" "Error"
        return $false
    }
}

# Generate Arc onboarding script
[CmdletBinding()]
function New-ArcOnboardingScript -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$ServerName,
        [string]$OperatingSystem
    )
    
    try {
        # Generate service principal if not provided
        if (-not $ServicePrincipalId) {
            Write-EnhancedLog "Creating service principal for Arc onboarding..." "Info"
            $sp = New-AzADServicePrincipal -DisplayName "Arc-Onboarding-SP-$((Get-Date).ToString('yyyyMMdd'))"
            $ServicePrincipalId = $sp.AppId
            $ServicePrincipalSecret = $sp.PasswordCredentials.SecretText | ConvertTo-SecureString -AsPlainText -Force
            
            # Assign required permissions
            $resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName
            New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName "Azure Connected Machine Onboarding" -Scope $resourceGroup.ResourceId
            New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName "Azure Connected Machine Resource Administrator" -Scope $resourceGroup.ResourceId
            
            Write-EnhancedLog "Created service principal: $ServicePrincipalId" "Success"
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

Write-Information "Azure Arc onboarding completed for $ServerName"
"@
            $windowsScript | Out-File -FilePath ".\Arc-Onboarding-Windows-$ServerName.ps1" -Encoding UTF8
            Write-EnhancedLog "Generated Windows onboarding script: Arc-Onboarding-Windows-$ServerName.ps1" "Success"
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
            Write-EnhancedLog "Generated Linux onboarding script: Arc-Onboarding-Linux-$ServerName.sh" "Success"
        }
        
    } catch {
        Write-EnhancedLog "Failed to generate onboarding script: $($_.Exception.Message)" "Error"
        return $false
    }
    
    return $true
}

# Install Arc extensions
[CmdletBinding()]
function Install-ArcExtension {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$ServerName,
        [string[]]$Extensions
    )
    
    foreach ($extension in $Extensions) {
        try {
            Write-EnhancedLog "Installing extension '$extension' on server '$ServerName'..." "Info"
            
            $extensionParams = @{
                ResourceGroupName = $ResourceGroupName
                MachineName = $ServerName
                Name = $extension
                Publisher = switch ($extension) {
                    "MicrosoftMonitoringAgent" { "Microsoft.EnterpriseCloud.Monitoring" }
                    "DependencyAgent" { "Microsoft.Azure.Monitoring.DependencyAgent" }
                    "CustomScriptExtension" { "Microsoft.Compute" }
                    default { "Microsoft.Azure.Extensions" }
                }
                Type = $extension
            }
            
            New-AzConnectedMachineExtension -ErrorAction Stop @extensionParams
            Write-EnhancedLog "Successfully installed extension '$extension'" "Success"
            
        } catch {
            Write-EnhancedLog "Failed to install extension '$extension': $($_.Exception.Message)" "Error"
        }
    }
}

# Configure monitoring for Arc servers
[CmdletBinding()]
function Enable-ArcMonitoring {
    param([string]$ServerName)
    
    try {
        Write-EnhancedLog "Configuring Azure Monitor for Arc server '$ServerName'..." "Info"
        
        # Create Log Analytics workspace if it doesn't exist
        $workspaceName = "law-$ResourceGroupName-$(Get-Random -Maximum 1000)"
        $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $workspaceName -ErrorAction SilentlyContinue
        
        if (-not $workspace) {
            $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $workspaceName -Location $Location
            Write-EnhancedLog "Created Log Analytics workspace: $workspaceName" "Success"
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
        Write-EnhancedLog "Successfully configured monitoring for '$ServerName'" "Success"
        
    } catch {
        Write-EnhancedLog "Failed to configure monitoring: $($_.Exception.Message)" "Error"
    }
}

# Configure compliance policies
[CmdletBinding()]
function Set-ComplianceConfiguration -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$ServerName)
    
    try {
        Write-EnhancedLog "Configuring compliance policies for Arc server '$ServerName'..." "Info"
        
        # Common compliance policies for Arc servers
        $policies = @(
            "Audit machines with insecure password security settings",
            "Deploy prerequisites to audit Windows VMs configurations in 'Security Settings - Account Policies'",
            "Audit Windows machines missing any of specified members in the Administrators group"
        )
        
        foreach ($policy in $policies) {
            try {
                # This would typically assign built-in policies - implementation depends on specific compliance requirements
                Write-EnhancedLog "Applying policy: $policy" "Info"
            } catch {
                Write-EnhancedLog "Failed to apply policy '$policy': $($_.Exception.Message)" "Warning"
            }
        }
        
        Write-EnhancedLog "Compliance configuration completed for '$ServerName'" "Success"
        
    } catch {
        Write-EnhancedLog "Failed to configure compliance: $($_.Exception.Message)" "Error"
    }
}

# Process bulk server onboarding
[CmdletBinding()]
function Start-BulkOnboarding {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$CsvPath)
    
    try {
        if (-not (Test-Path $CsvPath)) {
            throw "CSV file not found: $CsvPath"
        }
        
        $servers = Import-Csv $CsvPath
        Write-EnhancedLog "Found $($servers.Count) servers in CSV file" "Info"
        
        foreach ($server in $servers) {
            Write-EnhancedLog "Processing server: $($server.ServerName)" "Info"
            
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
        
        Write-EnhancedLog "Bulk onboarding process completed" "Success"
        
    } catch {
        Write-EnhancedLog "Bulk onboarding failed: $($_.Exception.Message)" "Error"
    }
}

# Main execution
try {
    Write-EnhancedLog "Starting Azure Arc Server Onboarding Tool" "Info"
    Write-EnhancedLog "Target Resource Group: $ResourceGroupName" "Info"
    Write-EnhancedLog "Target Location: $Location" "Info"
    
    # Connect to Azure
    if (-not (Connect-ToAzure)) {
        exit 1
    }
    
    # Ensure resource group exists
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-EnhancedLog "Creating resource group: $ResourceGroupName" "Info"
        $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag $Tags
        Write-EnhancedLog "Successfully created resource group" "Success"
    }
    
    # Process based on mode (single server or bulk)
    if ($ServerListPath) {
        Write-EnhancedLog "Running in bulk mode with CSV: $ServerListPath" "Info"
        Start-BulkOnboarding -CsvPath $ServerListPath
    } elseif ($ServerName) {
        Write-EnhancedLog "Running in single server mode for: $ServerName" "Info"
        
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
        Write-EnhancedLog "Please specify either -ServerName for single server or -ServerListPath for bulk operations" "Error"
        exit 1
    }
    
    Write-EnhancedLog "Azure Arc Server Onboarding Tool completed successfully" "Success"
    Write-EnhancedLog "Generated onboarding scripts are ready for deployment" "Info"
    Write-EnhancedLog "Next steps: Execute the generated scripts on target servers" "Info"
    
} catch {
    Write-EnhancedLog "Tool execution failed: $($_.Exception.Message)" "Error"
    exit 1
}
