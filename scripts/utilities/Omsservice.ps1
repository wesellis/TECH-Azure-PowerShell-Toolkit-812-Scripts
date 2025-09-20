#Requires -Version 7.0

<#`n.SYNOPSIS
    Omsservice

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
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
