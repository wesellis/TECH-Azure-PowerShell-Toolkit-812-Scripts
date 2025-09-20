#Requires -Version 7.0
#Requires -Modules Az.Network
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Kill Azresourcegroup

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
This script attempts to remove a resource group by first removing all the things that prevent removing resource groups
- Locks, backup protection, geo-pairing, etc.
It is a living script as we keep finding more cases... if you find one please add it.
[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [string][Parameter(mandatory = $true)] $ResourceGroupName
)
Write-Host "Kill: $resourceGroupName"
if ((Get-AzContext).Environment.Name -eq "AzureUSGovernment" ) {
    Write-Host "Running in FF..."
    $deployment = Get-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName
    $ops = Get-AzResourceGroupDeploymentOperation -ResourceGroupName $ResourceGroupName -DeploymentName $deployment.DeploymentName
    foreach ($op in $ops) {
        if ($op.TargetResource -like " */Microsoft.Scheduler/jobCollections/*" ) {
            Write-Host "Found operation with target resource: $($op.TargetResource)"
            exit
        }
    }
}
$subscriptionId = $(Get-AzContext).Subscription.Id
Get-AzResourceLock -ResourceGroupName $ResourceGroupName -Verbose | Remove-AzResourceLock -Force -verbose
$vaults = Get-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName -Verbose
foreach ($vault in $vaults) {
    Write-Host "Recovery Services Vaults..."
    & " $PSScriptRoot\Kill-AzRecoveryServicesVault.ps1" -ResourceGroup $ResourceGroupName -VaultName $vault.Name
}
$oms = Get-AzResource -ResourceGroupName $ResourceGroupName -ResourceType "Microsoft.OperationsManagement/solutions"
foreach($o in $oms){
    # need to invoke REST to get the properties body
    $r = Invoke-AzRestMethod -Method "GET" -Path " $($o.id)?api-version=2015-11-01-preview" -Verbose
    $responseBody = $r.Content | ConvertFrom-JSon -Depth 30
    $body = @{}
    $properties = @{}
    $properties['workSpaceResourceId'] = $responseBody.properties.workSpaceResourceId # tranfer the workspaceID
    $properties['containedResources'] = @() # empty out arrays
    $properties['referencedResources'] = @()
    $plan = $responseBody.plan
    $body['plan'] = $plan # transfer the plan
    $body['properties'] = $properties
    $body['location'] = $responseBody.location # transfer the location
    $jsonBody = $body | ConvertTo-Json -Depth 30
    # Write-Host $jsonBody
    # re-PUT the resource with the empty properties body (arrays)
    Invoke-AzRestMethod -Method "PUT" -Path " $($o.id)?api-version=2015-11-01-preview" -Payload $jsonBody -Verbose
}
if ($(Get-Module -ListAvailable Az.DataProtection) -eq $null) {
    Write-Host "Installing Az.DataProtection module..."
    Install-Module Az.DataProtection -Force -AllowClobber #| Out-Null # this is way too noisy for some reason
}
$vaults = Get-AzDataProtectionBackupVault -ResourceGroupName $ResourceGroupName #-Verbose
foreach ($vault in $vaults) {
    Write-Host "Data Protection Vault: $($vault.name)"
    $backupInstances = Get-AzDataProtectionBackupInstance -ResourceGroupName $ResourceGroupName -VaultName $vault.Name
    foreach ($bi in $backupInstances) {
        Write-Host "Removing Backup Instance: $($bi.name)"
        Remove-AzDataProtectionBackupInstance -ResourceGroupName $ResourceGroupName -VaultName $vault.Name -Name $bi.Name
    }
    $backupPolicies = Get-AzDataProtectionBackupPolicy -ResourceGroupName $ResourceGroupName -VaultName $vault.Name
    foreach ($bp in $backupPolicies) {
        Write-Host "Removing backup policy: $($bp.name)"
        Remove-AzDataProtectionBackupPolicy -ResourceGroupName $ResourceGroupName -VaultName $vault.name -Name $bp.Name
    }
}
$eventHubs = Get-AzEventHubNamespace -ResourceGroupName $ResourceGroupName -Verbose  #-Name $VaultName
foreach ($eventHub in $eventHubs) {
    $drConfig = Get-AzEventHubGeoDRConfiguration -ResourceGroupName $ResourceGroupName -Namespace $eventHub.Name -Verbose
    $drConfig
    if ($drConfig) {
        if ($drConfig.Role.ToString() -eq "Primary" ) {
            #there is a partner namespace, break the pair before removing
            Write-Host "EventHubs Break Pairing... (primary)"
            Set-AzEventHubGeoDRConfigurationBreakPair -ResourceGroupName $ResourceGroupName -Namespace $eventHub.Name -Name $drConfig.Name
        }
    }
}
foreach ($eventHub in $eventHubs) {
    Write-Host "EventHubs remove DR config..."
    $drConfig = Get-AzEventHubGeoDRConfiguration -ResourceGroupName $ResourceGroupName -Namespace $eventHub.Name -Verbose
    #### DEBUG THIS: I think this can only be done on primary?  So need to handle the error - once config is removed resource can be deleted by job
    Remove-AzEventHubGeoDRConfiguration -ResourceGroupName $ResourceGroupName -Namespace $eventHub.Name $drConfig.Name -Verbose
}
$serviceBusNamespaces = Get-AzServiceBusNamespace -ResourceGroupName $ResourceGroupName -Verbose
foreach ($s in $serviceBusNamespaces) {
    Write-Host "ServiceBus Break pairing..."
    $drConfig = Get-AzServiceBusGeoDRConfiguration -ResourceGroupName $ResourceGroupName -Namespace $s.Name
    $drConfig
    if ($drConfig) {
        if ($drConfig.Role.ToString() -eq "Primary" ) {
            #there is a partner namespace, break the pair before removing
            Write-Host "ServiceBus Break pairing... (primary)"
            Set-AzServiceBusGeoDRConfigurationBreakPair -ResourceGroupName $ResourceGroupName -Namespace $s.Name -Name $drConfig.Name
        }
    }
}
foreach ($s in $serviceBusNamespaces) {
    $drConfig = Get-AzServiceBusGeoDRConfiguration -ResourceGroupName $ResourceGroupName -Namespace $s.Name
    if ($drConfig) {
        Write-Host "Service Bus remove DR config..."
        Remove-AzServiceBusGeoDRConfiguration -ResourceGroupName $ResourceGroupName -Namespace $s.Name -Name $drConfig.Name -Verbose
    }
    # ??? Remove-AzureRmServiceBusNamespace -ResourceGroupName $ResourceGroupName -Name $s.Name -Verbose
}
foreach ($s in $serviceBusNamespaces) {
    # set ErrorAction on this since it throws if there is no config (unlike the other cmdlets)
    $migrationConfig = Get-AzServiceBusMigration -ResourceGroupName $ResourceGroupName -Name $s.Name -ErrorAction SilentlyContinue
    if ($migrationConfig) {
        Write-Host "Service Bus remove migration..."
        Remove-AzServiceBusMigration -ResourceGroupName $ResourceGroupName -Name $s.Name -Verbose
    }
}
#>
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $rg -Name $vnetName
$subnets = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet
foreach($subnet in $subnets){
    Remove-AzureRMResource -ResourceId " $($subnet.id)/providers/Microsoft.ContainerInstance/serviceAssociationLinks/default" -Force
}
$webapps = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Verbose
foreach ($w in $webapps) {
    Write-Host "WebApp: $($w.Name)"
    $slots = Get-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $w.Name -Verbose
    foreach ($s in $slots) {
        $slotName = $($s.Name).Split('/')[1]
        # assumption is that there can only be one vnetConfig but it returns an array so maybe not
        $r = Invoke-AzRestMethod -Method "GET" -Path " /subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$($w.name)/slots/$slotName/virtualNetworkConnections?api-version=2020-10-01"
        Write-Host "Slot: $slotName / $($r.StatusCode)"
        if ($r.StatusCode -eq '200') {
            # The URI for remove is not the same as the GET URI
            $r | Out-String
            Invoke-AzRestMethod -Method "DELETE" -Path " /subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$($w.name)/slots/$slotName/networkConfig/virtualNetwork?api-version=2020-10-01" -Verbose
        }
    }
    # now remove the config on the webapp itself
    $r = Invoke-AzRestMethod -Method "GET" -Path " /subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$($w.name)/virtualNetworkConnections?api-version=2020-10-01"
    Write-Host "Prod Slot: $($r.StatusCode)"
    if ($r.StatusCode -eq '200') {
        # The URI for remove is not the same as the GET URI
        $r | Out-String
        Invoke-AzRestMethod -Method "DELETE" -Path " /subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Web/sites/$($w.name)/networkConfig/virtualNetwork?api-version=2020-10-01" -Verbose
    }
}
$redisCaches = Get-AzRedisCache -ResourceGroupName $ResourceGroupName -Verbose
foreach ($r in $redisCaches) {
    Write-Host "Redis..."
    $link = Get-AzRedisCacheLink -Name $r.Name
    if ($link) {
        Write-Host "Remove Redis Link..."
        $link | Remove-AzRedisCacheLink -Verbose
    }
}
$vnets = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Verbose
foreach ($vnet in $vnets) {
    Write-Host "Vnet Delegation..."
    foreach ($subnet in $vnet.Subnets) {
        $delegations = Get-AzDelegation -Subnet $subnet -Verbose
        foreach ($d in $delegations) {
            Write-Output "Removing VNet Delegation: $($d.name)"
            Remove-AzDelegation -Name $d.Name -Subnet $subnet -Verbose
        }
    }
}
$vHubs = Get-AzVirtualHub -ResourceGroupName $ResourceGroupName -Verbose
foreach ($h in $vHubs) {
    # see if there is are any ipConfigurations on the hub
    Write-Host "Checking for ipConfigurations in vhub: $($h.name)"
    $r = Invoke-AzRestMethod -Method "GET" -path " /subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Network/virtualHubs/$($h.name)/ipConfigurations?api-version=2020-11-01"
    $r | Out-String
    $ipConfigs = $($r.Content | ConvertFrom-Json -Depth 50).Value
    $ipConfigs | Out-String
    foreach ($config in $ipConfigs) {
        Write-Host "Attempting to remove: $($config.name)"
        $r = Invoke-AzRestMethod -Method DELETE -Path " $($config.id)?api-version=2020-11-01"
        $r | Out-String
        if ($r.StatusCode -like " 20*" ) {
            do {
                Start-Sleep 60 -Verbose
                $r = Invoke-AzRestMethod -Method GET -Path " $($config.id)?api-version=2020-11-01"
                $r | Out-String
                # wait until the delete is finished and GET returns 404
            } until ($r.StatusCode -eq " 404" )
        }
    }
}
$privateLinks = Get-AzPrivateLinkService -ResourceGroupName $ResourceGroupName
foreach ($pl in $privateLinks) {
    Write-Host "Checking Private Links for endpoint connections..."
$connections = Get-AzPrivateEndpointConnection -ResourceGroupName $ResourceGroupName -ServiceName $pl.Name
    foreach ($c in $connections) {
        Write-Host "Removing PrivateLink Endpoint Connection: $($c.name)"
        Remove-AzPrivateEndpointConnection -ResourceGroupName $ResourceGroupName -ServiceName $pl.Name -Name $c.Name -Force
    }
}
Remove-AzResourceGroup -Force -Verbose -Name $ResourceGroupName
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n

