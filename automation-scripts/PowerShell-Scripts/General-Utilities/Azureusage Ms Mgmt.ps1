#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azureusage Ms Mgmt

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
    We Enhanced Azureusage Ms Mgmt

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
[Parameter(Mandatory=$false)][string]$WECurrency   ,
[Parameter(Mandatory=$false)][string]$WELocale   ,
[Parameter(Mandatory=$false)][string]$WERegionInfo   ,
[Parameter(Mandatory=$false)][string]$WEOfferDurableId ,
[Parameter(Mandatory=$false)][bool]$propagatetags=$true ,
[Parameter(Mandatory=$false)][string]$syncInterval='Hourly'                
)

#region Functions


$WETimestampfield = " Timestamp" 
$log=@()
$WEApiVersion = '2015-06-01-preview'

IF([String]::IsNullOrEmpty($WECurrency)){  $WECurrency = 'USD' }
IF([String]::IsNullOrEmpty($WELocale)){ $WELocale = 'en-US'}
$regionlist=@{}
$regionlist.Add(" Australia" ," AU" )
$regionlist.Add(" Afghanistan" ," AF" )
$regionlist.Add(" Albania" ," AL" )
$regionlist.Add(" Algeria" ," DZ" )
$regionlist.Add(" Angola" ," AO" )
$regionlist.Add(" Argentina" ," AR" )
$regionlist.Add(" Armenia" ," AM" )
$regionlist.Add(" Austria" ," AT" )
$regionlist.Add(" Azerbaijan" ," AZ" )
$regionlist.Add(" Bahamas" ," BS" )
$regionlist.Add(" Bahrain" ," BH" )
$regionlist.Add(" Bangladesh" ," BD" )
$regionlist.Add(" Barbados" ," BB" )
$regionlist.Add(" Belarus" ," BY" )
$regionlist.Add(" Belgium" ," BE" )
$regionlist.Add(" Belize" ," BZ" )
$regionlist.Add(" Bermuda" ," BM" )
$regionlist.Add(" Bolivia" ," BO" )
$regionlist.Add(" Bosnia and Herzegovina" ," BA" )
$regionlist.Add(" Botswana" ," BW" )
$regionlist.Add(" Brazil" ," BR" )
$regionlist.Add(" Brunei" ," BN" )
$regionlist.Add(" Bulgaria" ," BG" )
$regionlist.Add(" Cameroon" ," CM" )
$regionlist.Add(" Canada" ," CA" )
$regionlist.Add(" Cape Verde" ," CV" )
$regionlist.Add(" Cayman Islands" ," KY" )
$regionlist.Add(" Chile" ," CL" )
$regionlist.Add(" Colombia" ," CO" )
$regionlist.Add(" Costa Rica" ," CR" )
$regionlist.Add(" Côte D'ivoire" ," CI" )
$regionlist.Add(" Croatia" ," HR" )
$regionlist.Add(" Curaçao" ," CW" )
$regionlist.Add(" Cyprus" ," CY" )
$regionlist.Add(" Czech Republic" ," CZ" )
$regionlist.Add(" Denmark" ," DK" )
$regionlist.Add(" Dominican Republic" ," DO" )
$regionlist.Add(" Ecuador" ," EC" )
$regionlist.Add(" Egypt" ," EG" )
$regionlist.Add(" El Salvador" ," SV" )
$regionlist.Add(" Estonia" ," EE" )
$regionlist.Add(" Ethiopia" ," ET" )
$regionlist.Add(" Faroe Islands" ," FO" )
$regionlist.Add(" Fiji" ," FJ" )
$regionlist.Add(" Finland" ," FI" )
$regionlist.Add(" France" ," FR" )
$regionlist.Add(" Georgia" ," GE" )
$regionlist.Add(" Germany" ," DE" )
$regionlist.Add(" Ghana" ," GH" )
$regionlist.Add(" Greece" ," GR" )
$regionlist.Add(" Guatemala" ," GT" )
$regionlist.Add(" Honduras" ," HN" )
$regionlist.Add(" Hong Kong SAR" ," HK" )
$regionlist.Add(" Hungary" ," HU" )
$regionlist.Add(" Iceland" ," IS" )
$regionlist.Add(" India" ," IN" )
$regionlist.Add(" Indonesia" ," ID" )
$regionlist.Add(" Iraq" ," IQ" )
$regionlist.Add(" Ireland" ," IE" )
$regionlist.Add(" Israel" ," IL" )
$regionlist.Add(" Italy" ," IT" )
$regionlist.Add(" Jamaica" ," JM" )
$regionlist.Add(" Japan" ," JP" )
$regionlist.Add(" Jordan" ," JO" )
$regionlist.Add(" Kazakhstan" ," KZ" )
$regionlist.Add(" Kenya" ," KE" )
$regionlist.Add(" Korea" ," KR" )
$regionlist.Add(" Kuwait" ," KW" )
$regionlist.Add(" Kyrgyzstan" ," KG" )
$regionlist.Add(" Latvia" ," LV" )
$regionlist.Add(" Lebanon" ," LB" )
$regionlist.Add(" Libya" ," LY" )
$regionlist.Add(" Liechtenstein" ," LI" )
$regionlist.Add(" Lithuania" ," LT" )
$regionlist.Add(" Luxembourg" ," LU" )
$regionlist.Add(" Macao SAR" ," MO" )
$regionlist.Add(" Macedonia, FYRO" ," MK" )
$regionlist.Add(" Malaysia" ," MY" )
$regionlist.Add(" Malta" ," MT" )
$regionlist.Add(" Mauritius" ," MU" )
$regionlist.Add(" Mexico" ," MX" )
$regionlist.Add(" Moldova" ," MD" )
$regionlist.Add(" Monaco" ," MC" )
$regionlist.Add(" Mongolia" ," MN" )
$regionlist.Add(" Montenegro" ," ME" )
$regionlist.Add(" Morocco" ," MA" )
$regionlist.Add(" Namibia" ," NA" )
$regionlist.Add(" Nepal" ," NP" )
$regionlist.Add(" Netherlands" ," NL" )
$regionlist.Add(" New Zealand" ," NZ" )
$regionlist.Add(" Nicaragua" ," NI" )
$regionlist.Add(" Nigeria" ," NG" )
$regionlist.Add(" Norway" ," NO" )
$regionlist.Add(" Oman" ," OM" )
$regionlist.Add(" Pakistan" ," PK" )
$regionlist.Add(" Palestinian Territory" ," PS" )
$regionlist.Add(" Panama" ," PA" )
$regionlist.Add(" Paraguay" ," PY" )
$regionlist.Add(" Peru" ," PE" )
$regionlist.Add(" Philippines" ," PH" )
$regionlist.Add(" Poland" ," PL" )
$regionlist.Add(" Portugal" ," PT" )
$regionlist.Add(" Puerto Rico" ," PR" )
$regionlist.Add(" Qatar" ," QA" )
$regionlist.Add(" Romania" ," RO" )
$regionlist.Add(" Russia" ," RU" )
$regionlist.Add(" Rwanda" ," RW" )
$regionlist.Add(" Saint Kitts and Nevis" ," KN" )
$regionlist.Add(" Saudi Arabia" ," SA" )
$regionlist.Add(" Senegal" ," SN" )
$regionlist.Add(" Serbia" ," RS" )
$regionlist.Add(" Singapore" ," SG" )
$regionlist.Add(" Slovakia" ," SK" )
$regionlist.Add(" Slovenia" ," SI" )
$regionlist.Add(" South Africa" ," ZA" )
$regionlist.Add(" Spain" ," ES" )
$regionlist.Add(" Sri Lanka" ," LK" )
$regionlist.Add(" Sweden" ," SE" )
$regionlist.Add(" Switzerland" ," CH" )
$regionlist.Add(" Taiwan" ," TW" )
$regionlist.Add(" Tajikistan" ," TJ" )
$regionlist.Add(" Tanzania" ," TZ" )
$regionlist.Add(" Thailand" ," TH" )
$regionlist.Add(" Trinidad and Tobago" ," TT" )
$regionlist.Add(" Tunisia" ," TN" )
$regionlist.Add(" Turkey" ," TR" )
$regionlist.Add(" Turkmenistan" ," TM" )
$regionlist.Add(" U.S. Virgin Islands" ," VI" )
$regionlist.Add(" Uganda" ," UG" )
$regionlist.Add(" Ukraine" ," UA" )
$regionlist.Add(" United Arab Emirates" ," AE" )
$regionlist.Add(" United Kingdom" ," GB" )
$regionlist.Add(" United States" ," US" )
$regionlist.Add(" Uruguay" ," UY" )
$regionlist.Add(" Uzbekistan" ," UZ" )
$regionlist.Add(" Venezuela" ," VE" )
$regionlist.Add(" Vietnam" ," VN" )
$regionlist.Add(" Yemen" ," YE" )
$regionlist.Add(" Zambia" ," ZM" )
$regionlist.Add(" Zimbabwe" ," ZW" ); 
$WERegionIso=$regionlist.item($regioninfo)
; 
$defaultCurrency=@(" Afghanistan;USD" ,
" Albania;USD" ,
" Algeria;USD" ,
" Angola;USD" ,
" Argentina;ARS" ,
" Armenia;USD" ,
" Australia;AUD" ,
" Austria;EUR" ,
" Azerbaijan;USD" ,
" Bahamas;USD" ,
" Bahrain;USD" ,
" Bangladesh;USD" ,
" Barbados;USD" ,
" Belarus;USD" ,
" Belgium;EUR" ,
" Belize;USD" ,
" Bermuda;USD" ,
" Bolivia;USD" ,
" Bosnia and Herzegovina;USD" ,
" Botswana;USD" ,
" Brazil;BRL" ,
" Brazil;USD" ,
" Brunei Darussalam;USD" ,
" Bulgaria;EUR" ,
" Cameroon;USD" ,
" Canada;CAD" ,
" Cape Verde;USD" ,
" Cayman Islands;USD" ,
" Chile;USD" ,
" Colombia;USD" ,
" Congo;USD" ,
" Costa Rica;USD" ,
" Côte D'ivoire;USD" ,
" Croatia;EUR" ,
" Croatia;USD" ,
" Curaçao;USD" ,
" Cyprus;EUR" ,
" Czech Republic;EUR" ,
" Denmark;DKK" ,
" Dominican Republic;USD" ,
" Ecuador;USD" ,
" Egypt;USD" ,
" El Salvador;USD" ,
" Estonia;EUR" ,
" Ethiopia;USD" ,
" Faroe Islands;EUR" ,
" Fiji;USD" ,
" Finland;EUR" ,
" France;EUR" ,
" Georgia;USD" ,
" Germany;EUR" ,
" Ghana;USD" ,
" Greece;EUR" ,
" Guatemala;USD" ,
" Honduras;USD" ,
" Hong Kong;HKD" ,
" Hong Kong SAR;USD" ,
" Hungary;EUR" ,
" Iceland;EUR" ,
" India;INR" ,
" India;USD" ,
" Indonesia;IDR" ,
" Iraq;USD" ,
" Ireland;EUR" ,
" Israel;USD" ,
" Italy;EUR" ,
" Jamaica;USD" ,
" Japan;JPY" ,
" Jordan;USD" ,
" Kazakhstan;USD" ,
" Kenya;USD" ,
" Korea;KRW" ,
" Kuwait;USD" ,
" Kyrgyzstan;USD" ,
" Latvia;EUR" ,
" Lebanon;USD" ,
" Libya;USD" ,
" Liechtenstein;CHF" ,
" Lithuania;EUR" ,
" Luxembourg;EUR" ,
" Macao;USD" ,
" Macedonia;USD" ,
" Malaysia;MYR" ,
" Malaysia;USD" ,
" Malta;EUR" ,
" Mauritius;USD" ,
" Mexico;MXN" ,
" Mexico;USD" ,
" Moldova;USD" ,
" Monaco;EUR" ,
" Mongolia;USD" ,
" Montenegro;USD" ,
" Morocco;USD" ,
" Namibia;USD" ,
" Nepal;USD" ,
" Netherlands;EUR" ,
" New Zealand;NZD" ,
" Nicaragua;USD" ,
" Nigeria;USD" ,
" Norway;NOK" ,
" Oman;USD" ,
" Pakistan;USD" ,
" Palestinian Territory, Occupied;USD" ,
" Panama;USD" ,
" Paraguay;USD" ,
" Peru;USD" ,
" Philippines;USD" ,
" Poland;EUR" ,
" Portugal;EUR" ,
" Puerto Rico;USD" ,
" Qatar;USD" ,
" Romania;EUR" ,
" Russia;RUB" ,
" Rwanda;USD" ,
" Saint Kitts and Nevis;USD" ,
" Saudi Arabia;SAR" ,
" Senegal;USD" ,
" Serbia;USD" ,
" Singapore;USD" ,
" Slovakia;EUR" ,
" Slovenia;EUR" ,
" South Africa;ZAR" ,
" Spain;EUR" ,
" Sri Lanka;USD" ,
" Sweden;SEK" ,
" Switzerland;CHF" ,
" Taiwan;TWD" ,
" Tajikistan;USD" ,
" Tanzania;USD" ,
" Thailand;USD" ,
" Trinidad and Tobago;USD" ,
" Tunisia;USD" ,
" Turkey;TRY" ,
" Turkmenistan;USD" ,
" UAE;USD" ,
" Uganda;USD" ,
" Ukraine;USD" ,
" United Kingdom;GBP" ,
" United States;USD" ,
" Uruguay;USD" ,
" Uzbekistan;USD" ,
" Venezuela;USD" ,
" Viet Nam;USD" ,
" Virgin Islands, US;USD" ,
" Yemen;USD" ,
" Zambia;USD" ,
" Zimbabwe;USD" )


