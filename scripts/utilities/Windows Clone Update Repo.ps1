#Requires -Version 7.4
<#
.SYNOPSIS
    Brief description of the Windows Clone Update Repo script functionality
.DESCRIPTION
    Detailed description of what the Windows Clone Update Repo script does and how it works.
    This script provides [specific functionality] and supports [key features].

    Key capabilities:
    - [Capability 1]
    - [Capability 2]
    - [Capability 3]

.PARAMETER true
    Description of the true parameter and its expected values
.EXAMPLE
    .\Windows Clone Update Repo.ps1

    Basic example showing how to run the script with default parameters.
.EXAMPLE
    .\Windows Clone Update Repo.ps1 -Parameter "Value"

    Example showing script usage with specific parameter values.
.INPUTS
    System.String
    Objects that can be piped to this script
.OUTPUTS
    System.Object
    Objects that this script outputs to the pipeline
.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Created: January 17, 2025
    Version: 1.0.0

    Requirements:
    - PowerShell 7.0 or later
    - [Additional requirements as needed]

    Change Log:
    1.0.0 - 2025-01-17 - Initial version
.LINK
    https://github.com/wesellis/scripts
.LINK
    about_Comment_Based_Help
Windows Clone Update Repo
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    Allows cloning a new or updating an existing repo (important for updating a chained image).
    $ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $RepoUrl,
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory = $true)]
    [String] $repository_TargetDirectory,
    [Parameter(Mandatory = $false)]
    [String] $repository_SourceControl,
    [Parameter(Mandatory = $false)]
    [bool] $repository_cloneIfNotExists = $false,
    [Parameter(Mandatory = $false)]
    [string] $RepoName,
    [Parameter(Mandatory = $false)]
    [string] $CommitId = 'latest',
    [Parameter(Mandatory = $false)]
    [string] $BranchName,
    [Parameter(Mandatory = $false)]
    [string] $repository_optionalCloningParameters,
    [Parameter(Mandatory = $false)]
    [string] $repository_optionalFetchParameters,
    [Parameter(Mandatory = $false)]
    [bool] $EnableGitCommitGraph = $false,
    [Parameter(Mandatory = $false)]
    [string] $SparseCheckoutFolders,
    [Parameter(Mandatory = $false)]
    [string] $repository_MSIClientId = $null
)
enum SourceControl {
    git = 0
    gvfs
}
    $logfilepath = $null
    $script:varLogArray = New-Object -TypeName "PSCustomObject"
Function ProcessRunner(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $command,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $arguments,
    $ArgumentsToLog = '',
    [bool] $CheckForSuccess = $true,
    [bool] $WaitForDependents = $true
) {
    if (!$ArgumentsToLog) {
    $ArgumentsToLog = $arguments
    }
    $ErrLog = [System.IO.Path]::GetTempFileName()
    if ($WaitForDependents) {
    $process = Start-Process -FilePath $command -ArgumentList $arguments -RedirectStandardError $ErrLog -Wait -PassThru -NoNewWindow
    }
    else {
    $process = Start-Process -FilePath $command -ArgumentList $arguments -RedirectStandardError $ErrLog -PassThru -NoNewWindow
    }
    if (!$process) {
        Write-Error "ERROR command failed to start: $command $ArgumentsToLog"
        return;
    }
    if ($WaitForDependents) {
    $ExitCode = $process.ExitCode
    }
    else {
    $process.WaitForExit()
    $process.HasExited
    $ExitCode = $process.GetType().GetField(" exitCode" , "NonPublic,Instance" ).GetValue($process) # Get the ExitCode from the hidden field but it is not publicly available
    }
    if ($ExitCode -ne 0) {
        Write-Output "Error running: $command $ArgumentsToLog"
        Write-Output "Exit code: $ExitCode"
        Write-Output " **ERROR**"
        Get-Content -Path $ErrLog
        if ([System.String]::IsNullOrWhiteSpace($logfilepath) -ne $true -and [System.IO.File]::Exists($logfilepath) -eq $true) {
            Write-Output "Logfile output from '$logfilepath':"
            Get-Content -ErrorAction Stop $logfilepath
        }
        if ($CheckForSuccess) {
            throw "Exit code from process was nonzero"
        }
        else {
            Write-Output " ==Ignored the error"
        }
    }
}
    Gvfs clones the repository and checks out to the specified gitBranchName
function GvfsCloneGitRepo {
    param(
        [ValidateNotNullOrEmpty()] $GitExeLocation,
        [ValidateNotNullOrEmpty()] $GvfsExeLocation,
        [ValidateNotNullOrEmpty()] $GvfsRepoLocation,
        [ValidateNotNullOrEmpty()] $GvfsLocalRepoLocation,
        [string] $GitBranchName,
        [string] $MsiClientId
    )
    if ($false -eq $GvfsRepoLocation.ToLowerInvariant().StartsWith(" https://" )) {
    $ErrMsg = $("Error! The specified Gvfs repo url is not a valid HTTPS clone url : " + $GvfsRepoLocation)
        Write-Output $ErrMsg
        Throw $ErrMsg
    }
    if ($false -eq ($GvfsRepoLocation.Length -gt 8)) {
    $ErrMsg = $("Error! The specified Git repo url is not valid : " + $GvfsRepoLocation)
        Write-Output $ErrMsg
        Throw $ErrMsg
    }
    $CmdArgs = $(" " + $GvfsRepoLocation + " `"" + $GvfsLocalRepoLocation + " `"" )
    Write-Output $("Gvfs cloning the git repo..." )
    $PrevCredentialHelper = &$GitExeLocation config --system credential.helper
    $GitAccessToken = Get-GitAccessToken -MsiClientID $MsiClientId
    $CredentialHelper = " `" !f() { test `" `$1`" = get && echo username=AzureManagedIdentity; echo password=$GitAccessToken; }; f`""
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system credential.helper $CredentialHelper" -argumentsToLog " --system credential.helper CUSTOM_AUTH_SCRIPT"
    $RunBlock = {
        ExecuteGvfsCmd -gvfsExeLocation $GvfsExeLocation -gvfsCmd " clone" -gvfsCmdArgs $CmdArgs
    }
    RunWithRetries -runBlock $RunBlock -retryAttempts 5 -waitBeforeRetrySeconds 30 -onFailureBlock {}
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system credential.helper $PrevCredentialHelper"
}
[OutputType([bool])]
 -ErrorAction Stop {
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String] $RepoUrl
    )
    return ($RepoUrl -Match '^https://[a-zA-Z][\w\-_]*\.visualstudio\.com/.*' -or $RepoUrl -Match '^https://dev\.azure\.com/.*')
}
    Clones the repository and checks out to the specified CommitId
