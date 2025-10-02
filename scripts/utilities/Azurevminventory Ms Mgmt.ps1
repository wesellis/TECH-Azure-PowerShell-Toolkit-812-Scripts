#Requires -Version 7.4

<#`n.SYNOPSIS
    Azurevminventory Ms Mgmt

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [Parameter()] [int] $apireadlimit=7500,
    [Parameter()] [bool] $getarmvmstatus=$true,
    [Parameter()] [bool] $GetNICandNSG=$true,
    [Parameter()] [bool] $GetDiskInfo=$true
    )
    $StartTime = [dateTime]::Now
    $Timestampfield = "Timestamp"
    $CustomerID = Get-AutomationVariable -Name  "AzureVMInventory-OPSINSIGHTS_WS_ID"
    $SharedKey = Get-AutomationVariable -Name  "AzureVMInventory-OPSINSIGHT_WS_KEY"
    $ApiVerSaAsm = '2016-04-01'
    $ApiVerSaArm = '2016-01-01'
    $ApiStorage='2016-05-31'
    $ApiverVM='2016-02-01'
    $logname='AzureVMInventory'
    $VMstates = @{
"StoppedDeallocated" ="Deallocated" ;
"ReadyRole" ="Running" ;
"PowerState/deallocated" ="Deallocated" ;
"PowerState/stopped" ="Stopped" ;
"StoppedVM" ="Stopped" ;
"PowerState/running" ="Running" }
    $vmiolimits = Get-AutomationVariable -Name 'VMinfo_-IOPSLimits'  -ea 0
IF(!$vmiolimits)
{;
    $vmiolimits=@{"Basic_A0" =300;
"Basic_A1" =300;
"Basic_A2" =300;
"Basic_A3" =300;
"Basic_A4" =300;
"ExtraSmall" =500;
"Small" =500;
"Medium" =500;
"Large" =500;
"ExtraLarge" =500;
"Standard_A0" =500;
"Standard_A1" =500;
"Standard_A2" =500;
"Standard_A3" =500;
"Standard_A4" =500;
"Standard_A5" =500;
"Standard_A6" =500;
"Standard_A7" =500;
"Standard_A8" =500;
"Standard_A9" =500;
"Standard_A10" =500;
"Standard_A11" =500;
"Standard_A1_v2" =500;
"Standard_A2_v2" =500;
"Standard_A4_v2" =500;
"Standard_A8_v2" =500;
"Standard_A2m_v2" =500;
"Standard_A4m_v2" =500;
"Standard_A8m_v2" =500;
"Standard_D1" =500;
"Standard_D2" =500;
"Standard_D3" =500;
"Standard_D4" =500;
"Standard_D11" =500;
"Standard_D12" =500;
"Standard_D13" =500;
"Standard_D14" =500;
"Standard_D1_v2" =500;
"Standard_D2_v2" =500;
"Standard_D3_v2" =500;
"Standard_D4_v2" =500;
"Standard_D5_v2" =500;
"Standard_D11_v2" =500;
"Standard_D12_v2" =500;
"Standard_D13_v2" =500;
"Standard_D14_v2" =500;
"Standard_D15_v2" =500;
"Standard_DS1" =3200;
"Standard_DS2" =6400;
"Standard_DS3" =12800;
"Standard_DS4" =25600;
"Standard_DS11" =6400;
"Standard_DS12" =12800;
"Standard_DS13" =25600;
"Standard_DS14" =51200;
"Standard_DS1_v2" =3200;
"Standard_DS2_v2" =6400;
"Standard_DS3_v2" =12800;
"Standard_DS4_v2" =25600;
"Standard_DS5_v2" =51200;
"Standard_DS11_v2" =6400;
"Standard_DS12_v2" =12800;
"Standard_DS13_v2" =25600;
"Standard_DS14_v2" =51200;
"Standard_DS15_v2" =64000;
"Standard_F1" =500;
"Standard_F2" =500;
"Standard_F4" =500;
"Standard_F8" =500;
"Standard_F16" =500;
"Standard_F1s" =3200;
"Standard_F2s" =6400;
"Standard_F4s" =12800;
"Standard_F8s" =25600;
"Standard_F16s" =51200;
"Standard_G1" =500;
"Standard_G2" =500;
"Standard_G3" =500;
"Standard_G4" =500;
"Standard_G5" =500;
"Standard_GS1" =5000;
"Standard_GS2" =10000;
"Standard_GS3" =20000;
"Standard_GS4" =40000;
"Standard_GS5" =80000;
"Standard_H8" =500;
"Standard_H16" =500;
"Standard_H8m" =500;
"Standard_H16m" =500;
"Standard_H16r" =500;
"Standard_H16mr" =500;
"Standard_NV6" =500;
"Standard_NV12" =500;
"Standard_NV24" =500;
"Standard_NC6" =500;
"Standard_NC12" =500;
"Standard_NC24" =500;
"Standard_NC24r" =500}
}
"Logging in to Azure..."
    $ArmConn = Get-AutomationConnection -Name AzureRunAsConnection
    $AsmConn = Get-AutomationConnection -Name AzureClassicRunAsConnection
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
    $retry = 6
    $SyncOk = $false
do
{
	try
	{
    $certs= Get-ChildItem -Path Cert:\Currentuser\my -Recurse | Where{$_.Thumbprint -eq $ArmConn.CertificateThumbprint}
		[System.Security.Cryptography.X509Certificates.X509Certificate2]$mycert=$certs[0]
    $SyncOk = $true
	}
	catch
	{
    $ErrorMessage = $_.Exception.Message
    $StackTrace = $_.Exception.StackTrace
		Write-Warning "Error during certificate retrieval : $ErrorMessage, stack: $StackTrace. Retry attempts left: $retry"
    $retry = $retry - 1
		Start-Sleep -s 60
	}
} while (-not $SyncOk -and $retry -ge 0)
IF ($mycert)
{
    $CliCert=new-object -ErrorAction Stop  Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate($ArmConn.ApplicationId,$mycert)
    $AuthContext = new-object -ErrorAction Stop Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext(" https://login.windows.net/$($ArmConn.tenantid)" )
    $result = $AuthContext.AcquireToken(" https://management.core.windows.net/" ,$CliCert)
    $header = "Bearer " + $result.AccessToken
    $headers = @{"Authorization" =$header;"Accept" =" application/json" }
    $body=$null
    $HTTPVerb="GET"
    $SubscriptionInfoUri = "https://management.azure.com/subscriptions/" +$ArmConn.SubscriptionId+"?api-version=$ApiverVM"
    $SubscriptionInfo = Invoke-RestMethod -Uri $SubscriptionInfoUri -Headers $headers -Method Get -UseBasicParsing
	IF($SubscriptionInfo)
	{
		"Successfully connected to Azure ARM REST;"
    $SubscriptionInfo
	}
    Else
    {
        Write-warning "Unable to login to Azure ARM Rest , runbook will not continue"
        Exit
    }
}
Else
{
	Write-error "Failed to login ro Azure ARM REST  , make sure Runas account configured correctly"
	Exit
}
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
Function invoke-StorageREST($SharedKey, $method, $msgbody, $resource,$uri,$svc)
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
	Try
    {
    $response = Invoke-WebRequest -Uri $uri -Method POST  -ContentType $ContentType -Headers $OMSheaders -Body $body -UseBasicParsing
	}
	Catch
	{
    $_.MEssage
	}
	return $response.StatusCode
	write-output $response.StatusCode
	Write-error <
    Azurevminventory Ms Mgmt

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [Parameter()] [int] $apireadlimit=7500,
    [Parameter()] [bool] $getarmvmstatus=$true,
    [Parameter()] [bool] $GetNICandNSG=$true,
    [Parameter()] [bool] $GetDiskInfo=$true
    )
    $StartTime = [dateTime]::Now
    $Timestampfield = "Timestamp"
    $CustomerID = Get-AutomationVariable -Name  "AzureVMInventory-OPSINSIGHTS_WS_ID"
    $SharedKey = Get-AutomationVariable -Name  "AzureVMInventory-OPSINSIGHT_WS_KEY"
    $ApiVerSaAsm = '2016-04-01'
    $ApiVerSaArm = '2016-01-01'
    $ApiStorage='2016-05-31'
    $ApiverVM='2016-02-01'
    $logname='AzureVMInventory'
    $VMstates = @{
"StoppedDeallocated" ="Deallocated" ;
"ReadyRole" ="Running" ;
"PowerState/deallocated" ="Deallocated" ;
"PowerState/stopped" ="Stopped" ;
"StoppedVM" ="Stopped" ;
"PowerState/running" ="Running" }
    $vmiolimits = Get-AutomationVariable -Name 'VMinfo_-IOPSLimits'  -ea 0
IF(!$vmiolimits)
{;
    $vmiolimits=@{"Basic_A0" =300;
"Basic_A1" =300;
"Basic_A2" =300;
"Basic_A3" =300;
"Basic_A4" =300;
"ExtraSmall" =500;
"Small" =500;
"Medium" =500;
"Large" =500;
"ExtraLarge" =500;
"Standard_A0" =500;
"Standard_A1" =500;
"Standard_A2" =500;
"Standard_A3" =500;
"Standard_A4" =500;
"Standard_A5" =500;
"Standard_A6" =500;
"Standard_A7" =500;
"Standard_A8" =500;
"Standard_A9" =500;
"Standard_A10" =500;
"Standard_A11" =500;
"Standard_A1_v2" =500;
"Standard_A2_v2" =500;
"Standard_A4_v2" =500;
"Standard_A8_v2" =500;
"Standard_A2m_v2" =500;
"Standard_A4m_v2" =500;
"Standard_A8m_v2" =500;
"Standard_D1" =500;
"Standard_D2" =500;
"Standard_D3" =500;
"Standard_D4" =500;
"Standard_D11" =500;
"Standard_D12" =500;
"Standard_D13" =500;
"Standard_D14" =500;
"Standard_D1_v2" =500;
"Standard_D2_v2" =500;
"Standard_D3_v2" =500;
"Standard_D4_v2" =500;
"Standard_D5_v2" =500;
"Standard_D11_v2" =500;
"Standard_D12_v2" =500;
"Standard_D13_v2" =500;
"Standard_D14_v2" =500;
"Standard_D15_v2" =500;
"Standard_DS1" =3200;
"Standard_DS2" =6400;
"Standard_DS3" =12800;
"Standard_DS4" =25600;
"Standard_DS11" =6400;
"Standard_DS12" =12800;
"Standard_DS13" =25600;
"Standard_DS14" =51200;
"Standard_DS1_v2" =3200;
"Standard_DS2_v2" =6400;
"Standard_DS3_v2" =12800;
"Standard_DS4_v2" =25600;
"Standard_DS5_v2" =51200;
"Standard_DS11_v2" =6400;
"Standard_DS12_v2" =12800;
"Standard_DS13_v2" =25600;
"Standard_DS14_v2" =51200;
"Standard_DS15_v2" =64000;
"Standard_F1" =500;
"Standard_F2" =500;
"Standard_F4" =500;
"Standard_F8" =500;
"Standard_F16" =500;
"Standard_F1s" =3200;
"Standard_F2s" =6400;
"Standard_F4s" =12800;
"Standard_F8s" =25600;
"Standard_F16s" =51200;
"Standard_G1" =500;
"Standard_G2" =500;
"Standard_G3" =500;
"Standard_G4" =500;
"Standard_G5" =500;
"Standard_GS1" =5000;
"Standard_GS2" =10000;
"Standard_GS3" =20000;
"Standard_GS4" =40000;
"Standard_GS5" =80000;
"Standard_H8" =500;
"Standard_H16" =500;
"Standard_H8m" =500;
"Standard_H16m" =500;
"Standard_H16r" =500;
"Standard_H16mr" =500;
"Standard_NV6" =500;
"Standard_NV12" =500;
"Standard_NV24" =500;
"Standard_NC6" =500;
"Standard_NC12" =500;
"Standard_NC24" =500;
"Standard_NC24r" =500}
}
"Logging in to Azure..."
    $ArmConn = Get-AutomationConnection -Name AzureRunAsConnection
    $AsmConn = Get-AutomationConnection -Name AzureClassicRunAsConnection
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
    $retry = 6
    $SyncOk = $false
