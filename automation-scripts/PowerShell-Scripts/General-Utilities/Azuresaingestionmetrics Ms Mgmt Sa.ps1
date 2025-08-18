<#
.SYNOPSIS
    Azuresaingestionmetrics Ms Mgmt Sa

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azuresaingestionmetrics Ms Mgmt Sa

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
[Parameter(Mandatory=$false)] [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESubscriptionidFilter,
[Parameter(Mandatory=$false)] [bool] $collectionFromAllSubscriptions=$false,
[Parameter(Mandatory=$false)] [bool] $getAsmHeader=$true)


$WEErrorActionPreference= " Stop"

Write-Output " RB Initial Memory  : $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB" 



$WEStartTime = [dateTime]::Now
$WETimestampfield = " Timestamp"


$timestamp=$WEStartTime.ToUniversalTime().ToString(" yyyy-MM-ddTHH:mm:00.000Z" )



$customerID = Get-AutomationVariable -Name 'AzureSAIngestion-OPSINSIGHTS_WS_ID-MS-Mgmt-SA'


$sharedKey = Get-AutomationVariable -Name 'AzureSAIngestion-OPSINSIGHTS_WS_KEY-MS-Mgmt-SA'



$WEApiVerSaAsm = '2016-04-01'
$WEApiVerSaArm = '2016-01-01'
$WEApiStorage='2016-05-31'




$WEAAAccount = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationAccount-MS-Mgmt-SA'

$WEAAResourceGroup = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationResourceGroup-MS-Mgmt-SA'



$logname='AzureStorage'




$hash = [hashtable]::New(@{})

$WEStarttimer=get-date




Function Build-tableSignature ($customerId, $sharedKey, $date,  $method,  $resource,$uri)
{
	$stringToHash = $method + " `n" + " `n" + " `n" +$date+" `n" +" /" +$resource+$uri.AbsolutePath
	Add-Type -AssemblyName System.Web
	$query = [System.Web.HttpUtility]::ParseQueryString($uri.query)  
	$querystr=''
	$bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
	$keyBytes = [Convert]::FromBase64String($sharedKey)
	$sha256 = New-Object System.Security.Cryptography.HMACSHA256
	$sha256.Key = $keyBytes
	$calculatedHash = $sha256.ComputeHash($bytesToHash)
	$encodedHash = [Convert]::ToBase64String($calculatedHash)
; 	$authorization = 'SharedKey {0}:{1}' -f $resource,$encodedHash
	return $authorization
	
}

