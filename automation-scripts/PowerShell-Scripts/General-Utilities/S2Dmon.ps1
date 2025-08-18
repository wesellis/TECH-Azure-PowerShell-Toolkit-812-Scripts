<#
.SYNOPSIS
    We Enhanced S2Dmon

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
    A sample Windows service, in a standalone PowerShell script.

  .DESCRIPTION
    This script demonstrates how to write a Windows service in pure PowerShell.
    It dynamically generates a small PSService.exe wrapper, that in turn
    invokes this PowerShell script again for its start and stop events.

  .PARAMETER Start
    Start the service.

  .PARAMETER Stop
    Stop the service.

  .PARAMETER Restart
    Stop then restart the service.

  .PARAMETER Status
    Get the current service status: Not installed / Stopped / Running

  .PARAMETER Setup
    Install the service.

  .PARAMETER Remove
    Uninstall the service.

  .PARAMETER Service
    Run the service in the background. Used internally by the script.
    Do not use, except for test purposes.

  .PARAMETER Control
    Send a control message to the service thread.

  .PARAMETER Version
    Display this script version and exit.

  .EXAMPLE
    # Setup the service and run it for the first time
    C:\PS>.\PSService.ps1 -Status
    Not installed
    C:\PS>.\PSService.ps1 -Setup
    C:\PS># At this stage, a copy of PSService.ps1 is present in the path
    C:\PS>PSService -Status
    Stopped
    C:\PS>PSService -Start
    C:\PS>PSService -Status
    Running
    C:\PS># Load the log file in Notepad.exe for review
    C:\PS>notepad ${ENV:windir}\Logs\PSService.log

  .EXAMPLE
    # Stop the service and uninstall it.
    C:\PS>PSService -Stop
    C:\PS>PSService -Status
    Stopped
    C:\PS>PSService -Remove
    C:\PS># At this stage, no copy of PSService.ps1 is present in the path anymore
    C:\PS>.\PSService.ps1 -Status
    Not installed

  .EXAMPLE
    # Send a control message to the service, and verify that it received it.
    C:\PS>PSService -Control Hello
    C:\PS>Notepad C:\Windows\Logs\PSService.log
    # The last lines should contain a trace of the reception of this Hello message


[CmdletBinding(DefaultParameterSetName='Status')]
param(
  [Parameter(ParameterSetName='Start', Mandatory=$true)]
  [Switch]$WEStart,               # Start the service

  [Parameter(ParameterSetName='Stop', Mandatory=$true)]
  [Switch]$WEStop,                # Stop the service

  [Parameter(ParameterSetName='Restart', Mandatory=$true)]
  [Switch]$WERestart,             # Restart the service

  [Parameter(ParameterSetName='Status', Mandatory=$false)]
  [Switch]$WEStatus = $($WEPSCmdlet.ParameterSetName -eq 'Status'), # Get the current service status

  [Parameter(ParameterSetName='Setup', Mandatory=$true)]
  [Switch]$WESetup,               # Install the service

  [Parameter(ParameterSetName='Setup', Mandatory=$true)]
  [System.Management.Automation.CredentialAttribute()]$WEOMSWorkspaceCreds,

  [Parameter(ParameterSetName='Remove', Mandatory=$true)]
  [Switch]$WERemove,              # Uninstall the service

  [Parameter(ParameterSetName='Service', Mandatory=$true)]
  [Switch]$WEService,             # Run the service

  [Parameter(ParameterSetName='Control', Mandatory=$true)]
  [String]$WEControl = $null,     # Control message to send to the service

  [Parameter(ParameterSetName='Version', Mandatory=$true)]
  [Switch]$WEVersion              # Get this script version
)

$scriptVersion = "2016-11-17"


$argv0 = Get-Item $WEMyInvocation.MyCommand.Definition
$script = $argv0.basename               # Ex: PSService
$scriptName = $argv0.name               # Ex: PSService.ps1
$scriptFullName = $argv0.fullname       # Ex: C:\Temp\PSService.ps1


$serviceName = $script                  # A one-word name used for net start commands
$serviceDisplayName = " S2DMon"
$WEServiceDescription = " Service for sending S2D data to OMS"
$pipeName = " Service_$serviceName"      # Named pipe name. Used for sending messages to the service task

$installDir = " ${ENV:windir}\System32"  # Where to install the service files
$scriptCopy = " $installDir\$scriptName"
$exeName = " $serviceName.exe"
$exeFullName = " $installDir\$exeName"

$WEKeyFileName = " $serviceName.key"
$WEKeyFileFullName = " $installDir\$WEKeyFileName"

$credFileName = " $serviceName.cred"
$credFileFullName = " $installDir\$credFileName"

$workspaceIdFileName = " $serviceName.id"
$workspaceIdFileFullName = " $installDir\$workspaceIdFileName"
$logDir = " ${ENV:windir}\Logs"          # Where to log the service messages
$logFile = " $logDir\$serviceName.log"
$logName = " Application"                # Event Log name (Unrelated to the logFile!)



if ($WEVersion) {
  Write-Output $scriptVersion
  return
}



Function Now {
  param(
    [Switch]$ms,        # Append milliseconds
    [Switch]$ns         # Append nanoseconds
  )
  $WEDate = Get-Date
  $now = ""
  $now = $now + " {0:0000}-{1:00}-{2:00} " -f $WEDate.Year, $WEDate.Month, $WEDate.Day
  $now = $now + " {0:00}:{1:00}:{2:00}" -f $WEDate.Hour, $WEDate.Minute, $WEDate.Second
  $nsSuffix = ""
  if ($ns) {
    if (" $($WEDate.TimeOfDay)" -match " \.\d\d\d\d\d\d") {
      $now = $now + $matches[0]
      $ms = $false
    } else {
      $ms = $true
      $nsSuffix = " 000"
    }
  } 
  if ($ms) {
    $now = $now + " .{0:000}$nsSuffix" -f $WEDate.MilliSecond
  }
  return $now
}



Function Log () {
  param(
    [Parameter(Mandatory=$false, ValueFromPipeline=$true, Position=0)]
    [String]$string
  )
  if (!(Test-Path $logDir)) {
    New-Item -ItemType directory -Path $logDir | Out-Null
  }
  if ($WEString.length) {
    $string = " $(Now) $pid $userName $string"
  }
  $string | Out-File -Encoding ASCII -Append " $logFile"
}