do
{
	try
	{
    $certs= Get-ChildItem -Path Cert:\Currentuser\my -Recurse | Where{$_.Thumbprint -eq $ArmConn.CertificateThumbprint}
		[System.Security.Cryptography.X509Certificates.X509Certificate2]$mycert=$certs[0]
    $SyncOk = $true
	}
	catch
	{
    $ErrorMessage = $_.Exception.Message
    $StackTrace = $_.Exception.StackTrace
		Write-Warning "Error during certificate retrieval : $ErrorMessage, stack: $StackTrace. Retry attempts left: $retry"
    $retry = $retry - 1
		Start-Sleep -s 60
	}
} while (-not $SyncOk -and $retry -ge 0)
IF ($mycert)
{
    $CliCert=new-object -ErrorAction Stop  Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate($ArmConn.ApplicationId,$mycert)
    $AuthContext = new-object -ErrorAction Stop Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext(" https://login.windows.net/$($ArmConn.tenantid)" )
    $result = $AuthContext.AcquireToken(" https://management.core.windows.net/" ,$CliCert)
    $header = "Bearer " + $result.AccessToken
    $headers = @{"Authorization" =$header;"Accept" =" application/json" }
    $body=$null
    $HTTPVerb="GET"
    $SubscriptionInfoUri = "https://management.azure.com/subscriptions/" +$ArmConn.SubscriptionId+"?api-version=$ApiverVM"
    $SubscriptionInfo = Invoke-RestMethod -Uri $SubscriptionInfoUri -Headers $headers -Method Get -UseBasicParsing
	IF($SubscriptionInfo)
	{
		"Successfully connected to Azure ARM REST;"
    $SubscriptionInfo
	}
    Else
    {
        Write-warning "Unable to login to Azure ARM Rest , runbook will not continue"
        Exit
    }
}
Else
{
	Write-error "Failed to login ro Azure ARM REST  , make sure Runas account configured correctly"
	Exit
}
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
Function invoke-StorageREST($SharedKey, $method, $msgbody, $resource,$uri,$svc)
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
	Try
    {
    $response = Invoke-WebRequest -Uri $uri -Method POST  -ContentType $ContentType -Headers $OMSheaders -Body $body -UseBasicParsing
	}
	Catch
	{
    $_.MEssage
	}
	return $response.StatusCode
	write-output $response.StatusCode
	Write-error $error[0]
}
function Get-BlobSize -ErrorAction Stop ($bloburi,$storageaccount,$rg,$type)
{
	If($type -eq 'ARM')
	{
    $Uri=" https://management.azure.com{3}/resourceGroups/{2}/providers/Microsoft.Storage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $ApiVerSaArm, $storageaccount,$rg,$Subscriptioninfo.id
    $keyresp=Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys=ConvertFrom-Json -InputObject $keyresp.Content
    $prikey=$keys.keys[0].value
	}Elseif($type -eq 'Classic')
	{
    $Uri=" https://management.azure.com{3}/resourceGroups/{2}/providers/Microsoft.ClassicStorage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $ApiVerSaAsm,$storageaccount,$rg,$Subscriptioninfo.id
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
    $timestamp=(get-date).ToUniversalTime().ToString(" yyyy-MM-ddT$($hour):$($min):00.000Z" )
"Starting $(get-date)"
" $(GEt-date)  Get ARM storage Accounts "
    $Uri=" https://management.azure.com{1}/providers/Microsoft.Storage/storageAccounts?api-version={0}"   -f  $ApiVerSaArm,$Subscriptioninfo.id
    $armresp=Invoke-WebRequest -Uri $uri -Method GET  -Headers $headers -UseBasicParsing
    $SaArmList=(ConvertFrom-Json -InputObject $armresp.Content).Value
" $(GEt-date)  $($SaArmList.count) storage accounts found"
" $(GEt-date)  Get Classic storage Accounts "
    $Uri=" https://management.azure.com{1}/providers/Microsoft.ClassicStorage/storageAccounts?api-version={0}"   -f  $ApiVerSaAsm,$Subscriptioninfo.id
    $sresp=Invoke-WebRequest -Uri $uri -Method GET  -Headers $headers -UseBasicParsing
    $SaAsmList=(ConvertFrom-Json -InputObject $sresp.Content).value
" $(GEt-date)  $($SaAsmList.count) storage accounts found"
    $ColParamsforChild=@()
foreach($sa in $SaArmList|where {$_.Sku.tier -ne 'Premium'})
{
    $rg=$sku=$null
    $rg=$sa.id.Split('/')[4]
    $ColParamsforChild = $ColParamsforChild + " $($sa.name);$($sa.id.Split('/')[4]);ARM;$($sa.sku.tier)"
}
    $sa=$rg=$null
foreach($sa in $SaAsmList|where{$_.properties.accounttype -notmatch 'Premium'})
{
    $rg=$sa.id.Split('/')[4]
    $tier=$null
	If( $sa.properties.accountType -notmatch 'premium')
	{
    $tier='Standard'
    $ColParamsforChild = $ColParamsforChild + " $($sa.name);$($sa.id.Split('/')[4]);Classic;$tier"
	}
}
    $SAInventory=@()
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
		SubscriptionId = $subscriptioninfo.subscriptionId
        AzureSubscription = $SubscriptionInfo.displayName
	}
	IF ($sa.properties.creationTime){$cu|Add-Member -MemberType NoteProperty -Name CreationTime -Value $sa.properties.creationTime}
	IF ($sa.properties.primaryLocation){$cu|Add-Member -MemberType NoteProperty -Name PrimaryLocation -Value $sa.properties.primaryLocation}
	IF ($sa.properties.secondaryLocation){$cu|Add-Member -MemberType NoteProperty -Name secondaryLocation-Value $sa.properties.secondaryLocation}
	IF ($sa.properties.statusOfPrimary){$cu|Add-Member -MemberType NoteProperty -Name statusOfPrimary -Value $sa.properties.statusOfPrimary}
	IF ($sa.properties.statusOfSecondary){$cu|Add-Member -MemberType NoteProperty -Name statusOfSecondary -Value $sa.properties.statusOfSecondary}
	IF ($sa.kind -eq 'BlobStorage'){$cu|Add-Member -MemberType NoteProperty -Name accessTier -Value $sa.properties.accessTier}
    $SAInventory = $SAInventory + $cu
}
foreach($sa in $SaAsmList)
{
    $rg=$sa.id.Split('/')[4]
    $cu=$iotype=$null
	IF($sa.properties.accountType -like 'Standard*')
	{$iotype='Standard'}Else{{$iotype='Premium'}}
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
			SubscriptionId = $subscriptioninfo.subscriptionId
        AzureSubscription = $SubscriptionInfo.displayName
	}
	IF ($sa.properties.creationTime){$cu|Add-Member -MemberType NoteProperty -Name CreationTime -Value $sa.properties.creationTime}
	IF ($sa.properties.geoPrimaryRegion){$cu|Add-Member -MemberType NoteProperty -Name PrimaryLocation -Value $sa.properties.geoPrimaryRegion.Replace(' ','')}
	IF ($sa.properties.geoSecondaryRegion ){$cu|Add-Member -MemberType NoteProperty -Name SecondaryLocation-Value $sa.properties.geoSecondaryRegion.Replace(' ','')}
	IF ($sa.properties.statusOfPrimaryRegion){$cu|Add-Member -MemberType NoteProperty -Name statusOfPrimary -Value $sa.properties.statusOfPrimaryRegion}
	IF ($sa.properties.statusOfSecondaryRegion){$cu|Add-Member -MemberType NoteProperty -Name statusOfSecondary -Value $sa.properties.statusOfSecondaryRegion}
    $SAInventory = $SAInventory + $cu
}
Write-output "Starting API Limits collection "
$r = Invoke-WebRequest -Uri " https://management.azure.com$($SubscriptionInfo.id)/resourcegroups?api-version=2016-09-01" -Method GET -Headers $Headers -UseBasicParsing
    $remaining=$r.Headers[" x-ms-ratelimit-remaining-subscription-reads" ]
"API reads remaining: $remaining"
    $apidatafirst = New-Object -ErrorAction Stop PSObject -Property @{
                             MetricName = 'ARMAPILimits';
                            APIReadsRemaining=$r.Headers[" x-ms-ratelimit-remaining-subscription-reads" ]
                            SubscriptionID = $SubscriptionInfo.id
                            AzureSubscription = $SubscriptionInfo.displayName
                            }
" $(get-date)   -  $($apidatafirst.APIReadsRemaining)  request available , collection will continue "
    $uri=" https://management.azure.com$($SubscriptionInfo.id)/resourceGroups?api-version=$ApiverVM"
    $resultarm = Invoke-WebRequest -Method Get -Uri $uri -Headers $headers -UseBasicParsing
    $content=$resultarm.Content
    $content= ConvertFrom-Json -InputObject $resultarm.Content
    $rglist=$content.value
    $uri=" https://management.azure.com" +$SubscriptionInfo.id+"/providers?api-version=$ApiverVM"
    $resultarm = Invoke-WebRequest -Method $HTTPVerb -Uri $uri -Headers $headers -UseBasicParsing
    $content=$resultarm.Content
    $content= ConvertFrom-Json -InputObject $resultarm.Content
    $providers=@()
