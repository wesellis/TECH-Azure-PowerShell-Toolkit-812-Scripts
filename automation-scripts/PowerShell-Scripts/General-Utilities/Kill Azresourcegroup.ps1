<#
.SYNOPSIS
    Kill Azresourcegroup

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
    We Enhanced Kill Azresourcegroup

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
    [string][Parameter(mandatory = $true)] $WEResourceGroupName
)

Write-WELog " Kill: $resourceGroupName" " INFO"


if ((Get-AzContext).Environment.Name -eq " AzureUSGovernment" ) {
    Write-WELog " Running in FF..." " INFO"
    $deployment = Get-AzResourceGroupDeployment -ResourceGroupName $WEResourceGroupName
    $ops = Get-AzResourceGroupDeploymentOperation -ResourceGroupName $WEResourceGroupName -DeploymentName $deployment.DeploymentName
    foreach ($op in $ops) {
        if ($op.TargetResource -like " */Microsoft.Scheduler/jobCollections/*" ) {
            Write-WELog " Found operation with target resource: $($op.TargetResource)" " INFO"
            exit
        }
    }
}


$subscriptionId = $(Get-AzContext).Subscription.Id


Get-AzResourceLock -ResourceGroupName $WEResourceGroupName -Verbose | Remove-AzResourceLock -Force -verbose


$vaults = Get-AzRecoveryServicesVault -ResourceGroupName $WEResourceGroupName -Verbose

foreach ($vault in $vaults) {
    Write-WELog " Recovery Services Vaults..." " INFO"

    & " $WEPSScriptRoot\Kill-AzRecoveryServicesVault.ps1" -ResourceGroup $WEResourceGroupName -VaultName $vault.Name

}


$oms = Get-AzResource -ResourceGroupName $WEResourceGroupName -ResourceType " Microsoft.OperationsManagement/solutions"

foreach($o in $oms){
    # need to invoke REST to get the properties body
    $r = Invoke-AzRestMethod -Method " GET" -Path " $($o.id)?api-version=2015-11-01-preview" -Verbose
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
    Invoke-AzRestMethod -Method " PUT" -Path " $($o.id)?api-version=2015-11-01-preview" -Payload $jsonBody -Verbose

}




if ($(Get-Module -ListAvailable Az.DataProtection) -eq $null) {
    Write-WELog " Installing Az.DataProtection module..." " INFO"
    Install-Module Az.DataProtection -Force -AllowClobber #| Out-Null # this is way too noisy for some reason
}

$vaults = Get-AzDataProtectionBackupVault -ResourceGroupName $WEResourceGroupName #-Verbose 

foreach ($vault in $vaults) {
    Write-WELog " Data Protection Vault: $($vault.name)" " INFO"
    $backupInstances = Get-AzDataProtectionBackupInstance -ResourceGroupName $WEResourceGroupName -VaultName $vault.Name
    foreach ($bi in $backupInstances) {
        Write-WELog " Removing Backup Instance: $($bi.name)" " INFO"
        Remove-AzDataProtectionBackupInstance -ResourceGroupName $WEResourceGroupName -VaultName $vault.Name -Name $bi.Name 
    }

    $backupPolicies = Get-AzDataProtectionBackupPolicy -ResourceGroupName $WEResourceGroupName -VaultName $vault.Name 
    foreach ($bp in $backupPolicies) {
        Write-WELog " Removing backup policy: $($bp.name)" " INFO"
        Remove-AzDataProtectionBackupPolicy -ResourceGroupName $WEResourceGroupName -VaultName $vault.name -Name $bp.Name   
    }
}


$eventHubs = Get-AzEventHubNamespace -ResourceGroupName $WEResourceGroupName -Verbose  #-Name $WEVaultName 