$WEPSThreadCount = 0              # Counter of PSThread IDs generated so far
$WEPSThreadList = @{}             # Existing PSThreads indexed by Id

Function Get-PSThread () {
  param(
    [Parameter(Mandatory=$false, ValueFromPipeline=$true, Position=0)]
    [int[]]$WEId = $WEPSThreadList.Keys     # List of thread IDs
  )
  $WEId | % { $WEPSThreadList.$_ }
}

Function Start-PSThread () {
  param(
    [Parameter(Mandatory=$true, Position=0)]
    [ScriptBlock]$WEScriptBlock,          # The script block to run in a new thread
    [Parameter(Mandatory=$false)]
    [String]$WEName = "" ,                 # Optional thread name. Default: "PSThread$WEId"
    [Parameter(Mandatory=$false)]
    [String]$WEEvent = "" ,                # Optional thread completion event name. Default: None
    [Parameter(Mandatory=$false)]
    [Hashtable]$WEVariables = @{},        # Optional variables to copy into the script context.
    [Parameter(Mandatory=$false)]
    [String[]]$WEFunctions = @(),         # Optional functions to copy into the script context.
    [Parameter(Mandatory=$false)]
    [Object[]]$WEArguments = @()          # Optional arguments to pass to the script.
  )

  $WEId = $script:PSThreadCount
  $script:PSThreadCount += 1
  if (!$WEName.Length) {
    $WEName = "PSThread$WEId"
  }
  $WEInitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
  foreach ($WEVarName in $WEVariables.Keys) { # Copy the specified variables into the script initial context
    $value = $WEVariables.$WEVarName
    Write-Debug " Adding variable $WEVarName=[$($WEValue.GetType())]$WEValue"
    $var = New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry($WEVarName, $value, "" )
    $WEInitialSessionState.Variables.Add($var)
  }
  foreach ($WEFuncName in $WEFunctions) { # Copy the specified functions into the script initial context
    $WEBody = Get-Content function:$WEFuncName
    Write-Debug "Adding function $WEFuncName () {$WEBody}"
    $func = New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry($WEFuncName, $WEBody)
    $WEInitialSessionState.Commands.Add($func)
  }
  $WERunSpace = [RunspaceFactory]::CreateRunspace($WEInitialSessionState)
  $WERunSpace.Open()
  $WEPSPipeline = [powershell]::Create()
  $WEPSPipeline.Runspace = $WERunSpace
  $WEPSPipeline.AddScript($WEScriptBlock) | Out-Null
  $WEArguments | % {
    Write-Debug " Adding argument [$($_.GetType())]'$_'"
    $WEPSPipeline.AddArgument($_) | Out-Null
  }
  $WEHandle = $WEPSPipeline.BeginInvoke() # Start executing the script
  if ($WEEvent.Length) { # Do this after BeginInvoke(), to avoid getting the start event.
    Register-ObjectEvent $WEPSPipeline -EventName InvocationStateChanged -SourceIdentifier $WEName -MessageData $WEEvent
  }
  $WEPSThread = New-Object PSObject -Property @{
    Id = $WEId
    Name = $WEName
    Event = $WEEvent
    RunSpace = $WERunSpace
    PSPipeline = $WEPSPipeline
    Handle = $WEHandle
  }     # Return the thread description variables
  $script:PSThreadList[$WEId] = $WEPSThread
  $WEPSThread
}



Function Receive-PSThread () {
  [CmdletBinding()]
$ErrorActionPreference = "Stop"
  param(
    [Parameter(Mandatory=$false, ValueFromPipeline=$true, Position=0)]
    [PSObject]$WEPSThread,                # Thread descriptor object
    [Parameter(Mandatory=$false)]
    [Switch]$WEAutoRemove                 # If $WETrue, remove the PSThread object
  )
  Process {
    if ($WEPSThread.Event -and $WEAutoRemove) {
      Unregister-Event -SourceIdentifier $WEPSThread.Name
      Get-Event -SourceIdentifier $WEPSThread.Name | Remove-Event # Flush remaining events
    }
    try {
      $WEPSThread.PSPipeline.EndInvoke($WEPSThread.Handle) # Output the thread pipeline output
    } catch {
      $_ # Output the thread pipeline error
    }
    if ($WEAutoRemove) {
      $WEPSThread.RunSpace.Close()
      $WEPSThread.PSPipeline.Dispose()
      $WEPSThreadList.Remove($WEPSThread.Id)
    }
  }
}

Function Remove-PSThread () {
  [CmdletBinding()]
$ErrorActionPreference = "Stop"
  param(
    [Parameter(Mandatory=$false, ValueFromPipeline=$true, Position=0)]
    [PSObject]$WEPSThread                 # Thread descriptor object
  )
  Process {
    $_ | Receive-PSThread -AutoRemove | Out-Null
  }
}



Function Send-PipeMessage () {
  param(
    [Parameter(Mandatory=$true)]
    [String]$WEPipeName,          # Named pipe name
    [Parameter(Mandatory=$true)]
    [String]$WEMessage            # Message string
  )
  $WEPipeDir  = [System.IO.Pipes.PipeDirection]::Out
  $WEPipeOpt  = [System.IO.Pipes.PipeOptions]::Asynchronous

  $pipe = $null # Named pipe stream
  $sw = $null   # Stream Writer
  try {
    $pipe = new-object System.IO.Pipes.NamedPipeClientStream(" .", $WEPipeName, $WEPipeDir, $WEPipeOpt)
    $sw = new-object System.IO.StreamWriter($pipe)
    $pipe.Connect(1000)
    if (!$pipe.IsConnected) {
      throw " Failed to connect client to pipe $pipeName"
    }
    $sw.AutoFlush = $true
    $sw.WriteLine($WEMessage)
  } catch {
    Log " Error sending pipe $pipeName message: $_"
  } finally {
    if ($sw) {
      $sw.Dispose() # Release resources
      $sw = $null   # Force the PowerShell garbage collector to delete the .net object
    }
    if ($pipe) {
      $pipe.Dispose() # Release resources
      $pipe = $null   # Force the PowerShell garbage collector to delete the .net object
    }
  }
}