Foreach($item in $content.value)
{
foreach ($rgobj in $item.resourceTypes)
{
    $properties = @{'ID'=$item.id;
                'namespace'=$item.namespace;
                'Resourcetype'=$rgobj.resourceType;
                'Apiversion'=$rgobj.apiVersions[0]}
    $object = New-Object -ErrorAction Stop TypeName PSObject Prop $properties
    $providers = $providers + $object
}
}
Write-output " $(get-date) - Starting inventory for VMs "
    $vmlist=@()
Foreach ($prvitem in $providers|where{$_.resourcetype -eq 'virtualMachines'})
{
    $uri=" https://management.azure.com" +$prvitem.id+"/$($prvitem.Resourcetype)?api-version=$($prvitem.apiversion)"
    $resultarm = Invoke-WebRequest -Method $HTTPVerb -Uri $uri -Headers $headers -UseBasicParsing
    $content=$resultarm.Content
    $content= ConvertFrom-Json -InputObject $resultarm.Content
    $vmlist = $vmlist + $content.value
    IF(![string]::IsNullOrEmpty($content.nextLink))
    {
        do
        {
    $uri2=$content.nextLink
    $content=$null
    $resultarm = Invoke-WebRequest -Method $HTTPVerb -Uri $uri2 -Headers $headers -UseBasicParsing
    $content=$resultarm.Content
    $content= ConvertFrom-Json -InputObject $resultarm.Content
    $vmlist = $vmlist + $content.value
    $uri2=$null
        }While (![string]::IsNullOrEmpty($content.nextLink))
    }
}
    $vmsclassic=$vmlist|where {$_.type -eq 'Microsoft.ClassicCompute/virtualMachines'}
    $vmsarm=$vmlist|where {$_.type -eq 'Microsoft.Compute/virtualMachines'}
    $vm=$cu=$cuvm=$cudisk=$null
    $allvms=@()
    $vmtags=@()
    $allvhds=@()
    $invendpoints=@()
    $invnsg=@()
    $invnic=@()
    $invextensions=@();
    $colltime=get-date -ErrorAction Stop
" {0}  VM found " -f $vmlist.count
Foreach ($vm in $vmsclassic)
{
    $extlist=$null
    $vm.properties.extensions|?{$extlist = $extlist + $_.extension+" ;" }
    $cuvm = New-Object -ErrorAction Stop PSObject -Property @{
                            Timestamp = $colltime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
                            MetricName = 'VMInventory';
                            ResourceGroup=$vm.id.Split('/')[4]
                            HWProfile=$vm.properties.hardwareProfile.size.ToString()
                            Deploymentname=$vm.properties.hardwareProfile.deploymentName.ToString()
                            Status=$VMstates.get_item($vm.properties.instanceView.status.ToString())
                            fqdn=$vm.properties.instanceView.fullyQualifiedDomainName
                            DeploymentType='Classic'
                            Location=$vm.location
                            VmName=$vm.Name
                            ID=$vm.id
                            OperatingSystem=$vm.properties.storageProfile.operatingSystemDisk.operatingSystem
                            privateIpAddress=$vm.properties.instanceView.privateIpAddress
                            SubscriptionId = $subscriptioninfo.subscriptionId
                             AzureSubscription = $SubscriptionInfo.displayName
                                   }
                if($vm.properties.networkProfile.virtualNetwork)
                    {
    $cuvm|Add-Member -MemberType NoteProperty -Name VNETName -Value $vm.properties.networkProfile.virtualNetwork.name -Force
    $cuvm|Add-Member -MemberType NoteProperty -Name Subnet -Value  $vm.properties.networkProfile.virtualNetwork.subnetNames[0] -Force
                    }
                 if( $vm.properties.instanceView.publicIpAddresses)
                    {
    $cuvm|Add-Member -MemberType NoteProperty -Name PublicIP -Value $vm.properties.instanceView.publicIpAddresses[0].tostring()
                    }
    $allvms = $allvms + $cuvm
    IF(![string]::IsNullOrEmpty($vm.properties.extensions))
    {
    Foreach ($extobj in $vm.properties.extensions)
        {
    $invextensions = $invextensions + New-Object -ErrorAction Stop PSObject -Property @{
                            Timestamp = $colltime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
                            MetricName = 'VMExtensions';
                           VmName=$vm.Name
                          Extension=$extobj.Extension
                          publisher=$extobj.publisher
                        version=$extobj.version
                        state=$extobj.state
                        referenceName=$extobj.referenceName
                        ID=$vm.id+"/extensions/" +$extobj.Extension
                        SubscriptionId = $subscriptioninfo.subscriptionId
                             AzureSubscription = $SubscriptionInfo.displayName
                                   }
        }
    }
    $ep=$null
    IF(![string]::IsNullOrEmpty($vm.properties.networkProfile.inputEndpoints)  -and $GetNICandNSG)
    {
        Foreach($ep in $vm.properties.networkProfile.inputEndpoints)
        {
    $invendpoints = $invendpoints + New-Object -ErrorAction Stop PSObject -Property @{
                            Timestamp = $colltime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
                            MetricName = 'VMEndpoint';
                           VmName=$vm.Name
                           endpointName=$ep.endpointName
                             publicIpAddress=$ep.publicIpAddress
                               privatePort=$ep.privatePort
                            publicPort=$ep.publicPort
                            protocol=$ep.protocol
                            enableDirectServerReturn=$ep.enableDirectServerReturn
                            SubscriptionId = $subscriptioninfo.subscriptionId
                             AzureSubscription = $SubscriptionInfo.displayName
                                   }
        }
    }
    If($GetDiskInfo)
    {
   IF(![string]::IsNullOrEmpty($vm.properties.storageProfile.operatingSystemDisk.storageAccount.Name))
    {
    $safordisk=$SAInventory|where {$_.StorageAccount -eq $vm.properties.storageProfile.operatingSystemDisk.storageAccount.Name}
    $IOtype=$safordisk.Tier
    $sizeingb=$null
    $sizeingb=Get-BlobSize -bloburi $([uri]$vm.properties.storageProfile.operatingSystemDisk.vhdUri) -storageaccount $safordisk.StorageAccount -rg $safordisk.ResourceGroup -type Classic
    $cudisk = New-Object -ErrorAction Stop PSObject -Property @{
		Timestamp = $colltime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
		MetricName = 'VMDisk';
        DiskType='Unmanaged'
		Deploymentname=$vm.properties.hardwareProfile.deploymentName.ToString()
		DeploymentType='Classic'
		Location=$vm.location
		VmName=$vm.Name
		VHDUri=$vm.properties.storageProfile.operatingSystemDisk.vhdUri
		DiskIOType=$IOtype
		StorageAccount=$vm.properties.storageProfile.operatingSystemDisk.storageAccount.Name
			SubscriptionId = $subscriptioninfo.subscriptionId
        AzureSubscription = $SubscriptionInfo.displayName
		SizeinGB=$sizeingb
	}
         IF ($IOtype -eq 'Standard' -and $vm.properties.hardwareProfile.size.ToString() -like  'Basic*')
	    {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 300
	    }ElseIf  ($IOtype -eq 'Standard' )
	    {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 500
        }Elseif($IOtype -eq 'Premium')
        {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxVMIO -Value $vmiolimits.Item($vm.properties.hardwareProfile.size)
           if ($cudisk.SizeinGB -le 128 )
           {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 500
           }Elseif ($cudisk.SizeinGB -in  129..512 )
           {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 2300
           }Elseif ($cudisk.SizeinGB -in  513..1024 )
           {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 5000
           }
        }
    $allvhds = $allvhds + $cudisk
    }
	IF($vm.properties.storageProfile.dataDisks)
	{
    $ddisks=$null
    $ddisks=@($vm.properties.storageProfile.dataDisks)
		Foreach($disk in $ddisks)
		{
            IF(![string]::IsNullOrEmpty($disk.storageAccount.Name))
            {
    $safordisk=$null
    $safordisk=$SAInventory|where {$_ -match $disk.storageAccount.Name}
    $IOtype=$safordisk.Tier
    $cudisk = New-Object -ErrorAction Stop PSObject -Property @{
				        Timestamp = $timestamp
				        MetricName = 'VMDisk';
                        DiskType='Unmanaged'
				        Deploymentname=$vm.properties.hardwareProfile.deploymentName.ToString()
				        DeploymentType='Classic'
				        Location=$vm.location
				        VmName=$vm.Name
				        VHDUri=$disk.vhdUri
				        DiskIOType=$IOtype
				        StorageAccount=$disk.storageAccount.Name
				        	SubscriptionId = $subscriptioninfo.subscriptionId
        AzureSubscription = $SubscriptionInfo.displayName
				        SizeinGB=$disk.diskSize
			        }
                 IF ($IOtype -eq 'Standard' -and $vm.properties.hardwareProfile.size.ToString() -like  'Basic*')
	            {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 300
	            }ElseIf  ($IOtype -eq 'Standard' )
	            {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 500
                }Elseif($IOtype -eq 'Premium')
                {
                   if ($cudisk.SizeinGB -le 128 )
                   {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 500
                   }Elseif ($cudisk.SizeinGB -in  129..512 )
                   {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 2300
                   }Elseif ($cudisk.SizeinGB -in  513..1024 )
                   {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 5000
                   }
                }
    $allvhds = $allvhds + $cudisk
		      }
		   }
	}
    }
}
    $vm=$cuvm=$cudisk=$osdisk=$nic=$nsg=$null