foreach ($eventHub in $eventHubs) {
    $drConfig = Get-AzEventHubGeoDRConfiguration -ResourceGroupName $WEResourceGroupName -Namespace $eventHub.Name -Verbose
    $drConfig
    if ($drConfig) {
        if ($drConfig.Role.ToString() -eq " Primary" ) {
            #there is a partner namespace, break the pair before removing
            Write-WELog " EventHubs Break Pairing... (primary)" " INFO"
            Set-AzEventHubGeoDRConfigurationBreakPair -ResourceGroupName $WEResourceGroupName -Namespace $eventHub.Name -Name $drConfig.Name
        }
    }
}


foreach ($eventHub in $eventHubs) {
    Write-WELog " EventHubs remove DR config..." " INFO"
    $drConfig = Get-AzEventHubGeoDRConfiguration -ResourceGroupName $WEResourceGroupName -Namespace $eventHub.Name -Verbose

    #### DEBUG THIS: I think this can only be done on primary?  So need to handle the error - once config is removed resource can be deleted by job
    Remove-AzEventHubGeoDRConfiguration -ResourceGroupName $WEResourceGroupName -Namespace $eventHub.Name $drConfig.Name -Verbose
}



$serviceBusNamespaces = Get-AzServiceBusNamespace -ResourceGroupName $WEResourceGroupName -Verbose


foreach ($s in $serviceBusNamespaces) {
    Write-WELog " ServiceBus Break pairing..." " INFO"
    $drConfig = Get-AzServiceBusGeoDRConfiguration -ResourceGroupName $WEResourceGroupName -Namespace $s.Name
    $drConfig
    if ($drConfig) {
        if ($drConfig.Role.ToString() -eq " Primary" ) {
            #there is a partner namespace, break the pair before removing
            Write-WELog " ServiceBus Break pairing... (primary)" " INFO"
            Set-AzServiceBusGeoDRConfigurationBreakPair -ResourceGroupName $WEResourceGroupName -Namespace $s.Name -Name $drConfig.Name
        }
    }
}


foreach ($s in $serviceBusNamespaces) {
    $drConfig = Get-AzServiceBusGeoDRConfiguration -ResourceGroupName $WEResourceGroupName -Namespace $s.Name
    if ($drConfig) {
        Write-WELog " Service Bus remove DR config..." " INFO"
        Remove-AzServiceBusGeoDRConfiguration -ResourceGroupName $WEResourceGroupName -Namespace $s.Name -Name $drConfig.Name -Verbose
    }
    # ??? Remove-AzureRmServiceBusNamespace -ResourceGroupName $WEResourceGroupName -Name $s.Name -Verbose
}

foreach ($s in $serviceBusNamespaces) {
    # set ErrorAction on this since it throws if there is no config (unlike the other cmdlets)
    $migrationConfig = Get-AzServiceBusMigration -ResourceGroupName $WEResourceGroupName -Name $s.Name -ErrorAction SilentlyContinue
    if ($migrationConfig) {
        Write-WELog " Service Bus remove migration..." " INFO"
        Remove-AzServiceBusMigration -ResourceGroupName $WEResourceGroupName -Name $s.Name -Verbose
    }
}

<#
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $rg -Name $vnetName
$subnets = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet

foreach($subnet in $subnets){
    Remove-AzureRMResource -ResourceId " $($subnet.id)/providers/Microsoft.ContainerInstance/serviceAssociationLinks/default" -Force
}



