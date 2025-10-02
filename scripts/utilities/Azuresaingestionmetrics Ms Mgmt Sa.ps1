#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azuresaingestionmetrics Ms Mgmt Sa

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
[Parameter()] [Parameter()]
    [ValidateNotNullOrEmpty()]
    $SubscriptionidFilter,
[Parameter()] [bool] $CollectionFromAllSubscriptions=$false,
[Parameter()] [bool] $GetAsmHeader=$true)
    $ErrorActionPreference= "Stop"
Write-Output "RB Initial Memory  : $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
    $StartTime = [dateTime]::Now
    $Timestampfield = "Timestamp"
    $timestamp=$StartTime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:00.000Z" )
    $CustomerID = Get-AutomationVariable -Name 'AzureSAIngestion-OPSINSIGHTS_WS_ID-MS-Mgmt-SA'
    $SharedKey = Get-AutomationVariable -Name 'AzureSAIngestion-OPSINSIGHTS_WS_KEY-MS-Mgmt-SA'
    $ApiVerSaAsm = '2016-04-01'
    $ApiVerSaArm = '2016-01-01'
    $ApiStorage='2016-05-31'
    $AAAccount = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationAccount-MS-Mgmt-SA'
    $AAResourceGroup = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationResourceGroup-MS-Mgmt-SA'
    $logname='AzureStorage'
    $hash = [hashtable]::New(@{})
    $Starttimer=get-date -ErrorAction Stop