function CloneGitRepo {
    param(
        [ValidateNotNullOrEmpty()] $GitExeLocation,
        [ValidateNotNullOrEmpty()] $GitRepoLocation,
        [ValidateNotNullOrEmpty()] $GitLocalRepoLocation,
        [string] $GitBranchName,
        [Parameter(Mandatory = $false)] $OptionalGitCloneArgs,
        [Parameter(Mandatory = $false)] $FormattedSparseCheckoutFolders,
        [Parameter(Mandatory = $false)][string] $MsiClientId
    )
    if ($false -eq $GitRepoLocation.ToLowerInvariant().StartsWith(" https://" )) {
    $ErrMsg = $("Error! The specified Git repo url is not a valid HTTPS clone url : " + $GitRepoLocation)
        Write-Output $ErrMsg
        Throw $ErrMsg
    }
    if ($false -eq ($GitRepoLocation.Length -gt 8)) {
    $ErrMsg = $("Error! The specified Git repo url is not valid : " + $GitRepoLocation)
        Write-Output $ErrMsg
        Throw $ErrMsg
    }
    $AuthorizationHeader = ''
    if (Get-CanUseManagedIdentityForRepo -RepoUrl $GitRepoLocation) {
    $AuthorizationHeader = Get-GitAuthorizationHeader -MsiClientID $MsiClientId
    }
    $OptionalArgs = ""
    if (!([System.String]::IsNullOrWhiteSpace($OptionalGitCloneArgs))) {
    $OptionalArgs = $OptionalGitCloneArgs
    }
    if (![string]::IsNullOrEmpty($GitBranchName)) {
    $OptionalArgs = " -b $GitBranchName " + $OptionalArgs
    }
    if (-not [string]::IsNullOrEmpty($FormattedSparseCheckoutFolders)) {
    $OptionalArgs = $OptionalArgs + " --no-checkout"
    }
    $CmdArgs = $($OptionalArgs + " " + $GitRepoLocation + " `"" + $GitLocalRepoLocation + " `"" )
    Write-Output $("Cloning the git repo..." )
    $RunBlock = {
        if (Test-Path $GitLocalRepoLocation) {
            Remove-Item -ErrorAction Stop $GitLocalRepoLocatio -Forcen -Force -Recurse -Force
        }
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " clone" -authHeader $AuthorizationHeader -gitCmdArgs $CmdArgs
    }
    RunWithRetries -runBlock $RunBlock -retryAttempts 5 -waitBeforeRetrySeconds 30 -onFailureBlock {}
    Write-Information Changing to repo location: $(" '$GitLocalRepoLocation'" )
    Set-Location -ErrorAction Stop $GitLocalRepoLocation
    if (-not [string]::IsNullOrEmpty($FormattedSparseCheckoutFolders)) {
    $SparseGitCmd = " set $FormattedSparseCheckoutFolders"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " sparse-checkout" -authHeader $AuthorizationHeader -gitCmdArgs $SparseGitCmd -argumentsToLog $SparseGitCmd
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " checkout" -authHeader $AuthorizationHeader
    }
}
    Updates the local repository to the commit ID specified
function UpdateGitRepo {
    param(
        [ValidateNotNullOrEmpty()] $GitExeLocation,
        [ValidateNotNullOrEmpty()] $GitRepoLocation,
        [ValidateNotNullOrEmpty()] $GitLocalRepoLocation,
        [string] $GitBranchName,
        [string] $CommitId,
        [string] $OptionalFetchArgs,
        [string] $FormattedSparseCheckoutFolders,
        [Parameter(Mandatory = $false)][string] $MsiClientId
    )
    if ($false -eq $GitRepoLocation.ToLowerInvariant().StartsWith(" https://" )) {
    $ErrMsg = $("Error! The specified Git repo url is not a valid HTTPS url : " + $GitRepoLocation)
        Write-Error $ErrMsg
        Throw $ErrMsg
    }
    if ($false -eq $GitRepoLocation.Length -gt 8) {
    $ErrMsg = $("Error! The specified Git repo url is not valid : " + $GitRepoLocation)
        Write-Error $ErrMsg
        Throw $ErrMsg
    }
    $AuthorizationHeader = ''
    if (Get-CanUseManagedIdentityForRepo -RepoUrl $GitRepoLocation) {
    $AuthorizationHeader = Get-GitAuthorizationHeader -MsiClientID $MsiClientId
    }
    $BaseRepoSparseCheckout = Invoke-Expression -Command '&$GitExeLocation config --get core.sparseCheckout'
    if ([string]::IsNullOrEmpty($BaseRepoSparseCheckout)) {
    $BaseRepoSparseCheckout = $false
    }
    $RepoSparseCheckout = $false
    if (-not [string]::IsNullOrEmpty($FormattedSparseCheckoutFolders)) {
    $RepoSparseCheckout = $true
    }
    if ($RepoSparseCheckout -ne $BaseRepoSparseCheckout) {
        Write-Output "Base image sparse checkout configuration: $BaseRepoSparseCheckout"
        Write-Output "Image sparse checkout configuration: $RepoSparseCheckout"
        throw "Sparse checkout configuration misaligned with base image"
    }
    $OptionalArgs = ""
    if (!([System.String]::IsNullOrWhiteSpace($OptionalFetchArgs))) {
    $OptionalArgs = $OptionalFetchArgs
    }
    if (![string]::IsNullOrEmpty($GitBranchName)) {
    $TempBranch = (New-Guid).Guid
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " checkout" -authHeader $AuthorizationHeader -gitCmdArgs " -b $TempBranch"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " branch" -gitCmdArgs " -D $GitBranchName" -checkForSuccess $false
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " fetch" -authHeader $AuthorizationHeader -gitCmdArgs " origin $($GitBranchName):$($GitBranchName) $OptionalArgs"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " checkout" -authHeader $AuthorizationHeader -gitCmdArgs " $GitBranchName"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " branch" -gitCmdArgs " -D $TempBranch"
    }
    elseif ($CommitId -ne 'latest') {
        Write-Output "Fetching commit $CommitId"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " fetch" -authHeader $AuthorizationHeader -gitCmdArgs " origin $CommitId $OptionalArgs"
        Write-Output "Resetting branch to $CommitId"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " reset" -authHeader $AuthorizationHeader -gitCmdArgs " $CommitId --hard"
    }
    else {
        Write-Output "Pulling the latest commit"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " pull" -authHeader $AuthorizationHeader -gitCmdArgs $OptionalArgs
    }
    $LogExpression = '&$GitExeLocation log -1 --quiet --format=%H'
    $UpdateCommitID = Invoke-Expression -Command $LogExpression
    Add-VarForLogging -varName 'CommitID' -varValue $UpdateCommitID
}
    Executes a git command with arguments
function ExecuteGitCmd {
    param(
        [ValidateNotNullOrEmpty()][string] $GitExeLocation,
        [ValidateNotNullOrEmpty()][string] $GitCmd,
        [string] $GitCmdArgs,
        [string] $AuthHeader = '',
        [bool] $CheckForSuccess = $true,
        $ArgumentsToLog = ''
    )
    if (!$ArgumentsToLog) {
    $ArgumentsToLog = $GitCmdArgs
    }
    Write-Output $("Running: "" $GitExeLocation"" $GitCmd $ArgumentsToLog" )
    $arguments = " $($AuthHeader)$GitCmd $GitCmdArgs"
    ProcessRunner -command $GitExeLocation -arguments $arguments -argumentsToLog " $GitCmd $ArgumentsToLog" -checkForSuccess $CheckForSuccess
}
    Executes a gvfs command with arguments
function ExecuteGvfsCmd {
    param(
        [ValidateNotNullOrEmpty()][string] $GvfsExeLocation,
        [ValidateNotNullOrEmpty()][string] $GvfsCmd,
        [string] $GvfsCmdArgs,
        [bool] $CheckForSuccess = $true,
        $ArgumentsToLog = ''
    )
    if (!$ArgumentsToLog) {
    $ArgumentsToLog = $GvfsCmdArgs
    }
    Write-Output $("Running: "" $GvfsExeLocation"" $GvfsCmd $ArgumentsToLog" )
    $arguments = " $GvfsCmd $GvfsCmdArgs"
    ProcessRunner -command $GvfsExeLocation -arguments $arguments -argumentsToLog " $GvfsCmd $ArgumentsToLog" -checkForSuccess $CheckForSuccess -waitForDependents $false
}
function ConfigureGitRepoBeforeClone {
    param(
        [ValidateNotNullOrEmpty()] $GitExeLocation
    )
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system core.safecrlf true"
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system push.default simple"
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system core.preloadindex true"
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system core.fscache true"
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system core.longpaths true"
}
function ConfigureGitRepoAfterClone {
    param(
        [ValidateNotNullOrEmpty()] $GitExeLocation,
        [ValidateNotNullOrEmpty()][string] $GitLocalRepoLocation,
        [ValidateNotNullOrEmpty()] [bool] $EnableGitCommitGraph
    )
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system --add safe.directory $($GitLocalRepoLocation -replace '\\','/')"
    if ($EnableGitCommitGraph -eq $true) {
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --local core.commitGraph true"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --local gc.writeCommitGraph true"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " commit-graph" -gitCmdArgs " write --reachable"
    }
}
    Calls update of the targetDirectory is a valid repository. Else it will attempt to clone the repository.
function UpdateOrCloneRepo {
    param(
        [ValidateNotNullOrEmpty()][string] $RepoUrl,
        [ValidateNotNullOrEmpty()][string] $TargetDirectory,
        [SourceControl]$SourceControl,
        [ValidateNotNullOrEmpty()][string] $CommitId,
        [string] $GitBranchName,
        [string] $OptionalCloneArgs,
        [bool] $CloneIfNotExists,
        [string] $OptionalFetchArgs,
        [bool] $EnableGitCommitGraph,
        [string] $FormattedSparseCheckoutFolders,
        [string] $MsiClientId
    )
    switch ($SourceControl) {
        { ($_ -eq [SourceControl]::git) -or ($_ -eq [SourceControl]::gvfs) } {
    $gitexe = Get-Command -ErrorAction Stop git
    $GitExeLocation = $gitexe.Source
        }
        { $_ -eq [SourceControl]::gvfs } {
    $gvfsexe = Get-Command -ErrorAction Stop gvfs
    $GvfsExeLocation = $gvfsexe.Source
        }
    }
    $ShouldCloneRepo = $false
    if ($RepoUrl.Contains("" )) {
    $RepoUrl = $RepoUrl.Replace(" " , "%20" )
    }
    if (!(Test-Path -Path $TargetDirectory -PathType Container)) {
        if ($CloneIfNotExists -eq $true) {
    $ShouldCloneRepo = $true
        }
        else {
            Write-Output " folder not found at '$TargetDirectory'."
            throw "folder not found."
        }
    }
    else {
        Set-Location -ErrorAction Stop $TargetDirectory
        switch ($SourceControl) {
            git {
                Write-Output "Testing if '$TargetDirectory' hosts a git repository..."
    $repo_originUrl = &$GitExeLocation remote get-url -ErrorAction Stop origin
            }
            gvfs {
                Write-Output "Testing if '$TargetDirectory' hosts a gvfs repository..."
                &$GvfsExeLocation status
                if ($? -eq $true) {
                    Set-Location -ErrorAction Stop (Join-Path $TargetDirectory " src" )
    $repo_originUrl = &$GitExeLocation remote get-url -ErrorAction Stop origin
                }
            }
        }
        if (-not $?) {
            if ($CloneIfNotExists -eq $true) {
    $ShouldCloneRepo = $true
            }
            else {
                Write-Output " repository not found at '$TargetDirectory'."
                throw "Repository not found."
            }
        }
    }
    if ($ShouldCloneRepo -eq $true) {
        ConfigureGitRepoBeforeClone -gitExeLocation $GitExeLocation
        switch ($SourceControl) {
            git {
                CloneGitRepo -gitExeLocation $GitExeLocation -gitRepoLocation $RepoUrl -gitLocalRepoLocation $TargetDirectory -gitBranchName $GitBranchName -optionalGitCloneArgs $OptionalCloneArgs -formattedSparseCheckoutFolders $FormattedSparseCheckoutFolders -msiClientId $MsiClientId
            }
            gvfs {
                GvfsCloneGitRepo -gitExeLocation $GitExeLocation -gvfsExeLocation $GvfsExeLocation -gvfsRepoLocation $RepoUrl -gvfsLocalRepoLocation $TargetDirectory -gitBranchName $GitBranchName -msiClientId $MsiClientId
    $TargetDirectory = Join-Path $TargetDirectory " src"
            }
        }
        Write-Information Changing to repo location: $(" '$TargetDirectory'" )
        Set-Location -ErrorAction Stop $TargetDirectory
    $repo_originUrl = &$GitExeLocation remote get-url -ErrorAction Stop origin
        ConfigureGitRepoAfterClone -gitExeLocation $GitExeLocation -gitLocalRepoLocation $TargetDirectory -enableGitCommitGraph $EnableGitCommitGraph
    }
    if ($ShouldCloneRepo -and $CommitId -eq 'latest') {
        Write-Output "Skip pulling latest updates for just cloned repo: $repo_originUrl"
    }
    else {
        Write-Information Updating repo with Url: $repo_originUrl
        UpdateGitRepo -gitExeLocation $GitExeLocation -gitRepoLocation $repo_originUrl -gitLocalRepoLocation $TargetDirectory -gitBranchName $GitBranchName -commitId $CommitId -optionalFetchArgs $OptionalFetchArgs -msiClientId $MsiClientId
    }
}
function Add-VarForLogging ($VarName, $VarValue) {
    if (!([string]::IsNullOrWhiteSpace($VarValue))) {
    $global:varLogArray | Add-Member -MemberType NoteProperty -Name $VarName -Value $VarValue
    }
}
function RunScriptSyncRepo(
    $RepoUrl,
    $repository_TargetDirectory,
    [SourceControl]$repository_SourceControl,
    $repository_cloneIfNotExists = $false,
    $RepoName,
    $CommitId,
    $BranchName,
    $repository_optionalCloningParameters,
    $repository_optionalFetchParameters,
    $EnableGitCommitGraph,
    $SparseCheckoutFolders,
    $repository_MSIClientId
) {
    $logfilepath = $null
    $script:varLogArray = New-Object -TypeName "PSCustomObject"
    Set-StrictMode -Version Latest
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
    $StartingDirectory = Get-Location -ErrorAction Stop
    $RepoLogFilePath = 'c:\.tools\RepoLogs'
    try {
        mkdir " $RepoLogFilePath" -Force
        switch ($repository_SourceControl) {
            { ($_ -eq [SourceControl]::git) -or ($_ -eq [SourceControl]::gvfs) } {
    $gitexe = Get-Command -ErrorAction Stop git
    $GitExeLocation = $gitexe.Source
                ProcessRunner -command $GitExeLocation -arguments " version"
                if ($? -ne $true) {
                    Write-Error Unable to find git.exe.
                    throw
                }
            }
            { $_ -eq [SourceControl]::gvfs } {
    $gvfsexe = Get-Command -ErrorAction Stop gvfs
    $GvfsExeLocation = $gvfsexe.Source
                ProcessRunner -command $GvfsExeLocation -arguments " version"
                if ($? -ne $true) {
                    Write-Error Unable to find gvfs.exe.
                    throw
                }
            }
        }
        Write-Information --------------------------------------
        Write-Output "Repository name: '$RepoName'"
        Write-Output "Commit id: '$CommitId'"
        Write-Output "BranchName name: '$BranchName'"
        Write-Information --------------------------------------
        Add-VarForLogging -varName 'RepoURL' -varValue $RepoUrl
        Add-VarForLogging -varName 'repository_TargetDirectory' -varValue $repository_TargetDirectory
        if (!([string]::IsNullOrWhiteSpace($BranchName))) {
            Write-Output "Use explicitly provided branch '$BranchName' rather than commitId"
    $CommitId = 'latest'
        }
        if ([string]::IsNullOrWhiteSpace($RepoUrl)) {
            throw "RepoUrl must be known at this point"
        }
    $FormattedSparseCheckoutFolders = ""
        if (-not [string]::IsNullOrWhiteSpace($SparseCheckoutFolders)) {
    $QuotedFolders = $SparseCheckoutFolders -Split ',' | ForEach-Object { '" ' + $_ + '" ' }
    $FormattedSparseCheckoutFolders = $QuotedFolders -Join " "
        }
        UpdateOrCloneRepo -repoUrl $RepoUrl -commitId $CommitId -gitBranchName $BranchName -enableGitCommitGraph $EnableGitCommitGraph -targetDirectory $repository_TargetDirectory -sourceControl $repository_SourceControl -optionalCloneArgs $repository_optionalCloningParameters -cloneIfNotExists $repository_cloneIfNotExists -optionalFetchArgs $repository_optionalFetchParameters -formattedSparseCheckoutFolders $FormattedSparseCheckoutFolders -msiClientId $repository_MSIClientId
        Write-Output "Var Log Array"
        Write-Output $global:varLogArray | ConvertTo-Json
        Write-Output "Derive Repo Log Name"
    $RepoLogFileName = [IO.Path]::GetFileName(" $repository_TargetDirectory" ) + " .json"
    $OutFile = " $RepoLogFilePath\$RepoLogFileName"
        Write-Output "Write output file to " $OutFile
    $global:varLogArray | ConvertTo-Json | Out-File -FilePath $OutFile
        Write-Information Completed!
    }
    catch {
        Write-Information -Object $_
        Write-Information -Object $_.ScriptStackTrace
        if (($null -ne Windows Clone Update Repo
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    Allows cloning a new or updating an existing repo (important for updating a chained image).
    $ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $RepoUrl,
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory = $true)]
    [String] $repository_TargetDirectory,
    [Parameter(Mandatory = $false)]
    [String] $repository_SourceControl,
    [Parameter(Mandatory = $false)]
    [bool] $repository_cloneIfNotExists = $false,
    [Parameter(Mandatory = $false)]
    [string] $RepoName,
    [Parameter(Mandatory = $false)]
    [string] $CommitId = 'latest',
    [Parameter(Mandatory = $false)]
    [string] $BranchName,
    [Parameter(Mandatory = $false)]
    [string] $repository_optionalCloningParameters,
    [Parameter(Mandatory = $false)]
    [string] $repository_optionalFetchParameters,
    [Parameter(Mandatory = $false)]
    [bool] $EnableGitCommitGraph = $false,
    [Parameter(Mandatory = $false)]
    [string] $SparseCheckoutFolders,
    [Parameter(Mandatory = $false)]
    [string] $repository_MSIClientId = $null
)
enum SourceControl {
    git = 0
    gvfs
}
    $logfilepath = $null
    $script:varLogArray = New-Object -TypeName "PSCustomObject"
Function ProcessRunner(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $command,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $arguments,
    $ArgumentsToLog = '',
    [bool] $CheckForSuccess = $true,
    [bool] $WaitForDependents = $true
) {
    if (!$ArgumentsToLog) {
    $ArgumentsToLog = $arguments
    }
    $ErrLog = [System.IO.Path]::GetTempFileName()
    if ($WaitForDependents) {
    $process = Start-Process -FilePath $command -ArgumentList $arguments -RedirectStandardError $ErrLog -Wait -PassThru -NoNewWindow
    }
    else {
    $process = Start-Process -FilePath $command -ArgumentList $arguments -RedirectStandardError $ErrLog -PassThru -NoNewWindow
    }
    if (!$process) {
        Write-Error "ERROR command failed to start: $command $ArgumentsToLog"
        return;
    }
    if ($WaitForDependents) {
    $ExitCode = $process.ExitCode
    }
    else {
    $process.WaitForExit()
    $process.HasExited
    $ExitCode = $process.GetType().GetField(" exitCode" , "NonPublic,Instance" ).GetValue($process) # Get the ExitCode from the hidden field but it is not publicly available
    }
    if ($ExitCode -ne 0) {
        Write-Output "Error running: $command $ArgumentsToLog"
        Write-Output "Exit code: $ExitCode"
        Write-Output " **ERROR**"
        Get-Content -Path $ErrLog
        if ([System.String]::IsNullOrWhiteSpace($logfilepath) -ne $true -and [System.IO.File]::Exists($logfilepath) -eq $true) {
            Write-Output "Logfile output from '$logfilepath':"
            Get-Content -ErrorAction Stop $logfilepath
        }
        if ($CheckForSuccess) {
            throw "Exit code from process was nonzero"
        }
        else {
            Write-Output " ==Ignored the error"
        }
    }
}
    Gvfs clones the repository and checks out to the specified gitBranchName
function GvfsCloneGitRepo {
    param(
        [ValidateNotNullOrEmpty()] $GitExeLocation,
        [ValidateNotNullOrEmpty()] $GvfsExeLocation,
        [ValidateNotNullOrEmpty()] $GvfsRepoLocation,
        [ValidateNotNullOrEmpty()] $GvfsLocalRepoLocation,
        [string] $GitBranchName,
        [string] $MsiClientId
    )
    if ($false -eq $GvfsRepoLocation.ToLowerInvariant().StartsWith(" https://" )) {
    $ErrMsg = $("Error! The specified Gvfs repo url is not a valid HTTPS clone url : " + $GvfsRepoLocation)
        Write-Output $ErrMsg
        Throw $ErrMsg
    }
    if ($false -eq ($GvfsRepoLocation.Length -gt 8)) {
    $ErrMsg = $("Error! The specified Git repo url is not valid : " + $GvfsRepoLocation)
        Write-Output $ErrMsg
        Throw $ErrMsg
    }
    $CmdArgs = $(" " + $GvfsRepoLocation + " `"" + $GvfsLocalRepoLocation + " `"" )
    Write-Output $("Gvfs cloning the git repo..." )
    $PrevCredentialHelper = &$GitExeLocation config --system credential.helper
    $GitAccessToken = Get-GitAccessToken -MsiClientID $MsiClientId
    $CredentialHelper = " `" !f() { test `" `$1`" = get && echo username=AzureManagedIdentity; echo password=$GitAccessToken; }; f`""
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system credential.helper $CredentialHelper" -argumentsToLog " --system credential.helper CUSTOM_AUTH_SCRIPT"
    $RunBlock = {
        ExecuteGvfsCmd -gvfsExeLocation $GvfsExeLocation -gvfsCmd " clone" -gvfsCmdArgs $CmdArgs
    }
    RunWithRetries -runBlock $RunBlock -retryAttempts 5 -waitBeforeRetrySeconds 30 -onFailureBlock {}
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system credential.helper $PrevCredentialHelper"
}
[OutputType([bool])]
 -ErrorAction Stop {
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String] $RepoUrl
    )
    return ($RepoUrl -Match '^https://[a-zA-Z][\w\-_]*\.visualstudio\.com/.*' -or $RepoUrl -Match '^https://dev\.azure\.com/.*')
}
    Clones the repository and checks out to the specified CommitId
