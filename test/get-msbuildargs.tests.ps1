Import-Module "$PSScriptRoot/../src/Invoke-MSBuild.psm1" -Force

InModuleScope "Invoke-MSBuild" {
    Describe 'Get-MSBuildArgs' {
        Context "Special Cases" {
            It "Given Version it returns /Version" {
                $actual = Get-MSBuildArgs "dummy.sln" "Version" @{}
                $actual | Should Be "/Version"
            }

            It "Given Help it calls Get-Help" {
                Mock Get-Help -Verifiable
                $null = Get-MSBuildArgs "dummy.sln" "Help" @{}
                Assert-VerifiableMocks
            }

        }

        Context "Path" {
            It "Given Only Path it returns only Path" {
                $actual = @(Get-MSBuildArgs "dummy.sln" "Main" @{})
                $actual.Count | Should Be 1
                $actual | Should Be "dummy.sln"
            }
    
            It "Given Path and params it returns Path" {
                $actual = Get-MSBuildArgs "dummy.sln" "Main" @{ Target = "bob"; MaxCpuCount = 5 }
                $actual[0] | Should Be "dummy.sln"
            }
        }

        Context "MaxCpuCount" {
            It "Given MaxCpuCount it returns /MaxCpuCount" {
                $actual = Get-MSBuildArgs "dummy.sln" "Main" @{ MaxCpuCount = 5 }
                $actual.Count | Should Be 2
                $actual[1] | Should Be "/MaxCpuCount:5"
            }
    
            It "Given MaxCpuCountPhysicalCpus it returns /MaxCpuCount" {
                $actual = Get-MSBuildArgs "dummy.sln" "Main" @{ MaxCpuCountPhysicalCpus = $true }
                $actual.Count | Should Be 2
                $actual[1] | Should Be "/MaxCpuCount"
            }
    
            It "Given both MaxCpuCount & MaxCpuCountPhysicalCpus it returns only /MaxCpuCount" {
                Mock -CommandName Write-Warning
                $actual = @(Get-MSBuildArgs "dummy.sln" "Main" @{ MaxCpuCountPhysicalCpus = $true; MaxCpuCount = 5 })
                $actual.Count | Should Be 2
                $actual[1] | Should Be "/MaxCpuCount:5"
            }
    
            It "Given both MaxCpuCount & MaxCpuCountPhysicalCpus it emits warning" {
                Mock -CommandName Write-Warning -Verifiable
                $null = @(Get-MSBuildArgs "dummy.sln" "Main" @{ MaxCpuCountPhysicalCpus = $true; MaxCpuCount = 5 })
                Assert-VerifiableMocks
            }
        }

        Context "Verbosity" {
            It "Given Verbosity it returns /Verbosity:n" {
                $actual = Get-MSBuildArgs "dummy.sln" "Main" @{ Verbosity = "detailed" }
                $actual.Count | Should Be 2
                $actual[1] | Should Be "/Verbosity:detailed"
            }
        }

        Context "ToolsVersion" {
            It "Given ToolsVersion it returns /ToolsVersion:`"n`"" {
                $actual = Get-MSBuildArgs "dummy.sln" "Main" @{ ToolsVersion = "3.5" }
                $actual.Count | Should Be 2
                $actual[1] | Should Be '/ToolsVersion:"3.5"'
            }
        }

        Context "Targets" {
            It "Given single target returns single target" {
                $actual = Get-MSBuildArgs "dummy.sln" "Main" @{ Target = "t1" }
                $actual.Count | Should Be 2
                $actual[1] | Should Be '/Target:"t1"'
            }

            It "Given multiple targets returns concatenated targets" {
                $actual = Get-MSBuildArgs "dummy.sln" "Main" @{ Target = "t1","t2","t3" }
                $actual.Count | Should Be 2
                $actual[1] | Should Be '/Target:"t1;t2;t3"'
            }

            It "Given multiple targets as single string returns concatenated targets" {
                $actual = Get-MSBuildArgs "dummy.sln" "Main" @{ Target = "t1;t2;t3" }
                $actual.Count | Should Be 2
                $actual[1] | Should Be '/Target:"t1;t2;t3"'
            }
        }

        Context "Property" {
            It "Given single property returns that property" {
                $actual = Get-MSBuildArgs "dummy.sln" "Main" @{ Property = @{ Configuration="Debug" } }
                $actual.Count | Should Be 2
                $actual[1] | Should Be '/Property:"Configuration=Debug"'
            }

            It "Given multiple property returns multiple property" {
                $actual = Get-MSBuildArgs "dummy.sln" "Main" @{ Property = @{ Configuration="Debug"; Architecture="x86" } }
                $actual.Count | Should Be 2
                # Looking for /Property:"Configuration=Debug;Architecture=x86"
                # But order of properties cannot be assumed
                $actual[1] | Should Match "^/Property:`""
                $actual[1] | Should Match "`"$"
                $actual[1] | Should Match "Configuration=Debug"
                $actual[1] | Should Match "Architecture=x86"
            }
        }

        Context "BinaryLogger" {
            It "Correctly Sets BinaryLogger" {
                $actual = Get-MSBuildArgs "dummy.sln" "Main" @{ BinaryLogger=$true }
                $actual.Count | Should Be 2
                $actual[1] | Should Be '/BinaryLogger'
            }

            It "Correctly Sets BinaryLoggerFile" {
                $actual = Get-MSBuildArgs "dummy.sln" "Main" @{ BinaryLoggerFile="output.binlog" }
                $actual.Count | Should Be 2
                $actual[1] | Should Be '/BinaryLogger:"output.binlog"'
            }

            It "Correctly Sets BinaryLoggerFile and BinaryLoggerProjectImports" {
                $actual = Get-MSBuildArgs "dummy.sln" "Main" @{ BinaryLoggerFile="output.binlog"; BinaryLoggerProjectImports="None" }
                $actual.Count | Should Be 2
                $actual[1] | Should Be '/BinaryLogger:"output.binlog;ProjectImports=None"'
            }

            It "Correctly Sets BinaryLoggerProjectImports" {
                $actual = Get-MSBuildArgs "dummy.sln" "Main" @{ BinaryLoggerProjectImports="None" }
                $actual.Count | Should Be 2
                $actual[1] | Should Be '/BinaryLogger:"ProjectImports=None"'
            }

            It "Correctly Sets BinaryLoggerFile and BinaryLoggerProjectImports if BinaryLogger also set." {
                $actual = Get-MSBuildArgs "dummy.sln" "Main" @{ BinaryLoggerFile="output.binlog"; BinaryLoggerProjectImports="None"; BinaryLogger=$true }
                $actual.Count | Should Be 2
                $actual[1] | Should Be '/BinaryLogger:"output.binlog;ProjectImports=None"'
            }
        }

        Context "ConsoleLoggerParameters" {
            
            It "Correctly sets Verbosity ConsoleLoggerParameters" {
                $actual = Get-MSBuildArgs "dummy.sln" "Main" @{ ConsoleLoggerParameters = @{ Verbosity = "minimal" } }
                $actual.Count | Should Be 2
                $actual[1] | Should Be '/ConsoleLoggerParameters:"Verbosity=minimal"'
            }
            
            It "Correctly sets single ConsoleLoggerParameters" {
                $actual = Get-MSBuildArgs "dummy.sln" "Main" @{ ConsoleLoggerParameters= @{ Summary = $true } }
                $actual.Count | Should Be 2
                $actual[1] | Should Be '/ConsoleLoggerParameters:"Summary"'
            }

            It "Correctly sets multiple ConsoleLoggerParameters" {
                $actual = Get-MSBuildArgs "dummy.sln" "Main" @{ ConsoleLoggerParameters= @{ Summary = $true; ErrorsOnly = $true } }
                $actual.Count | Should Be 2
                
                # Order of properties cannot be assumed
                $actual[1] | Should Match "^/ConsoleLoggerParameters:`""
                $actual[1] | Should Match "`"$"
                $actual[1] | Should Match "ErrorsOnly"
                $actual[1] | Should Match "Summary"
            }

            It "Correctly warns for unknown parameter." {
                Mock -CommandName Write-Warning -Verifiable
                $actual = Get-MSBuildArgs "dummy.sln" "Main" @{ ConsoleLoggerParameters= @{ Wibble = $true } }
                Assert-VerifiableMocks
            }
        }

        Context "Simple Switches" {

            It "Correctly Sets '<flag>' to '<expected>'." -TestCases @(
                @{ flag = 'NoAutoResponse' ; expected = '/NoAutoResponse' }
                @{ flag = 'DetailedSummary' ; expected = '/DetailedSummary' }
                @{ flag = 'NoLogo' ; expected = '/NoLogo' }
                @{ flag = 'NoConsoleLogger' ; expected = '/NoConsoleLogger' }
                ){
                    param($flag,$expected)
                    $actual = Get-MSBuildArgs "dummy.sln" "Main" @{ "$flag"=$true }
                    $actual.Count | Should Be 2
                    $actual[1] | Should Be "$expected"
                }
        }
    }
}
