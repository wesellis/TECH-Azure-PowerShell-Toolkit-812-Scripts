#Requires -Version 7.4
#Requires -Modules Az.Compute, Az.Network, Az.Automation

<#
.SYNOPSIS
    ASR Add Single NSG and Public IP

.DESCRIPTION
    Azure Site Recovery automation workflow that creates Public IP addresses
    and optionally attaches Network Security Groups to failed over VMs during
    test failover operations

.PARAMETER RecoveryPlanContext
    The recovery plan context object passed by Azure Site Recovery

.PARAMETER AutomationAccountName
    Name of the Azure Automation account

.PARAMETER AutomationAccountRg
    Resource group containing the Automation account

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Original Author: RuturajD@microsoft.com
    Version: 1.0
    Last Modified: January 27, 2017
    Requires appropriate permissions and modules
    NSG configuration uses automation variables: <RecoveryPlanName>-NSG and <RecoveryPlanName>-NSGRG
#>

workflow ASR-AddSingleNSGPublicIp {
    [CmdletBinding()]
    param(
        [Parameter()]
        [Object]$RecoveryPlanContext,

        [Parameter(Mandatory = $true)]
        [string]$AutomationAccountName,

        [Parameter(Mandatory = $true)]
        [string]$AutomationAccountRg
    )

    $ErrorActionPreference = "Stop"
    $ConnectionName = "AzureRunAsConnection"

    # Only execute for test failovers
    if ($RecoveryPlanContext.FailoverType -ne "Test") {
        Write-Output "This script only runs during test failovers. Exiting."
        return
    }

    try {
        Write-Output "Getting automation connection..."
        $servicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName -ErrorAction Stop

        Write-Output "Logging in to Azure..."
        $connectParams = @{
            ServicePrincipal = $true
            TenantId = $servicePrincipalConnection.TenantId
            ApplicationId = $servicePrincipalConnection.ApplicationId
            CertificateThumbprint = $servicePrincipalConnection.CertificateThumbprint
        }

        Add-AzAccount @connectParams -ErrorAction Stop

        Write-Output "Setting subscription context..."
        Select-AzSubscription -SubscriptionId $servicePrincipalConnection.SubscriptionID -ErrorAction Stop
    }
    catch {
        if (!$servicePrincipalConnection) {
            $errorMessage = "Connection '$ConnectionName' not found."
            Write-Error $errorMessage
            throw $errorMessage
        }
        else {
            Write-Error "Failed to connect to Azure: $_"
            throw
        }
    }

    Write-Output "Recovery Plan Context:"
    Write-Output $RecoveryPlanContext

    # Try to get NSG configuration from automation variables
    $nsgName = $null
    $nsgRgName = $null

    try {
        $nsgNameVariable = $RecoveryPlanContext.RecoveryPlanName + "-NSG"
        $nsgRgVariable = $RecoveryPlanContext.RecoveryPlanName + "-NSGRG"

        $nsgName = Get-AzAutomationVariable -AutomationAccountName $AutomationAccountName `
            -ResourceGroupName $AutomationAccountRg `
            -Name $nsgNameVariable `
            -ErrorAction SilentlyContinue

        $nsgRgName = Get-AzAutomationVariable -AutomationAccountName $AutomationAccountName `
            -ResourceGroupName $AutomationAccountRg `
            -Name $nsgRgVariable `
            -ErrorAction SilentlyContinue

        if ($nsgName -and $nsgRgName) {
            Write-Output "NSG configuration found: $nsgName in resource group $nsgRgName"
        }
        else {
            Write-Output "No NSG configuration found. Will only create public IPs."
        }
    }
    catch {
        Write-Warning "Could not retrieve NSG variables: $_"
    }

    # Get VM information from recovery plan
    $vmInfo = $RecoveryPlanContext.VmMap | Get-Member |
        Where-Object MemberType -eq NoteProperty |
        Select-Object -ExpandProperty Name

    Write-Output "Found VMs:"
    Write-Output $vmInfo

    $vmMap = $RecoveryPlanContext.VmMap

    foreach ($vmId in $vmInfo) {
        $vm = $vmMap.$vmId

        if ((-not ($null -eq $vm)) -and
            (-not ($null -eq $vm.ResourceGroupName)) -and
            (-not ($null -eq $vm.RoleName))) {

            Write-Output "`nProcessing VM:"
            Write-Output "  Resource Group: $($vm.ResourceGroupName)"
            Write-Output "  VM Name: $($vm.RoleName)"

            InlineScript {
                try {
                    # Get VM details
                    $azureVm = Get-AzVM -ResourceGroupName $Using:vm.ResourceGroupName `
                        -Name $Using:vm.RoleName `
                        -ErrorAction Stop

                    # Get network interface
                    $nicResourceId = $azureVm.NetworkProfile.NetworkInterfaces[0].Id
                    $nicResource = Get-AzResource -ResourceId $nicResourceId -ErrorAction Stop
                    $nic = Get-AzNetworkInterface -Name $nicResource.Name `
                        -ResourceGroupName $nicResource.ResourceGroupName `
                        -ErrorAction Stop

                    # Create and assign public IP
                    $pipParams = @{
                        Name = "$($Using:vm.RoleName)-pip"
                        ResourceGroupName = $Using:vm.ResourceGroupName
                        Location = $azureVm.Location
                        AllocationMethod = "Dynamic"
                        ErrorAction = "Stop"
                    }
                    $publicIP = New-AzPublicIpAddress @pipParams

                    $nic.IpConfigurations[0].PublicIpAddress = $publicIP
                    Write-Output "Assigned public IP to VM: $($Using:vm.RoleName)"

                    # Attach NSG if configured
                    if ($Using:nsgName -and $Using:nsgRgName) {
                        $nsg = Get-AzNetworkSecurityGroup -Name $Using:nsgName `
                            -ResourceGroupName $Using:nsgRgName `
                            -ErrorAction Stop

                        $nic.NetworkSecurityGroup = $nsg
                        Write-Output "Attached NSG '$($Using:nsgName)' to VM: $($Using:vm.RoleName)"
                    }

                    # Apply changes to network interface
                    Set-AzNetworkInterface -NetworkInterface $nic -ErrorAction Stop
                    Write-Output "Successfully configured networking for VM: $($Using:vm.RoleName)"
                }
                catch {
                    Write-Error "Failed to configure VM $($Using:vm.RoleName): $_"
                    throw
                }
            }
        }
        else {
            Write-Warning "Skipping VM due to missing information"
        }
    }

    Write-Output "`nPublic IP and NSG configuration completed for all VMs"
}