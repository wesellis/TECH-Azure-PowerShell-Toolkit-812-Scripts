#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Oms

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
    We Enhanced Oms

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


Configuration OMS
{
  
    $WEOMSPackageLocalPath = 'C:\MMA\MMASetup-AMD64.exe'
   ;  $WEOMSWorkspaceId = Get-AutomationVariable -Name 'OMSWorkspaceId'
   ;  $WEOMSWorkspaceKey = Get-AutomationVariable -Name 'OMSWorkspaceKey'


    Import-DscResource -ModuleName xPSDesiredStateConfiguration

    Node localhost {
        Service OMSService
        {
            Name = "HealthService"
            State = " Running"
        } 

        xRemoteFile OMSPackage {
            Uri = " https://go.microsoft.com/fwlink/?LinkID=517476"
            DestinationPath = $WEOMSPackageLocalPath
        }

        Package OMS {
            Ensure = " Present"
            Path  = $WEOMSPackageLocalPath
            Name = 'Microsoft Monitoring Agent'
            ProductId = '8A7F2C51-4C7D-4BFD-9014-91D11F24AAE2'
            Arguments = '/C:" setup.exe /qn ADD_OPINSIGHTS_WORKSPACE=1 OPINSIGHTS_WORKSPACE_ID=' + $WEOMSWorkspaceId + ' OPINSIGHTS_WORKSPACE_KEY=' + $WEOMSWorkspaceKey + ' AcceptEndUserLicenseAgreement=1" '
            DependsOn = '[xRemoteFile]OMSPackage'
        }
    }
}  


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