Foreach ($vm in $vmsarm)
{
    $cuvm = New-Object -ErrorAction Stop PSObject -Property @{
                            Timestamp = $colltime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
                            MetricName = 'VMInventory';
                            ResourceGroup=$vm.id.split('/')[4]
                            HWProfile=$vm.properties.hardwareProfile.vmSize.ToString()
                            DeploymentType='ARM'
                            Location=$vm.location
                            VmName=$vm.Name
                            OperatingSystem=$vm.properties.storageProfile.osDisk.osType
                            ID=$vm.id
                           	SubscriptionId = $subscriptioninfo.subscriptionId
        AzureSubscription = $SubscriptionInfo.displayName
                            }
              If([int]$remaining -gt [int]$apireadlimit -and $getarmvmstatus)
                {
    $uriinsview=" https://management.azure.com" +$vm.id+"/InstanceView?api-version=2015-06-15"
    $resiview = Invoke-WebRequest -Method Get -Uri $uriinsview -Headers $headers -UseBasicParsing
    $ivcontent=$resiview.Content
    $ivcontent= ConvertFrom-Json -InputObject $resiview.Content
    $cuvm|Add-Member -MemberType NoteProperty -Name Status  -Value $VMstates.get_item(($ivcontent.statuses|select -Last 1).Code)
                }
    $allvms = $allvms + $CuVM
                If($GetNICandNSG)
                {
Foreach ($nicobj in $vm.properties.networkProfile.networkInterfaces)
{
    $urinic=" https://management.azure.com" +$nicobj.id+"?api-version=2015-06-15"
    $nicresult = Invoke-WebRequest -Method Get -Uri $urinic -Headers $headers -UseBasicParsing
    $Nic= ConvertFrom-Json -InputObject $nicresult.Content
    $cunic=$null
    $CuNic= New-Object -ErrorAction Stop PSObject -Property @{
                            Timestamp = $colltime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
                            MetricName = 'VMNIC';
                            VmName=$vm.Name
                            ID=$nic.id
                            NetworkInterface=$nic.name
                            VNetName=$nic.properties.ipConfigurations[0].properties.subnet.id.split('/')[8]
                            ResourceGroup=$nic.id.split('/')[4]
                            Location=$nic.location
                            Primary=$nic.properties.primary
                            enableIPForwarding=$nic.properties.enableIPForwarding
                            macAddress=$nic.properties.macAddress
                            privateIPAddress=$nic.properties.ipConfigurations[0].properties.privateIPAddress
                            privateIPAllocationMethod=$nic.properties.ipConfigurations[0].properties.privateIPAllocationMethod
                            subnet=$nic.properties.ipConfigurations[0].properties.subnet.id.split('/')[10]
                           	SubscriptionId = $subscriptioninfo.subscriptionId
                            AzureSubscription = $SubscriptionInfo.displayName
                            }
            IF (![string]::IsNullOrEmpty($cunic.publicIPAddress))
            {
    $uripip=" https://management.azure.com" +$cunic.publicIPAddress+"?api-version=2015-06-15"
    $pipresult = Invoke-WebRequest -Method Get -Uri $uripip -Headers $headers -UseBasicParsing
    $pip= ConvertFrom-Json -InputObject $pipresult.Content
                If($pip)
                {
    $CuNic|Add-Member -MemberType NoteProperty -Name PublicIp -Value $pip.properties.ipAddress -Force
    $CuNic|Add-Member -MemberType NoteProperty -Name publicIPAllocationMethod -Value $pip.properties.publicIPAllocationMethod -Force
    $CuNic|Add-Member -MemberType NoteProperty -Name fqdn -Value $pip.properties.dnsSettings.fqdn -Force
                }
            }
    $InvNic = $InvNic + $CuNic
        IF($nic.properties.networkSecurityGroup)
        {
            Foreach($nsgobj in $nic.properties.networkSecurityGroup)
            {
    $urinsg=" https://management.azure.com" +$nsgobj.id+"?api-version=2015-06-15"
    $nsgresult = Invoke-WebRequest -Method Get -Uri $urinsg -Headers $headers -UseBasicParsing
    $nsg= ConvertFrom-Json -InputObject $nsgresult.Content
                 If($Nsg.properties.securityRules)
                 {
                    foreach($rule in $Nsg.properties.securityRules)
                    {
    $invnsg = $invnsg + New-Object -ErrorAction Stop PSObject -Property @{
                            Timestamp = $colltime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
                            MetricName = 'VMNSGrule';
                            VmName=$vm.Name
                            ID=$nsg.id
                            NSGName=$nsg.id
                            NetworkInterface=$nic.name
                            ResourceGroup=$nsg.id.split('/')[4]
                            Location=$nsg.location
                            RuleName=$rule.name
                            protocol=$rule.properties.protocol
                            sourcePortRange=$rule.properties.sourcePortRange
                            destinationPortRange=$rule.properties.destinationPortRange
                            sourceAddressPrefix=$rule.properties.sourceAddressPrefix
                            destinationAddressPrefix=$rule.properties.destinationAddressPrefix
                            access=$rule.properties.access
                            priority=$rule.properties.priority
                            direction=$rule.properties.direction
                             	SubscriptionId = $subscriptioninfo.subscriptionId
                             AzureSubscription = $SubscriptionInfo.displayName
                            }
                    }
                 }
             }
        }
}
                }
            IF(![string]::IsNullOrEmpty($vm.resources.id))
            {
                  Foreach ($extobj in $vm.resources)
                    {
                        if($extobj.id.Split('/')[9] -eq 'extensions')
                        {
    $invextensions = $invextensions + New-Object -ErrorAction Stop PSObject -Property @{
                                        Timestamp = $colltime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
                                        MetricName = 'VMExtensions';
                           VmName=$vm.Name
                          Extension=$extobj.Extension
                         ID=$extobj.id
                                                     SubscriptionId = $subscriptioninfo.subscriptionId
                             AzureSubscription = $SubscriptionInfo.displayName
                                   }
                        }
        }
            }
        If($vm.tags)
         {
    $tags=$null
    $tags=$vm.tags
            foreach ($tag in $tags)
            {
    $tag.PSObject.Properties | foreach-object {
    $name = $_.Name
    $value = $_.value
                    IF ($name -match '-LabUId'){Continue}
                    Write-Verbose     "Adding tag $name : $value to $($VM.name)"
    $cutag=$null
    $cutag=New-Object -ErrorAction Stop PSObject
    $CuVM.psobject.Properties|foreach-object  {
    $cutag|Add-Member -MemberType NoteProperty -Name  $_.Name   -Value $_.value -Force
                }
    $cutag|Add-Member -MemberType NoteProperty -Name Tag  -Value " $name : $value"
                }
    $vmtags = $vmtags + $cutag
           }
         }
      IF($GetDiskInfo)
      {
    $osdisk=$SaforVm=$IOtype=$null
   IF(![string]::IsNullOrEmpty($vm.properties.storageProfile.osDisk.vhd.uri))
    {
    $osdisk=[uri]$vm.properties.storageProfile.osDisk.vhd.uri
    $SaforVm=$SAInventory|where {$_.StorageAccount -eq $osdisk.host.Substring(0,$osdisk.host.IndexOf('.')) }
	    IF($saforvm)
	            {
    $IOtype=$saforvm.tier
	}
    $sizeingb=$null
    $sizeingb=Get-BlobSize -bloburi $([uri]$vm.properties.storageProfile.osDisk.vhd.uri) -storageaccount $saforvm.StorageAccount -rg $SaforVm.ResourceGroup -type ARM
    $cudisk = New-Object -ErrorAction Stop PSObject -Property @{
		        Timestamp = $colltime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
		        MetricName = 'VMDisk';
		        DiskType='Unmanaged'
		        Deploymentname=$vm.id.split('/')[4]   # !!! consider chnaging this to ResourceGroup here or in query
		        DeploymentType='ARM'
		        Location=$vm.location
		        VmName=$vm.Name
		        VHDUri=$vm.properties.storageProfile.osDisk.vhd.uri
		        DiskIOType=$IOtype
		        StorageAccount=$SaforVM.StorageAccount
		        	SubscriptionId = $subscriptioninfo.subscriptionId
        AzureSubscription = $SubscriptionInfo.displayName
		        SizeinGB=$sizeingb
                } -ea 0
	    IF ($cudisk.DiskIOType -eq 'Standard' -and $vm.properties.hardwareProfile.vmSize.ToString() -like  'BAsic*')
	            {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 300
	}ElseIf  ($cudisk.DiskIOType -eq 'Standard' -and $vm.properties.hardwareProfile.vmSize.ToString() -like 'Standard*')
	            {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 500
	}Elseif($IOtype -eq 'Premium')
        {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxVMIO -Value $vmiolimits.Item($vm.properties.hardwareProfile.vmSize)
           if ($cudisk.SizeinGB -le 128 )
           {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 500
           }Elseif ($cudisk.SizeinGB -in  129..512 )
           {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 2300
           }Elseif ($cudisk.SizeinGB -in  513..1024 )
           {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 5000
           }
        }
    $allvhds = $allvhds + $cudisk
    }
    Else
    {
    $cudisk=$null
    $cudisk = New-Object -ErrorAction Stop PSObject -Property @{
		    Timestamp = $colltime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
		    MetricName = 'VMDisk';
		    DiskType='Unmanaged'
		    Deploymentname=$vm.id.split('/')[4]   # !!! consider chnaging this to ResourceGroup here or in query
		    DeploymentType='ARM'
		    Location=$vm.location
		    VmName=$vm.Name
		    Uri=" https://management.azure.com/{0}" -f $vm.properties.storageProfile.osDisk.managedDisk.id
		    StorageAccount=$vm.properties.storageProfile.osDisk.managedDisk.id
		    	SubscriptionId = $subscriptioninfo.subscriptionId
        AzureSubscription = $SubscriptionInfo.displayName
		    SizeinGB=128
                } -ea 0
	    IF ($vm.properties.storageProfile.osDisk.managedDisk.storageAccountType -match 'Standard')
	    {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 500
    $cudisk|Add-Member -MemberType NoteProperty -Name DiskIOType -Value 'Standard'
	    }Elseif($vm.properties.storageProfile.osDisk.managedDisk.storageAccountType -match  'Premium')
        {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxVMIO -Value $vmiolimits.Item($vm.properties.hardwareProfile.vmSize)
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 500
    $cudisk|Add-Member -MemberType NoteProperty -Name DiskIOType -Value 'Premium'
           }
    $allvhds = $allvhds + $cudisk
     }
	iF ($vm.properties.storageProfile.dataDisks)
	{
    $ddisks=$null
    $ddisks=@($vm.properties.storageProfile.dataDisks)
		Foreach($disk in $ddisks)
		{
               IF(![string]::IsNullOrEmpty($disk.vhd.uri))
            {
    $diskuri=$safordisk=$IOtype=$null
    $diskuri=[uri]$disk.vhd.uri
    $safordisk=$SAInventory|where {$_ -match $diskuri.host.Substring(0,$diskuri.host.IndexOf('.')) }
    $IOtype=$safordisk.Tier
    $cudisk = New-Object -ErrorAction Stop PSObject -Property @{
				        Timestamp = $colltime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
				        MetricName = 'VMDisk';
				        DiskType='Unmanaged'
				        Deploymentname=$vm.id.split('/')[4]
				        DeploymentType='ARM'
				        Location=$vm.location
				        VmName=$vm.Name
				        VHDUri=$disk.vhd.uri
				        DiskIOType=$IOtype
				        StorageAccount=$safordisk.StorageAccount
				        	SubscriptionId = $subscriptioninfo.subscriptionId
        AzureSubscription = $SubscriptionInfo.displayName
				        SizeinGB=$disk.diskSizeGB
			        } -ea 0
			IF ($cudisk.DiskIOType -eq 'Standard' -and $vm.properties.hardwareProfile.vmSize.ToString() -like  'BAsic*')
			{
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 300
			}ElseIf  ($cudisk.DiskIOType -eq 'Standard' -and $vm.properties.hardwareProfile.vmSize.ToString() -like 'Standard*')
			{
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 500
			}Elseif($IOtype -eq 'Premium')
            {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxVMIO -Value $vmiolimits.Item($vm.properties.hardwareProfile.vmSize)
               if ($cudisk.SizeinGB -le 128 )
               {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 500
               }Elseif ($cudisk.SizeinGB -in  129..512 )
               {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 2300
               }Elseif ($cudisk.SizeinGB -in  513..1024 )
               {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 5000
               }
           }
    $allvhds = $allvhds + $cudisk
    		}
            Else
            {
    $cudisk = New-Object -ErrorAction Stop PSObject -Property @{
		            Timestamp = $timestamp
		            MetricName = 'Inventory';
		            DiskType='Managed'
		            Deploymentname=$vm.id.split('/')[4]   # !!! consider chnaging this to ResourceGroup here or in query
		            DeploymentType='ARM'
		            Location=$vm.location
		            VmName=$vm.Name
		            Uri=" https://management.azure.com/{0}" -f $disk.manageddisk.id
		            StorageAccount=$disk.managedDisk.id
		            	SubscriptionId = $subscriptioninfo.subscriptionId
        AzureSubscription = $SubscriptionInfo.displayNamee
		            SizeinGB=$disk.diskSizeGB
                        } -ea 0
               IF ($vm.properties.storageProfile.osDisk.managedDisk.storageAccountType -match 'Standard')
	            {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 500
    $cudisk|Add-Member -MemberType NoteProperty -Name DiskIOType -Value 'Standard'
	            }Elseif($vm.properties.storageProfile.osDisk.managedDisk.storageAccountType -match  'Premium')
                {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxVMIO -Value $vmiolimits.Item($vm.properties.hardwareProfile.vmSize)
    $cudisk|Add-Member -MemberType NoteProperty -Name DiskIOType -Value 'Premium'
                     if ($disk.diskSizeGB -le 128 )
               {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 500
               }Elseif ($disk.diskSizeGB -in  129..512 )
               {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 2300
               }Elseif ($disk.diskSizeGB -in  513..1024 )
               {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 5000
               }
           }
    $allvhds = $allvhds + $cudisk
            }
        }
	}
    }
}
Write-output " $(get-date) - Starting inventory of Usage data "
    $locations=$loclistcontent=$cu=$null
    $allvmusage=@()
    $loclisturi=" https://management.azure.com/" +$SubscriptionInfo.id+"/locations?api-version=2016-09-01"
    $loclist = Invoke-WebRequest -Uri $loclisturi -Method GET -Headers $Headers -UseBasicParsing
    $loclistcontent= ConvertFrom-Json -InputObject $loclist.Content
    $locations =$loclistcontent
