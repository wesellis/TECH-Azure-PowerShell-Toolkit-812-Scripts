#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Windows Imagelog

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
    We Enhanced Windows Imagelog

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
.DESCRIPTION
     Gathers various image build details and writes them to a .json file in the .tool directory and a customer .txt version to the desktop (useful for for image customizations troubleshooting).
.PARAMETER BicepInfo
    String of parameter details from Bicep in base64 string format.
.PARAMETER UsefulTagsList
    List of tags to include in the report.
.EXAMPLE
    Sample Bicep snippet for using the artifact:

    {
      name: 'windows-imagelog'
      parameters: {
        BicepInfo: base64(string(allParamsForLogging))
      }
    }


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $true)][String] $WEBicepInfo,
    [Parameter(Mandatory = $false)][String] $WEUsefulTagsList = " correlationId,createdBy,imageTemplateName,imageTemplateResourceGroupName"
)

#region Functions

function WE-Add-VarForLogging ($varName, $varValue) {
    <#
  .DESCRIPTION
  Add a row to the logging array but only if the value is not null or whitespace, or if an object then count is gt 0.
  .PARAMETER varName
  Name of the variable  
  .PARAMETER varValue
  Value of the variable
  #>

    if ((!([string]::IsNullOrWhiteSpace($varValue))) -or $varValue.Count -gt 0) {
        $global:varLogArray | Add-Member -MemberType NoteProperty -Name $varName -Value $varValue
    }
}

$WEErrorActionPreference = " Stop"
Set-StrictMode -Version Latest
Write-WELog " Starting log file write to desktop and DRI report location" " INFO"


$script:varLogArray = New-Object -TypeName " PSCustomObject"
$newLine = [Environment]::NewLine
$logBreak = $newLine + '=============================================================================' + $newLine
$currentTime = Get-Date -ErrorAction Stop
$usefulTags = $WEUsefulTagsList.Split(" ," )
$imageInfoJsonDir = " C:\.tools\Setup"
$imageInfoJsonFile = " $imageInfoJsonDir\ImageInfo.json"
$imageInfoTextFile = [Environment]::GetFolderPath('CommonDesktopDirectory') + " \ImageBuildReport.txt"
$repoLogFilePath = 'c:\.tools\RepoLogs'
$reportHeader = " Image Build Report at " + $currentTime.ToUniversalTime() + $newLine + " More details can be found at $imageInfoJsonFile"

try {
    # Create JSON log file location
    mkdir " $imageInfoJsonDir" -Force

    # Build json data to be output to file
    Write-WELog " Building " " INFO" $imageInfoJsonFile
    $bicepData = [Text.Encoding]::ASCII.GetString([Convert]::FromBase64String($WEBicepInfo)) | ConvertFrom-Json
    Add-VarForLogging -varName " BicepParameters" -varValue $bicepData

    Write-WELog " Calling compute API to get image tags." " INFO"
   ;  $vmTags = (Invoke-RestMethod -Headers @{" Metadata" = " true" } -Uri " http://169.254.169.254/metadata/instance/compute?api-version=2021-02-01" ).tags
    Write-WELog " VM Tags : " " INFO" $vmTags
    Write-WELog " Process image tags." " INFO"
   ;  $vmTagsList = $vmTags.Split(" ;" )
    $tagOut = New-Object -TypeName " PSCustomObject"
    foreach ($tag in $vmTagsList) {
        if (($tag.Split(" :" , 2))[0] -in $usefulTags) {
            $tagOut | Add-Member -MemberType NoteProperty -Name ($tag.Split(" :" , 2))[0] -Value ($tag.Split(" :" , 2))[1]
        }
    }
    Add-VarForLogging -varName " VMTags" -varValue $tagOut

    # Get Repo data
    $repoOut = @()
    $repoFiles = Get-ChildItem -File $repoLogFilePath -Recurse -Include " *.json"  -ErrorAction SilentlyContinue
    foreach ($row in $repoFiles) {
        $repoData = get-content -Path $row.FullName | ConvertFrom-Json
        $repoData | Add-Member -MemberType NoteProperty -Name " RepoName" -Value $row.BaseName
        $repoOut = $repoOut + $repoData 
    }
    Add-VarForLogging -varName " Repos" -varValue $repoOut

    # Write JSON file
    Write-WELog " Write json output file to " " INFO" $imageInfoJsonFile
    $global:varLogArray | ConvertTo-Json -Depth 10 | Out-File -FilePath $imageInfoJsonFile
    Get-Content -ErrorAction Stop $imageInfoJsonFile

    # Build and write customer image info text file
    Write-WELog " Write text output file to " " INFO" $imageInfoTextFile
    $repoDetail = ""
    $tagsDetail = ""
    if ([bool]($global:varLogArray.PSobject.Properties.name -match " Repos" )) {
       ;  $repoDetail = $global:varLogArray.Repos | ConvertTo-Json
    }
    if ([bool]($global:varLogArray.PSobject.Properties.name -match " VMTags" )) {
       ;  $tagsDetail = $global:varLogArray.VMTags 
    }
    $reportHeader, $logBreak, " Bicep Parameters : " , $($global:varLogArray.BicepParameters | ConvertTo-Json -Depth 10), $logBreak, " VM Image Tags : " , $tagsDetail, $logBreak, " Repos : " , $repoDetail | Out-File -FilePath $imageInfoTextFile
    Get-Content -ErrorAction Stop $imageInfoTextFile

    Write-WELog " Delete RepoLog directory now that it is no longer needed." " INFO"
    Remove-Item -ErrorAction Stop $repoLogFilePat -Forceh -Force -Recurse -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop
}

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