function CloneGitRepo {
    param(
        [ValidateNotNullOrEmpty()] $GitExeLocation,
        [ValidateNotNullOrEmpty()] $GitRepoLocation,
        [ValidateNotNullOrEmpty()] $GitLocalRepoLocation,
        [string] $GitBranchName,
        [Parameter(Mandatory = $false)] $OptionalGitCloneArgs,
        [Parameter(Mandatory = $false)] $FormattedSparseCheckoutFolders,
        [Parameter(Mandatory = $false)][string] $MsiClientId
    )
    if ($false -eq $GitRepoLocation.ToLowerInvariant().StartsWith(" https://" )) {
    $ErrMsg = $("Error! The specified Git repo url is not a valid HTTPS clone url : " + $GitRepoLocation)
        Write-Output $ErrMsg
        Throw $ErrMsg
    }
    if ($false -eq ($GitRepoLocation.Length -gt 8)) {
    $ErrMsg = $("Error! The specified Git repo url is not valid : " + $GitRepoLocation)
        Write-Output $ErrMsg
        Throw $ErrMsg
    }
    $AuthorizationHeader = ''
    if (Get-CanUseManagedIdentityForRepo -RepoUrl $GitRepoLocation) {
    $AuthorizationHeader = Get-GitAuthorizationHeader -MsiClientID $MsiClientId
    }
    $OptionalArgs = ""
    if (!([System.String]::IsNullOrWhiteSpace($OptionalGitCloneArgs))) {
    $OptionalArgs = $OptionalGitCloneArgs
    }
    if (![string]::IsNullOrEmpty($GitBranchName)) {
    $OptionalArgs = " -b $GitBranchName " + $OptionalArgs
    }
    if (-not [string]::IsNullOrEmpty($FormattedSparseCheckoutFolders)) {
    $OptionalArgs = $OptionalArgs + " --no-checkout"
    }
    $CmdArgs = $($OptionalArgs + " " + $GitRepoLocation + " `"" + $GitLocalRepoLocation + " `"" )
    Write-Output $("Cloning the git repo..." )
    $RunBlock = {
        if (Test-Path $GitLocalRepoLocation) {
            Remove-Item -ErrorAction Stop $GitLocalRepoLocatio -Forcen -Force -Recurse -Force
        }
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " clone" -authHeader $AuthorizationHeader -gitCmdArgs $CmdArgs
    }
    RunWithRetries -runBlock $RunBlock -retryAttempts 5 -waitBeforeRetrySeconds 30 -onFailureBlock {}
    Write-Information Changing to repo location: $(" '$GitLocalRepoLocation'" )
    Set-Location -ErrorAction Stop $GitLocalRepoLocation
    if (-not [string]::IsNullOrEmpty($FormattedSparseCheckoutFolders)) {
    $SparseGitCmd = " set $FormattedSparseCheckoutFolders"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " sparse-checkout" -authHeader $AuthorizationHeader -gitCmdArgs $SparseGitCmd -argumentsToLog $SparseGitCmd
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " checkout" -authHeader $AuthorizationHeader
    }
}
    Updates the local repository to the commit ID specified
function UpdateGitRepo {
    param(
        [ValidateNotNullOrEmpty()] $GitExeLocation,
        [ValidateNotNullOrEmpty()] $GitRepoLocation,
        [ValidateNotNullOrEmpty()] $GitLocalRepoLocation,
        [string] $GitBranchName,
        [string] $CommitId,
        [string] $OptionalFetchArgs,
        [string] $FormattedSparseCheckoutFolders,
        [Parameter(Mandatory = $false)][string] $MsiClientId
    )
    if ($false -eq $GitRepoLocation.ToLowerInvariant().StartsWith(" https://" )) {
    $ErrMsg = $("Error! The specified Git repo url is not a valid HTTPS url : " + $GitRepoLocation)
        Write-Error $ErrMsg
        Throw $ErrMsg
    }
    if ($false -eq $GitRepoLocation.Length -gt 8) {
    $ErrMsg = $("Error! The specified Git repo url is not valid : " + $GitRepoLocation)
        Write-Error $ErrMsg
        Throw $ErrMsg
    }
    $AuthorizationHeader = ''
    if (Get-CanUseManagedIdentityForRepo -RepoUrl $GitRepoLocation) {
    $AuthorizationHeader = Get-GitAuthorizationHeader -MsiClientID $MsiClientId
    }
    $BaseRepoSparseCheckout = Invoke-Expression -Command '&$GitExeLocation config --get core.sparseCheckout'
    if ([string]::IsNullOrEmpty($BaseRepoSparseCheckout)) {
    $BaseRepoSparseCheckout = $false
    }
    $RepoSparseCheckout = $false
    if (-not [string]::IsNullOrEmpty($FormattedSparseCheckoutFolders)) {
    $RepoSparseCheckout = $true
    }
    if ($RepoSparseCheckout -ne $BaseRepoSparseCheckout) {
        Write-Output "Base image sparse checkout configuration: $BaseRepoSparseCheckout"
        Write-Output "Image sparse checkout configuration: $RepoSparseCheckout"
        throw "Sparse checkout configuration misaligned with base image"
    }
    $OptionalArgs = ""
    if (!([System.String]::IsNullOrWhiteSpace($OptionalFetchArgs))) {
    $OptionalArgs = $OptionalFetchArgs
    }
    if (![string]::IsNullOrEmpty($GitBranchName)) {
    $TempBranch = (New-Guid).Guid
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " checkout" -authHeader $AuthorizationHeader -gitCmdArgs " -b $TempBranch"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " branch" -gitCmdArgs " -D $GitBranchName" -checkForSuccess $false
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " fetch" -authHeader $AuthorizationHeader -gitCmdArgs " origin $($GitBranchName):$($GitBranchName) $OptionalArgs"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " checkout" -authHeader $AuthorizationHeader -gitCmdArgs " $GitBranchName"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " branch" -gitCmdArgs " -D $TempBranch"
    }
    elseif ($CommitId -ne 'latest') {
        Write-Output "Fetching commit $CommitId"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " fetch" -authHeader $AuthorizationHeader -gitCmdArgs " origin $CommitId $OptionalArgs"
        Write-Output "Resetting branch to $CommitId"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " reset" -authHeader $AuthorizationHeader -gitCmdArgs " $CommitId --hard"
    }
    else {
        Write-Output "Pulling the latest commit"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " pull" -authHeader $AuthorizationHeader -gitCmdArgs $OptionalArgs
    }
    $LogExpression = '&$GitExeLocation log -1 --quiet --format=%H'
    $UpdateCommitID = Invoke-Expression -Command $LogExpression
    Add-VarForLogging -varName 'CommitID' -varValue $UpdateCommitID
}
    Executes a git command with arguments
function ExecuteGitCmd {
    param(
        [ValidateNotNullOrEmpty()][string] $GitExeLocation,
        [ValidateNotNullOrEmpty()][string] $GitCmd,
        [string] $GitCmdArgs,
        [string] $AuthHeader = '',
        [bool] $CheckForSuccess = $true,
        $ArgumentsToLog = ''
    )
    if (!$ArgumentsToLog) {
    $ArgumentsToLog = $GitCmdArgs
    }
    Write-Output $("Running: "" $GitExeLocation"" $GitCmd $ArgumentsToLog" )
    $arguments = " $($AuthHeader)$GitCmd $GitCmdArgs"
    ProcessRunner -command $GitExeLocation -arguments $arguments -argumentsToLog " $GitCmd $ArgumentsToLog" -checkForSuccess $CheckForSuccess
}
    Executes a gvfs command with arguments
function ExecuteGvfsCmd {
    param(
        [ValidateNotNullOrEmpty()][string] $GvfsExeLocation,
        [ValidateNotNullOrEmpty()][string] $GvfsCmd,
        [string] $GvfsCmdArgs,
        [bool] $CheckForSuccess = $true,
        $ArgumentsToLog = ''
    )
    if (!$ArgumentsToLog) {
    $ArgumentsToLog = $GvfsCmdArgs
    }
    Write-Output $("Running: "" $GvfsExeLocation"" $GvfsCmd $ArgumentsToLog" )
    $arguments = " $GvfsCmd $GvfsCmdArgs"
    ProcessRunner -command $GvfsExeLocation -arguments $arguments -argumentsToLog " $GvfsCmd $ArgumentsToLog" -checkForSuccess $CheckForSuccess -waitForDependents $false
}
function ConfigureGitRepoBeforeClone {
    param(
        [ValidateNotNullOrEmpty()] $GitExeLocation
    )
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system core.safecrlf true"
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system push.default simple"
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system core.preloadindex true"
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system core.fscache true"
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system core.longpaths true"
}
function ConfigureGitRepoAfterClone {
    param(
        [ValidateNotNullOrEmpty()] $GitExeLocation,
        [ValidateNotNullOrEmpty()][string] $GitLocalRepoLocation,
        [ValidateNotNullOrEmpty()] [bool] $EnableGitCommitGraph
    )
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system --add safe.directory $($GitLocalRepoLocation -replace '\\','/')"
    if ($EnableGitCommitGraph -eq $true) {
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --local core.commitGraph true"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --local gc.writeCommitGraph true"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " commit-graph" -gitCmdArgs " write --reachable"
    }
}
    Calls update of the targetDirectory is a valid repository. Else it will attempt to clone the repository.
function UpdateOrCloneRepo {
    param(
        [ValidateNotNullOrEmpty()][string] $RepoUrl,
        [ValidateNotNullOrEmpty()][string] $TargetDirectory,
        [SourceControl]$SourceControl,
        [ValidateNotNullOrEmpty()][string] $CommitId,
        [string] $GitBranchName,
        [string] $OptionalCloneArgs,
        [bool] $CloneIfNotExists,
        [string] $OptionalFetchArgs,
        [bool] $EnableGitCommitGraph,
        [string] $FormattedSparseCheckoutFolders,
        [string] $MsiClientId
    )
    switch ($SourceControl) {
        { ($_ -eq [SourceControl]::git) -or ($_ -eq [SourceControl]::gvfs) } {
    $gitexe = Get-Command -ErrorAction Stop git
    $GitExeLocation = $gitexe.Source
        }
        { $_ -eq [SourceControl]::gvfs } {
    $gvfsexe = Get-Command -ErrorAction Stop gvfs
    $GvfsExeLocation = $gvfsexe.Source
        }
    }
    $ShouldCloneRepo = $false
    if ($RepoUrl.Contains("" )) {
    $RepoUrl = $RepoUrl.Replace(" " , "%20" )
    }
    if (!(Test-Path -Path $TargetDirectory -PathType Container)) {
        if ($CloneIfNotExists -eq $true) {
    $ShouldCloneRepo = $true
        }
        else {
            Write-Output " folder not found at '$TargetDirectory'."
            throw "folder not found."
        }
    }
    else {
        Set-Location -ErrorAction Stop $TargetDirectory
        switch ($SourceControl) {
            git {
                Write-Output "Testing if '$TargetDirectory' hosts a git repository..."
    $repo_originUrl = &$GitExeLocation remote get-url -ErrorAction Stop origin
            }
            gvfs {
                Write-Output "Testing if '$TargetDirectory' hosts a gvfs repository..."
                &$GvfsExeLocation status
                if ($? -eq $true) {
                    Set-Location -ErrorAction Stop (Join-Path $TargetDirectory " src" )
    $repo_originUrl = &$GitExeLocation remote get-url -ErrorAction Stop origin
                }
            }
        }
        if (-not $?) {
            if ($CloneIfNotExists -eq $true) {
    $ShouldCloneRepo = $true
            }
            else {
                Write-Output " repository not found at '$TargetDirectory'."
                throw "Repository not found."
            }
        }
    }
    if ($ShouldCloneRepo -eq $true) {
        ConfigureGitRepoBeforeClone -gitExeLocation $GitExeLocation
        switch ($SourceControl) {
            git {
                CloneGitRepo -gitExeLocation $GitExeLocation -gitRepoLocation $RepoUrl -gitLocalRepoLocation $TargetDirectory -gitBranchName $GitBranchName -optionalGitCloneArgs $OptionalCloneArgs -formattedSparseCheckoutFolders $FormattedSparseCheckoutFolders -msiClientId $MsiClientId
            }
            gvfs {
                GvfsCloneGitRepo -gitExeLocation $GitExeLocation -gvfsExeLocation $GvfsExeLocation -gvfsRepoLocation $RepoUrl -gvfsLocalRepoLocation $TargetDirectory -gitBranchName $GitBranchName -msiClientId $MsiClientId
    $TargetDirectory = Join-Path $TargetDirectory " src"
            }
        }
        Write-Information Changing to repo location: $(" '$TargetDirectory'" )
        Set-Location -ErrorAction Stop $TargetDirectory
    $repo_originUrl = &$GitExeLocation remote get-url -ErrorAction Stop origin
        ConfigureGitRepoAfterClone -gitExeLocation $GitExeLocation -gitLocalRepoLocation $TargetDirectory -enableGitCommitGraph $EnableGitCommitGraph
    }
    if ($ShouldCloneRepo -and $CommitId -eq 'latest') {
        Write-Output "Skip pulling latest updates for just cloned repo: $repo_originUrl"
    }
    else {
        Write-Information Updating repo with Url: $repo_originUrl
        UpdateGitRepo -gitExeLocation $GitExeLocation -gitRepoLocation $repo_originUrl -gitLocalRepoLocation $TargetDirectory -gitBranchName $GitBranchName -commitId $CommitId -optionalFetchArgs $OptionalFetchArgs -msiClientId $MsiClientId
    }
}
function Add-VarForLogging ($VarName, $VarValue) {
    if (!([string]::IsNullOrWhiteSpace($VarValue))) {
    $global:varLogArray | Add-Member -MemberType NoteProperty -Name $VarName -Value $VarValue
    }
}
function RunScriptSyncRepo(
    $RepoUrl,
    $repository_TargetDirectory,
    [SourceControl]$repository_SourceControl,
    $repository_cloneIfNotExists = $false,
    $RepoName,
    $CommitId,
    $BranchName,
    $repository_optionalCloningParameters,
    $repository_optionalFetchParameters,
    $EnableGitCommitGraph,
    $SparseCheckoutFolders,
    $repository_MSIClientId
) {
    $logfilepath = $null
    $script:varLogArray = New-Object -TypeName "PSCustomObject"
    Set-StrictMode -Version Latest
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
    $StartingDirectory = Get-Location -ErrorAction Stop
    $RepoLogFilePath = 'c:\.tools\RepoLogs'
    try {
        mkdir " $RepoLogFilePath" -Force
        switch ($repository_SourceControl) {
            { ($_ -eq [SourceControl]::git) -or ($_ -eq [SourceControl]::gvfs) } {
    $gitexe = Get-Command -ErrorAction Stop git
    $GitExeLocation = $gitexe.Source
                ProcessRunner -command $GitExeLocation -arguments " version"
                if ($? -ne $true) {
                    Write-Error Unable to find git.exe.
                    throw
                }
            }
            { $_ -eq [SourceControl]::gvfs } {
    $gvfsexe = Get-Command -ErrorAction Stop gvfs
    $GvfsExeLocation = $gvfsexe.Source
                ProcessRunner -command $GvfsExeLocation -arguments " version"
                if ($? -ne $true) {
                    Write-Error Unable to find gvfs.exe.
                    throw
                }
            }
        }
        Write-Information --------------------------------------
        Write-Output "Repository name: '$RepoName'"
        Write-Output "Commit id: '$CommitId'"
        Write-Output "BranchName name: '$BranchName'"
        Write-Information --------------------------------------
        Add-VarForLogging -varName 'RepoURL' -varValue $RepoUrl
        Add-VarForLogging -varName 'repository_TargetDirectory' -varValue $repository_TargetDirectory
        if (!([string]::IsNullOrWhiteSpace($BranchName))) {
            Write-Output "Use explicitly provided branch '$BranchName' rather than commitId"
    $CommitId = 'latest'
        }
        if ([string]::IsNullOrWhiteSpace($RepoUrl)) {
            throw "RepoUrl must be known at this point"
        }
    $FormattedSparseCheckoutFolders = ""
        if (-not [string]::IsNullOrWhiteSpace($SparseCheckoutFolders)) {
    $QuotedFolders = $SparseCheckoutFolders -Split ',' | ForEach-Object { '" ' + $_ + '" ' }
    $FormattedSparseCheckoutFolders = $QuotedFolders -Join " "
        }
        UpdateOrCloneRepo -repoUrl $RepoUrl -commitId $CommitId -gitBranchName $BranchName -enableGitCommitGraph $EnableGitCommitGraph -targetDirectory $repository_TargetDirectory -sourceControl $repository_SourceControl -optionalCloneArgs $repository_optionalCloningParameters -cloneIfNotExists $repository_cloneIfNotExists -optionalFetchArgs $repository_optionalFetchParameters -formattedSparseCheckoutFolders $FormattedSparseCheckoutFolders -msiClientId $repository_MSIClientId
        Write-Output "Var Log Array"
        Write-Output $global:varLogArray | ConvertTo-Json
        Write-Output "Derive Repo Log Name"
    $RepoLogFileName = [IO.Path]::GetFileName(" $repository_TargetDirectory" ) + " .json"
    $OutFile = " $RepoLogFilePath\$RepoLogFileName"
        Write-Output "Write output file to " $OutFile
    $global:varLogArray | ConvertTo-Json | Out-File -FilePath $OutFile
        Write-Information Completed!
    }
    catch {
        Write-Information -Object $_
        Write-Information -Object $_.ScriptStackTrace
        if (($null -ne $Error[0]) -and ($null -ne $Error[0].Exception) -and ($null -ne $Error[0].Exception.Message)) {
    $ErrMsg = $Error[0].Exception.Message
            Write-Output $ErrMsg
            Write-Error $ErrMsg
        }
        if ([System.String]::IsNullOrWhiteSpace($logfilepath) -ne $true -and [System.IO.File]::Exists($logfilepath) -eq $true) {
            Write-Output "Logfile output from '$logfilepath':"
            Get-Content -ErrorAction Stop $logfilepath
        }
        Write-Information \'Script failed.\'
        Set-Location -ErrorAction Stop $StartingDirectory
        throw
    }
    Set-Location -ErrorAction Stop $StartingDirectory
}
if ((-not (Test-Path variable:global:IsUnderTest)) -or (-not $global:IsUnderTest)) {
    [SourceControl]$SourceControl = [SourceControl]::git
    if (-not [String]::IsNullOrEmpty($repository_SourceControl)) {
    $SourceControl = [Enum]::Parse([SourceControl], $repository_SourceControl)
    }
    $params = @{
        repository_TargetDirectory = $repository_TargetDirectory
        repository_optionalCloningParameters = $repository_optionalCloningParameters
        repository_cloneIfNotExists = $repository_cloneIfNotExists
        enableGitCommitGraph = $EnableGitCommitGraph
        sparseCheckoutFolders = $SparseCheckoutFolders
        commitId = $CommitId
        repository_optionalFetchParameters = $repository_optionalFetchParameters
        repository_MSIClientId = $repository_MSIClientId
        branchName = $BranchName
        repository_SourceControl = $SourceControl
        repoName = $RepoName
        repoUrl = $RepoUrl
    }
    RunScriptSyncRepo @params
}
.Exception.Message) -and ($null -ne Windows Clone Update Repo
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    Allows cloning a new or updating an existing repo (important for updating a chained image).
    $ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $RepoUrl,
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory = $true)]
    [String] $repository_TargetDirectory,
    [Parameter(Mandatory = $false)]
    [String] $repository_SourceControl,
    [Parameter(Mandatory = $false)]
    [bool] $repository_cloneIfNotExists = $false,
    [Parameter(Mandatory = $false)]
    [string] $RepoName,
    [Parameter(Mandatory = $false)]
    [string] $CommitId = 'latest',
    [Parameter(Mandatory = $false)]
    [string] $BranchName,
    [Parameter(Mandatory = $false)]
    [string] $repository_optionalCloningParameters,
    [Parameter(Mandatory = $false)]
    [string] $repository_optionalFetchParameters,
    [Parameter(Mandatory = $false)]
    [bool] $EnableGitCommitGraph = $false,
    [Parameter(Mandatory = $false)]
    [string] $SparseCheckoutFolders,
    [Parameter(Mandatory = $false)]
    [string] $repository_MSIClientId = $null
)
enum SourceControl {
    git = 0
    gvfs
}
    $logfilepath = $null
    $script:varLogArray = New-Object -TypeName "PSCustomObject"
Function ProcessRunner(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $command,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $arguments,
    $ArgumentsToLog = '',
    [bool] $CheckForSuccess = $true,
    [bool] $WaitForDependents = $true
) {
    if (!$ArgumentsToLog) {
    $ArgumentsToLog = $arguments
    }
    $ErrLog = [System.IO.Path]::GetTempFileName()
    if ($WaitForDependents) {
    $process = Start-Process -FilePath $command -ArgumentList $arguments -RedirectStandardError $ErrLog -Wait -PassThru -NoNewWindow
    }
    else {
    $process = Start-Process -FilePath $command -ArgumentList $arguments -RedirectStandardError $ErrLog -PassThru -NoNewWindow
    }
    if (!$process) {
        Write-Error "ERROR command failed to start: $command $ArgumentsToLog"
        return;
    }
    if ($WaitForDependents) {
    $ExitCode = $process.ExitCode
    }
    else {
    $process.WaitForExit()
    $process.HasExited
    $ExitCode = $process.GetType().GetField(" exitCode" , "NonPublic,Instance" ).GetValue($process) # Get the ExitCode from the hidden field but it is not publicly available
    }
    if ($ExitCode -ne 0) {
        Write-Output "Error running: $command $ArgumentsToLog"
        Write-Output "Exit code: $ExitCode"
        Write-Output " **ERROR**"
        Get-Content -Path $ErrLog
        if ([System.String]::IsNullOrWhiteSpace($logfilepath) -ne $true -and [System.IO.File]::Exists($logfilepath) -eq $true) {
            Write-Output "Logfile output from '$logfilepath':"
            Get-Content -ErrorAction Stop $logfilepath
        }
        if ($CheckForSuccess) {
            throw "Exit code from process was nonzero"
        }
        else {
            Write-Output " ==Ignored the error"
        }
    }
}
    Gvfs clones the repository and checks out to the specified gitBranchName
function GvfsCloneGitRepo {
    param(
        [ValidateNotNullOrEmpty()] $GitExeLocation,
        [ValidateNotNullOrEmpty()] $GvfsExeLocation,
        [ValidateNotNullOrEmpty()] $GvfsRepoLocation,
        [ValidateNotNullOrEmpty()] $GvfsLocalRepoLocation,
        [string] $GitBranchName,
        [string] $MsiClientId
    )
    if ($false -eq $GvfsRepoLocation.ToLowerInvariant().StartsWith(" https://" )) {
    $ErrMsg = $("Error! The specified Gvfs repo url is not a valid HTTPS clone url : " + $GvfsRepoLocation)
        Write-Output $ErrMsg
        Throw $ErrMsg
    }
    if ($false -eq ($GvfsRepoLocation.Length -gt 8)) {
    $ErrMsg = $("Error! The specified Git repo url is not valid : " + $GvfsRepoLocation)
        Write-Output $ErrMsg
        Throw $ErrMsg
    }
    $CmdArgs = $(" " + $GvfsRepoLocation + " `"" + $GvfsLocalRepoLocation + " `"" )
    Write-Output $("Gvfs cloning the git repo..." )
    $PrevCredentialHelper = &$GitExeLocation config --system credential.helper
    $GitAccessToken = Get-GitAccessToken -MsiClientID $MsiClientId
    $CredentialHelper = " `" !f() { test `" `$1`" = get && echo username=AzureManagedIdentity; echo password=$GitAccessToken; }; f`""
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system credential.helper $CredentialHelper" -argumentsToLog " --system credential.helper CUSTOM_AUTH_SCRIPT"
    $RunBlock = {
        ExecuteGvfsCmd -gvfsExeLocation $GvfsExeLocation -gvfsCmd " clone" -gvfsCmdArgs $CmdArgs
    }
    RunWithRetries -runBlock $RunBlock -retryAttempts 5 -waitBeforeRetrySeconds 30 -onFailureBlock {}
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system credential.helper $PrevCredentialHelper"
}
[OutputType([bool])]
 -ErrorAction Stop {
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String] $RepoUrl
    )
    return ($RepoUrl -Match '^https://[a-zA-Z][\w\-_]*\.visualstudio\.com/.*' -or $RepoUrl -Match '^https://dev\.azure\.com/.*')
}
    Clones the repository and checks out to the specified CommitId
