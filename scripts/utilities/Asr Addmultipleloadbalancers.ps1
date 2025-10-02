#Requires -Version 7.4
#Requires -Modules Az.Compute, Az.Network, Az.Automation

<#
.SYNOPSIS
    ASR Add Multiple Load Balancers

.DESCRIPTION
    Azure Site Recovery automation runbook that attaches existing load balancers
    to the vNics of virtual machines in a Recovery Plan during failover.
    Supports multiple load balancers for different VMs.

.PARAMETER RecoveryPlanContext
    The recovery plan context object passed by Azure Site Recovery

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Original Author: krnese@microsoft.com - AzureCAT
    Version: 1.0
    Last Modified: March 20, 2017
    Requires appropriate permissions and modules
    Pre-requisites:
    - Load Balancers with backend pools
    - Complex automation variable containing VM-to-LoadBalancer mapping
#>

[CmdletBinding()]
param(
    [Parameter()]
    [Object]$RecoveryPlanContext
)

$ErrorActionPreference = "Stop"

try {
    Write-Output "Recovery Plan Context received:"
    Write-Output $RecoveryPlanContext

    if ($RecoveryPlanContext.FailoverDirection -ne "PrimaryToSecondary") {
        Write-Output "Failover Direction is not Azure, script will stop."
        return
    }

    # Extract VM information
    $vmInfo = $RecoveryPlanContext.VmMap | Get-Member |
        Where-Object MemberType -eq NoteProperty |
        Select-Object -ExpandProperty Name

    Write-Output "Found the following VMGuid(s):"
    Write-Output $vmInfo

    if ($vmInfo -is [system.array]) {
        Write-Output "Found multiple VMs in the Recovery Plan"
    }
    else {
        Write-Output "Found only a single VM in the Recovery Plan"
    }

    # Connect to Azure
    try {
        Write-Output "Logging in to Azure..."
        $connection = Get-AutomationConnection -Name "AzureRunAsConnection" -ErrorAction Stop

        $connectParams = @{
            ServicePrincipal = $true
            TenantId = $connection.TenantID
            ApplicationId = $connection.ApplicationID
            CertificateThumbprint = $connection.CertificateThumbprint
        }

        Connect-AzAccount @connectParams -ErrorAction Stop

        Write-Output "Setting subscription context..."
        Set-AzContext -SubscriptionId $connection.SubscriptionID -ErrorAction Stop
    }
    catch {
        $errorMessage = "Login to Azure subscription failed: $_"
        Write-Error $errorMessage
        throw
    }

    # Get Load Balancer configuration from automation variable
    try {
        Write-Output "Retrieving Load Balancer configuration for Recovery Plan: $($RecoveryPlanContext.RecoveryPlanName)"
        $rpVariable = Get-AutomationVariable -Name $RecoveryPlanContext.RecoveryPlanName -ErrorAction Stop

        # Convert from JSON if it's a string
        if ($rpVariable -is [string]) {
            $rpVariable = $rpVariable | ConvertFrom-Json
        }

        Write-Output "Load Balancer configuration retrieved:"
        Write-Output $rpVariable
    }
    catch {
        $errorMessage = "Failed to retrieve Load Balancer info from Automation variables: $_"
        Write-Error $errorMessage
        throw
    }

    # Associate VMs with their respective Load Balancers
    try {
        $vmMap = $RecoveryPlanContext.VmMap

        foreach ($vmId in $vmInfo) {
            $vm = $vmMap.$vmId

            # Get VM-specific load balancer details
            $vmDetails = $rpVariable.$vmId

            # Validate all required information is present
            if (($null -eq $vm) -or
                ($null -eq $vm.ResourceGroupName) -or
                ($null -eq $vm.RoleName) -or
                ($null -eq $vmDetails) -or
                ($null -eq $vmDetails.ResourceGroupName) -or
                ($null -eq $vmDetails.LBName)) {

                Write-Warning "Skipping VM $vmId due to missing configuration"
                continue
            }

            Write-Output "`nProcessing VM:"
            Write-Output "  Resource Group: $($vm.ResourceGroupName)"
            Write-Output "  VM Name: $($vm.RoleName)"
            Write-Output "  Load Balancer: $($vmDetails.LBName)"
            Write-Output "  LB Resource Group: $($vmDetails.ResourceGroupName)"

            # Get the Load Balancer
            $loadBalancer = Get-AzLoadBalancer -ResourceGroupName $vmDetails.ResourceGroupName `
                -Name $vmDetails.LBName `
                -ErrorAction Stop

            if ($loadBalancer.BackendAddressPools.Count -eq 0) {
                Write-Warning "Load Balancer '$($vmDetails.LBName)' has no backend pools"
                continue
            }

            # Get VM details
            $azureVm = Get-AzVM -ResourceGroupName $vm.ResourceGroupName `
                -Name $vm.RoleName `
                -ErrorAction Stop

            # Check availability set
            if ($azureVm.AvailabilitySetReference) {
                Write-Output "  Availability Set is present for VM: $($azureVm.Name)"
            }
            else {
                Write-Output "  No Availability Set is present for VM: $($azureVm.Name)"
            }

            # Get and update network interface
            $nicResourceId = $azureVm.NetworkProfile.NetworkInterfaces[0].Id
            $nicResource = Get-AzResource -ResourceId $nicResourceId -ErrorAction Stop
            $nic = Get-AzNetworkInterface -Name $nicResource.Name `
                -ResourceGroupName $nicResource.ResourceGroupName `
                -ErrorAction Stop

            # Add to load balancer backend pool
            $nic.IpConfigurations[0].LoadBalancerBackendAddressPools.Add($loadBalancer.BackendAddressPools[0])
            Set-AzNetworkInterface -NetworkInterface $nic -ErrorAction Stop

            Write-Output "  Successfully configured Load Balancing for VM: $($azureVm.Name)"
        }

        Write-Output "`nLoad Balancer association completed for all configured VMs"
    }
    catch {
        $errorMessage = "Failed to associate VM with Load Balancer: $_"
        Write-Error $errorMessage
        throw
    }
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}