#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Scriptworkflow

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
    We Enhanced Scriptworkflow

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


Param($WEDomainFullName,$WECM,$WECMUser,$WEDPMPName,$WEClientName,$WEConfig,$WECurrentRole,$WELogFolder,$WECSName,$WEPSName)

$WECSRole = "CAS"
$WEPSRole = " PS1"

$WERole = $WEPSRole
if($WECurrentRole -eq " CS" )
{
    $WERole = $WECSRole
}
$WEProvisionToolPath = " $env:windir\temp\ProvisionScript"
if(!(Test-Path $WEProvisionToolPath))
{
    New-Item -ErrorAction Stop $WEProvisionToolPath -ItemType directory | Out-Null
}

$WEConfigurationFile = Join-Path -Path $WEProvisionToolPath -ChildPath " $WERole.json"

if (Test-Path -Path $WEConfigurationFile) 
{
    $WEConfiguration = Get-Content -Path $WEConfigurationFile | ConvertFrom-Json
} 
else 
{
    if($WEConfig -eq " Standalone" )
    {
        [hashtable]$WEActions = @{
            InstallSCCM = @{
                Status = 'NotStart'
                StartTime = ''
                EndTime = ''
            }
            UpgradeSCCM = @{
                Status = 'NotStart'
                StartTime = ''
                EndTime = ''
            }
            InstallDP = @{
                Status = 'NotStart'
                StartTime = ''
                EndTime = ''
            }
            InstallMP = @{
                Status = 'NotStart'
                StartTime = ''
                EndTime = ''
            }
            InstallClient = @{
                Status = 'NotStart'
                StartTime = ''
                EndTime = ''
            }
        }
    }
    else 
    {
        if($WECurrentRole -eq " CS" )
        {
            [hashtable]$WEActions = @{
                InstallSCCM = @{
                    Status = 'NotStart'
                    StartTime = ''
                    EndTime = ''
                }
                UpgradeSCCM = @{
                    Status = 'NotStart'
                    StartTime = ''
                    EndTime = ''
                }
                PSReadytoUse = @{
                    Status = 'NotStart'
                    StartTime = ''
                    EndTime = ''
                }
            }
        }
        elseif($WECurrentRole -eq " PS" ) 
        {
            [hashtable]$WEActions = @{
                WaitingForCASFinsihedInstall = @{
                    Status = 'NotStart'
                    StartTime = ''
                    EndTime = ''
                }
                InstallSCCM = @{
                    Status = 'NotStart'
                    StartTime = ''
                    EndTime = ''
                }
                InstallDP = @{
                    Status = 'NotStart'
                    StartTime = ''
                    EndTime = ''
                }
                InstallMP = @{
                    Status = 'NotStart'
                    StartTime = ''
                    EndTime = ''
                }
                InstallClient = @{
                    Status = 'NotStart'
                    StartTime = ''
                    EndTime = ''
                }
            }
        }
    }
    $WEConfiguration = New-Object -TypeName psobject -Property $WEActions
    $WEConfiguration | ConvertTo-Json | Out-File -FilePath $WEConfigurationFile -Force
}

if($WEConfig -eq " Standalone" )
{
    #Install CM and Config
    $WEScriptFile = Join-Path -Path $WEProvisionToolPath -ChildPath " InstallAndUpdateSCCM.ps1"

    . $WEScriptFile $WEDomainFullName $WECM $WECMUser $WERole $WEProvisionToolPath

    #Install DP
    $WEScriptFile = Join-Path -Path $WEProvisionToolPath -ChildPath " InstallDP.ps1"

    . $WEScriptFile $WEDomainFullName $WEDPMPName $WERole $WEProvisionToolPath

    #Install MP
    $WEScriptFile = Join-Path -Path $WEProvisionToolPath -ChildPath " InstallMP.ps1"

    . $WEScriptFile $WEDomainFullName $WEDPMPName $WERole $WEProvisionToolPath

    #Install Client
    $WEScriptFile = Join-Path -Path $WEProvisionToolPath -ChildPath " InstallClient.ps1"

    . $WEScriptFile $WEDomainFullName $WECMUser $WEClientName $WEDPMPName $WERole $WEProvisionToolPath
}
else {
    if($WECurrentRole -eq " CS" )
    {
        #Install CM and Config
        $WEScriptFile = Join-Path -Path $WEProvisionToolPath -ChildPath " InstallCSForHierarchy.ps1"
    
        . $WEScriptFile $WEDomainFullName $WECM $WECMUser $WERole $WEProvisionToolPath $WELogFolder $WEPSName $WEPSRole

    }
    elseif($WECurrentRole -eq " PS" )
    {
        #Install CM and Config
        $WEScriptFile = Join-Path -Path $WEProvisionToolPath -ChildPath " InstallPSForHierarchy.ps1"
    
        . $WEScriptFile $WEDomainFullName $WECM $WECMUser $WERole $WEProvisionToolPath $WECSName $WECSRole $WELogFolder
    
        #Install DP
        $WEScriptFile = Join-Path -Path $WEProvisionToolPath -ChildPath " InstallDP.ps1"
    
        . $WEScriptFile $WEDomainFullName $WEDPMPName $WERole $WEProvisionToolPath
    
        #Install MP
       ;  $WEScriptFile = Join-Path -Path $WEProvisionToolPath -ChildPath " InstallMP.ps1"
    
        . $WEScriptFile $WEDomainFullName $WEDPMPName $WERole $WEProvisionToolPath

        #Install Client
       ;  $WEScriptFile = Join-Path -Path $WEProvisionToolPath -ChildPath " InstallClient.ps1"

        . $WEScriptFile $WEDomainFullName $WECMUser $WEClientName $WEDPMPName $WERole $WEProvisionToolPath
    }
}

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