Foreach($loc in $loclistcontent.value.name)
{
    $usgdata=$cu=$usagecontent=$null
    $usageuri=" https://management.azure.com/" +$SubscriptionInfo.id+"/providers/Microsoft.Compute/locations/$(loc) /usages?api-version=2015-06-15"
    $usageapi = Invoke-WebRequest -Uri $usageuri -Method GET -Headers $Headers  -UseBasicParsing
    $usagecontent= ConvertFrom-Json -InputObject $usageapi.Content
Foreach($usgdata in $usagecontent.value)
{
    $cu= New-Object -ErrorAction Stop PSObject -Property @{
                              Timestamp = $timestamp
                             MetricName = 'ARMVMUsageStats';
                            Location = $loc
                            currentValue=$usgdata.currentValue
                            limit=$usgdata.limit
                            Usagemetric = $usgdata.name[0].value.ToString()
                            SubscriptionID = $SubscriptionInfo.id
                            AzureSubscription = $SubscriptionInfo.displayName
                            }
    $allvmusage = $allvmusage + $cu
}
}
    $jsonvmpool = ConvertTo-Json -InputObject $allvms
    $jsonvmtags = ConvertTo-Json -InputObject $vmtags
    $JsonVHDData= ConvertTo-Json -InputObject $allvhds
    $jsonallvmusage = ConvertTo-Json -InputObject $allvmusage
    $jsoninvnic = ConvertTo-Json -InputObject $invnic
    $jsoninvnsg = ConvertTo-Json -InputObject $invnsg;
    $jsoninvendpoint = ConvertTo-Json -InputObject $invendpoints;
    $jsoninveextensions = ConvertTo-Json -InputObject $invextensions
If($jsonvmpool){$postres1=Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonvmpool)) -logType $logname}
	If ($postres1 -ge 200 -and $postres1 -lt 300)
	{
		Write-Output "Succesfully uploaded $($allvms.count) vm inventory   to OMS"
	}
	Else
	{
		Write-Warning "Failed to upload  $($allvms.count) vm inventory   to OMS"
	}
If($jsonvmtags){$postres2=Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonvmtags)) -logType $logname}
	If ($postres2 -ge 200 -and $postres2 -lt 300)
	{
		Write-Output "Succesfully uploaded $($vmtags.count) vm tags  to OMS"
	}
	Else
	{
		Write-Warning "Failed to upload  $($vmtags.count) vm tags   to OMS"
	}
If($jsonallvmusage){$postres3=Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonallvmusage)) -logType $logname}
	If ($postres3 -ge 200 -and $postres3 -lt 300)
	{
		Write-Output "Succesfully uploaded $($allvmusage.count) vm core usage  metrics to OMS"
	}
	Else
	{
		Write-Warning "Failed to upload  $($allvmusage.count) vm core usage  metrics to OMS"
	}
If($JsonVHDData){$postres4=Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($JsonVHDData)) -logType $logname}
	If ($postres4 -ge 200 -and $postres4 -lt 300)
	{
		Write-Output "Succesfully uploaded $($allvhds.count) disk usage metrics to OMS"
	}
	Else
	{
		Write-Warning "Failed to upload  $($allvhds.count) Disk metrics to OMS"
	}
If($jsoninvnic){$postres5=Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsoninvnic)) -logType $logname}
	If ($postres5 -ge 200 -and $postres5 -lt 300)
	{
		Write-Output "Succesfully uploaded $($invnic.count) NICs to OMS"
	}
	Else
	{
		Write-Warning "Failed to upload  $($invnic.count) NICs to OMS"
	}
If($jsoninvnsg){$postres6=Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsoninvnsg)) -logType $logname}
	If ($postres6 -ge 200 -and $postres6 -lt 300)
	{
		Write-Output "Succesfully uploaded $($invnsg.count) NSG metrics to OMS"
	}
	Else
	{
		Write-Warning "Failed to upload  $($invnsg.count) NSG metrics to OMS"
	}
If($jsoninvendpoint){$postres7=Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsoninvendpoint)) -logType $logname}
	If ($postres7 -ge 200 -and $postres7 -lt 300)
	{
		Write-Output "Succesfully uploaded $($invendpoints.count) input endpoint metrics to OMS"
	}
	Else
	{
		Write-Warning "Failed to upload  $($invendpoints.count) input endpoint metrics to OMS"
	}
If($jsoninveextensions){$postres8=Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsoninveextensions)) -logType $logname}
	If ($postres8 -ge 200 -and $postres8 -lt 300)
	{
		Write-Output "Succesfully uploaded $($invendpoints.count) extensionsto OMS"
	}
	Else
	{
		Write-Warning "Failed to upload  $($invendpoints.count) extensions  to OMS"
	}
Write-output " $(get-date) - Uploading all data to OMS  "
.Exception.Message
}
function Get-BlobSize -ErrorAction Stop ($bloburi,$storageaccount,$rg,$type)
{
	If($type -eq 'ARM')
	{
    $Uri=" https://management.azure.com{3}/resourceGroups/{2}/providers/Microsoft.Storage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $ApiVerSaArm, $storageaccount,$rg,$Subscriptioninfo.id
    $keyresp=Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
    $keys=ConvertFrom-Json -InputObject $keyresp.Content
    $prikey=$keys.keys[0].value
	}Elseif($type -eq 'Classic')
	{
    $Uri=" https://management.azure.com{3}/resourceGroups/{2}/providers/Microsoft.ClassicStorage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $ApiVerSaAsm,$storageaccount,$rg,$Subscriptioninfo.id
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
    $timestamp=(get-date).ToUniversalTime().ToString(" yyyy-MM-ddT$($hour):$($min):00.000Z" )
"Starting $(get-date)"
" $(GEt-date)  Get ARM storage Accounts "
    $Uri=" https://management.azure.com{1}/providers/Microsoft.Storage/storageAccounts?api-version={0}"   -f  $ApiVerSaArm,$Subscriptioninfo.id
    $armresp=Invoke-WebRequest -Uri $uri -Method GET  -Headers $headers -UseBasicParsing
    $SaArmList=(ConvertFrom-Json -InputObject $armresp.Content).Value
" $(GEt-date)  $($SaArmList.count) storage accounts found"
" $(GEt-date)  Get Classic storage Accounts "
    $Uri=" https://management.azure.com{1}/providers/Microsoft.ClassicStorage/storageAccounts?api-version={0}"   -f  $ApiVerSaAsm,$Subscriptioninfo.id
    $sresp=Invoke-WebRequest -Uri $uri -Method GET  -Headers $headers -UseBasicParsing
    $SaAsmList=(ConvertFrom-Json -InputObject $sresp.Content).value
" $(GEt-date)  $($SaAsmList.count) storage accounts found"
    $ColParamsforChild=@()
foreach($sa in $SaArmList|where {$_.Sku.tier -ne 'Premium'})
{
    $rg=$sku=$null
    $rg=$sa.id.Split('/')[4]
    $ColParamsforChild = $ColParamsforChild + " $($sa.name);$($sa.id.Split('/')[4]);ARM;$($sa.sku.tier)"
}
    $sa=$rg=$null
foreach($sa in $SaAsmList|where{$_.properties.accounttype -notmatch 'Premium'})
{
    $rg=$sa.id.Split('/')[4]
    $tier=$null
	If( $sa.properties.accountType -notmatch 'premium')
	{
    $tier='Standard'
    $ColParamsforChild = $ColParamsforChild + " $($sa.name);$($sa.id.Split('/')[4]);Classic;$tier"
	}
}
    $SAInventory=@()
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
		SubscriptionId = $subscriptioninfo.subscriptionId
        AzureSubscription = $SubscriptionInfo.displayName
	}
	IF ($sa.properties.creationTime){$cu|Add-Member -MemberType NoteProperty -Name CreationTime -Value $sa.properties.creationTime}
	IF ($sa.properties.primaryLocation){$cu|Add-Member -MemberType NoteProperty -Name PrimaryLocation -Value $sa.properties.primaryLocation}
	IF ($sa.properties.secondaryLocation){$cu|Add-Member -MemberType NoteProperty -Name secondaryLocation-Value $sa.properties.secondaryLocation}
	IF ($sa.properties.statusOfPrimary){$cu|Add-Member -MemberType NoteProperty -Name statusOfPrimary -Value $sa.properties.statusOfPrimary}
	IF ($sa.properties.statusOfSecondary){$cu|Add-Member -MemberType NoteProperty -Name statusOfSecondary -Value $sa.properties.statusOfSecondary}
	IF ($sa.kind -eq 'BlobStorage'){$cu|Add-Member -MemberType NoteProperty -Name accessTier -Value $sa.properties.accessTier}
    $SAInventory = $SAInventory + $cu
}
foreach($sa in $SaAsmList)
{
    $rg=$sa.id.Split('/')[4]
    $cu=$iotype=$null
	IF($sa.properties.accountType -like 'Standard*')
	{$iotype='Standard'}Else{{$iotype='Premium'}}
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
			SubscriptionId = $subscriptioninfo.subscriptionId
        AzureSubscription = $SubscriptionInfo.displayName
	}
	IF ($sa.properties.creationTime){$cu|Add-Member -MemberType NoteProperty -Name CreationTime -Value $sa.properties.creationTime}
	IF ($sa.properties.geoPrimaryRegion){$cu|Add-Member -MemberType NoteProperty -Name PrimaryLocation -Value $sa.properties.geoPrimaryRegion.Replace(' ','')}
	IF ($sa.properties.geoSecondaryRegion ){$cu|Add-Member -MemberType NoteProperty -Name SecondaryLocation-Value $sa.properties.geoSecondaryRegion.Replace(' ','')}
	IF ($sa.properties.statusOfPrimaryRegion){$cu|Add-Member -MemberType NoteProperty -Name statusOfPrimary -Value $sa.properties.statusOfPrimaryRegion}
	IF ($sa.properties.statusOfSecondaryRegion){$cu|Add-Member -MemberType NoteProperty -Name statusOfSecondary -Value $sa.properties.statusOfSecondaryRegion}
    $SAInventory = $SAInventory + $cu
}
Write-output "Starting API Limits collection "
$r = Invoke-WebRequest -Uri " https://management.azure.com$($SubscriptionInfo.id)/resourcegroups?api-version=2016-09-01" -Method GET -Headers $Headers -UseBasicParsing
    $remaining=$r.Headers[" x-ms-ratelimit-remaining-subscription-reads" ]
