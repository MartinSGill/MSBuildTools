#Requires -Module TabExpansionPlusPlus

$switches = @(
    "/target"
    "/property"
    "/maxcpucount"
    "/toolsversion"
    "/verbosity"
    "/consoleloggerparameters"
    "/noconsolelogger"
    "/fileLogger"
    "/fileloggerparameters"
    "/distributedlogger"
    "/distributedFileLogger"
    "/logger"
    "/binaryLogger"
    "/warnaserror"
    "/warnasmessage"
    "/validate"
    "/ignoreprojectextensions"
    "/nodeReuse"
    "/preprocess"
    "/detailedsummary"
    "/noautoresponse"
    "/nologo"
    "/version"
    "/help"
)

function MSBuildArguementCompleterInternal {
    param($wordToComplete, $commandAst, $cursorPosition)
    Write-Verbose "In Local"
    $switches | Where-Object { $_ -like "$wordToComplete" } | Sort-Object | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

Register-ArgumentCompleter -Native `
                           -CommandName @("msbuild", "msbuild.exe") `
                           -ScriptBlock {
                                param($wordToComplete, $commandAst, $cursorPosition)
                                Write-Verbose "In Local"
                                $switches | Where-Object { $_ -like "$wordToComplete" } | Sort-Object | ForEach-Object {
                                    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
                                }
                            }

