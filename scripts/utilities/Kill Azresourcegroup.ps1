#Requires -Version 7.4
#Requires -Modules Az.Network
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Kill Azresourcegroup

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
This script attempts to remove a resource group by first removing all the things that prevent removing resource groups
- Locks, backup protection, geo-pairing, etc.
It is a living script as we keep finding more cases... if you find one please add it.
    $ErrorActionPreference = "Stop"
[CmdletBinding()
try {
]
param(
    [string][Parameter(mandatory = $true)] $ResourceGroupName
)
Write-Output "Kill: $ResourceGroupName"
if ((Get-AzContext).Environment.Name -eq "AzureUSGovernment" ) {
    Write-Output "Running in FF..."
    $deployment = Get-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName
    $ops = Get-AzResourceGroupDeploymentOperation -ResourceGroupName $ResourceGroupName -DeploymentName $deployment.DeploymentName
    foreach ($op in $ops) {
        if ($op.TargetResource -like " */Microsoft.Scheduler/jobCollections/*" ) {
            Write-Output "Found operation with target resource: $($op.TargetResource)"
            exit
        }
    }
}
    $SubscriptionId = $(Get-AzContext).Subscription.Id
Get-AzResourceLock -ResourceGroupName $ResourceGroupName -Verbose | Remove-AzResourceLock -Force -verbose
    $vaults = Get-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName -Verbose
foreach ($vault in $vaults) {
    Write-Output "Recovery Services Vaults..."
    & " $PSScriptRoot\Kill-AzRecoveryServicesVault.ps1" -ResourceGroup $ResourceGroupName -VaultName $vault.Name
}
    $oms = Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceType "Microsoft.OperationsManagement/solutions"
foreach($o in $oms){
    $r = Invoke-AzRestMethod -Method "GET" -Path " $($o.id)?api-version=2015-11-01-preview" -Verbose
    $ResponseBody = $r.Content | ConvertFrom-JSon -Depth 30
    $body = @{}
    $properties = @{}
    $properties['workSpaceResourceId'] = $ResponseBody.properties.workSpaceResourceId # tranfer the workspaceID
    $properties['containedResources'] = @() # empty out arrays
    $properties['referencedResources'] = @()
    $plan = $ResponseBody.plan
    $body['plan'] = $plan # transfer the plan
    $body['properties'] = $properties
    $body['location'] = $ResponseBody.location # transfer the location
    $JsonBody = $body | ConvertTo-Json -Depth 30
    Invoke-AzRestMethod -Method "PUT" -Path " $($o.id)?api-version=2015-11-01-preview" -Payload $JsonBody -Verbose
}
if ($(Get-Module -ListAvailable Az.DataProtection) -eq $null) {
    Write-Output "Installing Az.DataProtection module..."
    Install-Module Az.DataProtection -Force -AllowClobber
}
    $vaults = Get-AzDataProtectionBackupVault -ResourceGroupName $ResourceGroupName
foreach ($vault in $vaults) {
    Write-Output "Data Protection Vault: $($vault.name)"
    $BackupInstances = Get-AzDataProtectionBackupInstance -ResourceGroupName $ResourceGroupName -VaultName $vault.Name
    foreach ($bi in $BackupInstances) {
        Write-Output "Removing Backup Instance: $($bi.name)"
        Remove-AzDataProtectionBackupInstance -ResourceGroupName $ResourceGroupName -VaultName $vault.Name -Name $bi.Name
    }
    $BackupPolicies = Get-AzDataProtectionBackupPolicy -ResourceGroupName $ResourceGroupName -VaultName $vault.Name
    foreach ($bp in $BackupPolicies) {
        Write-Output "Removing backup policy: $($bp.name)"
        Remove-AzDataProtectionBackupPolicy -ResourceGroupName $ResourceGroupName -VaultName $vault.name -Name $bp.Name
    }
}
    $EventHubs = Get-AzEventHubNamespace -ResourceGroupName $ResourceGroupName -Verbose
foreach ($EventHub in $EventHubs) {
    $DrConfig = Get-AzEventHubGeoDRConfiguration -ResourceGroupName $ResourceGroupName -Namespace $EventHub.Name -Verbose
    $DrConfig
    if ($DrConfig) {
        if ($DrConfig.Role.ToString() -eq "Primary" ) {
            Write-Output "EventHubs Break Pairing... (primary)"
            Set-AzEventHubGeoDRConfigurationBreakPair -ResourceGroupName $ResourceGroupName -Namespace $EventHub.Name -Name $DrConfig.Name
        }
    }
}
foreach ($EventHub in $EventHubs) {
    Write-Output "EventHubs remove DR config..."
    $DrConfig = Get-AzEventHubGeoDRConfiguration -ResourceGroupName $ResourceGroupName -Namespace $EventHub.Name -Verbose
    Remove-AzEventHubGeoDRConfiguration -ResourceGroupName $ResourceGroupName -Namespace $EventHub.Name $DrConfig.Name -Verbose
}
    $ServiceBusNamespaces = Get-AzServiceBusNamespace -ResourceGroupName $ResourceGroupName -Verbose
foreach ($s in $ServiceBusNamespaces) {
    Write-Output "ServiceBus Break pairing..."
    $DrConfig = Get-AzServiceBusGeoDRConfiguration -ResourceGroupName $ResourceGroupName -Namespace $s.Name
    $DrConfig
    if ($DrConfig) {
        if ($DrConfig.Role.ToString() -eq "Primary" ) {
            Write-Output "ServiceBus Break pairing... (primary)"
            Set-AzServiceBusGeoDRConfigurationBreakPair -ResourceGroupName $ResourceGroupName -Namespace $s.Name -Name $DrConfig.Name
        }
    }
}
foreach ($s in $ServiceBusNamespaces) {
    $DrConfig = Get-AzServiceBusGeoDRConfiguration -ResourceGroupName $ResourceGroupName -Namespace $s.Name
    if ($DrConfig) {
        Write-Output "Service Bus remove DR config..."
        Remove-AzServiceBusGeoDRConfiguration -ResourceGroupName $ResourceGroupName -Namespace $s.Name -Name $DrConfig.Name -Verbose
    }
}
foreach ($s in $ServiceBusNamespaces) {
    $MigrationConfig = Get-AzServiceBusMigration -ResourceGroupName $ResourceGroupName -Name $s.Name -ErrorAction SilentlyContinue
    if ($MigrationConfig) {
        Write-Output "Service Bus remove migration..."
        Remove-AzServiceBusMigration -ResourceGroupName $ResourceGroupName -Name $s.Name -Verbose
    }
}
    $vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $rg -Name $VnetName
    $subnets = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet
foreach($subnet in $subnets){
    Remove-AzureRMResource -ResourceId " $($subnet.id)/providers/Microsoft.ContainerInstance/serviceAssociationLinks/default" -Force
}
    $webapps = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Verbose
foreach ($w in $webapps) {
    Write-Output "WebApp: $($w.Name)"
    $slots = Get-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $w.Name -Verbose
    foreach ($s in $slots) {
    $SlotName = $($s.Name).Split('/')[1]
        $r = Invoke-AzRestMethod -Method "GET" -Path "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$($w.name)/slots/$SlotName/virtualNetworkConnections?api-version=2020-10-01"
        Write-Output "Slot: $SlotName / $($r.StatusCode)"
        if ($r.StatusCode -eq '200') {
    $r | Out-String
            Invoke-AzRestMethod -Method "DELETE" -Path "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$($w.name)/slots/$SlotName/networkConfig/virtualNetwork?api-version=2020-10-01" -Verbose
        }
    }
    $r = Invoke-AzRestMethod -Method "GET" -Path "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$($w.name)/virtualNetworkConnections?api-version=2020-10-01"
    Write-Output "Prod Slot: $($r.StatusCode)"
    if ($r.StatusCode -eq '200') {
    $r | Out-String
        Invoke-AzRestMethod -Method "DELETE" -Path "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$($w.name)/networkConfig/virtualNetwork?api-version=2020-10-01" -Verbose
    }
}
    $RedisCaches = Get-AzRedisCache -ResourceGroupName $ResourceGroupName -Verbose
foreach ($r in $RedisCaches) {
    Write-Output "Redis..."
    $link = Get-AzRedisCacheLink -Name $r.Name
    if ($link) {
        Write-Output "Remove Redis Link..."
    $link | Remove-AzRedisCacheLink -Verbose
    }
}
    $vnets = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Verbose
foreach ($vnet in $vnets) {
    Write-Output "Vnet Delegation..."
    foreach ($subnet in $vnet.Subnets) {
    $delegations = Get-AzDelegation -Subnet $subnet -Verbose
        foreach ($d in $delegations) {
            Write-Output "Removing VNet Delegation: $($d.name)"
            Remove-AzDelegation -Name $d.Name -Subnet $subnet -Verbose
        }
    }
}
    $VHubs = Get-AzVirtualHub -ResourceGroupName $ResourceGroupName -Verbose
foreach ($h in $VHubs) {
    Write-Output "Checking for ipConfigurations in vhub: $($h.name)"
    $r = Invoke-AzRestMethod -Method "GET" -path "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Network/virtualHubs/$($h.name)/ipConfigurations?api-version=2020-11-01"
    $r | Out-String
    $IpConfigs = $($r.Content | ConvertFrom-Json -Depth 50).Value
    $IpConfigs | Out-String
    foreach ($config in $IpConfigs) {
        Write-Output "Attempting to remove: $($config.name)"
        $r = Invoke-AzRestMethod -Method DELETE -Path " $($config.id)?api-version=2020-11-01"
    $r | Out-String
        if ($r.StatusCode -like " 20*" ) {
            do {
                Start-Sleep 60 -Verbose
                $r = Invoke-AzRestMethod -Method GET -Path " $($config.id)?api-version=2020-11-01"
    $r | Out-String
            } until ($r.StatusCode -eq " 404" )
        }
    }
}
    $PrivateLinks = Get-AzPrivateLinkService -ResourceGroupName $ResourceGroupName
foreach ($pl in $PrivateLinks) {
    Write-Output "Checking Private Links for endpoint connections..."
    $connections = Get-AzPrivateEndpointConnection -ResourceGroupName $ResourceGroupName -ServiceName $pl.Name
    foreach ($c in $connections) {
        Write-Output "Removing PrivateLink Endpoint Connection: $($c.name)"
        Remove-AzPrivateEndpointConnection -ResourceGroupName $ResourceGroupName -ServiceName $pl.Name -Name $c.Name -Force
    }
}
Remove-AzResourceGroup -Force -Verbose -Name $ResourceGroupName
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
