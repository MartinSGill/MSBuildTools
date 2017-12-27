Set-StrictMode -Version 5

<#
    .SYNOPSIS
    Wrapper for MSBuild

    .DESCRIPTION
    Wrapper for MSBuild

    .PARAMETER PathToMSBuild
    Manually specify path to MSBuild, instead of 
    having the script determine which version to use.
    Example:
    -PathToMSBuild c:\custommsbuild\bin\msbuild.exe

    .PARAMETER Path
    Path to project file to build.

    .PARAMETER Target
    Build these targets in this project.
    Can build multiple, example:
    -Target @(Target1, Target2)

    .PARAMETER Property
    Set or override these project-level properties.
    Use a map to specify properties to override/define.
    Example:
    -Property @{ WarningLevel = 2, OutDir = "bin\Debug\" }

    .PARAMETER MaxCpuCountPhysicalCpus
    MSBuild will use up to the number of processors on the 
    computer. This is equivalent to calling msbuild 
    /maxcpucount without a value.

    .PARAMETER MaxCpuCount
    Specifies the maximum number of concurrent processes to 
    build with.

    .PARAMETER ToolsVersion
    The version of the MSBuild Toolset (tasks, targets, etc.)
    to use during build. This version will override the 
    versions specified by individual projects. 
    Example:
    -ToolsVersion "3.5"

    .PARAMETER Verbosity
    Display this amount of information in the event log.

    .PARAMETER ConsoleLoggerParameters
    Parameters to console logger.
    The available parameters are:
       PerformanceSummary--Show time spent in tasks, targets
           and projects.
       Summary--Show error and warning summary at the end.
       NoSummary--Don't show error and warning summary at the
           end.
       ErrorsOnly--Show only errors.
       WarningsOnly--Show only warnings.
       NoItemAndPropertyList--Don't show list of items and
           properties at the start of each project build.    
       ShowCommandLine--Show TaskCommandLineEvent messages  
       ShowTimestamp--Display the Timestamp as a prefix to any
           message.                                           
       ShowEventId--Show eventId for started events, finished 
           events, and messages
       ForceNoAlign--Does not align the text to the size of
           the console buffer
       DisableConsoleColor--Use the default console colors
           for all logging messages.
       DisableMPLogging-- Disable the multiprocessor
           logging style of output when running in 
           non-multiprocessor mode.
       EnableMPLogging--Enable the multiprocessor logging
           style even when running in non-multiprocessor
           mode. This logging style is on by default. 
       ForceConsoleColor--Use ANSI console colors even if
           console does not support it
       Verbosity--overrides the /verbosity setting for this
           logger.
    Example:
       -ConsoleLoggerParameters @{ PerformanceSummary=$true; NoSummary=$true; Verbosity="minimal" }

    .PARAMETER NoConsoleLogger
    Disable the default console logger and do not log events
    to the console.

    .PARAMETER BinaryLogger
    Serializes all build events to a compressed binary file.
    By default the file is in the current directory and named
    "msbuild.binlog". The binary log is a detailed description
    of the build process that can later be used to reconstruct
    text logs and used by other analysis tools. A binary log
    is usually 10-20x smaller than the most detailed text
    diagnostic-level log, but it contains more information.
    (Short form: /bl)

    The binary logger by default collects the source text of
    project files, including all imported projects and target
    files encountered during the build. The optional 
    ProjectImports switch controls this behavior:

     ProjectImports=None     - Don't collect the project
                               imports.
     ProjectImports=Embed    - Embed project imports in the
                               log file.
     ProjectImports=ZipFile  - Save project files to 
                               output.projectimports.zip
                               where output is the same name
                               as the binary log file name.

    The default setting for ProjectImports is Embed.
    Note: the logger does not collect non-MSBuild source files
    such as .cs, .cpp etc.

    A .binlog file can be "played back" by passing it to
    msbuild.exe as an argument instead of a project/solution.
    Other loggers will receive the information contained
    in the log file as if the original build was happening.
    You can read more about the binary log and its usages at:
    https://github.com/Microsoft/msbuild/wiki/Binary-Log

    Examples:
      -BinaryLogger -BinaryLoggerFile output.binlog -BinaryLoggerProjectImports None
      -BinaryLoggerFile output.binlog
      -BinaryLogger

    .PARAMETER BinaryLoggerFile
    @see BinaryLogger

    .PARAMETER BinaryLoggerProjectImports
    @see BinaryLogger

    .PARAMETER DetailedSummary
    Shows detailed information at the end of the build
    about the configurations built and how they were
    scheduled to nodes. 

    .PARAMETER NoAutoResponse
    Do not auto-include any MSBuild.rsp files.

    .PARAMETER NoLogo
    Do not display the startup banner and copyright message.

    .PARAMETER Version
    Display Version information only.

    .PARAMETER Help
    Display this help.

    .EXAMPLE
    An example

    .NOTES
    General notes
#>
function Invoke-MSBuild {
    [CmdletBinding(
        SupportsShouldProcess=$true,
        PositionalBinding=$false)]
    param (
        [Parameter(Mandatory = $true,
            ParameterSetName = "Main",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [Alias("Project")]
        [string]$Path,

        [Parameter(
            ValueFromPipelineByPropertyName = $true,             
            ParameterSetName = "Main")]
        [String]$PathToMSBuild,
  
        [Parameter(
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Main"
        )]
        [string[]]$Target,

        [Parameter(
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Main"
        )]
        [hashtable]$Property,

        [Parameter(
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Main"
        )]
        [Switch]$MaxCpuCountPhysicalCpus,

        [Parameter(
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Main"
        )]
        [Int]$MaxCpuCount,

        [Parameter(
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Main"
        )]
        [String]$ToolsVersion,

        [Parameter(
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Main"
        )]
        [ValidateSet("quiet", "minimal", "normal", "detailed", "diagnostic")]
        [String]$Verbosity,

        [Parameter(
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Main"
        )]
        [String]$ConsoleLoggerParameters,


        # Disable the default console logger and do not log events
        #    to the console.
        [Parameter(
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Main"
        )]
        [Switch]$NoConsoleLogger,

        # /fileLogger[n]     Logs the build output to a file. By default
        #     the file is in the current directory and named 
        #     "msbuild[n].log". Events from all nodes are combined into
        #     a single log. The location of the file and other
        #     parameters for the fileLogger can be specified through 
        #     the addition of the "/fileLoggerParameters[n]" switch.
        #     "n" if present can be a digit from 1-9, allowing up to 
        #     10 file loggers to be attached. (Short form: /fl[n])

        # /fileloggerparameters[n]:<parameters>                                
        #     Provides any extra parameters for file loggers.
        #     The presence of this switch implies the 
        #     corresponding /filelogger[n] switch.
        #     "n" if present can be a digit from 1-9.
        #     /fileloggerparameters is also used by any distributed
        #     file logger, see description of /distributedFileLogger.
        #     (Short form: /flp[n])
        #     The same parameters listed for the console logger are
        #     available. Some additional available parameters are:
        #        LogFile--path to the log file into which the
        #            build log will be written.
        #        Append--determines if the build log will be appended
        #            to or overwrite the log file. Setting the
        #            switch appends the build log to the log file;
        #            Not setting the switch overwrites the 
        #            contents of an existing log file. 
        #            The default is not to append to the log file.
        #        Encoding--specifies the encoding for the file, 
        #            for example, UTF-8, Unicode, or ASCII
        #     Default verbosity is Detailed.
        #     Examples:
        #       /fileLoggerParameters:LogFile=MyLog.log;Append;
        #                           Verbosity=diagnostic;Encoding=UTF-8

        #       /flp:Summary;Verbosity=minimal;LogFile=msbuild.sum 
        #       /flp1:warningsonly;logfile=msbuild.wrn 
        #       /flp2:errorsonly;logfile=msbuild.err

        # /distributedlogger:<central logger>*<forwarding logger>                     
        #     Use this logger to log events from MSBuild, attaching a
        #     different logger instance to each node. To specify
        #     multiple loggers, specify each logger separately. 
        #     (Short form /dl)
        #     The <logger> syntax is:
        #       [<logger class>,]<logger assembly>[;<logger parameters>]
        #     The <logger class> syntax is:
        #       [<partial or full namespace>.]<logger class name>
        #     The <logger assembly> syntax is:
        #       {<assembly name>[,<strong name>] | <assembly file>}
        #     The <logger parameters> are optional, and are passed
        #     to the logger exactly as you typed them. (Short form: /l)
        #     Examples:
        #       /dl:XMLLogger,MyLogger,Version=1.0.2,Culture=neutral
        #       /dl:MyLogger,C:\My.dll*ForwardingLogger,C:\Logger.dll

        # /distributedFileLogger                                                       
        #     Logs the build output to multiple log files, one log file
        #     per MSBuild node. The initial location for these files is
        #     the current directory. By default the files are called 
        #     "MSBuild<nodeid>.log". The location of the files and
        #     other parameters for the fileLogger can be specified 
        #     with the addition of the "/fileLoggerParameters" switch.

        #     If a log file name is set through the fileLoggerParameters
        #     switch the distributed logger will use the fileName as a 
        #     template and append the node id to this fileName to 
        #     create a log file for each node.

        # /logger:<logger>   Use this logger to log events from MSBuild. To specify
        #     multiple loggers, specify each logger separately.
        #     The <logger> syntax is:
        #       [<logger class>,]<logger assembly>[;<logger parameters>]
        #     The <logger class> syntax is:
        #       [<partial or full namespace>.]<logger class name>
        #     The <logger assembly> syntax is:
        #       {<assembly name>[,<strong name>] | <assembly file>}
        #     The <logger parameters> are optional, and are passed
        #     to the logger exactly as you typed them. (Short form: /l)
        #     Examples:
        #       /logger:XMLLogger,MyLogger,Version=1.0.2,Culture=neutral
        #       /logger:XMLLogger,C:\Loggers\MyLogger.dll;OutputAsHTML


        [Parameter(
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Main"        
        )]
        [Switch]$BinaryLogger,

        [Parameter(
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Main"
        )]
        [String]$BinaryLoggerFile,

        [Parameter(
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Main"
        )]
        [ValidateSet("Embed", "None", "ZipFile")]
        [String]$BinaryLoggerProjectImports,

        # /warnaserror[:code[;code2]]
        #     List of warning codes to treats as errors.  Use a semicolon
        #     or a comma to separate multiple warning codes. To treat all
        #     warnings as errors use the switch with no values.
        #     (Short form: /err[:c;[c2]])

        #     Example:
        #       /warnaserror:MSB4130

        #     When a warning is treated as an error the target will
        #     continue to execute as if it was a warning but the overall
        #     build will fail.

        # /warnasmessage[:code[;code2]]
        #     List of warning codes to treats as low importance
        #     messages.  Use a semicolon or a comma to separate
        #     multiple warning codes.
        #     (Short form: /nowarn[:c;[c2]])

        #     Example:
        #       /warnasmessage:MSB3026

        # /validate          Validate the project against the default schema. (Short
        #     form: /val)

        # /validate:<schema> Validate the project against the specified schema. (Short
        #     form: /val)
        #     Example:
        #       /validate:MyExtendedBuildSchema.xsd

        # /ignoreprojectextensions:<extensions>
        #     List of extensions to ignore when determining which 
        #     project file to build. Use a semicolon or a comma 
        #     to separate multiple extensions.
        #     (Short form: /ignore)
        #     Example:
        #       /ignoreprojectextensions:.sln

        # /nodeReuse:<parameters>
        #     Enables or Disables the reuse of MSBuild nodes.
        #     The parameters are:
        #     True --Nodes will remain after the build completes
        #            and will be reused by subsequent builds (default)
        #     False--Nodes will not remain after the build completes
        #     (Short form: /nr)
        #     Example:
        #       /nr:true

        # /preprocess[:file] 
        #     Creates a single, aggregated project file by
        #     inlining all the files that would be imported during a
        #     build, with their boundaries marked. This can be
        #     useful for figuring out what files are being imported
        #     and from where, and what they will contribute to
        #     the build. By default the output is written to
        #     the console window. If the path to an output file 
        #     is provided that will be used instead.
        #     (Short form: /pp)
        #     Example:
        #       /pp:out.txt

        [Parameter(
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Main"
        )]
        [Switch]$DetailedSummary,

        # @<file>            Insert command-line settings from a text file. To specify
        #     multiple response files, specify each response file
        #     separately.
    
        #     Any response files named "msbuild.rsp" are automatically 
        #     consumed from the following locations: 
        #     (1) the directory of msbuild.exe
        #     (2) the directory of the first project or solution built

        [Parameter(
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Main"
        )]
        [Switch]$NoAutoResponse,

        [Parameter(
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Main"
        )]
        [Switch]$NoLogo,

        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Version"
        )]
        [Switch]$Version,

        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Help"
        )]
        [Switch]$Help
    )

    if (-not [string]::IsNullOrWhiteSpace($PathToMSBuild)) {
        $msbuildExe = $PathToMSBuild
    }
    else {
        $msbuildExe = Select-MSBuildExe
    }

    $keys = $PSCmdlet.MyInvocation.BoundParameters.Keys
    $msBuildArgs = Get-MSBuildArgs $PSCmdlet.ParameterSetName $PSCmdlet.BoundParameters

    if ($keys -contains "WhatIf" -or $keys -contains "Confirm" -or $keys -contains "Verbose") {
        Write-Host "MSBuildExe: " -NoNewline -ForegroundColor Cyan
        Write-Host $msbuildExe -ForegroundColor DarkGray
        Write-Host "MSBuild Args:" -ForegroundColor Cyan
        $msBuildArgs | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
    }
    
    if ($PSCmdlet.ShouldProcess("see above", "Invoking MSBuild")) {
        Invoke-Native $msbuildExe $msBuildArgs
    }
}