function CloneGitRepo {
    param(
        [ValidateNotNullOrEmpty()] $GitExeLocation,
        [ValidateNotNullOrEmpty()] $GitRepoLocation,
        [ValidateNotNullOrEmpty()] $GitLocalRepoLocation,
        [string] $GitBranchName,
        [Parameter(Mandatory = $false)] $OptionalGitCloneArgs,
        [Parameter(Mandatory = $false)] $FormattedSparseCheckoutFolders,
        [Parameter(Mandatory = $false)][string] $MsiClientId
    )
    if ($false -eq $GitRepoLocation.ToLowerInvariant().StartsWith(" https://" )) {
    $ErrMsg = $("Error! The specified Git repo url is not a valid HTTPS clone url : " + $GitRepoLocation)
        Write-Output $ErrMsg
        Throw $ErrMsg
    }
    if ($false -eq ($GitRepoLocation.Length -gt 8)) {
    $ErrMsg = $("Error! The specified Git repo url is not valid : " + $GitRepoLocation)
        Write-Output $ErrMsg
        Throw $ErrMsg
    }
    $AuthorizationHeader = ''
    if (Get-CanUseManagedIdentityForRepo -RepoUrl $GitRepoLocation) {
    $AuthorizationHeader = Get-GitAuthorizationHeader -MsiClientID $MsiClientId
    }
    $OptionalArgs = ""
    if (!([System.String]::IsNullOrWhiteSpace($OptionalGitCloneArgs))) {
    $OptionalArgs = $OptionalGitCloneArgs
    }
    if (![string]::IsNullOrEmpty($GitBranchName)) {
    $OptionalArgs = " -b $GitBranchName " + $OptionalArgs
    }
    if (-not [string]::IsNullOrEmpty($FormattedSparseCheckoutFolders)) {
    $OptionalArgs = $OptionalArgs + " --no-checkout"
    }
    $CmdArgs = $($OptionalArgs + " " + $GitRepoLocation + " `"" + $GitLocalRepoLocation + " `"" )
    Write-Output $("Cloning the git repo..." )
    $RunBlock = {
        if (Test-Path $GitLocalRepoLocation) {
            Remove-Item -ErrorAction Stop $GitLocalRepoLocatio -Forcen -Force -Recurse -Force
        }
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " clone" -authHeader $AuthorizationHeader -gitCmdArgs $CmdArgs
    }
    RunWithRetries -runBlock $RunBlock -retryAttempts 5 -waitBeforeRetrySeconds 30 -onFailureBlock {}
    Write-Information Changing to repo location: $(" '$GitLocalRepoLocation'" )
    Set-Location -ErrorAction Stop $GitLocalRepoLocation
    if (-not [string]::IsNullOrEmpty($FormattedSparseCheckoutFolders)) {
    $SparseGitCmd = " set $FormattedSparseCheckoutFolders"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " sparse-checkout" -authHeader $AuthorizationHeader -gitCmdArgs $SparseGitCmd -argumentsToLog $SparseGitCmd
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " checkout" -authHeader $AuthorizationHeader
    }
}
    Updates the local repository to the commit ID specified
function UpdateGitRepo {
    param(
        [ValidateNotNullOrEmpty()] $GitExeLocation,
        [ValidateNotNullOrEmpty()] $GitRepoLocation,
        [ValidateNotNullOrEmpty()] $GitLocalRepoLocation,
        [string] $GitBranchName,
        [string] $CommitId,
        [string] $OptionalFetchArgs,
        [string] $FormattedSparseCheckoutFolders,
        [Parameter(Mandatory = $false)][string] $MsiClientId
    )
    if ($false -eq $GitRepoLocation.ToLowerInvariant().StartsWith(" https://" )) {
    $ErrMsg = $("Error! The specified Git repo url is not a valid HTTPS url : " + $GitRepoLocation)
        Write-Error $ErrMsg
        Throw $ErrMsg
    }
    if ($false -eq $GitRepoLocation.Length -gt 8) {
    $ErrMsg = $("Error! The specified Git repo url is not valid : " + $GitRepoLocation)
        Write-Error $ErrMsg
        Throw $ErrMsg
    }
    $AuthorizationHeader = ''
    if (Get-CanUseManagedIdentityForRepo -RepoUrl $GitRepoLocation) {
    $AuthorizationHeader = Get-GitAuthorizationHeader -MsiClientID $MsiClientId
    }
    $BaseRepoSparseCheckout = Invoke-Expression -Command '&$GitExeLocation config --get core.sparseCheckout'
    if ([string]::IsNullOrEmpty($BaseRepoSparseCheckout)) {
    $BaseRepoSparseCheckout = $false
    }
    $RepoSparseCheckout = $false
    if (-not [string]::IsNullOrEmpty($FormattedSparseCheckoutFolders)) {
    $RepoSparseCheckout = $true
    }
    if ($RepoSparseCheckout -ne $BaseRepoSparseCheckout) {
        Write-Output "Base image sparse checkout configuration: $BaseRepoSparseCheckout"
        Write-Output "Image sparse checkout configuration: $RepoSparseCheckout"
        throw "Sparse checkout configuration misaligned with base image"
    }
    $OptionalArgs = ""
    if (!([System.String]::IsNullOrWhiteSpace($OptionalFetchArgs))) {
    $OptionalArgs = $OptionalFetchArgs
    }
    if (![string]::IsNullOrEmpty($GitBranchName)) {
    $TempBranch = (New-Guid).Guid
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " checkout" -authHeader $AuthorizationHeader -gitCmdArgs " -b $TempBranch"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " branch" -gitCmdArgs " -D $GitBranchName" -checkForSuccess $false
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " fetch" -authHeader $AuthorizationHeader -gitCmdArgs " origin $($GitBranchName):$($GitBranchName) $OptionalArgs"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " checkout" -authHeader $AuthorizationHeader -gitCmdArgs " $GitBranchName"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " branch" -gitCmdArgs " -D $TempBranch"
    }
    elseif ($CommitId -ne 'latest') {
        Write-Output "Fetching commit $CommitId"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " fetch" -authHeader $AuthorizationHeader -gitCmdArgs " origin $CommitId $OptionalArgs"
        Write-Output "Resetting branch to $CommitId"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " reset" -authHeader $AuthorizationHeader -gitCmdArgs " $CommitId --hard"
    }
    else {
        Write-Output "Pulling the latest commit"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " pull" -authHeader $AuthorizationHeader -gitCmdArgs $OptionalArgs
    }
    $LogExpression = '&$GitExeLocation log -1 --quiet --format=%H'
    $UpdateCommitID = Invoke-Expression -Command $LogExpression
    Add-VarForLogging -varName 'CommitID' -varValue $UpdateCommitID
}
    Executes a git command with arguments
function ExecuteGitCmd {
    param(
        [ValidateNotNullOrEmpty()][string] $GitExeLocation,
        [ValidateNotNullOrEmpty()][string] $GitCmd,
        [string] $GitCmdArgs,
        [string] $AuthHeader = '',
        [bool] $CheckForSuccess = $true,
        $ArgumentsToLog = ''
    )
    if (!$ArgumentsToLog) {
    $ArgumentsToLog = $GitCmdArgs
    }
    Write-Output $("Running: "" $GitExeLocation"" $GitCmd $ArgumentsToLog" )
    $arguments = " $($AuthHeader)$GitCmd $GitCmdArgs"
    ProcessRunner -command $GitExeLocation -arguments $arguments -argumentsToLog " $GitCmd $ArgumentsToLog" -checkForSuccess $CheckForSuccess
}
    Executes a gvfs command with arguments
function ExecuteGvfsCmd {
    param(
        [ValidateNotNullOrEmpty()][string] $GvfsExeLocation,
        [ValidateNotNullOrEmpty()][string] $GvfsCmd,
        [string] $GvfsCmdArgs,
        [bool] $CheckForSuccess = $true,
        $ArgumentsToLog = ''
    )
    if (!$ArgumentsToLog) {
    $ArgumentsToLog = $GvfsCmdArgs
    }
    Write-Output $("Running: "" $GvfsExeLocation"" $GvfsCmd $ArgumentsToLog" )
    $arguments = " $GvfsCmd $GvfsCmdArgs"
    ProcessRunner -command $GvfsExeLocation -arguments $arguments -argumentsToLog " $GvfsCmd $ArgumentsToLog" -checkForSuccess $CheckForSuccess -waitForDependents $false
}
function ConfigureGitRepoBeforeClone {
    param(
        [ValidateNotNullOrEmpty()] $GitExeLocation
    )
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system core.safecrlf true"
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system push.default simple"
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system core.preloadindex true"
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system core.fscache true"
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system core.longpaths true"
}
function ConfigureGitRepoAfterClone {
    param(
        [ValidateNotNullOrEmpty()] $GitExeLocation,
        [ValidateNotNullOrEmpty()][string] $GitLocalRepoLocation,
        [ValidateNotNullOrEmpty()] [bool] $EnableGitCommitGraph
    )
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system --add safe.directory $($GitLocalRepoLocation -replace '\\','/')"
    if ($EnableGitCommitGraph -eq $true) {
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --local core.commitGraph true"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --local gc.writeCommitGraph true"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " commit-graph" -gitCmdArgs " write --reachable"
    }
}
    Calls update of the targetDirectory is a valid repository. Else it will attempt to clone the repository.
function UpdateOrCloneRepo {
    param(
        [ValidateNotNullOrEmpty()][string] $RepoUrl,
        [ValidateNotNullOrEmpty()][string] $TargetDirectory,
        [SourceControl]$SourceControl,
        [ValidateNotNullOrEmpty()][string] $CommitId,
        [string] $GitBranchName,
        [string] $OptionalCloneArgs,
        [bool] $CloneIfNotExists,
        [string] $OptionalFetchArgs,
        [bool] $EnableGitCommitGraph,
        [string] $FormattedSparseCheckoutFolders,
        [string] $MsiClientId
    )
    switch ($SourceControl) {
        { ($_ -eq [SourceControl]::git) -or ($_ -eq [SourceControl]::gvfs) } {
    $gitexe = Get-Command -ErrorAction Stop git
    $GitExeLocation = $gitexe.Source
        }
        { $_ -eq [SourceControl]::gvfs } {
    $gvfsexe = Get-Command -ErrorAction Stop gvfs
    $GvfsExeLocation = $gvfsexe.Source
        }
    }
    $ShouldCloneRepo = $false
    if ($RepoUrl.Contains("" )) {
    $RepoUrl = $RepoUrl.Replace(" " , "%20" )
    }
    if (!(Test-Path -Path $TargetDirectory -PathType Container)) {
        if ($CloneIfNotExists -eq $true) {
    $ShouldCloneRepo = $true
        }
        else {
            Write-Output " folder not found at '$TargetDirectory'."
            throw "folder not found."
        }
    }
    else {
        Set-Location -ErrorAction Stop $TargetDirectory
        switch ($SourceControl) {
            git {
                Write-Output "Testing if '$TargetDirectory' hosts a git repository..."
    $repo_originUrl = &$GitExeLocation remote get-url -ErrorAction Stop origin
            }
            gvfs {
                Write-Output "Testing if '$TargetDirectory' hosts a gvfs repository..."
                &$GvfsExeLocation status
                if ($? -eq $true) {
                    Set-Location -ErrorAction Stop (Join-Path $TargetDirectory " src" )
    $repo_originUrl = &$GitExeLocation remote get-url -ErrorAction Stop origin
                }
            }
        }
        if (-not $?) {
            if ($CloneIfNotExists -eq $true) {
    $ShouldCloneRepo = $true
            }
            else {
                Write-Output " repository not found at '$TargetDirectory'."
                throw "Repository not found."
            }
        }
    }
    if ($ShouldCloneRepo -eq $true) {
        ConfigureGitRepoBeforeClone -gitExeLocation $GitExeLocation
        switch ($SourceControl) {
            git {
                CloneGitRepo -gitExeLocation $GitExeLocation -gitRepoLocation $RepoUrl -gitLocalRepoLocation $TargetDirectory -gitBranchName $GitBranchName -optionalGitCloneArgs $OptionalCloneArgs -formattedSparseCheckoutFolders $FormattedSparseCheckoutFolders -msiClientId $MsiClientId
            }
            gvfs {
                GvfsCloneGitRepo -gitExeLocation $GitExeLocation -gvfsExeLocation $GvfsExeLocation -gvfsRepoLocation $RepoUrl -gvfsLocalRepoLocation $TargetDirectory -gitBranchName $GitBranchName -msiClientId $MsiClientId
    $TargetDirectory = Join-Path $TargetDirectory " src"
            }
        }
        Write-Information Changing to repo location: $(" '$TargetDirectory'" )
        Set-Location -ErrorAction Stop $TargetDirectory
    $repo_originUrl = &$GitExeLocation remote get-url -ErrorAction Stop origin
        ConfigureGitRepoAfterClone -gitExeLocation $GitExeLocation -gitLocalRepoLocation $TargetDirectory -enableGitCommitGraph $EnableGitCommitGraph
    }
    if ($ShouldCloneRepo -and $CommitId -eq 'latest') {
        Write-Output "Skip pulling latest updates for just cloned repo: $repo_originUrl"
    }
    else {
        Write-Information Updating repo with Url: $repo_originUrl
        UpdateGitRepo -gitExeLocation $GitExeLocation -gitRepoLocation $repo_originUrl -gitLocalRepoLocation $TargetDirectory -gitBranchName $GitBranchName -commitId $CommitId -optionalFetchArgs $OptionalFetchArgs -msiClientId $MsiClientId
    }
}
function Add-VarForLogging ($VarName, $VarValue) {
    if (!([string]::IsNullOrWhiteSpace($VarValue))) {
    $global:varLogArray | Add-Member -MemberType NoteProperty -Name $VarName -Value $VarValue
    }
}
function RunScriptSyncRepo(
    $RepoUrl,
    $repository_TargetDirectory,
    [SourceControl]$repository_SourceControl,
    $repository_cloneIfNotExists = $false,
    $RepoName,
    $CommitId,
    $BranchName,
    $repository_optionalCloningParameters,
    $repository_optionalFetchParameters,
    $EnableGitCommitGraph,
    $SparseCheckoutFolders,
    $repository_MSIClientId
) {
    $logfilepath = $null
    $script:varLogArray = New-Object -TypeName "PSCustomObject"
    Set-StrictMode -Version Latest
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
    $StartingDirectory = Get-Location -ErrorAction Stop
    $RepoLogFilePath = 'c:\.tools\RepoLogs'
    try {
        mkdir " $RepoLogFilePath" -Force
        switch ($repository_SourceControl) {
            { ($_ -eq [SourceControl]::git) -or ($_ -eq [SourceControl]::gvfs) } {
    $gitexe = Get-Command -ErrorAction Stop git
    $GitExeLocation = $gitexe.Source
                ProcessRunner -command $GitExeLocation -arguments " version"
                if ($? -ne $true) {
                    Write-Error Unable to find git.exe.
                    throw
                }
            }
            { $_ -eq [SourceControl]::gvfs } {
    $gvfsexe = Get-Command -ErrorAction Stop gvfs
    $GvfsExeLocation = $gvfsexe.Source
                ProcessRunner -command $GvfsExeLocation -arguments " version"
                if ($? -ne $true) {
                    Write-Error Unable to find gvfs.exe.
                    throw
                }
            }
        }
        Write-Information --------------------------------------
        Write-Output "Repository name: '$RepoName'"
        Write-Output "Commit id: '$CommitId'"
        Write-Output "BranchName name: '$BranchName'"
        Write-Information --------------------------------------
        Add-VarForLogging -varName 'RepoURL' -varValue $RepoUrl
        Add-VarForLogging -varName 'repository_TargetDirectory' -varValue $repository_TargetDirectory
        if (!([string]::IsNullOrWhiteSpace($BranchName))) {
            Write-Output "Use explicitly provided branch '$BranchName' rather than commitId"
    $CommitId = 'latest'
        }
        if ([string]::IsNullOrWhiteSpace($RepoUrl)) {
            throw "RepoUrl must be known at this point"
        }
    $FormattedSparseCheckoutFolders = ""
        if (-not [string]::IsNullOrWhiteSpace($SparseCheckoutFolders)) {
    $QuotedFolders = $SparseCheckoutFolders -Split ',' | ForEach-Object { '" ' + $_ + '" ' }
    $FormattedSparseCheckoutFolders = $QuotedFolders -Join " "
        }
        UpdateOrCloneRepo -repoUrl $RepoUrl -commitId $CommitId -gitBranchName $BranchName -enableGitCommitGraph $EnableGitCommitGraph -targetDirectory $repository_TargetDirectory -sourceControl $repository_SourceControl -optionalCloneArgs $repository_optionalCloningParameters -cloneIfNotExists $repository_cloneIfNotExists -optionalFetchArgs $repository_optionalFetchParameters -formattedSparseCheckoutFolders $FormattedSparseCheckoutFolders -msiClientId $repository_MSIClientId
        Write-Output "Var Log Array"
        Write-Output $global:varLogArray | ConvertTo-Json
        Write-Output "Derive Repo Log Name"
    $RepoLogFileName = [IO.Path]::GetFileName(" $repository_TargetDirectory" ) + " .json"
    $OutFile = " $RepoLogFilePath\$RepoLogFileName"
        Write-Output "Write output file to " $OutFile
    $global:varLogArray | ConvertTo-Json | Out-File -FilePath $OutFile
        Write-Information Completed!
    }
    catch {
        Write-Information -Object $_
        Write-Information -Object $_.ScriptStackTrace
        if (($null -ne $Error[0]) -and ($null -ne $Error[0].Exception) -and ($null -ne $Error[0].Exception.Message)) {
    $ErrMsg = $Error[0].Exception.Message
            Write-Output $ErrMsg
            Write-Error $ErrMsg
        }
        if ([System.String]::IsNullOrWhiteSpace($logfilepath) -ne $true -and [System.IO.File]::Exists($logfilepath) -eq $true) {
            Write-Output "Logfile output from '$logfilepath':"
            Get-Content -ErrorAction Stop $logfilepath
        }
        Write-Information \'Script failed.\'
        Set-Location -ErrorAction Stop $StartingDirectory
        throw
    }
    Set-Location -ErrorAction Stop $StartingDirectory
}
if ((-not (Test-Path variable:global:IsUnderTest)) -or (-not $global:IsUnderTest)) {
    [SourceControl]$SourceControl = [SourceControl]::git
    if (-not [String]::IsNullOrEmpty($repository_SourceControl)) {
    $SourceControl = [Enum]::Parse([SourceControl], $repository_SourceControl)
    }
    $params = @{
        repository_TargetDirectory = $repository_TargetDirectory
        repository_optionalCloningParameters = $repository_optionalCloningParameters
        repository_cloneIfNotExists = $repository_cloneIfNotExists
        enableGitCommitGraph = $EnableGitCommitGraph
        sparseCheckoutFolders = $SparseCheckoutFolders
        commitId = $CommitId
        repository_optionalFetchParameters = $repository_optionalFetchParameters
        repository_MSIClientId = $repository_MSIClientId
        branchName = $BranchName
        repository_SourceControl = $SourceControl
        repoName = $RepoName
        repoUrl = $RepoUrl
    }
    RunScriptSyncRepo @params
}
.Exception.Message.Exception) -and ($null -ne Windows Clone Update Repo
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    Allows cloning a new or updating an existing repo (important for updating a chained image).
    $ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $RepoUrl,
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory = $true)]
    [String] $repository_TargetDirectory,
    [Parameter(Mandatory = $false)]
    [String] $repository_SourceControl,
    [Parameter(Mandatory = $false)]
    [bool] $repository_cloneIfNotExists = $false,
    [Parameter(Mandatory = $false)]
    [string] $RepoName,
    [Parameter(Mandatory = $false)]
    [string] $CommitId = 'latest',
    [Parameter(Mandatory = $false)]
    [string] $BranchName,
    [Parameter(Mandatory = $false)]
    [string] $repository_optionalCloningParameters,
    [Parameter(Mandatory = $false)]
    [string] $repository_optionalFetchParameters,
    [Parameter(Mandatory = $false)]
    [bool] $EnableGitCommitGraph = $false,
    [Parameter(Mandatory = $false)]
    [string] $SparseCheckoutFolders,
    [Parameter(Mandatory = $false)]
    [string] $repository_MSIClientId = $null
)
enum SourceControl {
    git = 0
    gvfs
}
    $logfilepath = $null
    $script:varLogArray = New-Object -TypeName "PSCustomObject"
Function ProcessRunner(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $command,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $arguments,
    $ArgumentsToLog = '',
    [bool] $CheckForSuccess = $true,
    [bool] $WaitForDependents = $true
) {
    if (!$ArgumentsToLog) {
    $ArgumentsToLog = $arguments
    }
    $ErrLog = [System.IO.Path]::GetTempFileName()
    if ($WaitForDependents) {
    $process = Start-Process -FilePath $command -ArgumentList $arguments -RedirectStandardError $ErrLog -Wait -PassThru -NoNewWindow
    }
    else {
    $process = Start-Process -FilePath $command -ArgumentList $arguments -RedirectStandardError $ErrLog -PassThru -NoNewWindow
    }
    if (!$process) {
        Write-Error "ERROR command failed to start: $command $ArgumentsToLog"
        return;
    }
    if ($WaitForDependents) {
    $ExitCode = $process.ExitCode
    }
    else {
    $process.WaitForExit()
    $process.HasExited
    $ExitCode = $process.GetType().GetField(" exitCode" , "NonPublic,Instance" ).GetValue($process) # Get the ExitCode from the hidden field but it is not publicly available
    }
    if ($ExitCode -ne 0) {
        Write-Output "Error running: $command $ArgumentsToLog"
        Write-Output "Exit code: $ExitCode"
        Write-Output " **ERROR**"
        Get-Content -Path $ErrLog
        if ([System.String]::IsNullOrWhiteSpace($logfilepath) -ne $true -and [System.IO.File]::Exists($logfilepath) -eq $true) {
            Write-Output "Logfile output from '$logfilepath':"
            Get-Content -ErrorAction Stop $logfilepath
        }
        if ($CheckForSuccess) {
            throw "Exit code from process was nonzero"
        }
        else {
            Write-Output " ==Ignored the error"
        }
    }
}
    Gvfs clones the repository and checks out to the specified gitBranchName
function GvfsCloneGitRepo {
    param(
        [ValidateNotNullOrEmpty()] $GitExeLocation,
        [ValidateNotNullOrEmpty()] $GvfsExeLocation,
        [ValidateNotNullOrEmpty()] $GvfsRepoLocation,
        [ValidateNotNullOrEmpty()] $GvfsLocalRepoLocation,
        [string] $GitBranchName,
        [string] $MsiClientId
    )
    if ($false -eq $GvfsRepoLocation.ToLowerInvariant().StartsWith(" https://" )) {
    $ErrMsg = $("Error! The specified Gvfs repo url is not a valid HTTPS clone url : " + $GvfsRepoLocation)
        Write-Output $ErrMsg
        Throw $ErrMsg
    }
    if ($false -eq ($GvfsRepoLocation.Length -gt 8)) {
    $ErrMsg = $("Error! The specified Git repo url is not valid : " + $GvfsRepoLocation)
        Write-Output $ErrMsg
        Throw $ErrMsg
    }
    $CmdArgs = $(" " + $GvfsRepoLocation + " `"" + $GvfsLocalRepoLocation + " `"" )
    Write-Output $("Gvfs cloning the git repo..." )
    $PrevCredentialHelper = &$GitExeLocation config --system credential.helper
    $GitAccessToken = Get-GitAccessToken -MsiClientID $MsiClientId
    $CredentialHelper = " `" !f() { test `" `$1`" = get && echo username=AzureManagedIdentity; echo password=$GitAccessToken; }; f`""
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system credential.helper $CredentialHelper" -argumentsToLog " --system credential.helper CUSTOM_AUTH_SCRIPT"
    $RunBlock = {
        ExecuteGvfsCmd -gvfsExeLocation $GvfsExeLocation -gvfsCmd " clone" -gvfsCmdArgs $CmdArgs
    }
    RunWithRetries -runBlock $RunBlock -retryAttempts 5 -waitBeforeRetrySeconds 30 -onFailureBlock {}
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system credential.helper $PrevCredentialHelper"
}
[OutputType([bool])]
 -ErrorAction Stop {
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String] $RepoUrl
    )
    return ($RepoUrl -Match '^https://[a-zA-Z][\w\-_]*\.visualstudio\.com/.*' -or $RepoUrl -Match '^https://dev\.azure\.com/.*')
}
    Clones the repository and checks out to the specified CommitId
