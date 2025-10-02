#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Check Azure Spring Apps provision state

.DESCRIPTION
    Checks the provisioning state of Azure Spring Apps Build Service Builder
    and waits for it to reach "Succeeded" status

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

try {
    $SubscriptionId = $env:SUBSCRIPTION_ID
    $ResourceGroup = $env:RESOURCE_GROUP
    $AsaServiceName = $env:ASA_SERVICE_NAME

    if ([string]::IsNullOrWhiteSpace($SubscriptionId)) {
        throw "The subscription Id is not successfully retrieved, please retry another deployment."
    }

    if ([string]::IsNullOrWhiteSpace($ResourceGroup)) {
        throw "The resource group is not successfully retrieved, please retry another deployment."
    }

    if ([string]::IsNullOrWhiteSpace($AsaServiceName)) {
        throw "The Azure Spring Apps service name is not successfully retrieved, please retry another deployment."
    }

    Write-Verbose "Subscription ID: $SubscriptionId"
    Write-Verbose "Resource Group: $ResourceGroup"
    Write-Verbose "ASA Service Name: $AsaServiceName"

    $ApiUrl = "https://management.azure.com/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.AppPlatform/Spring/$AsaServiceName/buildServices/default/builders/default?api-version=2023-05-01-preview"

    $state = $null
    $timeout = New-TimeSpan -Seconds 900
    $Succeeded = 'Succeeded'

    Write-Output "Check the status of Build Service Builder provisioning state within $timeout ..."

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $AccessToken = (Get-AzAccessToken).Token
    $headers = @{
        'Authorization' = "Bearer $AccessToken"
    }

    while ($sw.Elapsed -lt $timeout) {
        Write-Verbose "Checking provisioning state... Elapsed: $($sw.Elapsed)"

        $response = Invoke-WebRequest -Uri $ApiUrl -Headers $headers -Method GET
        $content = $response.Content | ConvertFrom-Json
        $state = $content.properties.provisioningState

        Write-Verbose "Current state: $state"

        if ($state -eq $Succeeded) {
            Write-Output "Build Service Builder provisioning succeeded!"
            break
        }

        Start-Sleep -Seconds 5
    }

    Write-Output "Final State: $state"

    if ($state -ne $Succeeded) {
        throw "The Build Service Builder provisioning state is not succeeded. Current state: $state"
    }

    Write-Output "Azure Spring Apps Build Service Builder is ready"
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}