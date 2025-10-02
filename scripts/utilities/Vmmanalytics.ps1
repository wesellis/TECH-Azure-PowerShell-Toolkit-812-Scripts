#Requires -Version 7.4

<#`n.SYNOPSIS
    Vmmanalytics

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
$ErrorActionPreference = 'Stop'

    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$VmmServers��=��(Get-AutomationVariable -Name 'vmmServers').Split("," )
$LastRunTimestamp��=��Get-Date -ErrorAction Stop (Get-AutomationVariable -Name 'lastRunTime')
$CurrentTimestamp��=��Get-Date -ErrorAction Stop
$WorkSpaceId=��Get-AutomationVariable -Name 'workspaceId'
$SharedKey��=��Get-AutomationVariable -Name 'workspaceKey'
[OutputType([PSObject])]
 ($CustomerId, $SharedKey, $date, $ContentLength, $method, $ContentType, $resource)
{
    $XHeaders = " x-ms-date:" + $date
    $StringToHash = $method + " `n" + $ContentLength + " `n" + $ContentType + " `n" + $XHeaders + " `n" + $resource
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $CustomerId,$EncodedHash
    return $authorization
}
Function Post-OMSData($CustomerId, $SharedKey, $body)
{
    $method = "POST"
    $ContentType = " application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
    $ContentLength = $body.Length
    $params = @{
        date = $rfc1123date
        contentLength = $ContentLength
        resource = $resource ;  $uri = "https://" + $CustomerId + " .ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01
        sharedKey = $SharedKey
        customerId = $CustomerId
        contentType = $ContentType
        fileName = $FileName
        method = $method
    }
    $signature @params
$headers = @{
        "Authorization" = $signature;
        "Log-Type" = "VMMjobs" ;
        " x-ms-date" = $rfc1123date;
        " time-generated-field" = "StartTime" ;
    }
    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $ContentType -Headers $headers -Body $body -UseBasicParsing
    return $response.StatusCode
}
foreach��($server��in��$VmmServers)
{
write-output��('Getting��jobs��data��from��VMM��Server��'+��$server)
    $VmmJobsDataForOMS = Invoke-Command��-ComputerName��$server��-ScriptBlock��{
        $server_r = $args[0]
        $LastRunTimestamp_r = $args[1]
        $CurrentTimestamp_r = $args[2]
$JobsData��=��Get-SCJob��-All��-VMMServer $server_r |��where��{$_.Status -ne 'Running' -and $_.EndTime��-gt��$LastRunTimestamp_r��-and��$_.EndTime��-le��$CurrentTimestamp_r}
��; ��$VmmJobsDataForOMS��=��@();
        foreach��($job��in��$JobsData) {
            $VmmJobsDataForOMS = $VmmJobsDataForOMS + New-Object -ErrorAction Stop��PSObject��-Property��@{
                JobName��=��$job.CmdletName;
                Name��=��$job.Name;
                StartTime��=��$job.StartTime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffffffZ" );
                EndTime��=��$job.EndTime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffffffZ" );
                Duration��=��($job.EndTime-$job.StartTime).TotalSeconds;
                Progress��=��$job.Progress.ToString();
                Status��=��$job.Status.ToString();
                ErrorInfo��=��$job.ErrorInfo.ToString();
                Problem��=��$job.ErrorInfo.Problem;
                CloudProblem��=��$job.ErrorInfo.CloudProblem;
                RecommendedAction��=��$job.ErrorInfo.RecommendedAction;
                ResultObjectID��=��$job.ResultObjectID;
                TargetObjectID��=��$job.TargetObjectID;
                TargetObjectType��=��$job.TargetObjectType;
                ID��=��$job.ID.ToString();
                ServerConnection��=��$job.ServerConnection.ToString();
                IsRestartable��=��$job.IsRestartable
                IsCompleted��=��$job.IsCompleted
                VMMServer��=��$server_r;
                }
        }
           $VmmJobsDataForOMS��=��$VmmJobsDataForOMS��|��ConvertTo-Json;
           Return $VmmJobsDataForOMS;
        } -Args��$server,��$LastRunTimestamp,��$CurrentTimestamp
    write-output��('Pushing��job records to OMS for VMM server ' + $server)
    if($VmmJobsDataForOMS) {
        Post-OMSData��-customerId��$WorkSpaceId��-sharedKey��$SharedKey��-body��([System.Text.Encoding]::UTF8.GetBytes($VmmJobsDataForOMS))
    }
}
write-output��('Setting lastRunTimestamp varaible as UTC ' + $CurrentTimestamp.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffffffZ" ));
Set-AutomationVariable -Name 'lastRunTime' -Value $CurrentTimestamp



