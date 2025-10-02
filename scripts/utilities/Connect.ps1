#Requires -Version 7.4
#Requires -Modules Az.Resources, Az.Accounts, Az.ConnectedMachine, Az.StackHCI

<#
.SYNOPSIS
    Connect Azure Arc Server

.DESCRIPTION
    Azure automation script to connect a server to Azure Arc

.PARAMETER UserName
    Username for remote connection

.PARAMETER AuthType
    Authentication type for remote connection

.PARAMETER ip
    IP address of the target server

.PARAMETER port
    Port number for remote connection

.PARAMETER SubscriptionId
    Azure subscription ID

.PARAMETER ResourceGroupName
    Azure resource group name

.PARAMETER region
    Azure region for Arc deployment

.PARAMETER tenant
    Azure tenant ID

.PARAMETER ServicePrincipalId
    Service principal ID for authentication

.PARAMETER ExpandC
    Whether to expand C: drive

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$UserName,

    [Parameter(Mandatory = $false)]
    [string]$AuthType = "Default",

    [Parameter(Mandatory = $true)]
    [string]$ip,

    [Parameter(Mandatory = $false)]
    [int]$port = 5985,

    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$region,

    [Parameter(Mandatory = $true)]
    [string]$tenant,

    [Parameter(Mandatory = $true)]
    [string]$ServicePrincipalId,

    [Parameter(Mandatory = $false)]
    [switch]$ExpandC
)

$ErrorActionPreference = 'Stop'

function Install-ModuleIfMissing {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [string]$Repository = 'PSGallery',

        [switch]$Force,

        [switch]$AllowClobber
    )

    $module = Get-Module -Name $Name -ListAvailable

    if (!$module) {
        Write-Output "Installing module $Name"
        Install-Module -Name $Name -Repository $Repository -Force:$Force -AllowClobber:$AllowClobber
    }
    else {
        Write-Output "Module $Name is already installed"
    }
}

Write-Output "Starting Azure Arc server connection process..."

# Enable CredSSP if specified
if ($AuthType -eq "CredSSP") {
    try {
        Write-Output "Enabling CredSSP authentication..."
        Enable-WSManCredSSP -Role Client -DelegateComputer $ip -Force
    }
    catch {
        Write-Warning "Enable-WSManCredSSP failed: $_"
    }
}

# Get credentials securely
$secpasswd = Read-Host -Prompt "Enter password for $UserName" -AsSecureString
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList ".\$UserName", $secpasswd

# Get service principal secret
$ServicePrincipalSecret = Read-Host -Prompt "Enter Service Principal secret" -AsSecureString

$maxRetries = 6
$retryCount = 0
$success = $false