[OutputType([bool])]
 ($CustomerId, $SharedKey, $date,  $method,  $resource,$uri)
{
    $StringToHash = $method + " `n" + " `n" + " `n$(date) `n" +"/" +$resource+$uri.AbsolutePath
	Add-Type -AssemblyName System.Web
    $query = [System.Web.HttpUtility]::ParseQueryString($uri.query)
    $querystr=''
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource,$EncodedHash
	return $authorization
}
function New-StorageSignature ($SharedKey, $date,  $method, $bodylength, $resource,$uri ,$service)
{
	Add-Type -AssemblyName System.Web
    $str=  New-Object -TypeName "System.Text.StringBuilder" ;
    $builder=  [System.Text.StringBuilder]::new("/" )
    $builder.Append($resource) |out-null
    $builder.Append($uri.AbsolutePath) | out-null
    $str.Append($builder.ToString()) | out-null
    $values2=@{}
	IF($service -eq 'Table')
	{
    $values= [System.Web.HttpUtility]::ParseQueryString($uri.query)
		foreach ($str2 in $values.Keys)
		{
			[System.Collections.ArrayList]$list=$values.GetValues($str2)
    $list.sort()
    $builder2=  [System.Text.StringBuilder]::new()
			foreach ($obj2 in $list)
			{
				if ($builder2.Length -gt 0)
				{
    $builder2.Append(" ," );
				}
    $builder2.Append($obj2.ToString()) |Out-Null
			}
			IF ($null -ne $str2)
			{
    $values2.add($str2.ToLowerInvariant(),$builder2.ToString())
			}
		}
    $list2=[System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
		foreach ($str3 in $list2)
		{
			IF($str3 -eq 'comp')
			{
    $builder3=[System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" =" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" ?" ) |out-null
    $str.Append($builder3.ToString())|out-null
			}
		}
	}
	Else
	{
    $values= [System.Web.HttpUtility]::ParseQueryString($uri.query)
		foreach ($str2 in $values.Keys)
		{
			[System.Collections.ArrayList]$list=$values.GetValues($str2)
    $list.sort()
    $builder2=  [System.Text.StringBuilder]::new()
			foreach ($obj2 in $list)
			{
				if ($builder2.Length -gt 0)
				{
    $builder2.Append(" ," );
				}
    $builder2.Append($obj2.ToString()) |Out-Null
			}
			IF ($null -ne $str2)
			{
    $values2.add($str2.ToLowerInvariant(),$builder2.ToString())
			}
		}
    $list2=[System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
		foreach ($str3 in $list2)
		{
    $builder3=[System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" :" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" `n" ) |out-null
    $str.Append($builder3.ToString())|out-null
		}
	}
    $XHeaders = " x-ms-date:$(date) `n" +" x-ms-version:$ApiStorage"
	if ($service -eq 'Table')
	{
    $StringToHash= $method + " `n" + " `n" + " `n$(date) `n" +$str.ToString()
	}
	Else
	{
		IF ($method -eq 'GET' -or $method -eq 'HEAD')
		{
    $StringToHash = $method + " `n" + " `n" + " `n" + " `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" +$str.ToString()
		}
		Else
		{
    $StringToHash = $method + " `n" + " `n" + " `n$(bodylength) `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" +$str.ToString()
		}
	}
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource,$EncodedHash
	return $authorization
}
Function invoke-StorageREST($SharedKey, $method, $msgbody, $resource,$uri,$svc,$download)
{
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
	If ($method -eq 'PUT')
    $params = @{
	    uri = $uri
	    date = $rfc1123date
	    service = $svc }Else {
	    resource = $resource
	    sharedKey = $SharedKey
	    bodylength = $msgbody.length
	    method = $method
	}
	{$signature @params
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
	If($svc -eq 'Table')
	{
    $headersforsa=  @{
			'Authorization'= " $signature"
			'x-ms-version'=" $apistorage"
			'x-ms-date'=" $rfc1123date"
			'Accept-Charset'='UTF-8'
			'MaxDataServiceVersion'='3.0;NetFx'
			'Accept'='application/json;odata=nometadata'
		}
	}
	Else
	{
    $HeadersforSA=  @{
			'x-ms-date'=" $rfc1123date"
			'Content-Type'='application\xml'
			'Authorization'= " $signature"
			'x-ms-version'=" $ApiStorage"
		}
	}
	IF($download)
	{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody  -OutFile " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
		return " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
	}Else{
		If ($svc -eq 'Table')
		{
			IF ($method -eq 'PUT'){
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method  -UseBasicParsing -Body $msgbody
				return $resp1
			}Else
			{  $resp1=Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method   -UseBasicParsing -Body $msgbody
    $xresp=$resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
			}
			return $xresp
		}Else
		{
			IF ($method -eq 'PUT'){
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
				return $resp1
			}Elseif($method -eq 'GET')
			{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody -ea 0
    $xresp=$resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
				return $xresp
			}Elseif($method -eq 'HEAD')
			{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
				return $resp1
			}
		}
	}
}
function Get-BlobSize -ErrorAction Stop ($bloburi,$storageaccount,$rg,$type)
{
	If($type -eq 'ARM')
	{
    $Uri=" https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.Storage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $ApiVerSaArm, $storageaccount,$rg,$SubscriptionId
    $keyresp=Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys=ConvertFrom-Json -InputObject $keyresp.Content
    $prikey=$keys.keys[0].value
	}Elseif($type -eq 'Classic')
	{
    $Uri=" https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.ClassicStorage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $ApiVerSaAsm,$storageaccount,$rg,$SubscriptionId
    $keyresp=Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys=ConvertFrom-Json -InputObject $keyresp.Content
    $prikey=$keys.primaryKey
	}Else
	{
		"Could not detect storage account type, $storageaccount will not be processed"
		Continue
	}
    $vhdblob=invoke-StorageREST -sharedKey $prikey -method HEAD -resource $storageaccount -uri $bloburi
	Return [math]::round($vhdblob.Headers.'Content-Length'/1024/1024/1024,0)
}
function New-OMSSignature ($CustomerId, $SharedKey, $date, $ContentLength, $method, $ContentType, $resource)
{
    $XHeaders = " x-ms-date:" + $date
    $StringToHash = $method + " `n$(contentLength) `n" + $ContentType + " `n$(xHeaders) `n" + $resource
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $CustomerId,$EncodedHash
	return $authorization
}
Function Post-OMSData($CustomerId, $SharedKey, $body, $LogType)
{
    $method = "POST"
    $ContentType = " application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
    $ContentLength = $body.Length
    $params = @{
	    date = $rfc1123date
	    contentLength = $ContentLength
	    resource = $resource
	    sharedKey = $SharedKey
	    customerId = $CustomerId
	    contentType = $ContentType
	    fileName = $FileName
	    method = $method
	}
    $signature @params
    $uri = "https://$(customerId) .ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"
    $OMSheaders = @{
		"Authorization" = $signature;
		"Log-Type" = $LogType;
		" x-ms-date" = $rfc1123date;
		" time-generated-field" = $TimeStampField;
	}
	Try{
    $response = Invoke-WebRequest -Uri $uri -Method POST  -ContentType $ContentType -Headers $OMSheaders -Body $body -UseBasicParsing
	}catch [Net.WebException]
	{
    $ex=$_.Exception
		If ($_.Exception.Response.StatusCode.value__) {
    $exrespcode = ($_.Exception.Response.StatusCode.value__ ).ToString().Trim();
		}
		If  ($_.Exception.Message) {
    $ExMessage = ($_.Exception.Message).ToString().Trim();
		}
    $errmsg= " $exrespcode : $ExMessage"
	}
	if ($errmsg){return $errmsg }
	Else{	return $response.StatusCode }
	Write-error

    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
[Parameter()] [Parameter()]
    [ValidateNotNullOrEmpty()]
    $SubscriptionidFilter,
[Parameter()] [bool] $CollectionFromAllSubscriptions=$false,
[Parameter()] [bool] $GetAsmHeader=$true)
    $ErrorActionPreference= "Stop"
Write-Output "RB Initial Memory  : $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
    $StartTime = [dateTime]::Now
    $Timestampfield = "Timestamp"
    $timestamp=$StartTime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:00.000Z" )
    $CustomerID = Get-AutomationVariable -Name 'AzureSAIngestion-OPSINSIGHTS_WS_ID-MS-Mgmt-SA'
    $SharedKey = Get-AutomationVariable -Name 'AzureSAIngestion-OPSINSIGHTS_WS_KEY-MS-Mgmt-SA'
    $ApiVerSaAsm = '2016-04-01'
    $ApiVerSaArm = '2016-01-01'
    $ApiStorage='2016-05-31'
    $AAAccount = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationAccount-MS-Mgmt-SA'
    $AAResourceGroup = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationResourceGroup-MS-Mgmt-SA'
    $logname='AzureStorage'
    $hash = [hashtable]::New(@{})
    $Starttimer=get-date -ErrorAction Stop
[OutputType([bool])]
 ($CustomerId, $SharedKey, $date,  $method,  $resource,$uri)
{
    $StringToHash = $method + " `n" + " `n" + " `n$(date) `n" +"/" +$resource+$uri.AbsolutePath
	Add-Type -AssemblyName System.Web
    $query = [System.Web.HttpUtility]::ParseQueryString($uri.query)
    $querystr=''
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource,$EncodedHash
	return $authorization
}
function New-StorageSignature ($SharedKey, $date,  $method, $bodylength, $resource,$uri ,$service)
{
	Add-Type -AssemblyName System.Web
    $str=  New-Object -TypeName "System.Text.StringBuilder" ;
    $builder=  [System.Text.StringBuilder]::new("/" )
    $builder.Append($resource) |out-null
    $builder.Append($uri.AbsolutePath) | out-null
    $str.Append($builder.ToString()) | out-null
    $values2=@{}
	IF($service -eq 'Table')
	{
    $values= [System.Web.HttpUtility]::ParseQueryString($uri.query)
		foreach ($str2 in $values.Keys)
		{
			[System.Collections.ArrayList]$list=$values.GetValues($str2)
    $list.sort()
    $builder2=  [System.Text.StringBuilder]::new()
			foreach ($obj2 in $list)
			{
				if ($builder2.Length -gt 0)
				{
    $builder2.Append(" ," );
				}
    $builder2.Append($obj2.ToString()) |Out-Null
			}
			IF ($null -ne $str2)
			{
    $values2.add($str2.ToLowerInvariant(),$builder2.ToString())
			}
		}
    $list2=[System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
		foreach ($str3 in $list2)
		{
			IF($str3 -eq 'comp')
			{
    $builder3=[System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" =" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" ?" ) |out-null
    $str.Append($builder3.ToString())|out-null
			}
		}
	}
	Else
	{
    $values= [System.Web.HttpUtility]::ParseQueryString($uri.query)
		foreach ($str2 in $values.Keys)
		{
			[System.Collections.ArrayList]$list=$values.GetValues($str2)
    $list.sort()
    $builder2=  [System.Text.StringBuilder]::new()
			foreach ($obj2 in $list)
			{
				if ($builder2.Length -gt 0)
				{
    $builder2.Append(" ," );
				}
    $builder2.Append($obj2.ToString()) |Out-Null
			}
			IF ($null -ne $str2)
			{
    $values2.add($str2.ToLowerInvariant(),$builder2.ToString())
			}
		}
    $list2=[System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
		foreach ($str3 in $list2)
		{
    $builder3=[System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" :" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" `n" ) |out-null
    $str.Append($builder3.ToString())|out-null
		}
	}
    $XHeaders = " x-ms-date:$(date) `n" +" x-ms-version:$ApiStorage"
	if ($service -eq 'Table')
	{
    $StringToHash= $method + " `n" + " `n" + " `n$(date) `n" +$str.ToString()
	}
	Else
	{
		IF ($method -eq 'GET' -or $method -eq 'HEAD')
		{
    $StringToHash = $method + " `n" + " `n" + " `n" + " `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" +$str.ToString()
		}
		Else
		{
    $StringToHash = $method + " `n" + " `n" + " `n$(bodylength) `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" +$str.ToString()
		}
	}
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource,$EncodedHash
	return $authorization
}
Function invoke-StorageREST($SharedKey, $method, $msgbody, $resource,$uri,$svc,$download)
{
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
	If ($method -eq 'PUT')
    $params = @{
	    uri = $uri
	    date = $rfc1123date
	    service = $svc }Else {
	    resource = $resource
	    sharedKey = $SharedKey
	    bodylength = $msgbody.length
	    method = $method
	}
	{$signature @params
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
	If($svc -eq 'Table')
	{
    $headersforsa=  @{
			'Authorization'= " $signature"
			'x-ms-version'=" $apistorage"
			'x-ms-date'=" $rfc1123date"
			'Accept-Charset'='UTF-8'
			'MaxDataServiceVersion'='3.0;NetFx'
			'Accept'='application/json;odata=nometadata'
		}
	}
	Else
	{
    $HeadersforSA=  @{
			'x-ms-date'=" $rfc1123date"
			'Content-Type'='application\xml'
			'Authorization'= " $signature"
			'x-ms-version'=" $ApiStorage"
		}
	}
	IF($download)
	{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody  -OutFile " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
		return " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
	}Else{
		If ($svc -eq 'Table')
		{
			IF ($method -eq 'PUT'){
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method  -UseBasicParsing -Body $msgbody
				return $resp1
			}Else
			{  $resp1=Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method   -UseBasicParsing -Body $msgbody
    $xresp=$resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
			}
			return $xresp
		}Else
		{
			IF ($method -eq 'PUT'){
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
				return $resp1
			}Elseif($method -eq 'GET')
			{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody -ea 0
    $xresp=$resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
				return $xresp
			}Elseif($method -eq 'HEAD')
			{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
				return $resp1
			}
		}
	}
}
function Get-BlobSize -ErrorAction Stop ($bloburi,$storageaccount,$rg,$type)
{
	If($type -eq 'ARM')
	{
    $Uri=" https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.Storage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $ApiVerSaArm, $storageaccount,$rg,$SubscriptionId
    $keyresp=Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys=ConvertFrom-Json -InputObject $keyresp.Content
    $prikey=$keys.keys[0].value
	}Elseif($type -eq 'Classic')
	{
    $Uri=" https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.ClassicStorage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $ApiVerSaAsm,$storageaccount,$rg,$SubscriptionId
    $keyresp=Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys=ConvertFrom-Json -InputObject $keyresp.Content
    $prikey=$keys.primaryKey
	}Else
	{
		"Could not detect storage account type, $storageaccount will not be processed"
		Continue
	}
    $vhdblob=invoke-StorageREST -sharedKey $prikey -method HEAD -resource $storageaccount -uri $bloburi
	Return [math]::round($vhdblob.Headers.'Content-Length'/1024/1024/1024,0)
}
function New-OMSSignature ($CustomerId, $SharedKey, $date, $ContentLength, $method, $ContentType, $resource)
{
    $XHeaders = " x-ms-date:" + $date
    $StringToHash = $method + " `n$(contentLength) `n" + $ContentType + " `n$(xHeaders) `n" + $resource
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $CustomerId,$EncodedHash
	return $authorization
}
Function Post-OMSData($CustomerId, $SharedKey, $body, $LogType)
{
    $method = "POST"
    $ContentType = " application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
    $ContentLength = $body.Length
    $params = @{
	    date = $rfc1123date
	    contentLength = $ContentLength
	    resource = $resource
	    sharedKey = $SharedKey
	    customerId = $CustomerId
	    contentType = $ContentType
	    fileName = $FileName
	    method = $method
	}
    $signature @params
    $uri = "https://$(customerId) .ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"
    $OMSheaders = @{
		"Authorization" = $signature;
		"Log-Type" = $LogType;
		" x-ms-date" = $rfc1123date;
		" time-generated-field" = $TimeStampField;
	}
	Try{
    $response = Invoke-WebRequest -Uri $uri -Method POST  -ContentType $ContentType -Headers $OMSheaders -Body $body -UseBasicParsing
	}catch [Net.WebException]
	{
    $ex=$_.Exception
		If ($_.Exception.Response.StatusCode.value__) {
    $exrespcode = ($_.Exception.Response.StatusCode.value__ ).ToString().Trim();
		}
		If  ($_.Exception.Message) {
    $ExMessage = ($_.Exception.Message).ToString().Trim();
		}
    $errmsg= " $exrespcode : $ExMessage"
	}
	if ($errmsg){return $errmsg }
	Else{	return $response.StatusCode }
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
    $SubscriptionsURI=" https://management.azure.com/subscriptions?api-version=2016-06-01"
    $Subscriptions = Invoke-RestMethod -Uri  $SubscriptionsURI -Method GET  -Headers $headers -UseBasicParsing
    $Subscriptions=@($Subscriptions.value)
IF($CollectionFromAllSubscriptions -and $Subscriptions.count -gt 1 )
{
	Write-Output " $($Subscriptions.count) Subscription found , additonal runbook jobs will be created to collect data "
    $AAResourceGroup = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationResourceGroup-MS-Mgmt-SA'
    $AAAccount = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationAccount-MS-Mgmt-SA'
    $MetricsRunbookName = "AzureSAIngestionMetrics-MS-Mgmt-SA"
	$n=$Subscriptions.count-1
    $subslist=$subscriptions|where {$_.subscriptionId  -ne $SubscriptionId}
	Foreach($item in $subslist)
	{
    $params1 = @{"SubscriptionidFilter" =$item.subscriptionId;" collectionFromAllSubscriptions" = $false;" getAsmHeader" =$false}
		Start-AzureRmAutomationRunbook -AutomationAccountName $AAAccount -Name $MetricsRunbookName -ResourceGroupName $AAResourceGroup -Parameters $params1 | out-null
	}
}
" $(GEt-date) - Get ARM storage Accounts "
    $Uri=" https://management.azure.com/subscriptions/{1}/providers/Microsoft.Storage/storageAccounts?api-version={0}"   -f  $ApiVerSaArm,$SubscriptionId
    $armresp=Invoke-RestMethod -Uri $uri -Method GET  -Headers $headers -UseBasicParsing
    $SaArmList=$armresp.Value
" $(GEt-date)  $($SaArmList.count) classic storage accounts found"
" $(GEt-date)  Get Classic storage Accounts "
    $Uri=" https://management.azure.com/subscriptions/{1}/providers/Microsoft.ClassicStorage/storageAccounts?api-version={0}"   -f  $ApiVerSaAsm,$SubscriptionId
    $asmresp=Invoke-RestMethod -Uri $uri -Method GET  -Headers $headers -UseBasicParsing
    $SaAsmList=$asmresp.value
" $(GEt-date)  $($SaAsmList.count) storage accounts found"
    $ColParamsforChild=@()
foreach($sa in $SaArmList|where {$_.Sku.tier -ne 'Premium'})
{
    $rg=$sku=$null
    $rg=$sa.id.Split('/')[4]
    $ColParamsforChild = $ColParamsforChild + " $($sa.name);$($sa.id.Split('/')[4]);ARM;$($sa.sku.tier);$($sa.Kind)"
}
    $sa=$rg=$null
foreach($sa in $SaAsmList|where{$_.properties.accounttype -notmatch 'Premium'})
{
    $rg=$sa.id.Split('/')[4]
    $tier=$null
	If( $sa.properties.accountType -notmatch 'premium')
	{
    $tier='Standard'
    $ColParamsforChild = $ColParamsforChild + " $($sa.name);$($sa.id.Split('/')[4]);Classic;$tier;$($sa.Kind)"
	}
}
Write-Output "Core Count  $([System.Environment]::ProcessorCount)"
if($ColParamsforChild.count -eq 0)
{
	Write-Output "No Storage account found under subscription $subscriptionid , please note that Premium storage does not support metrics and excluded from the collection!"
	exit
}
    $SAInventory=@()
    $sa=$null
foreach($sa in $SaArmList)
{
    $rg=$sa.id.Split('/')[4]
    $cu=$null
    $cu = New-Object -ErrorAction Stop PSObject -Property @{
		Timestamp = $timestamp
		MetricName = 'Inventory';
		InventoryType='StorageAccount'
		StorageAccount=$sa.name
		Uri=" https://management.azure.com" +$sa.id
		DeploymentType='ARM'
		Location=$sa.location
		Kind=$sa.kind
		ResourceGroup=$rg
		Sku=$sa.sku.name
		Tier=$sa.sku.tier
		SubscriptionId = $ArmConn.SubscriptionId;
		AzureSubscription = $SubscriptionInfo.displayName
	}
	IF ($sa.properties.creationTime){$cu|Add-Member -MemberType NoteProperty -Name CreationTime -Value $sa.properties.creationTime}
	IF ($sa.properties.primaryLocation){$cu|Add-Member -MemberType NoteProperty -Name PrimaryLocation -Value $sa.properties.primaryLocation}
	IF ($sa.properties.secondaryLocation){$cu|Add-Member -MemberType NoteProperty -Name secondaryLocation-Value $sa.properties.secondaryLocation}
	IF ($sa.properties.statusOfPrimary){$cu|Add-Member -MemberType NoteProperty -Name statusOfPrimary -Value $sa.properties.statusOfPrimary}
	IF ($sa.properties.statusOfSecondary){$cu|Add-Member -MemberType NoteProperty -Name statusOfSecondary -Value $sa.properties.statusOfSecondary}
	IF ($sa.kind -eq 'BlobStorage'){$cu|Add-Member -MemberType NoteProperty -Name accessTier -Value $sa.properties.accessTier}
	IF ($t.properties.encryption.services.blob){$cu|Add-Member -MemberType NoteProperty -Name blobEncryption -Value 'enabled'}
	IF ($t.properties.encryption.services.file){$cu|Add-Member -MemberType NoteProperty -Name fileEncryption -Value 'enabled'}
    $SAInventory = $SAInventory + $cu
}
foreach($sa in $SaAsmList)
{
    $rg=$sa.id.Split('/')[4]
    $cu=$iotype=$null
	IF($sa.properties.accountType -like 'Standard*')
	{$iotype='Standard'}Else{$iotype='Premium'}
    $cu = New-Object -ErrorAction Stop PSObject -Property @{
		Timestamp = $timestamp
		MetricName = 'Inventory'
		InventoryType='StorageAccount'
		StorageAccount=$sa.name
		Uri=" https://management.azure.com" +$sa.id
		DeploymentType='Classic'
		Location=$sa.location
		Kind='Storage'
		ResourceGroup=$rg
		Sku=$sa.properties.accountType
		Tier=$iotype
		SubscriptionId = $ArmConn.SubscriptionId;
		AzureSubscription = $SubscriptionInfo.displayName
	}
	IF ($sa.properties.creationTime){$cu|Add-Member -MemberType NoteProperty -Name CreationTime -Value $sa.properties.creationTime}
	IF ($sa.properties.geoPrimaryRegion){$cu|Add-Member -MemberType NoteProperty -Name PrimaryLocation -Value $sa.properties.geoPrimaryRegion.Replace(' ','')}
	IF ($sa.properties.geoSecondaryRegion ){$cu|Add-Member -MemberType NoteProperty -Name SecondaryLocation-Value $sa.properties.geoSecondaryRegion.Replace(' ','')}
	IF ($sa.properties.statusOfPrimaryRegion){$cu|Add-Member -MemberType NoteProperty -Name statusOfPrimary -Value $sa.properties.statusOfPrimaryRegion}
	IF ($sa.properties.statusOfSecondaryRegion){$cu|Add-Member -MemberType NoteProperty -Name statusOfSecondary -Value $sa.properties.statusOfSecondaryRegion}
    $SAInventory = $SAInventory + $cu
}
    $JsonSAInventory = ConvertTo-Json -InputObject $SAInventory
If($JsonSAInventory){Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($JsonSAInventory)) -logType $logname}
" $(get-date)  - SA Inventory  data  uploaded"
    $quotas=@()
IF($GetAsmHeader)
{
    $uri=" https://management.core.windows.net/$SubscriptionId"
    $qresp=Invoke-WebRequest -Uri $uri -Method GET  -Headers $headerasm -UseBasicParsing -Certificate $AzureCert
	[xml]$qres=$qresp.Content
	[int]$SAMAX=$qres.Subscription.MaxStorageAccounts
	[int]$SACurrent=$qres.Subscription.CurrentStorageAccounts
    $Quotapct=$qres.Subscription.CurrentStorageAccounts/$qres.Subscription.MaxStorageAccounts*100
    $quotas = $quotas + New-Object -ErrorAction Stop PSObject -Property @{
		Timestamp = $timestamp
		MetricName = 'StorageQuotas';
		QuotaType="Classic"
		SAMAX=$samax
		SACurrent=$SACurrent
		Quotapct=$Quotapct
		SubscriptionId = $ArmConn.SubscriptionId;
		AzureSubscription = $SubscriptionInfo.displayName;
	}
}
    $SAMAX=$SACurrent=$SAquotapct=$null
    $usageuri=" https://management.azure.com/subscriptions/$(subscriptionid) /providers/Microsoft.Storage/usages?api-version=2016-05-01"
    $usageapi = Invoke-RestMethod -Uri $usageuri -Method GET -Headers $Headers  -UseBasicParsing;
    $usagecontent=$usageapi.value;
    $SAquotapct=$usagecontent[0].currentValue/$usagecontent[0].Limit*100
[int]$SAMAX=$usagecontent[0].limit
[int]$SACurrent=$usagecontent[0].currentValue
    $quotas = $quotas + New-Object -ErrorAction Stop PSObject -Property @{
	Timestamp = $timestamp
	MetricName = 'StorageQuotas';
	QuotaType="ARM"
	SAMAX=$SAMAX
	SACurrent=$SACurrent
	Quotapct=$SAquotapct
	SubscriptionId = $ArmConn.SubscriptionId;
	AzureSubscription = $SubscriptionInfo.displayName;
}
    $jsonquotas = ConvertTo-Json -InputObject $quotas
If($jsonquotas){Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonquotas)) -logType $logname}
" $(get-date)  - Quota info uploaded"
    $hash = [hashtable]::New(@{})
    $hash['Host']=$host
    $hash['subscriptionInfo']=$SubscriptionInfo
    $hash['ArmConn']=$ArmConn
    $hash['AsmConn']=$AsmConn
    $hash['headers']=$headers
    $hash['headerasm']=$headers
    $hash['AzureCert']=$AzureCert
    $hash['Timestampfield']=$Timestampfield
    $hash['customerID'] =$CustomerID
    $hash['syncInterval']=$SyncInterval
    $hash['sharedKey']=$SharedKey
    $hash['Logname']=$logname
    $hash['ApiVerSaAsm']=$ApiVerSaAsm
    $hash['ApiVerSaArm']=$ApiVerSaArm
    $hash['ApiStorage']=$ApiStorage
    $hash['AAAccount']=$AAAccount
    $hash['AAResourceGroup']=$AAResourceGroup
    $hash['debuglog']=$true
    $hash['saTransactionsMetrics']=@()
    $hash['saCapacityMetrics']=@()
    $hash['tableInventory']=@()
    $hash['fileInventory']=@()
    $hash['queueInventory']=@()
    $hash['vhdinventory']=@()
    $SAInfo=@()
    $hash.'SAInfo'=$sainfo
    $Throttle = [int][System.Environment]::ProcessorCount+1
    $sessionstate = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
    $runspacepool = [runspacefactory]::CreateRunspacePool(1, $Throttle, $sessionstate, $Host)
    $runspacepool.Open()
[System.Collections.ArrayList]$Jobs = @()
    $ScriptBlockGetKeys={
	Param ($hash,[array]$Sa,$rsid)
    $SubscriptionInfo=$hash.subscriptionInfo
    $ArmConn=$hash.ArmConn
    $headers=$hash.headers
    $AsmConn=$hash.AsmConn
    $headerasm=$hash.headerasm
    $AzureCert=$hash.AzureCert
    $Timestampfield = $hash.Timestampfield
    $Currency=$hash.Currency
    $Locale=$hash.Locale
    $RegionInfo=$hash.RegionInfo
    $OfferDurableId=$hash.OfferDurableId
    $SyncInterval=$Hash.syncInterval
    $CustomerID =$hash.customerID
    $SharedKey = $hash.sharedKey
    $logname=$hash.Logname
    $StartTime = [dateTime]::Now
    $ApiVerSaAsm = $hash.ApiVerSaAsm
    $ApiVerSaArm = $hash.ApiVerSaArm
    $ApiStorage=$hash.ApiStorage
    $AAAccount = $hash.AAAccount
    $AAResourceGroup = $hash.AAResourceGroup
    $debuglog=$hash.deguglog
    $VarQueueList="AzureSAIngestion-List-Queues"
    $VarFilesList="AzureSAIngestion-List-Files"
    $SubscriptionId=$SubscriptionInfo.subscriptionId
	[OutputType([bool])]
 ($CustomerId, $SharedKey, $date,  $method,  $resource,$uri)
	{
    $StringToHash = $method + " `n" + " `n" + " `n$(date) `n" +"/" +$resource+$uri.AbsolutePath
		Add-Type -AssemblyName System.Web
    $query = [System.Web.HttpUtility]::ParseQueryString($uri.query)
    $querystr=''
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource,$EncodedHash
		return $authorization
	}
	function New-StorageSignature ($SharedKey, $date,  $method, $bodylength, $resource,$uri ,$service)
	{
		Add-Type -AssemblyName System.Web
    $str=  New-Object -TypeName "System.Text.StringBuilder" ;
    $builder=  [System.Text.StringBuilder]::new("/" )
    $builder.Append($resource) |out-null
    $builder.Append($uri.AbsolutePath) | out-null
    $str.Append($builder.ToString()) | out-null
    $values2=@{}
		IF($service -eq 'Table')
		{
    $values= [System.Web.HttpUtility]::ParseQueryString($uri.query)
			foreach ($str2 in $values.Keys)
			{
				[System.Collections.ArrayList]$list=$values.GetValues($str2)
    $list.sort()
    $builder2=  [System.Text.StringBuilder]::new()
				foreach ($obj2 in $list)
				{
					if ($builder2.Length -gt 0)
					{
    $builder2.Append(" ," );
					}
    $builder2.Append($obj2.ToString()) |Out-Null
				}
				IF ($null -ne $str2)
				{
    $values2.add($str2.ToLowerInvariant(),$builder2.ToString())
				}
			}
    $list2=[System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
			foreach ($str3 in $list2)
			{
				IF($str3 -eq 'comp')
				{
    $builder3=[System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" =" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" ?" ) |out-null
    $str.Append($builder3.ToString())|out-null
				}
			}
		}
		Else
		{
    $values= [System.Web.HttpUtility]::ParseQueryString($uri.query)
			foreach ($str2 in $values.Keys)
			{
				[System.Collections.ArrayList]$list=$values.GetValues($str2)
    $list.sort()
    $builder2=  [System.Text.StringBuilder]::new()
				foreach ($obj2 in $list)
				{
					if ($builder2.Length -gt 0)
					{
    $builder2.Append(" ," );
					}
    $builder2.Append($obj2.ToString()) |Out-Null
				}
				IF ($null -ne $str2)
				{
    $values2.add($str2.ToLowerInvariant(),$builder2.ToString())
				}
			}
    $list2=[System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
			foreach ($str3 in $list2)
			{
    $builder3=[System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" :" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" `n" ) |out-null
    $str.Append($builder3.ToString())|out-null
			}
		}
    $XHeaders = " x-ms-date:$(date) `n" +" x-ms-version:$ApiStorage"
		if ($service -eq 'Table')
		{
    $StringToHash= $method + " `n" + " `n" + " `n$(date) `n" +$str.ToString()
		}
		Else
		{
			IF ($method -eq 'GET' -or $method -eq 'HEAD')
			{
    $StringToHash = $method + " `n" + " `n" + " `n" + " `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" +$str.ToString()
			}
			Else
			{
    $StringToHash = $method + " `n" + " `n" + " `n$(bodylength) `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" +$str.ToString()
			}
		}
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource,$EncodedHash
		return $authorization
	}
	Function invoke-StorageREST($SharedKey, $method, $msgbody, $resource,$uri,$svc,$download)
	{
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
		If ($method -eq 'PUT')
    $params = @{
		    uri = $uri
		    date = $rfc1123date
		    service = $svc }Else {
		    resource = $resource
		    sharedKey = $SharedKey
		    bodylength = $msgbody.length
		    method = $method
		}
		{$signature @params
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
		If($svc -eq 'Table')
		{
    $headersforsa=  @{
				'Authorization'= " $signature"
				'x-ms-version'=" $apistorage"
				'x-ms-date'=" $rfc1123date"
				'Accept-Charset'='UTF-8'
				'MaxDataServiceVersion'='3.0;NetFx'
				'Accept'='application/json;odata=nometadata'
			}
		}
		Else
		{
    $HeadersforSA=  @{
				'x-ms-date'=" $rfc1123date"
				'Content-Type'='application\xml'
				'Authorization'= " $signature"
				'x-ms-version'=" $ApiStorage"
			}
		}
		IF($download)
		{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody  -OutFile " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
			return " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
		}Else{
			If ($svc -eq 'Table')
			{
				IF ($method -eq 'PUT'){
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method  -UseBasicParsing -Body $msgbody
					return $resp1
				}Else
				{  $resp1=Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method   -UseBasicParsing -Body $msgbody
    $xresp=$resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
				}
				return $xresp
			}Else
			{
				IF ($method -eq 'PUT'){
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
					return $resp1
				}Elseif($method -eq 'GET')
				{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody -ea 0
    $xresp=$resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
					return $xresp
				}Elseif($method -eq 'HEAD')
				{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
					return $resp1
				}
			}
		}
	}
    $prikey=$storageaccount=$rg=$type=$null
    $storageaccount =$sa.Split(';')[0]
    $rg=$sa.Split(';')[1]
    $type=$sa.Split(';')[2]
    $tier=$sa.Split(';')[3]
    $kind=$sa.Split(';')[4]
	If($type -eq 'ARM')
	{
    $Uri=" https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.Storage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $ApiVerSaArm, $storageaccount,$rg,$SubscriptionId
    $keyresp=Invoke-RestMethod -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $prikey=$keyresp.keys[0].value
	}Elseif($type -eq 'Classic')
	{
    $uri=$keyresp=$null
    $Uri=" https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.ClassicStorage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $ApiVerSaAsm,$storageaccount,$rg,$SubscriptionId
    $keyresp=Invoke-RestMethod -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $prikey=$keyresp.primaryKey
	}Else
	{
		"Could not detect storage account type, $storageaccount will not be processed"
		Continue
	}
	IF ($kind -eq 'BlobStorage')
	{
    $svclist=@('blob','table')
	}Else
	{
    $svclist=@('blob','table','queue')
	}
    $logging=$false
	Foreach ($svc in $svclist)
	{
		[uri]$UriSvcProp = "https://{0}.{1}.core.windows.net/?restype=service&comp=properties	" -f $storageaccount,$svc
		IF($svc -eq 'table')
		{
			[xml]$SvcPropResp= invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriSvcProp -svc Table
		}else
		{
			[xml]$SvcPropResp= invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriSvcProp
		}
		IF($SvcPropResp.StorageServiceProperties.Logging.Read -eq 'true' -or $SvcPropResp.StorageServiceProperties.Logging.Write -eq 'true' -or $SvcPropResp.StorageServiceProperties.Logging.Delete -eq 'true')
		{
    $msg="Logging is enabled for {0} in {1}" -f $svc,$storageaccount
    $logging=$true
		}
		Else {
    $msg="Logging is not  enabled for {0} in {1}" -f $svc,$storageaccount
		}
	}
    $hash.SAInfo+=New-Object -ErrorAction Stop PSObject -Property @{
		StorageAccount = $storageaccount
		Key=$prikey
		Logging=$logging
		Rg=$rg
		Type=$type
		Tier=$tier
		Kind=$kind
	}
}
Write-Output "After Runspace creation  $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
write-output " $($ColParamsforChild.count) objects will be processed "
$i=1
    $Starttimer=get-date -ErrorAction Stop
    $ColParamsforChild|foreach{
    $splitmetrics=$null
    $splitmetrics=$_
    $Job = [powershell]::Create().AddScript($ScriptBlockGetKeys).AddArgument($hash).AddArgument($splitmetrics).Addargument($i)
    $Job.RunspacePool = $RunspacePool
    $Jobs = $Jobs + New-Object -ErrorAction Stop PSObject -Property @{
		RunNum = $i
		Pipe = $Job
		Result = $Job.BeginInvoke()
	}
    $i++
}
write-output  " $(get-date)  , started $i Runspaces "
Write-Output "After dispatching runspaces $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
    $JobsClone=$jobs.clone()
Write-Output "Waiting.."
$s=1
Do {
	Write-Output "  $(@($jobs.result.iscompleted|where{$_  -match 'False'}).count)  jobs remaining"
	foreach ($jobobj in $JobsClone)
	{
		if ($Jobobj.result.IsCompleted -eq $true)
		{
    $jobobj.Pipe.Endinvoke($jobobj.Result)
    $jobobj.pipe.dispose()
    $jobs.Remove($jobobj)
		}
	}
	IF($([System.gc]::gettotalmemory('forcefullcollection') /1MB) -gt 200)
	{
		[gc]::Collect()
	}
	IF($s%10 -eq 0)
	{
		Write-Output "Job $s - Mem: $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
	}
    $s++
	Start-Sleep -Seconds 15
} While ( @($jobs.result.iscompleted|where{$_  -match 'False'}).count -gt 0)
Write-output "All jobs completed!"
    $jobs|foreach{$_.Pipe.Dispose()}
if(Get-Variable -Name Jobs ){Remove-Variable -ErrorAction Stop Jobs -Force -Scope Global }
if(Get-Variable -Name Job ){Remove-Variable -ErrorAction Stop Job -Force -Scope Global }
if(Get-Variable -Name Jobobj ){Remove-Variable -ErrorAction Stop Jobobj -Force -Scope Global }
if(Get-Variable -Name Jobsclone ){Remove-Variable -ErrorAction Stop Jobsclone -Force -Scope Global }
    $runspacepool.Close()
[gc]::Collect()
    $ScriptBlockGetMetrics={
	Param ($hash,$Sa,$rsid)
    $SubscriptionInfo=$hash.subscriptionInfo
    $ArmConn=$hash.ArmConn
    $headers=$hash.headers
    $AsmConn=$hash.AsmConn
    $headerasm=$hash.headerasm
    $AzureCert=$hash.AzureCert
    $Timestampfield = $hash.Timestampfield
    $Currency=$hash.Currency
    $Locale=$hash.Locale
    $RegionInfo=$hash.RegionInfo
    $OfferDurableId=$hash.OfferDurableId
    $SyncInterval=$Hash.syncInterval
    $CustomerID =$hash.customerID
    $SharedKey = $hash.sharedKey
    $logname=$hash.Logname
    $StartTime = [dateTime]::Now
    $ApiVerSaAsm = $hash.ApiVerSaAsm
    $ApiVerSaArm = $hash.ApiVerSaArm
    $ApiStorage=$hash.ApiStorage
    $AAAccount = $hash.AAAccount
    $AAResourceGroup = $hash.AAResourceGroup
    $debuglog=$hash.deguglog
    $VarQueueList="AzureSAIngestion-List-Queues"
    $VarFilesList="AzureSAIngestion-List-Files"
    $SubscriptionId=$SubscriptionInfo.subscriptionId
	[OutputType([bool])]
 ($CustomerId, $SharedKey, $date,  $method,  $resource,$uri)
	{
    $StringToHash = $method + " `n" + " `n" + " `n$(date) `n" +"/" +$resource+$uri.AbsolutePath
		Add-Type -AssemblyName System.Web
    $query = [System.Web.HttpUtility]::ParseQueryString($uri.query)
    $querystr=''
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource,$EncodedHash
		return $authorization
	}
	function New-StorageSignature ($SharedKey, $date,  $method, $bodylength, $resource,$uri ,$service)
	{
		Add-Type -AssemblyName System.Web
    $str=  New-Object -TypeName "System.Text.StringBuilder" ;
    $builder=  [System.Text.StringBuilder]::new("/" )
    $builder.Append($resource) |out-null
    $builder.Append($uri.AbsolutePath) | out-null
    $str.Append($builder.ToString()) | out-null
    $values2=@{}
		IF($service -eq 'Table')
		{
    $values= [System.Web.HttpUtility]::ParseQueryString($uri.query)
			foreach ($str2 in $values.Keys)
			{
				[System.Collections.ArrayList]$list=$values.GetValues($str2)
    $list.sort()
    $builder2=  [System.Text.StringBuilder]::new()
				foreach ($obj2 in $list)
				{
					if ($builder2.Length -gt 0)
					{
    $builder2.Append(" ," );
					}
    $builder2.Append($obj2.ToString()) |Out-Null
				}
				IF ($null -ne $str2)
				{
    $values2.add($str2.ToLowerInvariant(),$builder2.ToString())
				}
			}
    $list2=[System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
			foreach ($str3 in $list2)
			{
				IF($str3 -eq 'comp')
				{
    $builder3=[System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" =" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" ?" ) |out-null
    $str.Append($builder3.ToString())|out-null
				}
			}
		}
		Else
		{
    $values= [System.Web.HttpUtility]::ParseQueryString($uri.query)
			foreach ($str2 in $values.Keys)
			{
				[System.Collections.ArrayList]$list=$values.GetValues($str2)
    $list.sort()
    $builder2=  [System.Text.StringBuilder]::new()
				foreach ($obj2 in $list)
				{
					if ($builder2.Length -gt 0)
					{
    $builder2.Append(" ," );
					}
    $builder2.Append($obj2.ToString()) |Out-Null
				}
				IF ($null -ne $str2)
				{
    $values2.add($str2.ToLowerInvariant(),$builder2.ToString())
				}
			}
    $list2=[System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
			foreach ($str3 in $list2)
			{
    $builder3=[System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" :" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" `n" ) |out-null
    $str.Append($builder3.ToString())|out-null
			}
		}
    $XHeaders = " x-ms-date:$(date) `n" +" x-ms-version:$ApiStorage"
		if ($service -eq 'Table')
		{
    $StringToHash= $method + " `n" + " `n" + " `n$(date) `n" +$str.ToString()
		}
		Else
		{
			IF ($method -eq 'GET' -or $method -eq 'HEAD')
			{
    $StringToHash = $method + " `n" + " `n" + " `n" + " `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" +$str.ToString()
			}
			Else
			{
    $StringToHash = $method + " `n" + " `n" + " `n$(bodylength) `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" +$str.ToString()
			}
		}
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource,$EncodedHash
		return $authorization
	}
	Function invoke-StorageREST($SharedKey, $method, $msgbody, $resource,$uri,$svc,$download)
	{
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
		If ($method -eq 'PUT')
    $params = @{
		    uri = $uri
		    date = $rfc1123date
		    service = $svc }Else {
		    resource = $resource
		    sharedKey = $SharedKey
		    bodylength = $msgbody.length
		    method = $method
		}
		{$signature @params
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
		If($svc -eq 'Table')
		{
    $headersforsa=  @{
				'Authorization'= " $signature"
				'x-ms-version'=" $apistorage"
				'x-ms-date'=" $rfc1123date"
				'Accept-Charset'='UTF-8'
				'MaxDataServiceVersion'='3.0;NetFx'
				'Accept'='application/json;odata=nometadata'
			}
		}
		Else
		{
    $HeadersforSA=  @{
				'x-ms-date'=" $rfc1123date"
				'Content-Type'='application\xml'
				'Authorization'= " $signature"
				'x-ms-version'=" $ApiStorage"
			}
		}
		IF($download)
		{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody  -OutFile " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
			return " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
		}Else{
			If ($svc -eq 'Table')
			{
				IF ($method -eq 'PUT'){
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method  -UseBasicParsing -Body $msgbody
					return $resp1
				}Else
				{  $resp1=Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method   -UseBasicParsing -Body $msgbody
    $xresp=$resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
				}
				return $xresp
			}Else
			{
				IF ($method -eq 'PUT'){
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
					return $resp1
				}Elseif($method -eq 'GET')
				{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody -ea 0
    $xresp=$resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
					return $xresp
				}Elseif($method -eq 'HEAD')
				{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
					return $resp1
				}
			}
		}
	}
	function Get-BlobSize -ErrorAction Stop ($bloburi,$storageaccount,$rg,$type)
	{
		If($type -eq 'ARM')
		{
    $Uri=" https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.Storage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $ApiVerSaArm, $storageaccount,$rg,$SubscriptionId
    $keyresp=Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys=ConvertFrom-Json -InputObject $keyresp.Content
    $prikey=$keys.keys[0].value
		}Elseif($type -eq 'Classic')
		{
    $Uri=" https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.ClassicStorage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $ApiVerSaAsm,$storageaccount,$rg,$SubscriptionId
    $keyresp=Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys=ConvertFrom-Json -InputObject $keyresp.Content
    $prikey=$keys.primaryKey
		}Else
		{
			"Could not detect storage account type, $storageaccount will not be processed"
			Continue
		}
    $vhdblob=invoke-StorageREST -sharedKey $prikey -method HEAD -resource $storageaccount -uri $bloburi
		Return [math]::round($vhdblob.Headers.'Content-Length'/1024/1024/1024,0)
	}
	function New-OMSSignature ($CustomerId, $SharedKey, $date, $ContentLength, $method, $ContentType, $resource)
	{
    $XHeaders = " x-ms-date:" + $date
    $StringToHash = $method + " `n$(contentLength) `n" + $ContentType + " `n$(xHeaders) `n" + $resource
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $CustomerId,$EncodedHash
		return $authorization
	}
	Function Post-OMSData($CustomerId, $SharedKey, $body, $LogType)
	{
    $method = "POST"
    $ContentType = " application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
    $ContentLength = $body.Length
    $params = @{
		    date = $rfc1123date
		    contentLength = $ContentLength
		    resource = $resource ; 	$uri = "https://$(customerId) .ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01" ; 	$OMSheaders = @{ "Authorization" = $signature; "Log-Type" = $LogType; " x-ms-date" = $rfc1123date; " time-generated-field" = $TimeStampField; }
		    sharedKey = $SharedKey
		    customerId = $CustomerId
		    contentType = $ContentType
		    fileName = $FileName
		    method = $method
		}
    $signature @params
		Try{
    $response = Invoke-WebRequest -Uri $uri -Method POST  -ContentType $ContentType -Headers $OMSheaders -Body $body -UseBasicParsing
		}catch [Net.WebException]
		{
    $ex=$_.Exception
			If ($_.Exception.Response.StatusCode.value__) {
    $exrespcode = ($_.Exception.Response.StatusCode.value__ ).ToString().Trim();
			}
			If  ($_.Exception.Message) {
    $ExMessage = ($_.Exception.Message).ToString().Trim();
			}
    $errmsg= " $exrespcode : $ExMessage"
		}
		if ($errmsg){return $errmsg }
		Else{	return $response.StatusCode }
		Write-error $error[0]
	}
    $prikey=$sa.key
    $storageaccount =$sa.StorageAccount
    $rg=$sa.rg
    $type=$sa.Type
    $tier=$sa.Tier
    $kind=$sa.Kind
    $colltime=Get-Date -ErrorAction Stop
	If($colltime.Minute -in 0..15)
	{
    $MetricColstartTime=$colltime.ToUniversalTime().AddHours(-1).ToString(" yyyyMMdd'T'HH46" )
    $MetricColendTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH00" )
	}
	Elseif($colltime.Minute -in 16..30)
	{
    $MetricColstartTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH00" )
    $MetricColendTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH15" )
	}
	Elseif($colltime.Minute -in 31..45)
	{
    $MetricColstartTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH16" )
    $MetricColendTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH30" )
	}
	Else
	{
    $MetricColstartTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH31" )
    $MetricColendTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH45" )
	}
    $hour=$MetricColEndTime.substring($MetricColEndTime.Length-4,4).Substring(0,2)
    $min=$MetricColEndTime.substring($MetricColEndTime.Length-4,4).Substring(2,2)
    $timestamp=(get-date).ToUniversalTime().ToString(" yyyy-MM-ddT$($hour):$($min):00.000Z" )
    $ColParamsforChild=@()
    $SaMetricsAvg=@()
    $storcapacity=@()
    $fltr1='?$filter='+"PartitionKey%20ge%20'$(MetricColstartTime) '%20and%20PartitionKey%20le%20'" +$MetricColendTime+" '%20and%20RowKey%20eq%20'user;All'"
    $slct1='&$select=PartitionKey,TotalRequests,TotalBillableRequests,TotalIngress,TotalEgress,AverageE2ELatency,AverageServerLatency,PercentSuccess,Availability,PercentThrottlingError,PercentNetworkError,PercentTimeoutError,SASAuthorizationError,PercentAuthorizationError,PercentClientOtherError,PercentServerOtherError'
    $sa=$null
    $vhdinventory=@()
    $AllContainers=@()
    $queueinventory=@()
    $queuearr=@()
    $QueueMetrics=@()
    $Fileinventory=@()
    $filearr=@()
    $InvFS=@()
    $fileshareinventory=@()
    $tableinventory=@()
    $tablearr=@{}
    $vmlist=@()
    $allvms=@()
    $allvhds=@()
    $tablelist= @('$MetricsMinutePrimaryTransactionsBlob','$MetricsMinutePrimaryTransactionsTable','$MetricsMinutePrimaryTransactionsQueue','$MetricsMinutePrimaryTransactionsFile')
	Foreach ($TableName in $tablelist)
	{
    $signature=$headersforsa=$null
		[uri]$tablequri=" https://$($storageaccount).table.core.windows.net/" +$TableName+'()'
    $resource = $storageaccount
    $logdate=[DateTime]::UtcNow
    $rfc1123date = $logdate.ToString(" r" )
    $params = @{
	    uri = $tablequri
	    date = $rfc1123date
	    service = "table"
	    resource = $storageaccount
	    sharedKey = $prikey
	    method = "GET"
	}
	; @params
    $headersforsa=  @{
			'Authorization'= " $signature"
			'x-ms-version'=" $apistorage"
			'x-ms-date'=" $rfc1123date"
			'Accept-Charset'='UTF-8'
			'MaxDataServiceVersion'='3.0;NetFx'
			'Accept'='application/json;odata=nometadata'
		}
    $response=$jresponse=$null
    $FullQuery=$tablequri.OriginalString+$fltr1+$slct1
    $method = "GET"
		Try
		{
    $response = Invoke-WebRequest -Uri $FullQuery -Method $method  -Headers $headersforsa  -UseBasicParsing  -ErrorAction SilentlyContinue
		}
		Catch
		{
    $ErrorMessage = $_.Exception.Message
    $StackTrace = $_.Exception.StackTrace
			Write-Warning "Error during accessing metrics table $tablename .Error: $ErrorMessage, stack: $StackTrace."
		}
    $Jresponse=convertFrom-Json    $response.Content
		IF($Jresponse.Value)
		{
    $entities=$null
    $entities=$Jresponse.value
    $stormetrics=@()
			foreach ($rowitem in $entities)
			{
    $cu=$null
    $dt=$rowitem.PartitionKey
    $timestamp=$dt.Substring(0,4)+'-'+$dt.Substring(4,2)+'-'+$dt.Substring(6,3)+$dt.Substring(9,2)+':'+$dt.Substring(11,2)+':00.000Z'
    $cu = New-Object -ErrorAction Stop PSObject -Property @{
					Timestamp = $timestamp
					MetricName = 'MetricsTransactions'
					TotalRequests=[long]$rowitem.TotalRequests
					TotalBillableRequests=[long]$rowitem.TotalBillableRequests
					TotalIngress=[long]$rowitem.TotalIngress
					TotalEgress=[long]$rowitem.TotalEgress
					Availability=[float]$rowitem.Availability
					AverageE2ELatency=[int]$rowitem.AverageE2ELatency
					AverageServerLatency=[int]$rowitem.AverageServerLatency
					PercentSuccess=[float]$rowitem.PercentSuccess
					PercentThrottlingError=[float]$rowitem.PercentThrottlingError
					PercentNetworkError=[float]$rowitem.PercentNetworkError
					PercentTimeoutError=[float]$rowitem.PercentTimeoutError
					SASAuthorizationError=[float]$rowitem.SASAuthorizationError
					PercentAuthorizationError=[float]$rowitem.PercentAuthorizationError
					PercentClientOtherError=[float]$rowitem.PercentClientOtherError
					PercentServerOtherError=[float]$rowitem.PercentServerOtherError
					ResourceGroup=$rg
					StorageAccount = $StorageAccount
					StorageService=$TableName.Substring(33,$TableName.Length-33)
					SubscriptionId = $ArmConn.SubscriptionID
					AzureSubscription = $SubscriptionInfo.displayName
				}
    $hash['saTransactionsMetrics']+=$cu
			}
		}
	}
    $TableName = '$MetricsCapacityBlob'
    $startdate=(get-date).AddDays(-1).ToUniversalTime().ToString(" yyyyMMdd'T'0000" )
    $table=$null
    $signature=$headersforsa=$null
	[uri]$tablequri=" https://$($storageaccount).table.core.windows.net/" +$TableName+'()'
    $resource = $storageaccount
    $logdate=[DateTime]::UtcNow
    $rfc1123date = $logdate.ToString(" r" )
    $params = @{
    uri = $tablequri
    date = $rfc1123date
    service = "table"
    resource = $storageaccount
    sharedKey = $prikey
    method = "GET"
}
; @params
    $headersforsa=  @{
		'Authorization'= " $signature"
		'x-ms-version'=" $apistorage"
		'x-ms-date'=" $rfc1123date"
		'Accept-Charset'='UTF-8'
		'MaxDataServiceVersion'='3.0;NetFx'
		'Accept'='application/json;odata=nometadata'
	}
    $response=$jresponse=$null
    $fltr2='?$filter='+"PartitionKey%20gt%20'$(startdate) '%20and%20RowKey%20eq%20'data'"
    $FullQuery=$tablequri.OriginalString+$fltr2
    $method = "GET"
	Try
	{
    $response = Invoke-WebRequest -Uri $FullQuery -Method $method  -Headers $headersforsa  -UseBasicParsing  -ErrorAction SilentlyContinue
	}
	Catch
	{
    $ErrorMessage = $_.Exception.Message
    $StackTrace = $_.Exception.StackTrace
		Write-Warning "Error during accessing metrics table $tablename .Error: $ErrorMessage, stack: $StackTrace."
	}
    $Jresponse=convertFrom-Json    $response.Content
	IF($Jresponse.Value)
	{
    $entities=$null
    $entities=@($jresponse.value)
    $cu=$null
    $cu = New-Object -ErrorAction Stop PSObject -Property @{
			Timestamp = $timestamp
			MetricName = 'MetricsCapacity'
			Capacity=$([long]$entities[0].Capacity)/1024/1024/1024
			ContainerCount=[long]$entities[0].ContainerCount
			ObjectCount=[long]$entities[0].ObjectCount
			ResourceGroup=$rg
			StorageAccount = $StorageAccount
			StorageService="Blob"
			SubscriptionId = $ArmConn.SubscriptionId
			AzureSubscription = $SubscriptionInfo.displayName
		}
    $hash['saCapacityMetrics']+=$cu
	}
	IF($tier -notmatch 'premium' -and $kind -ne 'BlobStorage')
	{
		[uri]$UriQueue=" https://{0}.queue.core.windows.net?comp=list" -f $storageaccount
		[xml]$Xresponse=invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriQueue
		IF (![String]::IsNullOrEmpty($Xresponse.EnumerationResults.Queues.Queue))
		{
			Foreach ($queue in $Xresponse.EnumerationResults.Queues.Queue)
			{
				write-verbose  "Queue found :$($sa.name) ; $($queue.name) "
    $queuearr = $queuearr + " {0};{1}" -f $queue.Name.tostring(),$sa.name
    $queueinventory = $queueinventory + New-Object -ErrorAction Stop PSObject -Property @{
					Timestamp = $timestamp
					MetricName = 'Inventory'
					InventoryType='Queue'
					StorageAccount=$sa.name
					Queue= $queue.Name
					Uri=$UriQueue.Scheme+'://'+$UriQueue.Host+'/'+$queue.Name
					SubscriptionID = $ArmConn.SubscriptionId;
					AzureSubscription = $SubscriptionInfo.displayName
					ShowinDesigner=1
				}
				[uri]$uriforq=" https://$storageaccount.queue.core.windows.net/$($queue.name)/messages?peekonly=true"
				[xml]$Xmlqresp= invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $uriforq
				[uri]$uriform=" https://$storageaccount.queue.core.windows.net/$($queue.name)?comp=metadata"
    $Xmlqrespm= invoke-StorageREST -sharedKey $prikey -method HEAD -resource $storageaccount -uri $uriform
    $cuq=$null
    $cuq = $cuq + New-Object -ErrorAction Stop PSObject -Property @{
					Timestamp=$timestamp
					MetricName = 'QueueMetrics';
					StorageAccount=$storageaccount
					StorageService="Queue"
					Queue= $queue.Name
					approximateMsgCount=$Xmlqrespm.Headers.'x-ms-approximate-messages-count'
					SubscriptionId = $ArmConn.SubscriptionId;
					AzureSubscription = $SubscriptionInfo.displayName
				}
    $msg=$Xmlqresp.QueueMessagesList.QueueMessage
				IF(![string]::IsNullOrEmpty($Xmlqresp.QueueMessagesList))
				{
    $cuq|Add-Member -MemberType NoteProperty -Name FirstMessageID -Value $msg.MessageId
    $cuq|Add-Member -MemberType NoteProperty -Name FirstMessageText -Value $msg.MessageText
    $cuq|Add-Member -MemberType NoteProperty -Name FirstMsgInsertionTime -Value $msg.InsertionTime
    $cuq|Add-Member -MemberType NoteProperty -Name Minutesinqueue -Value [Math]::Round(((Get-date).ToUniversalTime()-[datetime]($Xmlqresp.QueueMessagesList.QueueMessage.InsertionTime)).Totalminutes,0)
				}
    $hash['tableInventory']+=$cuq
			}
		}
	}
	IF($tier -notmatch 'premium' -and $kind -ne 'BlobStorage')
	{
		[uri]$UriFile=" https://{0}.file.core.windows.net?comp=list" -f $storageaccount
		[xml]$Xresponse=invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriFile
		if(![string]::IsNullOrEmpty($Xresponse.EnumerationResults.Shares.Share))
		{
			foreach($share in @($Xresponse.EnumerationResults.Shares.Share))
			{
				write-verbose  "File Share found :$($storageaccount) ; $($share.Name) "
    $filelist=@()
    $filearr = $filearr + " {0};{1}" -f $Share.Name,$storageaccount
    $cuf= New-Object -ErrorAction Stop PSObject -Property @{
					Timestamp = $timestamp
					MetricName = 'Inventory'
					InventoryType='File'
					StorageAccount=$storageaccount
					FileShare=$share.Name
					Uri=$UriFile.Scheme+'://'+$UriFile.Host+'/'+$Share.Name
					Quota=$share.Properties.Quota
					SubscriptionID = $ArmConn.SubscriptionId;
					AzureSubscription = $SubscriptionInfo.displayName
					ShowinDesigner=1
				}
				[uri]$UriforF=" https://{0}.file.core.windows.net/{1}?restype=share&comp=stats" -f $storageaccount,$share.Name
				[xml]$Xmlresp=invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriforF
				IF($Xmlresp)
				{
    $cuf|Add-Member -MemberType NoteProperty -Name  ShareUsedGB -Value $([int]$Xmlresp.ShareStats.ShareUsage)
				}
    $hash['fileInventory']+=$cuf
			}
		}
	}
	IF($tier -notmatch 'premium')
	{
		[uri]$uritable=" https://{0}.table.core.windows.net/Tables" -f $storageaccount
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
    $params = @{
	    uri = $uritable
	    UseBasicParsing = "; 	$RespJson=convertFrom-Json    $tableresp.Content  IF (![string]::IsNullOrEmpty($RespJson.value.Tablename)) { foreach($tbl in @($RespJson.value.Tablename)) { write-verbose  "Table found :$storageaccount ; $($tbl) "  #$tablearr = $tablearr + " {0}"
	    date = $rfc1123date
	    service = "table ; 	$headersforsa=  @{ 'Authorization'= " $signature" 'x-ms-version'=" $apistorage" 'x-ms-date'=" $rfc1123date" 'Accept-Charset'='UTF-8' 'MaxDataServiceVersion'='3.0;NetFx' 'Accept'='application/json;odata=nometadata' } $tableresp=Invoke-WebRequest"
	    resource = $sa.name
	    sharedKey = $prikey
	    Property = "@{ Timestamp = $timestamp MetricName = 'Inventory' InventoryType='Table' StorageAccount=$storageaccount Table=$tbl Uri=$uritable.Scheme+'://'+$uritable.Host+'/'+$tbl SubscriptionID = $ArmConn.SubscriptionId; AzureSubscription = $SubscriptionInfo.displayName ShowinDesigner=1  } } } }"
	    ErrorAction = "Stop PSObject"
	    Headers = $headersforsa
	    f = $sa.name IF ([string]::IsNullOrEmpty($tablearr.Get_item($storageaccount))) { $tablearr.add($sa.name,'Storageaccount') }   $hash['queueInventory']+= New-Object
	    method = "GET"
	}
	; @params
	if ((get-date).hour -in (1,5,9,13,17,21) -and   (get-date).minute -in (1..16)   )
	{
		[uri]$UriListC= "https://{0}.blob.core.windows.net/?comp=list" -f $storageaccount
		Write-verbose " $(get-date) - Getting list of blobs for $($sa.name) "
		[xml]$lb=invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriListC
    $containers=@($lb.EnumerationResults.Containers.Container)
		IF(![string]::IsNullOrEmpty($lb.EnumerationResults.Containers.Container))
		{
			Foreach($container in @($containers))
			{
    $allcontainers = $allcontainers + $container
				[uri]$UriLBlobs = "https://{0}.blob.core.windows.net/{1}/?comp=list&include=metadata&maxresults=1000&restype=container" -f $storageaccount,$container.name
				[xml]$fresponse= invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriLBlobs
    $filesincontainer=@()
    $blobs=$fresponse.EnumerationResults.Blobs.blob
				Foreach($blob in $blobs)
				{
					IF($blob.name -match '.vhd')
					{
    $cu = New-Object -ErrorAction Stop PSObject -Property @{
							Timestamp = $timestamp
							MetricName = 'Inventory'
							InventoryType='VHDFile'
							Capacity=[Math]::Round($blob.Properties.'Content-Length'/1024/1024/1024,0)
							Container=$container.Name
							VHDName=$blob.name
							Uri= " {0}{1}/{2}" -f $fresponse.EnumerationResults.ServiceEndpoint,$Container.Name,$blob.Name
							LeaseState=$blob.Properties.LeaseState.ToString()
							StorageAccount= $storageaccount
							SubscriptionID = $ArmConn.SubscriptionId;
							AzureSubscription = $SubscriptionInfo.displayName
							ShowinDesigner=1
						}
    $hash['vhdinventory']+=$cu
					}
				}
    $filesincontainer|Group-Object Fileextension|select Name,count
    $fileshareinventory = $fileshareinventory + $filesincontainer
			}
		}
	}
}
    $Throttle = [System.Environment]::ProcessorCount+1
    $sessionstate = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
    $runspacepool = [runspacefactory]::CreateRunspacePool(1, $Throttle, $sessionstate, $Host)
    $runspacepool.Open()
[System.Collections.ArrayList]$Jobs = @()
Write-Output "After Runspace creation for metric collection : $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
$i=1
    $Starttimer=get-date -ErrorAction Stop
    $hash.SAInfo|foreach{
    $splitmetrics=$null
    $splitmetrics=$_
    $Job = [powershell]::Create().AddScript($ScriptBlockGetMetrics).AddArgument($hash).AddArgument($splitmetrics).Addargument($i)
    $Job.RunspacePool = $RunspacePool
    $Jobs = $Jobs + New-Object -ErrorAction Stop PSObject -Property @{
		RunNum = $i
		Pipe = $Job
		Result = $Job.BeginInvoke()
	}
    $i++
}
write-output  " $(get-date)  , started $i Runspaces "
Write-Output "After dispatching runspaces $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
    $JobsClone=$jobs.clone()
Write-Output "Waiting.."
$s=1
Do {
	Write-Output "  $(@($jobs.result.iscompleted|where{$_  -match 'False'}).count)  jobs remaining"
	foreach ($jobobj in $JobsClone)
	{
		if ($Jobobj.result.IsCompleted -eq $true)
		{
    $jobobj.Pipe.Endinvoke($jobobj.Result)
    $jobobj.pipe.dispose()
    $jobs.Remove($jobobj)
		}
	}
	IF($s%2 -eq 0)
	{
		Write-Output "Mem: $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
	}
    $s++
	Start-Sleep -Seconds 15
} While ( @($jobs.result.iscompleted|where{$_  -match 'False'}).count -gt 0)
Write-output "All jobs completed!"
    $jobs|foreach{$_.Pipe.Dispose()}
Remove-Variable -ErrorAction Stop Jobs -Force -Scope Global
Remove-Variable -ErrorAction Stop Job -Force -Scope Global
Remove-Variable -ErrorAction Stop Jobobj -Force -Scope Global
Remove-Variable -ErrorAction Stop Jobsclone -Force -Scope Global
    $runspacepool.Close()
$([System.gc]::gettotalmemory('forcefullcollection') /1MB)
    $Endtimer=get-date -ErrorAction Stop
Write-Output "All jobs completed in $(($Endtimer-$starttimer).TotalMinutes) minutes"
Write-Output "Uploading to OMS ..."
    $SplitSize=5000
If($hash.saTransactionsMetrics)
{
	write-output  "Uploading  $($hash.saTransactionsMetrics.count) transaction metrics"
    $UploadToOms=$hash.saTransactionsMetrics
    $hash.saTransactionsMetrics=@()
	If($UploadToOms.count -gt $SplitSize)
	{
    $spltlist=@()
    $spltlist = $spltlist + for ($Index = 0; $Index -lt $UploadToOms.count; $Index = $Index + $SplitSize)
		{
			,($UploadToOms[$index..($index+$SplitSize-1)])
		}
    $spltlist|foreach{
    $SplitLogs=$null
    $SplitLogs=$_
    $jsonlogs= ConvertTo-Json -InputObject $SplitLogs
			Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
		}
	}Else{
    $jsonlogs= ConvertTo-Json -InputObject $UploadToOms
		Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
	}
	Remove-Variable -ErrorAction Stop uploadToOms -Force -Scope Global -ErrorAction SilentlyContinue
	Remove-Variable -ErrorAction Stop jsonlogs -Force -Scope Global -ErrorAction SilentlyContinue
	Remove-Variable -ErrorAction Stop spltlist -Force -Scope Global -ErrorAction SilentlyContinue
	[System.gc]::Collect()
}
If($hash.saCapacityMetrics)
{
	write-output  "Uploading  $($hash.saCapacityMetrics.count) capacity metrics"
    $UploadToOms=$hash.saCapacityMetrics
    $hash.saCapacityMetrics=@()
	If($UploadToOms.count -gt $SplitSize)
	{
    $spltlist=@()
    $spltlist = $spltlist + for ($Index = 0; $Index -lt $UploadToOms.count; $Index = $Index + $SplitSize)
		{
			,($UploadToOms[$index..($index+$SplitSize-1)])
		}
    $spltlist|foreach{
    $SplitLogs=$null
    $SplitLogs=$_
    $jsonlogs= ConvertTo-Json -InputObject $SplitLogs
			Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
		}
	}Else{
    $jsonlogs= ConvertTo-Json -InputObject $UploadToOms
		Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
	}
	Remove-Variable -ErrorAction Stop uploadToOms -Force -Scope Global  -ErrorAction SilentlyContinue
	Remove-Variable -ErrorAction Stop jsonlogs -Force -Scope Global -ErrorAction SilentlyContinue
	Remove-Variable -ErrorAction Stop spltlist -Force -Scope Global -ErrorAction SilentlyContinue
	[System.gc]::Collect()
}
If($hash.tableInventory)
{
	write-output  "Uploading  $($hash.tableInventory.count) table inventory"
    $UploadToOms=$hash.tableInventory
    $hash.tableInventory=@()
	If($UploadToOms.count -gt $SplitSize)
	{
    $spltlist=@()
    $spltlist = $spltlist + for ($Index = 0; $Index -lt $UploadToOms.count; $Index = $Index + $SplitSize)
		{
			,($UploadToOms[$index..($index+$SplitSize-1)])
		}
    $spltlist|foreach{
    $SplitLogs=$null
    $SplitLogs=$_
    $jsonlogs= ConvertTo-Json -InputObject $SplitLogs
			Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
		}
	}Else{
    $jsonlogs= ConvertTo-Json -InputObject $UploadToOms
		Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
	}
	Remove-Variable -ErrorAction Stop uploadToOms -Force -Scope Global -ErrorAction SilentlyContinue
	Remove-Variable -ErrorAction Stop jsonlogs -Force -Scope Global -ErrorAction SilentlyContinue
	Remove-Variable -ErrorAction Stop spltlist -Force -Scope Global -ErrorAction SilentlyContinue
	[System.gc]::Collect()
}
If(!$hash.queueInventory)
{
    $hash.queueInventory+=New-Object -ErrorAction Stop PSObject -Property @{
		Timestamp = $timestamp
		MetricName = 'Inventory'
		InventoryType='Queue'
		Queue= "NO RESOURCE FOUND"
		Uri="NO RESOURCE FOUND"
		SubscriptionID = $ArmConn.SubscriptionId;
		AzureSubscription = $SubscriptionInfo.displayName
		ShowinDesigner=0
	}
}
write-output  "Uploading  $($hash.queueInventory.count) queue inventory"
    $UploadToOms=$hash.queueInventory
    $hash.queueInventory=@()
If($UploadToOms.count -gt $SplitSize)
{
    $spltlist=@()
    $spltlist = $spltlist + for ($Index = 0; $Index -lt $UploadToOms.count; $Index = $Index + $SplitSize)
	{
		,($UploadToOms[$index..($index+$SplitSize-1)])
	}
    $spltlist|foreach{
    $SplitLogs=$null
    $SplitLogs=$_
    $jsonlogs= ConvertTo-Json -InputObject $SplitLogs
		Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
	}
}Else{
    $jsonlogs= ConvertTo-Json -InputObject $UploadToOms
	Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
}
Remove-Variable -ErrorAction Stop uploadToOms -Force -Scope Global  -ErrorAction SilentlyContinue
Remove-Variable -ErrorAction Stop jsonlogs -Force -Scope Global  -ErrorAction SilentlyContinue
Remove-Variable -ErrorAction Stop spltlist -Force -Scope Global  -ErrorAction SilentlyContinue
[System.gc]::Collect()
If(!$hash.fileInventory)
{
    $hash.fileInventory+=New-Object -ErrorAction Stop PSObject -Property @{
		Timestamp = $timestamp
		MetricName = 'Inventory'
		InventoryType='File'
		FileShare="NO RESOURCE FOUND"
		Uri="NO RESOURCE FOUND"
		SubscriptionID = $ArmConn.SubscriptionId;
		AzureSubscription = $SubscriptionInfo.displayName
		ShowinDesigner=0
	}
}
write-output  "Uploading  $($hash.fileInventory.count) file inventory"
    $UploadToOms=$hash.fileInventory
    $hash.fileInventory=@()
If($UploadToOms.count -gt $SplitSize)
{
    $spltlist=@()
    $spltlist = $spltlist + for ($Index = 0; $Index -lt $UploadToOms.count; $Index = $Index + $SplitSize)
	{
		,($UploadToOms[$index..($index+$SplitSize-1)])
	}
    $spltlist|foreach{
    $SplitLogs=$null
    $SplitLogs=$_
    $jsonlogs= ConvertTo-Json -InputObject $SplitLogs
		Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
	}
}Else{
    $jsonlogs= ConvertTo-Json -InputObject $UploadToOms
	Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
}
Remove-Variable -ErrorAction Stop uploadToOms -Force -Scope Global -ErrorAction SilentlyContinue
Remove-Variable -ErrorAction Stop jsonlogs -Force -Scope Global -ErrorAction SilentlyContinue
Remove-Variable -ErrorAction Stop spltlist -Force -Scope Global -ErrorAction SilentlyContinue
[System.gc]::Collect()
If(!$hash.vhdinventory)
{
    $hash.vhdinventory+= New-Object -ErrorAction Stop PSObject -Property @{
		Timestamp = $timestamp
		MetricName = 'Inventory'
		InventoryType='VHDFile'
		VHDName="NO RESOURCE FOUND"
		Uri= "NO RESOURCE FOUND"
		SubscriptionID = $ArmConn.SubscriptionId;
		AzureSubscription = $SubscriptionInfo.displayName
		ShowinDesigner=0
	}
}
write-output  "Uploading  $($hash.vhdinventory.count) vhd inventory"
    $UploadToOms=$hash.vhdinventory
    $hash.vhdinventory=@()
If($UploadToOms.count -gt $SplitSize)
{
    $spltlist=@()
    $spltlist = $spltlist + for ($Index = 0; $Index -lt $UploadToOms.count; $Index = $Index + $SplitSize)
	{
		,($UploadToOms[$index..($index+$SplitSize-1)])
	}
    $spltlist|foreach{
    $SplitLogs=$null
    $SplitLogs=$_
    $jsonlogs= ConvertTo-Json -InputObject $SplitLogs
		Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
	}
}Else{
    $jsonlogs= ConvertTo-Json -InputObject $UploadToOms
	Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
}
Remove-Variable -ErrorAction Stop uploadToOms -Force -Scope Global -ErrorAction SilentlyContinue
Remove-Variable -ErrorAction Stop jsonlogs -Force -Scope Global -ErrorAction SilentlyContinue
Remove-Variable -ErrorAction Stop spltlist -Force -Scope Global -ErrorAction SilentlyContinue
[System.gc]::Collect()
"Final Memory Consumption: $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
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
    $SubscriptionsURI=" https://management.azure.com/subscriptions?api-version=2016-06-01"
    $Subscriptions = Invoke-RestMethod -Uri  $SubscriptionsURI -Method GET  -Headers $headers -UseBasicParsing
    $Subscriptions=@($Subscriptions.value)
IF($CollectionFromAllSubscriptions -and $Subscriptions.count -gt 1 )
{
	Write-Output " $($Subscriptions.count) Subscription found , additonal runbook jobs will be created to collect data "
    $AAResourceGroup = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationResourceGroup-MS-Mgmt-SA'
    $AAAccount = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationAccount-MS-Mgmt-SA'
    $MetricsRunbookName = "AzureSAIngestionMetrics-MS-Mgmt-SA"
	$n=$Subscriptions.count-1
    $subslist=$subscriptions|where {$_.subscriptionId  -ne $SubscriptionId}
	Foreach($item in $subslist)
	{
    $params1 = @{"SubscriptionidFilter" =$item.subscriptionId;" collectionFromAllSubscriptions" = $false;" getAsmHeader" =$false}
		Start-AzureRmAutomationRunbook -AutomationAccountName $AAAccount -Name $MetricsRunbookName -ResourceGroupName $AAResourceGroup -Parameters $params1 | out-null
	}
}
" $(GEt-date) - Get ARM storage Accounts "
    $Uri=" https://management.azure.com/subscriptions/{1}/providers/Microsoft.Storage/storageAccounts?api-version={0}"   -f  $ApiVerSaArm,$SubscriptionId
    $armresp=Invoke-RestMethod -Uri $uri -Method GET  -Headers $headers -UseBasicParsing
    $SaArmList=$armresp.Value
" $(GEt-date)  $($SaArmList.count) classic storage accounts found"
" $(GEt-date)  Get Classic storage Accounts "
    $Uri=" https://management.azure.com/subscriptions/{1}/providers/Microsoft.ClassicStorage/storageAccounts?api-version={0}"   -f  $ApiVerSaAsm,$SubscriptionId
    $asmresp=Invoke-RestMethod -Uri $uri -Method GET  -Headers $headers -UseBasicParsing
    $SaAsmList=$asmresp.value
" $(GEt-date)  $($SaAsmList.count) storage accounts found"
    $ColParamsforChild=@()
foreach($sa in $SaArmList|where {$_.Sku.tier -ne 'Premium'})
{
    $rg=$sku=$null
    $rg=$sa.id.Split('/')[4]
    $ColParamsforChild = $ColParamsforChild + " $($sa.name);$($sa.id.Split('/')[4]);ARM;$($sa.sku.tier);$($sa.Kind)"
}
    $sa=$rg=$null
foreach($sa in $SaAsmList|where{$_.properties.accounttype -notmatch 'Premium'})
{
    $rg=$sa.id.Split('/')[4]
    $tier=$null
	If( $sa.properties.accountType -notmatch 'premium')
	{
    $tier='Standard'
    $ColParamsforChild = $ColParamsforChild + " $($sa.name);$($sa.id.Split('/')[4]);Classic;$tier;$($sa.Kind)"
	}
}
Write-Output "Core Count  $([System.Environment]::ProcessorCount)"
if($ColParamsforChild.count -eq 0)
{
	Write-Output "No Storage account found under subscription $subscriptionid , please note that Premium storage does not support metrics and excluded from the collection!"
	exit
}
    $SAInventory=@()
    $sa=$null
foreach($sa in $SaArmList)
{
    $rg=$sa.id.Split('/')[4]
    $cu=$null
    $cu = New-Object -ErrorAction Stop PSObject -Property @{
		Timestamp = $timestamp
		MetricName = 'Inventory';
		InventoryType='StorageAccount'
		StorageAccount=$sa.name
		Uri=" https://management.azure.com" +$sa.id
		DeploymentType='ARM'
		Location=$sa.location
		Kind=$sa.kind
		ResourceGroup=$rg
		Sku=$sa.sku.name
		Tier=$sa.sku.tier
		SubscriptionId = $ArmConn.SubscriptionId;
		AzureSubscription = $SubscriptionInfo.displayName
	}
	IF ($sa.properties.creationTime){$cu|Add-Member -MemberType NoteProperty -Name CreationTime -Value $sa.properties.creationTime}
	IF ($sa.properties.primaryLocation){$cu|Add-Member -MemberType NoteProperty -Name PrimaryLocation -Value $sa.properties.primaryLocation}
	IF ($sa.properties.secondaryLocation){$cu|Add-Member -MemberType NoteProperty -Name secondaryLocation-Value $sa.properties.secondaryLocation}
	IF ($sa.properties.statusOfPrimary){$cu|Add-Member -MemberType NoteProperty -Name statusOfPrimary -Value $sa.properties.statusOfPrimary}
	IF ($sa.properties.statusOfSecondary){$cu|Add-Member -MemberType NoteProperty -Name statusOfSecondary -Value $sa.properties.statusOfSecondary}
	IF ($sa.kind -eq 'BlobStorage'){$cu|Add-Member -MemberType NoteProperty -Name accessTier -Value $sa.properties.accessTier}
	IF ($t.properties.encryption.services.blob){$cu|Add-Member -MemberType NoteProperty -Name blobEncryption -Value 'enabled'}
	IF ($t.properties.encryption.services.file){$cu|Add-Member -MemberType NoteProperty -Name fileEncryption -Value 'enabled'}
    $SAInventory = $SAInventory + $cu
}
foreach($sa in $SaAsmList)
{
    $rg=$sa.id.Split('/')[4]
    $cu=$iotype=$null
	IF($sa.properties.accountType -like 'Standard*')
	{$iotype='Standard'}Else{$iotype='Premium'}
    $cu = New-Object -ErrorAction Stop PSObject -Property @{
		Timestamp = $timestamp
		MetricName = 'Inventory'
		InventoryType='StorageAccount'
		StorageAccount=$sa.name
		Uri=" https://management.azure.com" +$sa.id
		DeploymentType='Classic'
		Location=$sa.location
		Kind='Storage'
		ResourceGroup=$rg
		Sku=$sa.properties.accountType
		Tier=$iotype
		SubscriptionId = $ArmConn.SubscriptionId;
		AzureSubscription = $SubscriptionInfo.displayName
	}
	IF ($sa.properties.creationTime){$cu|Add-Member -MemberType NoteProperty -Name CreationTime -Value $sa.properties.creationTime}
	IF ($sa.properties.geoPrimaryRegion){$cu|Add-Member -MemberType NoteProperty -Name PrimaryLocation -Value $sa.properties.geoPrimaryRegion.Replace(' ','')}
	IF ($sa.properties.geoSecondaryRegion ){$cu|Add-Member -MemberType NoteProperty -Name SecondaryLocation-Value $sa.properties.geoSecondaryRegion.Replace(' ','')}
	IF ($sa.properties.statusOfPrimaryRegion){$cu|Add-Member -MemberType NoteProperty -Name statusOfPrimary -Value $sa.properties.statusOfPrimaryRegion}
	IF ($sa.properties.statusOfSecondaryRegion){$cu|Add-Member -MemberType NoteProperty -Name statusOfSecondary -Value $sa.properties.statusOfSecondaryRegion}
    $SAInventory = $SAInventory + $cu
}
    $JsonSAInventory = ConvertTo-Json -InputObject $SAInventory
If($JsonSAInventory){Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($JsonSAInventory)) -logType $logname}
" $(get-date)  - SA Inventory  data  uploaded"
    $quotas=@()
IF($GetAsmHeader)
{
    $uri=" https://management.core.windows.net/$SubscriptionId"
    $qresp=Invoke-WebRequest -Uri $uri -Method GET  -Headers $headerasm -UseBasicParsing -Certificate $AzureCert
	[xml]$qres=$qresp.Content
	[int]$SAMAX=$qres.Subscription.MaxStorageAccounts
	[int]$SACurrent=$qres.Subscription.CurrentStorageAccounts
    $Quotapct=$qres.Subscription.CurrentStorageAccounts/$qres.Subscription.MaxStorageAccounts*100
    $quotas = $quotas + New-Object -ErrorAction Stop PSObject -Property @{
		Timestamp = $timestamp
		MetricName = 'StorageQuotas';
		QuotaType="Classic"
		SAMAX=$samax
		SACurrent=$SACurrent
		Quotapct=$Quotapct
		SubscriptionId = $ArmConn.SubscriptionId;
		AzureSubscription = $SubscriptionInfo.displayName;
	}
}
    $SAMAX=$SACurrent=$SAquotapct=$null
    $usageuri=" https://management.azure.com/subscriptions/$(subscriptionid) /providers/Microsoft.Storage/usages?api-version=2016-05-01"
    $usageapi = Invoke-RestMethod -Uri $usageuri -Method GET -Headers $Headers  -UseBasicParsing;
    $usagecontent=$usageapi.value;
    $SAquotapct=$usagecontent[0].currentValue/$usagecontent[0].Limit*100
[int]$SAMAX=$usagecontent[0].limit
[int]$SACurrent=$usagecontent[0].currentValue
    $quotas = $quotas + New-Object -ErrorAction Stop PSObject -Property @{
	Timestamp = $timestamp
	MetricName = 'StorageQuotas';
	QuotaType="ARM"
	SAMAX=$SAMAX
	SACurrent=$SACurrent
	Quotapct=$SAquotapct
	SubscriptionId = $ArmConn.SubscriptionId;
	AzureSubscription = $SubscriptionInfo.displayName;
}
    $jsonquotas = ConvertTo-Json -InputObject $quotas
If($jsonquotas){Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonquotas)) -logType $logname}
" $(get-date)  - Quota info uploaded"
    $hash = [hashtable]::New(@{})
    $hash['Host']=$host
    $hash['subscriptionInfo']=$SubscriptionInfo
    $hash['ArmConn']=$ArmConn
    $hash['AsmConn']=$AsmConn
    $hash['headers']=$headers
    $hash['headerasm']=$headers
    $hash['AzureCert']=$AzureCert
    $hash['Timestampfield']=$Timestampfield
    $hash['customerID'] =$CustomerID
    $hash['syncInterval']=$SyncInterval
    $hash['sharedKey']=$SharedKey
    $hash['Logname']=$logname
    $hash['ApiVerSaAsm']=$ApiVerSaAsm
    $hash['ApiVerSaArm']=$ApiVerSaArm
    $hash['ApiStorage']=$ApiStorage
    $hash['AAAccount']=$AAAccount
    $hash['AAResourceGroup']=$AAResourceGroup
    $hash['debuglog']=$true
    $hash['saTransactionsMetrics']=@()
    $hash['saCapacityMetrics']=@()
    $hash['tableInventory']=@()
    $hash['fileInventory']=@()
    $hash['queueInventory']=@()
    $hash['vhdinventory']=@()
    $SAInfo=@()
    $hash.'SAInfo'=$sainfo
    $Throttle = [int][System.Environment]::ProcessorCount+1
    $sessionstate = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
    $runspacepool = [runspacefactory]::CreateRunspacePool(1, $Throttle, $sessionstate, $Host)
    $runspacepool.Open()
[System.Collections.ArrayList]$Jobs = @()
    $ScriptBlockGetKeys={
	Param ($hash,[array]$Sa,$rsid)
    $SubscriptionInfo=$hash.subscriptionInfo
    $ArmConn=$hash.ArmConn
    $headers=$hash.headers
    $AsmConn=$hash.AsmConn
    $headerasm=$hash.headerasm
    $AzureCert=$hash.AzureCert
    $Timestampfield = $hash.Timestampfield
    $Currency=$hash.Currency
    $Locale=$hash.Locale
    $RegionInfo=$hash.RegionInfo
    $OfferDurableId=$hash.OfferDurableId
    $SyncInterval=$Hash.syncInterval
    $CustomerID =$hash.customerID
    $SharedKey = $hash.sharedKey
    $logname=$hash.Logname
    $StartTime = [dateTime]::Now
    $ApiVerSaAsm = $hash.ApiVerSaAsm
    $ApiVerSaArm = $hash.ApiVerSaArm
    $ApiStorage=$hash.ApiStorage
    $AAAccount = $hash.AAAccount
    $AAResourceGroup = $hash.AAResourceGroup
    $debuglog=$hash.deguglog
    $VarQueueList="AzureSAIngestion-List-Queues"
    $VarFilesList="AzureSAIngestion-List-Files"
    $SubscriptionId=$SubscriptionInfo.subscriptionId
	[OutputType([bool])]
 ($CustomerId, $SharedKey, $date,  $method,  $resource,$uri)
	{
    $StringToHash = $method + " `n" + " `n" + " `n$(date) `n" +"/" +$resource+$uri.AbsolutePath
		Add-Type -AssemblyName System.Web
    $query = [System.Web.HttpUtility]::ParseQueryString($uri.query)
    $querystr=''
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource,$EncodedHash
		return $authorization
	}
	function New-StorageSignature ($SharedKey, $date,  $method, $bodylength, $resource,$uri ,$service)
	{
		Add-Type -AssemblyName System.Web
    $str=  New-Object -TypeName "System.Text.StringBuilder" ;
    $builder=  [System.Text.StringBuilder]::new("/" )
    $builder.Append($resource) |out-null
    $builder.Append($uri.AbsolutePath) | out-null
    $str.Append($builder.ToString()) | out-null
    $values2=@{}
		IF($service -eq 'Table')
		{
    $values= [System.Web.HttpUtility]::ParseQueryString($uri.query)
			foreach ($str2 in $values.Keys)
			{
				[System.Collections.ArrayList]$list=$values.GetValues($str2)
    $list.sort()
    $builder2=  [System.Text.StringBuilder]::new()
				foreach ($obj2 in $list)
				{
					if ($builder2.Length -gt 0)
					{
    $builder2.Append(" ," );
					}
    $builder2.Append($obj2.ToString()) |Out-Null
				}
				IF ($null -ne $str2)
				{
    $values2.add($str2.ToLowerInvariant(),$builder2.ToString())
				}
			}
    $list2=[System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
			foreach ($str3 in $list2)
			{
				IF($str3 -eq 'comp')
				{
    $builder3=[System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" =" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" ?" ) |out-null
    $str.Append($builder3.ToString())|out-null
				}
			}
		}
		Else
		{
    $values= [System.Web.HttpUtility]::ParseQueryString($uri.query)
			foreach ($str2 in $values.Keys)
			{
				[System.Collections.ArrayList]$list=$values.GetValues($str2)
    $list.sort()
    $builder2=  [System.Text.StringBuilder]::new()
				foreach ($obj2 in $list)
				{
					if ($builder2.Length -gt 0)
					{
    $builder2.Append(" ," );
					}
    $builder2.Append($obj2.ToString()) |Out-Null
				}
				IF ($null -ne $str2)
				{
    $values2.add($str2.ToLowerInvariant(),$builder2.ToString())
				}
			}
    $list2=[System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
			foreach ($str3 in $list2)
			{
    $builder3=[System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" :" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" `n" ) |out-null
    $str.Append($builder3.ToString())|out-null
			}
		}
    $XHeaders = " x-ms-date:$(date) `n" +" x-ms-version:$ApiStorage"
		if ($service -eq 'Table')
		{
    $StringToHash= $method + " `n" + " `n" + " `n$(date) `n" +$str.ToString()
		}
		Else
		{
			IF ($method -eq 'GET' -or $method -eq 'HEAD')
			{
    $StringToHash = $method + " `n" + " `n" + " `n" + " `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" +$str.ToString()
			}
			Else
			{
    $StringToHash = $method + " `n" + " `n" + " `n$(bodylength) `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" +$str.ToString()
			}
		}
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource,$EncodedHash
		return $authorization
	}
	Function invoke-StorageREST($SharedKey, $method, $msgbody, $resource,$uri,$svc,$download)
	{
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
		If ($method -eq 'PUT')
    $params = @{
		    uri = $uri
		    date = $rfc1123date
		    service = $svc }Else {
		    resource = $resource
		    sharedKey = $SharedKey
		    bodylength = $msgbody.length
		    method = $method
		}
		{$signature @params
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
		If($svc -eq 'Table')
		{
    $headersforsa=  @{
				'Authorization'= " $signature"
				'x-ms-version'=" $apistorage"
				'x-ms-date'=" $rfc1123date"
				'Accept-Charset'='UTF-8'
				'MaxDataServiceVersion'='3.0;NetFx'
				'Accept'='application/json;odata=nometadata'
			}
		}
		Else
		{
    $HeadersforSA=  @{
				'x-ms-date'=" $rfc1123date"
				'Content-Type'='application\xml'
				'Authorization'= " $signature"
				'x-ms-version'=" $ApiStorage"
			}
		}
		IF($download)
		{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody  -OutFile " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
			return " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
		}Else{
			If ($svc -eq 'Table')
			{
				IF ($method -eq 'PUT'){
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method  -UseBasicParsing -Body $msgbody
					return $resp1
				}Else
				{  $resp1=Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method   -UseBasicParsing -Body $msgbody
    $xresp=$resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
				}
				return $xresp
			}Else
			{
				IF ($method -eq 'PUT'){
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
					return $resp1
				}Elseif($method -eq 'GET')
				{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody -ea 0
    $xresp=$resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
					return $xresp
				}Elseif($method -eq 'HEAD')
				{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
					return $resp1
				}
			}
		}
	}
    $prikey=$storageaccount=$rg=$type=$null
    $storageaccount =$sa.Split(';')[0]
    $rg=$sa.Split(';')[1]
    $type=$sa.Split(';')[2]
    $tier=$sa.Split(';')[3]
    $kind=$sa.Split(';')[4]
	If($type -eq 'ARM')
	{
    $Uri=" https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.Storage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $ApiVerSaArm, $storageaccount,$rg,$SubscriptionId
    $keyresp=Invoke-RestMethod -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $prikey=$keyresp.keys[0].value
	}Elseif($type -eq 'Classic')
	{
    $uri=$keyresp=$null
    $Uri=" https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.ClassicStorage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $ApiVerSaAsm,$storageaccount,$rg,$SubscriptionId
    $keyresp=Invoke-RestMethod -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $prikey=$keyresp.primaryKey
	}Else
	{
		"Could not detect storage account type, $storageaccount will not be processed"
		Continue
	}
	IF ($kind -eq 'BlobStorage')
	{
    $svclist=@('blob','table')
	}Else
	{
    $svclist=@('blob','table','queue')
	}
    $logging=$false
	Foreach ($svc in $svclist)
	{
		[uri]$UriSvcProp = "https://{0}.{1}.core.windows.net/?restype=service&comp=properties	" -f $storageaccount,$svc
		IF($svc -eq 'table')
		{
			[xml]$SvcPropResp= invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriSvcProp -svc Table
		}else
		{
			[xml]$SvcPropResp= invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriSvcProp
		}
		IF($SvcPropResp.StorageServiceProperties.Logging.Read -eq 'true' -or $SvcPropResp.StorageServiceProperties.Logging.Write -eq 'true' -or $SvcPropResp.StorageServiceProperties.Logging.Delete -eq 'true')
		{
    $msg="Logging is enabled for {0} in {1}" -f $svc,$storageaccount
    $logging=$true
		}
		Else {
    $msg="Logging is not  enabled for {0} in {1}" -f $svc,$storageaccount
		}
	}
    $hash.SAInfo+=New-Object -ErrorAction Stop PSObject -Property @{
		StorageAccount = $storageaccount
		Key=$prikey
		Logging=$logging
		Rg=$rg
		Type=$type
		Tier=$tier
		Kind=$kind
	}
}
Write-Output "After Runspace creation  $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
write-output " $($ColParamsforChild.count) objects will be processed "
$i=1
    $Starttimer=get-date -ErrorAction Stop
    $ColParamsforChild|foreach{
    $splitmetrics=$null
    $splitmetrics=$_
    $Job = [powershell]::Create().AddScript($ScriptBlockGetKeys).AddArgument($hash).AddArgument($splitmetrics).Addargument($i)
    $Job.RunspacePool = $RunspacePool
    $Jobs = $Jobs + New-Object -ErrorAction Stop PSObject -Property @{
		RunNum = $i
		Pipe = $Job
		Result = $Job.BeginInvoke()
	}
    $i++
}
write-output  " $(get-date)  , started $i Runspaces "
Write-Output "After dispatching runspaces $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
    $JobsClone=$jobs.clone()
Write-Output "Waiting.."
$s=1
Do {
	Write-Output "  $(@($jobs.result.iscompleted|where{$_  -match 'False'}).count)  jobs remaining"
	foreach ($jobobj in $JobsClone)
	{
		if ($Jobobj.result.IsCompleted -eq $true)
		{
    $jobobj.Pipe.Endinvoke($jobobj.Result)
    $jobobj.pipe.dispose()
    $jobs.Remove($jobobj)
		}
	}
	IF($([System.gc]::gettotalmemory('forcefullcollection') /1MB) -gt 200)
	{
		[gc]::Collect()
	}
	IF($s%10 -eq 0)
	{
		Write-Output "Job $s - Mem: $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
	}
    $s++
	Start-Sleep -Seconds 15
} While ( @($jobs.result.iscompleted|where{$_  -match 'False'}).count -gt 0)
Write-output "All jobs completed!"
    $jobs|foreach{$_.Pipe.Dispose()}
if(Get-Variable -Name Jobs ){Remove-Variable -ErrorAction Stop Jobs -Force -Scope Global }
if(Get-Variable -Name Job ){Remove-Variable -ErrorAction Stop Job -Force -Scope Global }
if(Get-Variable -Name Jobobj ){Remove-Variable -ErrorAction Stop Jobobj -Force -Scope Global }
if(Get-Variable -Name Jobsclone ){Remove-Variable -ErrorAction Stop Jobsclone -Force -Scope Global }
    $runspacepool.Close()
[gc]::Collect()
    $ScriptBlockGetMetrics={
	Param ($hash,$Sa,$rsid)
    $SubscriptionInfo=$hash.subscriptionInfo
    $ArmConn=$hash.ArmConn
    $headers=$hash.headers
    $AsmConn=$hash.AsmConn
    $headerasm=$hash.headerasm
    $AzureCert=$hash.AzureCert
    $Timestampfield = $hash.Timestampfield
    $Currency=$hash.Currency
    $Locale=$hash.Locale
    $RegionInfo=$hash.RegionInfo
    $OfferDurableId=$hash.OfferDurableId
    $SyncInterval=$Hash.syncInterval
    $CustomerID =$hash.customerID
    $SharedKey = $hash.sharedKey
    $logname=$hash.Logname
    $StartTime = [dateTime]::Now
    $ApiVerSaAsm = $hash.ApiVerSaAsm
    $ApiVerSaArm = $hash.ApiVerSaArm
    $ApiStorage=$hash.ApiStorage
    $AAAccount = $hash.AAAccount
    $AAResourceGroup = $hash.AAResourceGroup
    $debuglog=$hash.deguglog
    $VarQueueList="AzureSAIngestion-List-Queues"
    $VarFilesList="AzureSAIngestion-List-Files"
    $SubscriptionId=$SubscriptionInfo.subscriptionId
	[OutputType([bool])]
 ($CustomerId, $SharedKey, $date,  $method,  $resource,$uri)
	{
    $StringToHash = $method + " `n" + " `n" + " `n$(date) `n" +"/" +$resource+$uri.AbsolutePath
		Add-Type -AssemblyName System.Web
    $query = [System.Web.HttpUtility]::ParseQueryString($uri.query)
    $querystr=''
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource,$EncodedHash
		return $authorization
	}
	function New-StorageSignature ($SharedKey, $date,  $method, $bodylength, $resource,$uri ,$service)
	{
		Add-Type -AssemblyName System.Web
    $str=  New-Object -TypeName "System.Text.StringBuilder" ;
    $builder=  [System.Text.StringBuilder]::new("/" )
    $builder.Append($resource) |out-null
    $builder.Append($uri.AbsolutePath) | out-null
    $str.Append($builder.ToString()) | out-null
    $values2=@{}
		IF($service -eq 'Table')
		{
    $values= [System.Web.HttpUtility]::ParseQueryString($uri.query)
			foreach ($str2 in $values.Keys)
			{
				[System.Collections.ArrayList]$list=$values.GetValues($str2)
    $list.sort()
    $builder2=  [System.Text.StringBuilder]::new()
				foreach ($obj2 in $list)
				{
					if ($builder2.Length -gt 0)
					{
    $builder2.Append(" ," );
					}
    $builder2.Append($obj2.ToString()) |Out-Null
				}
				IF ($null -ne $str2)
				{
    $values2.add($str2.ToLowerInvariant(),$builder2.ToString())
				}
			}
    $list2=[System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
			foreach ($str3 in $list2)
			{
				IF($str3 -eq 'comp')
				{
    $builder3=[System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" =" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" ?" ) |out-null
    $str.Append($builder3.ToString())|out-null
				}
			}
		}
		Else
		{
    $values= [System.Web.HttpUtility]::ParseQueryString($uri.query)
			foreach ($str2 in $values.Keys)
			{
				[System.Collections.ArrayList]$list=$values.GetValues($str2)
    $list.sort()
    $builder2=  [System.Text.StringBuilder]::new()
				foreach ($obj2 in $list)
				{
					if ($builder2.Length -gt 0)
					{
    $builder2.Append(" ," );
					}
    $builder2.Append($obj2.ToString()) |Out-Null
				}
				IF ($null -ne $str2)
				{
    $values2.add($str2.ToLowerInvariant(),$builder2.ToString())
				}
			}
    $list2=[System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
			foreach ($str3 in $list2)
			{
    $builder3=[System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" :" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" `n" ) |out-null
    $str.Append($builder3.ToString())|out-null
			}
		}
    $XHeaders = " x-ms-date:$(date) `n" +" x-ms-version:$ApiStorage"
		if ($service -eq 'Table')
		{
    $StringToHash= $method + " `n" + " `n" + " `n$(date) `n" +$str.ToString()
		}
		Else
		{
			IF ($method -eq 'GET' -or $method -eq 'HEAD')
			{
    $StringToHash = $method + " `n" + " `n" + " `n" + " `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" +$str.ToString()
			}
			Else
			{
    $StringToHash = $method + " `n" + " `n" + " `n$(bodylength) `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" +$str.ToString()
			}
		}
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource,$EncodedHash
		return $authorization
	}
	Function invoke-StorageREST($SharedKey, $method, $msgbody, $resource,$uri,$svc,$download)
	{
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
		If ($method -eq 'PUT')
    $params = @{
		    uri = $uri
		    date = $rfc1123date
		    service = $svc }Else {
		    resource = $resource
		    sharedKey = $SharedKey
		    bodylength = $msgbody.length
		    method = $method
		}
		{$signature @params
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
		If($svc -eq 'Table')
		{
    $headersforsa=  @{
				'Authorization'= " $signature"
				'x-ms-version'=" $apistorage"
				'x-ms-date'=" $rfc1123date"
				'Accept-Charset'='UTF-8'
				'MaxDataServiceVersion'='3.0;NetFx'
				'Accept'='application/json;odata=nometadata'
			}
		}
		Else
		{
    $HeadersforSA=  @{
				'x-ms-date'=" $rfc1123date"
				'Content-Type'='application\xml'
				'Authorization'= " $signature"
				'x-ms-version'=" $ApiStorage"
			}
		}
		IF($download)
		{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody  -OutFile " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
			return " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
		}Else{
			If ($svc -eq 'Table')
			{
				IF ($method -eq 'PUT'){
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method  -UseBasicParsing -Body $msgbody
					return $resp1
				}Else
				{  $resp1=Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method   -UseBasicParsing -Body $msgbody
    $xresp=$resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
				}
				return $xresp
			}Else
			{
				IF ($method -eq 'PUT'){
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
					return $resp1
				}Elseif($method -eq 'GET')
				{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody -ea 0
    $xresp=$resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
					return $xresp
				}Elseif($method -eq 'HEAD')
				{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
					return $resp1
				}
			}
		}
	}
	function Get-BlobSize -ErrorAction Stop ($bloburi,$storageaccount,$rg,$type)
	{
		If($type -eq 'ARM')
		{
    $Uri=" https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.Storage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $ApiVerSaArm, $storageaccount,$rg,$SubscriptionId
    $keyresp=Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys=ConvertFrom-Json -InputObject $keyresp.Content
    $prikey=$keys.keys[0].value
		}Elseif($type -eq 'Classic')
		{
    $Uri=" https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.ClassicStorage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $ApiVerSaAsm,$storageaccount,$rg,$SubscriptionId
    $keyresp=Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys=ConvertFrom-Json -InputObject $keyresp.Content
    $prikey=$keys.primaryKey
		}Else
		{
			"Could not detect storage account type, $storageaccount will not be processed"
			Continue
		}
    $vhdblob=invoke-StorageREST -sharedKey $prikey -method HEAD -resource $storageaccount -uri $bloburi
		Return [math]::round($vhdblob.Headers.'Content-Length'/1024/1024/1024,0)
	}
	function New-OMSSignature ($CustomerId, $SharedKey, $date, $ContentLength, $method, $ContentType, $resource)
	{
    $XHeaders = " x-ms-date:" + $date
    $StringToHash = $method + " `n$(contentLength) `n" + $ContentType + " `n$(xHeaders) `n" + $resource
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $CustomerId,$EncodedHash
		return $authorization
	}
	Function Post-OMSData($CustomerId, $SharedKey, $body, $LogType)
	{
    $method = "POST"
    $ContentType = " application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
    $ContentLength = $body.Length
    $params = @{
		    date = $rfc1123date
		    contentLength = $ContentLength
		    resource = $resource ; 	$uri = "https://$(customerId) .ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01" ; 	$OMSheaders = @{ "Authorization" = $signature; "Log-Type" = $LogType; " x-ms-date" = $rfc1123date; " time-generated-field" = $TimeStampField; }
		    sharedKey = $SharedKey
		    customerId = $CustomerId
		    contentType = $ContentType
		    fileName = $FileName
		    method = $method
		}
    $signature @params
		Try{
    $response = Invoke-WebRequest -Uri $uri -Method POST  -ContentType $ContentType -Headers $OMSheaders -Body $body -UseBasicParsing
		}catch [Net.WebException]
		{
    $ex=$_.Exception
			If ($_.Exception.Response.StatusCode.value__) {
    $exrespcode = ($_.Exception.Response.StatusCode.value__ ).ToString().Trim();
			}
			If  ($_.Exception.Message) {
    $ExMessage = ($_.Exception.Message).ToString().Trim();
			}
    $errmsg= " $exrespcode : $ExMessage"
		}
		if ($errmsg){return $errmsg }
		Else{	return $response.StatusCode }
		Write-error

    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
[Parameter()] [Parameter()]
    [ValidateNotNullOrEmpty()]
    $SubscriptionidFilter,
[Parameter()] [bool] $CollectionFromAllSubscriptions=$false,
[Parameter()] [bool] $GetAsmHeader=$true)
    $ErrorActionPreference= "Stop"
Write-Output "RB Initial Memory  : $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
    $StartTime = [dateTime]::Now
    $Timestampfield = "Timestamp"
    $timestamp=$StartTime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:00.000Z" )
    $CustomerID = Get-AutomationVariable -Name 'AzureSAIngestion-OPSINSIGHTS_WS_ID-MS-Mgmt-SA'
    $SharedKey = Get-AutomationVariable -Name 'AzureSAIngestion-OPSINSIGHTS_WS_KEY-MS-Mgmt-SA'
    $ApiVerSaAsm = '2016-04-01'
    $ApiVerSaArm = '2016-01-01'
    $ApiStorage='2016-05-31'
    $AAAccount = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationAccount-MS-Mgmt-SA'
    $AAResourceGroup = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationResourceGroup-MS-Mgmt-SA'
    $logname='AzureStorage'
    $hash = [hashtable]::New(@{})
    $Starttimer=get-date -ErrorAction Stop
[OutputType([bool])]
 ($CustomerId, $SharedKey, $date,  $method,  $resource,$uri)
{
    $StringToHash = $method + " `n" + " `n" + " `n$(date) `n" +"/" +$resource+$uri.AbsolutePath
	Add-Type -AssemblyName System.Web
    $query = [System.Web.HttpUtility]::ParseQueryString($uri.query)
    $querystr=''
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource,$EncodedHash
	return $authorization
}
function New-StorageSignature ($SharedKey, $date,  $method, $bodylength, $resource,$uri ,$service)
{
	Add-Type -AssemblyName System.Web
    $str=  New-Object -TypeName "System.Text.StringBuilder" ;
    $builder=  [System.Text.StringBuilder]::new("/" )
    $builder.Append($resource) |out-null
    $builder.Append($uri.AbsolutePath) | out-null
    $str.Append($builder.ToString()) | out-null
    $values2=@{}
	IF($service -eq 'Table')
	{
    $values= [System.Web.HttpUtility]::ParseQueryString($uri.query)
		foreach ($str2 in $values.Keys)
		{
			[System.Collections.ArrayList]$list=$values.GetValues($str2)
    $list.sort()
    $builder2=  [System.Text.StringBuilder]::new()
			foreach ($obj2 in $list)
			{
				if ($builder2.Length -gt 0)
				{
    $builder2.Append(" ," );
				}
    $builder2.Append($obj2.ToString()) |Out-Null
			}
			IF ($null -ne $str2)
			{
    $values2.add($str2.ToLowerInvariant(),$builder2.ToString())
			}
		}
    $list2=[System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
		foreach ($str3 in $list2)
		{
			IF($str3 -eq 'comp')
			{
    $builder3=[System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" =" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" ?" ) |out-null
    $str.Append($builder3.ToString())|out-null
			}
		}
	}
	Else
	{
    $values= [System.Web.HttpUtility]::ParseQueryString($uri.query)
		foreach ($str2 in $values.Keys)
		{
			[System.Collections.ArrayList]$list=$values.GetValues($str2)
    $list.sort()
    $builder2=  [System.Text.StringBuilder]::new()
			foreach ($obj2 in $list)
			{
				if ($builder2.Length -gt 0)
				{
    $builder2.Append(" ," );
				}
    $builder2.Append($obj2.ToString()) |Out-Null
			}
			IF ($null -ne $str2)
			{
    $values2.add($str2.ToLowerInvariant(),$builder2.ToString())
			}
		}
    $list2=[System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
		foreach ($str3 in $list2)
		{
    $builder3=[System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" :" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" `n" ) |out-null
    $str.Append($builder3.ToString())|out-null
		}
	}
    $XHeaders = " x-ms-date:$(date) `n" +" x-ms-version:$ApiStorage"
	if ($service -eq 'Table')
	{
    $StringToHash= $method + " `n" + " `n" + " `n$(date) `n" +$str.ToString()
	}
	Else
	{
		IF ($method -eq 'GET' -or $method -eq 'HEAD')
		{
    $StringToHash = $method + " `n" + " `n" + " `n" + " `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" +$str.ToString()
		}
		Else
		{
    $StringToHash = $method + " `n" + " `n" + " `n$(bodylength) `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" +$str.ToString()
		}
	}
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource,$EncodedHash
	return $authorization
}
Function invoke-StorageREST($SharedKey, $method, $msgbody, $resource,$uri,$svc,$download)
{
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
	If ($method -eq 'PUT')
    $params = @{
	    uri = $uri
	    date = $rfc1123date
	    service = $svc }Else {
	    resource = $resource
	    sharedKey = $SharedKey
	    bodylength = $msgbody.length
	    method = $method
	}
	{$signature @params
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
	If($svc -eq 'Table')
	{
    $headersforsa=  @{
			'Authorization'= " $signature"
			'x-ms-version'=" $apistorage"
			'x-ms-date'=" $rfc1123date"
			'Accept-Charset'='UTF-8'
			'MaxDataServiceVersion'='3.0;NetFx'
			'Accept'='application/json;odata=nometadata'
		}
	}
	Else
	{
    $HeadersforSA=  @{
			'x-ms-date'=" $rfc1123date"
			'Content-Type'='application\xml'
			'Authorization'= " $signature"
			'x-ms-version'=" $ApiStorage"
		}
	}
	IF($download)
	{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody  -OutFile " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
		return " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
	}Else{
		If ($svc -eq 'Table')
		{
			IF ($method -eq 'PUT'){
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method  -UseBasicParsing -Body $msgbody
				return $resp1
			}Else
			{  $resp1=Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method   -UseBasicParsing -Body $msgbody
    $xresp=$resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
			}
			return $xresp
		}Else
		{
			IF ($method -eq 'PUT'){
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
				return $resp1
			}Elseif($method -eq 'GET')
			{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody -ea 0
    $xresp=$resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
				return $xresp
			}Elseif($method -eq 'HEAD')
			{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
				return $resp1
			}
		}
	}
}
function Get-BlobSize -ErrorAction Stop ($bloburi,$storageaccount,$rg,$type)
{
	If($type -eq 'ARM')
	{
    $Uri=" https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.Storage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $ApiVerSaArm, $storageaccount,$rg,$SubscriptionId
    $keyresp=Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys=ConvertFrom-Json -InputObject $keyresp.Content
    $prikey=$keys.keys[0].value
	}Elseif($type -eq 'Classic')
	{
    $Uri=" https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.ClassicStorage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $ApiVerSaAsm,$storageaccount,$rg,$SubscriptionId
    $keyresp=Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys=ConvertFrom-Json -InputObject $keyresp.Content
    $prikey=$keys.primaryKey
	}Else
	{
		"Could not detect storage account type, $storageaccount will not be processed"
		Continue
	}
    $vhdblob=invoke-StorageREST -sharedKey $prikey -method HEAD -resource $storageaccount -uri $bloburi
	Return [math]::round($vhdblob.Headers.'Content-Length'/1024/1024/1024,0)
}
function New-OMSSignature ($CustomerId, $SharedKey, $date, $ContentLength, $method, $ContentType, $resource)
{
    $XHeaders = " x-ms-date:" + $date
    $StringToHash = $method + " `n$(contentLength) `n" + $ContentType + " `n$(xHeaders) `n" + $resource
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $CustomerId,$EncodedHash
	return $authorization
}
Function Post-OMSData($CustomerId, $SharedKey, $body, $LogType)
{
    $method = "POST"
    $ContentType = " application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
    $ContentLength = $body.Length
    $params = @{
	    date = $rfc1123date
	    contentLength = $ContentLength
	    resource = $resource
	    sharedKey = $SharedKey
	    customerId = $CustomerId
	    contentType = $ContentType
	    fileName = $FileName
	    method = $method
	}
    $signature @params
    $uri = "https://$(customerId) .ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"
    $OMSheaders = @{
		"Authorization" = $signature;
		"Log-Type" = $LogType;
		" x-ms-date" = $rfc1123date;
		" time-generated-field" = $TimeStampField;
	}
	Try{
    $response = Invoke-WebRequest -Uri $uri -Method POST  -ContentType $ContentType -Headers $OMSheaders -Body $body -UseBasicParsing
	}catch [Net.WebException]
	{
    $ex=$_.Exception
		If ($_.Exception.Response.StatusCode.value__) {
    $exrespcode = ($_.Exception.Response.StatusCode.value__ ).ToString().Trim();
		}
		If  ($_.Exception.Message) {
    $ExMessage = ($_.Exception.Message).ToString().Trim();
		}
    $errmsg= " $exrespcode : $ExMessage"
	}
	if ($errmsg){return $errmsg }
	Else{	return $response.StatusCode }
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
    $SubscriptionsURI=" https://management.azure.com/subscriptions?api-version=2016-06-01"
    $Subscriptions = Invoke-RestMethod -Uri  $SubscriptionsURI -Method GET  -Headers $headers -UseBasicParsing
    $Subscriptions=@($Subscriptions.value)
IF($CollectionFromAllSubscriptions -and $Subscriptions.count -gt 1 )
{
	Write-Output " $($Subscriptions.count) Subscription found , additonal runbook jobs will be created to collect data "
    $AAResourceGroup = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationResourceGroup-MS-Mgmt-SA'
    $AAAccount = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationAccount-MS-Mgmt-SA'
    $MetricsRunbookName = "AzureSAIngestionMetrics-MS-Mgmt-SA"
	$n=$Subscriptions.count-1
    $subslist=$subscriptions|where {$_.subscriptionId  -ne $SubscriptionId}
	Foreach($item in $subslist)
	{
    $params1 = @{"SubscriptionidFilter" =$item.subscriptionId;" collectionFromAllSubscriptions" = $false;" getAsmHeader" =$false}
		Start-AzureRmAutomationRunbook -AutomationAccountName $AAAccount -Name $MetricsRunbookName -ResourceGroupName $AAResourceGroup -Parameters $params1 | out-null
	}
}
" $(GEt-date) - Get ARM storage Accounts "
    $Uri=" https://management.azure.com/subscriptions/{1}/providers/Microsoft.Storage/storageAccounts?api-version={0}"   -f  $ApiVerSaArm,$SubscriptionId
    $armresp=Invoke-RestMethod -Uri $uri -Method GET  -Headers $headers -UseBasicParsing
    $SaArmList=$armresp.Value
" $(GEt-date)  $($SaArmList.count) classic storage accounts found"
" $(GEt-date)  Get Classic storage Accounts "
    $Uri=" https://management.azure.com/subscriptions/{1}/providers/Microsoft.ClassicStorage/storageAccounts?api-version={0}"   -f  $ApiVerSaAsm,$SubscriptionId
    $asmresp=Invoke-RestMethod -Uri $uri -Method GET  -Headers $headers -UseBasicParsing
    $SaAsmList=$asmresp.value
" $(GEt-date)  $($SaAsmList.count) storage accounts found"
    $ColParamsforChild=@()
foreach($sa in $SaArmList|where {$_.Sku.tier -ne 'Premium'})
{
    $rg=$sku=$null
    $rg=$sa.id.Split('/')[4]
    $ColParamsforChild = $ColParamsforChild + " $($sa.name);$($sa.id.Split('/')[4]);ARM;$($sa.sku.tier);$($sa.Kind)"
}
    $sa=$rg=$null
foreach($sa in $SaAsmList|where{$_.properties.accounttype -notmatch 'Premium'})
{
    $rg=$sa.id.Split('/')[4]
    $tier=$null
	If( $sa.properties.accountType -notmatch 'premium')
	{
    $tier='Standard'
    $ColParamsforChild = $ColParamsforChild + " $($sa.name);$($sa.id.Split('/')[4]);Classic;$tier;$($sa.Kind)"
	}
}
Write-Output "Core Count  $([System.Environment]::ProcessorCount)"
if($ColParamsforChild.count -eq 0)
{
	Write-Output "No Storage account found under subscription $subscriptionid , please note that Premium storage does not support metrics and excluded from the collection!"
	exit
}
    $SAInventory=@()
    $sa=$null
foreach($sa in $SaArmList)
{
    $rg=$sa.id.Split('/')[4]
    $cu=$null
    $cu = New-Object -ErrorAction Stop PSObject -Property @{
		Timestamp = $timestamp
		MetricName = 'Inventory';
		InventoryType='StorageAccount'
		StorageAccount=$sa.name
		Uri=" https://management.azure.com" +$sa.id
		DeploymentType='ARM'
		Location=$sa.location
		Kind=$sa.kind
		ResourceGroup=$rg
		Sku=$sa.sku.name
		Tier=$sa.sku.tier
		SubscriptionId = $ArmConn.SubscriptionId;
		AzureSubscription = $SubscriptionInfo.displayName
	}
	IF ($sa.properties.creationTime){$cu|Add-Member -MemberType NoteProperty -Name CreationTime -Value $sa.properties.creationTime}
	IF ($sa.properties.primaryLocation){$cu|Add-Member -MemberType NoteProperty -Name PrimaryLocation -Value $sa.properties.primaryLocation}
	IF ($sa.properties.secondaryLocation){$cu|Add-Member -MemberType NoteProperty -Name secondaryLocation-Value $sa.properties.secondaryLocation}
	IF ($sa.properties.statusOfPrimary){$cu|Add-Member -MemberType NoteProperty -Name statusOfPrimary -Value $sa.properties.statusOfPrimary}
	IF ($sa.properties.statusOfSecondary){$cu|Add-Member -MemberType NoteProperty -Name statusOfSecondary -Value $sa.properties.statusOfSecondary}
	IF ($sa.kind -eq 'BlobStorage'){$cu|Add-Member -MemberType NoteProperty -Name accessTier -Value $sa.properties.accessTier}
	IF ($t.properties.encryption.services.blob){$cu|Add-Member -MemberType NoteProperty -Name blobEncryption -Value 'enabled'}
	IF ($t.properties.encryption.services.file){$cu|Add-Member -MemberType NoteProperty -Name fileEncryption -Value 'enabled'}
    $SAInventory = $SAInventory + $cu
}
foreach($sa in $SaAsmList)
{
    $rg=$sa.id.Split('/')[4]
    $cu=$iotype=$null
	IF($sa.properties.accountType -like 'Standard*')
	{$iotype='Standard'}Else{$iotype='Premium'}
    $cu = New-Object -ErrorAction Stop PSObject -Property @{
		Timestamp = $timestamp
		MetricName = 'Inventory'
		InventoryType='StorageAccount'
		StorageAccount=$sa.name
		Uri=" https://management.azure.com" +$sa.id
		DeploymentType='Classic'
		Location=$sa.location
		Kind='Storage'
		ResourceGroup=$rg
		Sku=$sa.properties.accountType
		Tier=$iotype
		SubscriptionId = $ArmConn.SubscriptionId;
		AzureSubscription = $SubscriptionInfo.displayName
	}
	IF ($sa.properties.creationTime){$cu|Add-Member -MemberType NoteProperty -Name CreationTime -Value $sa.properties.creationTime}
	IF ($sa.properties.geoPrimaryRegion){$cu|Add-Member -MemberType NoteProperty -Name PrimaryLocation -Value $sa.properties.geoPrimaryRegion.Replace(' ','')}
	IF ($sa.properties.geoSecondaryRegion ){$cu|Add-Member -MemberType NoteProperty -Name SecondaryLocation-Value $sa.properties.geoSecondaryRegion.Replace(' ','')}
	IF ($sa.properties.statusOfPrimaryRegion){$cu|Add-Member -MemberType NoteProperty -Name statusOfPrimary -Value $sa.properties.statusOfPrimaryRegion}
	IF ($sa.properties.statusOfSecondaryRegion){$cu|Add-Member -MemberType NoteProperty -Name statusOfSecondary -Value $sa.properties.statusOfSecondaryRegion}
    $SAInventory = $SAInventory + $cu
}
    $JsonSAInventory = ConvertTo-Json -InputObject $SAInventory
If($JsonSAInventory){Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($JsonSAInventory)) -logType $logname}
" $(get-date)  - SA Inventory  data  uploaded"
    $quotas=@()
IF($GetAsmHeader)
{
    $uri=" https://management.core.windows.net/$SubscriptionId"
    $qresp=Invoke-WebRequest -Uri $uri -Method GET  -Headers $headerasm -UseBasicParsing -Certificate $AzureCert
	[xml]$qres=$qresp.Content
	[int]$SAMAX=$qres.Subscription.MaxStorageAccounts
	[int]$SACurrent=$qres.Subscription.CurrentStorageAccounts
    $Quotapct=$qres.Subscription.CurrentStorageAccounts/$qres.Subscription.MaxStorageAccounts*100
    $quotas = $quotas + New-Object -ErrorAction Stop PSObject -Property @{
		Timestamp = $timestamp
		MetricName = 'StorageQuotas';
		QuotaType="Classic"
		SAMAX=$samax
		SACurrent=$SACurrent
		Quotapct=$Quotapct
		SubscriptionId = $ArmConn.SubscriptionId;
		AzureSubscription = $SubscriptionInfo.displayName;
	}
}
    $SAMAX=$SACurrent=$SAquotapct=$null
    $usageuri=" https://management.azure.com/subscriptions/$(subscriptionid) /providers/Microsoft.Storage/usages?api-version=2016-05-01"
    $usageapi = Invoke-RestMethod -Uri $usageuri -Method GET -Headers $Headers  -UseBasicParsing;
    $usagecontent=$usageapi.value;
    $SAquotapct=$usagecontent[0].currentValue/$usagecontent[0].Limit*100
[int]$SAMAX=$usagecontent[0].limit
[int]$SACurrent=$usagecontent[0].currentValue
    $quotas = $quotas + New-Object -ErrorAction Stop PSObject -Property @{
	Timestamp = $timestamp
	MetricName = 'StorageQuotas';
	QuotaType="ARM"
	SAMAX=$SAMAX
	SACurrent=$SACurrent
	Quotapct=$SAquotapct
	SubscriptionId = $ArmConn.SubscriptionId;
	AzureSubscription = $SubscriptionInfo.displayName;
}
    $jsonquotas = ConvertTo-Json -InputObject $quotas
If($jsonquotas){Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonquotas)) -logType $logname}
" $(get-date)  - Quota info uploaded"
    $hash = [hashtable]::New(@{})
    $hash['Host']=$host
    $hash['subscriptionInfo']=$SubscriptionInfo
    $hash['ArmConn']=$ArmConn
    $hash['AsmConn']=$AsmConn
    $hash['headers']=$headers
    $hash['headerasm']=$headers
    $hash['AzureCert']=$AzureCert
    $hash['Timestampfield']=$Timestampfield
    $hash['customerID'] =$CustomerID
    $hash['syncInterval']=$SyncInterval
    $hash['sharedKey']=$SharedKey
    $hash['Logname']=$logname
    $hash['ApiVerSaAsm']=$ApiVerSaAsm
    $hash['ApiVerSaArm']=$ApiVerSaArm
    $hash['ApiStorage']=$ApiStorage
    $hash['AAAccount']=$AAAccount
    $hash['AAResourceGroup']=$AAResourceGroup
    $hash['debuglog']=$true
    $hash['saTransactionsMetrics']=@()
    $hash['saCapacityMetrics']=@()
    $hash['tableInventory']=@()
    $hash['fileInventory']=@()
    $hash['queueInventory']=@()
    $hash['vhdinventory']=@()
    $SAInfo=@()
    $hash.'SAInfo'=$sainfo
    $Throttle = [int][System.Environment]::ProcessorCount+1
    $sessionstate = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
    $runspacepool = [runspacefactory]::CreateRunspacePool(1, $Throttle, $sessionstate, $Host)
    $runspacepool.Open()
[System.Collections.ArrayList]$Jobs = @()
    $ScriptBlockGetKeys={
	Param ($hash,[array]$Sa,$rsid)
    $SubscriptionInfo=$hash.subscriptionInfo
    $ArmConn=$hash.ArmConn
    $headers=$hash.headers
    $AsmConn=$hash.AsmConn
    $headerasm=$hash.headerasm
    $AzureCert=$hash.AzureCert
    $Timestampfield = $hash.Timestampfield
    $Currency=$hash.Currency
    $Locale=$hash.Locale
    $RegionInfo=$hash.RegionInfo
    $OfferDurableId=$hash.OfferDurableId
    $SyncInterval=$Hash.syncInterval
    $CustomerID =$hash.customerID
    $SharedKey = $hash.sharedKey
    $logname=$hash.Logname
    $StartTime = [dateTime]::Now
    $ApiVerSaAsm = $hash.ApiVerSaAsm
    $ApiVerSaArm = $hash.ApiVerSaArm
    $ApiStorage=$hash.ApiStorage
    $AAAccount = $hash.AAAccount
    $AAResourceGroup = $hash.AAResourceGroup
    $debuglog=$hash.deguglog
    $VarQueueList="AzureSAIngestion-List-Queues"
    $VarFilesList="AzureSAIngestion-List-Files"
    $SubscriptionId=$SubscriptionInfo.subscriptionId
	[OutputType([bool])]
 ($CustomerId, $SharedKey, $date,  $method,  $resource,$uri)
	{
    $StringToHash = $method + " `n" + " `n" + " `n$(date) `n" +"/" +$resource+$uri.AbsolutePath
		Add-Type -AssemblyName System.Web
    $query = [System.Web.HttpUtility]::ParseQueryString($uri.query)
    $querystr=''
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource,$EncodedHash
		return $authorization
	}
	function New-StorageSignature ($SharedKey, $date,  $method, $bodylength, $resource,$uri ,$service)
	{
		Add-Type -AssemblyName System.Web
    $str=  New-Object -TypeName "System.Text.StringBuilder" ;
    $builder=  [System.Text.StringBuilder]::new("/" )
    $builder.Append($resource) |out-null
    $builder.Append($uri.AbsolutePath) | out-null
    $str.Append($builder.ToString()) | out-null
    $values2=@{}
		IF($service -eq 'Table')
		{
    $values= [System.Web.HttpUtility]::ParseQueryString($uri.query)
			foreach ($str2 in $values.Keys)
			{
				[System.Collections.ArrayList]$list=$values.GetValues($str2)
    $list.sort()
    $builder2=  [System.Text.StringBuilder]::new()
				foreach ($obj2 in $list)
				{
					if ($builder2.Length -gt 0)
					{
    $builder2.Append(" ," );
					}
    $builder2.Append($obj2.ToString()) |Out-Null
				}
				IF ($null -ne $str2)
				{
    $values2.add($str2.ToLowerInvariant(),$builder2.ToString())
				}
			}
    $list2=[System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
			foreach ($str3 in $list2)
			{
				IF($str3 -eq 'comp')
				{
    $builder3=[System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" =" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" ?" ) |out-null
    $str.Append($builder3.ToString())|out-null
				}
			}
		}
		Else
		{
    $values= [System.Web.HttpUtility]::ParseQueryString($uri.query)
			foreach ($str2 in $values.Keys)
			{
				[System.Collections.ArrayList]$list=$values.GetValues($str2)
    $list.sort()
    $builder2=  [System.Text.StringBuilder]::new()
				foreach ($obj2 in $list)
				{
					if ($builder2.Length -gt 0)
					{
    $builder2.Append(" ," );
					}
    $builder2.Append($obj2.ToString()) |Out-Null
				}
				IF ($null -ne $str2)
				{
    $values2.add($str2.ToLowerInvariant(),$builder2.ToString())
				}
			}
    $list2=[System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
			foreach ($str3 in $list2)
			{
    $builder3=[System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" :" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" `n" ) |out-null
    $str.Append($builder3.ToString())|out-null
			}
		}
    $XHeaders = " x-ms-date:$(date) `n" +" x-ms-version:$ApiStorage"
		if ($service -eq 'Table')
		{
    $StringToHash= $method + " `n" + " `n" + " `n$(date) `n" +$str.ToString()
		}
		Else
		{
			IF ($method -eq 'GET' -or $method -eq 'HEAD')
			{
    $StringToHash = $method + " `n" + " `n" + " `n" + " `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" +$str.ToString()
			}
			Else
			{
    $StringToHash = $method + " `n" + " `n" + " `n$(bodylength) `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" +$str.ToString()
			}
		}
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource,$EncodedHash
		return $authorization
	}
	Function invoke-StorageREST($SharedKey, $method, $msgbody, $resource,$uri,$svc,$download)
	{
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
		If ($method -eq 'PUT')
    $params = @{
		    uri = $uri
		    date = $rfc1123date
		    service = $svc }Else {
		    resource = $resource
		    sharedKey = $SharedKey
		    bodylength = $msgbody.length
		    method = $method
		}
		{$signature @params
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
		If($svc -eq 'Table')
		{
    $headersforsa=  @{
				'Authorization'= " $signature"
				'x-ms-version'=" $apistorage"
				'x-ms-date'=" $rfc1123date"
				'Accept-Charset'='UTF-8'
				'MaxDataServiceVersion'='3.0;NetFx'
				'Accept'='application/json;odata=nometadata'
			}
		}
		Else
		{
    $HeadersforSA=  @{
				'x-ms-date'=" $rfc1123date"
				'Content-Type'='application\xml'
				'Authorization'= " $signature"
				'x-ms-version'=" $ApiStorage"
			}
		}
		IF($download)
		{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody  -OutFile " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
			return " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
		}Else{
			If ($svc -eq 'Table')
			{
				IF ($method -eq 'PUT'){
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method  -UseBasicParsing -Body $msgbody
					return $resp1
				}Else
				{  $resp1=Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method   -UseBasicParsing -Body $msgbody
    $xresp=$resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
				}
				return $xresp
			}Else
			{
				IF ($method -eq 'PUT'){
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
					return $resp1
				}Elseif($method -eq 'GET')
				{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody -ea 0
    $xresp=$resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
					return $xresp
				}Elseif($method -eq 'HEAD')
				{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
					return $resp1
				}
			}
		}
	}
    $prikey=$storageaccount=$rg=$type=$null
    $storageaccount =$sa.Split(';')[0]
    $rg=$sa.Split(';')[1]
    $type=$sa.Split(';')[2]
    $tier=$sa.Split(';')[3]
    $kind=$sa.Split(';')[4]
	If($type -eq 'ARM')
	{
    $Uri=" https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.Storage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $ApiVerSaArm, $storageaccount,$rg,$SubscriptionId
    $keyresp=Invoke-RestMethod -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $prikey=$keyresp.keys[0].value
	}Elseif($type -eq 'Classic')
	{
    $uri=$keyresp=$null
    $Uri=" https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.ClassicStorage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $ApiVerSaAsm,$storageaccount,$rg,$SubscriptionId
    $keyresp=Invoke-RestMethod -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $prikey=$keyresp.primaryKey
	}Else
	{
		"Could not detect storage account type, $storageaccount will not be processed"
		Continue
	}
	IF ($kind -eq 'BlobStorage')
	{
    $svclist=@('blob','table')
	}Else
	{
    $svclist=@('blob','table','queue')
	}
    $logging=$false
	Foreach ($svc in $svclist)
	{
		[uri]$UriSvcProp = "https://{0}.{1}.core.windows.net/?restype=service&comp=properties	" -f $storageaccount,$svc
		IF($svc -eq 'table')
		{
			[xml]$SvcPropResp= invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriSvcProp -svc Table
		}else
		{
			[xml]$SvcPropResp= invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriSvcProp
		}
		IF($SvcPropResp.StorageServiceProperties.Logging.Read -eq 'true' -or $SvcPropResp.StorageServiceProperties.Logging.Write -eq 'true' -or $SvcPropResp.StorageServiceProperties.Logging.Delete -eq 'true')
		{
    $msg="Logging is enabled for {0} in {1}" -f $svc,$storageaccount
    $logging=$true
		}
		Else {
    $msg="Logging is not  enabled for {0} in {1}" -f $svc,$storageaccount
		}
	}
    $hash.SAInfo+=New-Object -ErrorAction Stop PSObject -Property @{
		StorageAccount = $storageaccount
		Key=$prikey
		Logging=$logging
		Rg=$rg
		Type=$type
		Tier=$tier
		Kind=$kind
	}
}
Write-Output "After Runspace creation  $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
write-output " $($ColParamsforChild.count) objects will be processed "
$i=1
    $Starttimer=get-date -ErrorAction Stop
    $ColParamsforChild|foreach{
    $splitmetrics=$null
    $splitmetrics=$_
    $Job = [powershell]::Create().AddScript($ScriptBlockGetKeys).AddArgument($hash).AddArgument($splitmetrics).Addargument($i)
    $Job.RunspacePool = $RunspacePool
    $Jobs = $Jobs + New-Object -ErrorAction Stop PSObject -Property @{
		RunNum = $i
		Pipe = $Job
		Result = $Job.BeginInvoke()
	}
    $i++
}
write-output  " $(get-date)  , started $i Runspaces "
Write-Output "After dispatching runspaces $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
    $JobsClone=$jobs.clone()
Write-Output "Waiting.."
$s=1
Do {
	Write-Output "  $(@($jobs.result.iscompleted|where{$_  -match 'False'}).count)  jobs remaining"
	foreach ($jobobj in $JobsClone)
	{
		if ($Jobobj.result.IsCompleted -eq $true)
		{
    $jobobj.Pipe.Endinvoke($jobobj.Result)
    $jobobj.pipe.dispose()
    $jobs.Remove($jobobj)
		}
	}
	IF($([System.gc]::gettotalmemory('forcefullcollection') /1MB) -gt 200)
	{
		[gc]::Collect()
	}
	IF($s%10 -eq 0)
	{
		Write-Output "Job $s - Mem: $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
	}
    $s++
	Start-Sleep -Seconds 15
} While ( @($jobs.result.iscompleted|where{$_  -match 'False'}).count -gt 0)
Write-output "All jobs completed!"
    $jobs|foreach{$_.Pipe.Dispose()}
if(Get-Variable -Name Jobs ){Remove-Variable -ErrorAction Stop Jobs -Force -Scope Global }
if(Get-Variable -Name Job ){Remove-Variable -ErrorAction Stop Job -Force -Scope Global }
if(Get-Variable -Name Jobobj ){Remove-Variable -ErrorAction Stop Jobobj -Force -Scope Global }
if(Get-Variable -Name Jobsclone ){Remove-Variable -ErrorAction Stop Jobsclone -Force -Scope Global }
    $runspacepool.Close()
[gc]::Collect()
    $ScriptBlockGetMetrics={
	Param ($hash,$Sa,$rsid)
    $SubscriptionInfo=$hash.subscriptionInfo
    $ArmConn=$hash.ArmConn
    $headers=$hash.headers
    $AsmConn=$hash.AsmConn
    $headerasm=$hash.headerasm
    $AzureCert=$hash.AzureCert
    $Timestampfield = $hash.Timestampfield
    $Currency=$hash.Currency
    $Locale=$hash.Locale
    $RegionInfo=$hash.RegionInfo
    $OfferDurableId=$hash.OfferDurableId
    $SyncInterval=$Hash.syncInterval
    $CustomerID =$hash.customerID
    $SharedKey = $hash.sharedKey
    $logname=$hash.Logname
    $StartTime = [dateTime]::Now
    $ApiVerSaAsm = $hash.ApiVerSaAsm
    $ApiVerSaArm = $hash.ApiVerSaArm
    $ApiStorage=$hash.ApiStorage
    $AAAccount = $hash.AAAccount
    $AAResourceGroup = $hash.AAResourceGroup
    $debuglog=$hash.deguglog
    $VarQueueList="AzureSAIngestion-List-Queues"
    $VarFilesList="AzureSAIngestion-List-Files"
    $SubscriptionId=$SubscriptionInfo.subscriptionId
	[OutputType([bool])]
 ($CustomerId, $SharedKey, $date,  $method,  $resource,$uri)
	{
    $StringToHash = $method + " `n" + " `n" + " `n$(date) `n" +"/" +$resource+$uri.AbsolutePath
		Add-Type -AssemblyName System.Web
    $query = [System.Web.HttpUtility]::ParseQueryString($uri.query)
    $querystr=''
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource,$EncodedHash
		return $authorization
	}
	function New-StorageSignature ($SharedKey, $date,  $method, $bodylength, $resource,$uri ,$service)
	{
		Add-Type -AssemblyName System.Web
    $str=  New-Object -TypeName "System.Text.StringBuilder" ;
    $builder=  [System.Text.StringBuilder]::new("/" )
    $builder.Append($resource) |out-null
    $builder.Append($uri.AbsolutePath) | out-null
    $str.Append($builder.ToString()) | out-null
    $values2=@{}
		IF($service -eq 'Table')
		{
    $values= [System.Web.HttpUtility]::ParseQueryString($uri.query)
			foreach ($str2 in $values.Keys)
			{
				[System.Collections.ArrayList]$list=$values.GetValues($str2)
    $list.sort()
    $builder2=  [System.Text.StringBuilder]::new()
				foreach ($obj2 in $list)
				{
					if ($builder2.Length -gt 0)
					{
    $builder2.Append(" ," );
					}
    $builder2.Append($obj2.ToString()) |Out-Null
				}
				IF ($null -ne $str2)
				{
    $values2.add($str2.ToLowerInvariant(),$builder2.ToString())
				}
			}
    $list2=[System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
			foreach ($str3 in $list2)
			{
				IF($str3 -eq 'comp')
				{
    $builder3=[System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" =" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" ?" ) |out-null
    $str.Append($builder3.ToString())|out-null
				}
			}
		}
		Else
		{
    $values= [System.Web.HttpUtility]::ParseQueryString($uri.query)
			foreach ($str2 in $values.Keys)
			{
				[System.Collections.ArrayList]$list=$values.GetValues($str2)
    $list.sort()
    $builder2=  [System.Text.StringBuilder]::new()
				foreach ($obj2 in $list)
				{
					if ($builder2.Length -gt 0)
					{
    $builder2.Append(" ," );
					}
    $builder2.Append($obj2.ToString()) |Out-Null
				}
				IF ($null -ne $str2)
				{
    $values2.add($str2.ToLowerInvariant(),$builder2.ToString())
				}
			}
    $list2=[System.Collections.ArrayList]::new($values2.Keys)
    $list2.sort()
			foreach ($str3 in $list2)
			{
    $builder3=[System.Text.StringBuilder]::new()
    $builder3.Append($str3) |out-null
    $builder3.Append(" :" ) |out-null
    $builder3.Append($values2[$str3]) |out-null
    $str.Append(" `n" ) |out-null
    $str.Append($builder3.ToString())|out-null
			}
		}
    $XHeaders = " x-ms-date:$(date) `n" +" x-ms-version:$ApiStorage"
		if ($service -eq 'Table')
		{
    $StringToHash= $method + " `n" + " `n" + " `n$(date) `n" +$str.ToString()
		}
		Else
		{
			IF ($method -eq 'GET' -or $method -eq 'HEAD')
			{
    $StringToHash = $method + " `n" + " `n" + " `n" + " `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" +$str.ToString()
			}
			Else
			{
    $StringToHash = $method + " `n" + " `n" + " `n$(bodylength) `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" +$str.ToString()
			}
		}
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $resource,$EncodedHash
		return $authorization
	}
	Function invoke-StorageREST($SharedKey, $method, $msgbody, $resource,$uri,$svc,$download)
	{
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
		If ($method -eq 'PUT')
    $params = @{
		    uri = $uri
		    date = $rfc1123date
		    service = $svc }Else {
		    resource = $resource
		    sharedKey = $SharedKey
		    bodylength = $msgbody.length
		    method = $method
		}
		{$signature @params
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
		If($svc -eq 'Table')
		{
    $headersforsa=  @{
				'Authorization'= " $signature"
				'x-ms-version'=" $apistorage"
				'x-ms-date'=" $rfc1123date"
				'Accept-Charset'='UTF-8'
				'MaxDataServiceVersion'='3.0;NetFx'
				'Accept'='application/json;odata=nometadata'
			}
		}
		Else
		{
    $HeadersforSA=  @{
				'x-ms-date'=" $rfc1123date"
				'Content-Type'='application\xml'
				'Authorization'= " $signature"
				'x-ms-version'=" $ApiStorage"
			}
		}
		IF($download)
		{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody  -OutFile " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
			return " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
		}Else{
			If ($svc -eq 'Table')
			{
				IF ($method -eq 'PUT'){
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method  -UseBasicParsing -Body $msgbody
					return $resp1
				}Else
				{  $resp1=Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method   -UseBasicParsing -Body $msgbody
    $xresp=$resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
				}
				return $xresp
			}Else
			{
				IF ($method -eq 'PUT'){
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
					return $resp1
				}Elseif($method -eq 'GET')
				{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody -ea 0
    $xresp=$resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
					return $xresp
				}Elseif($method -eq 'HEAD')
				{
    $resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
					return $resp1
				}
			}
		}
	}
	function Get-BlobSize -ErrorAction Stop ($bloburi,$storageaccount,$rg,$type)
	{
		If($type -eq 'ARM')
		{
    $Uri=" https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.Storage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $ApiVerSaArm, $storageaccount,$rg,$SubscriptionId
    $keyresp=Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys=ConvertFrom-Json -InputObject $keyresp.Content
    $prikey=$keys.keys[0].value
		}Elseif($type -eq 'Classic')
		{
    $Uri=" https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.ClassicStorage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $ApiVerSaAsm,$storageaccount,$rg,$SubscriptionId
    $keyresp=Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys=ConvertFrom-Json -InputObject $keyresp.Content
    $prikey=$keys.primaryKey
		}Else
		{
			"Could not detect storage account type, $storageaccount will not be processed"
			Continue
		}
    $vhdblob=invoke-StorageREST -sharedKey $prikey -method HEAD -resource $storageaccount -uri $bloburi
		Return [math]::round($vhdblob.Headers.'Content-Length'/1024/1024/1024,0)
	}
	function New-OMSSignature ($CustomerId, $SharedKey, $date, $ContentLength, $method, $ContentType, $resource)
	{
    $XHeaders = " x-ms-date:" + $date
    $StringToHash = $method + " `n$(contentLength) `n" + $ContentType + " `n$(xHeaders) `n" + $resource
    $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
    $KeyBytes = [Convert]::FromBase64String($SharedKey)
    $sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
    $sha256.Key = $KeyBytes
    $CalculatedHash = $sha256.ComputeHash($BytesToHash)
    $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $CustomerId,$EncodedHash
		return $authorization
	}
	Function Post-OMSData($CustomerId, $SharedKey, $body, $LogType)
	{
    $method = "POST"
    $ContentType = " application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
    $ContentLength = $body.Length
    $params = @{
		    date = $rfc1123date
		    contentLength = $ContentLength
		    resource = $resource ; 	$uri = "https://$(customerId) .ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01" ; 	$OMSheaders = @{ "Authorization" = $signature; "Log-Type" = $LogType; " x-ms-date" = $rfc1123date; " time-generated-field" = $TimeStampField; }
		    sharedKey = $SharedKey
		    customerId = $CustomerId
		    contentType = $ContentType
		    fileName = $FileName
		    method = $method
		}
    $signature @params
		Try{
    $response = Invoke-WebRequest -Uri $uri -Method POST  -ContentType $ContentType -Headers $OMSheaders -Body $body -UseBasicParsing
		}catch [Net.WebException]
		{
    $ex=$_.Exception
			If ($_.Exception.Response.StatusCode.value__) {
    $exrespcode = ($_.Exception.Response.StatusCode.value__ ).ToString().Trim();
			}
			If  ($_.Exception.Message) {
    $ExMessage = ($_.Exception.Message).ToString().Trim();
			}
    $errmsg= " $exrespcode : $ExMessage"
		}
		if ($errmsg){return $errmsg }
		Else{	return $response.StatusCode }
		Write-error $error[0]
	}
    $prikey=$sa.key
    $storageaccount =$sa.StorageAccount
    $rg=$sa.rg
    $type=$sa.Type
    $tier=$sa.Tier
    $kind=$sa.Kind
    $colltime=Get-Date -ErrorAction Stop
	If($colltime.Minute -in 0..15)
	{
    $MetricColstartTime=$colltime.ToUniversalTime().AddHours(-1).ToString(" yyyyMMdd'T'HH46" )
    $MetricColendTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH00" )
	}
	Elseif($colltime.Minute -in 16..30)
	{
    $MetricColstartTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH00" )
    $MetricColendTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH15" )
	}
	Elseif($colltime.Minute -in 31..45)
	{
    $MetricColstartTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH16" )
    $MetricColendTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH30" )
	}
	Else
	{
    $MetricColstartTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH31" )
    $MetricColendTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH45" )
	}
    $hour=$MetricColEndTime.substring($MetricColEndTime.Length-4,4).Substring(0,2)
    $min=$MetricColEndTime.substring($MetricColEndTime.Length-4,4).Substring(2,2)
    $timestamp=(get-date).ToUniversalTime().ToString(" yyyy-MM-ddT$($hour):$($min):00.000Z" )
    $ColParamsforChild=@()
    $SaMetricsAvg=@()
    $storcapacity=@()
    $fltr1='?$filter='+"PartitionKey%20ge%20'$(MetricColstartTime) '%20and%20PartitionKey%20le%20'" +$MetricColendTime+" '%20and%20RowKey%20eq%20'user;All'"
    $slct1='&$select=PartitionKey,TotalRequests,TotalBillableRequests,TotalIngress,TotalEgress,AverageE2ELatency,AverageServerLatency,PercentSuccess,Availability,PercentThrottlingError,PercentNetworkError,PercentTimeoutError,SASAuthorizationError,PercentAuthorizationError,PercentClientOtherError,PercentServerOtherError'
    $sa=$null
    $vhdinventory=@()
    $AllContainers=@()
    $queueinventory=@()
    $queuearr=@()
    $QueueMetrics=@()
    $Fileinventory=@()
    $filearr=@()
    $InvFS=@()
    $fileshareinventory=@()
    $tableinventory=@()
    $tablearr=@{}
    $vmlist=@()
    $allvms=@()
    $allvhds=@()
    $tablelist= @('$MetricsMinutePrimaryTransactionsBlob','$MetricsMinutePrimaryTransactionsTable','$MetricsMinutePrimaryTransactionsQueue','$MetricsMinutePrimaryTransactionsFile')
	Foreach ($TableName in $tablelist)
	{
    $signature=$headersforsa=$null
		[uri]$tablequri=" https://$($storageaccount).table.core.windows.net/" +$TableName+'()'
    $resource = $storageaccount
    $logdate=[DateTime]::UtcNow
    $rfc1123date = $logdate.ToString(" r" )
    $params = @{
	    uri = $tablequri
	    date = $rfc1123date
	    service = "table"
	    resource = $storageaccount
	    sharedKey = $prikey
	    method = "GET"
	}
	; @params
    $headersforsa=  @{
			'Authorization'= " $signature"
			'x-ms-version'=" $apistorage"
			'x-ms-date'=" $rfc1123date"
			'Accept-Charset'='UTF-8'
			'MaxDataServiceVersion'='3.0;NetFx'
			'Accept'='application/json;odata=nometadata'
		}
    $response=$jresponse=$null
    $FullQuery=$tablequri.OriginalString+$fltr1+$slct1
    $method = "GET"
		Try
		{
    $response = Invoke-WebRequest -Uri $FullQuery -Method $method  -Headers $headersforsa  -UseBasicParsing  -ErrorAction SilentlyContinue
		}
		Catch
		{
    $ErrorMessage = $_.Exception.Message
    $StackTrace = $_.Exception.StackTrace
			Write-Warning "Error during accessing metrics table $tablename .Error: $ErrorMessage, stack: $StackTrace."
		}
    $Jresponse=convertFrom-Json    $response.Content
		IF($Jresponse.Value)
		{
    $entities=$null
    $entities=$Jresponse.value
    $stormetrics=@()
			foreach ($rowitem in $entities)
			{
    $cu=$null
    $dt=$rowitem.PartitionKey
    $timestamp=$dt.Substring(0,4)+'-'+$dt.Substring(4,2)+'-'+$dt.Substring(6,3)+$dt.Substring(9,2)+':'+$dt.Substring(11,2)+':00.000Z'
    $cu = New-Object -ErrorAction Stop PSObject -Property @{
					Timestamp = $timestamp
					MetricName = 'MetricsTransactions'
					TotalRequests=[long]$rowitem.TotalRequests
					TotalBillableRequests=[long]$rowitem.TotalBillableRequests
					TotalIngress=[long]$rowitem.TotalIngress
					TotalEgress=[long]$rowitem.TotalEgress
					Availability=[float]$rowitem.Availability
					AverageE2ELatency=[int]$rowitem.AverageE2ELatency
					AverageServerLatency=[int]$rowitem.AverageServerLatency
					PercentSuccess=[float]$rowitem.PercentSuccess
					PercentThrottlingError=[float]$rowitem.PercentThrottlingError
					PercentNetworkError=[float]$rowitem.PercentNetworkError
					PercentTimeoutError=[float]$rowitem.PercentTimeoutError
					SASAuthorizationError=[float]$rowitem.SASAuthorizationError
					PercentAuthorizationError=[float]$rowitem.PercentAuthorizationError
					PercentClientOtherError=[float]$rowitem.PercentClientOtherError
					PercentServerOtherError=[float]$rowitem.PercentServerOtherError
					ResourceGroup=$rg
					StorageAccount = $StorageAccount
					StorageService=$TableName.Substring(33,$TableName.Length-33)
					SubscriptionId = $ArmConn.SubscriptionID
					AzureSubscription = $SubscriptionInfo.displayName
				}
    $hash['saTransactionsMetrics']+=$cu
			}
		}
	}
    $TableName = '$MetricsCapacityBlob'
    $startdate=(get-date).AddDays(-1).ToUniversalTime().ToString(" yyyyMMdd'T'0000" )
    $table=$null
    $signature=$headersforsa=$null
	[uri]$tablequri=" https://$($storageaccount).table.core.windows.net/" +$TableName+'()'
    $resource = $storageaccount
    $logdate=[DateTime]::UtcNow
    $rfc1123date = $logdate.ToString(" r" )
    $params = @{
    uri = $tablequri
    date = $rfc1123date
    service = "table"
    resource = $storageaccount
    sharedKey = $prikey
    method = "GET"
}
; @params
    $headersforsa=  @{
		'Authorization'= " $signature"
		'x-ms-version'=" $apistorage"
		'x-ms-date'=" $rfc1123date"
		'Accept-Charset'='UTF-8'
		'MaxDataServiceVersion'='3.0;NetFx'
		'Accept'='application/json;odata=nometadata'
	}
    $response=$jresponse=$null
    $fltr2='?$filter='+"PartitionKey%20gt%20'$(startdate) '%20and%20RowKey%20eq%20'data'"
    $FullQuery=$tablequri.OriginalString+$fltr2
    $method = "GET"
	Try
	{
    $response = Invoke-WebRequest -Uri $FullQuery -Method $method  -Headers $headersforsa  -UseBasicParsing  -ErrorAction SilentlyContinue
	}
	Catch
	{
    $ErrorMessage = $_.Exception.Message
    $StackTrace = $_.Exception.StackTrace
		Write-Warning "Error during accessing metrics table $tablename .Error: $ErrorMessage, stack: $StackTrace."
	}
    $Jresponse=convertFrom-Json    $response.Content
	IF($Jresponse.Value)
	{
    $entities=$null
    $entities=@($jresponse.value)
    $cu=$null
    $cu = New-Object -ErrorAction Stop PSObject -Property @{
			Timestamp = $timestamp
			MetricName = 'MetricsCapacity'
			Capacity=$([long]$entities[0].Capacity)/1024/1024/1024
			ContainerCount=[long]$entities[0].ContainerCount
			ObjectCount=[long]$entities[0].ObjectCount
			ResourceGroup=$rg
			StorageAccount = $StorageAccount
			StorageService="Blob"
			SubscriptionId = $ArmConn.SubscriptionId
			AzureSubscription = $SubscriptionInfo.displayName
		}
    $hash['saCapacityMetrics']+=$cu
	}
	IF($tier -notmatch 'premium' -and $kind -ne 'BlobStorage')
	{
		[uri]$UriQueue=" https://{0}.queue.core.windows.net?comp=list" -f $storageaccount
		[xml]$Xresponse=invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriQueue
		IF (![String]::IsNullOrEmpty($Xresponse.EnumerationResults.Queues.Queue))
		{
			Foreach ($queue in $Xresponse.EnumerationResults.Queues.Queue)
			{
				write-verbose  "Queue found :$($sa.name) ; $($queue.name) "
    $queuearr = $queuearr + " {0};{1}" -f $queue.Name.tostring(),$sa.name
    $queueinventory = $queueinventory + New-Object -ErrorAction Stop PSObject -Property @{
					Timestamp = $timestamp
					MetricName = 'Inventory'
					InventoryType='Queue'
					StorageAccount=$sa.name
					Queue= $queue.Name
					Uri=$UriQueue.Scheme+'://'+$UriQueue.Host+'/'+$queue.Name
					SubscriptionID = $ArmConn.SubscriptionId;
					AzureSubscription = $SubscriptionInfo.displayName
					ShowinDesigner=1
				}
				[uri]$uriforq=" https://$storageaccount.queue.core.windows.net/$($queue.name)/messages?peekonly=true"
				[xml]$Xmlqresp= invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $uriforq
				[uri]$uriform=" https://$storageaccount.queue.core.windows.net/$($queue.name)?comp=metadata"
    $Xmlqrespm= invoke-StorageREST -sharedKey $prikey -method HEAD -resource $storageaccount -uri $uriform
    $cuq=$null
    $cuq = $cuq + New-Object -ErrorAction Stop PSObject -Property @{
					Timestamp=$timestamp
					MetricName = 'QueueMetrics';
					StorageAccount=$storageaccount
					StorageService="Queue"
					Queue= $queue.Name
					approximateMsgCount=$Xmlqrespm.Headers.'x-ms-approximate-messages-count'
					SubscriptionId = $ArmConn.SubscriptionId;
					AzureSubscription = $SubscriptionInfo.displayName
				}
    $msg=$Xmlqresp.QueueMessagesList.QueueMessage
				IF(![string]::IsNullOrEmpty($Xmlqresp.QueueMessagesList))
				{
    $cuq|Add-Member -MemberType NoteProperty -Name FirstMessageID -Value $msg.MessageId
    $cuq|Add-Member -MemberType NoteProperty -Name FirstMessageText -Value $msg.MessageText
    $cuq|Add-Member -MemberType NoteProperty -Name FirstMsgInsertionTime -Value $msg.InsertionTime
    $cuq|Add-Member -MemberType NoteProperty -Name Minutesinqueue -Value [Math]::Round(((Get-date).ToUniversalTime()-[datetime]($Xmlqresp.QueueMessagesList.QueueMessage.InsertionTime)).Totalminutes,0)
				}
    $hash['tableInventory']+=$cuq
			}
		}
	}
	IF($tier -notmatch 'premium' -and $kind -ne 'BlobStorage')
	{
		[uri]$UriFile=" https://{0}.file.core.windows.net?comp=list" -f $storageaccount
		[xml]$Xresponse=invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriFile
		if(![string]::IsNullOrEmpty($Xresponse.EnumerationResults.Shares.Share))
		{
			foreach($share in @($Xresponse.EnumerationResults.Shares.Share))
			{
				write-verbose  "File Share found :$($storageaccount) ; $($share.Name) "
    $filelist=@()
    $filearr = $filearr + " {0};{1}" -f $Share.Name,$storageaccount
    $cuf= New-Object -ErrorAction Stop PSObject -Property @{
					Timestamp = $timestamp
					MetricName = 'Inventory'
					InventoryType='File'
					StorageAccount=$storageaccount
					FileShare=$share.Name
					Uri=$UriFile.Scheme+'://'+$UriFile.Host+'/'+$Share.Name
					Quota=$share.Properties.Quota
					SubscriptionID = $ArmConn.SubscriptionId;
					AzureSubscription = $SubscriptionInfo.displayName
					ShowinDesigner=1
				}
				[uri]$UriforF=" https://{0}.file.core.windows.net/{1}?restype=share&comp=stats" -f $storageaccount,$share.Name
				[xml]$Xmlresp=invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriforF
				IF($Xmlresp)
				{
    $cuf|Add-Member -MemberType NoteProperty -Name  ShareUsedGB -Value $([int]$Xmlresp.ShareStats.ShareUsage)
				}
    $hash['fileInventory']+=$cuf
			}
		}
	}
	IF($tier -notmatch 'premium')
	{
		[uri]$uritable=" https://{0}.table.core.windows.net/Tables" -f $storageaccount
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
    $params = @{
	    uri = $uritable
	    UseBasicParsing = "; 	$RespJson=convertFrom-Json    $tableresp.Content  IF (![string]::IsNullOrEmpty($RespJson.value.Tablename)) { foreach($tbl in @($RespJson.value.Tablename)) { write-verbose  "Table found :$storageaccount ; $($tbl) "  #$tablearr = $tablearr + " {0}"
	    date = $rfc1123date
	    service = "table ; 	$headersforsa=  @{ 'Authorization'= " $signature" 'x-ms-version'=" $apistorage" 'x-ms-date'=" $rfc1123date" 'Accept-Charset'='UTF-8' 'MaxDataServiceVersion'='3.0;NetFx' 'Accept'='application/json;odata=nometadata' } $tableresp=Invoke-WebRequest"
	    resource = $sa.name
	    sharedKey = $prikey
	    Property = "@{ Timestamp = $timestamp MetricName = 'Inventory' InventoryType='Table' StorageAccount=$storageaccount Table=$tbl Uri=$uritable.Scheme+'://'+$uritable.Host+'/'+$tbl SubscriptionID = $ArmConn.SubscriptionId; AzureSubscription = $SubscriptionInfo.displayName ShowinDesigner=1  } } } }"
	    ErrorAction = "Stop PSObject"
	    Headers = $headersforsa
	    f = $sa.name IF ([string]::IsNullOrEmpty($tablearr.Get_item($storageaccount))) { $tablearr.add($sa.name,'Storageaccount') }   $hash['queueInventory']+= New-Object
	    method = "GET"
	}
	; @params
	if ((get-date).hour -in (1,5,9,13,17,21) -and   (get-date).minute -in (1..16)   )
	{
		[uri]$UriListC= "https://{0}.blob.core.windows.net/?comp=list" -f $storageaccount
		Write-verbose " $(get-date) - Getting list of blobs for $($sa.name) "
		[xml]$lb=invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriListC
    $containers=@($lb.EnumerationResults.Containers.Container)
		IF(![string]::IsNullOrEmpty($lb.EnumerationResults.Containers.Container))
		{
			Foreach($container in @($containers))
			{
    $allcontainers = $allcontainers + $container
				[uri]$UriLBlobs = "https://{0}.blob.core.windows.net/{1}/?comp=list&include=metadata&maxresults=1000&restype=container" -f $storageaccount,$container.name
				[xml]$fresponse= invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriLBlobs
    $filesincontainer=@()
    $blobs=$fresponse.EnumerationResults.Blobs.blob
				Foreach($blob in $blobs)
				{
					IF($blob.name -match '.vhd')
					{
    $cu = New-Object -ErrorAction Stop PSObject -Property @{
							Timestamp = $timestamp
							MetricName = 'Inventory'
							InventoryType='VHDFile'
							Capacity=[Math]::Round($blob.Properties.'Content-Length'/1024/1024/1024,0)
							Container=$container.Name
							VHDName=$blob.name
							Uri= " {0}{1}/{2}" -f $fresponse.EnumerationResults.ServiceEndpoint,$Container.Name,$blob.Name
							LeaseState=$blob.Properties.LeaseState.ToString()
							StorageAccount= $storageaccount
							SubscriptionID = $ArmConn.SubscriptionId;
							AzureSubscription = $SubscriptionInfo.displayName
							ShowinDesigner=1
						}
    $hash['vhdinventory']+=$cu
					}
				}
    $filesincontainer|Group-Object Fileextension|select Name,count
    $fileshareinventory = $fileshareinventory + $filesincontainer
			}
		}
	}
}
    $Throttle = [System.Environment]::ProcessorCount+1
    $sessionstate = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
    $runspacepool = [runspacefactory]::CreateRunspacePool(1, $Throttle, $sessionstate, $Host)
    $runspacepool.Open()
[System.Collections.ArrayList]$Jobs = @()
Write-Output "After Runspace creation for metric collection : $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
$i=1
    $Starttimer=get-date -ErrorAction Stop
    $hash.SAInfo|foreach{
    $splitmetrics=$null
    $splitmetrics=$_
    $Job = [powershell]::Create().AddScript($ScriptBlockGetMetrics).AddArgument($hash).AddArgument($splitmetrics).Addargument($i)
    $Job.RunspacePool = $RunspacePool
    $Jobs = $Jobs + New-Object -ErrorAction Stop PSObject -Property @{
		RunNum = $i
		Pipe = $Job
		Result = $Job.BeginInvoke()
	}
    $i++
}
write-output  " $(get-date)  , started $i Runspaces "
Write-Output "After dispatching runspaces $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
    $JobsClone=$jobs.clone()
Write-Output "Waiting.."
$s=1
Do {
	Write-Output "  $(@($jobs.result.iscompleted|where{$_  -match 'False'}).count)  jobs remaining"
	foreach ($jobobj in $JobsClone)
	{
		if ($Jobobj.result.IsCompleted -eq $true)
		{
    $jobobj.Pipe.Endinvoke($jobobj.Result)
    $jobobj.pipe.dispose()
    $jobs.Remove($jobobj)
		}
	}
	IF($s%2 -eq 0)
	{
		Write-Output "Mem: $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
	}
    $s++
	Start-Sleep -Seconds 15
} While ( @($jobs.result.iscompleted|where{$_  -match 'False'}).count -gt 0)
Write-output "All jobs completed!"
    $jobs|foreach{$_.Pipe.Dispose()}
Remove-Variable -ErrorAction Stop Jobs -Force -Scope Global
Remove-Variable -ErrorAction Stop Job -Force -Scope Global
Remove-Variable -ErrorAction Stop Jobobj -Force -Scope Global
Remove-Variable -ErrorAction Stop Jobsclone -Force -Scope Global
    $runspacepool.Close()
$([System.gc]::gettotalmemory('forcefullcollection') /1MB)
    $Endtimer=get-date -ErrorAction Stop
Write-Output "All jobs completed in $(($Endtimer-$starttimer).TotalMinutes) minutes"
Write-Output "Uploading to OMS ..."
    $SplitSize=5000
If($hash.saTransactionsMetrics)
{
	write-output  "Uploading  $($hash.saTransactionsMetrics.count) transaction metrics"
    $UploadToOms=$hash.saTransactionsMetrics
    $hash.saTransactionsMetrics=@()
	If($UploadToOms.count -gt $SplitSize)
	{
    $spltlist=@()
    $spltlist = $spltlist + for ($Index = 0; $Index -lt $UploadToOms.count; $Index = $Index + $SplitSize)
		{
			,($UploadToOms[$index..($index+$SplitSize-1)])
		}
    $spltlist|foreach{
    $SplitLogs=$null
    $SplitLogs=$_
    $jsonlogs= ConvertTo-Json -InputObject $SplitLogs
			Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
		}
	}Else{
    $jsonlogs= ConvertTo-Json -InputObject $UploadToOms
		Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
	}
	Remove-Variable -ErrorAction Stop uploadToOms -Force -Scope Global -ErrorAction SilentlyContinue
	Remove-Variable -ErrorAction Stop jsonlogs -Force -Scope Global -ErrorAction SilentlyContinue
	Remove-Variable -ErrorAction Stop spltlist -Force -Scope Global -ErrorAction SilentlyContinue
	[System.gc]::Collect()
}
If($hash.saCapacityMetrics)
{
	write-output  "Uploading  $($hash.saCapacityMetrics.count) capacity metrics"
    $UploadToOms=$hash.saCapacityMetrics
    $hash.saCapacityMetrics=@()
	If($UploadToOms.count -gt $SplitSize)
	{
    $spltlist=@()
    $spltlist = $spltlist + for ($Index = 0; $Index -lt $UploadToOms.count; $Index = $Index + $SplitSize)
		{
			,($UploadToOms[$index..($index+$SplitSize-1)])
		}
    $spltlist|foreach{
    $SplitLogs=$null
    $SplitLogs=$_
    $jsonlogs= ConvertTo-Json -InputObject $SplitLogs
			Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
		}
	}Else{
    $jsonlogs= ConvertTo-Json -InputObject $UploadToOms
		Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
	}
	Remove-Variable -ErrorAction Stop uploadToOms -Force -Scope Global  -ErrorAction SilentlyContinue
	Remove-Variable -ErrorAction Stop jsonlogs -Force -Scope Global -ErrorAction SilentlyContinue
	Remove-Variable -ErrorAction Stop spltlist -Force -Scope Global -ErrorAction SilentlyContinue
	[System.gc]::Collect()
}
If($hash.tableInventory)
{
	write-output  "Uploading  $($hash.tableInventory.count) table inventory"
    $UploadToOms=$hash.tableInventory
    $hash.tableInventory=@()
	If($UploadToOms.count -gt $SplitSize)
	{
    $spltlist=@()
    $spltlist = $spltlist + for ($Index = 0; $Index -lt $UploadToOms.count; $Index = $Index + $SplitSize)
		{
			,($UploadToOms[$index..($index+$SplitSize-1)])
		}
    $spltlist|foreach{
    $SplitLogs=$null
    $SplitLogs=$_
    $jsonlogs= ConvertTo-Json -InputObject $SplitLogs
			Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
		}
	}Else{
    $jsonlogs= ConvertTo-Json -InputObject $UploadToOms
		Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
	}
	Remove-Variable -ErrorAction Stop uploadToOms -Force -Scope Global -ErrorAction SilentlyContinue
	Remove-Variable -ErrorAction Stop jsonlogs -Force -Scope Global -ErrorAction SilentlyContinue
	Remove-Variable -ErrorAction Stop spltlist -Force -Scope Global -ErrorAction SilentlyContinue
	[System.gc]::Collect()
}
If(!$hash.queueInventory)
{
    $hash.queueInventory+=New-Object -ErrorAction Stop PSObject -Property @{
		Timestamp = $timestamp
		MetricName = 'Inventory'
		InventoryType='Queue'
		Queue= "NO RESOURCE FOUND"
		Uri="NO RESOURCE FOUND"
		SubscriptionID = $ArmConn.SubscriptionId;
		AzureSubscription = $SubscriptionInfo.displayName
		ShowinDesigner=0
	}
}
write-output  "Uploading  $($hash.queueInventory.count) queue inventory"
    $UploadToOms=$hash.queueInventory
    $hash.queueInventory=@()
If($UploadToOms.count -gt $SplitSize)
{
    $spltlist=@()
    $spltlist = $spltlist + for ($Index = 0; $Index -lt $UploadToOms.count; $Index = $Index + $SplitSize)
	{
		,($UploadToOms[$index..($index+$SplitSize-1)])
	}
    $spltlist|foreach{
    $SplitLogs=$null
    $SplitLogs=$_
    $jsonlogs= ConvertTo-Json -InputObject $SplitLogs
		Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
	}
}Else{
    $jsonlogs= ConvertTo-Json -InputObject $UploadToOms
	Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
}
Remove-Variable -ErrorAction Stop uploadToOms -Force -Scope Global  -ErrorAction SilentlyContinue
Remove-Variable -ErrorAction Stop jsonlogs -Force -Scope Global  -ErrorAction SilentlyContinue
Remove-Variable -ErrorAction Stop spltlist -Force -Scope Global  -ErrorAction SilentlyContinue
[System.gc]::Collect()
If(!$hash.fileInventory)
{
    $hash.fileInventory+=New-Object -ErrorAction Stop PSObject -Property @{
		Timestamp = $timestamp
		MetricName = 'Inventory'
		InventoryType='File'
		FileShare="NO RESOURCE FOUND"
		Uri="NO RESOURCE FOUND"
		SubscriptionID = $ArmConn.SubscriptionId;
		AzureSubscription = $SubscriptionInfo.displayName
		ShowinDesigner=0
	}
}
write-output  "Uploading  $($hash.fileInventory.count) file inventory"
    $UploadToOms=$hash.fileInventory
    $hash.fileInventory=@()
If($UploadToOms.count -gt $SplitSize)
{
    $spltlist=@()
    $spltlist = $spltlist + for ($Index = 0; $Index -lt $UploadToOms.count; $Index = $Index + $SplitSize)
	{
		,($UploadToOms[$index..($index+$SplitSize-1)])
	}
    $spltlist|foreach{
    $SplitLogs=$null
    $SplitLogs=$_
    $jsonlogs= ConvertTo-Json -InputObject $SplitLogs
		Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
	}
}Else{
    $jsonlogs= ConvertTo-Json -InputObject $UploadToOms
	Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
}
Remove-Variable -ErrorAction Stop uploadToOms -Force -Scope Global -ErrorAction SilentlyContinue
Remove-Variable -ErrorAction Stop jsonlogs -Force -Scope Global -ErrorAction SilentlyContinue
Remove-Variable -ErrorAction Stop spltlist -Force -Scope Global -ErrorAction SilentlyContinue
[System.gc]::Collect()
If(!$hash.vhdinventory)
{
    $hash.vhdinventory+= New-Object -ErrorAction Stop PSObject -Property @{
		Timestamp = $timestamp
		MetricName = 'Inventory'
		InventoryType='VHDFile'
		VHDName="NO RESOURCE FOUND"
		Uri= "NO RESOURCE FOUND"
		SubscriptionID = $ArmConn.SubscriptionId;
		AzureSubscription = $SubscriptionInfo.displayName
		ShowinDesigner=0
	}
}
write-output  "Uploading  $($hash.vhdinventory.count) vhd inventory"
    $UploadToOms=$hash.vhdinventory
    $hash.vhdinventory=@()
If($UploadToOms.count -gt $SplitSize)
{
    $spltlist=@()
    $spltlist = $spltlist + for ($Index = 0; $Index -lt $UploadToOms.count; $Index = $Index + $SplitSize)
	{
		,($UploadToOms[$index..($index+$SplitSize-1)])
	}
    $spltlist|foreach{
    $SplitLogs=$null
    $SplitLogs=$_
    $jsonlogs= ConvertTo-Json -InputObject $SplitLogs
		Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
	}
}Else{
    $jsonlogs= ConvertTo-Json -InputObject $UploadToOms
	Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
}
Remove-Variable -ErrorAction Stop uploadToOms -Force -Scope Global -ErrorAction SilentlyContinue
Remove-Variable -ErrorAction Stop jsonlogs -Force -Scope Global -ErrorAction SilentlyContinue
Remove-Variable -ErrorAction Stop spltlist -Force -Scope Global -ErrorAction SilentlyContinue
[System.gc]::Collect()
"Final Memory Consumption: $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
.Exception.Message
	}
    $prikey=$sa.key
    $storageaccount =$sa.StorageAccount
    $rg=$sa.rg
    $type=$sa.Type
    $tier=$sa.Tier
    $kind=$sa.Kind
    $colltime=Get-Date -ErrorAction Stop
	If($colltime.Minute -in 0..15)
	{
    $MetricColstartTime=$colltime.ToUniversalTime().AddHours(-1).ToString(" yyyyMMdd'T'HH46" )
    $MetricColendTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH00" )
	}
	Elseif($colltime.Minute -in 16..30)
	{
    $MetricColstartTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH00" )
    $MetricColendTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH15" )
	}
	Elseif($colltime.Minute -in 31..45)
	{
    $MetricColstartTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH16" )
    $MetricColendTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH30" )
	}
	Else
	{
    $MetricColstartTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH31" )
    $MetricColendTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH45" )
	}
    $hour=$MetricColEndTime.substring($MetricColEndTime.Length-4,4).Substring(0,2)
    $min=$MetricColEndTime.substring($MetricColEndTime.Length-4,4).Substring(2,2)
    $timestamp=(get-date).ToUniversalTime().ToString(" yyyy-MM-ddT$($hour):$($min):00.000Z" )
    $ColParamsforChild=@()
    $SaMetricsAvg=@()
    $storcapacity=@()
    $fltr1='?$filter='+"PartitionKey%20ge%20'$(MetricColstartTime) '%20and%20PartitionKey%20le%20'" +$MetricColendTime+" '%20and%20RowKey%20eq%20'user;All'"
    $slct1='&$select=PartitionKey,TotalRequests,TotalBillableRequests,TotalIngress,TotalEgress,AverageE2ELatency,AverageServerLatency,PercentSuccess,Availability,PercentThrottlingError,PercentNetworkError,PercentTimeoutError,SASAuthorizationError,PercentAuthorizationError,PercentClientOtherError,PercentServerOtherError'
    $sa=$null
    $vhdinventory=@()
    $AllContainers=@()
    $queueinventory=@()
    $queuearr=@()
    $QueueMetrics=@()
    $Fileinventory=@()
    $filearr=@()
    $InvFS=@()
    $fileshareinventory=@()
    $tableinventory=@()
    $tablearr=@{}
    $vmlist=@()
    $allvms=@()
    $allvhds=@()
    $tablelist= @('$MetricsMinutePrimaryTransactionsBlob','$MetricsMinutePrimaryTransactionsTable','$MetricsMinutePrimaryTransactionsQueue','$MetricsMinutePrimaryTransactionsFile')
	Foreach ($TableName in $tablelist)
	{
    $signature=$headersforsa=$null
		[uri]$tablequri=" https://$($storageaccount).table.core.windows.net/" +$TableName+'()'
    $resource = $storageaccount
    $logdate=[DateTime]::UtcNow
    $rfc1123date = $logdate.ToString(" r" )
    $params = @{
	    uri = $tablequri
	    date = $rfc1123date
	    service = "table"
	    resource = $storageaccount
	    sharedKey = $prikey
	    method = "GET"
	}
	; @params
    $headersforsa=  @{
			'Authorization'= " $signature"
			'x-ms-version'=" $apistorage"
			'x-ms-date'=" $rfc1123date"
			'Accept-Charset'='UTF-8'
			'MaxDataServiceVersion'='3.0;NetFx'
			'Accept'='application/json;odata=nometadata'
		}
    $response=$jresponse=$null
    $FullQuery=$tablequri.OriginalString+$fltr1+$slct1
    $method = "GET"
		Try
		{
    $response = Invoke-WebRequest -Uri $FullQuery -Method $method  -Headers $headersforsa  -UseBasicParsing  -ErrorAction SilentlyContinue
		}
		Catch
		{
    $ErrorMessage = $_.Exception.Message
    $StackTrace = $_.Exception.StackTrace
			Write-Warning "Error during accessing metrics table $tablename .Error: $ErrorMessage, stack: $StackTrace."
		}
    $Jresponse=convertFrom-Json    $response.Content
		IF($Jresponse.Value)
		{
    $entities=$null
    $entities=$Jresponse.value
    $stormetrics=@()
			foreach ($rowitem in $entities)
			{
    $cu=$null
    $dt=$rowitem.PartitionKey
    $timestamp=$dt.Substring(0,4)+'-'+$dt.Substring(4,2)+'-'+$dt.Substring(6,3)+$dt.Substring(9,2)+':'+$dt.Substring(11,2)+':00.000Z'
    $cu = New-Object -ErrorAction Stop PSObject -Property @{
					Timestamp = $timestamp
					MetricName = 'MetricsTransactions'
					TotalRequests=[long]$rowitem.TotalRequests
					TotalBillableRequests=[long]$rowitem.TotalBillableRequests
					TotalIngress=[long]$rowitem.TotalIngress
					TotalEgress=[long]$rowitem.TotalEgress
					Availability=[float]$rowitem.Availability
					AverageE2ELatency=[int]$rowitem.AverageE2ELatency
					AverageServerLatency=[int]$rowitem.AverageServerLatency
					PercentSuccess=[float]$rowitem.PercentSuccess
					PercentThrottlingError=[float]$rowitem.PercentThrottlingError
					PercentNetworkError=[float]$rowitem.PercentNetworkError
					PercentTimeoutError=[float]$rowitem.PercentTimeoutError
					SASAuthorizationError=[float]$rowitem.SASAuthorizationError
					PercentAuthorizationError=[float]$rowitem.PercentAuthorizationError
					PercentClientOtherError=[float]$rowitem.PercentClientOtherError
					PercentServerOtherError=[float]$rowitem.PercentServerOtherError
					ResourceGroup=$rg
					StorageAccount = $StorageAccount
					StorageService=$TableName.Substring(33,$TableName.Length-33)
					SubscriptionId = $ArmConn.SubscriptionID
					AzureSubscription = $SubscriptionInfo.displayName
				}
    $hash['saTransactionsMetrics']+=$cu
			}
		}
	}
    $TableName = '$MetricsCapacityBlob'
    $startdate=(get-date).AddDays(-1).ToUniversalTime().ToString(" yyyyMMdd'T'0000" )
    $table=$null
    $signature=$headersforsa=$null
	[uri]$tablequri=" https://$($storageaccount).table.core.windows.net/" +$TableName+'()'
    $resource = $storageaccount
    $logdate=[DateTime]::UtcNow
    $rfc1123date = $logdate.ToString(" r" )
    $params = @{
    uri = $tablequri
    date = $rfc1123date
    service = "table"
    resource = $storageaccount
    sharedKey = $prikey
    method = "GET"
}
; @params
    $headersforsa=  @{
		'Authorization'= " $signature"
		'x-ms-version'=" $apistorage"
		'x-ms-date'=" $rfc1123date"
		'Accept-Charset'='UTF-8'
		'MaxDataServiceVersion'='3.0;NetFx'
		'Accept'='application/json;odata=nometadata'
	}
    $response=$jresponse=$null
    $fltr2='?$filter='+"PartitionKey%20gt%20'$(startdate) '%20and%20RowKey%20eq%20'data'"
    $FullQuery=$tablequri.OriginalString+$fltr2
    $method = "GET"
	Try
	{
    $response = Invoke-WebRequest -Uri $FullQuery -Method $method  -Headers $headersforsa  -UseBasicParsing  -ErrorAction SilentlyContinue
	}
	Catch
	{
    $ErrorMessage = $_.Exception.Message
    $StackTrace = $_.Exception.StackTrace
		Write-Warning "Error during accessing metrics table $tablename .Error: $ErrorMessage, stack: $StackTrace."
	}
    $Jresponse=convertFrom-Json    $response.Content
	IF($Jresponse.Value)
	{
    $entities=$null
    $entities=@($jresponse.value)
    $cu=$null
    $cu = New-Object -ErrorAction Stop PSObject -Property @{
			Timestamp = $timestamp
			MetricName = 'MetricsCapacity'
			Capacity=$([long]$entities[0].Capacity)/1024/1024/1024
			ContainerCount=[long]$entities[0].ContainerCount
			ObjectCount=[long]$entities[0].ObjectCount
			ResourceGroup=$rg
			StorageAccount = $StorageAccount
			StorageService="Blob"
			SubscriptionId = $ArmConn.SubscriptionId
			AzureSubscription = $SubscriptionInfo.displayName
		}
    $hash['saCapacityMetrics']+=$cu
	}
	IF($tier -notmatch 'premium' -and $kind -ne 'BlobStorage')
	{
		[uri]$UriQueue=" https://{0}.queue.core.windows.net?comp=list" -f $storageaccount
		[xml]$Xresponse=invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriQueue
		IF (![String]::IsNullOrEmpty($Xresponse.EnumerationResults.Queues.Queue))
		{
			Foreach ($queue in $Xresponse.EnumerationResults.Queues.Queue)
			{
				write-verbose  "Queue found :$($sa.name) ; $($queue.name) "
    $queuearr = $queuearr + " {0};{1}" -f $queue.Name.tostring(),$sa.name
    $queueinventory = $queueinventory + New-Object -ErrorAction Stop PSObject -Property @{
					Timestamp = $timestamp
					MetricName = 'Inventory'
					InventoryType='Queue'
					StorageAccount=$sa.name
					Queue= $queue.Name
					Uri=$UriQueue.Scheme+'://'+$UriQueue.Host+'/'+$queue.Name
					SubscriptionID = $ArmConn.SubscriptionId;
					AzureSubscription = $SubscriptionInfo.displayName
					ShowinDesigner=1
				}
				[uri]$uriforq=" https://$storageaccount.queue.core.windows.net/$($queue.name)/messages?peekonly=true"
				[xml]$Xmlqresp= invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $uriforq
				[uri]$uriform=" https://$storageaccount.queue.core.windows.net/$($queue.name)?comp=metadata"
    $Xmlqrespm= invoke-StorageREST -sharedKey $prikey -method HEAD -resource $storageaccount -uri $uriform
    $cuq=$null
    $cuq = $cuq + New-Object -ErrorAction Stop PSObject -Property @{
					Timestamp=$timestamp
					MetricName = 'QueueMetrics';
					StorageAccount=$storageaccount
					StorageService="Queue"
					Queue= $queue.Name
					approximateMsgCount=$Xmlqrespm.Headers.'x-ms-approximate-messages-count'
					SubscriptionId = $ArmConn.SubscriptionId;
					AzureSubscription = $SubscriptionInfo.displayName
				}
    $msg=$Xmlqresp.QueueMessagesList.QueueMessage
				IF(![string]::IsNullOrEmpty($Xmlqresp.QueueMessagesList))
				{
    $cuq|Add-Member -MemberType NoteProperty -Name FirstMessageID -Value $msg.MessageId
    $cuq|Add-Member -MemberType NoteProperty -Name FirstMessageText -Value $msg.MessageText
    $cuq|Add-Member -MemberType NoteProperty -Name FirstMsgInsertionTime -Value $msg.InsertionTime
    $cuq|Add-Member -MemberType NoteProperty -Name Minutesinqueue -Value [Math]::Round(((Get-date).ToUniversalTime()-[datetime]($Xmlqresp.QueueMessagesList.QueueMessage.InsertionTime)).Totalminutes,0)
				}
    $hash['tableInventory']+=$cuq
			}
		}
	}
	IF($tier -notmatch 'premium' -and $kind -ne 'BlobStorage')
	{
		[uri]$UriFile=" https://{0}.file.core.windows.net?comp=list" -f $storageaccount
		[xml]$Xresponse=invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriFile
		if(![string]::IsNullOrEmpty($Xresponse.EnumerationResults.Shares.Share))
		{
			foreach($share in @($Xresponse.EnumerationResults.Shares.Share))
			{
				write-verbose  "File Share found :$($storageaccount) ; $($share.Name) "
    $filelist=@()
    $filearr = $filearr + " {0};{1}" -f $Share.Name,$storageaccount
    $cuf= New-Object -ErrorAction Stop PSObject -Property @{
					Timestamp = $timestamp
					MetricName = 'Inventory'
					InventoryType='File'
					StorageAccount=$storageaccount
					FileShare=$share.Name
					Uri=$UriFile.Scheme+'://'+$UriFile.Host+'/'+$Share.Name
					Quota=$share.Properties.Quota
					SubscriptionID = $ArmConn.SubscriptionId;
					AzureSubscription = $SubscriptionInfo.displayName
					ShowinDesigner=1
				}
				[uri]$UriforF=" https://{0}.file.core.windows.net/{1}?restype=share&comp=stats" -f $storageaccount,$share.Name
				[xml]$Xmlresp=invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriforF
				IF($Xmlresp)
				{
    $cuf|Add-Member -MemberType NoteProperty -Name  ShareUsedGB -Value $([int]$Xmlresp.ShareStats.ShareUsage)
				}
    $hash['fileInventory']+=$cuf
			}
		}
	}
	IF($tier -notmatch 'premium')
	{
		[uri]$uritable=" https://{0}.table.core.windows.net/Tables" -f $storageaccount
    $rfc1123date = [DateTime]::UtcNow.ToString(" r" )
    $params = @{
	    uri = $uritable
	    UseBasicParsing = "; 	$RespJson=convertFrom-Json    $tableresp.Content  IF (![string]::IsNullOrEmpty($RespJson.value.Tablename)) { foreach($tbl in @($RespJson.value.Tablename)) { write-verbose  "Table found :$storageaccount ; $($tbl) "  #$tablearr = $tablearr + " {0}"
	    date = $rfc1123date
	    service = "table ; 	$headersforsa=  @{ 'Authorization'= " $signature" 'x-ms-version'=" $apistorage" 'x-ms-date'=" $rfc1123date" 'Accept-Charset'='UTF-8' 'MaxDataServiceVersion'='3.0;NetFx' 'Accept'='application/json;odata=nometadata' } $tableresp=Invoke-WebRequest"
	    resource = $sa.name
	    sharedKey = $prikey
	    Property = "@{ Timestamp = $timestamp MetricName = 'Inventory' InventoryType='Table' StorageAccount=$storageaccount Table=$tbl Uri=$uritable.Scheme+'://'+$uritable.Host+'/'+$tbl SubscriptionID = $ArmConn.SubscriptionId; AzureSubscription = $SubscriptionInfo.displayName ShowinDesigner=1  } } } }"
	    ErrorAction = "Stop PSObject"
	    Headers = $headersforsa
	    f = $sa.name IF ([string]::IsNullOrEmpty($tablearr.Get_item($storageaccount))) { $tablearr.add($sa.name,'Storageaccount') }   $hash['queueInventory']+= New-Object
	    method = "GET"
	}
	; @params
	if ((get-date).hour -in (1,5,9,13,17,21) -and   (get-date).minute -in (1..16)   )
	{
		[uri]$UriListC= "https://{0}.blob.core.windows.net/?comp=list" -f $storageaccount
		Write-verbose " $(get-date) - Getting list of blobs for $($sa.name) "
		[xml]$lb=invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriListC
    $containers=@($lb.EnumerationResults.Containers.Container)
		IF(![string]::IsNullOrEmpty($lb.EnumerationResults.Containers.Container))
		{
			Foreach($container in @($containers))
			{
    $allcontainers = $allcontainers + $container
				[uri]$UriLBlobs = "https://{0}.blob.core.windows.net/{1}/?comp=list&include=metadata&maxresults=1000&restype=container" -f $storageaccount,$container.name
				[xml]$fresponse= invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $UriLBlobs
    $filesincontainer=@()
    $blobs=$fresponse.EnumerationResults.Blobs.blob
				Foreach($blob in $blobs)
				{
					IF($blob.name -match '.vhd')
					{
    $cu = New-Object -ErrorAction Stop PSObject -Property @{
							Timestamp = $timestamp
							MetricName = 'Inventory'
							InventoryType='VHDFile'
							Capacity=[Math]::Round($blob.Properties.'Content-Length'/1024/1024/1024,0)
							Container=$container.Name
							VHDName=$blob.name
							Uri= " {0}{1}/{2}" -f $fresponse.EnumerationResults.ServiceEndpoint,$Container.Name,$blob.Name
							LeaseState=$blob.Properties.LeaseState.ToString()
							StorageAccount= $storageaccount
							SubscriptionID = $ArmConn.SubscriptionId;
							AzureSubscription = $SubscriptionInfo.displayName
							ShowinDesigner=1
						}
    $hash['vhdinventory']+=$cu
					}
				}
    $filesincontainer|Group-Object Fileextension|select Name,count
    $fileshareinventory = $fileshareinventory + $filesincontainer
			}
		}
	}
}
    $Throttle = [System.Environment]::ProcessorCount+1
    $sessionstate = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
    $runspacepool = [runspacefactory]::CreateRunspacePool(1, $Throttle, $sessionstate, $Host)
    $runspacepool.Open()
[System.Collections.ArrayList]$Jobs = @()
Write-Output "After Runspace creation for metric collection : $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
$i=1
    $Starttimer=get-date -ErrorAction Stop
    $hash.SAInfo|foreach{
    $splitmetrics=$null
    $splitmetrics=$_
    $Job = [powershell]::Create().AddScript($ScriptBlockGetMetrics).AddArgument($hash).AddArgument($splitmetrics).Addargument($i)
    $Job.RunspacePool = $RunspacePool
    $Jobs = $Jobs + New-Object -ErrorAction Stop PSObject -Property @{
		RunNum = $i
		Pipe = $Job
		Result = $Job.BeginInvoke()
	}
    $i++
}
write-output  " $(get-date)  , started $i Runspaces "
Write-Output "After dispatching runspaces $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
    $JobsClone=$jobs.clone()
Write-Output "Waiting.."
$s=1
Do {
	Write-Output "  $(@($jobs.result.iscompleted|where{$_  -match 'False'}).count)  jobs remaining"
	foreach ($jobobj in $JobsClone)
	{
		if ($Jobobj.result.IsCompleted -eq $true)
		{
    $jobobj.Pipe.Endinvoke($jobobj.Result)
    $jobobj.pipe.dispose()
    $jobs.Remove($jobobj)
		}
	}
	IF($s%2 -eq 0)
	{
		Write-Output "Mem: $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
	}
    $s++
	Start-Sleep -Seconds 15
} While ( @($jobs.result.iscompleted|where{$_  -match 'False'}).count -gt 0)
Write-output "All jobs completed!"
    $jobs|foreach{$_.Pipe.Dispose()}
Remove-Variable -ErrorAction Stop Jobs -Force -Scope Global
Remove-Variable -ErrorAction Stop Job -Force -Scope Global
Remove-Variable -ErrorAction Stop Jobobj -Force -Scope Global
Remove-Variable -ErrorAction Stop Jobsclone -Force -Scope Global
    $runspacepool.Close()
$([System.gc]::gettotalmemory('forcefullcollection') /1MB)
    $Endtimer=get-date -ErrorAction Stop
Write-Output "All jobs completed in $(($Endtimer-$starttimer).TotalMinutes) minutes"
Write-Output "Uploading to OMS ..."
    $SplitSize=5000
If($hash.saTransactionsMetrics)
{
	write-output  "Uploading  $($hash.saTransactionsMetrics.count) transaction metrics"
    $UploadToOms=$hash.saTransactionsMetrics
    $hash.saTransactionsMetrics=@()
	If($UploadToOms.count -gt $SplitSize)
	{
    $spltlist=@()
    $spltlist = $spltlist + for ($Index = 0; $Index -lt $UploadToOms.count; $Index = $Index + $SplitSize)
		{
			,($UploadToOms[$index..($index+$SplitSize-1)])
		}
    $spltlist|foreach{
    $SplitLogs=$null
    $SplitLogs=$_
    $jsonlogs= ConvertTo-Json -InputObject $SplitLogs
			Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
		}
	}Else{
    $jsonlogs= ConvertTo-Json -InputObject $UploadToOms
		Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
	}
	Remove-Variable -ErrorAction Stop uploadToOms -Force -Scope Global -ErrorAction SilentlyContinue
	Remove-Variable -ErrorAction Stop jsonlogs -Force -Scope Global -ErrorAction SilentlyContinue
	Remove-Variable -ErrorAction Stop spltlist -Force -Scope Global -ErrorAction SilentlyContinue
	[System.gc]::Collect()
}
If($hash.saCapacityMetrics)
{
	write-output  "Uploading  $($hash.saCapacityMetrics.count) capacity metrics"
    $UploadToOms=$hash.saCapacityMetrics
    $hash.saCapacityMetrics=@()
	If($UploadToOms.count -gt $SplitSize)
	{
    $spltlist=@()
    $spltlist = $spltlist + for ($Index = 0; $Index -lt $UploadToOms.count; $Index = $Index + $SplitSize)
		{
			,($UploadToOms[$index..($index+$SplitSize-1)])
		}
    $spltlist|foreach{
    $SplitLogs=$null
    $SplitLogs=$_
    $jsonlogs= ConvertTo-Json -InputObject $SplitLogs
			Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
		}
	}Else{
    $jsonlogs= ConvertTo-Json -InputObject $UploadToOms
		Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
	}
	Remove-Variable -ErrorAction Stop uploadToOms -Force -Scope Global  -ErrorAction SilentlyContinue
	Remove-Variable -ErrorAction Stop jsonlogs -Force -Scope Global -ErrorAction SilentlyContinue
	Remove-Variable -ErrorAction Stop spltlist -Force -Scope Global -ErrorAction SilentlyContinue
	[System.gc]::Collect()
}
If($hash.tableInventory)
{
	write-output  "Uploading  $($hash.tableInventory.count) table inventory"
    $UploadToOms=$hash.tableInventory
    $hash.tableInventory=@()
	If($UploadToOms.count -gt $SplitSize)
	{
    $spltlist=@()
    $spltlist = $spltlist + for ($Index = 0; $Index -lt $UploadToOms.count; $Index = $Index + $SplitSize)
		{
			,($UploadToOms[$index..($index+$SplitSize-1)])
		}
    $spltlist|foreach{
    $SplitLogs=$null
    $SplitLogs=$_
    $jsonlogs= ConvertTo-Json -InputObject $SplitLogs
			Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
		}
	}Else{
    $jsonlogs= ConvertTo-Json -InputObject $UploadToOms
		Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
	}
	Remove-Variable -ErrorAction Stop uploadToOms -Force -Scope Global -ErrorAction SilentlyContinue
	Remove-Variable -ErrorAction Stop jsonlogs -Force -Scope Global -ErrorAction SilentlyContinue
	Remove-Variable -ErrorAction Stop spltlist -Force -Scope Global -ErrorAction SilentlyContinue
	[System.gc]::Collect()
}
If(!$hash.queueInventory)
{
    $hash.queueInventory+=New-Object -ErrorAction Stop PSObject -Property @{
		Timestamp = $timestamp
		MetricName = 'Inventory'
		InventoryType='Queue'
		Queue= "NO RESOURCE FOUND"
		Uri="NO RESOURCE FOUND"
		SubscriptionID = $ArmConn.SubscriptionId;
		AzureSubscription = $SubscriptionInfo.displayName
		ShowinDesigner=0
	}
}
write-output  "Uploading  $($hash.queueInventory.count) queue inventory"
    $UploadToOms=$hash.queueInventory
    $hash.queueInventory=@()
If($UploadToOms.count -gt $SplitSize)
{
    $spltlist=@()
    $spltlist = $spltlist + for ($Index = 0; $Index -lt $UploadToOms.count; $Index = $Index + $SplitSize)
	{
		,($UploadToOms[$index..($index+$SplitSize-1)])
	}
    $spltlist|foreach{
    $SplitLogs=$null
    $SplitLogs=$_
    $jsonlogs= ConvertTo-Json -InputObject $SplitLogs
		Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
	}
}Else{
    $jsonlogs= ConvertTo-Json -InputObject $UploadToOms
	Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
}
Remove-Variable -ErrorAction Stop uploadToOms -Force -Scope Global  -ErrorAction SilentlyContinue
Remove-Variable -ErrorAction Stop jsonlogs -Force -Scope Global  -ErrorAction SilentlyContinue
Remove-Variable -ErrorAction Stop spltlist -Force -Scope Global  -ErrorAction SilentlyContinue
[System.gc]::Collect()
If(!$hash.fileInventory)
{
    $hash.fileInventory+=New-Object -ErrorAction Stop PSObject -Property @{
		Timestamp = $timestamp
		MetricName = 'Inventory'
		InventoryType='File'
		FileShare="NO RESOURCE FOUND"
		Uri="NO RESOURCE FOUND"
		SubscriptionID = $ArmConn.SubscriptionId;
		AzureSubscription = $SubscriptionInfo.displayName
		ShowinDesigner=0
	}
}
write-output  "Uploading  $($hash.fileInventory.count) file inventory"
    $UploadToOms=$hash.fileInventory
    $hash.fileInventory=@()
If($UploadToOms.count -gt $SplitSize)
{
    $spltlist=@()
    $spltlist = $spltlist + for ($Index = 0; $Index -lt $UploadToOms.count; $Index = $Index + $SplitSize)
	{
		,($UploadToOms[$index..($index+$SplitSize-1)])
	}
    $spltlist|foreach{
    $SplitLogs=$null
    $SplitLogs=$_
    $jsonlogs= ConvertTo-Json -InputObject $SplitLogs
		Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
	}
}Else{
    $jsonlogs= ConvertTo-Json -InputObject $UploadToOms
	Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
}
Remove-Variable -ErrorAction Stop uploadToOms -Force -Scope Global -ErrorAction SilentlyContinue
Remove-Variable -ErrorAction Stop jsonlogs -Force -Scope Global -ErrorAction SilentlyContinue
Remove-Variable -ErrorAction Stop spltlist -Force -Scope Global -ErrorAction SilentlyContinue
[System.gc]::Collect()
If(!$hash.vhdinventory)
{
    $hash.vhdinventory+= New-Object -ErrorAction Stop PSObject -Property @{
		Timestamp = $timestamp
		MetricName = 'Inventory'
		InventoryType='VHDFile'
		VHDName="NO RESOURCE FOUND"
		Uri= "NO RESOURCE FOUND"
		SubscriptionID = $ArmConn.SubscriptionId;
		AzureSubscription = $SubscriptionInfo.displayName
		ShowinDesigner=0
	}
}
write-output  "Uploading  $($hash.vhdinventory.count) vhd inventory"
    $UploadToOms=$hash.vhdinventory
    $hash.vhdinventory=@()
If($UploadToOms.count -gt $SplitSize)
{
    $spltlist=@()
    $spltlist = $spltlist + for ($Index = 0; $Index -lt $UploadToOms.count; $Index = $Index + $SplitSize)
	{
		,($UploadToOms[$index..($index+$SplitSize-1)])
	}
    $spltlist|foreach{
    $SplitLogs=$null
    $SplitLogs=$_
    $jsonlogs= ConvertTo-Json -InputObject $SplitLogs
		Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
	}
}Else{
    $jsonlogs= ConvertTo-Json -InputObject $UploadToOms
	Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
}
Remove-Variable -ErrorAction Stop uploadToOms -Force -Scope Global -ErrorAction SilentlyContinue
Remove-Variable -ErrorAction Stop jsonlogs -Force -Scope Global -ErrorAction SilentlyContinue
Remove-Variable -ErrorAction Stop spltlist -Force -Scope Global -ErrorAction SilentlyContinue
[System.gc]::Collect()
"Final Memory Consumption: $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"