# Wrapper for running native commands
# to enable mocking them for testing.
function Invoke-Native() {
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Path,
        [Parameter(Mandatory=$true)]
        [string[]]
        $Arguments
    )

    & $Path $Arguments
}

function Get-MSBuildArgs {
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Path,

        [Parameter(Mandatory=$true)]
        [string]
        $parameterSetName,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $boundParams   
    )

    Write-Verbose "Building MSBuild Arguments"

    # Deal with exclusive parameters first
    if ($parameterSetName -eq "Version") {
        return @('/Version');
    }

    if ($parameterSetName -eq "Help") {
        Get-Help Invoke-MSBuild -Full  
        return;
    }

    $result = @($Path)
    
    if ($boundParams.keys -contains "Verbosity") {
        $Verbosity = $boundParams['Verbosity']
        $result += "/Verbosity:$Verbosity"
    }

    if ($boundParams.keys -contains "Target") {
        $Target = @($boundParams['Target'])
        $result += "/Target:`"$($Target -join ';')`""
    }

    if ($boundParams.keys -contains "Property") {
        $Property = $boundParams['Property']
        $result += "/Property:`"{0}`"" -f (($Property.Keys | ForEach-Object { "$_=$($Property[$_])" }) -join ';')
    }

    if ($boundParams.keys -contains "ToolsVersion") {
        $ToolsVersion = $boundParams['ToolsVersion']
        $result += "/toolsversion:`"$ToolsVersion`""
    }

    if ($boundParams.keys -contains "MaxCpuCountPhysicalCpus" -and $boundParams.keys -contains "MaxCpuCount") {
        Write-Warning "MaxCpuCount and MaxCpuCountPhysicalCpus provided. Only MaxCpuCount will be used."
        $MaxCpuCount = $boundParams['MaxCpuCount']
        $result += "/MaxCpuCount:$MaxCpuCount"
    } else {
        if ($boundParams.keys -contains "MaxCpuCountPhysicalCpus") {
            $result += "/MaxCpuCount"
        } elseif ($boundParams.keys -contains "MaxCpuCount") {
            $MaxCpuCount = $boundParams['MaxCpuCount']
            $result += "/MaxCpuCount:$MaxCpuCount"
        }
    }

    if ($boundParams.keys -contains "BinaryLogger" -or 
        $boundParams.keys -contains "BinaryLoggerFile" -or 
        $boundParams.keys -contains "BinaryLoggerProjectImports") {

        $blString = "/BinaryLogger"
        $sep = if ($boundParams.keys -contains "BinaryLoggerFile" -and $boundParams.keys -contains "BinaryLoggerProjectImports") { ';' } else { ':"' }
        $end = if ($boundParams.keys -contains "BinaryLoggerFile" -or $boundParams.keys -contains "BinaryLoggerProjectImports") { '"' } else { "" }

        if ($boundParams.keys -contains "BinaryLoggerFile") {
            $BinaryLoggerFile = $boundParams['BinaryLoggerFile']
            $blString += ":`"$BinaryLoggerFile"
        }

        if ($boundParams.keys -contains "BinaryLoggerProjectImports") {
            $BinaryLoggerProjectImports = $boundParams['BinaryLoggerProjectImports']
            $blString += "${sep}ProjectImports=$BinaryLoggerProjectImports"
        }
        $result += $blString + $end
    }

    if ($boundParams.keys -contains "ConsoleLoggerParameters") {
        $ConsoleLoggerParameters = $boundParams['ConsoleLoggerParameters']
        $params = @(
            "PerformanceSummary"
            "Summary"
            "ErrorsOnly"
            "WarningsOnly"
            "NoItemAndPropertyList"
            "ShowCommandLine"
            "ShowTimestamp"
            "ShowEventId"
            "ForceNoAlign"
            "DisableConsoleColor"
            "DisableMPLogging"
            "EnableMPLogging"
            "ForceConsoleColor"
            "Verbosity"
        )

        $values = ($ConsoleLoggerParameters.keys | ForEach-Object {
            if ($params -notcontains $_) {
                Write-Warning "Unknown ConsoleLoggerParameters parameter: $_"
            }

            if ($_ -eq "Verbosity") {
                "$_=$($ConsoleLoggerParameters[$_])"
            } else {
                "$_"
            }
        }) -join ';'

        $result += "/ConsoleLoggerParameters:`"$values`""
    }

    $simpleFlags = @{
        NoAutoResponse = "/NoAutoResponse"
        DetailedSummary = "/DetailedSummary"
        NoLogo = "/NoLogo"
        NoConsoleLogger = "/NoConsoleLogger"
    }

    $simpleFlags.Keys | ForEach-Object { if ($boundParams.keys -contains "$_") { $result += $simpleFlags[$_] } }

    return $result
}

<#
.SYNOPSIS
Find available MSBuild versions.

.DESCRIPTION
Searches disk for installed MSBuild instances and 
return version information.

#>
function Get-MSBuildVersion {
    [CmdletBinding()]
    param()

    $msBuildSearchTerm = "C:\Program Files (x86)\*\MSBuild.exe"
    Write-Verbose "Looking for $msBuildSearchTerm"
    Write-Host "Searching for MSBuild - This might take some time..." -ForegroundColor DarkGray
    Get-ChildItem $msBuildSearchTerm  -Recurse | 
        Select-Object -ExpandProperty Fullname |
        ForEach-Object {
        $version = (Invoke-Native $_ "/Version","/NoLogo")
        [PSCustomObject]@{
            Path         = $_
            Version      = New-Object -ArgumentList $version -TypeName Version
            Architecture = if ($_ -match "amd64") { "amd64" } else { "x86" }
        }
    }
}

<#
.SYNOPSIS
Select "best" MSBuild install.

.DESCRIPTION
Select "best" MSBuild install.

.PARAMETER IgnoreCache
Ignores the cached result, causes a new
search to happen.

.EXAMPLE
An example

.NOTES
Result is cached in $env:IMSB_Path to speed
up subsequent calls, as searching is quite
time consuming.

#>
function Select-MSBuildExe {
    [CmdletBinding()]
    param([switch]$IgnoreCache)
  
    if ($IgnoreCache.IsPresent -or [string]::IsNullOrWhiteSpace($env:IMSB_Path)) {
        Write-Verbose "No Cache, or Ignoring Cached value for MSBuildExe"
        $env:IMSB_Path = Get-MSBuildVersion | 
            Sort-Object -Property Version | 
            Where-Object { $_.Architecture -match $env:PROCESSOR_ARCHITECTURE } | 
            Select-Object -ExpandProperty Path
    } else {
        Write-Verbose "Using Cached Value from `$env:IMSB_Path"
    }
    
    Write-Verbose "Result Cached in `$env:IMSB_Path for future invocations."
    return "$env:IMSB_Path"
}

Export-ModuleMember -Function @("Invoke-MSBuild", "Get-MSBuildVersion", "Select-MSBuildExe")
