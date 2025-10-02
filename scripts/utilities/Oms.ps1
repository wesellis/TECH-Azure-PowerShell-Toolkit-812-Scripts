#Requires -Version 7.4
#Requires -Modules xPSDesiredStateConfiguration

<#
.SYNOPSIS
    Operations Management Suite Configuration

.DESCRIPTION
    Azure DSC configuration for installing and configuring Microsoft Monitoring Agent (MMA)
    for Operations Management Suite (OMS). This simplified configuration focuses only on
    OMS agent deployment without Azure VM Agent.

.PARAMETER OMSWorkspaceId
    The workspace ID for the Operations Management Suite

.PARAMETER OMSWorkspaceKey
    The workspace key for authenticating to OMS

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and DSC modules
    Designed for use with Azure Automation DSC
#>

Configuration OMS {
    param(
        [Parameter(Mandatory = $false)]
        [string]$OMSWorkspaceId,

        [Parameter(Mandatory = $false)]
        [string]$OMSWorkspaceKey
    )

    Import-DscResource -ModuleName xPSDesiredStateConfiguration

    # Agent download path
    $OMSPackageLocalPath = 'C:\MMA\MMASetup-AMD64.exe'

    # Get workspace credentials from automation variables if not provided
    if (-not $OMSWorkspaceId) {
        $OMSWorkspaceId = Get-AutomationVariable -Name 'OMSWorkspaceId' -ErrorAction SilentlyContinue
    }
    if (-not $OMSWorkspaceKey) {
        $OMSWorkspaceKey = Get-AutomationVariable -Name 'OMSWorkspaceKey' -ErrorAction SilentlyContinue
    }

    Node localhost {
        # Ensure MMA directory exists
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

        # Ensure OMS Health Service is running
        Service OMSService {
            Name = "HealthService"
            State = "Running"
            DependsOn = '[Package]OMS'
        }
    }
}

# Example usage:
# OMS -OMSWorkspaceId 'your-workspace-id' -OMSWorkspaceKey 'your-workspace-key'
# Start-DscConfiguration -Path .\OMS -Wait -Verbose -Force