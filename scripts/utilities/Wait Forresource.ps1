#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Wait Forresource

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
This script will query regional endpoints directly to determine if replication is complete
[CmdletBinding()]
    $ErrorActionPreference = "Stop"
param(
    [Parameter()]
    $ResourceId,
    [Parameter()]
    $ApiVersion,
    [Parameter()]
    $TimeOutSeconds = 60
)
    $token = Get-AzAccessToken -ErrorAction Stop
    $headers = @{
    'Content-Type'  = 'application/json'
    'Authorization' = 'Bearer ' + $token.Token
}
    $locations = @()
    $AzureLocations = ((Invoke-AzRestMethod -Method GET -Path "/locations?api-version=2022-01-01" ).content | ConvertFrom-Json -Depth 100).value
foreach($l in $AzureLocations){
    if($l.metadata.RegionType -eq "Physical" ){
    $locations = $locations + $l.name
    }
}
    $env:FOUND = $true
    $endpoint = (Get-AzContext).Environment.ResourceManagerUrl.Split('/')[2]
    $locations | ForEach-Object -Parallel {
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
    $StopTime = (Get-Date).AddSeconds($using:timeOutSeconds)
    While ($null -eq $r -and $(Get-Date) -lt $StopTime) {
        try {
            Write-Output $uri
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
            Write-Output " response:`n$r`n... from $_" # Color: $2
        }
    }
    if($null -eq $r){
    $env:FOUND = $false
    }
}
    $DeploymentScriptOutputs = @{}
    $DeploymentScriptOutputs['ResourceFound'] = $env:FOUND
Write-Output $DeploymentScriptOutputs['ResourceFound']