Function Build-StorageSignature ($sharedKey, $date,  $method, $bodylength, $resource,$uri ,$service)
{
	Add-Type -AssemblyName System.Web
; 	$str=  New-Object -TypeName " System.Text.StringBuilder" ;
	$builder=  [System.Text.StringBuilder]::new(" /" )
	$builder.Append($resource) |out-null
	$builder.Append($uri.AbsolutePath) | out-null
	$str.Append($builder.ToString()) | out-null
; 	$values2=@{}
	IF($service -eq 'Table')
	{
	; 	$values= [System.Web.HttpUtility]::ParseQueryString($uri.query)  
		#    NameValueCollection values = HttpUtility.ParseQueryString(address.Query);
		foreach ($str2 in $values.Keys)
		{
			[System.Collections.ArrayList]$list=$values.GetValues($str2)
			$list.sort()
		; 	$builder2=  [System.Text.StringBuilder]::new()
			
			foreach ($obj2 in $list)
			{
				if ($builder2.Length -gt 0)
				{
					$builder2.Append(" ," );
				}
				$builder2.Append($obj2.ToString()) |Out-Null
			}
			IF ($str2 -ne $null)
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
			; 	$builder3=[System.Text.StringBuilder]::new()
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
	; 	$values= [System.Web.HttpUtility]::ParseQueryString($uri.query)  
		#    NameValueCollection values = HttpUtility.ParseQueryString(address.Query);
		foreach ($str2 in $values.Keys)
		{
			[System.Collections.ArrayList]$list=$values.GetValues($str2)
			$list.sort()
		; 	$builder2=  [System.Text.StringBuilder]::new()
			
			foreach ($obj2 in $list)
			{
				if ($builder2.Length -gt 0)
				{
					$builder2.Append(" ," );
				}
				$builder2.Append($obj2.ToString()) |Out-Null
			}
			IF ($str2 -ne $null)
			{
				$values2.add($str2.ToLowerInvariant(),$builder2.ToString())
			} 
		}
		
		$list2=[System.Collections.ArrayList]::new($values2.Keys)
		$list2.sort()
		foreach ($str3 in $list2)
		{
			
		; 	$builder3=[System.Text.StringBuilder]::new()
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
	$xHeaders = " x-ms-date:" + $date+ " `n" +" x-ms-version:$WEApiStorage"
	if ($service -eq 'Table')
	{
		$stringToHash= $method + " `n" + " `n" + " `n" +$date+" `n" +$str.ToString()
	}
	Else
	{
		IF ($method -eq 'GET' -or $method -eq 'HEAD')
		{
			$stringToHash = $method + " `n" + " `n" + " `n" + " `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" +$xHeaders+" `n" +$str.ToString()
		}
		Else
		{
			$stringToHash = $method + " `n" + " `n" + " `n" +$bodylength+ " `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" +$xHeaders+" `n" +$str.ToString()
		}     
	}
	##############
	

	$bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
	$keyBytes = [Convert]::FromBase64String($sharedKey)
	$sha256 = New-Object System.Security.Cryptography.HMACSHA256
	$sha256.Key = $keyBytes
	$calculatedHash = $sha256.ComputeHash($bytesToHash)
	$encodedHash = [Convert]::ToBase64String($calculatedHash)
	$authorization = 'SharedKey {0}:{1}' -f $resource,$encodedHash
	return $authorization
	
}

Function invoke-StorageREST($sharedKey, $method, $msgbody, $resource,$uri,$svc,$download)
{

	$rfc1123date = [DateTime]::UtcNow.ToString(" r" )

	
	If ($method -eq 'PUT')
	{$signature = Build-StorageSignature `
		-sharedKey $sharedKey `
		-date  $rfc1123date `
		-method $method -resource $resource -uri $uri -bodylength $msgbody.length -service $svc
	}Else
	{

	; 	$signature = Build-StorageSignature `
		-sharedKey $sharedKey `
		-date  $rfc1123date `
		-method $method -resource $resource -uri $uri -body $body -service $svc
	} 

	If($svc -eq 'Table')
	{
	; 	$headersforsa=  @{
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
			'x-ms-version'=" $WEApiStorage"
		}
	}
	




	IF($download)
	{
		$resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody  -OutFile " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"

		
		#$xresp=Get-Content " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
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


function WE-Get-BlobSize ($bloburi,$storageaccount,$rg,$type)
{

	If($type -eq 'ARM')
	{
		$WEUri=" https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.Storage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $WEApiVerSaArm, $storageaccount,$rg,$WESubscriptionId 
		$keyresp=Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
		$keys=ConvertFrom-Json -InputObject $keyresp.Content
		$prikey=$keys.keys[0].value
	}Elseif($type -eq 'Classic')
	{
		$WEUri=" https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.ClassicStorage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $WEApiVerSaAsm,$storageaccount,$rg,$WESubscriptionId 
		$keyresp=Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
		$keys=ConvertFrom-Json -InputObject $keyresp.Content
		$prikey=$keys.primaryKey
	}Else
	{
		" Could not detect storage account type, $storageaccount will not be processed"
		Continue
	}





	$vhdblob=invoke-StorageREST -sharedKey $prikey -method HEAD -resource $storageaccount -uri $bloburi
	
	Return [math]::round($vhdblob.Headers.'Content-Length'/1024/1024/1024,0)



}		

Function Build-OMSSignature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
{
	$xHeaders = " x-ms-date:" + $date
	$stringToHash = $method + " `n" + $contentLength + " `n" + $contentType + " `n" + $xHeaders + " `n" + $resource
	$bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
	$keyBytes = [Convert]::FromBase64String($sharedKey)
	$sha256 = New-Object System.Security.Cryptography.HMACSHA256
	$sha256.Key = $keyBytes
	$calculatedHash = $sha256.ComputeHash($bytesToHash)
	$encodedHash = [Convert]::ToBase64String($calculatedHash)
	$authorization = 'SharedKey {0}:{1}' -f $customerId,$encodedHash
	return $authorization
}

Function Post-OMSData($customerId, $sharedKey, $body, $logType)
{


	#usage     Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
	$method = " POST"
	$contentType = " application/json"
	$resource = " /api/logs"
	$rfc1123date = [DateTime]::UtcNow.ToString(" r" )
	$contentLength = $body.Length
	$signature = Build-OMSSignature `
	-customerId $customerId `
	-sharedKey $sharedKey `
	-date $rfc1123date `
	-contentLength $contentLength `
	-fileName $fileName `
	-method $method `
	-contentType $contentType `
	-resource $resource
; 	$uri = " https://" + $customerId + " .ods.opinsights.azure.com" + $resource + " ?api-version=2016-04-01"
; 	$WEOMSheaders = @{
		" Authorization" = $signature;
		" Log-Type" = $logType;
		" x-ms-date" = $rfc1123date;
		" time-generated-field" = $WETimeStampField;
	}

	Try{
		$response = Invoke-WebRequest -Uri $uri -Method POST  -ContentType $contentType -Headers $WEOMSheaders -Body $body -UseBasicParsing
	}catch [Net.WebException] 
	{
	; 	$ex=$_.Exception
		If ($_.Exception.Response.StatusCode.value__) {
		; 	$exrespcode = ($_.Exception.Response.StatusCode.value__ ).ToString().Trim();
			#Write-Output $crap;
		}
		If  ($_.Exception.Message) {
			$exMessage = ($_.Exception.Message).ToString().Trim();
			#Write-Output $crapMessage;
		}
		$errmsg= " $exrespcode : $exMessage"
	}

	if ($errmsg){return $errmsg }
	Else{	return $response.StatusCode }
	#write-output $response.StatusCode
	Write-error $error[0]
}


function WE-Cleanup-Variables {

	Get-Variable |

	Where-Object { $startupVariables -notcontains $_.Name } |

	% { Remove-Variable -Name “$($_.Name)” -Force -Scope “global” }

}





" Logging in to Azure..."
$WEArmConn = Get-AutomationConnection -Name AzureRunAsConnection 

if ($WEArmConn  -eq $null)
{
	throw " Could not retrieve connection asset AzureRunAsConnection,  Ensure that runas account  exists in the Automation account."
}


$retry = 6
$syncOk = $false
do
{ 
	try
	{  
		Add-AzureRMAccount -ServicePrincipal -Tenant $WEArmConn.TenantID -ApplicationId $WEArmConn.ApplicationID -CertificateThumbprint $WEArmConn.CertificateThumbprint
		$syncOk = $true
	}
	catch
	{
		$WEErrorMessage = $_.Exception.Message
		$WEStackTrace = $_.Exception.StackTrace
		Write-Warning " Error during sync: $WEErrorMessage, stack: $WEStackTrace. Retry attempts left: $retry"
		$retry = $retry - 1       
		Start-Sleep -s 60        
	}
} while (-not $syncOk -and $retry -ge 0)
" Selecting Azure subscription..."
$WESelectedAzureSub = Select-AzureRmSubscription -SubscriptionId $WEArmConn.SubscriptionId -TenantId $WEArmConn.tenantid 

$subscriptionid=$WEArmConn.SubscriptionId
" Azure rm profile path  $((get-module -Name AzureRM.Profile).path) "
$path=(get-module -Name AzureRM.Profile).path
$path=Split-Path $path
$dlllist=Get-ChildItem -Path $path  -Filter Microsoft.IdentityModel.Clients.ActiveDirectory.dll  -Recurse
$adal =  $dlllist[0].VersionInfo.FileName
try
{
	Add-type -Path $adal
	[reflection.assembly]::LoadWithPartialName( " Microsoft.IdentityModel.Clients.ActiveDirectory" )
}
catch
{
	$WEErrorMessage = $_.Exception.Message
	$WEStackTrace = $_.Exception.StackTrace
	Write-Warning " Error during sync: $WEErrorMessage, stack: $WEStackTrace. "
}

$certs= Get-ChildItem -Path Cert:\Currentuser\my -Recurse | Where{$_.Thumbprint -eq $WEArmConn.CertificateThumbprint}

[System.Security.Cryptography.X509Certificates.X509Certificate2]$mycert=$certs[0]

$WECliCert=new-object   Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate($WEArmConn.ApplicationId,$mycert)
$WEAuthContext = new-object Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext(" https://login.windows.net/$($WEArmConn.tenantid)" )
$result = $WEAuthContext.AcquireToken(" https://management.core.windows.net/" ,$WECliCert); 
$header = " Bearer " + $result.AccessToken; 
$headers = @{" Authorization" =$header;" Accept" =" application/json" }
$body=$null
$WEHTTPVerb=" GET"
$subscriptionInfoUri = " https://management.azure.com/subscriptions/" +$subscriptionid+" ?api-version=2016-02-01"
$subscriptionInfo = Invoke-RestMethod -Uri $subscriptionInfoUri -Headers $headers -Method Get -UseBasicParsing
IF($subscriptionInfo)
{
	" Successfully connected to Azure ARM REST"
}



if ($getAsmHeader) {
    
	try
    {
        $WEAsmConn = Get-AutomationConnection -Name AzureClassicRunAsConnection -ea 0
       
    }
    Catch
    {
        if ($WEAsmConn -eq $null) {
            Write-Warning " Could not retrieve connection asset AzureClassicRunAsConnection. Ensure that runas account exist and valid in the Automation account."
            $getAsmHeader=$false
        }
    }
     if ($WEAsmConn -eq $null) {
        Write-Warning " Could not retrieve connection asset AzureClassicRunAsConnection. Ensure that runas account exist and valid in the Automation account. Quota usage infomration for classic accounts will no tbe collected"
        $getAsmHeader=$false
    }Else{

        $WECertificateAssetName = $WEAsmConn.CertificateAssetName
        $WEAzureCert = Get-AutomationCertificate -Name $WECertificateAssetName
        if ($WEAzureCert -eq $null)
        {
            Write-Warning  " Could not retrieve certificate asset: $WECertificateAssetName. Ensure that this asset exists and valid  in the Automation account."
            $getAsmHeader=$false
        }
        Else{

        " Logging into Azure Service Manager"
        Write-Verbose " Authenticating to Azure with certificate." -Verbose
        Set-AzureSubscription -SubscriptionName $WEAsmConn.SubscriptionName -SubscriptionId $WEAsmConn.SubscriptionId -Certificate $WEAzureCert
        Select-AzureSubscription -SubscriptionId $WEAsmConn.SubscriptionId
        #finally create the headers for ASM REST 
        $headerasm = @{" x-ms-version" =" 2013-08-01" }
        }
    }

}





$WESubscriptionsURI=" https://management.azure.com/subscriptions?api-version=2016-06-01" 
$WESubscriptions = Invoke-RestMethod -Uri  $WESubscriptionsURI -Method GET  -Headers $headers -UseBasicParsing 
$WESubscriptions=@($WESubscriptions.value)


IF($collectionFromAllSubscriptions -and $WESubscriptions.count -gt 1 )
{
	Write-Output " $($WESubscriptions.count) Subscription found , additonal runbook jobs will be created to collect data "
	$WEAAResourceGroup = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationResourceGroup-MS-Mgmt-SA'
	$WEAAAccount = Get-AutomationVariable -Name 'AzureSAIngestion-AzureAutomationAccount-MS-Mgmt-SA'
	$WEMetricsRunbookName = " AzureSAIngestionMetrics-MS-Mgmt-SA"

	#we will process first subscription with this runbook and  pass the rest to additional jobs

	$n=$WESubscriptions.count-1
	#$subslist=$WESubscriptions[-$n..-1]
	#remove existing subsription from list 
; 	$subslist=$subscriptions|where {$_.subscriptionId  -ne $subscriptionId}
	Foreach($item in $subslist)
	{

	; 	$params1 = @{" SubscriptionidFilter" =$item.subscriptionId;" collectionFromAllSubscriptions" = $false;" getAsmHeader" =$false}
		Start-AzureRmAutomationRunbook -AutomationAccountName $WEAAAccount -Name $WEMetricsRunbookName -ResourceGroupName $WEAAResourceGroup -Parameters $params1 | out-null
	}
}






" $(GEt-date) - Get ARM storage Accounts "

$WEUri=" https://management.azure.com/subscriptions/{1}/providers/Microsoft.Storage/storageAccounts?api-version={0}"   -f  $WEApiVerSaArm,$WESubscriptionId 
$armresp=Invoke-RestMethod -Uri $uri -Method GET  -Headers $headers -UseBasicParsing
$saArmList=$armresp.Value
" $(GEt-date)  $($saArmList.count) classic storage accounts found"



" $(GEt-date)  Get Classic storage Accounts "

$WEUri=" https://management.azure.com/subscriptions/{1}/providers/Microsoft.ClassicStorage/storageAccounts?api-version={0}"   -f  $WEApiVerSaAsm,$WESubscriptionId 

$asmresp=Invoke-RestMethod -Uri $uri -Method GET  -Headers $headers -UseBasicParsing
$saAsmList=$asmresp.value

" $(GEt-date)  $($saAsmList.count) storage accounts found"





$colParamsforChild=@()

foreach($sa in $saArmList|where {$_.Sku.tier -ne 'Premium'})
{

; 	$rg=$sku=$null

; 	$rg=$sa.id.Split('/')[4]

; 	$colParamsforChild = $colParamsforChild + " $($sa.name);$($sa.id.Split('/')[4]);ARM;$($sa.sku.tier);$($sa.Kind)"
	
}


$sa=$rg=$null

foreach($sa in $saAsmList|where{$_.properties.accounttype -notmatch 'Premium'})
{

	$rg=$sa.id.Split('/')[4]
; 	$tier=$null



	If( $sa.properties.accountType -notmatch 'premium')
	{
	; 	$tier='Standard'
	; 	$colParamsforChild = $colParamsforChild + " $($sa.name);$($sa.id.Split('/')[4]);Classic;$tier;$($sa.Kind)"
	}

	

}


Write-Output " Core Count  $([System.Environment]::ProcessorCount)"



if($colParamsforChild.count -eq 0)
{
	Write-Output " No Storage account found under subscription $subscriptionid , please note that Premium storage does not support metrics and excluded from the collection!"
	exit
}





$WESAInventory=@()
$sa=$null

foreach($sa in $saArmList)
{
	$rg=$sa.id.Split('/')[4]
; 	$cu=$null
; 	$cu = New-Object PSObject -Property @{
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
		
		SubscriptionId = $WEArmConn.SubscriptionId;
		AzureSubscription = $subscriptionInfo.displayName
	}
	
	IF ($sa.properties.creationTime){$cu|Add-Member -MemberType NoteProperty -Name CreationTime -Value $sa.properties.creationTime}
	IF ($sa.properties.primaryLocation){$cu|Add-Member -MemberType NoteProperty -Name PrimaryLocation -Value $sa.properties.primaryLocation}
	IF ($sa.properties.secondaryLocation){$cu|Add-Member -MemberType NoteProperty -Name secondaryLocation-Value $sa.properties.secondaryLocation}
	IF ($sa.properties.statusOfPrimary){$cu|Add-Member -MemberType NoteProperty -Name statusOfPrimary -Value $sa.properties.statusOfPrimary}
	IF ($sa.properties.statusOfSecondary){$cu|Add-Member -MemberType NoteProperty -Name statusOfSecondary -Value $sa.properties.statusOfSecondary}
	IF ($sa.kind -eq 'BlobStorage'){$cu|Add-Member -MemberType NoteProperty -Name accessTier -Value $sa.properties.accessTier}
	IF ($t.properties.encryption.services.blob){$cu|Add-Member -MemberType NoteProperty -Name blobEncryption -Value 'enabled'}
	IF ($t.properties.encryption.services.file){$cu|Add-Member -MemberType NoteProperty -Name fileEncryption -Value 'enabled'}
	$WESAInventory = $WESAInventory + $cu
}

foreach($sa in $saAsmList)
{
	$rg=$sa.id.Split('/')[4]
; 	$cu=$iotype=$null
	IF($sa.properties.accountType -like 'Standard*')
	{$iotype='Standard'}Else{$iotype='Premium'}
; 	$cu = New-Object PSObject -Property @{
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
		SubscriptionId = $WEArmConn.SubscriptionId;
		AzureSubscription = $subscriptionInfo.displayName
	}
	
	IF ($sa.properties.creationTime){$cu|Add-Member -MemberType NoteProperty -Name CreationTime -Value $sa.properties.creationTime}
	IF ($sa.properties.geoPrimaryRegion){$cu|Add-Member -MemberType NoteProperty -Name PrimaryLocation -Value $sa.properties.geoPrimaryRegion.Replace(' ','')}
	IF ($sa.properties.geoSecondaryRegion ){$cu|Add-Member -MemberType NoteProperty -Name SecondaryLocation-Value $sa.properties.geoSecondaryRegion.Replace(' ','')}
	IF ($sa.properties.statusOfPrimaryRegion){$cu|Add-Member -MemberType NoteProperty -Name statusOfPrimary -Value $sa.properties.statusOfPrimaryRegion}
	IF ($sa.properties.statusOfSecondaryRegion){$cu|Add-Member -MemberType NoteProperty -Name statusOfSecondary -Value $sa.properties.statusOfSecondaryRegion}
	
	$WESAInventory = $WESAInventory + $cu
}

$jsonSAInventory = ConvertTo-Json -InputObject $WESAInventory
If($jsonSAInventory){Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonSAInventory)) -logType $logname}
" $(get-date)  - SA Inventory  data  uploaded"



$quotas=@()

IF($getAsmHeader)
{
	$uri=" https://management.core.windows.net/$subscriptionId"
; 	$qresp=Invoke-WebRequest -Uri $uri -Method GET  -Headers $headerasm -UseBasicParsing -Certificate $WEAzureCert
	[xml]$qres=$qresp.Content
	[int]$WESAMAX=$qres.Subscription.MaxStorageAccounts
	[int]$WESACurrent=$qres.Subscription.CurrentStorageAccounts
; 	$WEQuotapct=$qres.Subscription.CurrentStorageAccounts/$qres.Subscription.MaxStorageAccounts*100  
; 	$quotas = $quotas + New-Object PSObject -Property @{
		Timestamp = $timestamp
		MetricName = 'StorageQuotas';
		QuotaType=" Classic"
		SAMAX=$samax
		SACurrent=$WESACurrent
		Quotapct=$WEQuotapct     
		SubscriptionId = $WEArmConn.SubscriptionId;
		AzureSubscription = $subscriptionInfo.displayName;
		
	}
}

$WESAMAX=$WESACurrent=$WESAquotapct=$null
$usageuri=" https://management.azure.com/subscriptions/" +$subscriptionid+" /providers/Microsoft.Storage/usages?api-version=2016-05-01"
$usageapi = Invoke-RestMethod -Uri $usageuri -Method GET -Headers $WEHeaders  -UseBasicParsing; 
$usagecontent=$usageapi.value; 
$WESAquotapct=$usagecontent[0].currentValue/$usagecontent[0].Limit*100
[int]$WESAMAX=$usagecontent[0].limit
[int]$WESACurrent=$usagecontent[0].currentValue
; 
$quotas = $quotas + New-Object PSObject -Property @{
	Timestamp = $timestamp
	MetricName = 'StorageQuotas';
	QuotaType=" ARM"
	SAMAX=$WESAMAX
	SACurrent=$WESACurrent
	Quotapct=$WESAquotapct     
	SubscriptionId = $WEArmConn.SubscriptionId;
	AzureSubscription = $subscriptionInfo.displayName;
	
}

$jsonquotas = ConvertTo-Json -InputObject $quotas
If($jsonquotas){Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonquotas)) -logType $logname}
" $(get-date)  - Quota info uploaded"







$hash = [hashtable]::New(@{})
$hash['Host']=$host
$hash['subscriptionInfo']=$subscriptionInfo
$hash['ArmConn']=$WEArmConn
$hash['AsmConn']=$WEAsmConn
$hash['headers']=$headers
$hash['headerasm']=$headers
$hash['AzureCert']=$WEAzureCert
$hash['Timestampfield']=$WETimestampfield
$hash['customerID'] =$customerID
$hash['syncInterval']=$syncInterval
$hash['sharedKey']=$sharedKey 
$hash['Logname']=$logname
$hash['ApiVerSaAsm']=$WEApiVerSaAsm
$hash['ApiVerSaArm']=$WEApiVerSaArm
$hash['ApiStorage']=$WEApiStorage
$hash['AAAccount']=$WEAAAccount
$hash['AAResourceGroup']=$WEAAResourceGroup

$hash['debuglog']=$true

$hash['saTransactionsMetrics']=@()
$hash['saCapacityMetrics']=@()
$hash['tableInventory']=@()
$hash['fileInventory']=@()
$hash['queueInventory']=@()
$hash['vhdinventory']=@()

$WESAInfo=@()
$hash.'SAInfo'=$sainfo

$WEThrottle = [int][System.Environment]::ProcessorCount+1  #threads

$sessionstate = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
$runspacepool = [runspacefactory]::CreateRunspacePool(1, $WEThrottle, $sessionstate, $WEHost)
$runspacepool.Open() 
[System.Collections.ArrayList]$WEJobs = @()




$scriptBlockGetKeys={

	Param ($hash,[array]$WESa,$rsid)

	$subscriptionInfo=$hash.subscriptionInfo
	$WEArmConn=$hash.ArmConn
	$headers=$hash.headers
	$WEAsmConn=$hash.AsmConn
	$headerasm=$hash.headerasm
	$WEAzureCert=$hash.AzureCert

	$WETimestampfield = $hash.Timestampfield

	$WECurrency=$hash.Currency
	$WELocale=$hash.Locale
	$WERegionInfo=$hash.RegionInfo
	$WEOfferDurableId=$hash.OfferDurableId
	$syncInterval=$WEHash.syncInterval
	$customerID =$hash.customerID 
	$sharedKey = $hash.sharedKey
	$logname=$hash.Logname
	$WEStartTime = [dateTime]::Now
	$WEApiVerSaAsm = $hash.ApiVerSaAsm
	$WEApiVerSaArm = $hash.ApiVerSaArm
	$WEApiStorage=$hash.ApiStorage
	$WEAAAccount = $hash.AAAccount
	$WEAAResourceGroup = $hash.AAResourceGroup
	$debuglog=$hash.deguglog




	$varQueueList=" AzureSAIngestion-List-Queues"
	$varFilesList=" AzureSAIngestion-List-Files"

	$subscriptionId=$subscriptionInfo.subscriptionId






	Function Build-tableSignature ($customerId, $sharedKey, $date,  $method,  $resource,$uri)
	{
		$stringToHash = $method + " `n" + " `n" + " `n" +$date+" `n" +" /" +$resource+$uri.AbsolutePath
		Add-Type -AssemblyName System.Web
		$query = [System.Web.HttpUtility]::ParseQueryString($uri.query)  
		$querystr=''
		$bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
		$keyBytes = [Convert]::FromBase64String($sharedKey)
		$sha256 = New-Object System.Security.Cryptography.HMACSHA256
		$sha256.Key = $keyBytes
		$calculatedHash = $sha256.ComputeHash($bytesToHash)
		$encodedHash = [Convert]::ToBase64String($calculatedHash)
	; 	$authorization = 'SharedKey {0}:{1}' -f $resource,$encodedHash
		return $authorization
		
	}

	Function Build-StorageSignature ($sharedKey, $date,  $method, $bodylength, $resource,$uri ,$service)
	{
		Add-Type -AssemblyName System.Web
	; 	$str=  New-Object -TypeName " System.Text.StringBuilder" ;
		$builder=  [System.Text.StringBuilder]::new(" /" )
		$builder.Append($resource) |out-null
		$builder.Append($uri.AbsolutePath) | out-null
		$str.Append($builder.ToString()) | out-null
	; 	$values2=@{}
		IF($service -eq 'Table')
		{
		; 	$values= [System.Web.HttpUtility]::ParseQueryString($uri.query)  
			#    NameValueCollection values = HttpUtility.ParseQueryString(address.Query);
			foreach ($str2 in $values.Keys)
			{
				[System.Collections.ArrayList]$list=$values.GetValues($str2)
				$list.sort()
			; 	$builder2=  [System.Text.StringBuilder]::new()
				
				foreach ($obj2 in $list)
				{
					if ($builder2.Length -gt 0)
					{
						$builder2.Append(" ," );
					}
					$builder2.Append($obj2.ToString()) |Out-Null
				}
				IF ($str2 -ne $null)
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
				; 	$builder3=[System.Text.StringBuilder]::new()
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
		; 	$values= [System.Web.HttpUtility]::ParseQueryString($uri.query)  
			#    NameValueCollection values = HttpUtility.ParseQueryString(address.Query);
			foreach ($str2 in $values.Keys)
			{
				[System.Collections.ArrayList]$list=$values.GetValues($str2)
				$list.sort()
			; 	$builder2=  [System.Text.StringBuilder]::new()
				
				foreach ($obj2 in $list)
				{
					if ($builder2.Length -gt 0)
					{
						$builder2.Append(" ," );
					}
					$builder2.Append($obj2.ToString()) |Out-Null
				}
				IF ($str2 -ne $null)
				{
					$values2.add($str2.ToLowerInvariant(),$builder2.ToString())
				} 
			}
			
			$list2=[System.Collections.ArrayList]::new($values2.Keys)
			$list2.sort()
			foreach ($str3 in $list2)
			{
				
			; 	$builder3=[System.Text.StringBuilder]::new()
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
		$xHeaders = " x-ms-date:" + $date+ " `n" +" x-ms-version:$WEApiStorage"
		if ($service -eq 'Table')
		{
			$stringToHash= $method + " `n" + " `n" + " `n" +$date+" `n" +$str.ToString()
		}
		Else
		{
			IF ($method -eq 'GET' -or $method -eq 'HEAD')
			{
				$stringToHash = $method + " `n" + " `n" + " `n" + " `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" +$xHeaders+" `n" +$str.ToString()
			}
			Else
			{
				$stringToHash = $method + " `n" + " `n" + " `n" +$bodylength+ " `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" +$xHeaders+" `n" +$str.ToString()
			}     
		}
		##############
		

		$bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
		$keyBytes = [Convert]::FromBase64String($sharedKey)
		$sha256 = New-Object System.Security.Cryptography.HMACSHA256
		$sha256.Key = $keyBytes
		$calculatedHash = $sha256.ComputeHash($bytesToHash)
		$encodedHash = [Convert]::ToBase64String($calculatedHash)
		$authorization = 'SharedKey {0}:{1}' -f $resource,$encodedHash
		return $authorization
		
	}

	Function invoke-StorageREST($sharedKey, $method, $msgbody, $resource,$uri,$svc,$download)
	{

		$rfc1123date = [DateTime]::UtcNow.ToString(" r" )

		
		If ($method -eq 'PUT')
		{$signature = Build-StorageSignature `
			-sharedKey $sharedKey `
			-date  $rfc1123date `
			-method $method -resource $resource -uri $uri -bodylength $msgbody.length -service $svc
		}Else
		{

		; 	$signature = Build-StorageSignature `
			-sharedKey $sharedKey `
			-date  $rfc1123date `
			-method $method -resource $resource -uri $uri -body $body -service $svc
		} 

		If($svc -eq 'Table')
		{
		; 	$headersforsa=  @{
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
				'x-ms-version'=" $WEApiStorage"
			}
		}
		




		IF($download)
		{
			$resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody  -OutFile " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"

			
			#$xresp=Get-Content " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
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





; 	$prikey=$storageaccount=$rg=$type=$null
; 	$storageaccount =$sa.Split(';')[0]
	$rg=$sa.Split(';')[1]
	$type=$sa.Split(';')[2]
	$tier=$sa.Split(';')[3]
	$kind=$sa.Split(';')[4]


	If($type -eq 'ARM')
	{
		$WEUri=" https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.Storage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $WEApiVerSaArm, $storageaccount,$rg,$WESubscriptionId 
		$keyresp=Invoke-RestMethod -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
		$prikey=$keyresp.keys[0].value


	}Elseif($type -eq 'Classic')
	{
		$uri=$keyresp=$null
		$WEUri=" https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.ClassicStorage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $WEApiVerSaAsm,$storageaccount,$rg,$WESubscriptionId 
		$keyresp=Invoke-RestMethod -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
		$prikey=$keyresp.primaryKey


	}Else
	{
		
		" Could not detect storage account type, $storageaccount will not be processed"
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


		
		[uri]$uriSvcProp = " https://{0}.{1}.core.windows.net/?restype=service&comp=properties	" -f $storageaccount,$svc

		IF($svc -eq 'table')
		{
			[xml]$WESvcPropResp= invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $uriSvcProp -svc Table
			
		}else
		{
			[xml]$WESvcPropResp= invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $uriSvcProp 
			
		}

		IF($WESvcPropResp.StorageServiceProperties.Logging.Read -eq 'true' -or $WESvcPropResp.StorageServiceProperties.Logging.Write -eq 'true' -or $WESvcPropResp.StorageServiceProperties.Logging.Delete -eq 'true')
		{
			$msg=" Logging is enabled for {0} in {1}" -f $svc,$storageaccount
			#Write-output $msg

			$logging=$true

			

			
		}
		Else {
			$msg=" Logging is not  enabled for {0} in {1}" -f $svc,$storageaccount

		}


	}


	$hash.SAInfo+=New-Object PSObject -Property @{
		StorageAccount = $storageaccount
		Key=$prikey
		Logging=$logging
		Rg=$rg
		Type=$type
		Tier=$tier
		Kind=$kind

	}


}

Write-Output " After Runspace creation  $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
write-output " $($colParamsforChild.count) objects will be processed "

$i=1 
$WEStarttimer=get-date
$colParamsforChild|foreach{

	$splitmetrics=$null
	$splitmetrics=$_
	$WEJob = [powershell]::Create().AddScript($scriptBlockGetKeys).AddArgument($hash).AddArgument($splitmetrics).Addargument($i)
	$WEJob.RunspacePool = $WERunspacePool
	$WEJobs = $WEJobs + New-Object PSObject -Property @{
		RunNum = $i
		Pipe = $WEJob
		Result = $WEJob.BeginInvoke()

	}
	
	$i++
}

write-output  " $(get-date)  , started $i Runspaces "
Write-Output " After dispatching runspaces $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
$jobsClone=$jobs.clone()
Write-Output " Waiting.."



$s=1
Do {

	Write-Output "  $(@($jobs.result.iscompleted|where{$_  -match 'False'}).count)  jobs remaining"

	foreach ($jobobj in $WEJobsClone)
	{

		if ($WEJobobj.result.IsCompleted -eq $true)
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
		Write-Output " Job $s - Mem: $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
	}  
	$s++
	
	Start-Sleep -Seconds 15


} While ( @($jobs.result.iscompleted|where{$_  -match 'False'}).count -gt 0)
Write-output " All jobs completed!"


$jobs|foreach{$_.Pipe.Dispose()}


if(Get-Variable -Name Jobs ){Remove-Variable Jobs -Force -Scope Global }
if(Get-Variable -Name Job ){Remove-Variable Job -Force -Scope Global }
if(Get-Variable -Name Jobobj ){Remove-Variable Jobobj -Force -Scope Global }
if(Get-Variable -Name Jobsclone ){Remove-Variable Jobsclone -Force -Scope Global }
$runspacepool.Close()
[gc]::Collect()




$scriptBlockGetMetrics={


	Param ($hash,$WESa,$rsid)


	$subscriptionInfo=$hash.subscriptionInfo
	$WEArmConn=$hash.ArmConn
	$headers=$hash.headers
	$WEAsmConn=$hash.AsmConn
	$headerasm=$hash.headerasm
	$WEAzureCert=$hash.AzureCert

	$WETimestampfield = $hash.Timestampfield

	$WECurrency=$hash.Currency
	$WELocale=$hash.Locale
	$WERegionInfo=$hash.RegionInfo
	$WEOfferDurableId=$hash.OfferDurableId
	$syncInterval=$WEHash.syncInterval
	$customerID =$hash.customerID 
	$sharedKey = $hash.sharedKey
	$logname=$hash.Logname
	$WEStartTime = [dateTime]::Now
	$WEApiVerSaAsm = $hash.ApiVerSaAsm
	$WEApiVerSaArm = $hash.ApiVerSaArm
	$WEApiStorage=$hash.ApiStorage
	$WEAAAccount = $hash.AAAccount
	$WEAAResourceGroup = $hash.AAResourceGroup
	$debuglog=$hash.deguglog


	$varQueueList=" AzureSAIngestion-List-Queues"
	$varFilesList=" AzureSAIngestion-List-Files"
	$subscriptionId=$subscriptionInfo.subscriptionId




	Function Build-tableSignature ($customerId, $sharedKey, $date,  $method,  $resource,$uri)
	{
		$stringToHash = $method + " `n" + " `n" + " `n" +$date+" `n" +" /" +$resource+$uri.AbsolutePath
		Add-Type -AssemblyName System.Web
		$query = [System.Web.HttpUtility]::ParseQueryString($uri.query)  
		$querystr=''
		$bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
		$keyBytes = [Convert]::FromBase64String($sharedKey)
		$sha256 = New-Object System.Security.Cryptography.HMACSHA256
		$sha256.Key = $keyBytes
		$calculatedHash = $sha256.ComputeHash($bytesToHash)
		$encodedHash = [Convert]::ToBase64String($calculatedHash)
	; 	$authorization = 'SharedKey {0}:{1}' -f $resource,$encodedHash
		return $authorization
		
	}

	Function Build-StorageSignature ($sharedKey, $date,  $method, $bodylength, $resource,$uri ,$service)
	{
		Add-Type -AssemblyName System.Web
	; 	$str=  New-Object -TypeName " System.Text.StringBuilder" ;
		$builder=  [System.Text.StringBuilder]::new(" /" )
		$builder.Append($resource) |out-null
		$builder.Append($uri.AbsolutePath) | out-null
		$str.Append($builder.ToString()) | out-null
	; 	$values2=@{}
		IF($service -eq 'Table')
		{
		; 	$values= [System.Web.HttpUtility]::ParseQueryString($uri.query)  
			#    NameValueCollection values = HttpUtility.ParseQueryString(address.Query);
			foreach ($str2 in $values.Keys)
			{
				[System.Collections.ArrayList]$list=$values.GetValues($str2)
				$list.sort()
			; 	$builder2=  [System.Text.StringBuilder]::new()
				
				foreach ($obj2 in $list)
				{
					if ($builder2.Length -gt 0)
					{
						$builder2.Append(" ," );
					}
					$builder2.Append($obj2.ToString()) |Out-Null
				}
				IF ($str2 -ne $null)
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
				; 	$builder3=[System.Text.StringBuilder]::new()
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
		; 	$values= [System.Web.HttpUtility]::ParseQueryString($uri.query)  
			#    NameValueCollection values = HttpUtility.ParseQueryString(address.Query);
			foreach ($str2 in $values.Keys)
			{
				[System.Collections.ArrayList]$list=$values.GetValues($str2)
				$list.sort()
			; 	$builder2=  [System.Text.StringBuilder]::new()
				
				foreach ($obj2 in $list)
				{
					if ($builder2.Length -gt 0)
					{
						$builder2.Append(" ," );
					}
					$builder2.Append($obj2.ToString()) |Out-Null
				}
				IF ($str2 -ne $null)
				{
					$values2.add($str2.ToLowerInvariant(),$builder2.ToString())
				} 
			}
			
			$list2=[System.Collections.ArrayList]::new($values2.Keys)
			$list2.sort()
			foreach ($str3 in $list2)
			{
				
			; 	$builder3=[System.Text.StringBuilder]::new()
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
		$xHeaders = " x-ms-date:" + $date+ " `n" +" x-ms-version:$WEApiStorage"
		if ($service -eq 'Table')
		{
			$stringToHash= $method + " `n" + " `n" + " `n" +$date+" `n" +$str.ToString()
		}
		Else
		{
			IF ($method -eq 'GET' -or $method -eq 'HEAD')
			{
				$stringToHash = $method + " `n" + " `n" + " `n" + " `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" +$xHeaders+" `n" +$str.ToString()
			}
			Else
			{
				$stringToHash = $method + " `n" + " `n" + " `n" +$bodylength+ " `n" + " `n" +" application/xml" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" + " `n" +$xHeaders+" `n" +$str.ToString()
			}     
		}
		##############
		

		$bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
		$keyBytes = [Convert]::FromBase64String($sharedKey)
		$sha256 = New-Object System.Security.Cryptography.HMACSHA256
		$sha256.Key = $keyBytes
		$calculatedHash = $sha256.ComputeHash($bytesToHash)
		$encodedHash = [Convert]::ToBase64String($calculatedHash)
		$authorization = 'SharedKey {0}:{1}' -f $resource,$encodedHash
		return $authorization
		
	}

	Function invoke-StorageREST($sharedKey, $method, $msgbody, $resource,$uri,$svc,$download)
	{

		$rfc1123date = [DateTime]::UtcNow.ToString(" r" )

		
		If ($method -eq 'PUT')
		{$signature = Build-StorageSignature `
			-sharedKey $sharedKey `
			-date  $rfc1123date `
			-method $method -resource $resource -uri $uri -bodylength $msgbody.length -service $svc
		}Else
		{

		; 	$signature = Build-StorageSignature `
			-sharedKey $sharedKey `
			-date  $rfc1123date `
			-method $method -resource $resource -uri $uri -body $body -service $svc
		} 

		If($svc -eq 'Table')
		{
		; 	$headersforsa=  @{
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
				'x-ms-version'=" $WEApiStorage"
			}
		}
		




		IF($download)
		{
			$resp1= Invoke-WebRequest -Uri $uri -Headers $headersforsa -Method $method -ContentType application/xml -UseBasicParsing -Body $msgbody  -OutFile " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"

			
			#$xresp=Get-Content " $($env:TEMP)\$resource.$($uri.LocalPath.Replace('/','.').Substring(7,$uri.LocalPath.Length-7))"
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


	function WE-Get-BlobSize ($bloburi,$storageaccount,$rg,$type)
	{

		If($type -eq 'ARM')
		{
			$WEUri=" https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.Storage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $WEApiVerSaArm, $storageaccount,$rg,$WESubscriptionId 
			$keyresp=Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
			$keys=ConvertFrom-Json -InputObject $keyresp.Content
			$prikey=$keys.keys[0].value
		}Elseif($type -eq 'Classic')
		{
			$WEUri=" https://management.azure.com/subscriptions/{3}/resourceGroups/{2}/providers/Microsoft.ClassicStorage/storageAccounts/{1}/listKeys?api-version={0}"   -f  $WEApiVerSaAsm,$storageaccount,$rg,$WESubscriptionId 
			$keyresp=Invoke-WebRequest -Uri $uri -Method POST  -Headers $headers -UseBasicParsing
			$keys=ConvertFrom-Json -InputObject $keyresp.Content
			$prikey=$keys.primaryKey
		}Else
		{
			" Could not detect storage account type, $storageaccount will not be processed"
			Continue
		}





		$vhdblob=invoke-StorageREST -sharedKey $prikey -method HEAD -resource $storageaccount -uri $bloburi
		
		Return [math]::round($vhdblob.Headers.'Content-Length'/1024/1024/1024,0)



	}		

	Function Build-OMSSignature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
	{
		$xHeaders = " x-ms-date:" + $date
		$stringToHash = $method + " `n" + $contentLength + " `n" + $contentType + " `n" + $xHeaders + " `n" + $resource
		$bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
		$keyBytes = [Convert]::FromBase64String($sharedKey)
		$sha256 = New-Object System.Security.Cryptography.HMACSHA256
		$sha256.Key = $keyBytes
		$calculatedHash = $sha256.ComputeHash($bytesToHash)
		$encodedHash = [Convert]::ToBase64String($calculatedHash)
		$authorization = 'SharedKey {0}:{1}' -f $customerId,$encodedHash
		return $authorization
	}

	Function Post-OMSData($customerId, $sharedKey, $body, $logType)
	{


		#usage     Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
		$method = " POST"
		$contentType = " application/json"
		$resource = " /api/logs"
		$rfc1123date = [DateTime]::UtcNow.ToString(" r" )
		$contentLength = $body.Length
		$signature = Build-OMSSignature `
		-customerId $customerId `
		-sharedKey $sharedKey `
		-date $rfc1123date `
		-contentLength $contentLength `
		-fileName $fileName `
		-method $method `
		-contentType $contentType `
		-resource $resource
	; 	$uri = " https://" + $customerId + " .ods.opinsights.azure.com" + $resource + " ?api-version=2016-04-01"
	; 	$WEOMSheaders = @{
			" Authorization" = $signature;
			" Log-Type" = $logType;
			" x-ms-date" = $rfc1123date;
			" time-generated-field" = $WETimeStampField;
		}

		Try{
			$response = Invoke-WebRequest -Uri $uri -Method POST  -ContentType $contentType -Headers $WEOMSheaders -Body $body -UseBasicParsing
		}catch [Net.WebException] 
		{
		; 	$ex=$_.Exception
			If ($_.Exception.Response.StatusCode.value__) {
			; 	$exrespcode = ($_.Exception.Response.StatusCode.value__ ).ToString().Trim();
				#Write-Output $crap;
			}
			If  ($_.Exception.Message) {
				$exMessage = ($_.Exception.Message).ToString().Trim();
				#Write-Output $crapMessage;
			}
			$errmsg= " $exrespcode : $exMessage"
		}

		if ($errmsg){return $errmsg }
		Else{	return $response.StatusCode }
		#write-output $response.StatusCode
		Write-error $error[0]
	}








	$prikey=$sa.key
	$storageaccount =$sa.StorageAccount
	$rg=$sa.rg
	$type=$sa.Type
	$tier=$sa.Tier
	$kind=$sa.Kind

	$colltime=Get-Date

	If($colltime.Minute -in 0..15)
	{
		$WEMetricColstartTime=$colltime.ToUniversalTime().AddHours(-1).ToString(" yyyyMMdd'T'HH46" )
		$WEMetricColendTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH00" )
	}
	Elseif($colltime.Minute -in 16..30)
	{
		$WEMetricColstartTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH00" )
		$WEMetricColendTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH15" )
	}
	Elseif($colltime.Minute -in 31..45)
	{
		$WEMetricColstartTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH16" )
		$WEMetricColendTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH30" )
	}
	Else
	{
		$WEMetricColstartTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH31" )
		$WEMetricColendTime=$colltime.ToUniversalTime().ToString(" yyyyMMdd'T'HH45" )
	}


	$hour=$WEMetricColEndTime.substring($WEMetricColEndTime.Length-4,4).Substring(0,2)
	$min=$WEMetricColEndTime.substring($WEMetricColEndTime.Length-4,4).Substring(2,2)
	$timestamp=(get-date).ToUniversalTime().ToString(" yyyy-MM-ddT$($hour):$($min):00.000Z" )



	$colParamsforChild=@()
	$WESaMetricsAvg=@()
; 	$storcapacity=@()


; 	$fltr1='?$filter='+" PartitionKey%20ge%20'" +$WEMetricColstartTime+" '%20and%20PartitionKey%20le%20'" +$WEMetricColendTime+" '%20and%20RowKey%20eq%20'user;All'"
	$slct1='&$select=PartitionKey,TotalRequests,TotalBillableRequests,TotalIngress,TotalEgress,AverageE2ELatency,AverageServerLatency,PercentSuccess,Availability,PercentThrottlingError,PercentNetworkError,PercentTimeoutError,SASAuthorizationError,PercentAuthorizationError,PercentClientOtherError,PercentServerOtherError'


	$sa=$null
	$vhdinventory=@()
	$allContainers=@()
	$queueinventory=@()
	$queuearr=@()
	$queueMetrics=@()
	$WEFileinventory=@()
	$filearr=@()
	$invFS=@()
	$fileshareinventory=@()
	$tableinventory=@()
	$tablearr=@{}

	$vmlist=@()
	$allvms=@()
	$allvhds=@()




	$tablelist= @('$WEMetricsMinutePrimaryTransactionsBlob','$WEMetricsMinutePrimaryTransactionsTable','$WEMetricsMinutePrimaryTransactionsQueue','$WEMetricsMinutePrimaryTransactionsFile')

	Foreach ($WETableName in $tablelist)
	{
		$signature=$headersforsa=$null
		[uri]$tablequri=" https://$($storageaccount).table.core.windows.net/" +$WETableName+'()'
		
		$resource = $storageaccount
		$logdate=[DateTime]::UtcNow
		$rfc1123date = $logdate.ToString(" r" )
		
	; 	$signature = Build-StorageSignature `
		-sharedKey $prikey `
		-date  $rfc1123date `
		-method GET -resource $storageaccount -uri $tablequri  -service table

	; 	$headersforsa=  @{
			'Authorization'= " $signature"
			'x-ms-version'=" $apistorage"
			'x-ms-date'=" $rfc1123date"
			'Accept-Charset'='UTF-8'
			'MaxDataServiceVersion'='3.0;NetFx'
			'Accept'='application/json;odata=nometadata'
		}

		$response=$jresponse=$null
		$fullQuery=$tablequri.OriginalString+$fltr1+$slct1
		$method = " GET"

		Try
		{
			$response = Invoke-WebRequest -Uri $fullQuery -Method $method  -Headers $headersforsa  -UseBasicParsing  -ErrorAction SilentlyContinue
		}
		Catch
		{
			$WEErrorMessage = $_.Exception.Message
			$WEStackTrace = $_.Exception.StackTrace
			Write-Warning " Error during accessing metrics table $tablename .Error: $WEErrorMessage, stack: $WEStackTrace."
		}
		
		$WEJresponse=convertFrom-Json    $response.Content
		#" $(GEt-date)- Metircs query  $tablename for    $($storageaccount) completed. "
		
		IF($WEJresponse.Value)
		{
			$entities=$null
			$entities=$WEJresponse.value
			$stormetrics=@()
			
			
			foreach ($rowitem in $entities)
			{
				$cu=$null
				
				$dt=$rowitem.PartitionKey
				$timestamp=$dt.Substring(0,4)+'-'+$dt.Substring(4,2)+'-'+$dt.Substring(6,3)+$dt.Substring(9,2)+':'+$dt.Substring(11,2)+':00.000Z'


				$cu = New-Object PSObject -Property @{
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
					StorageAccount = $WEStorageAccount 
					StorageService=$WETableName.Substring(33,$WETableName.Length-33) 
					SubscriptionId = $WEArmConn.SubscriptionID
					AzureSubscription = $subscriptionInfo.displayName
				}
				
				$hash['saTransactionsMetrics']+=$cu
				

			}

			
		}
	}




	$WETableName = '$WEMetricsCapacityBlob'
	$startdate=(get-date).AddDays(-1).ToUniversalTime().ToString(" yyyyMMdd'T'0000" )

	$table=$null
	$signature=$headersforsa=$null
	[uri]$tablequri=" https://$($storageaccount).table.core.windows.net/" +$WETableName+'()'
	
	$resource = $storageaccount
	$logdate=[DateTime]::UtcNow
	$rfc1123date = $logdate.ToString(" r" )
; 	$signature = Build-StorageSignature `
	-sharedKey $prikey `
	-date  $rfc1123date `
	-method GET -resource $storageaccount -uri $tablequri  -service table

; 	$headersforsa=  @{
		'Authorization'= " $signature"
		'x-ms-version'=" $apistorage"
		'x-ms-date'=" $rfc1123date"
		'Accept-Charset'='UTF-8'
		'MaxDataServiceVersion'='3.0;NetFx'
		'Accept'='application/json;odata=nometadata'
	}

	$response=$jresponse=$null
	$fltr2='?$filter='+" PartitionKey%20gt%20'" +$startdate+" '%20and%20RowKey%20eq%20'data'"
	$fullQuery=$tablequri.OriginalString+$fltr2
	$method = " GET"
	
	Try
	{
		$response = Invoke-WebRequest -Uri $fullQuery -Method $method  -Headers $headersforsa  -UseBasicParsing  -ErrorAction SilentlyContinue
	}
	Catch
	{
		$WEErrorMessage = $_.Exception.Message
		$WEStackTrace = $_.Exception.StackTrace
		Write-Warning " Error during accessing metrics table $tablename .Error: $WEErrorMessage, stack: $WEStackTrace."
	}
	$WEJresponse=convertFrom-Json    $response.Content

	IF($WEJresponse.Value)
	{
		$entities=$null
		$entities=@($jresponse.value)
	; 	$cu=$null

	; 	$cu = New-Object PSObject -Property @{
			Timestamp = $timestamp
			MetricName = 'MetricsCapacity'				
			Capacity=$([long]$entities[0].Capacity)/1024/1024/1024               
			ContainerCount=[long]$entities[0].ContainerCount 
			ObjectCount=[long]$entities[0].ObjectCount
			ResourceGroup=$rg
			StorageAccount = $WEStorageAccount
			StorageService=" Blob"  
			SubscriptionId = $WEArmConn.SubscriptionId
			AzureSubscription = $subscriptionInfo.displayName
			
		}
		$hash['saCapacityMetrics']+=$cu
		
	}





	IF($tier -notmatch 'premium' -and $kind -ne 'BlobStorage')
	{
		[uri]$uriQueue=" https://{0}.queue.core.windows.net?comp=list" -f $storageaccount
		[xml]$WEXresponse=invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $uriQueue
		# " Checking $uriQueue"
		# $WEXresponse.EnumerationResults.Queues.Queue
		IF (![String]::IsNullOrEmpty($WEXresponse.EnumerationResults.Queues.Queue))
		{
			Foreach ($queue in $WEXresponse.EnumerationResults.Queues.Queue)
			{
				write-verbose  " Queue found :$($sa.name) ; $($queue.name) "
				
				$queuearr = $queuearr + " {0};{1}" -f $queue.Name.tostring(),$sa.name
				$queueinventory = $queueinventory + New-Object PSObject -Property @{
					Timestamp = $timestamp
					MetricName = 'Inventory'
					InventoryType='Queue'
					StorageAccount=$sa.name
					Queue= $queue.Name
					Uri=$uriQueue.Scheme+'://'+$uriQueue.Host+'/'+$queue.Name
					SubscriptionID = $WEArmConn.SubscriptionId;
					AzureSubscription = $subscriptionInfo.displayName
					ShowinDesigner=1
				}

				#collect metrics

				
				[uri]$uriforq=" https://$storageaccount.queue.core.windows.net/$($queue.name)/messages?peekonly=true"
				[xml]$WEXmlqresp= invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $uriforq 
				
				[uri]$uriform=" https://$storageaccount.queue.core.windows.net/$($queue.name)?comp=metadata"
			; 	$WEXmlqrespm= invoke-StorageREST -sharedKey $prikey -method HEAD -resource $storageaccount -uri $uriform
				
				
			; 	$cuq=$null
			; 	$cuq = $cuq + New-Object PSObject -Property @{
					Timestamp=$timestamp
					MetricName = 'QueueMetrics';
					StorageAccount=$storageaccount
					StorageService=" Queue" 
					Queue= $queue.Name
					approximateMsgCount=$WEXmlqrespm.Headers.'x-ms-approximate-messages-count' 
					SubscriptionId = $WEArmConn.SubscriptionId;
					AzureSubscription = $subscriptionInfo.displayName
				}

				$msg=$WEXmlqresp.QueueMessagesList.QueueMessage
				IF(![string]::IsNullOrEmpty($WEXmlqresp.QueueMessagesList))
				{
					$cuq|Add-Member -MemberType NoteProperty -Name FirstMessageID -Value $msg.MessageId
					$cuq|Add-Member -MemberType NoteProperty -Name FirstMessageText -Value $msg.MessageText
					$cuq|Add-Member -MemberType NoteProperty -Name FirstMsgInsertionTime -Value $msg.InsertionTime
					$cuq|Add-Member -MemberType NoteProperty -Name Minutesinqueue -Value [Math]::Round(((Get-date).ToUniversalTime()-[datetime]($WEXmlqresp.QueueMessagesList.QueueMessage.InsertionTime)).Totalminutes,0)
				}

				$hash['tableInventory']+=$cuq
				



			}

		}
	}





	IF($tier -notmatch 'premium' -and $kind -ne 'BlobStorage')
	{
		
		[uri]$uriFile=" https://{0}.file.core.windows.net?comp=list" -f $storageaccount
		
		
		[xml]$WEXresponse=invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $uriFile

		if(![string]::IsNullOrEmpty($WEXresponse.EnumerationResults.Shares.Share))
		{
			foreach($share in @($WEXresponse.EnumerationResults.Shares.Share))
			{
				write-verbose  " File Share found :$($storageaccount) ; $($share.Name) "
				$filelist=@()			


			; 	$filearr = $filearr + " {0};{1}" -f $WEShare.Name,$storageaccount

				
				$cuf= New-Object PSObject -Property @{
					Timestamp = $timestamp
					MetricName = 'Inventory'
					InventoryType='File'
					StorageAccount=$storageaccount
					FileShare=$share.Name
					Uri=$uriFile.Scheme+'://'+$uriFile.Host+'/'+$WEShare.Name
					Quota=$share.Properties.Quota                              
					SubscriptionID = $WEArmConn.SubscriptionId;
					AzureSubscription = $subscriptionInfo.displayName
					ShowinDesigner=1
				}

				[uri]$uriforF=" https://{0}.file.core.windows.net/{1}?restype=share&comp=stats" -f $storageaccount,$share.Name 
				[xml]$WEXmlresp=invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $uriforF 
				
				IF($WEXmlresp)
				{       
					$cuf|Add-Member -MemberType NoteProperty -Name  ShareUsedGB -Value $([int]$WEXmlresp.ShareStats.ShareUsage)
				} 
				
				$hash['fileInventory']+=$cuf

			}
		}
	}




	IF($tier -notmatch 'premium')
	{
		[uri]$uritable=" https://{0}.table.core.windows.net/Tables" -f $storageaccount
		
		$rfc1123date = [DateTime]::UtcNow.ToString(" r" )
	; 	$signature = Build-StorageSignature `
		-sharedKey $prikey
		-date  $rfc1123date `
		-method GET -resource $sa.name -uri $uritable  -service table
	; 	$headersforsa=  @{
			'Authorization'= " $signature"
			'x-ms-version'=" $apistorage"
			'x-ms-date'=" $rfc1123date"
			'Accept-Charset'='UTF-8'
			'MaxDataServiceVersion'='3.0;NetFx'
			'Accept'='application/json;odata=nometadata'
		}
		$tableresp=Invoke-WebRequest -Uri $uritable -Headers $headersforsa -Method GET  -UseBasicParsing 
	; 	$respJson=convertFrom-Json    $tableresp.Content
		
		IF (![string]::IsNullOrEmpty($respJson.value.Tablename))
		{
			foreach($tbl in @($respJson.value.Tablename))
			{
				write-verbose  " Table found :$storageaccount ; $($tbl) "
				
				#$tablearr = $tablearr + " {0}" -f $sa.name
				IF ([string]::IsNullOrEmpty($tablearr.Get_item($storageaccount)))
				{
					$tablearr.add($sa.name,'Storageaccount') 
				}
				
				
				$hash['queueInventory']+= New-Object PSObject -Property @{
					Timestamp = $timestamp
					MetricName = 'Inventory'
					InventoryType='Table'
					StorageAccount=$storageaccount
					Table=$tbl
					Uri=$uritable.Scheme+'://'+$uritable.Host+'/'+$tbl
					SubscriptionID = $WEArmConn.SubscriptionId;
					AzureSubscription = $subscriptionInfo.displayName
					ShowinDesigner=1
					
				}
			}
		}
	}





	if ((get-date).hour -in (1,5,9,13,17,21) -and   (get-date).minute -in (1..16)   )
	{

		[uri]$uriListC= " https://{0}.blob.core.windows.net/?comp=list" -f $storageaccount
		
		Write-verbose " $(get-date) - Getting list of blobs for $($sa.name) "
		[xml]$lb=invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $uriListC
		$containers=@($lb.EnumerationResults.Containers.Container)
		
		IF(![string]::IsNullOrEmpty($lb.EnumerationResults.Containers.Container))
		{
			Foreach($container in @($containers))
			{
				$allcontainers = $allcontainers + $container
				[uri]$uriLBlobs = " https://{0}.blob.core.windows.net/{1}/?comp=list&include=metadata&maxresults=1000&restype=container" -f $storageaccount,$container.name
				[xml]$fresponse= invoke-StorageREST -sharedKey $prikey -method GET -resource $storageaccount -uri $uriLBlobs
				
				$filesincontainer=@()

			; 	$blobs=$fresponse.EnumerationResults.Blobs.blob
				Foreach($blob in $blobs)
				{
					IF($blob.name -match '.vhd')
					{
					; 	$cu = New-Object PSObject -Property @{
							Timestamp = $timestamp
							MetricName = 'Inventory'
							InventoryType='VHDFile'
							Capacity=[Math]::Round($blob.Properties.'Content-Length'/1024/1024/1024,0)               
							Container=$container.Name
							VHDName=$blob.name
							Uri= " {0}{1}/{2}" -f $fresponse.EnumerationResults.ServiceEndpoint,$WEContainer.Name,$blob.Name
							LeaseState=$blob.Properties.LeaseState.ToString()
							StorageAccount= $storageaccount
							SubscriptionID = $WEArmConn.SubscriptionId;
							AzureSubscription = $subscriptionInfo.displayName
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



$WEThrottle = [System.Environment]::ProcessorCount+1
$sessionstate = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
$runspacepool = [runspacefactory]::CreateRunspacePool(1, $WEThrottle, $sessionstate, $WEHost)
$runspacepool.Open() 
[System.Collections.ArrayList]$WEJobs = @()

Write-Output " After Runspace creation for metric collection : $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"

$i=1 
$WEStarttimer=get-date

$hash.SAInfo|foreach{

	$splitmetrics=$null
	$splitmetrics=$_
	$WEJob = [powershell]::Create().AddScript($scriptBlockGetMetrics).AddArgument($hash).AddArgument($splitmetrics).Addargument($i)
	$WEJob.RunspacePool = $WERunspacePool
	$WEJobs = $WEJobs + New-Object PSObject -Property @{
		RunNum = $i
		Pipe = $WEJob
		Result = $WEJob.BeginInvoke()

	}
	
	$i++
}

write-output  " $(get-date)  , started $i Runspaces "
Write-Output " After dispatching runspaces $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
$jobsClone=$jobs.clone()
Write-Output " Waiting.."




$s=1
Do {

	Write-Output "  $(@($jobs.result.iscompleted|where{$_  -match 'False'}).count)  jobs remaining"

	foreach ($jobobj in $WEJobsClone)
	{

		if ($WEJobobj.result.IsCompleted -eq $true)
		{
			$jobobj.Pipe.Endinvoke($jobobj.Result)
			$jobobj.pipe.dispose()
			$jobs.Remove($jobobj)
		}
	}




	IF($s%2 -eq 0) 
	{
		Write-Output " Mem: $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"
	}  
	$s++

	Start-Sleep -Seconds 15


} While ( @($jobs.result.iscompleted|where{$_  -match 'False'}).count -gt 0)
Write-output " All jobs completed!"




$jobs|foreach{$_.Pipe.Dispose()}
Remove-Variable Jobs -Force -Scope Global
Remove-Variable Job -Force -Scope Global
Remove-Variable Jobobj -Force -Scope Global
Remove-Variable Jobsclone -Force -Scope Global
$runspacepool.Close()

$([System.gc]::gettotalmemory('forcefullcollection') /1MB)


$WEEndtimer=get-date

Write-Output " All jobs completed in $(($WEEndtimer-$starttimer).TotalMinutes) minutes"




Write-Output " Uploading to OMS ..."

$splitSize=5000

If($hash.saTransactionsMetrics)
{

	write-output  " Uploading  $($hash.saTransactionsMetrics.count) transaction metrics"
; 	$uploadToOms=$hash.saTransactionsMetrics
	$hash.saTransactionsMetrics=@()
	
	If($uploadToOms.count -gt $splitSize)
	{
	; 	$spltlist=@()
	; 	$spltlist = $spltlist + for ($WEIndex = 0; $WEIndex -lt $uploadToOms.count; $WEIndex = $WEIndex + $splitSize)
		{
			,($uploadToOms[$index..($index+$splitSize-1)])
		}
		
		
		$spltlist|foreach{
			$splitLogs=$null
			$splitLogs=$_
			$jsonlogs= ConvertTo-Json -InputObject $splitLogs
			Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname

		}



	}Else{

		$jsonlogs= ConvertTo-Json -InputObject $uploadToOms

		Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname


	}
	Remove-Variable uploadToOms -Force -Scope Global -ErrorAction SilentlyContinue
	Remove-Variable jsonlogs -Force -Scope Global -ErrorAction SilentlyContinue
	Remove-Variable spltlist -Force -Scope Global -ErrorAction SilentlyContinue
	[System.gc]::Collect()
}


If($hash.saCapacityMetrics)
{

	write-output  " Uploading  $($hash.saCapacityMetrics.count) capacity metrics"
; 	$uploadToOms=$hash.saCapacityMetrics
	$hash.saCapacityMetrics=@()
	
	If($uploadToOms.count -gt $splitSize)
	{
	; 	$spltlist=@()
	; 	$spltlist = $spltlist + for ($WEIndex = 0; $WEIndex -lt $uploadToOms.count; $WEIndex = $WEIndex + $splitSize)
		{
			,($uploadToOms[$index..($index+$splitSize-1)])
		}
		
		
		$spltlist|foreach{
			$splitLogs=$null
			$splitLogs=$_
			$jsonlogs= ConvertTo-Json -InputObject $splitLogs
			Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname

		}



	}Else{

		$jsonlogs= ConvertTo-Json -InputObject $uploadToOms

		Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname

	}
	Remove-Variable uploadToOms -Force -Scope Global  -ErrorAction SilentlyContinue
	Remove-Variable jsonlogs -Force -Scope Global -ErrorAction SilentlyContinue
	Remove-Variable spltlist -Force -Scope Global -ErrorAction SilentlyContinue
	[System.gc]::Collect()
}

If($hash.tableInventory)
{
	write-output  " Uploading  $($hash.tableInventory.count) table inventory"
; 	$uploadToOms=$hash.tableInventory

	$hash.tableInventory=@()

	If($uploadToOms.count -gt $splitSize)
	{
	; 	$spltlist=@()
	; 	$spltlist = $spltlist + for ($WEIndex = 0; $WEIndex -lt $uploadToOms.count; $WEIndex = $WEIndex + $splitSize)
		{
			,($uploadToOms[$index..($index+$splitSize-1)])
		}
		
		
		$spltlist|foreach{
			$splitLogs=$null
			$splitLogs=$_
		; 	$jsonlogs= ConvertTo-Json -InputObject $splitLogs
			Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname

		}



	}Else{

	; 	$jsonlogs= ConvertTo-Json -InputObject $uploadToOms

		Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname

	}
	Remove-Variable uploadToOms -Force -Scope Global -ErrorAction SilentlyContinue
	Remove-Variable jsonlogs -Force -Scope Global -ErrorAction SilentlyContinue
	Remove-Variable spltlist -Force -Scope Global -ErrorAction SilentlyContinue
	[System.gc]::Collect()
}


If(!$hash.queueInventory)
{

	$hash.queueInventory+=New-Object PSObject -Property @{
		Timestamp = $timestamp
		MetricName = 'Inventory'
		InventoryType='Queue'
		Queue= " NO RESOURCE FOUND"
		Uri=" NO RESOURCE FOUND"
		SubscriptionID = $WEArmConn.SubscriptionId;
		AzureSubscription = $subscriptionInfo.displayName
		ShowinDesigner=0
	}
}

write-output  " Uploading  $($hash.queueInventory.count) queue inventory"
$uploadToOms=$hash.queueInventory
$hash.queueInventory=@()

If($uploadToOms.count -gt $splitSize)
{
; 	$spltlist=@()
; 	$spltlist = $spltlist + for ($WEIndex = 0; $WEIndex -lt $uploadToOms.count; $WEIndex = $WEIndex + $splitSize)
	{
		,($uploadToOms[$index..($index+$splitSize-1)])
	}
	
	
	$spltlist|foreach{
		$splitLogs=$null
		$splitLogs=$_
	; 	$jsonlogs= ConvertTo-Json -InputObject $splitLogs
		Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname

	}



}Else{

; 	$jsonlogs= ConvertTo-Json -InputObject $uploadToOms

	Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname

}
Remove-Variable uploadToOms -Force -Scope Global  -ErrorAction SilentlyContinue
Remove-Variable jsonlogs -Force -Scope Global  -ErrorAction SilentlyContinue
Remove-Variable spltlist -Force -Scope Global  -ErrorAction SilentlyContinue
[System.gc]::Collect()


If(!$hash.fileInventory)
{


	$hash.fileInventory+=New-Object PSObject -Property @{
		Timestamp = $timestamp
		MetricName = 'Inventory'
		InventoryType='File'
		FileShare=" NO RESOURCE FOUND"
		Uri=" NO RESOURCE FOUND"                       
		SubscriptionID = $WEArmConn.SubscriptionId;
		AzureSubscription = $subscriptionInfo.displayName
		ShowinDesigner=0
	}
	
}

write-output  " Uploading  $($hash.fileInventory.count) file inventory"
$uploadToOms=$hash.fileInventory
$hash.fileInventory=@()

If($uploadToOms.count -gt $splitSize)
{
; 	$spltlist=@()
; 	$spltlist = $spltlist + for ($WEIndex = 0; $WEIndex -lt $uploadToOms.count; $WEIndex = $WEIndex + $splitSize)
	{
		,($uploadToOms[$index..($index+$splitSize-1)])
	}
	
	
	$spltlist|foreach{
		$splitLogs=$null
		$splitLogs=$_
	; 	$jsonlogs= ConvertTo-Json -InputObject $splitLogs

		Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname

	}



}Else{

; 	$jsonlogs= ConvertTo-Json -InputObject $uploadToOms


	Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname

}
Remove-Variable uploadToOms -Force -Scope Global -ErrorAction SilentlyContinue
Remove-Variable jsonlogs -Force -Scope Global -ErrorAction SilentlyContinue
Remove-Variable spltlist -Force -Scope Global -ErrorAction SilentlyContinue
[System.gc]::Collect()



If(!$hash.vhdinventory)
{


	$hash.vhdinventory+= New-Object PSObject -Property @{
		Timestamp = $timestamp
		MetricName = 'Inventory'
		InventoryType='VHDFile'
		VHDName=" NO RESOURCE FOUND"
		Uri= " NO RESOURCE FOUND"
		SubscriptionID = $WEArmConn.SubscriptionId;
		AzureSubscription = $subscriptionInfo.displayName
		ShowinDesigner=0		
	}        

}

write-output  " Uploading  $($hash.vhdinventory.count) vhd inventory"
$uploadToOms=$hash.vhdinventory
$hash.vhdinventory=@()

If($uploadToOms.count -gt $splitSize)
{
; 	$spltlist=@()
; 	$spltlist = $spltlist + for ($WEIndex = 0; $WEIndex -lt $uploadToOms.count; $WEIndex = $WEIndex + $splitSize)
	{
		,($uploadToOms[$index..($index+$splitSize-1)])
	}
	
	
	$spltlist|foreach{
		$splitLogs=$null
		$splitLogs=$_
	; 	$jsonlogs= ConvertTo-Json -InputObject $splitLogs

		Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname

	}



}Else{

; 	$jsonlogs= ConvertTo-Json -InputObject $uploadToOms

	Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsonlogs)) -logType $logname
	
	
}
Remove-Variable uploadToOms -Force -Scope Global -ErrorAction SilentlyContinue
Remove-Variable jsonlogs -Force -Scope Global -ErrorAction SilentlyContinue
Remove-Variable spltlist -Force -Scope Global -ErrorAction SilentlyContinue
[System.gc]::Collect()



" Final Memory Consumption: $([System.gc]::gettotalmemory('forcefullcollection') /1MB) MB"







# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================