IF(!($defaultCurrency|where{$_ -match $WERegionInfo -and $_ -match $WECurrency}))
{

$WECurrency=@($defaultCurrency|where{$_ -match $WERegionInfo})[0].Split(';')[1]

}



IF([String]::IsNullOrEmpty($WERegionIso)){ $WERegionIso= 'US'}
IF([String]::IsNullOrEmpty($WEOfferDurableId)){ $WEOfferDurableId = 'MS-AZR-0003P' }Else
{
	$WEOfferDurableId=$WEOfferDurableId.Split(':')[0].trim()
}





$customerID = Get-AutomationVariable -Name  " AzureUsage-OPSINSIGHTS_WS_ID"

$sharedKey = Get-AutomationVariable -Name  " AzureUsage-OPSINSIGHTS_WS_KEY"

$logname='AzureUsage'

[Collections.Arraylist]$instanceResults = @()
$colltime=(get-date).ToUniversalTime().ToString(" yyyy-MM-ddThh:00:00.000Z" )

function New-OMSSignature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
{
	$xHeaders = " x-ms-date:" + $date
	$stringToHash = $method + " `n" + $contentLength + " `n" + $contentType + " `n" + $xHeaders + " `n" + $resource
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
	$method = " POST"
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
; 	$uri = " https://" + $customerId + " .ods.opinsights.azure.com" + $resource + " ?api-version=2016-04-01"
; 	$WEOMSheaders = @{
		" Authorization" = $signature;
		" Log-Type" = $logType;
		" x-ms-date" = $rfc1123date;
		" time-generated-field" = $WETimeStampField;
	}
	$response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $WEOMSheaders -Body $body -UseBasicParsing
	return $response.StatusCode
	$log = $log + " $(get-date)   -  OMS Data Upload ststus code $($response.StatusCod) " 
}
function WE-Calculate-rate ($meter,[double]$quantity)
{

	$i=0
	$calcCost=$calcSaving=$calcLowestCost=0
	$meterArr=@()
	$meterArr=[array]$meter.MeterRates.psobject.Properties
	If($meterArr.Count -eq 1)
	{
		$calcCost=[double]$meterArr[0].Value*$quantity
	}
	Else
	{
		$i=0
		$remaining=$quantity
		$calcCost=0
		$meter.MeterRates.psobject.Properties|Foreach-object{
			[long]$curname=$_.name
			[double]$curval=$_.value
			" $curname  $curval  -$i"
			IF ($i -gt 0 -and $quantity -gt 0 )
			{
				IF($quantity -le $curname )
				{
					$calcCost = $calcCost + $lastval*$quantity
					" cost =  $lastval * $quantity  =$calcCost"
					$quantity=$quantity-$curname
				}
				Else
				{
					$calcCost = $calcCost + ($curname-$lastname)*$lastval
					$quantity=$quantity-$curname
					" cost =  ($curname - $lastname) * $lastval  , total cost: $calcCost"
					" Reamining $quantity"
					
				}
				
			}
			
			$i++
			$lastname=$curname
			$lastval=$curval
		}
	}
	$calcBillItem = New-Object -ErrorAction Stop PSObject -Property @{
		calcCost=[double]$calcCost
	}
	Return $calcBillItem
}
Function find-lowestcost ($meter)
{

	$filteredMEters=$meters|where{$_.MeterCategory -eq $meter.MeterCategory -and $_.MeterName -eq $WEMeter.MeterName -and $_.MeterSubCategory -eq $meter.MeterSubCategory -and ![string]::IsNullOrEmpty($_.MeterREgion)}
	$sortedMEter=@()
	Foreach($billRegion in $filteredMEters)
	{
		$sortedMeter = $sortedMeter + new-object -ErrorAction Stop PSobject -Property @{
			MeterRegion=$billRegion.MeterRegion
			Meterrates=$billRegion.MeterRates.0
			Rates=$billRegion.MeterRates
			MeterID=$billRegion.MeterId
		}
	}
	$resultarr=@()
	$sortedMEter|where {$_.Meterrates -eq $($sortedMEter|Sort-Object -Property Meterrates |select -First 1).Meterrates}|?{
		$lowestregion = $lowestregion + " $($_.MEterregion),"
		$resultarr = $resultarr + New-Object -ErrorAction Stop PSObject -Property @{
			Lowcostregion=$_.MEterregion
			LowcostregionCost=[double]$_.MeterRates
			Meterid=$_.MeterId
		}
	}
	return $resultarr
}

