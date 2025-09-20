#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Eset Create Deployment

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
New-AzureResourceGroup -Name WindowsSecureRG -TemplateUri https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-simple-windows-vm/azuredeploy.json"\n

