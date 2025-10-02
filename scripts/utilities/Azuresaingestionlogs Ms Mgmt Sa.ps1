#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azuresaingestionlogs Ms Mgmt Sa

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $SubscriptionidFilter,
    [Parameter(Mandatory = $false)] [bool] $CollectionFromAllSubscriptions = $false,
    [Parameter(Mandatory = $false)] [bool] $GetAsmHeader = $true)
Write-Output "RB Initial Memory  : $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
    $StartTime = [dateTime]::Now
    $Timestampfield = "Timestamp"
    $timestamp = $StartTime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:45:00.000Z" )
    $CustomerID = Get-AutomationVariable -Name 'AzureSAIngestion-OPSINSIGHTS_WS_ID-MS-Mgmt-SA'
    $SharedKey = Get-AutomationVariable -Name 'AzureSAIngestion-OPSINSIGHTS_WS_KEY-MS-Mgmt-SA'
    $ApiVerSaAsm = '2016-04-01'
    $ApiVerSaArm = '2016-01-01'
    $ApiStorage = '2016-05-31'
    $AAAccount = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationAccount-MS-Mgmt-SA'
    $AAResourceGroup = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationResourceGroup-MS-Mgmt-SA'
    $logname = 'AzureStorage'
    $childrunbook = "AzureSAIngestionChild-MS-Mgmt-SA"
    $schedulename = "AzureStorageIngestionChild-Schedule-MS-Mgmt-SA"
    $hash = [hashtable]::New(@{})
    $Starttimer = get-date -ErrorAction Stop
