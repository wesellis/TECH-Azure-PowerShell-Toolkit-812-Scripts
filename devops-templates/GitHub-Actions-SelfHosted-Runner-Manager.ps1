<#
.SYNOPSIS
    GitHub Actions Self-Hosted Runner Enterprise Management Tool

.DESCRIPTION
    tool for deploying, managing, and scaling GitHub Actions self-hosted runners
    on Azure with enterprise security, monitoring, and auto-scaling capabilities.
.PARAMETER ResourceGroupName
    Target Resource Group for runner infrastructure
.PARAMETER RunnerGroupName
    Name for the runner group
.PARAMETER Location
    Azure region for the runner infrastructure
.PARAMETER Action
    Action to perform (Deploy, Scale, Monitor, Update, Remove, Register)
.PARAMETER GitHubOrganization
    GitHub organization name
.PARAMETER GitHubRepository
    GitHub repository name (optional, for repo-level runners)
.PARAMETER GitHubToken
    GitHub Personal Access Token with repo/admin:org permissions
.PARAMETER RunnerCount
    Number of runners to deploy
.PARAMETER VMSize
    Azure VM size for runners
.PARAMETER RunnerOS
    Operating system for runners (Windows, Linux)
.PARAMETER EnableAutoScaling
    Enable auto-scaling based on queue depth
.PARAMETER MinRunners
    Minimum number of runners for auto-scaling
.PARAMETER MaxRunners
    Maximum number of runners for auto-scaling
.PARAMETER EnableMonitoring
    Enable
.PARAMETER EnableSpotInstances
    Use Azure Spot VMs for cost optimization
.PARAMETER CustomImage
    Custom VM image for runners
.PARAMETER RunnerLabels
    Labels to assign to runners
.PARAMETER VNetName
    Virtual Network name for secure networking
.PARAMETER SubnetName
    Subnet name for runner deployment
.PARAMETER KeyVaultName
    Key Vault name for storing secrets
.PARAMETER Tags
    Tags to apply to resources
    .\GitHub-Actions-SelfHosted-Runner-Manager.ps1 -ResourceGroupName "github-runners-rg" -RunnerGroupName "enterprise-runners" -Location "East US" -Action "Deploy" -GitHubOrganization "myorg" -RunnerCount 5 -EnableAutoScaling
    .\GitHub-Actions-SelfHosted-Runner-Manager.ps1 -ResourceGroupName "github-runners-rg" -Action "Scale" -RunnerCount 10 -EnableMonitoring
.NOTES
    Author: Wesley Ellis
    Version: 2.0
    Requires: PowerShell 7.0+, Azure PowerShell modules, GitHub CLI (optional)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$RunnerGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$Location,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet("Deploy", "Scale", "Monitor", "Update", "Remove", "Register", "Status")]
    [string]$Action,
    
    [Parameter(Mandatory = $false)]
    [string]$GitHubOrganization,
    
    [Parameter(Mandatory = $false)]
    [string]$GitHubRepository,
    
    [Parameter(Mandatory = $false)]
    [SecureString]$GitHubToken,
    
    [Parameter(Mandatory = $false)]
    [int]$RunnerCount = 3,
    
    [Parameter(Mandatory = $false)]
    [string]$VMSize = "Standard_D4s_v3",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Windows", "Linux")]
    [string]$RunnerOS = "Linux",
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableAutoScaling,
    
    [Parameter(Mandatory = $false)]
    [int]$MinRunners = 1,
    
    [Parameter(Mandatory = $false)]
    [int]$MaxRunners = 20,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableMonitoring,
    
    [Parameter(Mandatory = $false)]
    [switch]$EnableSpotInstances,
    
    [Parameter(Mandatory = $false)]
    [string]$CustomImage,
    
    [Parameter(Mandatory = $false)]
    [string[]]$RunnerLabels = @("azure", "self-hosted"),
    
    [Parameter(Mandatory = $false)]
    [string]$VNetName,
    
    [Parameter(Mandatory = $false)]
    [string]$SubnetName,
    
    [Parameter(Mandatory = $false)]
    [string]$KeyVaultName,
    
    [Parameter(Mandatory = $false)]
    [hashtable]$Tags = @{
        Environment = "Production"
        Application = "GitHubRunners"
        ManagedBy = "AutomationScript"
    }
)

