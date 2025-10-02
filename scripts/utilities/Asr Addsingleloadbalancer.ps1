#Requires -Version 7.4
#Requires -Modules Az.Compute, Az.Network, Az.Automation

<#
.SYNOPSIS
    ASR Add Single Load Balancer

.DESCRIPTION
    Azure Site Recovery automation runbook that attaches an existing load balancer
    to the vNics of virtual machines in a Recovery Plan during failover

.PARAMETER RecoveryPlanContext
    The recovery plan context object passed by Azure Site Recovery

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Original Author: krnese@microsoft.com - AzureCAT
    Version: 1.0
    Last Modified: March 20, 2017
    Requires appropriate permissions and modules
    Pre-requisites:
    - A Load Balancer with a backend pool
    - Automation variables for Load Balancer name and Resource Group
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
        $vmInfo = $vmInfo[0]
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

    # Get Load Balancer configuration from automation variables
    try {
        $lbNameVariable = $RecoveryPlanContext.RecoveryPlanName + "-LB"
        $lbRgVariable = $RecoveryPlanContext.RecoveryPlanName + "-LBRG"

        Write-Output "Retrieving automation variables: $lbNameVariable, $lbRgVariable"
        $lbName = Get-AutomationVariable -Name $lbNameVariable -ErrorAction Stop
        $lbRgName = Get-AutomationVariable -Name $lbRgVariable -ErrorAction Stop

        Write-Output "Load Balancer Name: $lbName"
        Write-Output "Load Balancer Resource Group: $lbRgName"

        $loadBalancer = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $lbRgName -ErrorAction Stop
        Write-Output "Successfully retrieved Load Balancer configuration"
    }
    catch {
        $errorMessage = "Failed to retrieve Load Balancer info from Automation variables: $_"
        Write-Error $errorMessage
        throw
    }

    # Associate VMs with Load Balancer
    try {
        $vmMap = $RecoveryPlanContext.VmMap

        foreach ($vmId in $vmInfo) {
            $vm = $vmMap.$vmId
            Write-Output "`nProcessing VM:"
            Write-Output "  Resource Group: $($vm.ResourceGroupName)"
            Write-Output "  VM Name: $($vm.RoleName)"

            # Get VM details
            $azureVm = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.RoleName -ErrorAction Stop

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
            $nic = Get-AzNetworkInterface -Name $nicResource.Name -ResourceGroupName $nicResource.ResourceGroupName -ErrorAction Stop

            # Add to load balancer backend pool
            if ($loadBalancer.BackendAddressPools.Count -gt 0) {
                $nic.IpConfigurations[0].LoadBalancerBackendAddressPools.Add($loadBalancer.BackendAddressPools[0])
                Set-AzNetworkInterface -NetworkInterface $nic -ErrorAction Stop
                Write-Output "  Successfully configured Load Balancing for VM: $($azureVm.Name)"
            }
            else {
                Write-Warning "  No backend pools found in Load Balancer"
            }
        }

        Write-Output "`nLoad Balancer association completed for all VMs"
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