$WEArmConn = Get-AutomationConnection -Name AzureRunAsConnection       
Write-Output  " Logging in to Azure..."

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

$WECliCert=new-object -ErrorAction Stop   Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate($WEArmConn.ApplicationId,$mycert)
$WEAuthContext = new-object -ErrorAction Stop Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext(" https://login.windows.net/$($WEArmConn.tenantid)" )
$result = $WEAuthContext.AcquireToken(" https://management.core.windows.net/" ,$WECliCert); 
$header = " Bearer " + $result.AccessToken; 
$headers = @{" Authorization" =$header;" Accept" =" application/json" }
$body=$null
$WEHTTPVerb=" GET"
$subscriptionInfoUri = " https://management.azure.com/subscriptions/" +$subscriptionid+" ?api-version=2016-02-01"
$subscriptionInfo = Invoke-RestMethod -Uri $subscriptionInfoUri -Headers $headers -Method Get -UseBasicParsing
IF($subscriptionInfo)
{
	Write-Output   " Successfully connected to Azure ARM REST"
}

$WEScriptBlock = {
	Param ($hash,$meters,$metrics)
	$start=get-date -ErrorAction Stop

	function New-OMSSignature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
	{
		$xHeaders = " x-ms-date:" + $date
		$stringToHash = $method + " `n" + $contentLength + " `n" + $contentType + " `n" + $xHeaders + " `n" + $resource
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
		$method = " POST"
		$contentType = " application/json"
		$resource = " /api/logs"
		$rfc1123date = [DateTime]::UtcNow.ToString(" r" )
		$contentLength = $body.Length
		$params = @{
		    Uri = $uri
		    customerId = $customerId
		    contentLength = $contentLength
		    fileName = $fileName
		    Headers = $WEOMSheaders
		    contentType = $contentType
		    rate = "($meter,[double]$quantity) {"
		    sharedKey = $sharedKey
		    resource = $resource ; 	$uri = " https://" + $customerId + " .ods.opinsights.azure.com" + $resource + " ?api-version=2016-04-01" ; 	$WEOMSheaders = @{ " Authorization" = $signature; " Log-Type" = $logType; " x-ms-date" = $rfc1123date; " time-generated-field" = $WETimeStampField; } $response = Invoke-WebRequest
		    UseBasicParsing = "return $response.StatusCode $log = $log + " $(get-date)"
		    Body = $body
		    date = $rfc1123date
		    method = $method
		}
		$signature @params

		$i=0
		$calcCost=$calcSaving=$calcLowestCost=0
		$meterArr=@()
		$meterArr=[array]$meter.MeterRates.psobject.Properties
		If($meterArr.Count -eq 1)
		{
			$calcCost=[double]$meterArr[0].Value*$quantity
		}
		Else
		{
			$i=0
			$remaining=$quantity
			$calcCost=0
			$meter.MeterRates.psobject.Properties|Foreach-object{
				[long]$curname=$_.name
				[double]$curval=$_.value
				" $curname  $curval  -$i"
				IF ($i -gt 0 -and $quantity -gt 0 )
				{
					IF($quantity -le $curname )
					{
						$calcCost = $calcCost + $lastval*$quantity
						" cost =  $lastval * $quantity  =$calcCost"
						$quantity=$quantity-$curname
					}
					Else
					{
						$calcCost = $calcCost + ($curname-$lastname)*$lastval
						$quantity=$quantity-$curname
						" cost =  ($curname - $lastname) * $lastval  , total cost: $calcCost"
						" Reamining $quantity"
						
					}
					
				}
				
				$i++
				$lastname=$curname
				$lastval=$curval
			}
		}

		$filteredMEters=$meters|where{$_.MeterCategory -eq $meter.MeterCategory -and $_.MeterName -eq $WEMeter.MeterName -and $_.MeterSubCategory -eq $meter.MeterSubCategory -and ![string]::IsNullOrEmpty($_.MeterREgion)}
		$sortedMEter=@()
		Foreach($billRegion in $filteredMEters)
		{
			$sortedMeter = $sortedMeter + new-object -ErrorAction Stop PSobject -Property @{
				MeterRegion=$billRegion.MeterRegion
				Meterrates=$billRegion.MeterRates.0
				Rates=$billRegion.MeterRates
			}
		}
		$sortedMEter|where {$_.Meterrates -eq $($sortedMEter|Sort-Object -Property Meterrates |select -First 1).Meterrates}|?{$lowestregion = $lowestregion + " $($_.MEterregion)," }
		If ($lowestregion -match $meter.MeterRegion)
		{
			$calcLowestCost=$calcCost
			$calcSaving=0
		}
		Else
		{
			$calcLowestCost=0
			$lowestRate=($sortedMEter|Sort-Object -Property Meterrates |select -First 1).Rates
			$meterArr=[array]$lowestRate.psobject.Properties
			If($meterArr.Count -eq 1)
			{
				$calcLowestCost=[double]$meterArr[0].Value*$quantity
			}
			Else
			{
				$i=0
				$remaining=$quantity
				$calcLowestCost=0
				$lowestRate.psobject.Properties|Foreach-object{
					[long]$curname=$_.name
					[double]$curval=$_.value
					" $curname  $curval  -$i"
					IF ($i -gt 0 -and $quantity -gt 0 )
					{
						IF($quantity -le $curname )
						{
							$calcLowestCost = $calcLowestCost + $lastval*$quantity
							" cost =  $lastval * $quantity  =$calcLowestCost"
							$quantity=$quantity-$curname
						}
						Else
						{
							$calcLowestCost = $calcLowestCost + ($curname-$lastname)*$lastval
							$quantity=$quantity-$curname
							" cost =  ($curname - $lastname) * $lastval  , total cost: $calcLowestCost"
							" Remaining $quantity"
							
						}
						
					}
					
					$i++
					$lastname=$curname
					$lastval=$curval
				}
			}
			$calcSaving=$calcCost-$calcLowestCost
		}

		$calcBillItem = New-Object -ErrorAction Stop PSObject -Property @{
			calcCost=[double]$calcCost
		}
		Return $calcBillItem
	}
	Function find-lowestcost ($meter)
	{
		$filteredMEters=$meters|where{$_.MeterCategory -eq $meter.MeterCategory -and $_.MeterName -eq $WEMeter.MeterName -and $_.MeterSubCategory -eq $meter.MeterSubCategory -and ![string]::IsNullOrEmpty($_.MeterREgion)}
		$sortedMEter=@()
		Foreach($billRegion in $filteredMEters)
		{
			$sortedMeter = $sortedMeter + new-object -ErrorAction Stop PSobject -Property @{
				MeterRegion=$billRegion.MeterRegion
				Meterrates=$billRegion.MeterRates.0
				Rates=$billRegion.MeterRates
				MeterID=$billRegion.MeterId
			}
		}
		$resultarr=@()
		$sortedMEter|where {$_.Meterrates -eq $($sortedMEter|Sort-Object -Property Meterrates |select -First 1).Meterrates}|?{
			$lowestregion = $lowestregion + " $($_.MEterregion),"
			$resultarr = $resultarr + New-Object -ErrorAction Stop PSObject -Property @{
				Lowcostregion=$_.MEterregion
				LowcostregionCost=[double]$_.MeterRates
				Meterid=$_.MeterId
			}
		}
		return $resultarr
	}

	$subscriptionInfo=$hash.subscriptionInfo
	$WEArmConn=$hash.ArmConn
	$headers=$hash.headers
	$WETimestampfield = $hash.Timestampfield
	$WEApiVersion = $hash.ApiVersion 
	$WECurrency=$hash.Currency
	$WELocale=$hash.Locale
	$WERegionInfo=$hash.RegionInfo
	$WEOfferDurableId=$hash.OfferDurableId
	$syncInterval=$WEHash.syncInterval
	$allrg=$hash.allrg
	$resmap=$hash.resmap

	$customerID =$hash.customerID 

	$sharedKey = $hash.sharedKey

	$logname=$hash.Logname

	$colbilldata=@()
	$colTaggedbilldata=@()
	$ratescache=@{}
	$count=1
	$metrics|Foreach{
		$metricitem=$null
		$metricitem=$_
		$obj=$resid=$location=$resource=$null
		IF($metricitem.instanceData)
		{
			$insdata=$cu=$null
			$insdata=(convertfrom-json $metricitem.instanceData).'Microsoft.Resources'
			$resid=$insdata.resourceUri
			$rg=$allrg|where {$_.Name -eq $resid.Split('/')[4]}
			$tag=$null
			$tags=$null
			$tags=@{}
			$restag=$null
			$restag=(convertfrom-json $metricitem.instanceData).'Microsoft.Resources'.tags
			If ($restag)
			{
				$restag.PSObject.Properties | foreach-object {
					
					# add the tag if not  in the list already 
					$tags.add($_.Name,$_.value)
					# $tags|add-member -MemberType NoteProperty -Name -ea 0
				}   
			}
			$WEUsageType=$insdata.additionalInfo.UsageType
			$WEMeter=($meters|where {$_.meterid -eq $metricitem.meterId})
		; 	$price=Calculate-rate -meter $meter -quantity $metricitem.quantity
		; 	$cu = New-Object -ErrorAction Stop PSObject -Property @{
				Timestamp = $metricitem.usageStartTime
				Collectiontime=$colltime 
				meterCategory= $WEMeter.meterCategory
				meterSubCategory= $WEMeter.meterSubCategory
				meterName= $WEMeter.meterName 
				unit=$metricitem.unit
				quantity=$metricitem.quantity
				Location=$insdata.location
				ResourceGroup=$insdata.resourceUri.Split('/')[4]
				Cost=$price.calcCost
				SubscriptionId = $WEArmConn.SubscriptionID;
				AzureSubscription = $subscriptionInfo.displayname;
				usageEndTime=$metricitem.usageEndTime 
				UsageType=$insdata.additionalInfo.UsageType
				Resource=$insdata.resourceUri.Split('/')[$insdata.resourceUri.Split('/').count-1]
				Aggregation=$syncInterval
				CostTag='Overall'
				OfferDurableId=$WEOfferDurableId
				Currency=$WECurrency
				Locale=$WELocale
				RegionInfo=$WERegionInfo
			}
			#adding to array
			$colbilldata = $colbilldata + $cu
			#  Write-verbose $cu -Verbose
			IF($propagatetags -eq $true -and ![string]::IsNullOrEmpty($rg.tags) )
			{ 
				$rg.tags.PSObject.Properties | foreach-object {
					
					# add the tag if not  in the list already 
					$tags.add($_.Name,$_.value)
				}        
			}
			
			If($tags)
			{
				foreach ($tag in $tags.Keys)
				{
					
				; 	$cu = New-Object -ErrorAction Stop PSObject -Property @{
						Timestamp = $metricitem.usageStartTime
						Collectiontime=$colltime 
						meterCategory= $meter.meterCategory
						meterSubCategory= $meter.meterSubCategory
						meterName= $meter.meterName 
						unit=$metricitem.unit
						quantity=$metricitem.quantity
						Location=$insdata.location
						ResourceGroup=$insdata.resourceUri.Split('/')[4]
						TaggedCost=$price.calcCost
						SubscriptionId = $WEArmConn.SubscriptionID;
						AzureSubscription = $subscriptionInfo.displayname;
						usageEndTime=$metricitem.usageEndTime 
						
						UsageType=$insdata.additionalInfo.UsageType
						Resource=$insdata.resourceUri.Split('/')[$insdata.resourceUri.Split('/').count-1]
						Aggregation=$syncInterval
						Tag=" $tag : $($tags.item($tag))"
						OfferDurableId=$WEOfferDurableId
						Currency=$WECurrency
						Locale=$WELocale
						RegionInfo=$WERegionInfo
					}
					$cu|add-member -MemberType NoteProperty -Name $tag  -Value $tags.item($tag) -ea 0
					#adding to array
					$colTaggedbilldata = $colTaggedbilldata + $cu
					
					#End tag processing 
				}
			}
		}
		Else{
			$obj=$resid=$meteredRegion=$meteredService=$project=$cu1=$null
			$meteredRegion=$metricitem.infoFields.meteredRegion
			$meteredServiceType=$metricitem.infoFields.meteredServiceType
			$rgcls=$null
			$rg=$null
			IF ($metricitem.infoFields.meteredservice -eq 'Compute')
			{
				$rgcls=$metricitem.infoFields.project.Split('(')[0]
				$rg=$allrg|where {$_.Name -eq $rgcls}
			}Else
			{
				$rgcls=($resmap|where{$_.Resource -eq " $($metricitem.infoFields.project)" }).Resourcegroup
				$rg=$allrg|where {$_.Name -eq $rgcls}
			}
			$project=$metricitem.infoFields.project
			$price=$null
			$WEMeter=($meters|where {$_.meterid -eq $metricitem.meterId})
		; 	$price=Calculate-rate -meter $meter -quantity $metricitem.quantity
		; 	$cu1 = New-Object -ErrorAction Stop PSObject -Property @{
				
				Timestamp = $metricitem.usageStartTime
				Collectiontime=$colltime 
				meterCategory= $meter.meterCategory
				meterSubCategory= $meter.meterSubCategory
				meterName= $meter.meterName 
				unit=$metricitem.unit
				quantity=$metricitem.quantity
				Location=$metricitem.infoFields.meteredRegion
				ResourceGroup=$WERgcls
				Cost=$price.calcCost
				SubscriptionId = $WEArmConn.SubscriptionID;
				AzureSubscription = $subscriptionInfo.displayname;
				usageEndTime=$metricitem.usageEndTime 
				Resource= $metricitem.infoFields.project
				Aggregation=$syncInterval
				CostTag=" Overall"
				OfferDurableId=$WEOfferDurableId
				Currency=$WECurrency
				Locale=$WELocale
				RegionInfo=$WERegionInfo
			}
			#adding to array
			$colbilldata = $colbilldata + $cu1
			#  Write-Verbose $cu1 -Verbose
			IF($propagatetags -eq $true -and ![string]::IsNullOrEmpty($rg.Tags) )
			{
				" tags $($rg.Tags) added to classic res"
				
				
				$rg.tags.PSObject.Properties | foreach-object {
					
					# add the tag if not  in the list already 
					$tags.add($_.Name,$_.value)
					# $tags|add-member -MemberType NoteProperty -Name -ea 0
				}   
				foreach ($tag in $tags.Keys)
				{
					
					
				; 	$cu1=$null
				; 	$cu1 = New-Object -ErrorAction Stop PSObject -Property @{
						Timestamp = $metricitem.usageStartTime
						Collectiontime=$colltime                                     
						meterCategory= $meter.meterCategory
						meterSubCategory= $meter.meterSubCategory
						meterName= $meter.meterName 
						unit=$metricitem.unit
						quantity=$metricitem.quantity
						Location=$metricitem.infoFields.meteredRegion
						ResourceGroup=$WERgcls
						TaggedCost=$price.calcCost
						SubscriptionId = $WEArmConn.SubscriptionID;
						AzureSubscription = $subscriptionInfo.displayname;
						usageEndTime=$metricitem.usageEndTime 
						Resource= $metricitem.infoFields.project
						Aggregation=$syncInterval
						Tag=" $tag : $($tags.item($tag))" 
						OfferDurableId=$WEOfferDurableId
						Currency=$WECurrency
						Locale=$WELocale
						RegionInfo=$WERegionInfo
						
					}
					$cu1|add-member -MemberType NoteProperty -Name $tag  -Value $tags.item($tag) -ea 0
					#adding to array
					$colTaggedbilldata = $colTaggedbilldata + $cu1  
					
					
					#End tag processing 
				}
			}
		}
		$count++
	}
	$jsoncolbill = ConvertTo-Json -InputObject $colbilldata

	If($jsoncolbill){$postres=Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsoncolbill)) -logType $logname}
	If ($postres -ge 200 -and $postres -lt 300)
	{
		#Write-Output " Succesfully uploaded $($colbilldata.count) usage metrics to OMS"
	}
	Else
	{
		Write-Warning " Failed to upload  $($colbilldata.count)  metrics to OMS"
	}
	IF($colTaggedbilldata)
	{
		$jsoncolbill = ConvertTo-Json -InputObject $colTaggedbilldata

		If($jsoncolbill){$postres=Post-OMSData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($jsoncolbill)) -logType $logname}
		If ($postres -ge 200 -and $postres -lt 300)
		{
			#Write-Output " Succesfully uploaded $($colTaggedbilldata.count) tagged usage metrics to OMS"
		}
		Else
		{
			Write-Warning " Failed to upload  $($colTaggedbilldata.count) tagged usage metrics to OMS"
		}
	}

	$end=get-date -ErrorAction Stop
	$timetaken = ($end-$start).Totalseconds
	Write-Information " $timetaken   seconds ..." -Verbose
}

