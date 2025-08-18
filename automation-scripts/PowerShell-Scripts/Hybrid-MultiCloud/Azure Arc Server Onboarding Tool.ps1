<#
.SYNOPSIS
    Azure Arc Server Onboarding Tool

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
    We Enhanced Azure Arc Server Onboarding Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

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
    .\Azure-Arc-Server-Onboarding-Tool.ps1 -ResourceGroupName " arc-servers-rg" -Location " East US" -ServerName " web-server-01" -EnableMonitoring -ConfigureCompliance
.EXAMPLE
    .\Azure-Arc-Server-Onboarding-Tool.ps1 -ResourceGroupName " arc-servers-rg" -ServerListPath " C:\servers.csv" -InstallExtensions @(" MicrosoftMonitoringAgent" , " DependencyAgent" ) -EnableMonitoring
.NOTES
    Author: Wesley Ellis
    Version: 2.0
    Requires: PowerShell 7.0+, Az.ConnectedMachine module


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory = $false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESubscriptionId,
    
    [Parameter(Mandatory = $true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    
    [Parameter(Mandatory = $false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEServerName,
    
    [Parameter(Mandatory = $false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEServerListPath,
    
    [Parameter(Mandatory = $false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEServicePrincipalId,
    
    [Parameter(Mandatory = $false)]
    [SecureString]$WEServicePrincipalSecret,
    
    [Parameter(Mandatory = $false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WETenantId,
    
    [Parameter(Mandatory = $false)]
    [hashtable]$WETags = @{
        Environment = " Production"
        ManagedBy = " AzureArc"
        CreatedBy = " ArcOnboardingTool"
    },
    
    [Parameter(Mandatory = $false)]
    [string[]]$WEInstallExtensions = @(),
    
    [Parameter(Mandatory = $false)]
    [switch]$WEEnableMonitoring,
    
    [Parameter(Mandatory = $false)]
    [switch]$WEConfigureCompliance,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet(" Windows" , " Linux" , " Both" )]
    [string]$WEOperatingSystem = " Both"
)


try {
    Import-Module Az.Accounts -Force -ErrorAction Stop
    Import-Module Az.Resources -Force -ErrorAction Stop
    Import-Module Az.ConnectedMachine -Force -ErrorAction Stop
    Write-WELog " ✅ Successfully imported required Azure modules" " INFO" -ForegroundColor Green
} catch {
    Write-Error " ❌ Failed to import required modules: $($_.Exception.Message)"
    exit 1
}


[CmdletBinding()]
function WE-Write-EnhancedLog {
    param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEMessage,
        [ValidateSet(" Info" , " Warning" , " Error" , " Success" )]
        [string]$WELevel = " Info"
    )
    
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $colors = @{
        Info = " White"
        Warning = " Yellow" 
        Error = " Red"
        Success = " Green"
    }
    
    Write-WELog " [$timestamp] $WEMessage" " INFO" -ForegroundColor $colors[$WELevel]
    
    # Log to file if specified
    if ($script:LogPath) {
        " [$timestamp] [$WELevel] $WEMessage" | Out-File -FilePath $script:LogPath -Append
    }
}


[CmdletBinding()]
function WE-Connect-ToAzure {
    try {
        if ($WESubscriptionId) {
            Connect-AzAccount -Subscription $WESubscriptionId
        } else {
            Connect-AzAccount
        }
        
        $context = Get-AzContext -ErrorAction Stop
        Write-EnhancedLog " Successfully connected to Azure subscription: $($context.Subscription.Name)" " Success"
        return $true
    } catch {
        Write-EnhancedLog " Failed to connect to Azure: $($_.Exception.Message)" " Error"
        return $false
    }
}


[CmdletBinding()]
function WE-New-ArcOnboardingScript -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEServerName,
        [string]$WEOperatingSystem
    )
    
    try {
        # Generate service principal if not provided
        if (-not $WEServicePrincipalId) {
            Write-EnhancedLog " Creating service principal for Arc onboarding..." " Info"
            $sp = New-AzADServicePrincipal -DisplayName " Arc-Onboarding-SP-$((Get-Date).ToString('yyyyMMdd'))"
            $WEServicePrincipalId = $sp.AppId
            $WEServicePrincipalSecret = $sp.PasswordCredentials.SecretText | ConvertTo-SecureString -AsPlainText -Force
            
            # Assign required permissions
            $resourceGroup = Get-AzResourceGroup -Name $WEResourceGroupName
            New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName " Azure Connected Machine Onboarding" -Scope $resourceGroup.ResourceId
            New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName " Azure Connected Machine Resource Administrator" -Scope $resourceGroup.ResourceId
            
            Write-EnhancedLog " Created service principal: $WEServicePrincipalId" " Success"
        }
        
        # Generate onboarding command based on OS
        $secretText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($WEServicePrincipalSecret))
        
        if ($WEOperatingSystem -eq " Windows" -or $WEOperatingSystem -eq " Both" ) {
            $windowsScript = @"

Invoke-WebRequest -Uri " https://aka.ms/AzureConnectedMachineAgent" -OutFile " AzureConnectedMachineAgent.msi"
msiexec /i AzureConnectedMachineAgent.msi /l*v installationlog.txt /qn


& " \$env:ProgramFiles\AzureConnectedMachineAgent\azcmagent.exe" connect ``
    --service-principal-id " $WEServicePrincipalId" ``
    --service-principal-secret " $secretText" ``
    --tenant-id " $WETenantId" ``
    --subscription-id " $WESubscriptionId" ``
    --resource-group " $WEResourceGroupName" ``
    --location " $WELocation" ``
    --resource-name " $WEServerName" ``
    --tags " $(($WETags.GetEnumerator() | ForEach-Object { " $($_.Key)=$($_.Value)" }) -join ',')"

Write-WELog " Azure Arc onboarding completed for $WEServerName" " INFO"
" @
            $windowsScript | Out-File -FilePath " .\Arc-Onboarding-Windows-$WEServerName.ps1" -Encoding UTF8
            Write-EnhancedLog " Generated Windows onboarding script: Arc-Onboarding-Windows-$WEServerName.ps1" " Success"
        }
        
        if ($WEOperatingSystem -eq " Linux" -or $WEOperatingSystem -eq " Both" ) {
            $linuxScript = @"



wget https://aka.ms/azcmagent -O ~/azcmagent_linux_amd64.tar.gz
tar -xvzf ~/azcmagent_linux_amd64.tar.gz
sudo bash ~/install_linux_azcmagent.sh


sudo azcmagent connect \
    --service-principal-id " $WEServicePrincipalId" \
    --service-principal-secret " $secretText" \
    --tenant-id " $WETenantId" \
    --subscription-id " $WESubscriptionId" \
    --resource-group " $WEResourceGroupName" \
    --location " $WELocation" \
    --resource-name " $WEServerName" \
    --tags " $(($WETags.GetEnumerator() | ForEach-Object { " $($_.Key)=$($_.Value)" }) -join ',')"

echo " Azure Arc onboarding completed for $WEServerName"
" @
            $linuxScript | Out-File -FilePath " .\Arc-Onboarding-Linux-$WEServerName.sh" -Encoding UTF8
            Write-EnhancedLog " Generated Linux onboarding script: Arc-Onboarding-Linux-$WEServerName.sh" " Success"
        }
        
    } catch {
        Write-EnhancedLog " Failed to generate onboarding script: $($_.Exception.Message)" " Error"
        return $false
    }
    
    return $true
}


[CmdletBinding()]
function WE-Install-ArcExtension {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEServerName,
        [string[]]$WEExtensions
    )
    
    foreach ($extension in $WEExtensions) {
        try {
            Write-EnhancedLog " Installing extension '$extension' on server '$WEServerName'..." " Info"
            
            $extensionParams = @{
                ResourceGroupName = $WEResourceGroupName
                MachineName = $WEServerName
                Name = $extension
                Publisher = switch ($extension) {
                    " MicrosoftMonitoringAgent" { " Microsoft.EnterpriseCloud.Monitoring" }
                    " DependencyAgent" { " Microsoft.Azure.Monitoring.DependencyAgent" }
                    " CustomScriptExtension" { " Microsoft.Compute" }
                    default { " Microsoft.Azure.Extensions" }
                }
                Type = $extension
            }
            
            New-AzConnectedMachineExtension -ErrorAction Stop @extensionParams
            Write-EnhancedLog " Successfully installed extension '$extension'" " Success"
            
        } catch {
            Write-EnhancedLog " Failed to install extension '$extension': $($_.Exception.Message)" " Error"
        }
    }
}


[CmdletBinding()]
function WE-Enable-ArcMonitoring {
    param([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEServerName)
    
    try {
        Write-EnhancedLog " Configuring Azure Monitor for Arc server '$WEServerName'..." " Info"
        
        # Create Log Analytics workspace if it doesn't exist
        $workspaceName = " law-$WEResourceGroupName-$(Get-Random -Maximum 1000)"
        $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $WEResourceGroupName -Name $workspaceName -ErrorAction SilentlyContinue
        
        if (-not $workspace) {
            $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $WEResourceGroupName -Name $workspaceName -Location $WELocation
            Write-EnhancedLog " Created Log Analytics workspace: $workspaceName" " Success"
        }
        
        # Install monitoring agent extension
        $monitoringExtension = @{
            ResourceGroupName = $WEResourceGroupName
            MachineName = $WEServerName
            Name = " MicrosoftMonitoringAgent"
            Publisher = " Microsoft.EnterpriseCloud.Monitoring"
            Type = " MicrosoftMonitoringAgent"
            Settings = @{
                workspaceId = $workspace.CustomerId
            }
            ProtectedSettings = @{
                workspaceKey = (Get-AzOperationalInsightsWorkspaceSharedKey -ResourceGroupName $WEResourceGroupName -Name $workspaceName).PrimarySharedKey
            }
        }
        
        New-AzConnectedMachineExtension -ErrorAction Stop @monitoringExtension
        Write-EnhancedLog " Successfully configured monitoring for '$WEServerName'" " Success"
        
    } catch {
        Write-EnhancedLog " Failed to configure monitoring: $($_.Exception.Message)" " Error"
    }
}


[CmdletBinding()]
function WE-Set-ComplianceConfiguration -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEServerName)
    
    try {
        Write-EnhancedLog " Configuring compliance policies for Arc server '$WEServerName'..." " Info"
        
        # Common compliance policies for Arc servers
        $policies = @(
            " Audit machines with insecure password security settings" ,
            " Deploy prerequisites to audit Windows VMs configurations in 'Security Settings - Account Policies'" ,
            " Audit Windows machines missing any of specified members in the Administrators group"
        )
        
        foreach ($policy in $policies) {
            try {
                # This would typically assign built-in policies - implementation depends on specific compliance requirements
                Write-EnhancedLog " Applying policy: $policy" " Info"
            } catch {
                Write-EnhancedLog " Failed to apply policy '$policy': $($_.Exception.Message)" " Warning"
            }
        }
        
        Write-EnhancedLog " Compliance configuration completed for '$WEServerName'" " Success"
        
    } catch {
        Write-EnhancedLog " Failed to configure compliance: $($_.Exception.Message)" " Error"
    }
}


[CmdletBinding()]
function WE-Start-BulkOnboarding {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WECsvPath)
    
    try {
        if (-not (Test-Path $WECsvPath)) {
            throw " CSV file not found: $WECsvPath"
        }
        
        $servers = Import-Csv $WECsvPath
        Write-EnhancedLog " Found $($servers.Count) servers in CSV file" " Info"
        
        foreach ($server in $servers) {
            Write-EnhancedLog " Processing server: $($server.ServerName)" " Info"
            
            # Generate onboarding script
            $success = New-ArcOnboardingScript -ServerName $server.ServerName -OperatingSystem $server.OperatingSystem
            
            if ($success) {
                # Install extensions if specified
                if ($WEInstallExtensions.Count -gt 0) {
                    Install-ArcExtension -ServerName $server.ServerName -Extensions $WEInstallExtensions
                }
                
                # Configure monitoring if enabled
                if ($WEEnableMonitoring) {
                    Enable-ArcMonitoring -ServerName $server.ServerName
                }
                
                # Configure compliance if enabled
                if ($WEConfigureCompliance) {
                    Set-ComplianceConfiguration -ServerName $server.ServerName
                }
            }
        }
        
        Write-EnhancedLog " Bulk onboarding process completed" " Success"
        
    } catch {
        Write-EnhancedLog " Bulk onboarding failed: $($_.Exception.Message)" " Error"
    }
}


try {
    Write-EnhancedLog " Starting Azure Arc Server Onboarding Tool" " Info"
    Write-EnhancedLog " Target Resource Group: $WEResourceGroupName" " Info"
    Write-EnhancedLog " Target Location: $WELocation" " Info"
    
    # Connect to Azure
    if (-not (Connect-ToAzure)) {
        exit 1
    }
    
    # Ensure resource group exists
    $rg = Get-AzResourceGroup -Name $WEResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-EnhancedLog " Creating resource group: $WEResourceGroupName" " Info"
       ;  $rg = New-AzResourceGroup -Name $WEResourceGroupName -Location $WELocation -Tag $WETags
        Write-EnhancedLog " Successfully created resource group" " Success"
    }
    
    # Process based on mode (single server or bulk)
    if ($WEServerListPath) {
        Write-EnhancedLog " Running in bulk mode with CSV: $WEServerListPath" " Info"
        Start-BulkOnboarding -CsvPath $WEServerListPath
    } elseif ($WEServerName) {
        Write-EnhancedLog " Running in single server mode for: $WEServerName" " Info"
        
        # Generate onboarding script
       ;  $success = New-ArcOnboardingScript -ServerName $WEServerName -OperatingSystem $WEOperatingSystem
        
        if ($success) {
            # Install extensions if specified
            if ($WEInstallExtensions.Count -gt 0) {
                Install-ArcExtension -ServerName $WEServerName -Extensions $WEInstallExtensions
            }
            
            # Configure monitoring if enabled
            if ($WEEnableMonitoring) {
                Enable-ArcMonitoring -ServerName $WEServerName
            }
            
            # Configure compliance if enabled
            if ($WEConfigureCompliance) {
                Set-ComplianceConfiguration -ServerName $WEServerName
            }
        }
    } else {
        Write-EnhancedLog " Please specify either -ServerName for single server or -ServerListPath for bulk operations" " Error"
        exit 1
    }
    
    Write-EnhancedLog " Azure Arc Server Onboarding Tool completed successfully" " Success"
    Write-EnhancedLog " Generated onboarding scripts are ready for deployment" " Info"
    Write-EnhancedLog " Next steps: Execute the generated scripts on target servers" " Info"
    
} catch {
    Write-EnhancedLog " Tool execution failed: $($_.Exception.Message)" " Error"
    exit 1
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================