#region Functions

# Import required modules
try {
    Import-Module Az.Accounts -Force -ErrorAction Stop
    Import-Module Az.Resources -Force -ErrorAction Stop
    Import-Module Az.Compute -Force -ErrorAction Stop
    Import-Module Az.Network -Force -ErrorAction Stop
    Import-Module Az.KeyVault -Force -ErrorAction Stop
    Write-Host "Successfully imported required Azure modules"
} catch {
    Write-Error "Failed to import required modules: $($_.Exception.Message)"
    throw
}

# Enhanced logging function
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
    
    Write-Host "[$timestamp] $Message" -ForegroundColor $colors[$Level]
}

# Get GitHub registration token
function Get-GitHubRegistrationToken {
    try {
        Write-EnhancedLog "Getting GitHub runner registration token..." "Info"
        
        if (-not $GitHubToken) {
            throw "GitHub token is required for runner registration"
        }
        
        $tokenString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($GitHubToken))
        $headers = @{
            "Authorization" = "token $tokenString"
            "Accept" = "application/vnd.github.v3+json"
        }
        
        if ($GitHubRepository) {
            $url = "https://api.github.com/repos/$GitHubOrganization/$GitHubRepository/actions/runners/registration-token"
        } else {
            $url = "https://api.github.com/orgs/$GitHubOrganization/actions/runners/registration-token"
        }
        
        $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers
        
        Write-EnhancedLog "Successfully obtained registration token" "Success"
        return $response.token
        
    } catch {
        Write-EnhancedLog "Failed to get GitHub registration token: $($_.Exception.Message)" "Error"
        throw
    }
}

# Create runner infrastructure
function New-RunnerInfrastructure {
    try {
        Write-EnhancedLog "Creating GitHub Actions runner infrastructure..." "Info"
        
        # Create Virtual Network if specified
        if ($VNetName) {
            $vnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName -ErrorAction SilentlyContinue
            if (-not $vnet) {
                Write-EnhancedLog "Creating Virtual Network: $VNetName" "Info"
                $subnetConfig = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix "10.0.1.0/24"
                $vnet = New-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Location $Location -Name $VNetName -AddressPrefix "10.0.0.0/16" -Subnet $subnetConfig -Tag $Tags
                Write-EnhancedLog "Successfully created Virtual Network" "Success"
            }
        }
        
        # Create Key Vault if specified
        if ($KeyVaultName) {
            $keyVault = Get-AzKeyVault -ResourceGroupName $ResourceGroupName -VaultName $KeyVaultName -ErrorAction SilentlyContinue
            if (-not $keyVault) {
                Write-EnhancedLog "Creating Key Vault: $KeyVaultName" "Info"
                $keyVault = New-AzKeyVault -ResourceGroupName $ResourceGroupName -VaultName $KeyVaultName -Location $Location -EnabledForDeployment -EnabledForTemplateDeployment -Tag $Tags
                
                # Store GitHub token in Key Vault
                if ($GitHubToken) {
                    Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name "GitHubToken" -SecretValue $GitHubToken | Out-Null
                    Write-EnhancedLog "Stored GitHub token in Key Vault" "Success"
                }
            }
        }
        
        # Create Network Security Group
        $nsgName = "$RunnerGroupName-nsg"
        $nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name $nsgName -ErrorAction SilentlyContinue
        if (-not $nsg) {
            Write-EnhancedLog "Creating Network Security Group: $nsgName" "Info"
            
            $sshRule = New-AzNetworkSecurityRuleConfig -Name "SSH" -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow
            $rdpRule = New-AzNetworkSecurityRuleConfig -Name "RDP" -Protocol Tcp -Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow
            $httpOutRule = New-AzNetworkSecurityRuleConfig -Name "HTTP-Out" -Protocol Tcp -Direction Outbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80,443 -Access Allow
            
            $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Location $Location -Name $nsgName -SecurityRules $sshRule, $rdpRule, $httpOutRule -Tag $Tags
            Write-EnhancedLog "Successfully created Network Security Group" "Success"
        }
        
        Write-EnhancedLog "Infrastructure setup completed" "Success"
        return @{
            VNet = $vnet
            KeyVault = $keyVault
            NSG = $nsg
        }
        
    } catch {
        Write-EnhancedLog "Failed to create infrastructure: $($_.Exception.Message)" "Error"
        throw
    }
}