Function Receive-PipeMessage () {
  param(
    [Parameter(Mandatory=$true)]
    [String]$WEPipeName           # Named pipe name
  )
  $WEPipeDir  = [System.IO.Pipes.PipeDirection]::In
  $WEPipeOpt  = [System.IO.Pipes.PipeOptions]::Asynchronous
  $WEPipeMode = [System.IO.Pipes.PipeTransmissionMode]::Message

  try {
    $pipe = $null       # Named pipe stream
    $pipe = New-Object system.IO.Pipes.NamedPipeServerStream($WEPipeName, $WEPipeDir, 1, $WEPipeMode, $WEPipeOpt)
    $sr = $null         # Stream Reader
    $sr = new-object System.IO.StreamReader($pipe)
    $pipe.WaitForConnection()
    $WEMessage = $sr.Readline()
    $WEMessage
  } catch {
    Log " Error receiving pipe message: $_"
  } finally {
    if ($sr) {
      $sr.Dispose() # Release resources
      $sr = $null   # Force the PowerShell garbage collector to delete the .net object
    }
    if ($pipe) {
      $pipe.Dispose() # Release resources
      $pipe = $null   # Force the PowerShell garbage collector to delete the .net object
    }
  }
}



$pipeThreadName = " Control Pipe Handler"

Function Start-PipeHandlerThread () {
  param(
    [Parameter(Mandatory=$true)]
    [String]$pipeName,                  # Named pipe name
    [Parameter(Mandatory=$false)]
    [String]$WEEvent = " ControlMessage"   # Event message
  )
  Start-PSThread -Variables @{  # Copy variables required by function WE-Log() into the thread context
    logDir = $logDir
    logFile = $logFile
    userName = $userName
  } -Functions Now, Log, Receive-PipeMessage -ScriptBlock {
    Param($pipeName, $pipeThreadName)
    try {
      Receive-PipeMessage " $pipeName" # Blocks the thread until the next message is received from the pipe
    } catch {
      Log " $pipeThreadName # Error: $_"
      throw $_ # Push the error back to the main thread
    }
  } -Name $pipeThreadName -Event $WEEvent -Arguments $pipeName, $pipeThreadName
}



Function Receive-PipeHandlerThread () {
  param(
    [Parameter(Mandatory=$true)]
    [PSObject]$pipeThread               # Thread descriptor
  )
  Receive-PSThread -PSThread $pipeThread -AutoRemove
}


; 
$scriptCopyCname = $scriptCopy -replace " \\", " \\" # Double backslashes. (The first \\ is a regexp with \ escaped; The second is a plain string.)
$source = @"
  using System;
  using System.ServiceProcess;
  using System.Diagnostics;
  using System.Runtime.InteropServices;                                 // SET STATUS
  using System.ComponentModel;                                          // SET STATUS

  public enum ServiceType : int {                                       // SET STATUS [
    SERVICE_WIN32_OWN_PROCESS = 0x00000010,
    SERVICE_WIN32_SHARE_PROCESS = 0x00000020,
  };                                                                    // SET STATUS ]

  public enum ServiceState : int {                                      // SET STATUS [
    SERVICE_STOPPED = 0x00000001,
    SERVICE_START_PENDING = 0x00000002,
    SERVICE_STOP_PENDING = 0x00000003,
    SERVICE_RUNNING = 0x00000004,
    SERVICE_CONTINUE_PENDING = 0x00000005,
    SERVICE_PAUSE_PENDING = 0x00000006,
    SERVICE_PAUSED = 0x00000007,
  };                                                                    // SET STATUS ]

  [StructLayout(LayoutKind.Sequential)]                                 // SET STATUS [
  public struct ServiceStatus {
    public ServiceType dwServiceType;
    public ServiceState dwCurrentState;
    public int dwControlsAccepted;
    public int dwWin32ExitCode;
    public int dwServiceSpecificExitCode;
    public int dwCheckPoint;
    public int dwWaitHint;
  };                                                                    // SET STATUS ]

  public enum Win32Error : int { // WIN32 errors that we may need to use
    NO_ERROR = 0,
    ERROR_APP_INIT_FAILURE = 575,
    ERROR_FATAL_APP_EXIT = 713,
    ERROR_SERVICE_NOT_ACTIVE = 1062,
    ERROR_EXCEPTION_IN_SERVICE = 1064,
    ERROR_SERVICE_SPECIFIC_ERROR = 1066,
    ERROR_PROCESS_ABORTED = 1067,
  };

  public class Service_$serviceName : ServiceBase { // $serviceName may begin with a digit; The class name must begin with a letter
    private System.Diagnostics.EventLog eventLog;                       // EVENT LOG
    private ServiceStatus serviceStatus;                                // SET STATUS

    public Service_$serviceName() {
      ServiceName = " $serviceName";
      CanStop = true;
      CanPauseAndContinue = false;
      AutoLog = true;

      eventLog = new System.Diagnostics.EventLog();                     // EVENT LOG [
      if (!System.Diagnostics.EventLog.SourceExists(ServiceName)) {         
        System.Diagnostics.EventLog.CreateEventSource(ServiceName, " $logName");
      }
      eventLog.Source = ServiceName;
      eventLog.Log = " $logName";                                        // EVENT LOG ]
      EventLog.WriteEntry(ServiceName, " $exeName $serviceName()");      // EVENT LOG
    }

    [DllImport(" advapi32.dll", SetLastError=true)]                      // SET STATUS
    private static extern bool SetServiceStatus(IntPtr handle, ref ServiceStatus serviceStatus);

    protected override void OnStart(string [] args) {
      EventLog.WriteEntry(ServiceName, " $exeName OnStart() // Entry. Starting script '$scriptCopyCname' -Start"); // EVENT LOG
      // Set the service state to Start Pending.                        // SET STATUS [
      // Only useful if the startup time is long. Not really necessary here for a 2s startup time.
      serviceStatus.dwServiceType = ServiceType.SERVICE_WIN32_OWN_PROCESS;
      serviceStatus.dwCurrentState = ServiceState.SERVICE_START_PENDING;
      serviceStatus.dwWin32ExitCode = 0;
      serviceStatus.dwWaitHint = 2000; // It takes about 2 seconds to start PowerShell
      SetServiceStatus(ServiceHandle, ref serviceStatus);               // SET STATUS ]
      // Start a child process with another copy of this script
      try {
        Process p = new Process();
        // Redirect the output stream of the child process.
        p.StartInfo.UseShellExecute = false;
        p.StartInfo.RedirectStandardOutput = true;
        p.StartInfo.FileName = " PowerShell.exe";
        p.StartInfo.Arguments = " -c & '$scriptCopyCname' -Start"; // Works if path has spaces, but not if it contains ' quotes.
        p.Start();
        // Read the output stream first and then wait. (To avoid deadlocks says Microsoft!)
        string output = p.StandardOutput.ReadToEnd();
        // Wait for the completion of the script startup code, that launches the -Service instance
        p.WaitForExit();
        if (p.ExitCode != 0) throw new Win32Exception((int)(Win32Error.ERROR_APP_INIT_FAILURE));
        // Success. Set the service state to Running.                   // SET STATUS
        serviceStatus.dwCurrentState = ServiceState.SERVICE_RUNNING;    // SET STATUS
      } catch (Exception e) {
        EventLog.WriteEntry(ServiceName, " $exeName OnStart() // Failed to start $scriptCopyCname. " + e.Message, EventLogEntryType.Error); // EVENT LOG
        // Change the service state back to Stopped.                    // SET STATUS [
        serviceStatus.dwCurrentState = ServiceState.SERVICE_STOPPED;
        Win32Exception w32ex = e as Win32Exception; // Try getting the WIN32 error code
        if (w32ex == null) { // Not a Win32 exception, but maybe the inner one is...
          w32ex = e.InnerException as Win32Exception;
        }    
        if (w32ex != null) {    // Report the actual WIN32 error
          serviceStatus.dwWin32ExitCode = w32ex.NativeErrorCode;
        } else {                // Make up a reasonable reason
          serviceStatus.dwWin32ExitCode = (int)(Win32Error.ERROR_APP_INIT_FAILURE);
        }                                                               // SET STATUS ]
      } finally {
        serviceStatus.dwWaitHint = 0;                                   // SET STATUS
        SetServiceStatus(ServiceHandle, ref serviceStatus);             // SET STATUS
        EventLog.WriteEntry(ServiceName, " $exeName OnStart() // Exit"); // EVENT LOG
      }
    }

    protected override void OnStop() {
      EventLog.WriteEntry(ServiceName, " $exeName OnStop() // Entry");   // EVENT LOG
      // Start a child process with another copy of ourselves
      Process p = new Process();
      // Redirect the output stream of the child process.
      p.StartInfo.UseShellExecute = false;
      p.StartInfo.RedirectStandardOutput = true;
      p.StartInfo.FileName = " PowerShell.exe";
      p.StartInfo.Arguments = " -c & '$scriptCopyCname' -Stop"; // Works if path has spaces, but not if it contains ' quotes.
      p.Start();
      // Read the output stream first and then wait.
      string output = p.StandardOutput.ReadToEnd();
      // Wait for the PowerShell script to be fully stopped.
      p.WaitForExit();
      // Change the service state back to Stopped.                      // SET STATUS
      serviceStatus.dwCurrentState = ServiceState.SERVICE_STOPPED;      // SET STATUS
      SetServiceStatus(ServiceHandle, ref serviceStatus);               // SET STATUS
      EventLog.WriteEntry(ServiceName, " $exeName OnStop() // Exit");    // EVENT LOG
    }

    public static void Main() {
      System.ServiceProcess.ServiceBase.Run(new Service_$serviceName());
    }
  }