function CloneGitRepo {
    param(
        [ValidateNotNullOrEmpty()] $GitExeLocation,
        [ValidateNotNullOrEmpty()] $GitRepoLocation,
        [ValidateNotNullOrEmpty()] $GitLocalRepoLocation,
        [string] $GitBranchName,
        [Parameter(Mandatory = $false)] $OptionalGitCloneArgs,
        [Parameter(Mandatory = $false)] $FormattedSparseCheckoutFolders,
        [Parameter(Mandatory = $false)][string] $MsiClientId
    )
    if ($false -eq $GitRepoLocation.ToLowerInvariant().StartsWith(" https://" )) {
    $ErrMsg = $("Error! The specified Git repo url is not a valid HTTPS clone url : " + $GitRepoLocation)
        Write-Output $ErrMsg
        Throw $ErrMsg
    }
    if ($false -eq ($GitRepoLocation.Length -gt 8)) {
    $ErrMsg = $("Error! The specified Git repo url is not valid : " + $GitRepoLocation)
        Write-Output $ErrMsg
        Throw $ErrMsg
    }
    $AuthorizationHeader = ''
    if (Get-CanUseManagedIdentityForRepo -RepoUrl $GitRepoLocation) {
    $AuthorizationHeader = Get-GitAuthorizationHeader -MsiClientID $MsiClientId
    }
    $OptionalArgs = ""
    if (!([System.String]::IsNullOrWhiteSpace($OptionalGitCloneArgs))) {
    $OptionalArgs = $OptionalGitCloneArgs
    }
    if (![string]::IsNullOrEmpty($GitBranchName)) {
    $OptionalArgs = " -b $GitBranchName " + $OptionalArgs
    }
    if (-not [string]::IsNullOrEmpty($FormattedSparseCheckoutFolders)) {
    $OptionalArgs = $OptionalArgs + " --no-checkout"
    }
    $CmdArgs = $($OptionalArgs + " " + $GitRepoLocation + " `"" + $GitLocalRepoLocation + " `"" )
    Write-Output $("Cloning the git repo..." )
    $RunBlock = {
        if (Test-Path $GitLocalRepoLocation) {
            Remove-Item -ErrorAction Stop $GitLocalRepoLocatio -Forcen -Force -Recurse -Force
        }
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " clone" -authHeader $AuthorizationHeader -gitCmdArgs $CmdArgs
    }
    RunWithRetries -runBlock $RunBlock -retryAttempts 5 -waitBeforeRetrySeconds 30 -onFailureBlock {}
    Write-Information Changing to repo location: $(" '$GitLocalRepoLocation'" )
    Set-Location -ErrorAction Stop $GitLocalRepoLocation
    if (-not [string]::IsNullOrEmpty($FormattedSparseCheckoutFolders)) {
    $SparseGitCmd = " set $FormattedSparseCheckoutFolders"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " sparse-checkout" -authHeader $AuthorizationHeader -gitCmdArgs $SparseGitCmd -argumentsToLog $SparseGitCmd
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " checkout" -authHeader $AuthorizationHeader
    }
}
    Updates the local repository to the commit ID specified
function UpdateGitRepo {
    param(
        [ValidateNotNullOrEmpty()] $GitExeLocation,
        [ValidateNotNullOrEmpty()] $GitRepoLocation,
        [ValidateNotNullOrEmpty()] $GitLocalRepoLocation,
        [string] $GitBranchName,
        [string] $CommitId,
        [string] $OptionalFetchArgs,
        [string] $FormattedSparseCheckoutFolders,
        [Parameter(Mandatory = $false)][string] $MsiClientId
    )
    if ($false -eq $GitRepoLocation.ToLowerInvariant().StartsWith(" https://" )) {
    $ErrMsg = $("Error! The specified Git repo url is not a valid HTTPS url : " + $GitRepoLocation)
        Write-Error $ErrMsg
        Throw $ErrMsg
    }
    if ($false -eq $GitRepoLocation.Length -gt 8) {
    $ErrMsg = $("Error! The specified Git repo url is not valid : " + $GitRepoLocation)
        Write-Error $ErrMsg
        Throw $ErrMsg
    }
    $AuthorizationHeader = ''
    if (Get-CanUseManagedIdentityForRepo -RepoUrl $GitRepoLocation) {
    $AuthorizationHeader = Get-GitAuthorizationHeader -MsiClientID $MsiClientId
    }
    $BaseRepoSparseCheckout = Invoke-Expression -Command '&$GitExeLocation config --get core.sparseCheckout'
    if ([string]::IsNullOrEmpty($BaseRepoSparseCheckout)) {
    $BaseRepoSparseCheckout = $false
    }
    $RepoSparseCheckout = $false
    if (-not [string]::IsNullOrEmpty($FormattedSparseCheckoutFolders)) {
    $RepoSparseCheckout = $true
    }
    if ($RepoSparseCheckout -ne $BaseRepoSparseCheckout) {
        Write-Output "Base image sparse checkout configuration: $BaseRepoSparseCheckout"
        Write-Output "Image sparse checkout configuration: $RepoSparseCheckout"
        throw "Sparse checkout configuration misaligned with base image"
    }
    $OptionalArgs = ""
    if (!([System.String]::IsNullOrWhiteSpace($OptionalFetchArgs))) {
    $OptionalArgs = $OptionalFetchArgs
    }
    if (![string]::IsNullOrEmpty($GitBranchName)) {
    $TempBranch = (New-Guid).Guid
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " checkout" -authHeader $AuthorizationHeader -gitCmdArgs " -b $TempBranch"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " branch" -gitCmdArgs " -D $GitBranchName" -checkForSuccess $false
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " fetch" -authHeader $AuthorizationHeader -gitCmdArgs " origin $($GitBranchName):$($GitBranchName) $OptionalArgs"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " checkout" -authHeader $AuthorizationHeader -gitCmdArgs " $GitBranchName"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " branch" -gitCmdArgs " -D $TempBranch"
    }
    elseif ($CommitId -ne 'latest') {
        Write-Output "Fetching commit $CommitId"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " fetch" -authHeader $AuthorizationHeader -gitCmdArgs " origin $CommitId $OptionalArgs"
        Write-Output "Resetting branch to $CommitId"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " reset" -authHeader $AuthorizationHeader -gitCmdArgs " $CommitId --hard"
    }
    else {
        Write-Output "Pulling the latest commit"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " pull" -authHeader $AuthorizationHeader -gitCmdArgs $OptionalArgs
    }
    $LogExpression = '&$GitExeLocation log -1 --quiet --format=%H'
    $UpdateCommitID = Invoke-Expression -Command $LogExpression
    Add-VarForLogging -varName 'CommitID' -varValue $UpdateCommitID
}
    Executes a git command with arguments
function ExecuteGitCmd {
    param(
        [ValidateNotNullOrEmpty()][string] $GitExeLocation,
        [ValidateNotNullOrEmpty()][string] $GitCmd,
        [string] $GitCmdArgs,
        [string] $AuthHeader = '',
        [bool] $CheckForSuccess = $true,
        $ArgumentsToLog = ''
    )
    if (!$ArgumentsToLog) {
    $ArgumentsToLog = $GitCmdArgs
    }
    Write-Output $("Running: "" $GitExeLocation"" $GitCmd $ArgumentsToLog" )
    $arguments = " $($AuthHeader)$GitCmd $GitCmdArgs"
    ProcessRunner -command $GitExeLocation -arguments $arguments -argumentsToLog " $GitCmd $ArgumentsToLog" -checkForSuccess $CheckForSuccess
}
    Executes a gvfs command with arguments
function ExecuteGvfsCmd {
    param(
        [ValidateNotNullOrEmpty()][string] $GvfsExeLocation,
        [ValidateNotNullOrEmpty()][string] $GvfsCmd,
        [string] $GvfsCmdArgs,
        [bool] $CheckForSuccess = $true,
        $ArgumentsToLog = ''
    )
    if (!$ArgumentsToLog) {
    $ArgumentsToLog = $GvfsCmdArgs
    }
    Write-Output $("Running: "" $GvfsExeLocation"" $GvfsCmd $ArgumentsToLog" )
    $arguments = " $GvfsCmd $GvfsCmdArgs"
    ProcessRunner -command $GvfsExeLocation -arguments $arguments -argumentsToLog " $GvfsCmd $ArgumentsToLog" -checkForSuccess $CheckForSuccess -waitForDependents $false
}
function ConfigureGitRepoBeforeClone {
    param(
        [ValidateNotNullOrEmpty()] $GitExeLocation
    )
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system core.safecrlf true"
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system push.default simple"
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system core.preloadindex true"
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system core.fscache true"
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system core.longpaths true"
}
function ConfigureGitRepoAfterClone {
    param(
        [ValidateNotNullOrEmpty()] $GitExeLocation,
        [ValidateNotNullOrEmpty()][string] $GitLocalRepoLocation,
        [ValidateNotNullOrEmpty()] [bool] $EnableGitCommitGraph
    )
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system --add safe.directory $($GitLocalRepoLocation -replace '\\','/')"
    if ($EnableGitCommitGraph -eq $true) {
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --local core.commitGraph true"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --local gc.writeCommitGraph true"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " commit-graph" -gitCmdArgs " write --reachable"
    }
}
    Calls update of the targetDirectory is a valid repository. Else it will attempt to clone the repository.
function UpdateOrCloneRepo {
    param(
        [ValidateNotNullOrEmpty()][string] $RepoUrl,
        [ValidateNotNullOrEmpty()][string] $TargetDirectory,
        [SourceControl]$SourceControl,
        [ValidateNotNullOrEmpty()][string] $CommitId,
        [string] $GitBranchName,
        [string] $OptionalCloneArgs,
        [bool] $CloneIfNotExists,
        [string] $OptionalFetchArgs,
        [bool] $EnableGitCommitGraph,
        [string] $FormattedSparseCheckoutFolders,
        [string] $MsiClientId
    )
    switch ($SourceControl) {
        { ($_ -eq [SourceControl]::git) -or ($_ -eq [SourceControl]::gvfs) } {
    $gitexe = Get-Command -ErrorAction Stop git
    $GitExeLocation = $gitexe.Source
        }
        { $_ -eq [SourceControl]::gvfs } {
    $gvfsexe = Get-Command -ErrorAction Stop gvfs
    $GvfsExeLocation = $gvfsexe.Source
        }
    }
    $ShouldCloneRepo = $false
    if ($RepoUrl.Contains("" )) {
    $RepoUrl = $RepoUrl.Replace(" " , "%20" )
    }
    if (!(Test-Path -Path $TargetDirectory -PathType Container)) {
        if ($CloneIfNotExists -eq $true) {
    $ShouldCloneRepo = $true
        }
        else {
            Write-Output " folder not found at '$TargetDirectory'."
            throw "folder not found."
        }
    }
    else {
        Set-Location -ErrorAction Stop $TargetDirectory
        switch ($SourceControl) {
            git {
                Write-Output "Testing if '$TargetDirectory' hosts a git repository..."
    $repo_originUrl = &$GitExeLocation remote get-url -ErrorAction Stop origin
            }
            gvfs {
                Write-Output "Testing if '$TargetDirectory' hosts a gvfs repository..."
                &$GvfsExeLocation status
                if ($? -eq $true) {
                    Set-Location -ErrorAction Stop (Join-Path $TargetDirectory " src" )
    $repo_originUrl = &$GitExeLocation remote get-url -ErrorAction Stop origin
                }
            }
        }
        if (-not $?) {
            if ($CloneIfNotExists -eq $true) {
    $ShouldCloneRepo = $true
            }
            else {
                Write-Output " repository not found at '$TargetDirectory'."
                throw "Repository not found."
            }
        }
    }
    if ($ShouldCloneRepo -eq $true) {
        ConfigureGitRepoBeforeClone -gitExeLocation $GitExeLocation
        switch ($SourceControl) {
            git {
                CloneGitRepo -gitExeLocation $GitExeLocation -gitRepoLocation $RepoUrl -gitLocalRepoLocation $TargetDirectory -gitBranchName $GitBranchName -optionalGitCloneArgs $OptionalCloneArgs -formattedSparseCheckoutFolders $FormattedSparseCheckoutFolders -msiClientId $MsiClientId
            }
            gvfs {
                GvfsCloneGitRepo -gitExeLocation $GitExeLocation -gvfsExeLocation $GvfsExeLocation -gvfsRepoLocation $RepoUrl -gvfsLocalRepoLocation $TargetDirectory -gitBranchName $GitBranchName -msiClientId $MsiClientId
    $TargetDirectory = Join-Path $TargetDirectory " src"
            }
        }
        Write-Information Changing to repo location: $(" '$TargetDirectory'" )
        Set-Location -ErrorAction Stop $TargetDirectory
    $repo_originUrl = &$GitExeLocation remote get-url -ErrorAction Stop origin
        ConfigureGitRepoAfterClone -gitExeLocation $GitExeLocation -gitLocalRepoLocation $TargetDirectory -enableGitCommitGraph $EnableGitCommitGraph
    }
    if ($ShouldCloneRepo -and $CommitId -eq 'latest') {
        Write-Output "Skip pulling latest updates for just cloned repo: $repo_originUrl"
    }
    else {
        Write-Information Updating repo with Url: $repo_originUrl
        UpdateGitRepo -gitExeLocation $GitExeLocation -gitRepoLocation $repo_originUrl -gitLocalRepoLocation $TargetDirectory -gitBranchName $GitBranchName -commitId $CommitId -optionalFetchArgs $OptionalFetchArgs -msiClientId $MsiClientId
    }
}
function Add-VarForLogging ($VarName, $VarValue) {
    if (!([string]::IsNullOrWhiteSpace($VarValue))) {
    $global:varLogArray | Add-Member -MemberType NoteProperty -Name $VarName -Value $VarValue
    }
}
function RunScriptSyncRepo(
    $RepoUrl,
    $repository_TargetDirectory,
    [SourceControl]$repository_SourceControl,
    $repository_cloneIfNotExists = $false,
    $RepoName,
    $CommitId,
    $BranchName,
    $repository_optionalCloningParameters,
    $repository_optionalFetchParameters,
    $EnableGitCommitGraph,
    $SparseCheckoutFolders,
    $repository_MSIClientId
) {
    $logfilepath = $null
    $script:varLogArray = New-Object -TypeName "PSCustomObject"
    Set-StrictMode -Version Latest
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
    $StartingDirectory = Get-Location -ErrorAction Stop
    $RepoLogFilePath = 'c:\.tools\RepoLogs'
    try {
        mkdir " $RepoLogFilePath" -Force
        switch ($repository_SourceControl) {
            { ($_ -eq [SourceControl]::git) -or ($_ -eq [SourceControl]::gvfs) } {
    $gitexe = Get-Command -ErrorAction Stop git
    $GitExeLocation = $gitexe.Source
                ProcessRunner -command $GitExeLocation -arguments " version"
                if ($? -ne $true) {
                    Write-Error Unable to find git.exe.
                    throw
                }
            }
            { $_ -eq [SourceControl]::gvfs } {
    $gvfsexe = Get-Command -ErrorAction Stop gvfs
    $GvfsExeLocation = $gvfsexe.Source
                ProcessRunner -command $GvfsExeLocation -arguments " version"
                if ($? -ne $true) {
                    Write-Error Unable to find gvfs.exe.
                    throw
                }
            }
        }
        Write-Information --------------------------------------
        Write-Output "Repository name: '$RepoName'"
        Write-Output "Commit id: '$CommitId'"
        Write-Output "BranchName name: '$BranchName'"
        Write-Information --------------------------------------
        Add-VarForLogging -varName 'RepoURL' -varValue $RepoUrl
        Add-VarForLogging -varName 'repository_TargetDirectory' -varValue $repository_TargetDirectory
        if (!([string]::IsNullOrWhiteSpace($BranchName))) {
            Write-Output "Use explicitly provided branch '$BranchName' rather than commitId"
    $CommitId = 'latest'
        }
        if ([string]::IsNullOrWhiteSpace($RepoUrl)) {
            throw "RepoUrl must be known at this point"
        }
    $FormattedSparseCheckoutFolders = ""
        if (-not [string]::IsNullOrWhiteSpace($SparseCheckoutFolders)) {
    $QuotedFolders = $SparseCheckoutFolders -Split ',' | ForEach-Object { '" ' + $_ + '" ' }
    $FormattedSparseCheckoutFolders = $QuotedFolders -Join " "
        }
        UpdateOrCloneRepo -repoUrl $RepoUrl -commitId $CommitId -gitBranchName $BranchName -enableGitCommitGraph $EnableGitCommitGraph -targetDirectory $repository_TargetDirectory -sourceControl $repository_SourceControl -optionalCloneArgs $repository_optionalCloningParameters -cloneIfNotExists $repository_cloneIfNotExists -optionalFetchArgs $repository_optionalFetchParameters -formattedSparseCheckoutFolders $FormattedSparseCheckoutFolders -msiClientId $repository_MSIClientId
        Write-Output "Var Log Array"
        Write-Output $global:varLogArray | ConvertTo-Json
        Write-Output "Derive Repo Log Name"
    $RepoLogFileName = [IO.Path]::GetFileName(" $repository_TargetDirectory" ) + " .json"
    $OutFile = " $RepoLogFilePath\$RepoLogFileName"
        Write-Output "Write output file to " $OutFile
    $global:varLogArray | ConvertTo-Json | Out-File -FilePath $OutFile
        Write-Information Completed!
    }
    catch {
        Write-Information -Object $_
        Write-Information -Object $_.ScriptStackTrace
        if (($null -ne $Error[0]) -and ($null -ne $Error[0].Exception) -and ($null -ne $Error[0].Exception.Message)) {
    $ErrMsg = $Error[0].Exception.Message
            Write-Output $ErrMsg
            Write-Error $ErrMsg
        }
        if ([System.String]::IsNullOrWhiteSpace($logfilepath) -ne $true -and [System.IO.File]::Exists($logfilepath) -eq $true) {
            Write-Output "Logfile output from '$logfilepath':"
            Get-Content -ErrorAction Stop $logfilepath
        }
        Write-Information \'Script failed.\'
        Set-Location -ErrorAction Stop $StartingDirectory
        throw
    }
    Set-Location -ErrorAction Stop $StartingDirectory
}
if ((-not (Test-Path variable:global:IsUnderTest)) -or (-not $global:IsUnderTest)) {
    [SourceControl]$SourceControl = [SourceControl]::git
    if (-not [String]::IsNullOrEmpty($repository_SourceControl)) {
    $SourceControl = [Enum]::Parse([SourceControl], $repository_SourceControl)
    }
    $params = @{
        repository_TargetDirectory = $repository_TargetDirectory
        repository_optionalCloningParameters = $repository_optionalCloningParameters
        repository_cloneIfNotExists = $repository_cloneIfNotExists
        enableGitCommitGraph = $EnableGitCommitGraph
        sparseCheckoutFolders = $SparseCheckoutFolders
        commitId = $CommitId
        repository_optionalFetchParameters = $repository_optionalFetchParameters
        repository_MSIClientId = $repository_MSIClientId
        branchName = $BranchName
        repository_SourceControl = $SourceControl
        repoName = $RepoName
        repoUrl = $RepoUrl
    }
    RunScriptSyncRepo @params
}
.Exception.Message.Exception.Message)) {
    $ErrMsg = Windows Clone Update Repo
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    Allows cloning a new or updating an existing repo (important for updating a chained image).
    $ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $RepoUrl,
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory = $true)]
    [String] $repository_TargetDirectory,
    [Parameter(Mandatory = $false)]
    [String] $repository_SourceControl,
    [Parameter(Mandatory = $false)]
    [bool] $repository_cloneIfNotExists = $false,
    [Parameter(Mandatory = $false)]
    [string] $RepoName,
    [Parameter(Mandatory = $false)]
    [string] $CommitId = 'latest',
    [Parameter(Mandatory = $false)]
    [string] $BranchName,
    [Parameter(Mandatory = $false)]
    [string] $repository_optionalCloningParameters,
    [Parameter(Mandatory = $false)]
    [string] $repository_optionalFetchParameters,
    [Parameter(Mandatory = $false)]
    [bool] $EnableGitCommitGraph = $false,
    [Parameter(Mandatory = $false)]
    [string] $SparseCheckoutFolders,
    [Parameter(Mandatory = $false)]
    [string] $repository_MSIClientId = $null
)
enum SourceControl {
    git = 0
    gvfs
}
    $logfilepath = $null
    $script:varLogArray = New-Object -TypeName "PSCustomObject"
Function ProcessRunner(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $command,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $arguments,
    $ArgumentsToLog = '',
    [bool] $CheckForSuccess = $true,
    [bool] $WaitForDependents = $true
) {
    if (!$ArgumentsToLog) {
    $ArgumentsToLog = $arguments
    }
    $ErrLog = [System.IO.Path]::GetTempFileName()
    if ($WaitForDependents) {
    $process = Start-Process -FilePath $command -ArgumentList $arguments -RedirectStandardError $ErrLog -Wait -PassThru -NoNewWindow
    }
    else {
    $process = Start-Process -FilePath $command -ArgumentList $arguments -RedirectStandardError $ErrLog -PassThru -NoNewWindow
    }
    if (!$process) {
        Write-Error "ERROR command failed to start: $command $ArgumentsToLog"
        return;
    }
    if ($WaitForDependents) {
    $ExitCode = $process.ExitCode
    }
    else {
    $process.WaitForExit()
    $process.HasExited
    $ExitCode = $process.GetType().GetField(" exitCode" , "NonPublic,Instance" ).GetValue($process) # Get the ExitCode from the hidden field but it is not publicly available
    }
    if ($ExitCode -ne 0) {
        Write-Output "Error running: $command $ArgumentsToLog"
        Write-Output "Exit code: $ExitCode"
        Write-Output " **ERROR**"
        Get-Content -Path $ErrLog
        if ([System.String]::IsNullOrWhiteSpace($logfilepath) -ne $true -and [System.IO.File]::Exists($logfilepath) -eq $true) {
            Write-Output "Logfile output from '$logfilepath':"
            Get-Content -ErrorAction Stop $logfilepath
        }
        if ($CheckForSuccess) {
            throw "Exit code from process was nonzero"
        }
        else {
            Write-Output " ==Ignored the error"
        }
    }
}
    Gvfs clones the repository and checks out to the specified gitBranchName
function GvfsCloneGitRepo {
    param(
        [ValidateNotNullOrEmpty()] $GitExeLocation,
        [ValidateNotNullOrEmpty()] $GvfsExeLocation,
        [ValidateNotNullOrEmpty()] $GvfsRepoLocation,
        [ValidateNotNullOrEmpty()] $GvfsLocalRepoLocation,
        [string] $GitBranchName,
        [string] $MsiClientId
    )
    if ($false -eq $GvfsRepoLocation.ToLowerInvariant().StartsWith(" https://" )) {
    $ErrMsg = $("Error! The specified Gvfs repo url is not a valid HTTPS clone url : " + $GvfsRepoLocation)
        Write-Output $ErrMsg
        Throw $ErrMsg
    }
    if ($false -eq ($GvfsRepoLocation.Length -gt 8)) {
    $ErrMsg = $("Error! The specified Git repo url is not valid : " + $GvfsRepoLocation)
        Write-Output $ErrMsg
        Throw $ErrMsg
    }
    $CmdArgs = $(" " + $GvfsRepoLocation + " `"" + $GvfsLocalRepoLocation + " `"" )
    Write-Output $("Gvfs cloning the git repo..." )
    $PrevCredentialHelper = &$GitExeLocation config --system credential.helper
    $GitAccessToken = Get-GitAccessToken -MsiClientID $MsiClientId
    $CredentialHelper = " `" !f() { test `" `$1`" = get && echo username=AzureManagedIdentity; echo password=$GitAccessToken; }; f`""
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system credential.helper $CredentialHelper" -argumentsToLog " --system credential.helper CUSTOM_AUTH_SCRIPT"
    $RunBlock = {
        ExecuteGvfsCmd -gvfsExeLocation $GvfsExeLocation -gvfsCmd " clone" -gvfsCmdArgs $CmdArgs
    }
    RunWithRetries -runBlock $RunBlock -retryAttempts 5 -waitBeforeRetrySeconds 30 -onFailureBlock {}
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system credential.helper $PrevCredentialHelper"
}
[OutputType([bool])]
 -ErrorAction Stop {
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String] $RepoUrl
    )
    return ($RepoUrl -Match '^https://[a-zA-Z][\w\-_]*\.visualstudio\.com/.*' -or $RepoUrl -Match '^https://dev\.azure\.com/.*')
}
    Clones the repository and checks out to the specified CommitId
