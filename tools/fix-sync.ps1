#Requires -Version 7.0
<#
.SYNOPSIS
    fix sync
.DESCRIPTION
    fix sync operation
    Author: Wes Ellis (wes@wesellis.com)

    fix synccom)
Write-Output "Fixing GitHub sync..."

git pull origin main --allow-unrelated-histories
Write-Output "Pulled remote changes"

git push -u origin main
Write-Output "Repository fully synchronized!"