" @




$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$userName = $identity.Name      # Ex: "NT AUTHORITY\SYSTEM" or " Domain\Administrator"
$authority,$name = $username -split " \\"
$isSystem = $identity.IsSystem	# Do not test ($userName -eq " NT AUTHORITY\SYSTEM"), as this fails in non-English systems.


if ($WESetup) {Log "" }    # Insert one blank line to separate test sessions logs
Log $WEMyInvocation.Line # The exact command line that was used to start us


New-EventLog -LogName $logName -Source $serviceName -ea SilentlyContinue


$WEStatus = ($WEPSCmdlet.ParameterSetName -eq 'Status')

if ($WEStart) {                   # Start the service
  if ($isSystem) { # If running as SYSTEM, ie. invoked as a service
    # Do whatever is necessary to start the service script instance
    Log "$scriptName -Start: Starting script '$scriptFullName' -Service"
    Write-EventLog -LogName $logName -Source $serviceName -EventId 1001 -EntryType Information -Message " $scriptName -Start: Starting script '$scriptFullName' -Service"
    Start-Process PowerShell.exe -ArgumentList (" -c & '$scriptFullName' -Service")
  } else {
    Write-Verbose " Starting service $serviceName"
    Write-EventLog -LogName $logName -Source $serviceName -EventId 1002 -EntryType Information -Message " $scriptName -Start: Starting service $serviceName"
    Start-Service $serviceName # Ask Service Control Manager to start it
  }
  return
}

if ($WEStop) {                    # Stop the service
  if ($isSystem) { # If running as SYSTEM, ie. invoked as a service
    # Do whatever is necessary to stop the service script instance
    Write-EventLog -LogName $logName -Source $serviceName -EventId 1003 -EntryType Information -Message " $scriptName -Stop: Stopping script $scriptName -Service"
    Log " $scriptName -Stop: Stopping script $scriptName -Service"
    # Send an exit message to the service instance
    Send-PipeMessage $pipeName " exit" 
  } else {
    Write-Verbose " Stopping service $serviceName"
    Write-EventLog -LogName $logName -Source $serviceName -EventId 1004 -EntryType Information -Message " $scriptName -Stop: Stopping service $serviceName"
    Stop-Service $serviceName # Ask Service Control Manager to stop it
  }
  return
}

if ($WERestart) {                 # Restart the service
  & $scriptFullName -Stop
  & $scriptFullName -Start
  return
}

if ($WEStatus) {                  # Get the current service status
  $spid = $null
  $processes = @(Get-CimInstance Win32_Process -filter " Name = 'powershell.exe'" | Where-Object {
    $_.CommandLine -match " .*$scriptCopyCname.*-Service"
  })
  foreach ($process in $processes) { # There should be just one, but be prepared for surprises.
    $spid = $process.ProcessId
    Write-Verbose " $serviceName Process ID = $spid"
  }
  # if (Test-Path " HKLM:\SYSTEM\CurrentControlSet\services\$serviceName") {}
  try {
    $pss = Get-Service $serviceName -ea stop # Will error-out if not installed
  } catch {
    " Not Installed"
    return
  }
  $pss.Status
  if (($pss.Status -eq " Running") -and (!$spid)) { # This happened during the debugging phase
    Write-Error " The Service Control Manager thinks $serviceName is started, but $serviceName.ps1 -Service is not running."
    exit 1
  }
  return
}

