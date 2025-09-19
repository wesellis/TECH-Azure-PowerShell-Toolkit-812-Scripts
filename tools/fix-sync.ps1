#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
# Fix GitHub sync issue
Write-Information "Fixing GitHub sync..."

# Pull the remote changes first
git pull origin main --allow-unrelated-histories
Write-Information "Pulled remote changes"

# Push our local changes
git push -u origin main
Write-Information "Repository fully synchronized!"


#endregion
