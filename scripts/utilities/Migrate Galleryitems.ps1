#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Migrate Galleryitems

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    .Synopsis
        Exports templates from the Microsoft.Gallery in the Azure Portal to a file or templateSpec resource
    .Description
        This script will export all gallery items (i.e. ARM Templates) available to the current user context.  These templates are available under the
        Microsoft.Gallery Resource Provider or the Azure Portal at:
        https://portal.azure.com/
        Exporting the gallery items does not remove them from the gallery.  Templates can be saved to an ARM Template file that will create a templateSpec
        for the template, or the templateSpec may be created without saving to a file.  RoleAssignments can optionally be migrated to the templateSpec
        so users that have access to the galleryItem will also have access to the templateSpecs.
    .Notes
        When exporting AllGalleryItems, specifically for items in galleries not owned by the current user context, note the following:
         - Naming collisions can occur when creating templateSpecs since all templateSpecs will reside in the same resourceGroup.  A single attempt
           will be made to change the name to avoid the collision using the origin galleryName, which is the objectId of the owner of the gallery.
         - The current context may not have permission to query roleAssignments for shared items, i.e. items not in the gallery owned by the user,
           and if so, roleAssignments will not be migrated for those items.
        The script does not have an option to export the galleryItem as an ARM Template (only a templateSpec) but the template object is available
        in the $TemplateJSON variable.
        If there are a large number of items in the gallery, the API response will be paged - this script does not follow the link to the next page so
        will only export from the first page.
        Currently when templateSpecs are created from the script, the sort order of the template properties is changed by conversion to json so the source
        code in the resource itself may not look familiar.  To work around this, export the galleryItems to a file and manually deploy the templateSpecs
        from that file.  The azuredeploy.parameters.json file created by this script can be used with azuredeploy.json to deploy all exported templates.
    .Example
    > .\Migrate-GalleryItems.ps1 -ItemsToExport AllGalleryItems -ExportToFile -MigrateRBAC -ResourceGroupName TemplateGalleryTemplates -Location westeurope
[CmdletBinding()]
    $ErrorActionPreference = "Stop"
param(
    [ValidateSet('MyGalleryItems', 'AllGalleryItems')]
    [string] $ItemsToExport = 'MyGalleryItems',
    [switch] $ExportToFile,
    [switch] $MigrateRBAC,
    [string] $ResourceGroupName,
    [string] $Location
)
if ($ResourceGroupName -ne "" -and $location -eq "" ) {
    Write-Error -Message "Location is required when a the ResourceGroupName is specified."
}
try {
    [Microsoft.Azure.Common.Authentication.AzureSession]::ClientFactory.AddUserAgent("AzureQuickStarts-GalleryMigration" , "1.0" )
} catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    throw
}
if ($ItemsToExport -eq 'MyGalleryItems') {
    Write-Output "GET galleryName..."
    $r = Invoke-AzRestMethod -Method GET -path "/providers/Microsoft.Gallery/myareas?api-version=2016-03-01-preview"
    $GalleryName = ($r.Content | ConvertFrom-Json).value[0].name
    Write-Output "GET all galleryItems in myArea: $GalleryName..."
    $r = Invoke-AzRestMethod -Method GET -path "/providers/Microsoft.Gallery/myareas/$GalleryName/galleryItems?api-version=2016-03-01-preview"
    $templates = ($r.content | ConvertFrom-Json -Depth 50).Value
}
else {
    Write-Output "GET all galleryItems accessible by current user context..."
    $r = Invoke-AzRestMethod -Method GET -path "/providers/Microsoft.Gallery/galleryItems?api-version=2016-03-01-preview"
    $items = ($r.Content | ConvertFrom-Json).Value
    $templates = @()
    foreach ($i in $items) {
    $path = " $($i.id)?api-version=2016-03-01-preview"
        Write-Output "GET template content for $($i.name)..."
        $t = Invoke-AzRestMethod -Method GET -Path $path
    $templates = $templates + $t.Content | ConvertFrom-Json -Depth 50
    }
}
    $headers = @{
    Authorization = "Bearer $($(Get-AzAccessToken).Token)"
}
    $TemplateSpecNames = @()
    $AllTemplateFiles = @()
    $TemplateSpecFileParam = @()