function CloneGitRepo {
    param(
        [ValidateNotNullOrEmpty()] $GitExeLocation,
        [ValidateNotNullOrEmpty()] $GitRepoLocation,
        [ValidateNotNullOrEmpty()] $GitLocalRepoLocation,
        [string] $GitBranchName,
        [Parameter(Mandatory = $false)] $OptionalGitCloneArgs,
        [Parameter(Mandatory = $false)] $FormattedSparseCheckoutFolders,
        [Parameter(Mandatory = $false)][string] $MsiClientId
    )
    if ($false -eq $GitRepoLocation.ToLowerInvariant().StartsWith(" https://" )) {
    $ErrMsg = $("Error! The specified Git repo url is not a valid HTTPS clone url : " + $GitRepoLocation)
        Write-Output $ErrMsg
        Throw $ErrMsg
    }
    if ($false -eq ($GitRepoLocation.Length -gt 8)) {
    $ErrMsg = $("Error! The specified Git repo url is not valid : " + $GitRepoLocation)
        Write-Output $ErrMsg
        Throw $ErrMsg
    }
    $AuthorizationHeader = ''
    if (Get-CanUseManagedIdentityForRepo -RepoUrl $GitRepoLocation) {
    $AuthorizationHeader = Get-GitAuthorizationHeader -MsiClientID $MsiClientId
    }
    $OptionalArgs = ""
    if (!([System.String]::IsNullOrWhiteSpace($OptionalGitCloneArgs))) {
    $OptionalArgs = $OptionalGitCloneArgs
    }
    if (![string]::IsNullOrEmpty($GitBranchName)) {
    $OptionalArgs = " -b $GitBranchName " + $OptionalArgs
    }
    if (-not [string]::IsNullOrEmpty($FormattedSparseCheckoutFolders)) {
    $OptionalArgs = $OptionalArgs + " --no-checkout"
    }
    $CmdArgs = $($OptionalArgs + " " + $GitRepoLocation + " `"" + $GitLocalRepoLocation + " `"" )
    Write-Output $("Cloning the git repo..." )
    $RunBlock = {
        if (Test-Path $GitLocalRepoLocation) {
            Remove-Item -ErrorAction Stop $GitLocalRepoLocatio -Forcen -Force -Recurse -Force
        }
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " clone" -authHeader $AuthorizationHeader -gitCmdArgs $CmdArgs
    }
    RunWithRetries -runBlock $RunBlock -retryAttempts 5 -waitBeforeRetrySeconds 30 -onFailureBlock {}
    Write-Information Changing to repo location: $(" '$GitLocalRepoLocation'" )
    Set-Location -ErrorAction Stop $GitLocalRepoLocation
    if (-not [string]::IsNullOrEmpty($FormattedSparseCheckoutFolders)) {
    $SparseGitCmd = " set $FormattedSparseCheckoutFolders"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " sparse-checkout" -authHeader $AuthorizationHeader -gitCmdArgs $SparseGitCmd -argumentsToLog $SparseGitCmd
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " checkout" -authHeader $AuthorizationHeader
    }
}
    Updates the local repository to the commit ID specified
function UpdateGitRepo {
    param(
        [ValidateNotNullOrEmpty()] $GitExeLocation,
        [ValidateNotNullOrEmpty()] $GitRepoLocation,
        [ValidateNotNullOrEmpty()] $GitLocalRepoLocation,
        [string] $GitBranchName,
        [string] $CommitId,
        [string] $OptionalFetchArgs,
        [string] $FormattedSparseCheckoutFolders,
        [Parameter(Mandatory = $false)][string] $MsiClientId
    )
    if ($false -eq $GitRepoLocation.ToLowerInvariant().StartsWith(" https://" )) {
    $ErrMsg = $("Error! The specified Git repo url is not a valid HTTPS url : " + $GitRepoLocation)
        Write-Error $ErrMsg
        Throw $ErrMsg
    }
    if ($false -eq $GitRepoLocation.Length -gt 8) {
    $ErrMsg = $("Error! The specified Git repo url is not valid : " + $GitRepoLocation)
        Write-Error $ErrMsg
        Throw $ErrMsg
    }
    $AuthorizationHeader = ''
    if (Get-CanUseManagedIdentityForRepo -RepoUrl $GitRepoLocation) {
    $AuthorizationHeader = Get-GitAuthorizationHeader -MsiClientID $MsiClientId
    }
    $BaseRepoSparseCheckout = Invoke-Expression -Command '&$GitExeLocation config --get core.sparseCheckout'
    if ([string]::IsNullOrEmpty($BaseRepoSparseCheckout)) {
    $BaseRepoSparseCheckout = $false
    }
    $RepoSparseCheckout = $false
    if (-not [string]::IsNullOrEmpty($FormattedSparseCheckoutFolders)) {
    $RepoSparseCheckout = $true
    }
    if ($RepoSparseCheckout -ne $BaseRepoSparseCheckout) {
        Write-Output "Base image sparse checkout configuration: $BaseRepoSparseCheckout"
        Write-Output "Image sparse checkout configuration: $RepoSparseCheckout"
        throw "Sparse checkout configuration misaligned with base image"
    }
    $OptionalArgs = ""
    if (!([System.String]::IsNullOrWhiteSpace($OptionalFetchArgs))) {
    $OptionalArgs = $OptionalFetchArgs
    }
    if (![string]::IsNullOrEmpty($GitBranchName)) {
    $TempBranch = (New-Guid).Guid
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " checkout" -authHeader $AuthorizationHeader -gitCmdArgs " -b $TempBranch"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " branch" -gitCmdArgs " -D $GitBranchName" -checkForSuccess $false
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " fetch" -authHeader $AuthorizationHeader -gitCmdArgs " origin $($GitBranchName):$($GitBranchName) $OptionalArgs"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " checkout" -authHeader $AuthorizationHeader -gitCmdArgs " $GitBranchName"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " branch" -gitCmdArgs " -D $TempBranch"
    }
    elseif ($CommitId -ne 'latest') {
        Write-Output "Fetching commit $CommitId"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " fetch" -authHeader $AuthorizationHeader -gitCmdArgs " origin $CommitId $OptionalArgs"
        Write-Output "Resetting branch to $CommitId"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " reset" -authHeader $AuthorizationHeader -gitCmdArgs " $CommitId --hard"
    }
    else {
        Write-Output "Pulling the latest commit"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " pull" -authHeader $AuthorizationHeader -gitCmdArgs $OptionalArgs
    }
    $LogExpression = '&$GitExeLocation log -1 --quiet --format=%H'
    $UpdateCommitID = Invoke-Expression -Command $LogExpression
    Add-VarForLogging -varName 'CommitID' -varValue $UpdateCommitID
}
    Executes a git command with arguments
function ExecuteGitCmd {
    param(
        [ValidateNotNullOrEmpty()][string] $GitExeLocation,
        [ValidateNotNullOrEmpty()][string] $GitCmd,
        [string] $GitCmdArgs,
        [string] $AuthHeader = '',
        [bool] $CheckForSuccess = $true,
        $ArgumentsToLog = ''
    )
    if (!$ArgumentsToLog) {
    $ArgumentsToLog = $GitCmdArgs
    }
    Write-Output $("Running: "" $GitExeLocation"" $GitCmd $ArgumentsToLog" )
    $arguments = " $($AuthHeader)$GitCmd $GitCmdArgs"
    ProcessRunner -command $GitExeLocation -arguments $arguments -argumentsToLog " $GitCmd $ArgumentsToLog" -checkForSuccess $CheckForSuccess
}
    Executes a gvfs command with arguments
function ExecuteGvfsCmd {
    param(
        [ValidateNotNullOrEmpty()][string] $GvfsExeLocation,
        [ValidateNotNullOrEmpty()][string] $GvfsCmd,
        [string] $GvfsCmdArgs,
        [bool] $CheckForSuccess = $true,
        $ArgumentsToLog = ''
    )
    if (!$ArgumentsToLog) {
    $ArgumentsToLog = $GvfsCmdArgs
    }
    Write-Output $("Running: "" $GvfsExeLocation"" $GvfsCmd $ArgumentsToLog" )
    $arguments = " $GvfsCmd $GvfsCmdArgs"
    ProcessRunner -command $GvfsExeLocation -arguments $arguments -argumentsToLog " $GvfsCmd $ArgumentsToLog" -checkForSuccess $CheckForSuccess -waitForDependents $false
}
function ConfigureGitRepoBeforeClone {
    param(
        [ValidateNotNullOrEmpty()] $GitExeLocation
    )
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system core.safecrlf true"
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system push.default simple"
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system core.preloadindex true"
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system core.fscache true"
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system core.longpaths true"
}
function ConfigureGitRepoAfterClone {
    param(
        [ValidateNotNullOrEmpty()] $GitExeLocation,
        [ValidateNotNullOrEmpty()][string] $GitLocalRepoLocation,
        [ValidateNotNullOrEmpty()] [bool] $EnableGitCommitGraph
    )
    ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --system --add safe.directory $($GitLocalRepoLocation -replace '\\','/')"
    if ($EnableGitCommitGraph -eq $true) {
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --local core.commitGraph true"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " config" -gitCmdArgs " --local gc.writeCommitGraph true"
        ExecuteGitCmd -gitExeLocation $GitExeLocation -gitCmd " commit-graph" -gitCmdArgs " write --reachable"
    }
}
    Calls update of the targetDirectory is a valid repository. Else it will attempt to clone the repository.
function UpdateOrCloneRepo {
    param(
        [ValidateNotNullOrEmpty()][string] $RepoUrl,
        [ValidateNotNullOrEmpty()][string] $TargetDirectory,
        [SourceControl]$SourceControl,
        [ValidateNotNullOrEmpty()][string] $CommitId,
        [string] $GitBranchName,
        [string] $OptionalCloneArgs,
        [bool] $CloneIfNotExists,
        [string] $OptionalFetchArgs,
        [bool] $EnableGitCommitGraph,
        [string] $FormattedSparseCheckoutFolders,
        [string] $MsiClientId
    )
    switch ($SourceControl) {
        { ($_ -eq [SourceControl]::git) -or ($_ -eq [SourceControl]::gvfs) } {
    $gitexe = Get-Command -ErrorAction Stop git
    $GitExeLocation = $gitexe.Source
        }
        { $_ -eq [SourceControl]::gvfs } {
    $gvfsexe = Get-Command -ErrorAction Stop gvfs
    $GvfsExeLocation = $gvfsexe.Source
        }
    }
    $ShouldCloneRepo = $false
    if ($RepoUrl.Contains("" )) {
    $RepoUrl = $RepoUrl.Replace(" " , "%20" )
    }
    if (!(Test-Path -Path $TargetDirectory -PathType Container)) {
        if ($CloneIfNotExists -eq $true) {
    $ShouldCloneRepo = $true
        }
        else {
            Write-Output " folder not found at '$TargetDirectory'."
            throw "folder not found."
        }
    }
    else {
        Set-Location -ErrorAction Stop $TargetDirectory
        switch ($SourceControl) {
            git {
                Write-Output "Testing if '$TargetDirectory' hosts a git repository..."
    $repo_originUrl = &$GitExeLocation remote get-url -ErrorAction Stop origin
            }
            gvfs {
                Write-Output "Testing if '$TargetDirectory' hosts a gvfs repository..."
                &$GvfsExeLocation status
                if ($? -eq $true) {
                    Set-Location -ErrorAction Stop (Join-Path $TargetDirectory " src" )
    $repo_originUrl = &$GitExeLocation remote get-url -ErrorAction Stop origin
                }
            }
        }
        if (-not $?) {
            if ($CloneIfNotExists -eq $true) {
    $ShouldCloneRepo = $true
            }
            else {
                Write-Output " repository not found at '$TargetDirectory'."
                throw "Repository not found."
            }
        }
    }
    if ($ShouldCloneRepo -eq $true) {
        ConfigureGitRepoBeforeClone -gitExeLocation $GitExeLocation
        switch ($SourceControl) {
            git {
                CloneGitRepo -gitExeLocation $GitExeLocation -gitRepoLocation $RepoUrl -gitLocalRepoLocation $TargetDirectory -gitBranchName $GitBranchName -optionalGitCloneArgs $OptionalCloneArgs -formattedSparseCheckoutFolders $FormattedSparseCheckoutFolders -msiClientId $MsiClientId
            }
            gvfs {
                GvfsCloneGitRepo -gitExeLocation $GitExeLocation -gvfsExeLocation $GvfsExeLocation -gvfsRepoLocation $RepoUrl -gvfsLocalRepoLocation $TargetDirectory -gitBranchName $GitBranchName -msiClientId $MsiClientId
    $TargetDirectory = Join-Path $TargetDirectory " src"
            }
        }
        Write-Information Changing to repo location: $(" '$TargetDirectory'" )
        Set-Location -ErrorAction Stop $TargetDirectory
    $repo_originUrl = &$GitExeLocation remote get-url -ErrorAction Stop origin
        ConfigureGitRepoAfterClone -gitExeLocation $GitExeLocation -gitLocalRepoLocation $TargetDirectory -enableGitCommitGraph $EnableGitCommitGraph
    }
    if ($ShouldCloneRepo -and $CommitId -eq 'latest') {
        Write-Output "Skip pulling latest updates for just cloned repo: $repo_originUrl"
    }
    else {
        Write-Information Updating repo with Url: $repo_originUrl
        UpdateGitRepo -gitExeLocation $GitExeLocation -gitRepoLocation $repo_originUrl -gitLocalRepoLocation $TargetDirectory -gitBranchName $GitBranchName -commitId $CommitId -optionalFetchArgs $OptionalFetchArgs -msiClientId $MsiClientId
    }
}
function Add-VarForLogging ($VarName, $VarValue) {
    if (!([string]::IsNullOrWhiteSpace($VarValue))) {
    $global:varLogArray | Add-Member -MemberType NoteProperty -Name $VarName -Value $VarValue
    }
}
function RunScriptSyncRepo(
    $RepoUrl,
    $repository_TargetDirectory,
    [SourceControl]$repository_SourceControl,
    $repository_cloneIfNotExists = $false,
    $RepoName,
    $CommitId,
    $BranchName,
    $repository_optionalCloningParameters,
    $repository_optionalFetchParameters,
    $EnableGitCommitGraph,
    $SparseCheckoutFolders,
    $repository_MSIClientId
) {
    $logfilepath = $null
    $script:varLogArray = New-Object -TypeName "PSCustomObject"
    Set-StrictMode -Version Latest
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
    $StartingDirectory = Get-Location -ErrorAction Stop
    $RepoLogFilePath = 'c:\.tools\RepoLogs'
    try {
        mkdir " $RepoLogFilePath" -Force
        switch ($repository_SourceControl) {
            { ($_ -eq [SourceControl]::git) -or ($_ -eq [SourceControl]::gvfs) } {
    $gitexe = Get-Command -ErrorAction Stop git
    $GitExeLocation = $gitexe.Source
                ProcessRunner -command $GitExeLocation -arguments " version"
                if ($? -ne $true) {
                    Write-Error Unable to find git.exe.
                    throw
                }
            }
            { $_ -eq [SourceControl]::gvfs } {
    $gvfsexe = Get-Command -ErrorAction Stop gvfs
    $GvfsExeLocation = $gvfsexe.Source
                ProcessRunner -command $GvfsExeLocation -arguments " version"
                if ($? -ne $true) {
                    Write-Error Unable to find gvfs.exe.
                    throw
                }
            }
        }
        Write-Information --------------------------------------
        Write-Output "Repository name: '$RepoName'"
        Write-Output "Commit id: '$CommitId'"
        Write-Output "BranchName name: '$BranchName'"
        Write-Information --------------------------------------
        Add-VarForLogging -varName 'RepoURL' -varValue $RepoUrl
        Add-VarForLogging -varName 'repository_TargetDirectory' -varValue $repository_TargetDirectory
        if (!([string]::IsNullOrWhiteSpace($BranchName))) {
            Write-Output "Use explicitly provided branch '$BranchName' rather than commitId"
    $CommitId = 'latest'
        }
        if ([string]::IsNullOrWhiteSpace($RepoUrl)) {
            throw "RepoUrl must be known at this point"
        }
    $FormattedSparseCheckoutFolders = ""
        if (-not [string]::IsNullOrWhiteSpace($SparseCheckoutFolders)) {
    $QuotedFolders = $SparseCheckoutFolders -Split ',' | ForEach-Object { '" ' + $_ + '" ' }
    $FormattedSparseCheckoutFolders = $QuotedFolders -Join " "
        }
        UpdateOrCloneRepo -repoUrl $RepoUrl -commitId $CommitId -gitBranchName $BranchName -enableGitCommitGraph $EnableGitCommitGraph -targetDirectory $repository_TargetDirectory -sourceControl $repository_SourceControl -optionalCloneArgs $repository_optionalCloningParameters -cloneIfNotExists $repository_cloneIfNotExists -optionalFetchArgs $repository_optionalFetchParameters -formattedSparseCheckoutFolders $FormattedSparseCheckoutFolders -msiClientId $repository_MSIClientId
        Write-Output "Var Log Array"
        Write-Output $global:varLogArray | ConvertTo-Json
        Write-Output "Derive Repo Log Name"
    $RepoLogFileName = [IO.Path]::GetFileName(" $repository_TargetDirectory" ) + " .json"
    $OutFile = " $RepoLogFilePath\$RepoLogFileName"
        Write-Output "Write output file to " $OutFile
    $global:varLogArray | ConvertTo-Json | Out-File -FilePath $OutFile
        Write-Information Completed!
    }
    catch {
        Write-Information -Object $_
        Write-Information -Object $_.ScriptStackTrace
        if (($null -ne $Error[0]) -and ($null -ne $Error[0].Exception) -and ($null -ne $Error[0].Exception.Message)) {
    $ErrMsg = $Error[0].Exception.Message
            Write-Output $ErrMsg
            Write-Error $ErrMsg
        }
        if ([System.String]::IsNullOrWhiteSpace($logfilepath) -ne $true -and [System.IO.File]::Exists($logfilepath) -eq $true) {
            Write-Output "Logfile output from '$logfilepath':"
            Get-Content -ErrorAction Stop $logfilepath
        }
        Write-Information \'Script failed.\'
        Set-Location -ErrorAction Stop $StartingDirectory
        throw
    }
    Set-Location -ErrorAction Stop $StartingDirectory
}
if ((-not (Test-Path variable:global:IsUnderTest)) -or (-not $global:IsUnderTest)) {
    [SourceControl]$SourceControl = [SourceControl]::git
    if (-not [String]::IsNullOrEmpty($repository_SourceControl)) {
    $SourceControl = [Enum]::Parse([SourceControl], $repository_SourceControl)
    }
    $params = @{
        repository_TargetDirectory = $repository_TargetDirectory
        repository_optionalCloningParameters = $repository_optionalCloningParameters
        repository_cloneIfNotExists = $repository_cloneIfNotExists
        enableGitCommitGraph = $EnableGitCommitGraph
        sparseCheckoutFolders = $SparseCheckoutFolders
        commitId = $CommitId
        repository_optionalFetchParameters = $repository_optionalFetchParameters
        repository_MSIClientId = $repository_MSIClientId
        branchName = $BranchName
        repository_SourceControl = $SourceControl
        repoName = $RepoName
        repoUrl = $RepoUrl
    }
    RunScriptSyncRepo @params
}
.Exception.Message.Exception.Message
            Write-Output $ErrMsg
            Write-Error $ErrMsg
        }
        if ([System.String]::IsNullOrWhiteSpace($logfilepath) -ne $true -and [System.IO.File]::Exists($logfilepath) -eq $true) {
            Write-Output "Logfile output from '$logfilepath':"
            Get-Content -ErrorAction Stop $logfilepath
        }
        Write-Information \'Script failed.\'
        Set-Location -ErrorAction Stop $StartingDirectory
        throw
    }
    Set-Location -ErrorAction Stop $StartingDirectory
}
if ((-not (Test-Path variable:global:IsUnderTest)) -or (-not $global:IsUnderTest)) {
    [SourceControl]$SourceControl = [SourceControl]::git
    if (-not [String]::IsNullOrEmpty($repository_SourceControl)) {
    $SourceControl = [Enum]::Parse([SourceControl], $repository_SourceControl)
    }
    $params = @{
        repository_TargetDirectory = $repository_TargetDirectory
        repository_optionalCloningParameters = $repository_optionalCloningParameters
        repository_cloneIfNotExists = $repository_cloneIfNotExists
        enableGitCommitGraph = $EnableGitCommitGraph
        sparseCheckoutFolders = $SparseCheckoutFolders
        commitId = $CommitId
        repository_optionalFetchParameters = $repository_optionalFetchParameters
        repository_MSIClientId = $repository_MSIClientId
        branchName = $BranchName
        repository_SourceControl = $SourceControl
        repoName = $RepoName
        repoUrl = $RepoUrl
    }
    RunScriptSyncRepo @params`n}
