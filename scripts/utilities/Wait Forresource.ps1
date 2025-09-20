#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Wait Forresource

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
This script will query regional endpoints directly to determine if replication is complete
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter()]
    $resourceId,
    [Parameter()]
    $apiVersion,
    [Parameter()]
    $timeOutSeconds = 60
)
$token = Get-AzAccessToken -ErrorAction Stop
$headers = @{
    'Content-Type'  = 'application/json'
    'Authorization' = 'Bearer ' + $token.Token
}
$locations = @()
$azureLocations = ((Invoke-AzRestMethod -Method GET -Path " /locations?api-version=2022-01-01" ).content | ConvertFrom-Json -Depth 100).value
foreach($l in $azureLocations){
    if($l.metadata.RegionType -eq "Physical" ){
        $locations = $locations + $l.name
        #Write-Host $l.name + $l.metadata.RegionType
    }
}
$env:FOUND = $true
$endpoint = (Get-AzContext).Environment.ResourceManagerUrl.Split('/')[2]
$locations | ForEach-Object -Parallel {
    # AzureGov regional endpoints are seemingly random, so we need to MAP those...
    switch ($_) {
        " usgovvirginia" {
            $region = " usgoveast"
        }
        " usgovtexas" {
            $region = " usgovsc"
        }
        " usgovarizona" {
            $region = " usgovsw"
        }
        " usgoviowa" {
            $region = " usgovcentral"
        }
        Default {
            $region = $_
        }
    }
    $uri = "https://$region.$($using:endpoint)/$($using:resourceId)?api-version=$($using:apiVersion)"
    $r = $null
    $stopTime = (Get-Date).AddSeconds($using:timeOutSeconds)
    While ($null -eq $r -and $(Get-Date) -lt $stopTime) {
        try {
            Write-Host $uri
$r = Invoke-RestMethod -Headers $using:headers -Method "GET" $uri
        }
        catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    throw
}
        if ($null -eq $r) {
            Write-Warning "Not found in $_"
            Start-Sleep 3
        }
        else {
            Write-Host " response:`n$r`n... from $_" -ForegroundColor Green
        }
    }
    if($null -eq $r){
        $env:FOUND = $false
    }
}
$DeploymentScriptOutputs = @{}
$DeploymentScriptOutputs['ResourceFound'] = $env:FOUND
Write-Host $DeploymentScriptOutputs['ResourceFound']