"API reads remaining: $remaining"
    $apidatafirst = New-Object -ErrorAction Stop PSObject -Property @{
                             MetricName = 'ARMAPILimits';
                            APIReadsRemaining=$r.Headers[" x-ms-ratelimit-remaining-subscription-reads" ]
                            SubscriptionID = $SubscriptionInfo.id
                            AzureSubscription = $SubscriptionInfo.displayName
                            }
" $(get-date)   -  $($apidatafirst.APIReadsRemaining)  request available , collection will continue "
    $uri=" https://management.azure.com$($SubscriptionInfo.id)/resourceGroups?api-version=$ApiverVM"
    $resultarm = Invoke-WebRequest -Method Get -Uri $uri -Headers $headers -UseBasicParsing
    $content=$resultarm.Content
    $content= ConvertFrom-Json -InputObject $resultarm.Content
    $rglist=$content.value
    $uri=" https://management.azure.com" +$SubscriptionInfo.id+"/providers?api-version=$ApiverVM"
    $resultarm = Invoke-WebRequest -Method $HTTPVerb -Uri $uri -Headers $headers -UseBasicParsing
    $content=$resultarm.Content
    $content= ConvertFrom-Json -InputObject $resultarm.Content
    $providers=@()
Foreach($item in $content.value)
{
foreach ($rgobj in $item.resourceTypes)
{
    $properties = @{'ID'=$item.id;
                'namespace'=$item.namespace;
                'Resourcetype'=$rgobj.resourceType;
                'Apiversion'=$rgobj.apiVersions[0]}
    $object = New-Object -ErrorAction Stop TypeName PSObject Prop $properties
    $providers = $providers + $object
}
}
Write-output " $(get-date) - Starting inventory for VMs "
    $vmlist=@()
Foreach ($prvitem in $providers|where{$_.resourcetype -eq 'virtualMachines'})
{
    $uri=" https://management.azure.com" +$prvitem.id+"/$($prvitem.Resourcetype)?api-version=$($prvitem.apiversion)"
    $resultarm = Invoke-WebRequest -Method $HTTPVerb -Uri $uri -Headers $headers -UseBasicParsing
    $content=$resultarm.Content
    $content= ConvertFrom-Json -InputObject $resultarm.Content
    $vmlist = $vmlist + $content.value
    IF(![string]::IsNullOrEmpty($content.nextLink))
    {
        do
        {
    $uri2=$content.nextLink
    $content=$null
    $resultarm = Invoke-WebRequest -Method $HTTPVerb -Uri $uri2 -Headers $headers -UseBasicParsing
    $content=$resultarm.Content
    $content= ConvertFrom-Json -InputObject $resultarm.Content
    $vmlist = $vmlist + $content.value
    $uri2=$null
        }While (![string]::IsNullOrEmpty($content.nextLink))
    }
}
    $vmsclassic=$vmlist|where {$_.type -eq 'Microsoft.ClassicCompute/virtualMachines'}
    $vmsarm=$vmlist|where {$_.type -eq 'Microsoft.Compute/virtualMachines'}
    $vm=$cu=$cuvm=$cudisk=$null
    $allvms=@()
    $vmtags=@()
    $allvhds=@()
    $invendpoints=@()
    $invnsg=@()
    $invnic=@()
    $invextensions=@();
    $colltime=get-date -ErrorAction Stop
" {0}  VM found " -f $vmlist.count
Foreach ($vm in $vmsclassic)
{
    $extlist=$null
    $vm.properties.extensions|?{$extlist = $extlist + $_.extension+" ;" }
    $cuvm = New-Object -ErrorAction Stop PSObject -Property @{
                            Timestamp = $colltime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
                            MetricName = 'VMInventory';
                            ResourceGroup=$vm.id.Split('/')[4]
                            HWProfile=$vm.properties.hardwareProfile.size.ToString()
                            Deploymentname=$vm.properties.hardwareProfile.deploymentName.ToString()
                            Status=$VMstates.get_item($vm.properties.instanceView.status.ToString())
                            fqdn=$vm.properties.instanceView.fullyQualifiedDomainName
                            DeploymentType='Classic'
                            Location=$vm.location
                            VmName=$vm.Name
                            ID=$vm.id
                            OperatingSystem=$vm.properties.storageProfile.operatingSystemDisk.operatingSystem
                            privateIpAddress=$vm.properties.instanceView.privateIpAddress
                            SubscriptionId = $subscriptioninfo.subscriptionId
                             AzureSubscription = $SubscriptionInfo.displayName
                                   }
                if($vm.properties.networkProfile.virtualNetwork)
                    {
    $cuvm|Add-Member -MemberType NoteProperty -Name VNETName -Value $vm.properties.networkProfile.virtualNetwork.name -Force
    $cuvm|Add-Member -MemberType NoteProperty -Name Subnet -Value  $vm.properties.networkProfile.virtualNetwork.subnetNames[0] -Force
                    }
                 if( $vm.properties.instanceView.publicIpAddresses)
                    {
    $cuvm|Add-Member -MemberType NoteProperty -Name PublicIP -Value $vm.properties.instanceView.publicIpAddresses[0].tostring()
                    }
    $allvms = $allvms + $cuvm
    IF(![string]::IsNullOrEmpty($vm.properties.extensions))
    {
    Foreach ($extobj in $vm.properties.extensions)
        {
    $invextensions = $invextensions + New-Object -ErrorAction Stop PSObject -Property @{
                            Timestamp = $colltime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
                            MetricName = 'VMExtensions';
                           VmName=$vm.Name
                          Extension=$extobj.Extension
                          publisher=$extobj.publisher
                        version=$extobj.version
                        state=$extobj.state
                        referenceName=$extobj.referenceName
                        ID=$vm.id+"/extensions/" +$extobj.Extension
                        SubscriptionId = $subscriptioninfo.subscriptionId
                             AzureSubscription = $SubscriptionInfo.displayName
                                   }
        }
    }
    $ep=$null
    IF(![string]::IsNullOrEmpty($vm.properties.networkProfile.inputEndpoints)  -and $GetNICandNSG)
    {
        Foreach($ep in $vm.properties.networkProfile.inputEndpoints)
        {
    $invendpoints = $invendpoints + New-Object -ErrorAction Stop PSObject -Property @{
                            Timestamp = $colltime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
                            MetricName = 'VMEndpoint';
                           VmName=$vm.Name
                           endpointName=$ep.endpointName
                             publicIpAddress=$ep.publicIpAddress
                               privatePort=$ep.privatePort
                            publicPort=$ep.publicPort
                            protocol=$ep.protocol
                            enableDirectServerReturn=$ep.enableDirectServerReturn
                            SubscriptionId = $subscriptioninfo.subscriptionId
                             AzureSubscription = $SubscriptionInfo.displayName
                                   }
        }
    }
    If($GetDiskInfo)
    {
   IF(![string]::IsNullOrEmpty($vm.properties.storageProfile.operatingSystemDisk.storageAccount.Name))
    {
    $safordisk=$SAInventory|where {$_.StorageAccount -eq $vm.properties.storageProfile.operatingSystemDisk.storageAccount.Name}
    $IOtype=$safordisk.Tier
    $sizeingb=$null
    $sizeingb=Get-BlobSize -bloburi $([uri]$vm.properties.storageProfile.operatingSystemDisk.vhdUri) -storageaccount $safordisk.StorageAccount -rg $safordisk.ResourceGroup -type Classic
    $cudisk = New-Object -ErrorAction Stop PSObject -Property @{
		Timestamp = $colltime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
		MetricName = 'VMDisk';
        DiskType='Unmanaged'
		Deploymentname=$vm.properties.hardwareProfile.deploymentName.ToString()
		DeploymentType='Classic'
		Location=$vm.location
		VmName=$vm.Name
		VHDUri=$vm.properties.storageProfile.operatingSystemDisk.vhdUri
		DiskIOType=$IOtype
		StorageAccount=$vm.properties.storageProfile.operatingSystemDisk.storageAccount.Name
			SubscriptionId = $subscriptioninfo.subscriptionId
        AzureSubscription = $SubscriptionInfo.displayName
		SizeinGB=$sizeingb
	}
         IF ($IOtype -eq 'Standard' -and $vm.properties.hardwareProfile.size.ToString() -like  'Basic*')
	    {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 300
	    }ElseIf  ($IOtype -eq 'Standard' )
	    {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 500
        }Elseif($IOtype -eq 'Premium')
        {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxVMIO -Value $vmiolimits.Item($vm.properties.hardwareProfile.size)
           if ($cudisk.SizeinGB -le 128 )
           {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 500
           }Elseif ($cudisk.SizeinGB -in  129..512 )
           {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 2300
           }Elseif ($cudisk.SizeinGB -in  513..1024 )
           {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 5000
           }
        }
    $allvhds = $allvhds + $cudisk
    }
	IF($vm.properties.storageProfile.dataDisks)
	{
    $ddisks=$null
    $ddisks=@($vm.properties.storageProfile.dataDisks)
		Foreach($disk in $ddisks)
		{
            IF(![string]::IsNullOrEmpty($disk.storageAccount.Name))
            {
    $safordisk=$null
    $safordisk=$SAInventory|where {$_ -match $disk.storageAccount.Name}
    $IOtype=$safordisk.Tier
    $cudisk = New-Object -ErrorAction Stop PSObject -Property @{
				        Timestamp = $timestamp
				        MetricName = 'VMDisk';
                        DiskType='Unmanaged'
				        Deploymentname=$vm.properties.hardwareProfile.deploymentName.ToString()
				        DeploymentType='Classic'
				        Location=$vm.location
				        VmName=$vm.Name
				        VHDUri=$disk.vhdUri
				        DiskIOType=$IOtype
				        StorageAccount=$disk.storageAccount.Name
				        	SubscriptionId = $subscriptioninfo.subscriptionId
        AzureSubscription = $SubscriptionInfo.displayName
				        SizeinGB=$disk.diskSize
			        }
                 IF ($IOtype -eq 'Standard' -and $vm.properties.hardwareProfile.size.ToString() -like  'Basic*')
	            {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 300
	            }ElseIf  ($IOtype -eq 'Standard' )
	            {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 500
                }Elseif($IOtype -eq 'Premium')
                {
                   if ($cudisk.SizeinGB -le 128 )
                   {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 500
                   }Elseif ($cudisk.SizeinGB -in  129..512 )
                   {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 2300
                   }Elseif ($cudisk.SizeinGB -in  513..1024 )
                   {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 5000
                   }
                }
    $allvhds = $allvhds + $cudisk
		      }
		   }
	}
    }
}
    $vm=$cuvm=$cudisk=$osdisk=$nic=$nsg=$null