Write-Output " Getting all available rates... "
$uri= " https://management.azure.com/subscriptions/{5}/providers/Microsoft.Commerce/RateCard?api-version={0}&`$filter=OfferDurableId eq '{1}' and Currency eq '{2}' and Locale eq '{3}' and RegionInfo eq '{4}'" -f $WEApiVersion, $WEOfferDurableId, $WECurrency, $WELocale, $WERegionIso, $WESubscriptionId
$resp=Invoke-WebRequest -Uri $uri -Method GET  -Headers $headers -UseBasicParsing -Timeout 180
$res=ConvertFrom-Json -InputObject $resp.Content
$WEMeters=$res.meters
If([string]::IsNullOrEmpty($WEMeters))
{
	Write-warning " Rates are not available ,  runbook will try again after 15 minutes"
	$rescheduleRB=$true 

	exit
}

$WEUri=" https://management.azure.com/subscriptions/$subscriptionid/resourcegroups?api-version=2016-09-01"
$resp=Invoke-WebRequest -Uri $uri -Method GET  -Headers $headers -UseBasicParsing -TimeoutSec 180
$res=@()
$content=ConvertFrom-Json -InputObject $resp.Content
$res = $res + $content
IF(![string]::IsNullOrEmpty($res.nextLink))
{
	do 
	{
		$uri2=$content.nextLink
		$content=$null
		$resultarm = Invoke-WebRequest -Method $WEHTTPVerb -Uri $uri2 -Headers $headers -UseBasicParsing
		$content=$resultarm.Content
		$content= ConvertFrom-Json -InputObject $resultarm.Content
		$res = $res + $content
		$uri2=$null
	}While (![string]::IsNullOrEmpty($content.nextLink))
}
$allRg=$res.value
$WEUriresources=" https://management.azure.com/subscriptions/$subscriptionid/resources?api-version=2016-09-01" 
$respresources=Invoke-WebRequest -Uri $uriresources -Method GET  -Headers $headers -UseBasicParsing -TimeoutSec 180
$resresources=@()
$resresources = $resresources + ConvertFrom-Json -InputObject $respresources.Content
IF(![string]::IsNullOrEmpty($resresources.nextLink))
{
	do 
	{
		
		$uri2=$resresources.nextLink
		$content=$null
		$resultarm = Invoke-WebRequest -Method $WEHTTPVerb -Uri $uri2 -Headers $headers -UseBasicParsing
		$content=$resultarm.Content
		$content= ConvertFrom-Json -InputObject $resultarm.Content
		$resresources = $resresources + $content
		$uri2=$null
	}While (![string]::IsNullOrEmpty($content.nextLink))
}
write-output " $($resresources.value.count) resources found"
$resmap=@()   
foreach($azres in $resresources.value)
{
	$resgrp=$null
	$resgrp=$azres.id.split('/')[4]
	$resmap = $resmap + New-Object -ErrorAction Stop PSObject -Property @{
		
		Resource=$azres.name
		REsourceGroup=$resgrp
		Type=$azres.type
	}
}