[OutputType([bool])]
 ($CustomerId, $SharedKey, $date, $method, $resource, $uri) {
    $StringToHash = $method + " `n" + " `n" + " `n$(date) `n" + "/" + $resource + $uri.AbsolutePath
    Add-Type -AssemblyName System.Web
    $query = [System.Web.HttpUtility]::ParseQueryString($uri.query)
    $querystr = ''
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource, $EncodedHash
    return $authorization
}
function New-StorageSignature ($SharedKey, $date, $method, $bodylength, $resource, $uri , $service) {
    Add-Type -AssemblyName System.Web
    $str = New-Object -TypeName "System.Text.StringBuilder" ;
    $builder = [System.Text.StringBuilder]::new("/" )
    $builder.Append($resource) |out-null
    $builder.Append($uri.AbsolutePath) | out-null
    $str.Append($builder.ToString()) | out-null
    $values2 = @{}
    IF ($service -eq 'Table') {
    $values = [System.Web.HttpUtility]::ParseQueryString($uri.query)
        foreach ($str2 in $values.Keys) {
            [System.Collections.ArrayList]$list = $values.GetValues($str2)
    $list.sort()
    $builder2 = [System.Text.StringBuilder]::new()
            foreach ($obj2 in $list) {
                if ($builder2.Length -gt 0) {
    $builder2.Append(" ," );
                }
    $builder2.Append($obj2.ToString()) |Out-Null
            }
            IF ($null -ne $str2) {
    $values2.add($str2.ToLowerInvariant(), $builder2.ToString())
            }
        }
    $list2 = [System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
        foreach ($str3 in $list2) {
            IF ($str3 -eq 'comp') {
    $builder3 = [System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" =" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" ?" ) |out-null
    $str.Append($builder3.ToString())|out-null
            }
        }
    }
    Else {
    $values = [System.Web.HttpUtility]::ParseQueryString($uri.query)
        foreach ($str2 in $values.Keys) {
            [System.Collections.ArrayList]$list = $values.GetValues($str2)
    $list.sort()
    $builder2 = [System.Text.StringBuilder]::new()
            foreach ($obj2 in $list) {
                if ($builder2.Length -gt 0) {
    $builder2.Append(" ," );
                }
    $builder2.Append($obj2.ToString()) |Out-Null
            }
            IF ($null -ne $str2) {
    $values2.add($str2.ToLowerInvariant(), $builder2.ToString())
            }
        }
    $list2 = [System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
        foreach ($str3 in $list2) {
    $builder3 = [System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" :" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" `n" ) |out-null
    $str.Append($builder3.ToString())|out-null
        }
    }
    $XHeaders = " x-ms-date:$(date) `n" + " x-ms-version:$ApiStorage"
    if ($service -eq 'Table') {
    $StringToHash = $method + " `n" + " `n" + " `n$(date) `n" + $str.ToString()
    }
    Else {
        IF ($method -eq 'GET' -or $method -eq 'HEAD') {
    $StringToHash = $method + " `n" + " `n" + " `n" + " `n" + " `n" + " application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" + $str.ToString()
        }
        Else {
    $StringToHash = $method + " `n" + " `n" + " `n$(bodylength) `n" + " `n" + " application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" + $str.ToString()
        }
    }
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource, $EncodedHash
    return $authorization
}
Function invoke-StorageREST($SharedKey, $method, $msgbody, $resource, $uri, $svc, $download) {
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
    If ($method -eq 'PUT') {
    $params = @{
            uri = $uri
            date = $rfc1123date
            service = $svc } Else {
            resource = $resource
            sharedKey = $SharedKey
            bodylength = $msgbody.length
            method = $method
        }
    $signature @params
    $params = @{
           uri = $uri
           date = $rfc1123date
           service = $svc }
           resource = $resource
           sharedKey = $SharedKey
           body = $body
           method = $method
       }
       ; @params
    If ($svc -eq 'Table') {
    $headersforsa = @{
            'Authorization'         = " $signature"
            'x-ms-version'          = " $apistorage"
            'x-ms-date'             = " $rfc1123date"
            'Accept-Charset'        = 'UTF-8'
            'MaxDataServiceVersion' = '3.0;NetFx'
            'Accept'                = 'application/json;odata=nometadata'
        }
    }
    Else {
    $HeadersforSA = @{
            'x-ms-date'     = " $rfc1123date"
            'Content-Type'  = 'application\xml'
            'Authorization' = " $signature"
            'x-ms-version'  = " $ApiStorage"
        }
    }
    IF ($download) {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody  -OutFile " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
        return " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
    }
    Else {
        If ($svc -eq 'Table') {
            IF ($method -eq 'PUT') {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method  -UseBasicParsing -Body $msgbody
                return $resp1
            }
            Else {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method   -UseBasicParsing -Body $msgbody
    $xresp = $resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
            }
            return $xresp
        }
        Else {
            IF ($method -eq 'PUT') {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
                return $resp1
            }
            Elseif ($method -eq 'GET') {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody -ea 0
    $xresp = $resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
                return $xresp
            }
            Elseif ($method -eq 'HEAD') {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
                return $resp1
            }
        }
    }
}
function Get-BlobSize -ErrorAction Stop ($bloburi, $storageaccount, $rg, $type) {
    If ($type -eq 'ARM') {
    $Uri = "https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.Storage/storageAccounts/{1}/listKeys?api-version={0}" -f $ApiVerSaArm, $storageaccount, $rg, $SubscriptionId
    $keyresp = Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys = ConvertFrom-Json -InputObject $keyresp.Content
    $prikey = $keys.keys[0].value
    }
    Elseif ($type -eq 'Classic') {
    $Uri = "https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.ClassicStorage/storageAccounts/{1}/listKeys?api-version={0}" -f $ApiVerSaAsm, $storageaccount, $rg, $SubscriptionId
    $keyresp = Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys = ConvertFrom-Json -InputObject $keyresp.Content
    $prikey = $keys.primaryKey
    }
    Else {
        "Could not detect storage account type, $storageaccount will not be processed"
        Continue
    }
    $vhdblob = invoke-StorageREST -sharedKey $prikey -method HEAD -resource $storageaccount -uri $bloburi
    Return [math]::round($vhdblob.Headers.'Content-Length' / 1024 / 1024 / 1024, 0)
}
function New-OMSSignature ($CustomerId, $SharedKey, $date, $ContentLength, $method, $ContentType, $resource) {
    $XHeaders = " x-ms-date:" + $date
    $StringToHash = $method + " `n$(contentLength) `n" + $ContentType + " `n$(xHeaders) `n" + $resource
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $CustomerId, $EncodedHash
    return $authorization
}
Function Post-OMSData($CustomerId, $SharedKey, $body, $LogType) {
    $method = "POST"
    $ContentType = " application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
    $ContentLength = $body.Length
    $params = @{
        date = $rfc1123date
        contentLength = $ContentLength
        resource = $resource ;  $uri = "https://$(customerId) .ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01" ;  $OMSheaders = @{ "Authorization"        = $signature; "Log-Type"             = $LogType; " x-ms-date"            = $rfc1123date; " time-generated-field" = $TimeStampField; }
        sharedKey = $SharedKey
        customerId = $CustomerId
        contentType = $ContentType
        fileName = $FileName
        method = $method
    }
    $signature @params
    Try {
    $response = Invoke-WebRequest -Uri $uri -Method POST  -ContentType $ContentType -Headers $OMSheaders -Body $body -UseBasicParsing
    }catch [Net.WebException] {
    $ex = $_.Exception
        If ($_.Exception.Response.StatusCode.value__) {
    $exrespcode = ($_.Exception.Response.StatusCode.value__ ).ToString().Trim();
        }
        If ($_.Exception.Message) {
    $ExMessage = ($_.Exception.Message).ToString().Trim();
        }
    $errmsg = " $exrespcode : $ExMessage"
    }
    if ($errmsg) {return $errmsg }
    Else {	return $response.StatusCode }
    Write-error
    $ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $SubscriptionidFilter,
    [Parameter(Mandatory = $false)] [bool] $CollectionFromAllSubscriptions = $false,
    [Parameter(Mandatory = $false)] [bool] $GetAsmHeader = $true)
Write-Output "RB Initial Memory  : $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
    $StartTime = [dateTime]::Now
    $Timestampfield = "Timestamp"
    $timestamp = $StartTime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:45:00.000Z" )
    $CustomerID = Get-AutomationVariable -Name 'AzureSAIngestion-OPSINSIGHTS_WS_ID-MS-Mgmt-SA'
    $SharedKey = Get-AutomationVariable -Name 'AzureSAIngestion-OPSINSIGHTS_WS_KEY-MS-Mgmt-SA'
    $ApiVerSaAsm = '2016-04-01'
    $ApiVerSaArm = '2016-01-01'
    $ApiStorage = '2016-05-31'
    $AAAccount = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationAccount-MS-Mgmt-SA'
    $AAResourceGroup = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationResourceGroup-MS-Mgmt-SA'
    $logname = 'AzureStorage'
    $childrunbook = "AzureSAIngestionChild-MS-Mgmt-SA"
    $schedulename = "AzureStorageIngestionChild-Schedule-MS-Mgmt-SA"
    $hash = [hashtable]::New(@{})
    $Starttimer = get-date -ErrorAction Stop
[OutputType([bool])]
 ($CustomerId, $SharedKey, $date, $method, $resource, $uri) {
    $StringToHash = $method + " `n" + " `n" + " `n$(date) `n" + "/" + $resource + $uri.AbsolutePath
    Add-Type -AssemblyName System.Web
    $query = [System.Web.HttpUtility]::ParseQueryString($uri.query)
    $querystr = ''
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource, $EncodedHash
    return $authorization
}
function New-StorageSignature ($SharedKey, $date, $method, $bodylength, $resource, $uri , $service) {
    Add-Type -AssemblyName System.Web
    $str = New-Object -TypeName "System.Text.StringBuilder" ;
    $builder = [System.Text.StringBuilder]::new("/" )
    $builder.Append($resource) |out-null
    $builder.Append($uri.AbsolutePath) | out-null
    $str.Append($builder.ToString()) | out-null
    $values2 = @{}
    IF ($service -eq 'Table') {
    $values = [System.Web.HttpUtility]::ParseQueryString($uri.query)
        foreach ($str2 in $values.Keys) {
            [System.Collections.ArrayList]$list = $values.GetValues($str2)
    $list.sort()
    $builder2 = [System.Text.StringBuilder]::new()
            foreach ($obj2 in $list) {
                if ($builder2.Length -gt 0) {
    $builder2.Append(" ," );
                }
    $builder2.Append($obj2.ToString()) |Out-Null
            }
            IF ($null -ne $str2) {
    $values2.add($str2.ToLowerInvariant(), $builder2.ToString())
            }
        }
    $list2 = [System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
        foreach ($str3 in $list2) {
            IF ($str3 -eq 'comp') {
    $builder3 = [System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" =" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" ?" ) |out-null
    $str.Append($builder3.ToString())|out-null
            }
        }
    }
    Else {
    $values = [System.Web.HttpUtility]::ParseQueryString($uri.query)
        foreach ($str2 in $values.Keys) {
            [System.Collections.ArrayList]$list = $values.GetValues($str2)
    $list.sort()
    $builder2 = [System.Text.StringBuilder]::new()
            foreach ($obj2 in $list) {
                if ($builder2.Length -gt 0) {
    $builder2.Append(" ," );
                }
    $builder2.Append($obj2.ToString()) |Out-Null
            }
            IF ($null -ne $str2) {
    $values2.add($str2.ToLowerInvariant(), $builder2.ToString())
            }
        }
    $list2 = [System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
        foreach ($str3 in $list2) {
    $builder3 = [System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" :" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" `n" ) |out-null
    $str.Append($builder3.ToString())|out-null
        }
    }
    $XHeaders = " x-ms-date:$(date) `n" + " x-ms-version:$ApiStorage"
    if ($service -eq 'Table') {
    $StringToHash = $method + " `n" + " `n" + " `n$(date) `n" + $str.ToString()
    }
    Else {
        IF ($method -eq 'GET' -or $method -eq 'HEAD') {
    $StringToHash = $method + " `n" + " `n" + " `n" + " `n" + " `n" + " application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" + $str.ToString()
        }
        Else {
    $StringToHash = $method + " `n" + " `n" + " `n$(bodylength) `n" + " `n" + " application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" + $str.ToString()
        }
    }
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource, $EncodedHash
    return $authorization
}
Function invoke-StorageREST($SharedKey, $method, $msgbody, $resource, $uri, $svc, $download) {
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
    If ($method -eq 'PUT') {
    $params = @{
            uri = $uri
            date = $rfc1123date
            service = $svc } Else {
            resource = $resource
            sharedKey = $SharedKey
            bodylength = $msgbody.length
            method = $method
        }
    $signature @params
    $params = @{
           uri = $uri
           date = $rfc1123date
           service = $svc }
           resource = $resource
           sharedKey = $SharedKey
           body = $body
           method = $method
       }
       ; @params
    If ($svc -eq 'Table') {
    $headersforsa = @{
            'Authorization'         = " $signature"
            'x-ms-version'          = " $apistorage"
            'x-ms-date'             = " $rfc1123date"
            'Accept-Charset'        = 'UTF-8'
            'MaxDataServiceVersion' = '3.0;NetFx'
            'Accept'                = 'application/json;odata=nometadata'
        }
    }
    Else {
    $HeadersforSA = @{
            'x-ms-date'     = " $rfc1123date"
            'Content-Type'  = 'application\xml'
            'Authorization' = " $signature"
            'x-ms-version'  = " $ApiStorage"
        }
    }
    IF ($download) {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody  -OutFile " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
        return " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
    }
    Else {
        If ($svc -eq 'Table') {
            IF ($method -eq 'PUT') {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method  -UseBasicParsing -Body $msgbody
                return $resp1
            }
            Else {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method   -UseBasicParsing -Body $msgbody
    $xresp = $resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
            }
            return $xresp
        }
        Else {
            IF ($method -eq 'PUT') {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
                return $resp1
            }
            Elseif ($method -eq 'GET') {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody -ea 0
    $xresp = $resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
                return $xresp
            }
            Elseif ($method -eq 'HEAD') {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
                return $resp1
            }
        }
    }
}
function Get-BlobSize -ErrorAction Stop ($bloburi, $storageaccount, $rg, $type) {
    If ($type -eq 'ARM') {
    $Uri = "https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.Storage/storageAccounts/{1}/listKeys?api-version={0}" -f $ApiVerSaArm, $storageaccount, $rg, $SubscriptionId
    $keyresp = Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys = ConvertFrom-Json -InputObject $keyresp.Content
    $prikey = $keys.keys[0].value
    }
    Elseif ($type -eq 'Classic') {
    $Uri = "https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.ClassicStorage/storageAccounts/{1}/listKeys?api-version={0}" -f $ApiVerSaAsm, $storageaccount, $rg, $SubscriptionId
    $keyresp = Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys = ConvertFrom-Json -InputObject $keyresp.Content
    $prikey = $keys.primaryKey
    }
    Else {
        "Could not detect storage account type, $storageaccount will not be processed"
        Continue
    }
    $vhdblob = invoke-StorageREST -sharedKey $prikey -method HEAD -resource $storageaccount -uri $bloburi
    Return [math]::round($vhdblob.Headers.'Content-Length' / 1024 / 1024 / 1024, 0)
}
function New-OMSSignature ($CustomerId, $SharedKey, $date, $ContentLength, $method, $ContentType, $resource) {
    $XHeaders = " x-ms-date:" + $date
    $StringToHash = $method + " `n$(contentLength) `n" + $ContentType + " `n$(xHeaders) `n" + $resource
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $CustomerId, $EncodedHash
    return $authorization
}
Function Post-OMSData($CustomerId, $SharedKey, $body, $LogType) {
    $method = "POST"
    $ContentType = " application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
    $ContentLength = $body.Length
    $params = @{
        date = $rfc1123date
        contentLength = $ContentLength
        resource = $resource ;  $uri = "https://$(customerId) .ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01" ;  $OMSheaders = @{ "Authorization"        = $signature; "Log-Type"             = $LogType; " x-ms-date"            = $rfc1123date; " time-generated-field" = $TimeStampField; }
        sharedKey = $SharedKey
        customerId = $CustomerId
        contentType = $ContentType
        fileName = $FileName
        method = $method
    }
    $signature @params
    Try {
    $response = Invoke-WebRequest -Uri $uri -Method POST  -ContentType $ContentType -Headers $OMSheaders -Body $body -UseBasicParsing
    }catch [Net.WebException] {
    $ex = $_.Exception
        If ($_.Exception.Response.StatusCode.value__) {
    $exrespcode = ($_.Exception.Response.StatusCode.value__ ).ToString().Trim();
        }
        If ($_.Exception.Message) {
    $ExMessage = ($_.Exception.Message).ToString().Trim();
        }
    $errmsg = " $exrespcode : $ExMessage"
    }
    if ($errmsg) {return $errmsg }
    Else {	return $response.StatusCode }
    Write-error $error[0]
}
function Cleanup-Variables {
    Get-Variable -ErrorAction Stop |
    Where-Object { $StartupVariables -notcontains $_.Name } |
    % { Remove-Variable -Name $($_.Name) -Force -Scope global }
}
"Logging in to Azure..."
    $ArmConn = Get-AutomationConnection -Name AzureRunAsConnection
if ($null -eq $ArmConn)
{
	throw "Could not retrieve connection asset AzureRunAsConnection,  Ensure that runas account  exists in the Automation account."
}
    $retry = 6
    $SyncOk = $false
do
{
	try
	{
		Add-AzureRMAccount -ServicePrincipal -Tenant $ArmConn.TenantID -ApplicationId $ArmConn.ApplicationID -CertificateThumbprint $ArmConn.CertificateThumbprint
    $SyncOk = $true
	}
	catch
	{
    $ErrorMessage = $_.Exception.Message
    $StackTrace = $_.Exception.StackTrace
		Write-Warning "Error during sync: $ErrorMessage, stack: $StackTrace. Retry attempts left: $retry"
    $retry = $retry - 1
		Start-Sleep -s 60
	}
} while (-not $SyncOk -and $retry -ge 0)
"Selecting Azure subscription..."
    $SelectedAzureSub = Select-AzureRmSubscription -SubscriptionId $ArmConn.SubscriptionId -TenantId $ArmConn.tenantid
    $subscriptionid=$ArmConn.SubscriptionId
"Azure rm profile path  $((get-module -Name AzureRM.Profile).path) "
    $path=(get-module -Name AzureRM.Profile).path
    $path=Split-Path $path
    $dlllist=Get-ChildItem -Path $path  -Filter Microsoft.IdentityModel.Clients.ActiveDirectory.dll  -Recurse
    $adal =  $dlllist[0].VersionInfo.FileName
try
{
	Add-type -Path $adal
	[reflection.assembly]::LoadWithPartialName( "Microsoft.IdentityModel.Clients.ActiveDirectory" )
}
catch
{
    $ErrorMessage = $_.Exception.Message
    $StackTrace = $_.Exception.StackTrace
	Write-Warning "Error during sync: $ErrorMessage, stack: $StackTrace. "
}
    $certs= Get-ChildItem -Path Cert:\Currentuser\my -Recurse | Where{$_.Thumbprint -eq $ArmConn.CertificateThumbprint}
[System.Security.Cryptography.X509Certificates.X509Certificate2]$mycert=$certs[0]
    $CliCert=new-object -ErrorAction Stop  Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate($ArmConn.ApplicationId,$mycert)
    $AuthContext = new-object -ErrorAction Stop Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext(" https://login.windows.net/$($ArmConn.tenantid)" )
    $result = $AuthContext.AcquireToken(" https://management.core.windows.net/" ,$CliCert);
    $header = "Bearer " + $result.AccessToken;
    $headers = @{"Authorization" =$header;"Accept" =" application/json" }
    $body=$null
    $HTTPVerb="GET"
    $SubscriptionInfoUri = "https://management.azure.com/subscriptions/$(subscriptionid)?api-version=2016-02-01"
    $SubscriptionInfo = Invoke-RestMethod -Uri $SubscriptionInfoUri -Headers $headers -Method Get -UseBasicParsing
IF($SubscriptionInfo)
{
	"Successfully connected to Azure ARM REST"
}
if ($GetAsmHeader) {
	try
    {
    $AsmConn = Get-AutomationConnection -Name AzureClassicRunAsConnection -ea 0
    }
    Catch
    {
        if ($null -eq $AsmConn) {
            Write-Warning "Could not retrieve connection asset AzureClassicRunAsConnection. Ensure that runas account exist and valid in the Automation account."
    $GetAsmHeader=$false
        }
    }
     if ($null -eq $AsmConn) {
        Write-Warning "Could not retrieve connection asset AzureClassicRunAsConnection. Ensure that runas account exist and valid in the Automation account. Quota usage infomration for classic accounts will no tbe collected"
    $GetAsmHeader=$false
    }Else{
    $CertificateAssetName = $AsmConn.CertificateAssetName
    $AzureCert = Get-AutomationCertificate -Name $CertificateAssetName
        if ($null -eq $AzureCert)
        {
            Write-Warning  "Could not retrieve certificate asset: $CertificateAssetName. Ensure that this asset exists and valid  in the Automation account."
    $GetAsmHeader=$false
        }
        Else{
        "Logging into Azure Service Manager"
        Write-Verbose "Authenticating to Azure with certificate." -Verbose
        Set-AzureSubscription -SubscriptionName $AsmConn.SubscriptionName -SubscriptionId $AsmConn.SubscriptionId -Certificate $AzureCert
        Select-AzureSubscription -SubscriptionId $AsmConn.SubscriptionId
    $headerasm = @{" x-ms-version" =" 2013-08-01" }
        }
    }
}
    $SubscriptionsURI = "https://management.azure.com/subscriptions?api-version=2016-06-01"
    $Subscriptions = Invoke-RestMethod -Uri  $SubscriptionsURI -Method GET  -Headers $headers -UseBasicParsing
    $Subscriptions = @($Subscriptions.value)
IF ($CollectionFromAllSubscriptions -and $Subscriptions.count -gt 1 ) {
    Write-Output " $($Subscriptions.count) Subscription found , additonal runbook jobs will be created to collect data "
    $AAResourceGroup = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationResourceGroup-MS-Mgmt-SA'
    $AAAccount = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationAccount-MS-Mgmt-SA'
    $LogsRunbookName = "AzureSAIngestionLogs-MS-Mgmt-SA"
    $subslist = $subscriptions|where {$_.subscriptionId -ne $SubscriptionId}
    Foreach ($item in $subslist) {
    $params1 = @{"SubscriptionidFilter" = $item.subscriptionId; " collectionFromAllSubscriptions" = $false; " getAsmHeader" = $false}
        Start-AzureRmAutomationRunbook -AutomationAccountName $AAAccount -Name $LogsRunbookName -ResourceGroupName $AAResourceGroup -Parameters $params1 | out-null
    }
}
" $(GEt-date) - Get ARM storage Accounts "
    $Uri = "https://management.azure.com/subscriptions/{1}/providers/Microsoft.Storage/storageAccounts?api-version={0}" -f $ApiVerSaArm, $SubscriptionId
    $armresp = Invoke-RestMethod -Uri $uri -Method GET  -Headers $headers -UseBasicParsing
    $SaArmList = $armresp.Value
" $(GEt-date)  $($SaArmList.count) classic storage accounts found"
" $(GEt-date)  Get Classic storage Accounts "
    $Uri = "https://management.azure.com/subscriptions/{1}/providers/Microsoft.ClassicStorage/storageAccounts?api-version={0}" -f $ApiVerSaAsm, $SubscriptionId
    $asmresp = Invoke-RestMethod -Uri $uri -Method GET  -Headers $headers -UseBasicParsing
    $SaAsmList = $asmresp.value
" $(GEt-date)  $($SaAsmList.count) storage accounts found"
    $ColParamsforChild = @()
foreach ($sa in $SaArmList|where {$_.Sku.tier -ne 'Premium'}) {
    $rg =;  $sku = $null
    $rg = $sa.id.Split('/')[4]
    $ColParamsforChild = $ColParamsforChild + " $($sa.name);$($sa.id.Split('/')[4]);ARM;$($sa.sku.tier);$($sa.Kind)"
}
    $sa = $rg = $null
foreach ($sa in $SaAsmList|where {$_.properties.accounttype -notmatch 'Premium'}) {
    $rg = $sa.id.Split('/')[4]
    $tier = $null
    If ( $sa.properties.accountType -notmatch 'premium') {
    $tier = 'Standard'
    $ColParamsforChild = $ColParamsforChild + " $($sa.name);$($sa.id.Split('/')[4]);Classic;$tier;$($sa.Kind)"
    }
}
Write-Output "Core Count  $([System.Environment]::ProcessorCount)"
if ($ColParamsforChild.count -eq 0) {
    Write-Output "No Storage account found under subscription $subscriptionid , please note that Premium storage does not support metrics and excluded from the collection!"
    exit
}
    $sa = $null
    $LogTracker = @()
    $blobdate = (Get-date).AddHours(-1).ToUniversalTime().ToString(" yyyy/MM/dd/HH00" )
    $hash['Host'] = $host
    $hash['subscriptionInfo'] = $SubscriptionInfo
    $hash['ArmConn'] = $ArmConn
    $hash['AsmConn'] = $AsmConn
    $hash['headers'] = $headers
    $hash['headerasm'] = $headers
    $hash['AzureCert'] = $AzureCert
    $hash['Timestampfield'] = $Timestampfield
    $hash['customerID'] = $CustomerID
    $hash['syncInterval'] = $SyncInterval
    $hash['sharedKey'] = $SharedKey
    $hash['Logname'] = $logname
    $hash['ApiVerSaAsm'] = $ApiVerSaAsm
    $hash['ApiVerSaArm'] = $ApiVerSaArm
    $hash['ApiStorage'] = $ApiStorage
    $hash['AAAccount'] = $AAAccount
    $hash['AAResourceGroup'] = $AAResourceGroup
    $hash['debuglog'] = $true
    $hash['logTracker'] = @()
    $SAInfo = @()
    $hash.'SAInfo' = $sainfo
    $Throttle = [int][System.Environment]::ProcessorCount + 1
    $sessionstate = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
    $runspacepool = [runspacefactory]::CreateRunspacePool(1, $Throttle, $sessionstate, $Host)
    $runspacepool.Open()
[System.Collections.ArrayList]$Jobs = @()
    $ScriptBlock = {
    Param ($hash, [array]$Sa, $rsid)
    $SubscriptionInfo = $hash.subscriptionInfo
    $ArmConn = $hash.ArmConn
    $headers = $hash.headers
    $AsmConn = $hash.AsmConn
    $headerasm = $hash.headerasm
    $AzureCert = $hash.AzureCert
    $Timestampfield = $hash.Timestampfield
    $Currency = $hash.Currency
    $Locale = $hash.Locale
    $RegionInfo = $hash.RegionInfo
    $OfferDurableId = $hash.OfferDurableId
    $SyncInterval = $Hash.syncInterval
    $CustomerID = $hash.customerID
    $SharedKey = $hash.sharedKey
    $logname = $hash.Logname
    $StartTime = [dateTime]::Now
    $ApiVerSaAsm = $hash.ApiVerSaAsm
    $ApiVerSaArm = $hash.ApiVerSaArm
    $ApiStorage = $hash.ApiStorage
    $AAAccount = $hash.AAAccount
    $AAResourceGroup = $hash.AAResourceGroup
    $debuglog = $hash.deguglog
    $VarQueueList = "AzureSAIngestion-List-Queues"
    $VarFilesList = "AzureSAIngestion-List-Files"
    $SubscriptionId = $SubscriptionInfo.subscriptionId
    [OutputType([bool])]
 ($CustomerId, $SharedKey, $date, $method, $resource, $uri) {
    $StringToHash = $method + " `n" + " `n" + " `n$(date) `n" + "/" + $resource + $uri.AbsolutePath
        Add-Type -AssemblyName System.Web
    $query = [System.Web.HttpUtility]::ParseQueryString($uri.query)
    $querystr = ''
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource, $EncodedHash
        return $authorization
    }
    function New-StorageSignature ($SharedKey, $date, $method, $bodylength, $resource, $uri , $service) {
        Add-Type -AssemblyName System.Web
    $str = New-Object -TypeName "System.Text.StringBuilder" ;
    $builder = [System.Text.StringBuilder]::new("/" )
    $builder.Append($resource) |out-null
    $builder.Append($uri.AbsolutePath) | out-null
    $str.Append($builder.ToString()) | out-null
    $values2 = @{}
        IF ($service -eq 'Table') {
    $values = [System.Web.HttpUtility]::ParseQueryString($uri.query)
            foreach ($str2 in $values.Keys) {
                [System.Collections.ArrayList]$list = $values.GetValues($str2)
    $list.sort()
    $builder2 = [System.Text.StringBuilder]::new()
                foreach ($obj2 in $list) {
                    if ($builder2.Length -gt 0) {
    $builder2.Append(" ," );
                    }
    $builder2.Append($obj2.ToString()) |Out-Null
                }
                IF ($null -ne $str2) {
    $values2.add($str2.ToLowerInvariant(), $builder2.ToString())
                }
            }
    $list2 = [System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
            foreach ($str3 in $list2) {
                IF ($str3 -eq 'comp') {
    $builder3 = [System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" =" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" ?" ) |out-null
    $str.Append($builder3.ToString())|out-null
                }
            }
        }
        Else {
    $values = [System.Web.HttpUtility]::ParseQueryString($uri.query)
            foreach ($str2 in $values.Keys) {
                [System.Collections.ArrayList]$list = $values.GetValues($str2)
    $list.sort()
    $builder2 = [System.Text.StringBuilder]::new()
                foreach ($obj2 in $list) {
                    if ($builder2.Length -gt 0) {
    $builder2.Append(" ," );
                    }
    $builder2.Append($obj2.ToString()) |Out-Null
                }
                IF ($null -ne $str2) {
    $values2.add($str2.ToLowerInvariant(), $builder2.ToString())
                }
            }
    $list2 = [System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
            foreach ($str3 in $list2) {
    $builder3 = [System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" :" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" `n" ) |out-null
    $str.Append($builder3.ToString())|out-null
            }
        }
    $XHeaders = " x-ms-date:$(date) `n" + " x-ms-version:$ApiStorage"
        if ($service -eq 'Table') {
    $StringToHash = $method + " `n" + " `n" + " `n$(date) `n" + $str.ToString()
        }
        Else {
            IF ($method -eq 'GET' -or $method -eq 'HEAD') {
    $StringToHash = $method + " `n" + " `n" + " `n" + " `n" + " `n" + " application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" + $str.ToString()
            }
            Else {
    $StringToHash = $method + " `n" + " `n" + " `n$(bodylength) `n" + " `n" + " application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" + $str.ToString()
            }
        }
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource, $EncodedHash
        return $authorization
    }
    Function invoke-StorageREST($SharedKey, $method, $msgbody, $resource, $uri, $svc, $download) {
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
        If ($method -eq 'PUT') {
    $params = @{
                uri = $uri
                date = $rfc1123date
                service = $svc } Else {
                resource = $resource
                sharedKey = $SharedKey
                bodylength = $msgbody.length
                method = $method
            }
    $signature @params
    $params = @{
               uri = $uri
               date = $rfc1123date
               service = $svc }
               resource = $resource
               sharedKey = $SharedKey
               body = $body
               method = $method
           }
           ; @params
        If ($svc -eq 'Table') {
    $headersforsa = @{
                'Authorization'         = " $signature"
                'x-ms-version'          = " $apistorage"
                'x-ms-date'             = " $rfc1123date"
                'Accept-Charset'        = 'UTF-8'
                'MaxDataServiceVersion' = '3.0;NetFx'
                'Accept'                = 'application/json;odata=nometadata'
            }
        }
        Else {
    $HeadersforSA = @{
                'x-ms-date'     = " $rfc1123date"
                'Content-Type'  = 'application\xml'
                'Authorization' = " $signature"
                'x-ms-version'  = " $ApiStorage"
            }
        }
        IF ($download) {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody  -OutFile " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
            return " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
        }
        Else {
            If ($svc -eq 'Table') {
                IF ($method -eq 'PUT') {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method  -UseBasicParsing -Body $msgbody
                    return $resp1
                }
                Else {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method   -UseBasicParsing -Body $msgbody
    $xresp = $resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
                }
                return $xresp
            }
            Else {
                IF ($method -eq 'PUT') {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
                    return $resp1
                }
                Elseif ($method -eq 'GET') {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody -ea 0
    $xresp = $resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
                    return $xresp
                }
                Elseif ($method -eq 'HEAD') {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
                    return $resp1
                }
            }
        }
    }
    function Get-BlobSize -ErrorAction Stop ($bloburi, $storageaccount, $rg, $type) {
        If ($type -eq 'ARM') {
    $Uri = "https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.Storage/storageAccounts/{1}/listKeys?api-version={0}" -f $ApiVerSaArm, $storageaccount, $rg, $SubscriptionId
    $keyresp = Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys = ConvertFrom-Json -InputObject $keyresp.Content
    $prikey = $keys.keys[0].value
        }
        Elseif ($type -eq 'Classic') {
    $Uri = "https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.ClassicStorage/storageAccounts/{1}/listKeys?api-version={0}" -f $ApiVerSaAsm, $storageaccount, $rg, $SubscriptionId
    $keyresp = Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys = ConvertFrom-Json -InputObject $keyresp.Content
    $prikey = $keys.primaryKey
        }
        Else {
            "Could not detect storage account type, $storageaccount will not be processed"
            Continue
        }
    $vhdblob = invoke-StorageREST -sharedKey $prikey -method HEAD -resource $storageaccount -uri $bloburi
        Return [math]::round($vhdblob.Headers.'Content-Length' / 1024 / 1024 / 1024, 0)
    }
    function New-OMSSignature ($CustomerId, $SharedKey, $date, $ContentLength, $method, $ContentType, $resource) {
    $XHeaders = " x-ms-date:" + $date
    $StringToHash = $method + " `n$(contentLength) `n" + $ContentType + " `n$(xHeaders) `n" + $resource
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $CustomerId, $EncodedHash
        return $authorization
    }
    Function Post-OMSData($CustomerId, $SharedKey, $body, $LogType) {
    $method = "POST"
    $ContentType = " application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
    $ContentLength = $body.Length
    $params = @{
            date = $rfc1123date
            contentLength = $ContentLength
            resource = $resource ;  $uri = "https://$(customerId) .ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01" ;  $OMSheaders = @{ "Authorization"        = $signature; "Log-Type"             = $LogType; " x-ms-date"            = $rfc1123date; " time-generated-field" = $TimeStampField; }
            sharedKey = $SharedKey
            customerId = $CustomerId
            contentType = $ContentType
            fileName = $FileName
            method = $method
        }
    $signature @params
        Try {
    $response = Invoke-WebRequest -Uri $uri -Method POST  -ContentType $ContentType -Headers $OMSheaders -Body $body -UseBasicParsing
        }catch [Net.WebException] {
    $ex = $_.Exception
            If ($_.Exception.Response.StatusCode.value__) {
    $exrespcode = ($_.Exception.Response.StatusCode.value__ ).ToString().Trim();
            }
            If ($_.Exception.Message) {
    $ExMessage = ($_.Exception.Message).ToString().Trim();
            }
    $errmsg = " $exrespcode : $ExMessage"
        }
        if ($errmsg) {return $errmsg }
        Else {	return $response.StatusCode }
        Write-error $error[0]
    }
    $prikey = $storageaccount = $rg =;  $type = $null
    $storageaccount = $sa.Split(';')[0]
    $rg = $sa.Split(';')[1]
    $type = $sa.Split(';')[2]
    $tier = $sa.Split(';')[3]
    $kind = $sa.Split(';')[4]
    If ($type -eq 'ARM') {
    $Uri = "https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.Storage/storageAccounts/{1}/listKeys?api-version={0}" -f $ApiVerSaArm, $storageaccount, $rg, $SubscriptionId
    $keyresp = Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys = ConvertFrom-Json -InputObject $keyresp.Content
    $prikey = $keys.keys[0].value
    }
    Elseif ($type -eq 'Classic') {
    $Uri = "https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.ClassicStorage/storageAccounts/{1}/listKeys?api-version={0}" -f $ApiVerSaAsm, $storageaccount, $rg, $SubscriptionId
    $keyresp = Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys = ConvertFrom-Json -InputObject $keyresp.Content
    $prikey = $keys.primaryKey
    }
    Else {
        "Could not detect storage account type, $storageaccount will not be processed"
        Continue
    }
    IF ($kind -eq 'BlobStorage') {
    $svclist = @('blob', 'table')
    }
    Else {
    $svclist = @('blob', 'table', 'queue')
    }
    $logging = $false
    Foreach ($svc in $svclist) {
        [uri]$UriSvcProp = "https://{0}.{1}.core.windows.net/?restype=service&comp=properties	" -f $storageaccount, $svc
        IF ($svc -eq 'table') {
            [xml]$SvcPropResp = invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriSvcProp -svc Table
        }
        else {
            [xml]$SvcPropResp = invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriSvcProp
        }
        IF ($SvcPropResp.StorageServiceProperties.Logging.Read -eq 'true' -or $SvcPropResp.StorageServiceProperties.Logging.Write -eq 'true' -or $SvcPropResp.StorageServiceProperties.Logging.Delete -eq 'true') {
    $msg = "Logging is enabled for {0} in {1}" -f $svc, $storageaccount
    $logging = $true
        }
        Else {
    $msg = "Logging is not  enabled for {0} in {1}" -f $svc, $storageaccount
        }
    }
    $hash.SAInfo += New-Object -ErrorAction Stop PSObject -Property @{
        StorageAccount = $storageaccount
        Key            = $prikey
        Logging        = $logging
        Rg             = $rg
        Type           = $type
        Tier           = $tier
        Kind           = $kind
    }
}
write-output " $($ColParamsforChild.count) objects will be processed "
$i = 1
    $Starttimer = get-date -ErrorAction Stop
    $ColParamsforChild|foreach {
    $splitmetrics = $null
    $splitmetrics = $_
    $Job = [powershell]::Create().AddScript($ScriptBlock).AddArgument($hash).AddArgument($splitmetrics).Addargument($i)
    $Job.RunspacePool = $RunspacePool
    $Jobs = $Jobs + New-Object -ErrorAction Stop PSObject -Property @{
        RunNum = $i
        Pipe   = $Job
        Result = $Job.BeginInvoke()
    }
    $i++
}
write-output  " $(get-date)  , started $i Runspaces "
Write-Output "After dispatching runspaces $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
    $JobsClone = $jobs.clone()
Write-Output "Waiting.."
$s = 1
Do {
    Write-Output "  $(@($jobs.result.iscompleted|where{$_  -match 'False'}).count)  jobs remaining"
    foreach ($jobobj in $JobsClone) {
        if ($Jobobj.result.IsCompleted -eq $true) {
    $jobobj.Pipe.Endinvoke($jobobj.Result)
    $jobobj.pipe.dispose()
    $jobs.Remove($jobobj)
        }
    }
    IF ($([System.gc]::gettotalmemory('forcefullcollection') / 1MB) -gt 200) {
        [gc]::Collect()
    }
    IF ($s % 10 -eq 0) {
        Write-Output "Job $s - Mem: $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
    }
    $s++
    Start-Sleep -Seconds 15
} While ( @($jobs.result.iscompleted|where {$_ -match 'False'}).count -gt 0)
Write-output "All jobs completed!"
    $jobs|foreach {$_.Pipe.Dispose()}
Remove-Variable -ErrorAction Stop Jobs -Force -Scope Global
Remove-Variable -ErrorAction Stop Job -Force -Scope Global
Remove-Variable -ErrorAction Stop Jobobj -Force -Scope Global
Remove-Variable -ErrorAction Stop Jobsclone -Force -Scope Global
    $runspacepool.Close()
[gc]::Collect()
    $StartupVariables =
new-variable -force -name startupVariables -value ( Get-Variable -ErrorAction Stop |
    % { $_.Name } )
Write-Output "Memory After Initial pool for keys : $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
    $sa = $null
    $LogTracker = @()
    $blobdate = (Get-date).AddHours(-1).ToUniversalTime().ToString(" yyyy/MM/dd/HH00" )
$s = 1
write-output $hash.SAInfo|select Logging , storageaccount
foreach ($sa in @($hash.SAInfo|Where {$_.Logging -eq 'True' -and $_.key -ne $null})) {
    $prikey = $sa.key
    $storageaccount = $sa.StorageAccount
    $rg = $sa.rg
    $type = $sa.Type
    $tier = $sa.Tier
    $kind = $sa.Kind
    $LogArray = @()
    $Logcount = 0
    $LogSize = 0
    Foreach ($svc in @('blob', 'table', 'queue')) {
    $blobs = @()
    $prefix = $svc + "/" + $blobdate
        [uri]$UriLBlobs = "https://{0}.blob.core.windows.net/`$logs`?restype=container&comp=list&prefix={1}&maxresults=1000" -f $storageaccount, $prefix
        [xml]$fresponse = invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriLBlobs
    $content = $null
    $content = $fresponse.EnumerationResults
    $blobs = $blobs + $content.Blobs.blob
        REmove-Variable -Name fresponse
        IF (![string]::IsNullOrEmpty($content.NextMarker)) {
            do {
                [uri]$UriLogs2 = "https://{0}.blob.core.windows.net/`$logs`?restype=container&comp=list&maxresults=1000&marker={1}" -f $storageaccount, $content.NextMarker
    $content = $null
                [xml]$Logresp2 = invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriLogs2
    $content = $Logresp2.EnumerationResults
    $blobs = $blobs + $content.Blobs.Blob
    $UriLogs2 = $null
            }While (![string]::IsNullOrEmpty($content.NextMarker))
        }
    $fresponse = $logresp2 = $null
        IF ($blobs) {
            Foreach ($blob in $blobs) {
                [uri]$UriLogs3 = "https://{0}.blob.core.windows.net/`$logs/{1}" -f $storageaccount, $blob.Name
    $content = $null
    $auditlog = invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriLogs3 -download $true
                if (Test-Path $auditlog) {
    $file = New-Object -ErrorAction Stop System.IO.StreamReader -Arg $auditlog
                    while ($line = $file.ReadLine()) {
    $splitline = [regex]::Split( $line , ';(?=(?:[^" ]|" [^" ]*" )*$)' )
    $LogArray = $LogArray + New-Object -ErrorAction Stop PSObject -Property @{
                            Timestamp          = $splitline[1]
                            MetricName         = 'AuditLogs'
                            StorageAccount     = $storageaccount
                            StorageService     = $splitline[10]
                            Operation          = $splitline[2]
                            Status             = $splitline[3]
                            StatusCode         = $splitline[4]
                            E2ELatency         = [int]$splitline[5]
                            ServerLatency      = [int]$splitline[6]
                            AuthenticationType = $splitline[7]
                            Requesteraccount   = $splitline[8]
                            Resource           = $splitline[12].Replace('" ', '')
                            RequesterIP        = $splitline[15].Split(':')[0]
                            UserAgent          = $splitline[27].Replace('" ', '')
                            SubscriptionId     = $ArmConn.SubscriptionId;
                            AzureSubscription  = $SubscriptionInfo.displayName;
                        }
                    }
    $file.close()
    $file = get-item -ErrorAction Stop $auditlog
    $Logcount++
    $LogSize = $LogSize + [Math]::Round($file.Length / 1024, 0)
                    Remove-Item -ErrorAction Stop $auditl -Forceo -Forceg -Force
                    IF ($LogArray.count -gt 5000 -or $([System.gc]::gettotalmemory('forcefullcollection') / 1MB) -gt 150) {
                        write-output " $($LogArray.count)  logs consumed $([System.gc]::gettotalmemory('forcefullcollection') /1MB) , uploading data  to OMS"
    $jsonlogs = ConvertTo-Json -InputObject $LogArray
    $logarray = @()
                        Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
                        remove-variable -ErrorAction Stop jsonlogs -force
                        [gc]::Collect()
                    }
                }
            }
    $auditlog = $file = $null
        }
        write-output " $($blobs.count)  log file processed for $storageaccount. $($logarray.count) records wil be uploaded"
    }
    Remove-Variable -Name Blobs
    $LogTracker = $LogTracker + New-Object -ErrorAction Stop PSObject -Property @{
        StorageAccount = $storageaccount
        Logcount       = $Logcount
        LogSizeinKB    = $LogSize
    }
}
If ($LogArray) {
    $SplitSize = 5000
    If ($LogArray.count -gt $SplitSize) {
    $spltlist = @()
    $spltlist = $spltlist + for ($Index = 0; $Index -lt $LogArray.count; $Index = $Index + $SplitSize) {
            , ($LogArray[$index..($index + $SplitSize - 1)])
        }
    $spltlist|foreach {
    $SplitLogs = $null
    $SplitLogs = $_
    $jsonlogs = ConvertTo-Json -InputObject $SplitLogs
            Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
        }
    }
    Else {
    $jsonlogs = ConvertTo-Json -InputObject $LogArray
        Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
    }
}
IF ($s % 10 -eq 0) {
    Write-Output "Job $s - SA $storageaccount -Logsize : $logsize - Mem: $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
}
    $s++
Remove-Variable -Name  logArray -ea 0
Remove-Variable -Name  fresponse -ea 0
Remove-Variable -Name  auditlog -ea 0
Remove-Variable -Name  jsonlogs  -ea 0
[gc]::Collect()
.Exception.Message
}
function Cleanup-Variables {
    Get-Variable -ErrorAction Stop |
    Where-Object { $StartupVariables -notcontains $_.Name } |
    % { Remove-Variable -Name $($_.Name) -Force -Scope global }
}
"Logging in to Azure..."
    $ArmConn = Get-AutomationConnection -Name AzureRunAsConnection
if ($null -eq $ArmConn)
{
	throw "Could not retrieve connection asset AzureRunAsConnection,  Ensure that runas account  exists in the Automation account."
}
    $retry = 6
    $SyncOk = $false
do
{
	try
	{
		Add-AzureRMAccount -ServicePrincipal -Tenant $ArmConn.TenantID -ApplicationId $ArmConn.ApplicationID -CertificateThumbprint $ArmConn.CertificateThumbprint
    $SyncOk = $true
	}
	catch
	{
    $ErrorMessage = $_.Exception.Message
    $StackTrace = $_.Exception.StackTrace
		Write-Warning "Error during sync: $ErrorMessage, stack: $StackTrace. Retry attempts left: $retry"
    $retry = $retry - 1
		Start-Sleep -s 60
	}
} while (-not $SyncOk -and $retry -ge 0)
"Selecting Azure subscription..."
    $SelectedAzureSub = Select-AzureRmSubscription -SubscriptionId $ArmConn.SubscriptionId -TenantId $ArmConn.tenantid
    $subscriptionid=$ArmConn.SubscriptionId
"Azure rm profile path  $((get-module -Name AzureRM.Profile).path) "
    $path=(get-module -Name AzureRM.Profile).path
    $path=Split-Path $path
    $dlllist=Get-ChildItem -Path $path  -Filter Microsoft.IdentityModel.Clients.ActiveDirectory.dll  -Recurse
    $adal =  $dlllist[0].VersionInfo.FileName
try
{
	Add-type -Path $adal
	[reflection.assembly]::LoadWithPartialName( "Microsoft.IdentityModel.Clients.ActiveDirectory" )
}
catch
{
    $ErrorMessage = $_.Exception.Message
    $StackTrace = $_.Exception.StackTrace
	Write-Warning "Error during sync: $ErrorMessage, stack: $StackTrace. "
}
    $certs= Get-ChildItem -Path Cert:\Currentuser\my -Recurse | Where{$_.Thumbprint -eq $ArmConn.CertificateThumbprint}
[System.Security.Cryptography.X509Certificates.X509Certificate2]$mycert=$certs[0]
    $CliCert=new-object -ErrorAction Stop  Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate($ArmConn.ApplicationId,$mycert)
    $AuthContext = new-object -ErrorAction Stop Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext(" https://login.windows.net/$($ArmConn.tenantid)" )
    $result = $AuthContext.AcquireToken(" https://management.core.windows.net/" ,$CliCert);
    $header = "Bearer " + $result.AccessToken;
    $headers = @{"Authorization" =$header;"Accept" =" application/json" }
    $body=$null
    $HTTPVerb="GET"
    $SubscriptionInfoUri = "https://management.azure.com/subscriptions/$(subscriptionid)?api-version=2016-02-01"
    $SubscriptionInfo = Invoke-RestMethod -Uri $SubscriptionInfoUri -Headers $headers -Method Get -UseBasicParsing
IF($SubscriptionInfo)
{
	"Successfully connected to Azure ARM REST"
}
if ($GetAsmHeader) {
	try
    {
    $AsmConn = Get-AutomationConnection -Name AzureClassicRunAsConnection -ea 0
    }
    Catch
    {
        if ($null -eq $AsmConn) {
            Write-Warning "Could not retrieve connection asset AzureClassicRunAsConnection. Ensure that runas account exist and valid in the Automation account."
    $GetAsmHeader=$false
        }
    }
     if ($null -eq $AsmConn) {
        Write-Warning "Could not retrieve connection asset AzureClassicRunAsConnection. Ensure that runas account exist and valid in the Automation account. Quota usage infomration for classic accounts will no tbe collected"
    $GetAsmHeader=$false
    }Else{
    $CertificateAssetName = $AsmConn.CertificateAssetName
    $AzureCert = Get-AutomationCertificate -Name $CertificateAssetName
        if ($null -eq $AzureCert)
        {
            Write-Warning  "Could not retrieve certificate asset: $CertificateAssetName. Ensure that this asset exists and valid  in the Automation account."
    $GetAsmHeader=$false
        }
        Else{
        "Logging into Azure Service Manager"
        Write-Verbose "Authenticating to Azure with certificate." -Verbose
        Set-AzureSubscription -SubscriptionName $AsmConn.SubscriptionName -SubscriptionId $AsmConn.SubscriptionId -Certificate $AzureCert
        Select-AzureSubscription -SubscriptionId $AsmConn.SubscriptionId
    $headerasm = @{" x-ms-version" =" 2013-08-01" }
        }
    }
}
    $SubscriptionsURI = "https://management.azure.com/subscriptions?api-version=2016-06-01"
    $Subscriptions = Invoke-RestMethod -Uri  $SubscriptionsURI -Method GET  -Headers $headers -UseBasicParsing
    $Subscriptions = @($Subscriptions.value)
IF ($CollectionFromAllSubscriptions -and $Subscriptions.count -gt 1 ) {
    Write-Output " $($Subscriptions.count) Subscription found , additonal runbook jobs will be created to collect data "
    $AAResourceGroup = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationResourceGroup-MS-Mgmt-SA'
    $AAAccount = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationAccount-MS-Mgmt-SA'
    $LogsRunbookName = "AzureSAIngestionLogs-MS-Mgmt-SA"
    $subslist = $subscriptions|where {$_.subscriptionId -ne $SubscriptionId}
    Foreach ($item in $subslist) {
    $params1 = @{"SubscriptionidFilter" = $item.subscriptionId; " collectionFromAllSubscriptions" = $false; " getAsmHeader" = $false}
        Start-AzureRmAutomationRunbook -AutomationAccountName $AAAccount -Name $LogsRunbookName -ResourceGroupName $AAResourceGroup -Parameters $params1 | out-null
    }
}
" $(GEt-date) - Get ARM storage Accounts "
    $Uri = "https://management.azure.com/subscriptions/{1}/providers/Microsoft.Storage/storageAccounts?api-version={0}" -f $ApiVerSaArm, $SubscriptionId
    $armresp = Invoke-RestMethod -Uri $uri -Method GET  -Headers $headers -UseBasicParsing
    $SaArmList = $armresp.Value
" $(GEt-date)  $($SaArmList.count) classic storage accounts found"
" $(GEt-date)  Get Classic storage Accounts "
    $Uri = "https://management.azure.com/subscriptions/{1}/providers/Microsoft.ClassicStorage/storageAccounts?api-version={0}" -f $ApiVerSaAsm, $SubscriptionId
    $asmresp = Invoke-RestMethod -Uri $uri -Method GET  -Headers $headers -UseBasicParsing
    $SaAsmList = $asmresp.value
" $(GEt-date)  $($SaAsmList.count) storage accounts found"
    $ColParamsforChild = @()
foreach ($sa in $SaArmList|where {$_.Sku.tier -ne 'Premium'}) {
    $rg =;  $sku = $null
    $rg = $sa.id.Split('/')[4]
    $ColParamsforChild = $ColParamsforChild + " $($sa.name);$($sa.id.Split('/')[4]);ARM;$($sa.sku.tier);$($sa.Kind)"
}
    $sa = $rg = $null
foreach ($sa in $SaAsmList|where {$_.properties.accounttype -notmatch 'Premium'}) {
    $rg = $sa.id.Split('/')[4]
    $tier = $null
    If ( $sa.properties.accountType -notmatch 'premium') {
    $tier = 'Standard'
    $ColParamsforChild = $ColParamsforChild + " $($sa.name);$($sa.id.Split('/')[4]);Classic;$tier;$($sa.Kind)"
    }
}
Write-Output "Core Count  $([System.Environment]::ProcessorCount)"
if ($ColParamsforChild.count -eq 0) {
    Write-Output "No Storage account found under subscription $subscriptionid , please note that Premium storage does not support metrics and excluded from the collection!"
    exit
}
    $sa = $null
    $LogTracker = @()
    $blobdate = (Get-date).AddHours(-1).ToUniversalTime().ToString(" yyyy/MM/dd/HH00" )
    $hash['Host'] = $host
    $hash['subscriptionInfo'] = $SubscriptionInfo
    $hash['ArmConn'] = $ArmConn
    $hash['AsmConn'] = $AsmConn
    $hash['headers'] = $headers
    $hash['headerasm'] = $headers
    $hash['AzureCert'] = $AzureCert
    $hash['Timestampfield'] = $Timestampfield
    $hash['customerID'] = $CustomerID
    $hash['syncInterval'] = $SyncInterval
    $hash['sharedKey'] = $SharedKey
    $hash['Logname'] = $logname
    $hash['ApiVerSaAsm'] = $ApiVerSaAsm
    $hash['ApiVerSaArm'] = $ApiVerSaArm
    $hash['ApiStorage'] = $ApiStorage
    $hash['AAAccount'] = $AAAccount
    $hash['AAResourceGroup'] = $AAResourceGroup
    $hash['debuglog'] = $true
    $hash['logTracker'] = @()
    $SAInfo = @()
    $hash.'SAInfo' = $sainfo
    $Throttle = [int][System.Environment]::ProcessorCount + 1
    $sessionstate = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
    $runspacepool = [runspacefactory]::CreateRunspacePool(1, $Throttle, $sessionstate, $Host)
    $runspacepool.Open()
[System.Collections.ArrayList]$Jobs = @()
    $ScriptBlock = {
    Param ($hash, [array]$Sa, $rsid)
    $SubscriptionInfo = $hash.subscriptionInfo
    $ArmConn = $hash.ArmConn
    $headers = $hash.headers
    $AsmConn = $hash.AsmConn
    $headerasm = $hash.headerasm
    $AzureCert = $hash.AzureCert
    $Timestampfield = $hash.Timestampfield
    $Currency = $hash.Currency
    $Locale = $hash.Locale
    $RegionInfo = $hash.RegionInfo
    $OfferDurableId = $hash.OfferDurableId
    $SyncInterval = $Hash.syncInterval
    $CustomerID = $hash.customerID
    $SharedKey = $hash.sharedKey
    $logname = $hash.Logname
    $StartTime = [dateTime]::Now
    $ApiVerSaAsm = $hash.ApiVerSaAsm
    $ApiVerSaArm = $hash.ApiVerSaArm
    $ApiStorage = $hash.ApiStorage
    $AAAccount = $hash.AAAccount
    $AAResourceGroup = $hash.AAResourceGroup
    $debuglog = $hash.deguglog
    $VarQueueList = "AzureSAIngestion-List-Queues"
    $VarFilesList = "AzureSAIngestion-List-Files"
    $SubscriptionId = $SubscriptionInfo.subscriptionId
    [OutputType([bool])]
 ($CustomerId, $SharedKey, $date, $method, $resource, $uri) {
    $StringToHash = $method + " `n" + " `n" + " `n$(date) `n" + "/" + $resource + $uri.AbsolutePath
        Add-Type -AssemblyName System.Web
    $query = [System.Web.HttpUtility]::ParseQueryString($uri.query)
    $querystr = ''
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource, $EncodedHash
        return $authorization
    }
    function New-StorageSignature ($SharedKey, $date, $method, $bodylength, $resource, $uri , $service) {
        Add-Type -AssemblyName System.Web
    $str = New-Object -TypeName "System.Text.StringBuilder" ;
    $builder = [System.Text.StringBuilder]::new("/" )
    $builder.Append($resource) |out-null
    $builder.Append($uri.AbsolutePath) | out-null
    $str.Append($builder.ToString()) | out-null
    $values2 = @{}
        IF ($service -eq 'Table') {
    $values = [System.Web.HttpUtility]::ParseQueryString($uri.query)
            foreach ($str2 in $values.Keys) {
                [System.Collections.ArrayList]$list = $values.GetValues($str2)
    $list.sort()
    $builder2 = [System.Text.StringBuilder]::new()
                foreach ($obj2 in $list) {
                    if ($builder2.Length -gt 0) {
    $builder2.Append(" ," );
                    }
    $builder2.Append($obj2.ToString()) |Out-Null
                }
                IF ($null -ne $str2) {
    $values2.add($str2.ToLowerInvariant(), $builder2.ToString())
                }
            }
    $list2 = [System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
            foreach ($str3 in $list2) {
                IF ($str3 -eq 'comp') {
    $builder3 = [System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" =" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" ?" ) |out-null
    $str.Append($builder3.ToString())|out-null
                }
            }
        }
        Else {
    $values = [System.Web.HttpUtility]::ParseQueryString($uri.query)
            foreach ($str2 in $values.Keys) {
                [System.Collections.ArrayList]$list = $values.GetValues($str2)
    $list.sort()
    $builder2 = [System.Text.StringBuilder]::new()
                foreach ($obj2 in $list) {
                    if ($builder2.Length -gt 0) {
    $builder2.Append(" ," );
                    }
    $builder2.Append($obj2.ToString()) |Out-Null
                }
                IF ($null -ne $str2) {
    $values2.add($str2.ToLowerInvariant(), $builder2.ToString())
                }
            }
    $list2 = [System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
            foreach ($str3 in $list2) {
    $builder3 = [System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" :" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" `n" ) |out-null
    $str.Append($builder3.ToString())|out-null
            }
        }
    $XHeaders = " x-ms-date:$(date) `n" + " x-ms-version:$ApiStorage"
        if ($service -eq 'Table') {
    $StringToHash = $method + " `n" + " `n" + " `n$(date) `n" + $str.ToString()
        }
        Else {
            IF ($method -eq 'GET' -or $method -eq 'HEAD') {
    $StringToHash = $method + " `n" + " `n" + " `n" + " `n" + " `n" + " application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" + $str.ToString()
            }
            Else {
    $StringToHash = $method + " `n" + " `n" + " `n$(bodylength) `n" + " `n" + " application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" + $str.ToString()
            }
        }
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource, $EncodedHash
        return $authorization
    }
    Function invoke-StorageREST($SharedKey, $method, $msgbody, $resource, $uri, $svc, $download) {
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
        If ($method -eq 'PUT') {
    $params = @{
                uri = $uri
                date = $rfc1123date
                service = $svc } Else {
                resource = $resource
                sharedKey = $SharedKey
                bodylength = $msgbody.length
                method = $method
            }
    $signature @params
    $params = @{
               uri = $uri
               date = $rfc1123date
               service = $svc }
               resource = $resource
               sharedKey = $SharedKey
               body = $body
               method = $method
           }
           ; @params
        If ($svc -eq 'Table') {
    $headersforsa = @{
                'Authorization'         = " $signature"
                'x-ms-version'          = " $apistorage"
                'x-ms-date'             = " $rfc1123date"
                'Accept-Charset'        = 'UTF-8'
                'MaxDataServiceVersion' = '3.0;NetFx'
                'Accept'                = 'application/json;odata=nometadata'
            }
        }
        Else {
    $HeadersforSA = @{
                'x-ms-date'     = " $rfc1123date"
                'Content-Type'  = 'application\xml'
                'Authorization' = " $signature"
                'x-ms-version'  = " $ApiStorage"
            }
        }
        IF ($download) {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody  -OutFile " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
            return " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
        }
        Else {
            If ($svc -eq 'Table') {
                IF ($method -eq 'PUT') {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method  -UseBasicParsing -Body $msgbody
                    return $resp1
                }
                Else {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method   -UseBasicParsing -Body $msgbody
    $xresp = $resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
                }
                return $xresp
            }
            Else {
                IF ($method -eq 'PUT') {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
                    return $resp1
                }
                Elseif ($method -eq 'GET') {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody -ea 0
    $xresp = $resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
                    return $xresp
                }
                Elseif ($method -eq 'HEAD') {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
                    return $resp1
                }
            }
        }
    }
    function Get-BlobSize -ErrorAction Stop ($bloburi, $storageaccount, $rg, $type) {
        If ($type -eq 'ARM') {
    $Uri = "https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.Storage/storageAccounts/{1}/listKeys?api-version={0}" -f $ApiVerSaArm, $storageaccount, $rg, $SubscriptionId
    $keyresp = Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys = ConvertFrom-Json -InputObject $keyresp.Content
    $prikey = $keys.keys[0].value
        }
        Elseif ($type -eq 'Classic') {
    $Uri = "https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.ClassicStorage/storageAccounts/{1}/listKeys?api-version={0}" -f $ApiVerSaAsm, $storageaccount, $rg, $SubscriptionId
    $keyresp = Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys = ConvertFrom-Json -InputObject $keyresp.Content
    $prikey = $keys.primaryKey
        }
        Else {
            "Could not detect storage account type, $storageaccount will not be processed"
            Continue
        }
    $vhdblob = invoke-StorageREST -sharedKey $prikey -method HEAD -resource $storageaccount -uri $bloburi
        Return [math]::round($vhdblob.Headers.'Content-Length' / 1024 / 1024 / 1024, 0)
    }
    function New-OMSSignature ($CustomerId, $SharedKey, $date, $ContentLength, $method, $ContentType, $resource) {
    $XHeaders = " x-ms-date:" + $date
    $StringToHash = $method + " `n$(contentLength) `n" + $ContentType + " `n$(xHeaders) `n" + $resource
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $CustomerId, $EncodedHash
        return $authorization
    }
    Function Post-OMSData($CustomerId, $SharedKey, $body, $LogType) {
    $method = "POST"
    $ContentType = " application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
    $ContentLength = $body.Length
    $params = @{
            date = $rfc1123date
            contentLength = $ContentLength
            resource = $resource ;  $uri = "https://$(customerId) .ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01" ;  $OMSheaders = @{ "Authorization"        = $signature; "Log-Type"             = $LogType; " x-ms-date"            = $rfc1123date; " time-generated-field" = $TimeStampField; }
            sharedKey = $SharedKey
            customerId = $CustomerId
            contentType = $ContentType
            fileName = $FileName
            method = $method
        }
    $signature @params
        Try {
    $response = Invoke-WebRequest -Uri $uri -Method POST  -ContentType $ContentType -Headers $OMSheaders -Body $body -UseBasicParsing
        }catch [Net.WebException] {
    $ex = $_.Exception
            If ($_.Exception.Response.StatusCode.value__) {
    $exrespcode = ($_.Exception.Response.StatusCode.value__ ).ToString().Trim();
            }
            If ($_.Exception.Message) {
    $ExMessage = ($_.Exception.Message).ToString().Trim();
            }
    $errmsg = " $exrespcode : $ExMessage"
        }
        if ($errmsg) {return $errmsg }
        Else {	return $response.StatusCode }
        Write-error
    $ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $SubscriptionidFilter,
    [Parameter(Mandatory = $false)] [bool] $CollectionFromAllSubscriptions = $false,
    [Parameter(Mandatory = $false)] [bool] $GetAsmHeader = $true)
Write-Output "RB Initial Memory  : $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
    $StartTime = [dateTime]::Now
    $Timestampfield = "Timestamp"
    $timestamp = $StartTime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:45:00.000Z" )
    $CustomerID = Get-AutomationVariable -Name 'AzureSAIngestion-OPSINSIGHTS_WS_ID-MS-Mgmt-SA'
    $SharedKey = Get-AutomationVariable -Name 'AzureSAIngestion-OPSINSIGHTS_WS_KEY-MS-Mgmt-SA'
    $ApiVerSaAsm = '2016-04-01'
    $ApiVerSaArm = '2016-01-01'
    $ApiStorage = '2016-05-31'
    $AAAccount = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationAccount-MS-Mgmt-SA'
    $AAResourceGroup = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationResourceGroup-MS-Mgmt-SA'
    $logname = 'AzureStorage'
    $childrunbook = "AzureSAIngestionChild-MS-Mgmt-SA"
    $schedulename = "AzureStorageIngestionChild-Schedule-MS-Mgmt-SA"
    $hash = [hashtable]::New(@{})
    $Starttimer = get-date -ErrorAction Stop
[OutputType([bool])]
 ($CustomerId, $SharedKey, $date, $method, $resource, $uri) {
    $StringToHash = $method + " `n" + " `n" + " `n$(date) `n" + "/" + $resource + $uri.AbsolutePath
    Add-Type -AssemblyName System.Web
    $query = [System.Web.HttpUtility]::ParseQueryString($uri.query)
    $querystr = ''
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource, $EncodedHash
    return $authorization
}
function New-StorageSignature ($SharedKey, $date, $method, $bodylength, $resource, $uri , $service) {
    Add-Type -AssemblyName System.Web
    $str = New-Object -TypeName "System.Text.StringBuilder" ;
    $builder = [System.Text.StringBuilder]::new("/" )
    $builder.Append($resource) |out-null
    $builder.Append($uri.AbsolutePath) | out-null
    $str.Append($builder.ToString()) | out-null
    $values2 = @{}
    IF ($service -eq 'Table') {
    $values = [System.Web.HttpUtility]::ParseQueryString($uri.query)
        foreach ($str2 in $values.Keys) {
            [System.Collections.ArrayList]$list = $values.GetValues($str2)
    $list.sort()
    $builder2 = [System.Text.StringBuilder]::new()
            foreach ($obj2 in $list) {
                if ($builder2.Length -gt 0) {
    $builder2.Append(" ," );
                }
    $builder2.Append($obj2.ToString()) |Out-Null
            }
            IF ($null -ne $str2) {
    $values2.add($str2.ToLowerInvariant(), $builder2.ToString())
            }
        }
    $list2 = [System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
        foreach ($str3 in $list2) {
            IF ($str3 -eq 'comp') {
    $builder3 = [System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" =" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" ?" ) |out-null
    $str.Append($builder3.ToString())|out-null
            }
        }
    }
    Else {
    $values = [System.Web.HttpUtility]::ParseQueryString($uri.query)
        foreach ($str2 in $values.Keys) {
            [System.Collections.ArrayList]$list = $values.GetValues($str2)
    $list.sort()
    $builder2 = [System.Text.StringBuilder]::new()
            foreach ($obj2 in $list) {
                if ($builder2.Length -gt 0) {
    $builder2.Append(" ," );
                }
    $builder2.Append($obj2.ToString()) |Out-Null
            }
            IF ($null -ne $str2) {
    $values2.add($str2.ToLowerInvariant(), $builder2.ToString())
            }
        }
    $list2 = [System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
        foreach ($str3 in $list2) {
    $builder3 = [System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" :" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" `n" ) |out-null
    $str.Append($builder3.ToString())|out-null
        }
    }
    $XHeaders = " x-ms-date:$(date) `n" + " x-ms-version:$ApiStorage"
    if ($service -eq 'Table') {
    $StringToHash = $method + " `n" + " `n" + " `n$(date) `n" + $str.ToString()
    }
    Else {
        IF ($method -eq 'GET' -or $method -eq 'HEAD') {
    $StringToHash = $method + " `n" + " `n" + " `n" + " `n" + " `n" + " application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" + $str.ToString()
        }
        Else {
    $StringToHash = $method + " `n" + " `n" + " `n$(bodylength) `n" + " `n" + " application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" + $str.ToString()
        }
    }
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource, $EncodedHash
    return $authorization
}
Function invoke-StorageREST($SharedKey, $method, $msgbody, $resource, $uri, $svc, $download) {
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
    If ($method -eq 'PUT') {
    $params = @{
            uri = $uri
            date = $rfc1123date
            service = $svc } Else {
            resource = $resource
            sharedKey = $SharedKey
            bodylength = $msgbody.length
            method = $method
        }
    $signature @params
    $params = @{
           uri = $uri
           date = $rfc1123date
           service = $svc }
           resource = $resource
           sharedKey = $SharedKey
           body = $body
           method = $method
       }
       ; @params
    If ($svc -eq 'Table') {
    $headersforsa = @{
            'Authorization'         = " $signature"
            'x-ms-version'          = " $apistorage"
            'x-ms-date'             = " $rfc1123date"
            'Accept-Charset'        = 'UTF-8'
            'MaxDataServiceVersion' = '3.0;NetFx'
            'Accept'                = 'application/json;odata=nometadata'
        }
    }
    Else {
    $HeadersforSA = @{
            'x-ms-date'     = " $rfc1123date"
            'Content-Type'  = 'application\xml'
            'Authorization' = " $signature"
            'x-ms-version'  = " $ApiStorage"
        }
    }
    IF ($download) {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody  -OutFile " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
        return " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
    }
    Else {
        If ($svc -eq 'Table') {
            IF ($method -eq 'PUT') {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method  -UseBasicParsing -Body $msgbody
                return $resp1
            }
            Else {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method   -UseBasicParsing -Body $msgbody
    $xresp = $resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
            }
            return $xresp
        }
        Else {
            IF ($method -eq 'PUT') {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
                return $resp1
            }
            Elseif ($method -eq 'GET') {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody -ea 0
    $xresp = $resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
                return $xresp
            }
            Elseif ($method -eq 'HEAD') {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
                return $resp1
            }
        }
    }
}
function Get-BlobSize -ErrorAction Stop ($bloburi, $storageaccount, $rg, $type) {
    If ($type -eq 'ARM') {
    $Uri = "https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.Storage/storageAccounts/{1}/listKeys?api-version={0}" -f $ApiVerSaArm, $storageaccount, $rg, $SubscriptionId
    $keyresp = Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys = ConvertFrom-Json -InputObject $keyresp.Content
    $prikey = $keys.keys[0].value
    }
    Elseif ($type -eq 'Classic') {
    $Uri = "https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.ClassicStorage/storageAccounts/{1}/listKeys?api-version={0}" -f $ApiVerSaAsm, $storageaccount, $rg, $SubscriptionId
    $keyresp = Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys = ConvertFrom-Json -InputObject $keyresp.Content
    $prikey = $keys.primaryKey
    }
    Else {
        "Could not detect storage account type, $storageaccount will not be processed"
        Continue
    }
    $vhdblob = invoke-StorageREST -sharedKey $prikey -method HEAD -resource $storageaccount -uri $bloburi
    Return [math]::round($vhdblob.Headers.'Content-Length' / 1024 / 1024 / 1024, 0)
}
function New-OMSSignature ($CustomerId, $SharedKey, $date, $ContentLength, $method, $ContentType, $resource) {
    $XHeaders = " x-ms-date:" + $date
    $StringToHash = $method + " `n$(contentLength) `n" + $ContentType + " `n$(xHeaders) `n" + $resource
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $CustomerId, $EncodedHash
    return $authorization
}
Function Post-OMSData($CustomerId, $SharedKey, $body, $LogType) {
    $method = "POST"
    $ContentType = " application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
    $ContentLength = $body.Length
    $params = @{
        date = $rfc1123date
        contentLength = $ContentLength
        resource = $resource ;  $uri = "https://$(customerId) .ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01" ;  $OMSheaders = @{ "Authorization"        = $signature; "Log-Type"             = $LogType; " x-ms-date"            = $rfc1123date; " time-generated-field" = $TimeStampField; }
        sharedKey = $SharedKey
        customerId = $CustomerId
        contentType = $ContentType
        fileName = $FileName
        method = $method
    }
    $signature @params
    Try {
    $response = Invoke-WebRequest -Uri $uri -Method POST  -ContentType $ContentType -Headers $OMSheaders -Body $body -UseBasicParsing
    }catch [Net.WebException] {
    $ex = $_.Exception
        If ($_.Exception.Response.StatusCode.value__) {
    $exrespcode = ($_.Exception.Response.StatusCode.value__ ).ToString().Trim();
        }
        If ($_.Exception.Message) {
    $ExMessage = ($_.Exception.Message).ToString().Trim();
        }
    $errmsg = " $exrespcode : $ExMessage"
    }
    if ($errmsg) {return $errmsg }
    Else {	return $response.StatusCode }
    Write-error $error[0]
}
function Cleanup-Variables {
    Get-Variable -ErrorAction Stop |
    Where-Object { $StartupVariables -notcontains $_.Name } |
    % { Remove-Variable -Name $($_.Name) -Force -Scope global }
}
"Logging in to Azure..."
    $ArmConn = Get-AutomationConnection -Name AzureRunAsConnection
if ($null -eq $ArmConn)
{
	throw "Could not retrieve connection asset AzureRunAsConnection,  Ensure that runas account  exists in the Automation account."
}
    $retry = 6
    $SyncOk = $false
do
{
	try
	{
		Add-AzureRMAccount -ServicePrincipal -Tenant $ArmConn.TenantID -ApplicationId $ArmConn.ApplicationID -CertificateThumbprint $ArmConn.CertificateThumbprint
    $SyncOk = $true
	}
	catch
	{
    $ErrorMessage = $_.Exception.Message
    $StackTrace = $_.Exception.StackTrace
		Write-Warning "Error during sync: $ErrorMessage, stack: $StackTrace. Retry attempts left: $retry"
    $retry = $retry - 1
		Start-Sleep -s 60
	}
} while (-not $SyncOk -and $retry -ge 0)
"Selecting Azure subscription..."
    $SelectedAzureSub = Select-AzureRmSubscription -SubscriptionId $ArmConn.SubscriptionId -TenantId $ArmConn.tenantid
    $subscriptionid=$ArmConn.SubscriptionId
"Azure rm profile path  $((get-module -Name AzureRM.Profile).path) "
    $path=(get-module -Name AzureRM.Profile).path
    $path=Split-Path $path
    $dlllist=Get-ChildItem -Path $path  -Filter Microsoft.IdentityModel.Clients.ActiveDirectory.dll  -Recurse
    $adal =  $dlllist[0].VersionInfo.FileName
try
{
	Add-type -Path $adal
	[reflection.assembly]::LoadWithPartialName( "Microsoft.IdentityModel.Clients.ActiveDirectory" )
}
catch
{
    $ErrorMessage = $_.Exception.Message
    $StackTrace = $_.Exception.StackTrace
	Write-Warning "Error during sync: $ErrorMessage, stack: $StackTrace. "
}
    $certs= Get-ChildItem -Path Cert:\Currentuser\my -Recurse | Where{$_.Thumbprint -eq $ArmConn.CertificateThumbprint}
[System.Security.Cryptography.X509Certificates.X509Certificate2]$mycert=$certs[0]
    $CliCert=new-object -ErrorAction Stop  Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate($ArmConn.ApplicationId,$mycert)
    $AuthContext = new-object -ErrorAction Stop Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext(" https://login.windows.net/$($ArmConn.tenantid)" )
    $result = $AuthContext.AcquireToken(" https://management.core.windows.net/" ,$CliCert);
    $header = "Bearer " + $result.AccessToken;
    $headers = @{"Authorization" =$header;"Accept" =" application/json" }
    $body=$null
    $HTTPVerb="GET"
    $SubscriptionInfoUri = "https://management.azure.com/subscriptions/$(subscriptionid)?api-version=2016-02-01"
    $SubscriptionInfo = Invoke-RestMethod -Uri $SubscriptionInfoUri -Headers $headers -Method Get -UseBasicParsing
IF($SubscriptionInfo)
{
	"Successfully connected to Azure ARM REST"
}
if ($GetAsmHeader) {
	try
    {
    $AsmConn = Get-AutomationConnection -Name AzureClassicRunAsConnection -ea 0
    }
    Catch
    {
        if ($null -eq $AsmConn) {
            Write-Warning "Could not retrieve connection asset AzureClassicRunAsConnection. Ensure that runas account exist and valid in the Automation account."
    $GetAsmHeader=$false
        }
    }
     if ($null -eq $AsmConn) {
        Write-Warning "Could not retrieve connection asset AzureClassicRunAsConnection. Ensure that runas account exist and valid in the Automation account. Quota usage infomration for classic accounts will no tbe collected"
    $GetAsmHeader=$false
    }Else{
    $CertificateAssetName = $AsmConn.CertificateAssetName
    $AzureCert = Get-AutomationCertificate -Name $CertificateAssetName
        if ($null -eq $AzureCert)
        {
            Write-Warning  "Could not retrieve certificate asset: $CertificateAssetName. Ensure that this asset exists and valid  in the Automation account."
    $GetAsmHeader=$false
        }
        Else{
        "Logging into Azure Service Manager"
        Write-Verbose "Authenticating to Azure with certificate." -Verbose
        Set-AzureSubscription -SubscriptionName $AsmConn.SubscriptionName -SubscriptionId $AsmConn.SubscriptionId -Certificate $AzureCert
        Select-AzureSubscription -SubscriptionId $AsmConn.SubscriptionId
    $headerasm = @{" x-ms-version" =" 2013-08-01" }
        }
    }
}
    $SubscriptionsURI = "https://management.azure.com/subscriptions?api-version=2016-06-01"
    $Subscriptions = Invoke-RestMethod -Uri  $SubscriptionsURI -Method GET  -Headers $headers -UseBasicParsing
    $Subscriptions = @($Subscriptions.value)
IF ($CollectionFromAllSubscriptions -and $Subscriptions.count -gt 1 ) {
    Write-Output " $($Subscriptions.count) Subscription found , additonal runbook jobs will be created to collect data "
    $AAResourceGroup = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationResourceGroup-MS-Mgmt-SA'
    $AAAccount = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationAccount-MS-Mgmt-SA'
    $LogsRunbookName = "AzureSAIngestionLogs-MS-Mgmt-SA"
    $subslist = $subscriptions|where {$_.subscriptionId -ne $SubscriptionId}
    Foreach ($item in $subslist) {
    $params1 = @{"SubscriptionidFilter" = $item.subscriptionId; " collectionFromAllSubscriptions" = $false; " getAsmHeader" = $false}
        Start-AzureRmAutomationRunbook -AutomationAccountName $AAAccount -Name $LogsRunbookName -ResourceGroupName $AAResourceGroup -Parameters $params1 | out-null
    }
}
" $(GEt-date) - Get ARM storage Accounts "
    $Uri = "https://management.azure.com/subscriptions/{1}/providers/Microsoft.Storage/storageAccounts?api-version={0}" -f $ApiVerSaArm, $SubscriptionId
    $armresp = Invoke-RestMethod -Uri $uri -Method GET  -Headers $headers -UseBasicParsing
    $SaArmList = $armresp.Value
" $(GEt-date)  $($SaArmList.count) classic storage accounts found"
" $(GEt-date)  Get Classic storage Accounts "
    $Uri = "https://management.azure.com/subscriptions/{1}/providers/Microsoft.ClassicStorage/storageAccounts?api-version={0}" -f $ApiVerSaAsm, $SubscriptionId
    $asmresp = Invoke-RestMethod -Uri $uri -Method GET  -Headers $headers -UseBasicParsing
    $SaAsmList = $asmresp.value
" $(GEt-date)  $($SaAsmList.count) storage accounts found"
    $ColParamsforChild = @()
foreach ($sa in $SaArmList|where {$_.Sku.tier -ne 'Premium'}) {
    $rg =;  $sku = $null
    $rg = $sa.id.Split('/')[4]
    $ColParamsforChild = $ColParamsforChild + " $($sa.name);$($sa.id.Split('/')[4]);ARM;$($sa.sku.tier);$($sa.Kind)"
}
    $sa = $rg = $null
foreach ($sa in $SaAsmList|where {$_.properties.accounttype -notmatch 'Premium'}) {
    $rg = $sa.id.Split('/')[4]
    $tier = $null
    If ( $sa.properties.accountType -notmatch 'premium') {
    $tier = 'Standard'
    $ColParamsforChild = $ColParamsforChild + " $($sa.name);$($sa.id.Split('/')[4]);Classic;$tier;$($sa.Kind)"
    }
}
Write-Output "Core Count  $([System.Environment]::ProcessorCount)"
if ($ColParamsforChild.count -eq 0) {
    Write-Output "No Storage account found under subscription $subscriptionid , please note that Premium storage does not support metrics and excluded from the collection!"
    exit
}
    $sa = $null
    $LogTracker = @()
    $blobdate = (Get-date).AddHours(-1).ToUniversalTime().ToString(" yyyy/MM/dd/HH00" )
    $hash['Host'] = $host
    $hash['subscriptionInfo'] = $SubscriptionInfo
    $hash['ArmConn'] = $ArmConn
    $hash['AsmConn'] = $AsmConn
    $hash['headers'] = $headers
    $hash['headerasm'] = $headers
    $hash['AzureCert'] = $AzureCert
    $hash['Timestampfield'] = $Timestampfield
    $hash['customerID'] = $CustomerID
    $hash['syncInterval'] = $SyncInterval
    $hash['sharedKey'] = $SharedKey
    $hash['Logname'] = $logname
    $hash['ApiVerSaAsm'] = $ApiVerSaAsm
    $hash['ApiVerSaArm'] = $ApiVerSaArm
    $hash['ApiStorage'] = $ApiStorage
    $hash['AAAccount'] = $AAAccount
    $hash['AAResourceGroup'] = $AAResourceGroup
    $hash['debuglog'] = $true
    $hash['logTracker'] = @()
    $SAInfo = @()
    $hash.'SAInfo' = $sainfo
    $Throttle = [int][System.Environment]::ProcessorCount + 1
    $sessionstate = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
    $runspacepool = [runspacefactory]::CreateRunspacePool(1, $Throttle, $sessionstate, $Host)
    $runspacepool.Open()
[System.Collections.ArrayList]$Jobs = @()
    $ScriptBlock = {
    Param ($hash, [array]$Sa, $rsid)
    $SubscriptionInfo = $hash.subscriptionInfo
    $ArmConn = $hash.ArmConn
    $headers = $hash.headers
    $AsmConn = $hash.AsmConn
    $headerasm = $hash.headerasm
    $AzureCert = $hash.AzureCert
    $Timestampfield = $hash.Timestampfield
    $Currency = $hash.Currency
    $Locale = $hash.Locale
    $RegionInfo = $hash.RegionInfo
    $OfferDurableId = $hash.OfferDurableId
    $SyncInterval = $Hash.syncInterval
    $CustomerID = $hash.customerID
    $SharedKey = $hash.sharedKey
    $logname = $hash.Logname
    $StartTime = [dateTime]::Now
    $ApiVerSaAsm = $hash.ApiVerSaAsm
    $ApiVerSaArm = $hash.ApiVerSaArm
    $ApiStorage = $hash.ApiStorage
    $AAAccount = $hash.AAAccount
    $AAResourceGroup = $hash.AAResourceGroup
    $debuglog = $hash.deguglog
    $VarQueueList = "AzureSAIngestion-List-Queues"
    $VarFilesList = "AzureSAIngestion-List-Files"
    $SubscriptionId = $SubscriptionInfo.subscriptionId
    [OutputType([bool])]
 ($CustomerId, $SharedKey, $date, $method, $resource, $uri) {
    $StringToHash = $method + " `n" + " `n" + " `n$(date) `n" + "/" + $resource + $uri.AbsolutePath
        Add-Type -AssemblyName System.Web
    $query = [System.Web.HttpUtility]::ParseQueryString($uri.query)
    $querystr = ''
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource, $EncodedHash
        return $authorization
    }
    function New-StorageSignature ($SharedKey, $date, $method, $bodylength, $resource, $uri , $service) {
        Add-Type -AssemblyName System.Web
    $str = New-Object -TypeName "System.Text.StringBuilder" ;
    $builder = [System.Text.StringBuilder]::new("/" )
    $builder.Append($resource) |out-null
    $builder.Append($uri.AbsolutePath) | out-null
    $str.Append($builder.ToString()) | out-null
    $values2 = @{}
        IF ($service -eq 'Table') {
    $values = [System.Web.HttpUtility]::ParseQueryString($uri.query)
            foreach ($str2 in $values.Keys) {
                [System.Collections.ArrayList]$list = $values.GetValues($str2)
    $list.sort()
    $builder2 = [System.Text.StringBuilder]::new()
                foreach ($obj2 in $list) {
                    if ($builder2.Length -gt 0) {
    $builder2.Append(" ," );
                    }
    $builder2.Append($obj2.ToString()) |Out-Null
                }
                IF ($null -ne $str2) {
    $values2.add($str2.ToLowerInvariant(), $builder2.ToString())
                }
            }
    $list2 = [System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
            foreach ($str3 in $list2) {
                IF ($str3 -eq 'comp') {
    $builder3 = [System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" =" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" ?" ) |out-null
    $str.Append($builder3.ToString())|out-null
                }
            }
        }
        Else {
    $values = [System.Web.HttpUtility]::ParseQueryString($uri.query)
            foreach ($str2 in $values.Keys) {
                [System.Collections.ArrayList]$list = $values.GetValues($str2)
    $list.sort()
    $builder2 = [System.Text.StringBuilder]::new()
                foreach ($obj2 in $list) {
                    if ($builder2.Length -gt 0) {
    $builder2.Append(" ," );
                    }
    $builder2.Append($obj2.ToString()) |Out-Null
                }
                IF ($null -ne $str2) {
    $values2.add($str2.ToLowerInvariant(), $builder2.ToString())
                }
            }
    $list2 = [System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
            foreach ($str3 in $list2) {
    $builder3 = [System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" :" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" `n" ) |out-null
    $str.Append($builder3.ToString())|out-null
            }
        }
    $XHeaders = " x-ms-date:$(date) `n" + " x-ms-version:$ApiStorage"
        if ($service -eq 'Table') {
    $StringToHash = $method + " `n" + " `n" + " `n$(date) `n" + $str.ToString()
        }
        Else {
            IF ($method -eq 'GET' -or $method -eq 'HEAD') {
    $StringToHash = $method + " `n" + " `n" + " `n" + " `n" + " `n" + " application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" + $str.ToString()
            }
            Else {
    $StringToHash = $method + " `n" + " `n" + " `n$(bodylength) `n" + " `n" + " application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" + $str.ToString()
            }
        }
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource, $EncodedHash
        return $authorization
    }
    Function invoke-StorageREST($SharedKey, $method, $msgbody, $resource, $uri, $svc, $download) {
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
        If ($method -eq 'PUT') {
    $params = @{
                uri = $uri
                date = $rfc1123date
                service = $svc } Else {
                resource = $resource
                sharedKey = $SharedKey
                bodylength = $msgbody.length
                method = $method
            }
    $signature @params
    $params = @{
               uri = $uri
               date = $rfc1123date
               service = $svc }
               resource = $resource
               sharedKey = $SharedKey
               body = $body
               method = $method
           }
           ; @params
        If ($svc -eq 'Table') {
    $headersforsa = @{
                'Authorization'         = " $signature"
                'x-ms-version'          = " $apistorage"
                'x-ms-date'             = " $rfc1123date"
                'Accept-Charset'        = 'UTF-8'
                'MaxDataServiceVersion' = '3.0;NetFx'
                'Accept'                = 'application/json;odata=nometadata'
            }
        }
        Else {
    $HeadersforSA = @{
                'x-ms-date'     = " $rfc1123date"
                'Content-Type'  = 'application\xml'
                'Authorization' = " $signature"
                'x-ms-version'  = " $ApiStorage"
            }
        }
        IF ($download) {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody  -OutFile " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
            return " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
        }
        Else {
            If ($svc -eq 'Table') {
                IF ($method -eq 'PUT') {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method  -UseBasicParsing -Body $msgbody
                    return $resp1
                }
                Else {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method   -UseBasicParsing -Body $msgbody
    $xresp = $resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
                }
                return $xresp
            }
            Else {
                IF ($method -eq 'PUT') {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
                    return $resp1
                }
                Elseif ($method -eq 'GET') {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody -ea 0
    $xresp = $resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
                    return $xresp
                }
                Elseif ($method -eq 'HEAD') {
    $resp1 = Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
                    return $resp1
                }
            }
        }
    }
    function Get-BlobSize -ErrorAction Stop ($bloburi, $storageaccount, $rg, $type) {
        If ($type -eq 'ARM') {
    $Uri = "https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.Storage/storageAccounts/{1}/listKeys?api-version={0}" -f $ApiVerSaArm, $storageaccount, $rg, $SubscriptionId
    $keyresp = Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys = ConvertFrom-Json -InputObject $keyresp.Content
    $prikey = $keys.keys[0].value
        }
        Elseif ($type -eq 'Classic') {
    $Uri = "https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.ClassicStorage/storageAccounts/{1}/listKeys?api-version={0}" -f $ApiVerSaAsm, $storageaccount, $rg, $SubscriptionId
    $keyresp = Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys = ConvertFrom-Json -InputObject $keyresp.Content
    $prikey = $keys.primaryKey
        }
        Else {
            "Could not detect storage account type, $storageaccount will not be processed"
            Continue
        }
    $vhdblob = invoke-StorageREST -sharedKey $prikey -method HEAD -resource $storageaccount -uri $bloburi
        Return [math]::round($vhdblob.Headers.'Content-Length' / 1024 / 1024 / 1024, 0)
    }
    function New-OMSSignature ($CustomerId, $SharedKey, $date, $ContentLength, $method, $ContentType, $resource) {
    $XHeaders = " x-ms-date:" + $date
    $StringToHash = $method + " `n$(contentLength) `n" + $ContentType + " `n$(xHeaders) `n" + $resource
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $CustomerId, $EncodedHash
        return $authorization
    }
    Function Post-OMSData($CustomerId, $SharedKey, $body, $LogType) {
    $method = "POST"
    $ContentType = " application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
    $ContentLength = $body.Length
    $params = @{
            date = $rfc1123date
            contentLength = $ContentLength
            resource = $resource ;  $uri = "https://$(customerId) .ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01" ;  $OMSheaders = @{ "Authorization"        = $signature; "Log-Type"             = $LogType; " x-ms-date"            = $rfc1123date; " time-generated-field" = $TimeStampField; }
            sharedKey = $SharedKey
            customerId = $CustomerId
            contentType = $ContentType
            fileName = $FileName
            method = $method
        }
    $signature @params
        Try {
    $response = Invoke-WebRequest -Uri $uri -Method POST  -ContentType $ContentType -Headers $OMSheaders -Body $body -UseBasicParsing
        }catch [Net.WebException] {
    $ex = $_.Exception
            If ($_.Exception.Response.StatusCode.value__) {
    $exrespcode = ($_.Exception.Response.StatusCode.value__ ).ToString().Trim();
            }
            If ($_.Exception.Message) {
    $ExMessage = ($_.Exception.Message).ToString().Trim();
            }
    $errmsg = " $exrespcode : $ExMessage"
        }
        if ($errmsg) {return $errmsg }
        Else {	return $response.StatusCode }
        Write-error $error[0]
    }
    $prikey = $storageaccount = $rg =;  $type = $null
    $storageaccount = $sa.Split(';')[0]
    $rg = $sa.Split(';')[1]
    $type = $sa.Split(';')[2]
    $tier = $sa.Split(';')[3]
    $kind = $sa.Split(';')[4]
    If ($type -eq 'ARM') {
    $Uri = "https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.Storage/storageAccounts/{1}/listKeys?api-version={0}" -f $ApiVerSaArm, $storageaccount, $rg, $SubscriptionId
    $keyresp = Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys = ConvertFrom-Json -InputObject $keyresp.Content
    $prikey = $keys.keys[0].value
    }
    Elseif ($type -eq 'Classic') {
    $Uri = "https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.ClassicStorage/storageAccounts/{1}/listKeys?api-version={0}" -f $ApiVerSaAsm, $storageaccount, $rg, $SubscriptionId
    $keyresp = Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys = ConvertFrom-Json -InputObject $keyresp.Content
    $prikey = $keys.primaryKey
    }
    Else {
        "Could not detect storage account type, $storageaccount will not be processed"
        Continue
    }
    IF ($kind -eq 'BlobStorage') {
    $svclist = @('blob', 'table')
    }
    Else {
    $svclist = @('blob', 'table', 'queue')
    }
    $logging = $false
    Foreach ($svc in $svclist) {
        [uri]$UriSvcProp = "https://{0}.{1}.core.windows.net/?restype=service&comp=properties	" -f $storageaccount, $svc
        IF ($svc -eq 'table') {
            [xml]$SvcPropResp = invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriSvcProp -svc Table
        }
        else {
            [xml]$SvcPropResp = invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriSvcProp
        }
        IF ($SvcPropResp.StorageServiceProperties.Logging.Read -eq 'true' -or $SvcPropResp.StorageServiceProperties.Logging.Write -eq 'true' -or $SvcPropResp.StorageServiceProperties.Logging.Delete -eq 'true') {
    $msg = "Logging is enabled for {0} in {1}" -f $svc, $storageaccount
    $logging = $true
        }
        Else {
    $msg = "Logging is not  enabled for {0} in {1}" -f $svc, $storageaccount
        }
    }
    $hash.SAInfo += New-Object -ErrorAction Stop PSObject -Property @{
        StorageAccount = $storageaccount
        Key            = $prikey
        Logging        = $logging
        Rg             = $rg
        Type           = $type
        Tier           = $tier
        Kind           = $kind
    }
}
write-output " $($ColParamsforChild.count) objects will be processed "
$i = 1
    $Starttimer = get-date -ErrorAction Stop
    $ColParamsforChild|foreach {
    $splitmetrics = $null
    $splitmetrics = $_
    $Job = [powershell]::Create().AddScript($ScriptBlock).AddArgument($hash).AddArgument($splitmetrics).Addargument($i)
    $Job.RunspacePool = $RunspacePool
    $Jobs = $Jobs + New-Object -ErrorAction Stop PSObject -Property @{
        RunNum = $i
        Pipe   = $Job
        Result = $Job.BeginInvoke()
    }
    $i++
}
write-output  " $(get-date)  , started $i Runspaces "
Write-Output "After dispatching runspaces $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
    $JobsClone = $jobs.clone()
Write-Output "Waiting.."
$s = 1
Do {
    Write-Output "  $(@($jobs.result.iscompleted|where{$_  -match 'False'}).count)  jobs remaining"
    foreach ($jobobj in $JobsClone) {
        if ($Jobobj.result.IsCompleted -eq $true) {
    $jobobj.Pipe.Endinvoke($jobobj.Result)
    $jobobj.pipe.dispose()
    $jobs.Remove($jobobj)
        }
    }
    IF ($([System.gc]::gettotalmemory('forcefullcollection') / 1MB) -gt 200) {
        [gc]::Collect()
    }
    IF ($s % 10 -eq 0) {
        Write-Output "Job $s - Mem: $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
    }
    $s++
    Start-Sleep -Seconds 15
} While ( @($jobs.result.iscompleted|where {$_ -match 'False'}).count -gt 0)
Write-output "All jobs completed!"
    $jobs|foreach {$_.Pipe.Dispose()}
Remove-Variable -ErrorAction Stop Jobs -Force -Scope Global
Remove-Variable -ErrorAction Stop Job -Force -Scope Global
Remove-Variable -ErrorAction Stop Jobobj -Force -Scope Global
Remove-Variable -ErrorAction Stop Jobsclone -Force -Scope Global
    $runspacepool.Close()
[gc]::Collect()
    $StartupVariables =
new-variable -force -name startupVariables -value ( Get-Variable -ErrorAction Stop |
    % { $_.Name } )
Write-Output "Memory After Initial pool for keys : $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
    $sa = $null
    $LogTracker = @()
    $blobdate = (Get-date).AddHours(-1).ToUniversalTime().ToString(" yyyy/MM/dd/HH00" )
$s = 1
write-output $hash.SAInfo|select Logging , storageaccount
foreach ($sa in @($hash.SAInfo|Where {$_.Logging -eq 'True' -and $_.key -ne $null})) {
    $prikey = $sa.key
    $storageaccount = $sa.StorageAccount
    $rg = $sa.rg
    $type = $sa.Type
    $tier = $sa.Tier
    $kind = $sa.Kind
    $LogArray = @()
    $Logcount = 0
    $LogSize = 0
    Foreach ($svc in @('blob', 'table', 'queue')) {
    $blobs = @()
    $prefix = $svc + "/" + $blobdate
        [uri]$UriLBlobs = "https://{0}.blob.core.windows.net/`$logs`?restype=container&comp=list&prefix={1}&maxresults=1000" -f $storageaccount, $prefix
        [xml]$fresponse = invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriLBlobs
    $content = $null
    $content = $fresponse.EnumerationResults
    $blobs = $blobs + $content.Blobs.blob
        REmove-Variable -Name fresponse
        IF (![string]::IsNullOrEmpty($content.NextMarker)) {
            do {
                [uri]$UriLogs2 = "https://{0}.blob.core.windows.net/`$logs`?restype=container&comp=list&maxresults=1000&marker={1}" -f $storageaccount, $content.NextMarker
    $content = $null
                [xml]$Logresp2 = invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriLogs2
    $content = $Logresp2.EnumerationResults
    $blobs = $blobs + $content.Blobs.Blob
    $UriLogs2 = $null
            }While (![string]::IsNullOrEmpty($content.NextMarker))
        }
    $fresponse = $logresp2 = $null
        IF ($blobs) {
            Foreach ($blob in $blobs) {
                [uri]$UriLogs3 = "https://{0}.blob.core.windows.net/`$logs/{1}" -f $storageaccount, $blob.Name
    $content = $null
    $auditlog = invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriLogs3 -download $true
                if (Test-Path $auditlog) {
    $file = New-Object -ErrorAction Stop System.IO.StreamReader -Arg $auditlog
                    while ($line = $file.ReadLine()) {
    $splitline = [regex]::Split( $line , ';(?=(?:[^" ]|" [^" ]*" )*$)' )
    $LogArray = $LogArray + New-Object -ErrorAction Stop PSObject -Property @{
                            Timestamp          = $splitline[1]
                            MetricName         = 'AuditLogs'
                            StorageAccount     = $storageaccount
                            StorageService     = $splitline[10]
                            Operation          = $splitline[2]
                            Status             = $splitline[3]
                            StatusCode         = $splitline[4]
                            E2ELatency         = [int]$splitline[5]
                            ServerLatency      = [int]$splitline[6]
                            AuthenticationType = $splitline[7]
                            Requesteraccount   = $splitline[8]
                            Resource           = $splitline[12].Replace('" ', '')
                            RequesterIP        = $splitline[15].Split(':')[0]
                            UserAgent          = $splitline[27].Replace('" ', '')
                            SubscriptionId     = $ArmConn.SubscriptionId;
                            AzureSubscription  = $SubscriptionInfo.displayName;
                        }
                    }
    $file.close()
    $file = get-item -ErrorAction Stop $auditlog
    $Logcount++
    $LogSize = $LogSize + [Math]::Round($file.Length / 1024, 0)
                    Remove-Item -ErrorAction Stop $auditl -Forceo -Forceg -Force
                    IF ($LogArray.count -gt 5000 -or $([System.gc]::gettotalmemory('forcefullcollection') / 1MB) -gt 150) {
                        write-output " $($LogArray.count)  logs consumed $([System.gc]::gettotalmemory('forcefullcollection') /1MB) , uploading data  to OMS"
    $jsonlogs = ConvertTo-Json -InputObject $LogArray
    $logarray = @()
                        Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
                        remove-variable -ErrorAction Stop jsonlogs -force
                        [gc]::Collect()
                    }
                }
            }
    $auditlog = $file = $null
        }
        write-output " $($blobs.count)  log file processed for $storageaccount. $($logarray.count) records wil be uploaded"
    }
    Remove-Variable -Name Blobs
    $LogTracker = $LogTracker + New-Object -ErrorAction Stop PSObject -Property @{
        StorageAccount = $storageaccount
        Logcount       = $Logcount
        LogSizeinKB    = $LogSize
    }
}
If ($LogArray) {
    $SplitSize = 5000
    If ($LogArray.count -gt $SplitSize) {
    $spltlist = @()
    $spltlist = $spltlist + for ($Index = 0; $Index -lt $LogArray.count; $Index = $Index + $SplitSize) {
            , ($LogArray[$index..($index + $SplitSize - 1)])
        }
    $spltlist|foreach {
    $SplitLogs = $null
    $SplitLogs = $_
    $jsonlogs = ConvertTo-Json -InputObject $SplitLogs
            Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
        }
    }
    Else {
    $jsonlogs = ConvertTo-Json -InputObject $LogArray
        Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
    }
}
IF ($s % 10 -eq 0) {
    Write-Output "Job $s - SA $storageaccount -Logsize : $logsize - Mem: $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
}
    $s++
Remove-Variable -Name  logArray -ea 0
Remove-Variable -Name  fresponse -ea 0
Remove-Variable -Name  auditlog -ea 0
Remove-Variable -Name  jsonlogs  -ea 0
[gc]::Collect()
.Exception.Message
    }
    $prikey = $storageaccount = $rg =;  $type = $null
    $storageaccount = $sa.Split(';')[0]
    $rg = $sa.Split(';')[1]
    $type = $sa.Split(';')[2]
    $tier = $sa.Split(';')[3]
    $kind = $sa.Split(';')[4]
    If ($type -eq 'ARM') {
    $Uri = "https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.Storage/storageAccounts/{1}/listKeys?api-version={0}" -f $ApiVerSaArm, $storageaccount, $rg, $SubscriptionId
    $keyresp = Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys = ConvertFrom-Json -InputObject $keyresp.Content
    $prikey = $keys.keys[0].value
    }
    Elseif ($type -eq 'Classic') {
    $Uri = "https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.ClassicStorage/storageAccounts/{1}/listKeys?api-version={0}" -f $ApiVerSaAsm, $storageaccount, $rg, $SubscriptionId
    $keyresp = Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys = ConvertFrom-Json -InputObject $keyresp.Content
    $prikey = $keys.primaryKey
    }
    Else {
        "Could not detect storage account type, $storageaccount will not be processed"
        Continue
    }
    IF ($kind -eq 'BlobStorage') {
    $svclist = @('blob', 'table')
    }
    Else {
    $svclist = @('blob', 'table', 'queue')
    }
    $logging = $false
    Foreach ($svc in $svclist) {
        [uri]$UriSvcProp = "https://{0}.{1}.core.windows.net/?restype=service&comp=properties	" -f $storageaccount, $svc
        IF ($svc -eq 'table') {
            [xml]$SvcPropResp = invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriSvcProp -svc Table
        }
        else {
            [xml]$SvcPropResp = invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriSvcProp
        }
        IF ($SvcPropResp.StorageServiceProperties.Logging.Read -eq 'true' -or $SvcPropResp.StorageServiceProperties.Logging.Write -eq 'true' -or $SvcPropResp.StorageServiceProperties.Logging.Delete -eq 'true') {
    $msg = "Logging is enabled for {0} in {1}" -f $svc, $storageaccount
    $logging = $true
        }
        Else {
    $msg = "Logging is not  enabled for {0} in {1}" -f $svc, $storageaccount
        }
    }
    $hash.SAInfo += New-Object -ErrorAction Stop PSObject -Property @{
        StorageAccount = $storageaccount
        Key            = $prikey
        Logging        = $logging
        Rg             = $rg
        Type           = $type
        Tier           = $tier
        Kind           = $kind
    }
}
write-output " $($ColParamsforChild.count) objects will be processed "
$i = 1
    $Starttimer = get-date -ErrorAction Stop
    $ColParamsforChild|foreach {
    $splitmetrics = $null
    $splitmetrics = $_
    $Job = [powershell]::Create().AddScript($ScriptBlock).AddArgument($hash).AddArgument($splitmetrics).Addargument($i)
    $Job.RunspacePool = $RunspacePool
    $Jobs = $Jobs + New-Object -ErrorAction Stop PSObject -Property @{
        RunNum = $i
        Pipe   = $Job
        Result = $Job.BeginInvoke()
    }
    $i++
}
write-output  " $(get-date)  , started $i Runspaces "
Write-Output "After dispatching runspaces $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
    $JobsClone = $jobs.clone()
Write-Output "Waiting.."
$s = 1
Do {
    Write-Output "  $(@($jobs.result.iscompleted|where{$_  -match 'False'}).count)  jobs remaining"
    foreach ($jobobj in $JobsClone) {
        if ($Jobobj.result.IsCompleted -eq $true) {
    $jobobj.Pipe.Endinvoke($jobobj.Result)
    $jobobj.pipe.dispose()
    $jobs.Remove($jobobj)
        }
    }
    IF ($([System.gc]::gettotalmemory('forcefullcollection') / 1MB) -gt 200) {
        [gc]::Collect()
    }
    IF ($s % 10 -eq 0) {
        Write-Output "Job $s - Mem: $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
    }
    $s++
    Start-Sleep -Seconds 15
} While ( @($jobs.result.iscompleted|where {$_ -match 'False'}).count -gt 0)
Write-output "All jobs completed!"
    $jobs|foreach {$_.Pipe.Dispose()}
Remove-Variable -ErrorAction Stop Jobs -Force -Scope Global
Remove-Variable -ErrorAction Stop Job -Force -Scope Global
Remove-Variable -ErrorAction Stop Jobobj -Force -Scope Global
Remove-Variable -ErrorAction Stop Jobsclone -Force -Scope Global
    $runspacepool.Close()
[gc]::Collect()
    $StartupVariables =
new-variable -force -name startupVariables -value ( Get-Variable -ErrorAction Stop |
    % { $_.Name } )
Write-Output "Memory After Initial pool for keys : $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
    $sa = $null
    $LogTracker = @()
    $blobdate = (Get-date).AddHours(-1).ToUniversalTime().ToString(" yyyy/MM/dd/HH00" )
$s = 1
write-output $hash.SAInfo|select Logging , storageaccount
foreach ($sa in @($hash.SAInfo|Where {$_.Logging -eq 'True' -and $_.key -ne $null})) {
    $prikey = $sa.key
    $storageaccount = $sa.StorageAccount
    $rg = $sa.rg
    $type = $sa.Type
    $tier = $sa.Tier
    $kind = $sa.Kind
    $LogArray = @()
    $Logcount = 0
    $LogSize = 0
    Foreach ($svc in @('blob', 'table', 'queue')) {
    $blobs = @()
    $prefix = $svc + "/" + $blobdate
        [uri]$UriLBlobs = "https://{0}.blob.core.windows.net/`$logs`?restype=container&comp=list&prefix={1}&maxresults=1000" -f $storageaccount, $prefix
        [xml]$fresponse = invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriLBlobs
    $content = $null
    $content = $fresponse.EnumerationResults
    $blobs = $blobs + $content.Blobs.blob
        REmove-Variable -Name fresponse
        IF (![string]::IsNullOrEmpty($content.NextMarker)) {
            do {
                [uri]$UriLogs2 = "https://{0}.blob.core.windows.net/`$logs`?restype=container&comp=list&maxresults=1000&marker={1}" -f $storageaccount, $content.NextMarker
    $content = $null
                [xml]$Logresp2 = invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriLogs2
    $content = $Logresp2.EnumerationResults
    $blobs = $blobs + $content.Blobs.Blob
    $UriLogs2 = $null
            }While (![string]::IsNullOrEmpty($content.NextMarker))
        }
    $fresponse = $logresp2 = $null
        IF ($blobs) {
            Foreach ($blob in $blobs) {
                [uri]$UriLogs3 = "https://{0}.blob.core.windows.net/`$logs/{1}" -f $storageaccount, $blob.Name
    $content = $null
    $auditlog = invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriLogs3 -download $true
                if (Test-Path $auditlog) {
    $file = New-Object -ErrorAction Stop System.IO.StreamReader -Arg $auditlog
                    while ($line = $file.ReadLine()) {
    $splitline = [regex]::Split( $line , ';(?=(?:[^" ]|" [^" ]*" )*$)' )
    $LogArray = $LogArray + New-Object -ErrorAction Stop PSObject -Property @{
                            Timestamp          = $splitline[1]
                            MetricName         = 'AuditLogs'
                            StorageAccount     = $storageaccount
                            StorageService     = $splitline[10]
                            Operation          = $splitline[2]
                            Status             = $splitline[3]
                            StatusCode         = $splitline[4]
                            E2ELatency         = [int]$splitline[5]
                            ServerLatency      = [int]$splitline[6]
                            AuthenticationType = $splitline[7]
                            Requesteraccount   = $splitline[8]
                            Resource           = $splitline[12].Replace('" ', '')
                            RequesterIP        = $splitline[15].Split(':')[0]
                            UserAgent          = $splitline[27].Replace('" ', '')
                            SubscriptionId     = $ArmConn.SubscriptionId;
                            AzureSubscription  = $SubscriptionInfo.displayName;
                        }
                    }
    $file.close()
    $file = get-item -ErrorAction Stop $auditlog
    $Logcount++
    $LogSize = $LogSize + [Math]::Round($file.Length / 1024, 0)
                    Remove-Item -ErrorAction Stop $auditl -Forceo -Forceg -Force
                    IF ($LogArray.count -gt 5000 -or $([System.gc]::gettotalmemory('forcefullcollection') / 1MB) -gt 150) {
                        write-output " $($LogArray.count)  logs consumed $([System.gc]::gettotalmemory('forcefullcollection') /1MB) , uploading data  to OMS"
    $jsonlogs = ConvertTo-Json -InputObject $LogArray
    $logarray = @()
                        Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
                        remove-variable -ErrorAction Stop jsonlogs -force
                        [gc]::Collect()
                    }
                }
            }
    $auditlog = $file = $null
        }
        write-output " $($blobs.count)  log file processed for $storageaccount. $($logarray.count) records wil be uploaded"
    }
    Remove-Variable -Name Blobs
    $LogTracker = $LogTracker + New-Object -ErrorAction Stop PSObject -Property @{
        StorageAccount = $storageaccount
        Logcount       = $Logcount
        LogSizeinKB    = $LogSize
    }
}
If ($LogArray) {
    $SplitSize = 5000
    If ($LogArray.count -gt $SplitSize) {
    $spltlist = @()
    $spltlist = $spltlist + for ($Index = 0; $Index -lt $LogArray.count; $Index = $Index + $SplitSize) {
            , ($LogArray[$index..($index + $SplitSize - 1)])
        }
    $spltlist|foreach {
    $SplitLogs = $null
    $SplitLogs = $_
    $jsonlogs = ConvertTo-Json -InputObject $SplitLogs
            Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
        }
    }
    Else {
    $jsonlogs = ConvertTo-Json -InputObject $LogArray
        Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
    }
}
IF ($s % 10 -eq 0) {
    Write-Output "Job $s - SA $storageaccount -Logsize : $logsize - Mem: $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
}
    $s++
Remove-Variable -Name  logArray -ea 0
Remove-Variable -Name  fresponse -ea 0
Remove-Variable -Name  auditlog -ea 0
Remove-Variable -Name  jsonlogs  -ea 0
[gc]::Collect()