Foreach ($vm in $vmsarm)
{
    $cuvm = New-Object -ErrorAction Stop PSObject -Property @{
                            Timestamp = $colltime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
                            MetricName = 'VMInventory';
                            ResourceGroup=$vm.id.split('/')[4]
                            HWProfile=$vm.properties.hardwareProfile.vmSize.ToString()
                            DeploymentType='ARM'
                            Location=$vm.location
                            VmName=$vm.Name
                            OperatingSystem=$vm.properties.storageProfile.osDisk.osType
                            ID=$vm.id
                           	SubscriptionId = $subscriptioninfo.subscriptionId
        AzureSubscription = $SubscriptionInfo.displayName
                            }
              If([int]$remaining -gt [int]$apireadlimit -and $getarmvmstatus)
                {
    $uriinsview=" https://management.azure.com" +$vm.id+"/InstanceView?api-version=2015-06-15"
    $resiview = Invoke-WebRequest -Method Get -Uri $uriinsview -Headers $headers -UseBasicParsing
    $ivcontent=$resiview.Content
    $ivcontent= ConvertFrom-Json -InputObject $resiview.Content
    $cuvm|Add-Member -MemberType NoteProperty -Name Status  -Value $VMstates.get_item(($ivcontent.statuses|select -Last 1).Code)
                }
    $allvms = $allvms + $CuVM
                If($GetNICandNSG)
                {
Foreach ($nicobj in $vm.properties.networkProfile.networkInterfaces)
{
    $urinic=" https://management.azure.com" +$nicobj.id+"?api-version=2015-06-15"
    $nicresult = Invoke-WebRequest -Method Get -Uri $urinic -Headers $headers -UseBasicParsing
    $Nic= ConvertFrom-Json -InputObject $nicresult.Content
    $cunic=$null
    $CuNic= New-Object -ErrorAction Stop PSObject -Property @{
                            Timestamp = $colltime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
                            MetricName = 'VMNIC';
                            VmName=$vm.Name
                            ID=$nic.id
                            NetworkInterface=$nic.name
                            VNetName=$nic.properties.ipConfigurations[0].properties.subnet.id.split('/')[8]
                            ResourceGroup=$nic.id.split('/')[4]
                            Location=$nic.location
                            Primary=$nic.properties.primary
                            enableIPForwarding=$nic.properties.enableIPForwarding
                            macAddress=$nic.properties.macAddress
                            privateIPAddress=$nic.properties.ipConfigurations[0].properties.privateIPAddress
                            privateIPAllocationMethod=$nic.properties.ipConfigurations[0].properties.privateIPAllocationMethod
                            subnet=$nic.properties.ipConfigurations[0].properties.subnet.id.split('/')[10]
                           	SubscriptionId = $subscriptioninfo.subscriptionId
                            AzureSubscription = $SubscriptionInfo.displayName
                            }
            IF (![string]::IsNullOrEmpty($cunic.publicIPAddress))
            {
    $uripip=" https://management.azure.com" +$cunic.publicIPAddress+"?api-version=2015-06-15"
    $pipresult = Invoke-WebRequest -Method Get -Uri $uripip -Headers $headers -UseBasicParsing
    $pip= ConvertFrom-Json -InputObject $pipresult.Content
                If($pip)
                {
    $CuNic|Add-Member -MemberType NoteProperty -Name PublicIp -Value $pip.properties.ipAddress -Force
    $CuNic|Add-Member -MemberType NoteProperty -Name publicIPAllocationMethod -Value $pip.properties.publicIPAllocationMethod -Force
    $CuNic|Add-Member -MemberType NoteProperty -Name fqdn -Value $pip.properties.dnsSettings.fqdn -Force
                }
            }
    $InvNic = $InvNic + $CuNic
        IF($nic.properties.networkSecurityGroup)
        {
            Foreach($nsgobj in $nic.properties.networkSecurityGroup)
            {
    $urinsg=" https://management.azure.com" +$nsgobj.id+"?api-version=2015-06-15"
    $nsgresult = Invoke-WebRequest -Method Get -Uri $urinsg -Headers $headers -UseBasicParsing
    $nsg= ConvertFrom-Json -InputObject $nsgresult.Content
                 If($Nsg.properties.securityRules)
                 {
                    foreach($rule in $Nsg.properties.securityRules)
                    {
    $invnsg = $invnsg + New-Object -ErrorAction Stop PSObject -Property @{
                            Timestamp = $colltime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
                            MetricName = 'VMNSGrule';
                            VmName=$vm.Name
                            ID=$nsg.id
                            NSGName=$nsg.id
                            NetworkInterface=$nic.name
                            ResourceGroup=$nsg.id.split('/')[4]
                            Location=$nsg.location
                            RuleName=$rule.name
                            protocol=$rule.properties.protocol
                            sourcePortRange=$rule.properties.sourcePortRange
                            destinationPortRange=$rule.properties.destinationPortRange
                            sourceAddressPrefix=$rule.properties.sourceAddressPrefix
                            destinationAddressPrefix=$rule.properties.destinationAddressPrefix
                            access=$rule.properties.access
                            priority=$rule.properties.priority
                            direction=$rule.properties.direction
                             	SubscriptionId = $subscriptioninfo.subscriptionId
                             AzureSubscription = $SubscriptionInfo.displayName
                            }
                    }
                 }
             }
        }
}
                }
            IF(![string]::IsNullOrEmpty($vm.resources.id))
            {
                  Foreach ($extobj in $vm.resources)
                    {
                        if($extobj.id.Split('/')[9] -eq 'extensions')
                        {
    $invextensions = $invextensions + New-Object -ErrorAction Stop PSObject -Property @{
                                        Timestamp = $colltime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
                                        MetricName = 'VMExtensions';
                           VmName=$vm.Name
                          Extension=$extobj.Extension
                         ID=$extobj.id
                                                     SubscriptionId = $subscriptioninfo.subscriptionId
                             AzureSubscription = $SubscriptionInfo.displayName
                                   }
                        }
        }
            }
        If($vm.tags)
         {
    $tags=$null
    $tags=$vm.tags
            foreach ($tag in $tags)
            {
    $tag.PSObject.Properties | foreach-object {
    $name = $_.Name
    $value = $_.value
                    IF ($name -match '-LabUId'){Continue}
                    Write-Verbose     "Adding tag $name : $value to $($VM.name)"
    $cutag=$null
    $cutag=New-Object -ErrorAction Stop PSObject
    $CuVM.psobject.Properties|foreach-object  {
    $cutag|Add-Member -MemberType NoteProperty -Name  $_.Name   -Value $_.value -Force
                }
    $cutag|Add-Member -MemberType NoteProperty -Name Tag  -Value " $name : $value"
                }
    $vmtags = $vmtags + $cutag
           }
         }
      IF($GetDiskInfo)
      {
    $osdisk=$SaforVm=$IOtype=$null
   IF(![string]::IsNullOrEmpty($vm.properties.storageProfile.osDisk.vhd.uri))
    {
    $osdisk=[uri]$vm.properties.storageProfile.osDisk.vhd.uri
    $SaforVm=$SAInventory|where {$_.StorageAccount -eq $osdisk.host.Substring(0,$osdisk.host.IndexOf('.')) }
	    IF($saforvm)
	            {
    $IOtype=$saforvm.tier
	}
    $sizeingb=$null
    $sizeingb=Get-BlobSize -bloburi $([uri]$vm.properties.storageProfile.osDisk.vhd.uri) -storageaccount $saforvm.StorageAccount -rg $SaforVm.ResourceGroup -type ARM
    $cudisk = New-Object -ErrorAction Stop PSObject -Property @{
		        Timestamp = $colltime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
		        MetricName = 'VMDisk';
		        DiskType='Unmanaged'
		        Deploymentname=$vm.id.split('/')[4]   # !!! consider chnaging this to ResourceGroup here or in query
		        DeploymentType='ARM'
		        Location=$vm.location
		        VmName=$vm.Name
		        VHDUri=$vm.properties.storageProfile.osDisk.vhd.uri
		        DiskIOType=$IOtype
		        StorageAccount=$SaforVM.StorageAccount
		        	SubscriptionId = $subscriptioninfo.subscriptionId
        AzureSubscription = $SubscriptionInfo.displayName
		        SizeinGB=$sizeingb
                } -ea 0
	    IF ($cudisk.DiskIOType -eq 'Standard' -and $vm.properties.hardwareProfile.vmSize.ToString() -like  'BAsic*')
	            {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 300
	}ElseIf  ($cudisk.DiskIOType -eq 'Standard' -and $vm.properties.hardwareProfile.vmSize.ToString() -like 'Standard*')
	            {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 500
	}Elseif($IOtype -eq 'Premium')
        {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxVMIO -Value $vmiolimits.Item($vm.properties.hardwareProfile.vmSize)
           if ($cudisk.SizeinGB -le 128 )
           {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 500
           }Elseif ($cudisk.SizeinGB -in  129..512 )
           {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 2300
           }Elseif ($cudisk.SizeinGB -in  513..1024 )
           {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 5000
           }
        }
    $allvhds = $allvhds + $cudisk
    }
    Else
    {
    $cudisk=$null
    $cudisk = New-Object -ErrorAction Stop PSObject -Property @{
		    Timestamp = $colltime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
		    MetricName = 'VMDisk';
		    DiskType='Unmanaged'
		    Deploymentname=$vm.id.split('/')[4]   # !!! consider chnaging this to ResourceGroup here or in query
		    DeploymentType='ARM'
		    Location=$vm.location
		    VmName=$vm.Name
		    Uri=" https://management.azure.com/{0}" -f $vm.properties.storageProfile.osDisk.managedDisk.id
		    StorageAccount=$vm.properties.storageProfile.osDisk.managedDisk.id
		    	SubscriptionId = $subscriptioninfo.subscriptionId
        AzureSubscription = $SubscriptionInfo.displayName
		    SizeinGB=128
                } -ea 0
	    IF ($vm.properties.storageProfile.osDisk.managedDisk.storageAccountType -match 'Standard')
	    {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 500
    $cudisk|Add-Member -MemberType NoteProperty -Name DiskIOType -Value 'Standard'
	    }Elseif($vm.properties.storageProfile.osDisk.managedDisk.storageAccountType -match  'Premium')
        {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxVMIO -Value $vmiolimits.Item($vm.properties.hardwareProfile.vmSize)
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 500
    $cudisk|Add-Member -MemberType NoteProperty -Name DiskIOType -Value 'Premium'
           }
    $allvhds = $allvhds + $cudisk
     }
	iF ($vm.properties.storageProfile.dataDisks)
	{
    $ddisks=$null
    $ddisks=@($vm.properties.storageProfile.dataDisks)
		Foreach($disk in $ddisks)
		{
               IF(![string]::IsNullOrEmpty($disk.vhd.uri))
            {
    $diskuri=$safordisk=$IOtype=$null
    $diskuri=[uri]$disk.vhd.uri
    $safordisk=$SAInventory|where {$_ -match $diskuri.host.Substring(0,$diskuri.host.IndexOf('.')) }
    $IOtype=$safordisk.Tier
    $cudisk = New-Object -ErrorAction Stop PSObject -Property @{
				        Timestamp = $colltime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:ss.fffZ" )
				        MetricName = 'VMDisk';
				        DiskType='Unmanaged'
				        Deploymentname=$vm.id.split('/')[4]
				        DeploymentType='ARM'
				        Location=$vm.location
				        VmName=$vm.Name
				        VHDUri=$disk.vhd.uri
				        DiskIOType=$IOtype
				        StorageAccount=$safordisk.StorageAccount
				        	SubscriptionId = $subscriptioninfo.subscriptionId
        AzureSubscription = $SubscriptionInfo.displayName
				        SizeinGB=$disk.diskSizeGB
			        } -ea 0
			IF ($cudisk.DiskIOType -eq 'Standard' -and $vm.properties.hardwareProfile.vmSize.ToString() -like  'BAsic*')
			{
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 300
			}ElseIf  ($cudisk.DiskIOType -eq 'Standard' -and $vm.properties.hardwareProfile.vmSize.ToString() -like 'Standard*')
			{
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 500
			}Elseif($IOtype -eq 'Premium')
            {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxVMIO -Value $vmiolimits.Item($vm.properties.hardwareProfile.vmSize)
               if ($cudisk.SizeinGB -le 128 )
               {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 500
               }Elseif ($cudisk.SizeinGB -in  129..512 )
               {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 2300
               }Elseif ($cudisk.SizeinGB -in  513..1024 )
               {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 5000
               }
           }
    $allvhds = $allvhds + $cudisk
    		}
            Else
            {
    $cudisk = New-Object -ErrorAction Stop PSObject -Property @{
		            Timestamp = $timestamp
		            MetricName = 'Inventory';
		            DiskType='Managed'
		            Deploymentname=$vm.id.split('/')[4]   # !!! consider chnaging this to ResourceGroup here or in query
		            DeploymentType='ARM'
		            Location=$vm.location
		            VmName=$vm.Name
		            Uri=" https://management.azure.com/{0}" -f $disk.manageddisk.id
		            StorageAccount=$disk.managedDisk.id
		            	SubscriptionId = $subscriptioninfo.subscriptionId
        AzureSubscription = $SubscriptionInfo.displayNamee
		            SizeinGB=$disk.diskSizeGB
                        } -ea 0
               IF ($vm.properties.storageProfile.osDisk.managedDisk.storageAccountType -match 'Standard')
	            {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 500
    $cudisk|Add-Member -MemberType NoteProperty -Name DiskIOType -Value 'Standard'
	            }Elseif($vm.properties.storageProfile.osDisk.managedDisk.storageAccountType -match  'Premium')
                {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxVMIO -Value $vmiolimits.Item($vm.properties.hardwareProfile.vmSize)
    $cudisk|Add-Member -MemberType NoteProperty -Name DiskIOType -Value 'Premium'
                     if ($disk.diskSizeGB -le 128 )
               {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 500
               }Elseif ($disk.diskSizeGB -in  129..512 )
               {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 2300
               }Elseif ($disk.diskSizeGB -in  513..1024 )
               {
    $cudisk|Add-Member -MemberType NoteProperty -Name MaxDiskIO -Value 5000
               }
           }
    $allvhds = $allvhds + $cudisk
            }
        }
	}
    }
}
Write-output " $(get-date) - Starting inventory of Usage data "
    $locations=$loclistcontent=$cu=$null
    $allvmusage=@()
    $loclisturi=" https://management.azure.com/" +$SubscriptionInfo.id+"/locations?api-version=2016-09-01"
    $loclist = Invoke-WebRequest -Uri $loclisturi -Method GET -Headers $Headers -UseBasicParsing
    $loclistcontent= ConvertFrom-Json -InputObject $loclist.Content
    $locations =$loclistcontent
