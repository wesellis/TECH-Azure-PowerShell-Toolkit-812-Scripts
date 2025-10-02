#Requires -Version 7.4
<#
.SYNOPSIS
    Brief description of the Windows Imagelog script functionality
.DESCRIPTION
    Detailed description of what the Windows Imagelog script does and how it works.
    This script provides [specific functionality] and supports [key features].

    Key capabilities:
    - [Capability 1]
    - [Capability 2]
    - [Capability 3]

.PARAMETER true
    Description of the true parameter and its expected values
.EXAMPLE
    .\Windows Imagelog.ps1

    Basic example showing how to run the script with default parameters.
.EXAMPLE
    .\Windows Imagelog.ps1 -Parameter "Value"

    Example showing script usage with specific parameter values.
.INPUTS
    System.String
    Objects that can be piped to this script
.OUTPUTS
    System.Object
    Objects that this script outputs to the pipeline
.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Created: October 14, 2024
    Version: 1.0.0

    Requirements:
    - PowerShell 7.0 or later
    - [Additional requirements as needed]

    Change Log:
    1.0.0 - 2024-10-14 - Initial version
.LINK
    https://github.com/wesellis/scripts
.LINK
    about_Comment_Based_Help
    Windows Imagelog
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
     Gathers various image build details and writes them to a .json file in the .tool directory and a customer .txt version to the desktop (useful for for image customizations troubleshooting).
.PARAMETER BicepInfo
    String of parameter details from Bicep in base64 string format.
.PARAMETER UsefulTagsList
    List of tags to include in the report.
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
    [Parameter(Mandatory = $true)][String] $BicepInfo,
    [Parameter(Mandatory = $false)][String] $UsefulTagsList = " correlationId,createdBy,imageTemplateName,imageTemplateResourceGroupName"
)
function Add-VarForLogging ($VarName, $VarValue) {
    if ((!([string]::IsNullOrWhiteSpace($VarValue))) -or $VarValue.Count -gt 0) {
    $global:varLogArray | Add-Member -MemberType NoteProperty -Name $VarName -Value $VarValue
    }
}
Set-StrictMode -Version Latest
Write-Output "Starting log file write to desktop and DRI report location"
    $script:varLogArray = New-Object -TypeName "PSCustomObject"
    $NewLine = [Environment]::NewLine
    $LogBreak = $NewLine + '=============================================================================' + $NewLine
    $CurrentTime = Get-Date -ErrorAction Stop
    $UsefulTags = $UsefulTagsList.Split(" ," )
    $ImageInfoJsonDir = "C:\.tools\Setup"
    $ImageInfoJsonFile = " $ImageInfoJsonDir\ImageInfo.json"
    $ImageInfoTextFile = [Environment]::GetFolderPath('CommonDesktopDirectory') + " \ImageBuildReport.txt"
    $RepoLogFilePath = 'c:\.tools\RepoLogs'
    $ReportHeader = "Image Build Report at " + $CurrentTime.ToUniversalTime() + $NewLine + "More details can be found at $ImageInfoJsonFile"
try {
    mkdir " $ImageInfoJsonDir" -Force
    Write-Output "Building " $ImageInfoJsonFile
    $BicepData = [Text.Encoding]::ASCII.GetString([Convert]::FromBase64String($BicepInfo)) | ConvertFrom-Json
    Add-VarForLogging -varName "BicepParameters" -varValue $BicepData
    Write-Output "Calling compute API to get image tags."
    $VmTags = (Invoke-RestMethod -Headers @{"Metadata" = " true" } -Uri " http://169.254.169.254/metadata/instance/compute?api-version=2021-02-01" ).tags
    Write-Output "VM Tags : " $VmTags
    Write-Output "Process image tags."
    $VmTagsList = $VmTags.Split(" ;" )
    $TagOut = New-Object -TypeName "PSCustomObject"
    foreach ($tag in $VmTagsList) {
        if (($tag.Split(" :" , 2))[0] -in $UsefulTags) {
    $TagOut | Add-Member -MemberType NoteProperty -Name ($tag.Split(" :" , 2))[0] -Value ($tag.Split(" :" , 2))[1]
        }
    }
    Add-VarForLogging -varName "VMTags" -varValue $TagOut
    $RepoOut = @()
    $RepoFiles = Get-ChildItem -File $RepoLogFilePath -Recurse -Include " *.json"  -ErrorAction SilentlyContinue
    foreach ($row in $RepoFiles) {
    $RepoData = get-content -Path $row.FullName | ConvertFrom-Json
    $RepoData | Add-Member -MemberType NoteProperty -Name "RepoName" -Value $row.BaseName
    $RepoOut = $RepoOut + $RepoData
    }
    Add-VarForLogging -varName "Repos" -varValue $RepoOut
    Write-Output "Write json output file to " $ImageInfoJsonFile
    $global:varLogArray | ConvertTo-Json -Depth 10 | Out-File -FilePath $ImageInfoJsonFile
    Get-Content -ErrorAction Stop $ImageInfoJsonFile
    Write-Output "Write text output file to " $ImageInfoTextFile
    $RepoDetail = ""
    $TagsDetail = ""
    if ([bool]($global:varLogArray.PSobject.Properties.name -match "Repos" )) {
    $RepoDetail = $global:varLogArray.Repos | ConvertTo-Json
    }
    if ([bool]($global:varLogArray.PSobject.Properties.name -match "VMTags" )) {
    $TagsDetail = $global:varLogArray.VMTags
    }
    $ReportHeader, $LogBreak, "Bicep Parameters : " , $($global:varLogArray.BicepParameters | ConvertTo-Json -Depth 10), $LogBreak, "VM Image Tags : " , $TagsDetail, $LogBreak, "Repos : " , $RepoDetail | Out-File -FilePath $ImageInfoTextFile
    Get-Content -ErrorAction Stop $ImageInfoTextFile
    Write-Output "Delete RepoLog directory now that it is no longer needed."
    Remove-Item -ErrorAction Stop $RepoLogFilePat -Forceh -Force -Recurse -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop`n}