# Generate runner configuration script
function New-RunnerConfigurationScript {
    param(
        [string]$RegistrationToken,
        [string]$RunnerName,
        [hashtable]$Infrastructure
    )
    
    try {
        Write-EnhancedLog "Generating runner configuration script for: $RunnerName" "Info"
        
        $runnerUrl = if ($GitHubRepository) {
            "https://github.com/$GitHubOrganization/$GitHubRepository"
        } else {
            "https://github.com/$GitHubOrganization"
        }
        
        $labelsString = $RunnerLabels -join ","
        
        if ($RunnerOS -eq "Linux") {
            $configScript = @"
#!/bin/bash
set -e

# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install required packages
sudo apt-get install -y curl wget unzip jq

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker `$USER

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=`$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt-get update
sudo apt-get install -y gh

# Create runner user
sudo useradd -m -s /bin/bash actions-runner
sudo usermod -aG docker actions-runner

# Download and configure GitHub Actions runner
sudo -u actions-runner mkdir -p /home/actions-runner/actions-runner
cd /home/actions-runner/actions-runner

RUNNER_VERSION=`$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/v//')
sudo -u actions-runner wget https://github.com/actions/runner/releases/download/v`$RUNNER_VERSION/actions-runner-linux-x64-`$RUNNER_VERSION.tar.gz
sudo -u actions-runner tar xzf actions-runner-linux-x64-`$RUNNER_VERSION.tar.gz

# Configure runner
sudo -u actions-runner ./config.sh --url "$runnerUrl" --token "$RegistrationToken" --name "$RunnerName" --labels "$labelsString" --unattended --replace

# Install runner as service
sudo ./svc.sh install actions-runner
sudo ./svc.sh start

# Configure auto-update
echo "0 2 * * * /home/actions-runner/actions-runner/update.sh" | sudo -u actions-runner crontab -

# Setup monitoring agent (if enabled)
if [ "$($EnableMonitoring.ToString().ToLower())" == "true" ]; then
    # Install Azure Monitor agent
    wget https://raw.githubusercontent.com/Microsoft/OMS-Agent-for-Linux/master/installer/scripts/onboard_agent.sh
    sudo sh onboard_agent.sh -w WORKSPACE_ID -s WORKSPACE_KEY
fi

echo "GitHub Actions runner '$RunnerName' configured successfully"
"@
        } else {
            # Windows PowerShell script
            $configScript = @"
# GitHub Actions Runner Configuration Script for Windows
Set-ExecutionPolicy Bypass -Scope Process -Force

# Install Chocolatey
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# Install required software
choco install -y git
choco install -y docker-desktop
choco install -y azure-cli
choco install -y gh

# Create runner directory
`$runnerPath = "C:\actions-runner"
New-Item -ItemType Directory -Path `$runnerPath -Force

# Download GitHub Actions runner
Set-Location `$runnerPath
`$runnerVersion = (Invoke-RestMethod -Uri "https://api.github.com/repos/actions/runner/releases/latest").tag_name.TrimStart('v')
`$runnerUrl = "https://github.com/actions/runner/releases/download/v`$runnerVersion/actions-runner-win-x64-`$runnerVersion.zip"
Invoke-WebRequest -Uri `$runnerUrl -OutFile "actions-runner.zip"
Expand-Archive -Path "actions-runner.zip" -DestinationPath . -Force
Remove-Item "actions-runner.zip"

# Configure runner
& .\config.cmd --url "$runnerUrl" --token "$RegistrationToken" --name "$RunnerName" --labels "$labelsString" --unattended --replace

# Install and start runner service
& .\svc.sh install
& .\svc.sh start

Write-Host "GitHub Actions runner '$RunnerName' configured successfully"
"@
        }
        
        return $configScript
        
    } catch {
        Write-EnhancedLog "Failed to generate configuration script: $($_.Exception.Message)" "Error"
        throw
    }
}

