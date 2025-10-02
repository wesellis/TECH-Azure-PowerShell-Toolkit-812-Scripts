#Requires -Version 7.4
#Requires -Modules xPSDesiredStateConfiguration

<#
.SYNOPSIS
    OMS and Azure Site Recovery Configuration

.DESCRIPTION
    Azure DSC configuration for installing and configuring Microsoft Monitoring Agent (MMA)
    and Azure VM Agent for Operations Management Suite (OMS) and Azure Site Recovery.
    This configuration automates the deployment of monitoring and recovery agents.

.PARAMETER OMSWorkspaceId
    The workspace ID for the Operations Management Suite

.PARAMETER OMSWorkspaceKey
    The workspace key for authenticating to OMS

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and DSC modules
    Must be run on target nodes where agents need to be installed
#>

Configuration OMSASR {
    param(
        [Parameter(Mandatory = $false)]
        [string]$OMSWorkspaceId,

        [Parameter(Mandatory = $false)]
        [string]$OMSWorkspaceKey
    )

    Import-DscResource -ModuleName xPSDesiredStateConfiguration

    # Agent download URLs and paths
    $RemoteAzureAgent = 'http://go.microsoft.com/fwlink/p/?LinkId=394789'
    $LocalAzureAgent = 'C:\Temp\AzureVmAgent.msi'
    $OMSPackageLocalPath = 'C:\MMA\MMASetup-AMD64.exe'

    # Get workspace credentials from automation variables if not provided
    if (-not $OMSWorkspaceId) {
        $OMSWorkspaceId = Get-AutomationVariable -Name 'OMSWorkspaceId' -ErrorAction SilentlyContinue
    }
    if (-not $OMSWorkspaceKey) {
        $OMSWorkspaceKey = Get-AutomationVariable -Name 'OMSWorkspaceKey' -ErrorAction SilentlyContinue
    }

    Node localhost {
        # Ensure temp directories exist
        File TempDirectory {
            Ensure = 'Present'
            Type = 'Directory'
            DestinationPath = 'C:\Temp'
        }

        File MMADirectory {
            Ensure = 'Present'
            Type = 'Directory'
            DestinationPath = 'C:\MMA'
        }

        # Download OMS package
        xRemoteFile OMSPackage {
            Uri = "https://go.microsoft.com/fwlink/?LinkID=517476"
            DestinationPath = $OMSPackageLocalPath
            DependsOn = '[File]MMADirectory'
        }

        # Download Azure VM Agent
        xRemoteFile AzureAgent {
            Uri = $RemoteAzureAgent
            DestinationPath = $LocalAzureAgent
            DependsOn = '[File]TempDirectory'
        }

        # Install Azure VM Agent
        Package AzureAgent {
            Path = $LocalAzureAgent
            Ensure = 'Present'
            Name = "Windows Azure VM Agent - 2.7.1198.778"
            ProductId = "5CF4D04A-F16C-4892-9196-6025EA61F964"
            Arguments = '/q /l "c:\temp\agentlog.txt"'
            DependsOn = '[xRemoteFile]AzureAgent'
        }

        # Install Microsoft Monitoring Agent
        if ($OMSWorkspaceId -and $OMSWorkspaceKey) {
            Package OMS {
                Ensure = "Present"
                Path = $OMSPackageLocalPath
                Name = 'Microsoft Monitoring Agent'
                ProductId = '8A7F2C51-4C7D-4BFD-9014-91D11F24AAE2'
                Arguments = '/C:"setup.exe /qn ADD_OPINSIGHTS_WORKSPACE=1 OPINSIGHTS_WORKSPACE_ID=' + $OMSWorkspaceId + ' OPINSIGHTS_WORKSPACE_KEY=' + $OMSWorkspaceKey + ' AcceptEndUserLicenseAgreement=1"'
                DependsOn = '[xRemoteFile]OMSPackage'
            }

            # Ensure OMS service is running
            Service OMSService {
                Name = "HealthService"
                State = "Running"
                DependsOn = '[Package]OMS'
            }
        }
        else {
            # Install without workspace configuration (can be configured later)
            Package OMS {
                Ensure = "Present"
                Path = $OMSPackageLocalPath
                Name = 'Microsoft Monitoring Agent'
                ProductId = '8A7F2C51-4C7D-4BFD-9014-91D11F24AAE2'
                Arguments = '/C:"setup.exe /qn AcceptEndUserLicenseAgreement=1"'
                DependsOn = '[xRemoteFile]OMSPackage'
            }
        }
    }
}

# Example usage:
# OMSASR -OMSWorkspaceId 'your-workspace-id' -OMSWorkspaceKey 'your-workspace-key'
# Start-DscConfiguration -Path .\OMSASR -Wait -Verbose -Force