IF($syncInterval -eq 'Hourly')
{
	$end=(get-date).AddHours(-1).ToUniversalTime().ToString(" yyyy-MM-dd'T'HH:00:00" )
	$start=(get-date).AddHours(-2).ToUniversalTime().ToString(" yyyy-MM-dd'T'HH:00:00" )
	$WEUri=" https://management.azure.com/subscriptions/$subscriptionid/providers/Microsoft.Commerce/UsageAggregates?api-version=2015-06-01-preview&reportedStartTime=$start&reportedEndTime=$end&aggregationGranularity=$syncInterval&showDetails=true"
}
Else
{
	$end=(get-date).ToUniversalTime().ToString(" yyyy-MM-dd'T'00:00:00" )
	$start=(get-date).Adddays(-1).ToUniversalTime().ToString(" yyyy-MM-dd'T'00:00:00" )
	$WEUri=" https://management.azure.com/subscriptions/$subscriptionid/providers/Microsoft.Commerce/UsageAggregates?api-version=2015-06-01-preview&reportedStartTime=$start&reportedEndTime=$end&aggregationGranularity=$syncInterval&showDetails=true"
}
Write-Output " Fetching Usage data for  $start (UTC) and $end (UTC) , Currency :$WECurrency Locate : $WELocale ,Region: $WERegionIso , Azure Subs Type : $WEOfferDurableId "
$resp=Invoke-WebRequest -Uri $uri -Method GET  -Headers $headers -UseBasicParsing  -TimeoutSec 180
$res=@()
$content=ConvertFrom-Json -InputObject $resp.Content
$res = $res + $content
IF(![string]::IsNullOrEmpty($res.nextLink))
{
	do 
	{
		$uri2=$content.nextLink
		$content=$null
		$resultarm = Invoke-WebRequest -Method $WEHTTPVerb -Uri $uri2 -Headers $headers -UseBasicParsing
		$content=$resultarm.Content
		$content= ConvertFrom-Json -InputObject $resultarm.Content
		$res = $res + $content
		$uri2=$null
	}While (![string]::IsNullOrEmpty($content.nextLink))
}
$metrics=$res.value.Properties
$metrics=$metrics|Sort-Object -Property metercategory -Descending 