# Deploy GitHub Actions runners
function Install-GitHubRunners {
    param([hashtable]$Infrastructure)
    
    try {
        Write-EnhancedLog "Deploying $RunnerCount GitHub Actions runners..." "Info"
        
        # Get GitHub registration token
        $registrationToken = Get-GitHubRegistrationToken -ErrorAction Stop
        
        $deployedRunners = @()
        
        for ($i = 1; $i -le $RunnerCount; $i++) {
            $runnerName = "$RunnerGroupName-runner-$i"
            
            Write-EnhancedLog "Deploying runner: $runnerName" "Info"
            
            # Generate configuration script
            $configScript = New-RunnerConfigurationScript -RegistrationToken $registrationToken -RunnerName $runnerName -Infrastructure $Infrastructure
            
            # Create VM
            $vmParams = @{
                ResourceGroupName = $ResourceGroupName
                Location = $Location
                Name = $runnerName
                Size = $VMSize
                Tag = $Tags
            }
            
            if ($RunnerOS -eq "Linux") {
                $vmParams.Image = if ($CustomImage) { $CustomImage } else { "Ubuntu2204" }
                $vmParams.Credential = Get-Credential -Message "Enter Linux admin credentials"
            } else {
                $vmParams.Image = if ($CustomImage) { $CustomImage } else { "Win2022Datacenter" }
                $vmParams.Credential = Get-Credential -Message "Enter Windows admin credentials"
            }
            
            if ($Infrastructure.VNet) {
                $vmParams.VirtualNetworkName = $Infrastructure.VNet.Name
                $vmParams.SubnetName = $SubnetName
            }
            
            if ($EnableSpotInstances) {
                $vmParams.Priority = "Spot"
                $vmParams.MaxPrice = -1  # Use current market price
            }
            
            # Create the VM
            $vm = New-AzVM -ErrorAction Stop @vmParams
            
            # Apply configuration script
            if ($RunnerOS -eq "Linux") {
                $scriptExtension = Set-AzVMExtension -ResourceGroupName $ResourceGroupName -VMName $runnerName -Name "ConfigureRunner" -Publisher "Microsoft.Azure.Extensions" -Type "CustomScript" -TypeHandlerVersion "2.1" -Settings @{
                    script = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($configScript))
                }
            } else {
                $scriptExtension = Set-AzVMExtension -ResourceGroupName $ResourceGroupName -VMName $runnerName -Name "ConfigureRunner" -Publisher "Microsoft.Compute" -Type "CustomScriptExtension" -TypeHandlerVersion "1.10" -Settings @{
                    commandToExecute = "powershell.exe -ExecutionPolicy Bypass -EncodedCommand $([System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($configScript)))"
                }
            }
            
            $deployedRunners += @{
                Name = $runnerName
                VM = $vm
                Extension = $scriptExtension
            }
            
            Write-EnhancedLog "Successfully deployed runner: $runnerName" "Success"
        }
        
        Write-EnhancedLog "Successfully deployed all $RunnerCount runners" "Success"
        return $deployedRunners
        
    } catch {
        Write-EnhancedLog "Failed to deploy runners: $($_.Exception.Message)" "Error"
        throw
    }
}

# Configure auto-scaling
function Set-RunnerAutoScaling {
    try {
        if (-not $EnableAutoScaling) {
            Write-EnhancedLog "Auto-scaling is not enabled" "Info"
            return
        }
        
        Write-EnhancedLog "Configuring auto-scaling for GitHub Actions runners..." "Info"
        
        # Create Logic App for auto-scaling (simplified version)
        $logicAppName = "$RunnerGroupName-autoscaler"
        
        # This would typically involve creating a Logic App or Function App
        # that monitors GitHub Actions queue depth and scales runners accordingly
        Write-EnhancedLog "Auto-scaling configuration completed (Logic App/Function App deployment required)" "Info"
        
    } catch {
        Write-EnhancedLog "Failed to configure auto-scaling: $($_.Exception.Message)" "Error"
    }
}