if ($WESetup) {                   # Install the service
  # Check if it's necessary
  try {
    $pss = Get-Service $serviceName -ea stop # Will error-out if not installed
    # Check if this script is newer than the installed copy.
    if ((Get-Item $scriptCopy -ea SilentlyContinue).LastWriteTime -lt (Get-Item $scriptFullName -ea SilentlyContinue).LastWriteTime) {
      Write-Verbose " Service $serviceName is already Installed, but requires upgrade"
      & $scriptFullName -Remove
      throw " continue"
    } else {
      Write-Verbose " Service $serviceName is already Installed, and up-to-date"
    }
    exit 0
  } catch {
    # This is the normal case here. Do not throw or write any error!
    Write-Debug " Installation is necessary" # Also avoids a ScriptAnalyzer warning
    # And continue with the installation.
  }
  if (!(Test-Path $installDir)) {
    New-Item -ItemType directory -Path $installDir | Out-Null
  }
  # Copy the service script into the installation directory
  if ($WEScriptFullName -ne $scriptCopy) {
    Write-Verbose " Installing $scriptCopy"
    Copy-Item $WEScriptFullName $scriptCopy

    # Create and Save Key
    $WEKey = New-Object Byte[] 32   # You can use 16, 24, or 32 for AES
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($WEKey)
    $WEKey | out-file $WEKeyFileFullName

    # Create and Save file with encrypted Workspace Key
    $WEWSKey = $WEOMSWorkspaceCreds.GetNetworkCredential().password | ConvertTo-SecureString -AsPlainText -Force
    $WEWSKey | ConvertFrom-SecureString -key $WEKey | Out-File $credFileFullName

    # Create File with Workspace ID
    $WEOMSWorkspaceCreds.UserName | Out-File $workspaceIdFileFullName
  }
  # Generate the service .EXE from the C# source embedded in this script
  try {
    Write-Verbose " Compiling $exeFullName"
    Add-Type -TypeDefinition $source -Language CSharp -OutputAssembly $exeFullName -OutputType ConsoleApplication -ReferencedAssemblies " System.ServiceProcess" -Debug:$false
  } catch {
    $msg = $_.Exception.Message
    Write-error " Failed to create the $exeFullName service stub. $msg"
    exit 1
  }
  # Register the service
  Write-Verbose " Registering service $serviceName"
  $pss = New-Service $serviceName $exeFullName -DisplayName $serviceDisplayName -Description $WEServiceDescription -StartupType Automatic

  return
}

if ($WERemove) {                  # Uninstall the service
  # Check if it's necessary
  try {
    $pss = Get-Service $serviceName -ea stop # Will error-out if not installed
  } catch {
    Write-Verbose " Already uninstalled"
    return
  }
  Stop-Service $serviceName # Make sure it's stopped
  # In the absence of a Remove-Service applet, use sc.exe instead.
  Write-Verbose " Removing service $serviceName"
  $msg = sc.exe delete $serviceName
  if ($WELastExitCode) {
    Write-Error " Failed to remove the service ${serviceName}: $msg"
    exit 1
  } else {
    Write-Verbose $msg
  }
  # Remove the installed files
  if (Test-Path $installDir) {
    foreach ($ext in (" exe", " pdb", " ps1", " cred", " id", " key")) {
      $file = " $installDir\$serviceName.$ext"
      if (Test-Path $file) {
        Write-Verbose " Deleting file $file"
        Remove-Item $file -Force
      }
    }
    if (!(@(Get-ChildItem $installDir -ea SilentlyContinue)).Count) {
      Write-Verbose " Removing directory $installDir"
      Remove-Item $installDir -Force
    }
  }
  return
}

if ($WEControl) {                 # Send a control message to the service
  Send-PipeMessage $pipeName $control
}