$webapps = Get-AzWebApp -ResourceGroupName $WEResourceGroupName -Verbose
foreach ($w in $webapps) {
    Write-WELog " WebApp: $($w.Name)" " INFO"
    $slots = Get-AzWebAppSlot -ResourceGroupName $WEResourceGroupName -Name $w.Name -Verbose
    foreach ($s in $slots) {
        $slotName = $($s.Name).Split('/')[1]
        # assumption is that there can only be one vnetConfig but it returns an array so maybe not
        $r = Invoke-AzRestMethod -Method " GET" -Path " /subscriptions/$subscriptionId/resourceGroups/$WEResourceGroupName/providers/Microsoft.Web/sites/$($w.name)/slots/$slotName/virtualNetworkConnections?api-version=2020-10-01"
        Write-WELog " Slot: $slotName / $($r.StatusCode)" " INFO"
        if ($r.StatusCode -eq '200') {
            # The URI for remove is not the same as the GET URI
            $r | Out-String
            Invoke-AzRestMethod -Method " DELETE" -Path " /subscriptions/$subscriptionId/resourceGroups/$WEResourceGroupName/providers/Microsoft.Web/sites/$($w.name)/slots/$slotName/networkConfig/virtualNetwork?api-version=2020-10-01" -Verbose
        }
    }
    # now remove the config on the webapp itself
    $r = Invoke-AzRestMethod -Method " GET" -Path " /subscriptions/$subscriptionId/resourceGroups/$WEResourceGroupName/providers/Microsoft.Web/sites/$($w.name)/virtualNetworkConnections?api-version=2020-10-01"
    Write-WELog " Prod Slot: $($r.StatusCode)" " INFO"
    if ($r.StatusCode -eq '200') {
        # The URI for remove is not the same as the GET URI
        $r | Out-String
        Invoke-AzRestMethod -Method " DELETE" -Path " /subscriptions/$subscriptionId/resourceGroups/$WEResourceGroupName/providers/Microsoft.Web/sites/$($w.name)/networkConfig/virtualNetwork?api-version=2020-10-01" -Verbose
    }
}



$redisCaches = Get-AzRedisCache -ResourceGroupName $WEResourceGroupName -Verbose

foreach ($r in $redisCaches) {
    Write-WELog " Redis..." " INFO"
    $link = Get-AzRedisCacheLink -Name $r.Name
    if ($link) {
        Write-WELog " Remove Redis Link..." " INFO"
        $link | Remove-AzRedisCacheLink -Verbose
    }
}




$vnets = Get-AzVirtualNetwork -ResourceGroupName $WEResourceGroupName -Verbose

foreach ($vnet in $vnets) {
    Write-WELog " Vnet Delegation..." " INFO"
    foreach ($subnet in $vnet.Subnets) {
        $delegations = Get-AzDelegation -Subnet $subnet -Verbose
        foreach ($d in $delegations) {
            Write-Output " Removing VNet Delegation: $($d.name)"
            Remove-AzDelegation -Name $d.Name -Subnet $subnet -Verbose
        }
    }
}


$vHubs = Get-AzVirtualHub -ResourceGroupName $WEResourceGroupName -Verbose
foreach ($h in $vHubs) {
    # see if there is are any ipConfigurations on the hub
    Write-WELog " Checking for ipConfigurations in vhub: $($h.name)" " INFO"
    $r = Invoke-AzRestMethod -Method " GET" -path " /subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Network/virtualHubs/$($h.name)/ipConfigurations?api-version=2020-11-01"
    $r | Out-String
    $ipConfigs = $($r.Content | ConvertFrom-Json -Depth 50).Value
    $ipConfigs | Out-String
    foreach ($config in $ipConfigs) {
        Write-WELog " Attempting to remove: $($config.name)" " INFO"
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

; 
$privateLinks = Get-AzPrivateLinkService -ResourceGroupName $WEResourceGroupName
foreach ($pl in $privateLinks) {
    Write-WELog " Checking Private Links for endpoint connections..." " INFO"
   ;  $connections = Get-AzPrivateEndpointConnection -ResourceGroupName $WEResourceGroupName -ServiceName $pl.Name
    foreach ($c in $connections) {
        Write-WELog " Removing PrivateLink Endpoint Connection: $($c.name)" " INFO"
        Remove-AzPrivateEndpointConnection -ResourceGroupName $WEResourceGroupName -ServiceName $pl.Name -Name $c.Name -Force
    }
}






Remove-AzResourceGroup -Force -Verbose -Name $WEResourceGroupName




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
