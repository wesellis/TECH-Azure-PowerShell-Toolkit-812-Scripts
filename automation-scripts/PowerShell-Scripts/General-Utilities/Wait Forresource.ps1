#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Wait Forresource

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Wait Forresource

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#

This script will query regional endpoints directly to determine if replication is complete



[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    $resourceId,
    $apiVersion,
    $timeOutSeconds = 60
)

#region Functions

$token = Get-AzAccessToken -ErrorAction Stop

$headers = @{
    'Content-Type'  = 'application/json'
    'Authorization' = 'Bearer ' + $token.Token
}


$locations = @()
$azureLocations = ((Invoke-AzRestMethod -Method GET -Path " /locations?api-version=2022-01-01" ).content | ConvertFrom-Json -Depth 100).value
foreach($l in $azureLocations){
    if($l.metadata.RegionType -eq " Physical" ){
        $locations = $locations + $l.name
        #Write-Information $l.name + $l.metadata.RegionType
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

    $uri = " https://$region.$($using:endpoint)/$($using:resourceId)?api-version=$($using:apiVersion)"

    $r = $null
    $stopTime = (Get-Date).AddSeconds($using:timeOutSeconds)

    While ($null -eq $r -and $(Get-Date) -lt $stopTime) {
        try {
            Write-Information $uri
           ;  $r = Invoke-RestMethod -Headers $using:headers -Method " GET" $uri
        }
        catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    throw
}

        if ($null -eq $r) {
            Write-Warning " Not found in $_"
            Start-Sleep 3
        }
        else {
            Write-WELog " response:`n$r`n... from $_" " INFO" -ForegroundColor Green
        }

    }

    if($null -eq $r){
        $env:FOUND = $false
    }
    
}
; 
$WEDeploymentScriptOutputs = @{}
$WEDeploymentScriptOutputs['ResourceFound'] = $env:FOUND
Write-Information $WEDeploymentScriptOutputs['ResourceFound']

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