if ($WEService) {                 # Run the service
  Write-EventLog -LogName $logName -Source $serviceName -EventId 1005 -EntryType Information -Message " $scriptName -Service # Beginning background job"
  # Do the service background job
  try {
    # Start the control pipe handler thread
    $pipeThread = Start-PipeHandlerThread $pipeName -Event " ControlMessage"
    ######### TO DO: Implement your own service code here. ##########
    ###### Example that wakes up and logs a line every 10 sec: ######
    # Start a periodic timer
    $timerName = " Sample service timer"
    $period = 60 # seconds
    $timer = new-object System.Timers.Timer
    $timer.Interval = ($period * 1000) # Milliseconds
    $timer.AutoReset = $true # Make it fire repeatedly
    Register-ObjectEvent $timer -EventName Elapsed -SourceIdentifier $timerName -MessageData " TimerTick"
    $timer.start() # Must be stopped in the finally block
    # Now enter the main service event loop
    do { # Keep running until told to exit by the -Stop handler
      $event = Wait-Event # Wait for the next incoming event
      $source = $event.SourceIdentifier
      $message = $event.MessageData
      $eventTime = $event.TimeGenerated.TimeofDay
      Write-Debug " Event at $eventTime from ${source}: $message"
      $event | Remove-Event # Flush the event from the queue
      switch ($message) {
        " ControlMessage" { # Required. Message received by the control pipe thread
          $state = $event.SourceEventArgs.InvocationStateInfo.state
          Write-Debug " $script -Service # Thread $source state changed to $state"
          switch ($state) {
            " Completed" {
              $message = Receive-PipeHandlerThread $pipeThread
              Log " $scriptName -Service # Received control message: $WEMessage"
              if ($message -ne " exit") { # Start another thread waiting for control messages
                $pipeThread = Start-PipeHandlerThread $pipeName -Event " ControlMessage"
              }
            }
            " Failed" {
              $error = Receive-PipeHandlerThread $pipeThread
              Log " $scriptName -Service # $source thread failed: $error"
              Start-Sleep 1 # Avoid getting too many errors
              $pipeThread = Start-PipeHandlerThread $pipeName -Event " ControlMessage" # Retry
            }
          }
        }
        " TimerTick" { # Example. Periodic event generated for this example
          # Check if this node is Cluster Name owner
          $ownerNode = Get-ClusterResource -Name " Cluster Name" | select -ExpandProperty OwnerNode

          If ($ownerNode -eq $env:computername)
          {
            #region Initalization
            # Get the Key
            Try
            {
                $key = Get-Content $WEKeyFileFullName
            }
            Catch
            {
                Write-Error -Message " Failed to get conent from $($WEKeyFileFullName)."
            }
            

            # Get Workspace ID
            Try
            {
                $WEOMSWorkspaceIDFromFile = Get-Content $workspaceIdFileFullName
            }
            Catch
            {
                Write-Error -Message " Failed to get conent from $($workspaceIdFileFullName)."
            }
            

            # Get Workspace Key
            Try
            {
                $WEOMSWorkspaceKeyFromFile  = Get-Content $credFileFullName | ConvertTo-SecureString -Key $key
            }
            Catch
            {
                Write-Error -Message " Failed to get conent from $($credFileFullName)."
            }
            

            # Construct Workspace ID and Key into credentials
            $WEOMSCredsFromFiles = New-Object -TypeName System.Management.Automation.PSCredential `
                                   -ArgumentList $WEOMSWorkspaceIDFromFile , $WEOMSWorkspaceKeyFromFile 
            
            # Log Name
            $logType = " S2D"

            # Time Generated Fields
            $WETimestampfield = " Timestamp"


            # Get Server and Cluster names
            $domainfqdn = (Get-CimInstance Win32_ComputerSystem | Select-Object -ExpandProperty domain)
            $WEServerName = ($env:computername + " ." + $domainfqdn).ToUpper()
            Try
            {
                $WEClusterName = ((gwmi -class " MSCluster_Cluster" -namespace " root\mscluster" | select -ExpandProperty Name) + " ." + $domainfqdn).ToUpper()
            }
            Catch
            {
                Write-Error -Message " Failed to get cluster name from WMI root\mscluster."
            }
            
            #endregion
            
            if($WEClusterName)
            {
                #region Get and Send S2D cluster Data to OMS
                $s2dreport = Get-StorageSubSystem Cluster*  | Get-StorageHealthReport
                if($s2dreport)
                {
                    $WENowTime = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
                    $table  = @()
                    foreach ($s2drecord in $s2dreport.itemValue.records)
                    {
                      
                      if ($s2drecord.Units -eq 0)
                      {
                          $WEUnitType = " Bytes"
                      }
                      if ($s2drecord.Units -eq 1)
                      {
                          $WEUnitType = " BytesPerSecond"
                      }
                      if ($s2drecord.Units -eq 2)
                      {
                          $WEUnitType = " CountPerSecond"
                      }
                      if ($s2drecord.Units -eq 3)
                      {
                          $WEUnitType = " Seconds"
                      }
                      if ($s2drecord.Units -eq 4)
                      {
                          $WEUnitType = " Percentage"
                      }
                      
                     ;  $sx = New-Object PSObject -Property @{
                        
                        Timestamp = $WENowTime
                        MetricLevel = " Cluster";
                        MetricName = $s2drecord.Name;
                        MetricValue = $s2drecord.Value;
                        UnitType = $WEUnitType;
                        ClusterName = $WEClusterName
                      } 
                      $table = $table + $sx 
                    }
                    
                    if($table)
                    {
                        # Convert to JSON
                        $jsonTable = $table | ConvertTo-Json -Depth 5

                        #Send to OMS
                        Send-OMSAPIIngestionFile -customerId $WEOMSCredsFromFiles.UserName `
                                                 -sharedKey $WEOMSCredsFromFiles.GetNetworkCredential().password `
                                                 -body $jsonTable `
                                                 -logType $logType `
                                                 -TimeStampField $WETimestampfield

                    }
                }
                
                #endregion  

                #region Get and Send S2D Node Data to OMS
                $WENowTime = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
                $s2dNodes = Get-StorageNode
                if($s2dNodes)
                {
                    $nodescount = $s2dNodes.GetEnumerator() | Group-Object Name | ? { $_.Count -gt 1 }
                    if($nodescount)
                    {
                        $s2dNodes = $s2dNodes | select -Skip 1
                    }
                    $table  = @()
                    foreach ($s2dNode in $s2dNodes)
                    {
                        
                        $s2dreport = $s2dNode | Get-StorageHealthReport -Count 1
                        If($s2dreport)
                        {
                            foreach ($s2drecord in $s2dreport.itemValue.records)
                            {
                              if ($s2drecord.Units -eq 0)
                              {
                                  $WEUnitType = " Bytes"
                              }
                              if ($s2drecord.Units -eq 1)
                              {
                                  $WEUnitType = " BytesPerSecond"
                              }
                              if ($s2drecord.Units -eq 2)
                              {
                                  $WEUnitType = " CountPerSecond"
                              }
                              if ($s2drecord.Units -eq 3)
                              {
                                  $WEUnitType = " Seconds"
                              }
                              if ($s2drecord.Units -eq 4)
                              {
                                  $WEUnitType = " Percentage"
                              }

                             ;  $sx = New-Object PSObject -Property @{
                                
                                Timestamp = $WENowTime
                                MetricLevel = " Node";
                                MetricName = $s2drecord.Name;
                                MetricValue = $s2drecord.Value;
                                UnitType = $WEUnitType;
                                ServerName = $s2dNode.Name.ToUpper();
                                ClusterName = $WEClusterName
                              } 
                              $table = $table + $sx 
                            }
                        }
                                   
                    }

                    if($table)
                    {
                        # Convert to JSON
                        $jsonTable = $table | ConvertTo-Json -Depth 5

                        #Send to OMS
                        Send-OMSAPIIngestionFile -customerId $WEOMSCredsFromFiles.UserName `
                                                 -sharedKey $WEOMSCredsFromFiles.GetNetworkCredential().password `
                                                 -body $jsonTable `
                                                 -logType $logType `
                                                 -TimeStampField $WETimestampfield

                    }
                }
                #endregion
                      
                #region Get and Send S2D Volume Data to OMS
                $volumes = Get-Volume | where {$_.FileSystem -eq " CSVFS" }
                $table  = @()
                $WENowTime = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
                if($volumes)
                {
                    foreach ($volume in $volumes)
                    {
                      $WEVolumeLabel = $volume.FileSystemLabel
                      $WEFileSystemType = $volume.FileSystemType
                      $WEOperationalStatus = $volume.OperationalStatus
                      $WEHealthStatus = $volume.HealthStatus

                      $s2dreport = Get-Volume -FileSystemLabel $WEVolumeLabel | Get-StorageHealthReport -Count 1
                      if($s2dreport)
                      {
                        foreach ($s2drecord in $s2dreport.itemValue.records)
                        {
                            if ($s2drecord.Units -eq 0)
                            {
                                $WEUnitType = " Bytes"
                            }
                            if ($s2drecord.Units -eq 1)
                            {
                                $WEUnitType = " BytesPerSecond"
                            }
                            if ($s2drecord.Units -eq 2)
                            {
                                $WEUnitType = " CountPerSecond"
                            }
                            if ($s2drecord.Units -eq 3)
                            {
                                $WEUnitType = " Seconds"
                            }
                            if ($s2drecord.Units -eq 4)
                            {
                                $WEUnitType = " Percentage"
                            }

                           ;  $sx = New-Object PSObject -Property @{
                          
                             Timestamp = $WENowTime
                             MetricLevel = " Volume";
                             VolumeLabel = $WEVolumeLabel;
                             FileSystemType = $WEFileSystemType;
                             OperationalStatus = $WEOperationalStatus;
                             HealthStatus = $WEHealthStatus;
                             MetricName = $s2drecord.Name;
                             MetricValue = $s2drecord.Value;
                             UnitType = $WEUnitType;
                             ClusterName = $WEClusterName
                            } 
                        $table = $table + $sx 
                        }
                      }
                      
                    
                    }

                    if($table)
                    {
                        # Convert to JSON
                        $jsonTable = $table | ConvertTo-Json -Depth 5

                        #Send to OMS
                        Send-OMSAPIIngestionFile -customerId $WEOMSCredsFromFiles.UserName `
                                                 -sharedKey $WEOMSCredsFromFiles.GetNetworkCredential().password `
                                                 -body $jsonTable `
                                                 -logType $logType `
                                                 -TimeStampField $WETimestampfield

                    }
                }
                
                #endregion

                #region Get and Send S2D Cluster Faults to OMS
                $s2dFaults = Get-StorageSubSystem Cluster* | Debug-StorageSubSystem
                $table  = @()
                $WENowTime = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
                
                If ($s2dFaults)
                {
                    foreach ($s2dFault in $s2dFaults)
                    {
                        if ($s2dFault.PerceivedSeverity -eq " Unknown" )
                        {
                            $WESeverityNumber = 0
                        }
                        if ($s2dFault.PerceivedSeverity -eq " Information")
                        {
                            $WESeverityNumber = 2
                        }
                        if ($s2dFault.PerceivedSeverity -eq " Degraded/Warning")
                        {
                            $WESeverityNumber = 3
                        }
                        if ($s2dFault.PerceivedSeverity -eq " Minor")
                        {
                            $WESeverityNumber = 4
                        }
                        if ($s2dFault.PerceivedSeverity -eq " Major")
                        {
                            $WESeverityNumber = 5
                        }
                        if ($s2dFault.PerceivedSeverity -eq " Critical")
                        {
                            $WESeverityNumber = 6
                        }
                        if ($s2dFault.PerceivedSeverity -eq " Fatal/NonRecoverable")
                        {
                            $WESeverityNumber = 7
                        }

                        $action=""
                        foreach ($recommendedAction in $s2dFault.RecommendedActions)
                        {
                            $action = $action + $recommendedAction
                            $action = $action + " | "
                        }

                       ;  $sx = New-Object PSObject -Property @{
                        
                            Timestamp = $WENowTime;
                            SecondTimeStamp = $WENowTime;
                            Severity = $s2dFault.PerceivedSeverity;
                            SeverityNumber = $WESeverityNumber;
                            FaultLevel = " Cluster";
                            FaultId = $s2dFault.FaultId;
                            FaultingObjectDescription = $s2dFault.FaultingObjectDescription;
                            FaultingObjectLocation = $s2dFault.FaultingObjectLocation;
                            FaultingObjectType = $s2dFault.FaultingObjectType;
                            FaultingObjectUniqueId = $s2dFault.FaultingObjectUniqueId;
                            FaultType = $s2dFault.FaultType;
                            Reason = $s2dFault.Reason;
                            RecommendedActions = $action;
                            ClusterName = $WEClusterName
                      } 
                      $table = $table + $sx 
                    
                    }
                }

                if($table)
                {
                    # Convert to JSON
                    $jsonTable = $table | ConvertTo-Json -Depth 5

                    #Send to OMS
                    Send-OMSAPIIngestionFile -customerId $WEOMSCredsFromFiles.UserName `
                                             -sharedKey $WEOMSCredsFromFiles.GetNetworkCredential().password `
                                             -body $jsonTable `
                                             -logType $logType `
                                             -TimeStampField $WETimestampfield

                }
                #endregion

                #region Get and Send S2D Volume Faults to OMS
                $volumes = Get-Volume | where {$_.FileSystem -eq " CSVFS" }
                $table  = @()
                $WENowTime = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
                if ($volumes)
                {
                    foreach ($volume in $volumes)
                    {
                        $WEVolumeLabel = $volume.FileSystemLabel
                        $WEFileSystemType = $volume.FileSystemType

                        $s2dFaults = Get-Volume -FileSystemLabel $WEVolumeLabel | Debug-Volume
                        if($s2dFaults)
                        {
                            foreach ($s2dFault in $s2dFaults)
                            {
                                if ($s2dFault.PerceivedSeverity -eq " Unknown" )
                                {
                                    $WESeverityNumber = 0
                                }
                                if ($s2dFault.PerceivedSeverity -eq " Information")
                                {
                                    $WESeverityNumber = 2
                                }
                                if ($s2dFault.PerceivedSeverity -eq " Degraded/Warning")
                                {
                                    $WESeverityNumber = 3
                                }
                                if ($s2dFault.PerceivedSeverity -eq " Minor")
                                {
                                    $WESeverityNumber = 4
                                }
                                if ($s2dFault.PerceivedSeverity -eq " Major")
                                {
                                    $WESeverityNumber = 5
                                }
                                if ($s2dFault.PerceivedSeverity -eq " Critical")
                                {
                                    $WESeverityNumber = 6
                                }
                                if ($s2dFault.PerceivedSeverity -eq " Fatal/NonRecoverable")
                                {
                                    $WESeverityNumber = 7
                                }

                                $action=""
                                foreach ($recommendedAction in $s2dFault.RecommendedActions)
                                {
                                    $action = $action + $recommendedAction
                                    $action = $action + " | "
                                }
                                
                               ;  $sx = New-Object PSObject -Property @{
                            
                                    Timestamp = $WENowTime;
                                    SecondTimeStamp = $WENowTime;
                                    Severity = $s2dFault.PerceivedSeverity;
                                    SeverityNumber = $WESeverityNumber;
                                    FaultId = $s2dFault.FaultId;
                                    FaultLevel = " Volume";
                                    VolumeLabel = $WEVolumeLabel;
                                    FaultingObjectDescription = $s2dFault.FaultingObjectDescription;
                                    FaultingObjectLocation = $s2dFault.FaultingObjectLocation;
                                    FaultingObjectType = $s2dFault.FaultingObjectType;
                                    FaultingObjectUniqueId = $s2dFault.FaultingObjectUniqueId;
                                    FaultType = $s2dFault.FaultType;
                                    Reason = $s2dFault.Reason;
                                    RecommendedActions = $action;
                                    ClusterName = $WEClusterName
                                } 
                                $table = $table + $sx 
                            }
                        }
                        
                    }

                    if($table)
                    {
                        # Convert to JSON
                        $jsonTable = $table | ConvertTo-Json -Depth 5

                        #Send to OMS
                        Send-OMSAPIIngestionFile -customerId $WEOMSCredsFromFiles.UserName `
                                                 -sharedKey $WEOMSCredsFromFiles.GetNetworkCredential().password `
                                                 -body $jsonTable `
                                                 -logType $logType `
                                                 -TimeStampField $WETimestampfield
                    }
                    
                }
                #endregion

                #region Get and Send S2D Share Faults to OMS
                $shares = Get-FileShare | where {$_.ContinuouslyAvailable -eq $true}
                $table  = @()
                $WENowTime = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
                if($shares)
                {
                    foreach ($share in $shares)
                    {
                        $shareName = $share.Name

                        $s2dFaults = Get-FileShare -Name $share.Name | Debug-FileShare
                        if($s2dFaults)
                        {
                            foreach ($s2dFault in $s2dFaults)
                            {
                                if ($s2dFault.PerceivedSeverity -eq " Unknown" )
                                {
                                    $WESeverityNumber = 0
                                }
                                if ($s2dFault.PerceivedSeverity -eq " Information")
                                {
                                    $WESeverityNumber = 2
                                }
                                if ($s2dFault.PerceivedSeverity -eq " Degraded/Warning")
                                {
                                    $WESeverityNumber = 3
                                }
                                if ($s2dFault.PerceivedSeverity -eq " Minor")
                                {
                                    $WESeverityNumber = 4
                                }
                                if ($s2dFault.PerceivedSeverity -eq " Major")
                                {
                                    $WESeverityNumber = 5
                                }
                                if ($s2dFault.PerceivedSeverity -eq " Critical")
                                {
                                    $WESeverityNumber = 6
                                }
                                if ($s2dFault.PerceivedSeverity -eq " Fatal/NonRecoverable")
                                {
                                    $WESeverityNumber = 7
                                }

                                $action=""
                                foreach ($recommendedAction in $s2dFault.RecommendedActions)
                                {
                                    $action = $action + $recommendedAction
                                    $action = $action + " | "
                                }
                                
                               ;  $sx = New-Object PSObject -Property @{
                            
                                    Timestamp = $WENowTime;
                                    SecondTimeStamp = $WENowTime;
                                    Severity = $s2dFault.PerceivedSeverity;
                                    SeverityNumber = $WESeverityNumber;
                                    FaultId = $s2dFault.FaultId;
                                    FaultLevel = " Share";
                                    ShareName = $shareName;
                                    FaultingObjectDescription = $s2dFault.FaultingObjectDescription;
                                    FaultingObjectLocation = $s2dFault.FaultingObjectLocation;
                                    FaultingObjectType = $s2dFault.FaultingObjectType;
                                    FaultingObjectUniqueId = $s2dFault.FaultingObjectUniqueId;
                                    FaultType = $s2dFault.FaultType;
                                    Reason = $s2dFault.Reason;
                                    RecommendedActions = $action;
                                    ClusterName = $WEClusterName
                                } 
                                $table = $table + $sx 
                            }
                        }
                        
                    }

                    if($table)
                    {
                        # Convert to JSON
                        $jsonTable = $table | ConvertTo-Json -Depth 5

                        #Send to OMS
                        Send-OMSAPIIngestionFile -customerId $WEOMSCredsFromFiles.UserName `
                                                 -sharedKey $WEOMSCredsFromFiles.GetNetworkCredential().password `
                                                 -body $jsonTable `
                                                 -logType $logType `
                                                 -TimeStampField $WETimestampfield

                    }
                    
                }
                #endregion
            }
            
          }
           
        }
        default { # Should not happen
          Log " $scriptName -Service # Unexpected event from ${source}: $WEMessage"
        }
      }
    } while ($message -ne " exit")
  } catch { # An exception occurred while runnning the service
    $msg = $_.Exception.Message
    $line = $_.InvocationInfo.ScriptLineNumber
    Log " $scriptName -Service # Error at line ${line}: $msg"
  } finally { # Invoked in all cases: Exception or normally by -Stop
    # Cleanup the periodic timer used in the above example
    Unregister-Event -SourceIdentifier $timerName
    $timer.stop()
    ############### End of the service code example. ################
    # Terminate the control pipe handler thread
    Get-PSThread | Remove-PSThread # Remove all remaining threads
    # Flush all leftover events (There may be some that arrived after we exited the while event loop, but before we unregistered the events)
   ;  $events = Get-Event | Remove-Event
    # Log a termination event, no matter what the cause is.
    Write-EventLog -LogName $logName -Source $serviceName -EventId 1006 -EntryType Information -Message " $script -Service # Exiting"
    Log " $scriptName -Service # Exiting"
  }
  return
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================