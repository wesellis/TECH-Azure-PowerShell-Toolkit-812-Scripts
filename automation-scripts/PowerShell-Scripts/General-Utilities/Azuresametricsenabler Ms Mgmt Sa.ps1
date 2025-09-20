#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azuresametricsenabler Ms Mgmt Sa

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$Timestampfield = "Timestamp"
$customerID = Get-AutomationVariable -Name 'AzureSAIngestion-OPSINSIGHTS_WS_ID-MS-Mgmt-SA'
$sharedKey = Get-AutomationVariable -Name 'AzureSAIngestion-OPSINSIGHTS_WS_KEY-MS-Mgmt-SA'
$ApiVerSaAsm = '2016-04-01'
$ApiVerSaArm = '2016-01-01'
$ApiStorage='2016-05-31'
$AAAccount = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationAccount-MS-Mgmt-SA'
$AAResourceGroup = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationResourceGroup-MS-Mgmt-SA'
$varQueueList="AzureSAIngestion-List-Queues"
$varFilesList="AzureSAIngestion-List-Files";
$varTableList="AzureSAIngestion-List-Tables"
[OutputType([bool])]
 ($sharedKey, $date,  $method, $bodylength, $resource,$uri ,$service)
{
	Add-Type -AssemblyName System.Web
$str=  New-Object -TypeName "System.Text.StringBuilder" ;
	$builder=  [System.Text.StringBuilder]::new(" /" )
	$builder.Append($resource) |out-null
	$builder.Append($uri.AbsolutePath) | out-null
	$str.Append($builder.ToString()) | out-null
$values2=@{}
	IF($service -eq 'Table')
	{
$values= [System.Web.HttpUtility]::ParseQueryString($uri.query)
		#    NameValueCollection values = HttpUtility.ParseQueryString(address.Query);
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
		#    NameValueCollection values = HttpUtility.ParseQueryString(address.Query);
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
	#   ;  $stringToHash = $stringToHash + $str.ToString();
	#$str.ToString()
	############
	$xHeaders = " x-ms-date:$(date) `n" +" x-ms-version:$ApiStorage"
	if ($service -eq 'Table')
	{
		$stringToHash= $method + " `n" + " `n" + " `n$(date) `n" +$str.ToString()
	}
	Else
	{
		IF ($method -eq 'GET' -or $method -eq 'HEAD')
		{
			$stringToHash = $method + " `n" + " `n" + " `n" + " `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" +$str.ToString()
		}
		Else
		{
			$stringToHash = $method + " `n" + " `n" + " `n$(bodylength) `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" +$str.ToString()
		}
	}
	##############
	$bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
	$keyBytes = [Convert]::FromBase64String($sharedKey)
	$sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
	$sha256.Key = $keyBytes
	$calculatedHash = $sha256.ComputeHash($bytesToHash)
	$encodedHash = [Convert]::ToBase64String($calculatedHash)
	$authorization = 'SharedKey {0}:{1}' -f $resource,$encodedHash
	return $authorization
}
Function invoke-StorageREST($sharedKey, $method, $msgbody, $resource,$uri,$svc)
{
	$rfc1123date = [DateTime]::UtcNow.ToString(" r" )
	If ($method -eq 'PUT')
	$params = @{
	    uri = $uri
	    date = $rfc1123date
	    service = $svc }Else {
	    resource = $resource
	    sharedKey = $sharedKey
	    bodylength = $msgbody.length
	    method = $method
	}
	{$signature @params
	$params = @{
	    uri = $uri
	    date = $rfc1123date
	    service = $svc }
	    resource = $resource
	    sharedKey = $sharedKey
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
			#      'Accept'='application/atom+xml,application/json;odata=nometadata'
			'Accept'='application/json;odata=nometadata'
		}
	}
	Else
	{
		$headersforSA=  @{
			'x-ms-date'=" $rfc1123date"
			'Content-Type'='application\xml'
			'Authorization'= " $signature"
			'x-ms-version'=" $ApiStorage"
		}
	}
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
			$resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
			$xresp=$resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
			return $xresp
		}Elseif($method -eq 'HEAD')
		{
			$resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
			return $resp1
		}
	}
}
function New-OMSSignature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
{
	$xHeaders = " x-ms-date:" + $date
	$stringToHash = $method + " `n$(contentLength) `n" + $contentType + " `n$(xHeaders) `n" + $resource
	$bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
	$keyBytes = [Convert]::FromBase64String($sharedKey)
	$sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
	$sha256.Key = $keyBytes
	$calculatedHash = $sha256.ComputeHash($bytesToHash)
	$encodedHash = [Convert]::ToBase64String($calculatedHash)
	$authorization = 'SharedKey {0}:{1}' -f $customerId,$encodedHash
	return $authorization
}
Function Post-OMSData($customerId, $sharedKey, $body, $logType)
{
	$method = "POST"
	$contentType = " application/json"
	$resource = " /api/logs"
	$rfc1123date = [DateTime]::UtcNow.ToString(" r" )
	$contentLength = $body.Length
	$params = @{
	    date = $rfc1123date
	    contentLength = $contentLength
	    resource = $resource
	    sharedKey = $sharedKey
	    customerId = $customerId
	    contentType = $contentType
	    fileName = $fileName
	    method = $method
	}
	$signature @params
$uri = "https://$(customerId) .ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"
$OMSheaders = @{
		"Authorization" = $signature;
		"Log-Type" = $logType;
		" x-ms-date" = $rfc1123date;
		" time-generated-field" = $TimeStampField;
	}
	Try{
		$response = Invoke-WebRequest -Uri $uri -Method POST  -ContentType $contentType -Headers $OMSheaders -Body $body -UseBasicParsing
	}
	Catch
	{
		$_.MEssage
	}
	return $response.StatusCode
	write-output $response.StatusCode
	Write-error #Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azuresametricsenabler Ms Mgmt Sa

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$Timestampfield = "Timestamp"
$customerID = Get-AutomationVariable -Name 'AzureSAIngestion-OPSINSIGHTS_WS_ID-MS-Mgmt-SA'
$sharedKey = Get-AutomationVariable -Name 'AzureSAIngestion-OPSINSIGHTS_WS_KEY-MS-Mgmt-SA'
$ApiVerSaAsm = '2016-04-01'
$ApiVerSaArm = '2016-01-01'
$ApiStorage='2016-05-31'
$AAAccount = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationAccount-MS-Mgmt-SA'
$AAResourceGroup = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationResourceGroup-MS-Mgmt-SA'
$varQueueList="AzureSAIngestion-List-Queues"
$varFilesList="AzureSAIngestion-List-Files";
$varTableList="AzureSAIngestion-List-Tables"
[OutputType([bool])]
 ($sharedKey, $date,  $method, $bodylength, $resource,$uri ,$service)
{
	Add-Type -AssemblyName System.Web
$str=  New-Object -TypeName "System.Text.StringBuilder" ;
	$builder=  [System.Text.StringBuilder]::new(" /" )
	$builder.Append($resource) |out-null
	$builder.Append($uri.AbsolutePath) | out-null
	$str.Append($builder.ToString()) | out-null
$values2=@{}
	IF($service -eq 'Table')
	{
$values= [System.Web.HttpUtility]::ParseQueryString($uri.query)
		#    NameValueCollection values = HttpUtility.ParseQueryString(address.Query);
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
		#    NameValueCollection values = HttpUtility.ParseQueryString(address.Query);
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
	#   ;  $stringToHash = $stringToHash + $str.ToString();
	#$str.ToString()
	############
	$xHeaders = " x-ms-date:$(date) `n" +" x-ms-version:$ApiStorage"
	if ($service -eq 'Table')
	{
		$stringToHash= $method + " `n" + " `n" + " `n$(date) `n" +$str.ToString()
	}
	Else
	{
		IF ($method -eq 'GET' -or $method -eq 'HEAD')
		{
			$stringToHash = $method + " `n" + " `n" + " `n" + " `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" +$str.ToString()
		}
		Else
		{
			$stringToHash = $method + " `n" + " `n" + " `n$(bodylength) `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n$(xHeaders) `n" +$str.ToString()
		}
	}
	##############
	$bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
	$keyBytes = [Convert]::FromBase64String($sharedKey)
	$sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
	$sha256.Key = $keyBytes
	$calculatedHash = $sha256.ComputeHash($bytesToHash)
	$encodedHash = [Convert]::ToBase64String($calculatedHash)
	$authorization = 'SharedKey {0}:{1}' -f $resource,$encodedHash
	return $authorization
}
Function invoke-StorageREST($sharedKey, $method, $msgbody, $resource,$uri,$svc)
{
	$rfc1123date = [DateTime]::UtcNow.ToString(" r" )
	If ($method -eq 'PUT')
	$params = @{
	    uri = $uri
	    date = $rfc1123date
	    service = $svc }Else {
	    resource = $resource
	    sharedKey = $sharedKey
	    bodylength = $msgbody.length
	    method = $method
	}
	{$signature @params
	$params = @{
	    uri = $uri
	    date = $rfc1123date
	    service = $svc }
	    resource = $resource
	    sharedKey = $sharedKey
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
			#      'Accept'='application/atom+xml,application/json;odata=nometadata'
			'Accept'='application/json;odata=nometadata'
		}
	}
	Else
	{
		$headersforSA=  @{
			'x-ms-date'=" $rfc1123date"
			'Content-Type'='application\xml'
			'Authorization'= " $signature"
			'x-ms-version'=" $ApiStorage"
		}
	}
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
			$resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
			$xresp=$resp1.Content.Substring($resp1.Content.IndexOf(" <" ))
			return $xresp
		}Elseif($method -eq 'HEAD')
		{
			$resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody
			return $resp1
		}
	}
}
function New-OMSSignature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
{
	$xHeaders = " x-ms-date:" + $date
	$stringToHash = $method + " `n$(contentLength) `n" + $contentType + " `n$(xHeaders) `n" + $resource
	$bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
	$keyBytes = [Convert]::FromBase64String($sharedKey)
	$sha256 = New-Object -ErrorAction Stop System.Security.Cryptography.HMACSHA256
	$sha256.Key = $keyBytes
	$calculatedHash = $sha256.ComputeHash($bytesToHash)
	$encodedHash = [Convert]::ToBase64String($calculatedHash)
	$authorization = 'SharedKey {0}:{1}' -f $customerId,$encodedHash
	return $authorization
}
Function Post-OMSData($customerId, $sharedKey, $body, $logType)
{
	$method = "POST"
	$contentType = " application/json"
	$resource = " /api/logs"
	$rfc1123date = [DateTime]::UtcNow.ToString(" r" )
	$contentLength = $body.Length
	$params = @{
	    date = $rfc1123date
	    contentLength = $contentLength
	    resource = $resource
	    sharedKey = $sharedKey
	    customerId = $customerId
	    contentType = $contentType
	    fileName = $fileName
	    method = $method
	}
	$signature @params
$uri = "https://$(customerId) .ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"
$OMSheaders = @{
		"Authorization" = $signature;
		"Log-Type" = $logType;
		" x-ms-date" = $rfc1123date;
		" time-generated-field" = $TimeStampField;
	}
	Try{
		$response = Invoke-WebRequest -Uri $uri -Method POST  -ContentType $contentType -Headers $OMSheaders -Body $body -UseBasicParsing
	}
	Catch
	{
		$_.MEssage
	}
	return $response.StatusCode
	write-output $response.StatusCode
	Write-error $error[0]
}
"Logging in to Azure..."
$ArmConn = Get-AutomationConnection -Name AzureRunAsConnection
if ($null -eq $ArmConn)
{
	throw "Could not retrieve connection asset AzureRunAsConnection,  Ensure that runas account  exists in the Automation account."
}
$retry = 6
$syncOk = $false
do
{
	try
	{
		Add-AzureRMAccount -ServicePrincipal -Tenant $ArmConn.TenantID -ApplicationId $ArmConn.ApplicationID -CertificateThumbprint $ArmConn.CertificateThumbprint
		$syncOk = $true
	}
	catch
	{
		$ErrorMessage = $_.Exception.Message
		$StackTrace = $_.Exception.StackTrace
		Write-Warning "Error during sync: $ErrorMessage, stack: $StackTrace. Retry attempts left: $retry"
		$retry = $retry - 1
		Start-Sleep -s 60
	}
} while (-not $syncOk -and $retry -ge 0)
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
$subscriptionInfoUri = "https://management.azure.com/subscriptions/$(subscriptionid)?api-version=2016-02-01"
$subscriptionInfo = Invoke-RestMethod -Uri $subscriptionInfoUri -Headers $headers -Method Get -UseBasicParsing
IF($subscriptionInfo)
{
	"Successfully connected to Azure ARM REST"
}
if ($getAsmHeader) {
	try
    {
        $AsmConn = Get-AutomationConnection -Name AzureClassicRunAsConnection -ea 0
    }
    Catch
    {
        if ($null -eq $AsmConn) {
            Write-Warning "Could not retrieve connection asset AzureClassicRunAsConnection. Ensure that runas account exist and valid in the Automation account."
            $getAsmHeader=$false
        }
    }
     if ($null -eq $AsmConn) {
        Write-Warning "Could not retrieve connection asset AzureClassicRunAsConnection. Ensure that runas account exist and valid in the Automation account. Quota usage infomration for classic accounts will no tbe collected"
        $getAsmHeader=$false
    }Else{
        $CertificateAssetName = $AsmConn.CertificateAssetName
        $AzureCert = Get-AutomationCertificate -Name $CertificateAssetName
        if ($null -eq $AzureCert)
        {
            Write-Warning  "Could not retrieve certificate asset: $CertificateAssetName. Ensure that this asset exists and valid  in the Automation account."
            $getAsmHeader=$false
        }
        Else{
        "Logging into Azure Service Manager"
        Write-Verbose "Authenticating to Azure with certificate." -Verbose
        Set-AzureSubscription -SubscriptionName $AsmConn.SubscriptionName -SubscriptionId $AsmConn.SubscriptionId -Certificate $AzureCert
        Select-AzureSubscription -SubscriptionId $AsmConn.SubscriptionId
        #finally create the headers for ASM REST
        $headerasm = @{" x-ms-version" =" 2013-08-01" }
        }
    }
}
$logname  = "AzureStorage"
$timestamp=(get-date).ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:00.000Z" )
$services=@('Blob','Table','Queue','File')
$sacount=0
$satracking=0
$salist=@()
" $(GEt-date)  Get ARM storage Accounts "
$Uri=" https://management.azure.com/subscriptions/{1}/providers/Microsoft.Storage/storageAccounts?api-version={0}"   -f  $ApiVerSaArm,$SubscriptionId
$armresp=Invoke-WebRequest -Uri $uri -Method GET  -Headers $headers -UseBasicParsing
$salist = $salist + (ConvertFrom-Json -InputObject $armresp.Content).Value
" $(GEt-date)  Get Classic storage Accounts "
$Uri=" https://management.azure.com/subscriptions/{1}/providers/Microsoft.ClassicStorage/storageAccounts?api-version={0}"   -f  $ApiVerSaAsm,$SubscriptionId
$sresp=Invoke-WebRequest -Uri $uri -Method GET  -Headers $headers -UseBasicParsing
$salist = $salist + (ConvertFrom-Json -InputObject $sresp.Content).value
" $(GEt-date)  $($saList.count) storage accounts found"
Foreach($sa in $salist)
{
	$prikey=$storageaccount=$rg=$type=$null
	$storageaccount =$sa.name
	$rg=$sa.id.Split('/')[4]
	If($sa.type -match 'ClassicStorage')
	{$type='Classic'}Else{$type='ARM'}
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
	$sa|Add-Member -MemberType NoteProperty -Name Key -Value $prikey
}
$vhdinventory=@()
$allContainers=@()
Foreach($sa in $salist)
{
	[uri]$uriListC= "https://{0}.blob.core.windows.net/?comp=list" -f $sa.name
	Write-verbose " $(get-date) - Getting list of blobs for $($sa.name) "
	[xml]$lb=invoke-StorageREST -sharedKey $sa.key -method GET -resource $sa.name -uri $uriListC
	$containers=@($lb.EnumerationResults.Containers.Container)
	IF(![string]::IsNullOrEmpty($lb.EnumerationResults.Containers.Container))
	{
		Foreach($container in @($containers))
		{
			$allcontainers = $allcontainers + $container
			[uri]$uriLBlobs = "https://{0}.blob.core.windows.net/{1}/?comp=list&include=metadata&maxresults=1000&restype=container" -f $sa.name,$container.name
			[xml]$fresponse= invoke-StorageREST -sharedKey $sa.key -method GET -resource $sa.name -uri $uriLBlobs
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
						StorageAccount= $sa.name
						SubscriptionID = $ArmConn.SubscriptionId;
						AzureSubscription = $subscriptionInfo.displayName
					}
					$vhdinventory = $vhdinventory + $cu
				}
			}
		}
	}
}
$jsonvhdpool = ConvertTo-Json -InputObject $vhdinventory
If($jsonvhdpool){$OMSRES=Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonvhdpool)) -logType $logname}
if($OMSRES -ge 200 -and $omsres -lt 300)
{
	Write-Output " $($vhdinventory.count) VHD inventory uploaded to OMS"
}
Else
{
	Write-Warning "Failed to upload VHD inventory to OMS"
}
$settingon='<?xml version=" 1.0" encoding=" utf-8" ?><StorageServiceProperties><MinuteMetrics><Version>1.0</Version><Enabled>true</Enabled><RetentionPolicy><Enabled>true</Enabled><Days>1</Days></RetentionPolicy><IncludeAPIs>true</IncludeAPIs></MinuteMetrics></StorageServiceProperties>'
$settingoff='<?xml version=" 1.0" encoding=" utf-8" ?><StorageServiceProperties><MinuteMetrics><Version>1.0</Version><Enabled>false</Enabled><RetentionPolicy><Enabled>true</Enabled><Days>1</Days></RetentionPolicy></MinuteMetrics></StorageServiceProperties>'
Foreach($sa in $salist|Where{$_.properties.accountType -notmatch 'premium' -and $_.sku.tier -ne 'Premium'})
{
	Foreach ($svc in $services)
	{
		[uri]$uriprop=" https://{0}.{1}.core.windows.net/?restype=service&comp=properties" -f $sa.name,$svc
		[xml]$Xresponse=invoke-StorageREST -sharedKey $sa.Key -method GET -resource $sa.name -uri $uriprop  -svc $svc
		IF ($Xresponse.StorageServiceProperties.MinuteMetrics.Enabled -ne 'true')
		{
			write-output "Metrics not enabled for $($sa.Name) / $svc service"
$response=invoke-StorageREST -sharedKey $sa.Key -method PUT -resource $sa.name -uri $uriprop  -msgbody ([System.Text.Encoding]::UTF8.GetBytes($settingon)) -svc $svc
			If ($response.StatusCode -in 200..299)
			{
				write-output "Minute metrics are  enabled for $($sa.Name) / $svc service"
			}
		}
	}
}\n.Exception.Message
}
"Logging in to Azure..."
$ArmConn = Get-AutomationConnection -Name AzureRunAsConnection
if ($null -eq $ArmConn)
{
	throw "Could not retrieve connection asset AzureRunAsConnection,  Ensure that runas account  exists in the Automation account."
}
$retry = 6
$syncOk = $false
do
{
	try
	{
		Add-AzureRMAccount -ServicePrincipal -Tenant $ArmConn.TenantID -ApplicationId $ArmConn.ApplicationID -CertificateThumbprint $ArmConn.CertificateThumbprint
		$syncOk = $true
	}
	catch
	{
		$ErrorMessage = $_.Exception.Message
		$StackTrace = $_.Exception.StackTrace
		Write-Warning "Error during sync: $ErrorMessage, stack: $StackTrace. Retry attempts left: $retry"
		$retry = $retry - 1
		Start-Sleep -s 60
	}
} while (-not $syncOk -and $retry -ge 0)
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
$subscriptionInfoUri = "https://management.azure.com/subscriptions/$(subscriptionid)?api-version=2016-02-01"
$subscriptionInfo = Invoke-RestMethod -Uri $subscriptionInfoUri -Headers $headers -Method Get -UseBasicParsing
IF($subscriptionInfo)
{
	"Successfully connected to Azure ARM REST"
}
if ($getAsmHeader) {
	try
    {
        $AsmConn = Get-AutomationConnection -Name AzureClassicRunAsConnection -ea 0
    }
    Catch
    {
        if ($null -eq $AsmConn) {
            Write-Warning "Could not retrieve connection asset AzureClassicRunAsConnection. Ensure that runas account exist and valid in the Automation account."
            $getAsmHeader=$false
        }
    }
     if ($null -eq $AsmConn) {
        Write-Warning "Could not retrieve connection asset AzureClassicRunAsConnection. Ensure that runas account exist and valid in the Automation account. Quota usage infomration for classic accounts will no tbe collected"
        $getAsmHeader=$false
    }Else{
        $CertificateAssetName = $AsmConn.CertificateAssetName
        $AzureCert = Get-AutomationCertificate -Name $CertificateAssetName
        if ($null -eq $AzureCert)
        {
            Write-Warning  "Could not retrieve certificate asset: $CertificateAssetName. Ensure that this asset exists and valid  in the Automation account."
            $getAsmHeader=$false
        }
        Else{
        "Logging into Azure Service Manager"
        Write-Verbose "Authenticating to Azure with certificate." -Verbose
        Set-AzureSubscription -SubscriptionName $AsmConn.SubscriptionName -SubscriptionId $AsmConn.SubscriptionId -Certificate $AzureCert
        Select-AzureSubscription -SubscriptionId $AsmConn.SubscriptionId
        #finally create the headers for ASM REST
        $headerasm = @{" x-ms-version" =" 2013-08-01" }
        }
    }
}
$logname  = "AzureStorage"
$timestamp=(get-date).ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:00.000Z" )
$services=@('Blob','Table','Queue','File')
$sacount=0
$satracking=0
$salist=@()
" $(GEt-date)  Get ARM storage Accounts "
$Uri=" https://management.azure.com/subscriptions/{1}/providers/Microsoft.Storage/storageAccounts?api-version={0}"   -f  $ApiVerSaArm,$SubscriptionId
$armresp=Invoke-WebRequest -Uri $uri -Method GET  -Headers $headers -UseBasicParsing
$salist = $salist + (ConvertFrom-Json -InputObject $armresp.Content).Value
" $(GEt-date)  Get Classic storage Accounts "
$Uri=" https://management.azure.com/subscriptions/{1}/providers/Microsoft.ClassicStorage/storageAccounts?api-version={0}"   -f  $ApiVerSaAsm,$SubscriptionId
$sresp=Invoke-WebRequest -Uri $uri -Method GET  -Headers $headers -UseBasicParsing
$salist = $salist + (ConvertFrom-Json -InputObject $sresp.Content).value
" $(GEt-date)  $($saList.count) storage accounts found"
Foreach($sa in $salist)
{
	$prikey=$storageaccount=$rg=$type=$null
	$storageaccount =$sa.name
	$rg=$sa.id.Split('/')[4]
	If($sa.type -match 'ClassicStorage')
	{$type='Classic'}Else{$type='ARM'}
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
	$sa|Add-Member -MemberType NoteProperty -Name Key -Value $prikey
}
$vhdinventory=@()
$allContainers=@()
Foreach($sa in $salist)
{
	[uri]$uriListC= "https://{0}.blob.core.windows.net/?comp=list" -f $sa.name
	Write-verbose " $(get-date) - Getting list of blobs for $($sa.name) "
	[xml]$lb=invoke-StorageREST -sharedKey $sa.key -method GET -resource $sa.name -uri $uriListC
	$containers=@($lb.EnumerationResults.Containers.Container)
	IF(![string]::IsNullOrEmpty($lb.EnumerationResults.Containers.Container))
	{
		Foreach($container in @($containers))
		{
			$allcontainers = $allcontainers + $container
			[uri]$uriLBlobs = "https://{0}.blob.core.windows.net/{1}/?comp=list&include=metadata&maxresults=1000&restype=container" -f $sa.name,$container.name
			[xml]$fresponse= invoke-StorageREST -sharedKey $sa.key -method GET -resource $sa.name -uri $uriLBlobs
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
						StorageAccount= $sa.name
						SubscriptionID = $ArmConn.SubscriptionId;
						AzureSubscription = $subscriptionInfo.displayName
					}
					$vhdinventory = $vhdinventory + $cu
				}
			}
		}
	}
}
$jsonvhdpool = ConvertTo-Json -InputObject $vhdinventory
If($jsonvhdpool){$OMSRES=Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonvhdpool)) -logType $logname}
if($OMSRES -ge 200 -and $omsres -lt 300)
{
	Write-Output " $($vhdinventory.count) VHD inventory uploaded to OMS"
}
Else
{
	Write-Warning "Failed to upload VHD inventory to OMS"
}
$settingon='<?xml version=" 1.0" encoding=" utf-8" ?><StorageServiceProperties><MinuteMetrics><Version>1.0</Version><Enabled>true</Enabled><RetentionPolicy><Enabled>true</Enabled><Days>1</Days></RetentionPolicy><IncludeAPIs>true</IncludeAPIs></MinuteMetrics></StorageServiceProperties>'
$settingoff='<?xml version=" 1.0" encoding=" utf-8" ?><StorageServiceProperties><MinuteMetrics><Version>1.0</Version><Enabled>false</Enabled><RetentionPolicy><Enabled>true</Enabled><Days>1</Days></RetentionPolicy></MinuteMetrics></StorageServiceProperties>'
Foreach($sa in $salist|Where{$_.properties.accountType -notmatch 'premium' -and $_.sku.tier -ne 'Premium'})
{
	Foreach ($svc in $services)
	{
		[uri]$uriprop=" https://{0}.{1}.core.windows.net/?restype=service&comp=properties" -f $sa.name,$svc
		[xml]$Xresponse=invoke-StorageREST -sharedKey $sa.Key -method GET -resource $sa.name -uri $uriprop  -svc $svc
		IF ($Xresponse.StorageServiceProperties.MinuteMetrics.Enabled -ne 'true')
		{
			write-output "Metrics not enabled for $($sa.Name) / $svc service"
$response=invoke-StorageREST -sharedKey $sa.Key -method PUT -resource $sa.name -uri $uriprop  -msgbody ([System.Text.Encoding]::UTF8.GetBytes($settingon)) -svc $svc
			If ($response.StatusCode -in 200..299)
			{
				write-output "Minute metrics are  enabled for $($sa.Name) / $svc service"
			}
		}
	}
}\n

