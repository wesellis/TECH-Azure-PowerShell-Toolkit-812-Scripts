<#
.SYNOPSIS
    Autoupdateworker

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

<#
.SYNOPSIS
    We Enhanced Autoupdateworker

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#
.SYNOPSIS  
 AutoUpdate worker Module for ARO Toolkit future releases
.DESCRIPTION  
 AutoUpdate worker Module for ARO Toolkit future releases
.EXAMPLE  
.\AutoUpdateWorker.ps1 
Version History  
v1.0   - <dev> - Initial Release  




$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection " AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    " Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch 
{
    if (!$servicePrincipalConnection)
    {
        $WEErrorMessage = " Connection $connectionName not found."
        throw $WEErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

try
{
    Write-Output " AutoUpdate Worker execution starts..."
    
    #Local Variables

    $WEGithubRootPath = " https://raw.githubusercontent.com/Microsoft/MSITARM"
    $WEGithubBranch = " azure-resource-optimization-toolkit"
    $WEScriptPath = " azure-resource-optimization-toolkit/nestedtemplates"
    $WEFileName = " Automation.json"
    $WEGithubFullPath = " $($WEGithubRootPath)/$($WEGithubBranch)/$($WEScriptPath)/$($WEFileName)"

    #[System.Reflection.Assembly]::LoadWithPartialName(" System.Web.Extensions" )

    $WEWebClient = New-Object -ErrorAction Stop System.Net.WebClient

    Write-Output " Download the $($WEFileName) template from GitHub..."

    $WEWebClient.DownloadFile($($WEGithubFullPath)," $WEPSScriptRoot\$($WEFileName)" )
    
    $jsonContent=Get-Content -ErrorAction Stop " $WEPSScriptRoot\$($WEFileName)"

    Write-Output " Deserialize the JSON..."
    $serializer = New-Object -ErrorAction Stop System.Web.Script.Serialization.JavaScriptSerializer
    $jsonData = $serializer.DeserializeObject($jsonContent)

    #Get the Automation Account tags to read the version
    Write-Output " Reading the Automation Account details..."

    $automationAccountName = Get-AutomationVariable -Name 'Internal_AROautomationAccountName'
    $aroResourceGroupName = Get-AutomationVariable -Name 'Internal_AROResourceGroupName'

    $WEAutomationAccountDetails = Get-AzureRmAutomationAccount -Name $automationAccountName -ResourceGroupName $aroResourceGroupName
    $WECurrentVersion = $WEAutomationAccountDetails.Tags.Values
    $WEUpdateVersion = $jsonData.variables.AROToolkitVersion

    Write-Output " Checking the ARO Toolkit version..."
    $WECurrentVersionCompare = New-Object -ErrorAction Stop System.Version($WECurrentVersion)
    $WEUpdateVersionCompare = New-Object -ErrorAction Stop System.Version($WEUpdateVersion)

    $WEVersionDiff = $WEUpdateVersionCompare.CompareTo($WECurrentVersionCompare)

    if(  $WEVersionDiff -gt 0)
    {
        Write-Output " Current version is: $($WECurrentVersion)"
        Write-Output " New version $($WEUpdatedVersion) is available and hence performing the upgrade..."
        #Prepare the Current variable object
        #---------Read all the input variables---------------
        Write-Output " ======================================"
        Write-Output " Checking for asset variable updates..."
        Write-Output " ======================================"
        $WEExistingVariables = Get-AzureRmAutomationVariable -automationAccountName $automationAccountName -ResourceGroupName $aroResourceGroupName | Select-Object Name 
        $WEExistingVariables = $WEExistingVariables | Foreach {" $($_.Name)" } | Sort-Object Name
        $WENewVariables=$jsonData.variables.Keys | Where-Object { $_.Trim() -match " Internal" -or $_ -match " External" } | Sort-Object

        $WEDiffVariables = Compare-Object -ReferenceObject $WENewVariables -DifferenceObject $WEExistingVariables | ?{$_.sideIndicator -eq " <=" }| Select InputObject

        if($null -ne $WEDiffVariables)
        {
            Write-Output " New asset variables found and creating now..."
            Write-Output $WEDiffVariables
            #Create all the new variables
            $newResourceVariables = $jsonData.resources | foreach{$_.resources}
            foreach ($difv in $WEDiffVariables)
            {
                foreach($newvar in $newResourceVariables)
                {
                    if(($newvar.name -like " *$($difv.InputObject)*" -eq $true) -and ($newvar.type -eq " variables" ))
                    {
                        [string[]] $rvarPropValArray = $newvar.properties.value.Split(" ," )

                        if($rvarPropValArray.get(1) -ne $null -and $rvarPropValArray.get(1).Contains('" ') -ne " True" )
                        {
                            [string];  $rvarPropVal = $rvarPropValArray.get(1).Replace(" '" ,"" )                            
                        }
                        else
                        {
                           ;  $rvarPropVal = ""
                        }
                        New-AzureRmAutomationVariable -Name $difv.InputObject.Trim() -automationAccountName $automationAccountName -ResourceGroupName $aroResourceGroupName -Encrypted $WEFalse -Value $rvarPropVal.Trim()
                        break;
                    }
            
                }
            }
        }
        else
        {
            Write-Output " No updates needed for asset variables..."
        }
    
        Write-Output " ================================="
        Write-Output " Checking for Runbooks updates..."
        Write-Output " ================================="
        #Find the delta runbooks to create/update
        $runbooks=$jsonData.variables.runbooks.Values
        $WERunbooktable = [ordered]@{}

        foreach($runb in $runbooks)
        {
            #ignore the bootstrap and AROToolkit_AutoUpdate runboooks
            if($runb.name -notlike " *Bootstrap*" )
            {
                [string[]] $runbookScriptUri = $runb.scriptUri -split " ,"
                $WERunbooktable.Add($runb.name,$runbookScriptUri.get(1).Replace(" )]" ,"" ).Replace(" '" ,"" ))
                $currentRunbook = Get-AzureRmAutomationRunbook -automationAccountName $automationAccountName -ResourceGroupName $aroResourceGroupName -Name $runb.name -ErrorAction SilentlyContinue
                #check if this is new runbook or existing
                if($null -ne $currentRunbook)
                {
                    $currentRBversion = $currentRunbook.Tags.Values        
                    $WENewVersion = $runb.version
                    $WECVrbCompare = New-Object -ErrorAction Stop System.Version($currentRBversion)
                    $WENVrbCompare = New-Object -ErrorAction Stop System.Version($WENewVersion)
                    $WEVersionDiffRB = $WENVrbCompare.CompareTo($WECVrbCompare)

                    if($WEVersionDiffRB -gt 0)
                    {
                        $WERunbookDownloadPath = " $($WEGitHubRootPath)/$($WEGitHubBranch)/azure-resource-optimization-toolkit$($WERunbooktable[$runb.name])"
                        Write-Output " Updates needed for $($runb.name)..."
                        #Now download the runbook and do the update
                        Write-Output " Downloading the updated PowerShell script from GitHub..."
                        $WEWebClientRB = New-Object -ErrorAction Stop System.Net.WebClient
                        
                        $WEWebClientRB.DownloadFile($($WERunbookDownloadPath)," $WEPSScriptRoot\$($runb.name).ps1" )
                        $WERunbookScriptPath = " $WEPSScriptRoot\$($runb.name).ps1"

                        Write-Output " Updating the Runbook content..." 
                        Import-AzureRmAutomationRunbook -automationAccountName $automationAccountName -ResourceGroupName $aroResourceGroupName -Path $WERunbookScriptPath -Name $runb.name -Tags @{version=$WENewVersion} -Force -Type PowerShell

                        Write-Output " Publishing the Runbook $($runb.name)..."
                        Publish-AzureRmAutomationRunbook -automationAccountName $automationAccountName -ResourceGroupName $aroResourceGroupName -Name $runb.name                
                    }
                }
                else
                {
                    $WERunbookDownloadPath = " $($WEGitHubRootPath)/$($WEGitHubBranch)/azure-resource-optimization-toolkit$($WERunbooktable[$runb.name])"
                    Write-Output " New Runbook $($runb.name) found..."
                    #New Runbook. So download and create it
                    Write-Output " Downloading the PowerShell script from GitHub..."
                    $WEWebClientRB = New-Object -ErrorAction Stop System.Net.WebClient
                    $WEWebClientRB.DownloadFile($($WERunbookDownloadPath)," $WEPSScriptRoot\$($runb.name).ps1" )
                    $WERunbookScriptPath = " $WEPSScriptRoot\$($runb.name).ps1"
                    $WENewVersion = $runb.version

                    Write-Output " Creating the Runbook in the Automation Account..." 
                    New-AzureRmAutomationRunbook -Name $runb.name -automationAccountName $automationAccountName -ResourceGroupName $aroResourceGroupName -Type PowerShell -Description " New Runbook"
                    Import-AzureRmAutomationRunbook -automationAccountName $automationAccountName -ResourceGroupName $aroResourceGroupName -Path $WERunbookScriptPath -Name $runb.name -Force -Type PowerShell -Tags @{version=$WENewVersion} 

                    Write-Output " Publishing the new Runbook $($runb.name)..."
                    Publish-AzureRmAutomationRunbook -automationAccountName $automationAccountName -ResourceGroupName $aroResourceGroupName -Name $runb.name
                }
            }
        }
        
        Write-Output " ============================="
        Write-Output " Checking for new schedule..."
        Write-Output " ============================="

        #just run the bootstrap_main runbook to create the schedules
        $WEBootstrap_MainRunbook = " Bootstrap_Main"

        $WERunbookDownloadPath = " $($WEGitHubRootPath)/$($WEGitHubBranch)/demos/azure-resource-optimization-toolkit/scripts/Bootstrap_Main.ps1"
        Write-Output " Downloading the Bootstrap_Main PowerShell script from GitHub..."
       ;  $WEWebClientRB = New-Object -ErrorAction Stop System.Net.WebClient
        $WEWebClientRB.DownloadFile($($WERunbookDownloadPath)," $WEPSScriptRoot\$($WEBootstrap_MainRunbook).ps1" )
       ;  $WERunbookScriptPath = " $WEPSScriptRoot\Bootstrap_Main.ps1"
        
        Write-Output " Creating the Runbook in the Automation Account..." 
        New-AzureRmAutomationRunbook -Name $WEBootstrap_MainRunbook -automationAccountName $automationAccountName -ResourceGroupName $aroResourceGroupName -Type PowerShell -Description " New Runbook"
        Import-AzureRmAutomationRunbook -automationAccountName $automationAccountName -ResourceGroupName $aroResourceGroupName -Path $WERunbookScriptPath -Name $WEBootstrap_MainRunbook -Force -Type PowerShell

        Write-Output " Publishing the Bootstrap_Main Runbook..."
        Publish-AzureRmAutomationRunbook -automationAccountName $automationAccountName -ResourceGroupName $aroResourceGroupName -Name $WEBootstrap_MainRunbook

        Start-AzureRmAutomationRunbook -Name $WEBootstrap_MainRunbook -automationAccountName $automationAccountName -ResourceGroupName $aroResourceGroupName -Wait

        #Update the Automation Account version tag to latest version
        Set-AzureRmAutomationAccount -Name $automationAccountName -ResourceGroupName $aroResourceGroupName -Tags @{AROToolkitVersion=$WEUpdateVersion}

    }    
    elseif($WEVersionDiff -le 0)
    {
        Write-Output " You are having the latest version of ARO Toolkit and hence no update needed..."
    }

    Write-Output " AutoUpdate worker execution completed..."
}
catch
{
    Write-Output " Error Occurred in the AutoUpdate worker runbook..."
    Write-Output $_.Exception
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================