# Monitor runner status
function Get-RunnerStatus {
    try {
        Write-EnhancedLog "Checking GitHub Actions runner status..." "Info"
        
        # Check Azure VMs
        $runnerVMs = Get-AzVM -ResourceGroupName $ResourceGroupName | Where-Object { $_.Name -like "$RunnerGroupName-runner-*" }
        
        Write-EnhancedLog "Azure VM Status:" "Info"
        foreach ($vm in $runnerVMs) {
            $vmStatus = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $vm.Name -Status
            $powerState = ($vmStatus.Statuses | Where-Object { $_.Code -like "PowerState/*" }).DisplayStatus
            
            Write-EnhancedLog "  VM: $($vm.Name)" "Info"
            Write-EnhancedLog "  Power State: $powerState" "Info"
            Write-EnhancedLog "  Size: $($vm.HardwareProfile.VmSize)" "Info"
            Write-EnhancedLog "  OS: $($vm.StorageProfile.OsDisk.OsType)" "Info"
            Write-EnhancedLog "  ---" "Info"
        }
        
        # Check GitHub runner status via API (if token provided)
        if ($GitHubToken) {
            try {
                $tokenString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($GitHubToken))
                $headers = @{
                    "Authorization" = "token $tokenString"
                    "Accept" = "application/vnd.github.v3+json"
                }
                
                if ($GitHubRepository) {
                    $url = "https://api.github.com/repos/$GitHubOrganization/$GitHubRepository/actions/runners"
                } else {
                    $url = "https://api.github.com/orgs/$GitHubOrganization/actions/runners"
                }
                
                $response = Invoke-RestMethod -Uri $url -Headers $headers
                
                Write-EnhancedLog "GitHub Runner Status:" "Info"
                foreach ($runner in $response.runners) {
                    if ($runner.name -like "$RunnerGroupName-runner-*") {
                        $status = if ($runner.status -eq "online") { "Success" } else { "Warning" }
                        Write-EnhancedLog "  Runner: $($runner.name)" "Info"
                        Write-EnhancedLog "  Status: $($runner.status)" $status
                        Write-EnhancedLog "  OS: $($runner.os)" "Info"
                        Write-EnhancedLog "  Labels: $($runner.labels -join ', ')" "Info"
                        Write-EnhancedLog "  ---" "Info"
                    }
                }
                
            } catch {
                Write-EnhancedLog "Could not retrieve GitHub runner status: $($_.Exception.Message)" "Warning"
            }
        }
        
    } catch {
        Write-EnhancedLog "Failed to check runner status: $($_.Exception.Message)" "Error"
    }
}

# Scale runners
function Set-RunnerScale {
    param([int]$TargetCount)
    
    try {
        Write-EnhancedLog "Scaling runners to $TargetCount instances..." "Info"
        
        $currentRunners = Get-AzVM -ResourceGroupName $ResourceGroupName | Where-Object { $_.Name -like "$RunnerGroupName-runner-*" }
        $currentCount = $currentRunners.Count
        
        if ($TargetCount -gt $currentCount) {
            # Scale up
            $scaleUpCount = $TargetCount - $currentCount
            Write-EnhancedLog "Scaling up by $scaleUpCount runners..." "Info"
            
            # Create infrastructure if needed
            $infrastructure = New-RunnerInfrastructure -ErrorAction Stop
            
            # Deploy additional runners
            $script:RunnerCount = $scaleUpCount
            Deploy-GitHubRunners -Infrastructure $infrastructure
            
        } elseif ($TargetCount -lt $currentCount) {
            # Scale down
            $scaleDownCount = $currentCount - $TargetCount
            Write-EnhancedLog "Scaling down by $scaleDownCount runners..." "Info"
            
            $runnersToRemove = $currentRunners | Sort-Object Name | Select-Object -Last $scaleDownCount
            
            foreach ($runner in $runnersToRemove) {
                Write-EnhancedLog "Removing runner: $($runner.Name)" "Info"
                Remove-AzVM -ResourceGroupName $ResourceGroupName -Name $runner.Name -Force
            }
        } else {
            Write-EnhancedLog "No scaling required. Current count matches target: $TargetCount" "Info"
        }
        
        Write-EnhancedLog "Scaling operation completed" "Success"
        
    } catch {
        Write-EnhancedLog "Failed to scale runners: $($_.Exception.Message)" "Error"
        throw
    }
}

