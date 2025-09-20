#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Check Provision State

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdLetBinding()
try {
    # Main script execution
]
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param()
$subscriptionId = $env:SUBSCRIPTION_ID
$resourceGroup = $env:RESOURCE_GROUP
$asaServiceName = $env:ASA_SERVICE_NAME
if (!$subscriptionId) {
    throw "The subscription Id is not successfully retrieved, please retry another deployment."
}
if (!$resourceGroup) {
    throw "The resource group is not successfully retrieved, please retry another deployment."
}
if (!$asaServiceName) {
    throw "The Azure Spring Apps service name is not successfully retrieved, please retry another deployment."
}
$apiUrl = 'https://management.azure.com/subscriptions/' + $subscriptionId + '/resourceGroups/' + $resourceGroup + '/providers/Microsoft.AppPlatform/Spring/' + $asaServiceName + '/buildServices/default/builders/default?api-version=2023-05-01-preview'
$state = $null
$timeout = New-TimeSpan -Seconds 900
Write-Output "Check the status of Build Service Builder provisioning state within $timeout ..."
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$accessToken = (Get-AzAccessToken).Token
$headers = @{
    'Authorization' = 'Bearer ' + $accessToken
}
$Succeeded = 'Succeeded'
while ($sw.Elapsed -lt $timeout) {
    $response = Invoke-WebRequest -Uri $apiUrl -Headers $headers -Method GET
$content = $response.Content | ConvertFrom-Json
$state = $content.properties.provisioningState
    if ($state -eq $Succeeded) {
        break
    }
    Start-Sleep -Seconds 5
}
Write-Output "State: $state"
if ($state -ne $Succeeded) {
    throw "The Build Service Builder provisioning state is not succeeded."
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


