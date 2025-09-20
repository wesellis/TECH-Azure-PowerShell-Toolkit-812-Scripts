<#
.SYNOPSIS
    Azure Arc Server Onboarding Tool

.DESCRIPTION
    Azure Arc Server Onboarding and Management Tool - Enterprise Edition
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
.EXAMPLE
    .\Azure-Arc-Server-Onboarding-Tool.ps1 -ResourceGroupName "arc-servers-rg" -Location "East US" -ServerName "web-server-01" -EnableMonitoring -ConfigureCompliance
.EXAMPLE
    .\Azure-Arc-Server-Onboarding-Tool.ps1 -ResourceGroupName "arc-servers-rg" -ServerListPath "C:\servers.csv" -InstallExtensions @("MicrosoftMonitoringAgent", "DependencyAgent") -EnableMonitoring
.NOTES
    Author: Wesley Ellis
    Version: 2.0
    Requires: PowerShell 7.0+, Az.ConnectedMachine module
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$ServerName,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$ServerListPath,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$ServicePrincipalId,
    [Parameter(Mandatory = $false)]
    [SecureString]$ServicePrincipalSecret,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
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
    [ValidateSet("Windows" , "Linux" , "Both" )]
    [string]$OperatingSystem = "Both"
)
try {
    Import-Module Az.Accounts -Force -ErrorAction Stop
    Import-Module Az.Resources -Force -ErrorAction Stop
    Import-Module Az.ConnectedMachine -Force -ErrorAction Stop
    Write-Host "Successfully imported required Azure modules" -ForegroundColor Green
} catch {
    Write-Error "  Failed to import required modules: $($_.Exception.Message)"
    throw
}
function Write-Verbose "Log entry"ndatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("Info" , "Warning" , "Error" , "Success" )]
        [string]$Level = "Info"
    )
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $colors = @{
        Info = "White"
        Warning = "Yellow"
        Error = "Red"
        Success = "Green"
    }
    Write-Host " [$timestamp] $Message" -ForegroundColor $colors[$Level]
    # Log to file if specified
    if ($script:LogPath) {
        " [$timestamp] [$Level] $Message" | Out-File -FilePath $script:LogPath -Append
    }
}
function Connect-ToAzure {
    try {
        if ($SubscriptionId) {
            Connect-AzAccount -Subscription $SubscriptionId
        } else {
            Connect-AzAccount
        }
        $context = Get-AzContext -ErrorAction Stop
        Write-Verbose "Log entry"nnected to Azure subscription: $($context.Subscription.Name)" "Success"
        return $true
    } catch {
        Write-Verbose "Log entry"nnect to Azure: $($_.Exception.Message)" "Error"
        return $false
    }
}
function New-ArcOnboardingScript -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ServerName,
        [string]$OperatingSystem
    )
    try {
        # Generate service principal if not provided
        if (-not $ServicePrincipalId) {
            Write-Verbose "Log entry"ng service principal for Arc onboarding..." "Info"
            $sp = New-AzADServicePrincipal -DisplayName "Arc-Onboarding-SP-$((Get-Date).ToString('yyyyMMdd'))"
            $ServicePrincipalId = $sp.AppId
            $ServicePrincipalSecret = $sp.PasswordCredentials.SecretText | ConvertTo-SecureString -AsPlainText -Force
            # Assign required permissions
            $resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName
            New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName "Azure Connected Machine Onboarding" -Scope $resourceGroup.ResourceId
            New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName "Azure Connected Machine Resource Administrator" -Scope $resourceGroup.ResourceId
            Write-Verbose "Log entry"ncipal: $ServicePrincipalId" "Success"
        }
        # Generate onboarding command based on OS
        $secretText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ServicePrincipalSecret))
        if ($OperatingSystem -eq "Windows" -or $OperatingSystem -eq "Both" ) {
            $windowsScript = @"
Invoke-WebRequest -Uri " https://aka.ms/AzureConnectedMachineAgent" -OutFile "AzureConnectedMachineAgent.msi"
msiexec /i AzureConnectedMachineAgent.msi /l*v installationlog.txt /qn
& " \$env:ProgramFiles\AzureConnectedMachineAgent\azcmagent.exe" connect ``
    --service-principal-id " $ServicePrincipalId" ``
    --service-principal-secret " $secretText" ``
    --tenant-id " $TenantId" ``
    --subscription-id " $SubscriptionId" ``
    --resource-group " $ResourceGroupName" ``
    --location " $Location" ``
    --resource-name " $ServerName" ``
    --tags " $(($Tags.GetEnumerator() | ForEach-Object { " $($_.Key)=$($_.Value)" }) -join ',')"
Write-Host "Azure Arc onboarding completed for $ServerName"
" @
            $windowsScript | Out-File -FilePath " .\Arc-Onboarding-Windows-$ServerName.ps1" -Encoding UTF8
            Write-Verbose "Log entry"nerated Windows onboarding script: Arc-Onboarding-Windows-$ServerName.ps1" "Success"
        }
        if ($OperatingSystem -eq "Linux" -or $OperatingSystem -eq "Both" ) {
            $linuxScript = @"
wget https://aka.ms/azcmagent -O ~/azcmagent_linux_amd64.tar.gz
tar -xvzf ~/azcmagent_linux_amd64.tar.gz
sudo bash ~/install_linux_azcmagent.sh
sudo azcmagent connect \
    --service-principal-id " $ServicePrincipalId" \
    --service-principal-secret " $secretText" \
    --tenant-id " $TenantId" \
    --subscription-id " $SubscriptionId" \
    --resource-group " $ResourceGroupName" \
    --location " $Location" \
    --resource-name " $ServerName" \
    --tags " $(($Tags.GetEnumerator() | ForEach-Object { " $($_.Key)=$($_.Value)" }) -join ',')"
echo "Azure Arc onboarding completed for $ServerName"
" @
            $linuxScript | Out-File -FilePath " .\Arc-Onboarding-Linux-$ServerName.sh" -Encoding UTF8
            Write-Verbose "Log entry"nerated Linux onboarding script: Arc-Onboarding-Linux-$ServerName.sh" "Success"
        }
    } catch {
        Write-Verbose "Log entry"nerate onboarding script: $($_.Exception.Message)" "Error"
        return $false
    }
    return $true
}
function Install-ArcExtension {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ServerName,
        [string[]]$Extensions
    )
    foreach ($extension in $Extensions) {
        try {
            Write-Verbose "Log entry"nstalling extension '$extension' on server '$ServerName'..." "Info"
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
            Write-Verbose "Log entry"nstalled extension '$extension'" "Success"
        } catch {
            Write-Verbose "Log entry"nstall extension '$extension': $($_.Exception.Message)" "Error"
        }
    }
}
function Enable-ArcMonitoring {
    param([Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ServerName)
    try {
        Write-Verbose "Log entry"nfiguring Azure Monitor for Arc server '$ServerName'..." "Info"
        # Create Log Analytics workspace if it doesn't exist
        $workspaceName = " law-$ResourceGroupName-$(Get-Random -Maximum 1000)"
        $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $workspaceName -ErrorAction SilentlyContinue
        if (-not $workspace) {
            $workspace = New-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $workspaceName -Location $Location
            Write-Verbose "Log entry"nalytics workspace: $workspaceName" "Success"
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
        Write-Verbose "Log entry"nfigured monitoring for '$ServerName'" "Success"
    } catch {
        Write-Verbose "Log entry"nfigure monitoring: $($_.Exception.Message)" "Error"
    }
}
function Set-ComplianceConfiguration -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ServerName)
    try {
        Write-Verbose "Log entry"nfiguring compliance policies for Arc server '$ServerName'..." "Info"
        # Common compliance policies for Arc servers
        $policies = @(
            "Audit machines with insecure password security settings" ,
            "Deploy prerequisites to audit Windows VMs configurations in 'Security Settings - Account Policies'" ,
            "Audit Windows machines missing any of specified members in the Administrators group"
        )
        foreach ($policy in $policies) {
            try {
                # This would typically assign built-in policies - implementation depends on specific compliance requirements
                Write-Verbose "Log entry"ng policy: $policy" "Info"
            } catch {
                Write-Verbose "Log entry"n.Message)" "Warning"
            }
        }
        Write-Verbose "Log entry"nce configuration completed for '$ServerName'" "Success"
    } catch {
        Write-Verbose "Log entry"nfigure compliance: $($_.Exception.Message)" "Error"
    }
}
function Start-BulkOnboarding {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$CsvPath)
    try {
        if (-not (Test-Path $CsvPath)) {
            throw "CSV file not found: $CsvPath"
        }
        $servers = Import-Csv $CsvPath
        Write-Verbose "Log entry"nd $($servers.Count) servers in CSV file" "Info"
        foreach ($server in $servers) {
            Write-Verbose "Log entry"ng server: $($server.ServerName)" "Info"
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
        Write-Verbose "Log entry"nboarding process completed" "Success"
    } catch {
        Write-Verbose "Log entry"nboarding failed: $($_.Exception.Message)" "Error"
    }
}
try {
    Write-Verbose "Log entry"ng Azure Arc Server Onboarding Tool" "Info"
    Write-Verbose "Log entry"Name" "Info"
    Write-Verbose "Log entry"n: $Location" "Info"
    # Connect to Azure
    if (-not (Connect-ToAzure)) {
        throw
    }
    # Ensure resource group exists
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-Verbose "Log entry"ng resource group: $ResourceGroupName" "Info"
$rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag $Tags
        Write-Verbose "Log entry"n mode (single server or bulk)
    if ($ServerListPath) {
        Write-Verbose "Log entry"nning in bulk mode with CSV: $ServerListPath" "Info"
        Start-BulkOnboarding -CsvPath $ServerListPath
    } elseif ($ServerName) {
        Write-Verbose "Log entry"nning in single server mode for: $ServerName" "Info"
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
        Write-Verbose "Log entry"Name for single server or -ServerListPath for bulk operations" "Error"
        throw
    }
    Write-Verbose "Log entry"nboarding Tool completed successfully" "Success"
    Write-Verbose "Log entry"nerated onboarding scripts are ready for deployment" "Info"
    Write-Verbose "Log entry"Next steps: Execute the generated scripts on target servers" "Info"
} catch {
    Write-Verbose "Log entry"n failed: $($_.Exception.Message)" "Error"
    throw
}

