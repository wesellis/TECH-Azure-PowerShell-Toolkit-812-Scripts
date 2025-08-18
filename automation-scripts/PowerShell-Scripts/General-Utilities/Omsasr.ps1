<#
.SYNOPSIS
    We Enhanced Omsasr

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

Configuration OMSASR
{
  
    $WERemoteAzureAgent = 'http://go.microsoft.com/fwlink/p/?LinkId=394789'
    $WELocalAzureAgent = 'C:\Temp\AzureVmAgent.msi'
    $WEOMSPackageLocalPath = 'C:\MMA\MMASetup-AMD64.exe'
    $WEOMSWorkspaceId = Get-AutomationVariable -Name 'OMSWorkspaceId'
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
        
        xRemoteFile AzureAgent {
            URI = $WERemoteAzureAgent
            DestinationPath = $WELocalAzureAgent
            }

        Package AzureAgent {
            Path = 'C:\Temp\AzureVmAgent.msi'
            Ensure = 'Present'
            Name = " Windows Azure VM Agent - 2.7.1198.778"
            ProductId = " 5CF4D04A-F16C-4892-9196-6025EA61F964"
            Arguments = '/q /l " c:\temp\agentlog.txt'
            DependsOn = '[xRemoteFile]AzureAgent'
            } 

        Package OMS {
            Ensure = "Present"
            Path  = $WEOMSPackageLocalPath
            Name = 'Microsoft Monitoring Agent'
            ProductId = '8A7F2C51-4C7D-4BFD-9014-91D11F24AAE2'
            Arguments = '/C:" setup.exe /qn ADD_OPINSIGHTS_WORKSPACE=1 OPINSIGHTS_WORKSPACE_ID=' + $WEOMSWorkspaceId + ' OPINSIGHTS_WORKSPACE_KEY=' + $WEOMSWorkspaceKey + ' AcceptEndUserLicenseAgreement=1"'
            DependsOn = '[xRemoteFile]OMSPackage'
        }
    }
}  


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================