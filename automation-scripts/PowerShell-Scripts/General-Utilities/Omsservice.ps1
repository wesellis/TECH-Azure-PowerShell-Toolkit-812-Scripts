<#
.SYNOPSIS
    Omsservice

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
Configuration OMSSERVICE
{
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Node localhost {
        Service OMSService
        {
            Name = "HealthService"
            State = "Running"
        }
    }
}