foreach ($t in $templates) {
    Write-Output "Processing template $($t.name)..."
    $uri = $t.properties.artifacts.default.uri
    $id = $t.id
    $TsName = $t.name
    if ($TemplateSpecNames -contains $TsName) {
    $TsName = " $($t.name)-$($GalleryName.Substring(8))"
        Write-Output "Changed name to $TsName..."
    }
    $TemplateSpecNames = $TemplateSpecNames + $TsName
    Write-Output "Downloading template from: $uri"
    $r = (Invoke-WebRequest -Uri $uri -Method "GET" -Headers $headers -UseBasicParsing -ContentType " application/json" )
    $TemplateJSON = $r.content
    $TemplateJSON = @([Regex]::Replace($TemplateJSON, '\:\s{0,}\" \s{0,}\[', ': " [[')) # replace expressions in string property types (preceded by a colon ':' )
    $TemplateJSON = @([Regex]::Replace($TemplateJSON, '\[\s{0,}\" \s{0,}\[', '[ " [[')) # replace expressions in array properties - the first element of the array (preceded by open bracket '[' )
    $TemplateJSON = @([Regex]::Replace($TemplateJSON, '\,\s{0,}\" \s{0,}\[', ', "[[')) # replace expressions in array properties - all elements after the first (preceded by comma ',' )
    $TemplateJSON = $TemplateJSON | ConvertFrom-Json -Depth 50
    $resources = @()
    $TemplateSpecResource = [ordered]@{
        type       = "Microsoft.Resources/templateSpecs"
        apiVersion = " 2019-06-01-preview"
        name       = $TsName
        location   = " [parameters('location')]"
        tags       = [ordered]@{
            publisherName        = $t.properties.publisherName
            publisherDisplayName = $t.properties.publisherDisplayName
            version              = $t.properties.version
            changedTime          = $t.properties.changedTime
            memo                 = "Imported from gallery item $id"
            sourceResourceId     = $id
        }
        properties = [ordered]@{
            description = $t.properties.description
            displayName = $t.properties.displayName
        }
        resources  = @(
            [ordered]@{
                type       = " versions"
                apiVersion = " 2019-06-01-preview"
                name       = $t.properties.version
                location   = " [parameters('location')]"
                dependsOn  = @($TsName)
                tags       = [ordered]@{
                    publisherName        = $t.properties.publisherName
                    publisherDisplayName = $t.properties.publisherDisplayName
                    version              = $t.properties.version
                    changedTime          = $t.properties.changedTime
                    memo                 = "Imported from gallery item $id"
                    sourceResourceId     = $id
                }
                properties = [ordered]@{
                    description = $t.properties.description
                    template    = $TemplateJSON
                }
            }
        )
    }
    $resources = $resources + $TemplateSpecResource
    if ($MigrateRBAC) {
        Write-Output "GET roleAssignments for $id"
    $RoleAssignments = Get-AzRoleAssignment -Scope $id
        foreach ($ra in $RoleAssignments) {
            if ($ra.scope -eq $id) {
    $RoleAssignmentResource = [ordered]@{
                    scope      = "Microsoft.Resources/templateSpecs/$($TsName)"
                    type       = "Microsoft.Authorization/roleAssignments"
                    apiVersion = " 2020-04-01-preview"
                    name       = " [guid(resourceId('Microsoft.Resources/templateSpecs', '$TsName'), '$($ra.RoleDefinitionId)', '$($ra.ObjectId)')]"
                    dependsOn  = @( $TsName )
                    tags       = [ordered]@{
                        memo              = "Migrated from $($ra.scope)"
                        sourceResourceId  = $ra.RoleAssignmentId
                        signInName        = $ra.SignInName
                        roleDefintionName = $ra.RoleDefinitionName
                    }
                    properties = [ordered]@{
                        principalId      = $ra.ObjectId
                        roleDefinitionId = " [resourceId('Microsoft.Authorization/roleDefinitions', '$($ra.RoleDefinitionId)')]"
                        principalType    = $ra.ObjectType
                    }
                }
    $resources = $resources + $RoleAssignmentResource
            }
        }
    }
    $TemplateFile = [ordered]@{
        '$schema'      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
        contentVersion = " 1.0.0.0"
        parameters     = [ordered]@{
            location = [ordered]@{
                type         = 'string'
                defaultValue = '[resourceGroup().location]'
            }
        }
        resources      = $resources
    }
    $AllTemplateFiles = $AllTemplateFiles + $TemplateFile
    if ($ExportToFile) {
    $GalleryFolder = $id.split('/')[4]
        if (!(Test-Path -path $GalleryFolder)) {
            Write-Output "Creating folder: $GalleryFolder..."
            New-Item -ItemType Directory -Path $GalleryFolder -Verbose
        }
        Write-Output "Creating ARM Template for: $TsName"
    $TemplateFile | ConvertTo-Json -Depth 50 | Set-Content -Path " $GalleryFolder/$($TsName).json"
    $TemplateSpecFileParam = $TemplateSpecFileParam + " $GalleryFolder/$($TsName).json" # add this file to the parameter file that will deploy all templateSpecs
    }
}
if ($ExportToFile) {
    $ParamFile = [ordered]@{
        '$schema' = "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#"
        contentVersion = " 1.0.0.0"
        parameters = @{
            templateSpecFiles = @{
                value = $TemplateSpecFileParam
            }
        }
    }
    Write-Output "Creating ARM Template parameter file..."
    $ParamFile | ConvertTo-Json -Depth 10 | Set-Content -Path " azuredeploy.parameters.json"
}
if ($ResourceGroupName -ne "" ) {
    if ($null -eq (Get-AzResourceGroup -Name $ResourceGroupName -Location $Location -Verbose -ErrorAction SilentlyContinue)) {
    $ResourcegroupSplat = @{
    Name = $ResourceGroupName
    Location = $Location
    ErrorAction = Stop
}
New-AzResourceGroup @resourcegroupSplat
    }
    if ($MigrateRBAC) {
        Write-Output "Checking for roleAssignments on the gallery..."
    $GalleryId = "/providers/Microsoft.Gallery/myareas/$GalleryName"
    $RoleAssignments = Get-AzRoleAssignment -Scope $GalleryId
        foreach ($ra in $RoleAssignments) {
            if ($ra.Scope -eq $GalleryId) {
                $s = "/subscriptions/$($(Get-AzContext).Subscription.id)/resourceGroups/$ResourceGroupName"
    $ExistingRoleAssignment = Get-AzRoleAssignment -Scope $s -ObjectId $ra.ObjectId -RoleDefinitionId $ra.RoleDefinitionId
                if ($null -eq $ExistingRoleAssignment) {
                    Write-Output "Adding roleAssignment for principal: $($ra.ObjectId)"
                    New-AzRoleAssignment -scope $s -ObjectId $ra.ObjectId -RoleDefinitionId $ra.RoleDefinitionId -Verbose
                }
                else {
                    Write-Output "RoleAssignment exists for:`nScope: $s`nPrincipal: $($ra.ObjectId)`nRole: $($ra.RoleDefinitionName)`n"
                }
            }
        }
    }
    foreach ($t in $AllTemplateFiles) {
$t = $t | ConvertTo-Json -depth 50 | ConvertFrom-Json -Depth 50 -AsHashtable
        New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateObject $t -Verbose
    }
`n}