Write-output " $($metrics.count) usage metrics  found "; 
$spltlist=@()
If($metrics.count -gt 200)
{
; 	$splitSize=200
; 	$spltlist = $spltlist + for ($WEIndex = 0; $WEIndex -lt  $metrics.Count; $WEIndex = $WEIndex + $splitSize)
	{
		,($metrics[$index..($index+$splitSize-1)])
	}
}Elseif($metrics.count -gt 100)
{
	$splitSize=100
; 	$spltlist = $spltlist + for ($WEIndex = 0; $WEIndex -lt  $metrics.Count; $WEIndex = $WEIndex + $splitSize)
	{
		,($metrics[$index..($index+$splitSize-1)])
	}
}Else{
	$spltlist = $spltlist + ,($metrics)
}

$hash = [hashtable]::New(@{})

$hash['Host']=$host
$hash['subscriptionInfo']=$subscriptionInfo
$hash['ArmConn']=$WEArmConn
$hash['headers']=$headers
$hash['Timestampfield']=$WETimestampfield
$hash['ApiVersion'] =$WEApiVersion 
$hash['Currency']=$WECurrency
$hash['Locale']=$WELocale
$hash['RegionInfo']=$WERegionInfo
$hash['OfferDurableId']=$WEOfferDurableId
$hash['allrg']=$allrg
$hash['resmap']=$resmap
$hash['customerID'] =$customerID
$hash['syncInterval']=$syncInterval
$hash['sharedKey']=$sharedKey 
$hash['Logname']=$logname
$WEThrottle = 6 #threads
$sessionstate = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
$runspacepool = [runspacefactory]::CreateRunspacePool(1, $WEThrottle, $sessionstate, $WEHost)
$runspacepool.Open() 
$WEJobs = @()
write-output " $($metrics.count) objects will be processed "
$i=1 
$spltlist|foreach{
	$splitmetrics=$null
	$splitmetrics=$_
	$WEJob = [powershell]::Create().AddScript($WEScriptBlock).AddArgument($hash).AddArgument($meters).AddArgument($splitmetrics)
	$WEJob.RunspacePool = $WERunspacePool
; 	$WEJobs = $WEJobs + New-Object -ErrorAction Stop PSObject -Property @{
		RunNum = $_
		Pipe = $WEJob
		Result = $WEJob.BeginInvoke()
	}
	write-output  " $(get-date)  , started Runsapce $i "
	$i++
}
Write-Output " Waiting.."
Do {
	Start-Sleep -Seconds 60
} While ( $WEJobs.Result.IsCompleted -contains $false)
Write-WELog " All jobs completed!" " INFO" ; 
$WEResults = @()
ForEach ($WEJob in $WEJobs)
{
; 	$WEResults = $WEResults + $WEJob.Pipe.EndInvoke($WEJob.Result)
	if($jobs[0].Pipe.HadErrors)
	{
		write-warning " $($jobs.Pipe.Streams.Error.exception)"
	}
}

$jobs|foreach{$_.Pipe.Dispose()}
$runspacepool.Close()
[gc]::Collect()


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