# Remove all runners
function Remove-RunnerInfrastructure {
    try {
        Write-EnhancedLog "Removing GitHub Actions runner infrastructure..." "Warning"
        
        # Remove all runner VMs
        $runnerVMs = Get-AzVM -ResourceGroupName $ResourceGroupName | Where-Object { $_.Name -like "$RunnerGroupName-runner-*" }
        
        foreach ($vm in $runnerVMs) {
            Write-EnhancedLog "Removing VM: $($vm.Name)" "Info"
            Remove-AzVM -ResourceGroupName $ResourceGroupName -Name $vm.Name -Force
        }
        
        # Optionally remove other infrastructure
        if ($VNetName) {
            $vnet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName -ErrorAction SilentlyContinue
            if ($vnet) {
                Write-EnhancedLog "Removing Virtual Network: $VNetName" "Info"
                Remove-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName -Force
            }
        }
        
        Write-EnhancedLog "Successfully removed runner infrastructure" "Success"
        
    } catch {
        Write-EnhancedLog "Failed to remove infrastructure: $($_.Exception.Message)" "Error"
        throw
    }
}

# Main execution
try {
    Write-EnhancedLog "Starting GitHub Actions Self-Hosted Runner Manager" "Info"
    Write-EnhancedLog "Action: $Action" "Info"
    Write-EnhancedLog "Runner Group: $RunnerGroupName" "Info"
    Write-EnhancedLog "Resource Group: $ResourceGroupName" "Info"
    
    # Ensure resource group exists
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-EnhancedLog "Creating resource group: $ResourceGroupName" "Info"
        $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag $Tags
        Write-EnhancedLog "Successfully created resource group" "Success"
    }
    
    switch ($Action) {
        "Deploy" {
            if (-not $GitHubOrganization) {
                throw "GitHubOrganization parameter is required for Deploy action"
            }
            
            $infrastructure = New-RunnerInfrastructure -ErrorAction Stop
            $runners = Deploy-GitHubRunners -Infrastructure $infrastructure
            
            if ($EnableAutoScaling) {
                Set-RunnerAutoScaling -ErrorAction Stop
            }
        }
        
        "Scale" {
            Set-RunnerScale -TargetCount $RunnerCount
        }
        
        "Monitor" {
            Get-RunnerStatus -ErrorAction Stop
        }
        
        "Status" {
            Get-RunnerStatus -ErrorAction Stop
        }
        
        "Update" {
            Write-EnhancedLog "Updating runners..." "Info"
            # This would typically involve updating the runner software
            # Implementation depends on specific update requirements
            Write-EnhancedLog "Update functionality needs to be implemented based on requirements" "Info"
        }
        
        "Remove" {
            Remove-RunnerInfrastructure -ErrorAction Stop
        }
        
        "Register" {
            if (-not $GitHubOrganization) {
                throw "GitHubOrganization parameter is required for Register action"
            }
            
            $registrationToken = Get-GitHubRegistrationToken -ErrorAction Stop
            Write-EnhancedLog "Registration token obtained: $($registrationToken.Substring(0, 10))..." "Success"
        }
    }
    
    Write-EnhancedLog "GitHub Actions Self-Hosted Runner Manager completed successfully" "Success"
    
} catch {
    Write-EnhancedLog "Tool execution failed: $($_.Exception.Message)" "Error"
    throw
}

#endregion

