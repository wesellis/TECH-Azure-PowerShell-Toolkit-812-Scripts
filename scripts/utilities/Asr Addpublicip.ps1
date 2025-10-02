#Requires -Version 7.4
#Requires -Modules Az.Compute, Az.Network

<#
.SYNOPSIS
    ASR Add Public IP

.DESCRIPTION
    Azure Site Recovery automation runbook that creates and assigns Public IP addresses
    for failed over VMs during disaster recovery operations

.PARAMETER RecoveryPlanContext
    The recovery plan context object passed by Azure Site Recovery

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Original Author: krnese@microsoft.com
    Version: 1.0
    Last Modified: March 20, 2017
    Requires appropriate permissions and modules
    Add as post-action in boot up group for VMs requiring public IPs
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

    if ($RecoveryPlanContext.FailoverDirection -ne 'PrimaryToSecondary') {
        Write-Output "Script is ignored since Azure is not the target"
        return
    }

    # Extract VM information from recovery plan context
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

    $resourceGroupName = $RecoveryPlanContext.VmMap.$vmInfo.ResourceGroupName
    Write-Output "Resource Group: $resourceGroupName"

    # Connect to Azure using Run As Connection
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

    # Get VMs within the Resource Group
    try {
        $vms = Get-AzVM -ResourceGroupName $resourceGroupName -ErrorAction Stop
        Write-Output "Found the following VMs:"
        $vms | ForEach-Object { Write-Output "  - $($_.Name)" }
    }
    catch {
        $errorMessage = "Failed to find any VMs in Resource Group '$resourceGroupName': $_"
        Write-Error $errorMessage
        throw
    }

    # Add public IP to each VM
    try {
        foreach ($vm in $vms) {
            Write-Output "Processing VM: $($vm.Name)"

            # Get the primary network interface
            $nicResourceId = $vm.NetworkProfile.NetworkInterfaces[0].Id
            $nicResource = Get-AzResource -ResourceId $nicResourceId -ErrorAction Stop
            $nic = Get-AzNetworkInterface -Name $nicResource.Name -ResourceGroupName $nicResource.ResourceGroupName -ErrorAction Stop

            # Create public IP address
            $pipParams = @{
                Name = "$($vm.Name)-pip"
                ResourceGroupName = $resourceGroupName
                Location = $vm.Location
                AllocationMethod = "Dynamic"
                ErrorAction = "Stop"
            }
            $publicIP = New-AzPublicIpAddress @pipParams

            # Associate public IP with network interface
            $nic.IpConfigurations[0].PublicIpAddress = $publicIP
            Set-AzNetworkInterface -NetworkInterface $nic -ErrorAction Stop

            Write-Output "Successfully added public IP address to VM: $($vm.Name)"
        }

        Write-Output "`nOperation completed successfully for all VMs"
    }
    catch {
        $errorMessage = "Failed to add public IP address to VM: $_"
        Write-Error $errorMessage
        throw
    }
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}