Foreach($loc in $loclistcontent.value.name)
{
    $usgdata=$cu=$usagecontent=$null
    $usageuri=" https://management.azure.com/" +$SubscriptionInfo.id+"/providers/Microsoft.Compute/locations/$(loc) /usages?api-version=2015-06-15"
    $usageapi = Invoke-WebRequest -Uri $usageuri -Method GET -Headers $Headers  -UseBasicParsing
    $usagecontent= ConvertFrom-Json -InputObject $usageapi.Content
Foreach($usgdata in $usagecontent.value)
{
    $cu= New-Object -ErrorAction Stop PSObject -Property @{
                              Timestamp = $timestamp
                             MetricName = 'ARMVMUsageStats';
                            Location = $loc
                            currentValue=$usgdata.currentValue
                            limit=$usgdata.limit
                            Usagemetric = $usgdata.name[0].value.ToString()
                            SubscriptionID = $SubscriptionInfo.id
                            AzureSubscription = $SubscriptionInfo.displayName
                            }
    $allvmusage = $allvmusage + $cu
}
}
    $jsonvmpool = ConvertTo-Json -InputObject $allvms
    $jsonvmtags = ConvertTo-Json -InputObject $vmtags
    $JsonVHDData= ConvertTo-Json -InputObject $allvhds
    $jsonallvmusage = ConvertTo-Json -InputObject $allvmusage
    $jsoninvnic = ConvertTo-Json -InputObject $invnic
    $jsoninvnsg = ConvertTo-Json -InputObject $invnsg;
    $jsoninvendpoint = ConvertTo-Json -InputObject $invendpoints;
    $jsoninveextensions = ConvertTo-Json -InputObject $invextensions
If($jsonvmpool){$postres1=Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonvmpool)) -logType $logname}
	If ($postres1 -ge 200 -and $postres1 -lt 300)
	{
		Write-Output "Succesfully uploaded $($allvms.count) vm inventory   to OMS"
	}
	Else
	{
		Write-Warning "Failed to upload  $($allvms.count) vm inventory   to OMS"
	}
If($jsonvmtags){$postres2=Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonvmtags)) -logType $logname}
	If ($postres2 -ge 200 -and $postres2 -lt 300)
	{
		Write-Output "Succesfully uploaded $($vmtags.count) vm tags  to OMS"
	}
	Else
	{
		Write-Warning "Failed to upload  $($vmtags.count) vm tags   to OMS"
	}
If($jsonallvmusage){$postres3=Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonallvmusage)) -logType $logname}
	If ($postres3 -ge 200 -and $postres3 -lt 300)
	{
		Write-Output "Succesfully uploaded $($allvmusage.count) vm core usage  metrics to OMS"
	}
	Else
	{
		Write-Warning "Failed to upload  $($allvmusage.count) vm core usage  metrics to OMS"
	}
If($JsonVHDData){$postres4=Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($JsonVHDData)) -logType $logname}
	If ($postres4 -ge 200 -and $postres4 -lt 300)
	{
		Write-Output "Succesfully uploaded $($allvhds.count) disk usage metrics to OMS"
	}
	Else
	{
		Write-Warning "Failed to upload  $($allvhds.count) Disk metrics to OMS"
	}
If($jsoninvnic){$postres5=Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsoninvnic)) -logType $logname}
	If ($postres5 -ge 200 -and $postres5 -lt 300)
	{
		Write-Output "Succesfully uploaded $($invnic.count) NICs to OMS"
	}
	Else
	{
		Write-Warning "Failed to upload  $($invnic.count) NICs to OMS"
	}
If($jsoninvnsg){$postres6=Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsoninvnsg)) -logType $logname}
	If ($postres6 -ge 200 -and $postres6 -lt 300)
	{
		Write-Output "Succesfully uploaded $($invnsg.count) NSG metrics to OMS"
	}
	Else
	{
		Write-Warning "Failed to upload  $($invnsg.count) NSG metrics to OMS"
	}
If($jsoninvendpoint){$postres7=Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsoninvendpoint)) -logType $logname}
	If ($postres7 -ge 200 -and $postres7 -lt 300)
	{
		Write-Output "Succesfully uploaded $($invendpoints.count) input endpoint metrics to OMS"
	}
	Else
	{
		Write-Warning "Failed to upload  $($invendpoints.count) input endpoint metrics to OMS"
	}
If($jsoninveextensions){$postres8=Post-OMSData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsoninveextensions)) -logType $logname}
	If ($postres8 -ge 200 -and $postres8 -lt 300)
	{
		Write-Output "Succesfully uploaded $($invendpoints.count) extensionsto OMS"
	}
	Else
	{
		Write-Warning "Failed to upload  $($invendpoints.count) extensions  to OMS"
	}
Write-output " $(get-date) - Uploading all data to OMS  "