while ($retryCount -lt $maxRetries -and !$success) {
    try {
        Write-Output "Connection attempt $($retryCount + 1) of $maxRetries"

        # Create remote session
        $sessionParams = @{
            ComputerName = $ip
            Port = $port
            Authentication = $AuthType
            Credential = $cred
        }
        $session = New-PSSession @sessionParams

        # Execute Arc connection script on remote machine
        Invoke-Command -Session $session -ScriptBlock {
            Param (
                $SubscriptionId,
                $ResourceGroupName,
                $region,
                $tenant,
                $ServicePrincipalId,
                $ServicePrincipalSecret,
                $ExpandC
            )

            $ErrorActionPreference = 'Stop'

            # Expand C: drive if requested
            if ($ExpandC) {
                $drive_letter = "C"
                $size = (Get-PartitionSupportedSize -DriveLetter $drive_letter)
                if ($size.SizeMax -gt (Get-Partition -DriveLetter $drive_letter).Size) {
                    Write-Output "Resizing volume C:"
                    Resize-Partition -DriveLetter $drive_letter -Size $size.SizeMax
                }
            }

            # Validate BITS is working
            Write-Output "Validating BITS service..."
            $job = Start-BitsTransfer -Source https://aka.ms -Destination $env:TEMP -TransferType Download -Asynchronous
            $timeout = 30
            $count = 0

            while ($job.JobState -ne "Transferred" -and $count -lt $timeout) {
                if ($job.JobState -eq "TransientError") {
                    throw "BITS transfer failed with transient error"
                }
                Start-Sleep -Seconds 6
                $count++
            }

            if ($count -ge $timeout) {
                throw "BITS transfer timed out after 3 minutes. Job state: $($job.JobState)"
            }

            Complete-BitsTransfer -BitsJob $job
            Remove-BitsTransfer -BitsJob $job

            # Create service principal credential
            $spCreds = [System.Management.Automation.PSCredential]::new($ServicePrincipalId, $ServicePrincipalSecret)

            # Install required modules
            Write-Output "Installing required modules..."
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false

            # Function to install module if missing
            function Install-ModuleIfMissing {
                param($Name, $RequiredVersion)
                if (!(Get-Module -Name $Name -ListAvailable)) {
                    if ($RequiredVersion) {
                        Install-Module -Name $Name -RequiredVersion $RequiredVersion -Force -AllowClobber
                    }
                    else {
                        Install-Module -Name $Name -Force -AllowClobber
                    }
                }
            }

            Install-ModuleIfMissing -Name Az
            Install-ModuleIfMissing -Name AzSHCI.ARCInstaller
            Install-ModuleIfMissing -Name Az.StackHCI -RequiredVersion 2.2.3
            Install-ModuleIfMissing -Name AzStackHci.EnvironmentChecker
            Install-ModuleIfMissing -Name Az.Accounts
            Install-ModuleIfMissing -Name Az.ConnectedMachine
            Install-ModuleIfMissing -Name Az.Resources

            # Connect to Azure
            Write-Output "Connecting to Azure..."
            Connect-AzAccount -Subscription $SubscriptionId -Tenant $tenant -Credential $spCreds -ServicePrincipal

            # Get Azure context details
            $id = (Get-AzContext).Tenant.Id
            $token = (Get-AzAccessToken).Token
            $accountid = (Get-AzContext).Account.Id

            # Initialize Azure Stack HCI Arc
            Write-Output "Initializing Azure Stack HCI Arc..."
            Invoke-AzStackHciArcInitialization -SubscriptionID $SubscriptionId `
                                              -ResourceGroup $ResourceGroupName `
                                              -TenantID $id `
                                              -Region $region `
                                              -Cloud "AzureCloud" `
                                              -ArmAccessToken $token `
                                              -AccountID $accountid

            $ExitCode = $LASTEXITCODE

            if ($ExitCode -eq 0) {
                Write-Output "Arc server connected successfully!"
            }
            else {
                throw "Arc server connection failed with exit code: $ExitCode"
            }

            # Wait for LCM extension to be ready
            Write-Output "Waiting for Lifecycle Manager extension..."
            $ready = $false
            $maxWait = 10

            while (!$ready -and $maxWait -gt 0) {
                Connect-AzAccount -Subscription $SubscriptionId -Tenant $tenant -Credential $spCreds -ServicePrincipal

                $extension = Get-AzConnectedMachineExtension -Name "AzureEdgeLifecycleManager" `
                                                            -ResourceGroup $ResourceGroupName `
                                                            -MachineName $env:COMPUTERNAME `
                                                            -SubscriptionId $SubscriptionId `
                                                            -ErrorAction SilentlyContinue

                if ($extension.ProvisioningState -eq "Succeeded") {
                    $ready = $true
                    Write-Output "LCM extension is ready"
                }
                else {
                    Write-Output "Waiting for LCM extension to be ready... ($maxWait attempts remaining)"
                    Start-Sleep -Seconds 30
                    $maxWait--
                }
            }

            if (!$ready) {
                Write-Warning "LCM extension did not become ready within timeout period"
            }

        } -ArgumentList $SubscriptionId, $ResourceGroupName, $region, $tenant, $ServicePrincipalId, $ServicePrincipalSecret, $ExpandC.IsPresent

        $success = $true
        Write-Output "Arc server connection completed successfully"
    }
    catch {
        Write-Error "Error in attempt $($retryCount + 1): $_"
        $retryCount++

        if ($retryCount -lt $maxRetries) {
            Write-Output "Waiting 10 minutes before retry..."
            Start-Sleep -Seconds 600
        }
    }
    finally {
        if ($session) {
            Remove-PSSession -Session $session
        }
    }
}

if (!$success) {
    throw "Failed to connect Arc server after $maxRetries retries."
}