#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Eset Create Deployment

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
New-AzureResourceGroup -Name WindowsSecureRG -TemplateUri https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-simple-windows-vm/azuredeploy.json"


