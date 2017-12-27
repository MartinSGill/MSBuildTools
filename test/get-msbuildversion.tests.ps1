Import-Module "$PSScriptRoot/../src/Invoke-MSBuild.psm1" -Force

InModuleScope "Invoke-MSBuild" {
    Describe 'Get-MSBuildVersion' {
        Mock Write-Host # Prevent output in test
        
        Context "Result Counts" {
            It 'Returns nothing, for no results' {
                Mock Get-ChildItem -Verifiable
                Get-MSBuildVersion | Should BeNullOrEmpty
                Assert-VerifiableMocks
            }
    
            It 'Returns single result, for single result' {
                Mock Get-ChildItem -Verifiable -MockWith {
                    [PSCustomObject]@{ Fullname = "/some/dummy/path.exe" }
                }
                Mock Invoke-Native
    
                @(Get-MSBuildVersion).Count | Should Be 1
            }
    
            It 'Returns multiple results, for multiple results' {
                Mock Get-ChildItem -Verifiable -MockWith {
                    @(
                        [PSCustomObject]@{ Fullname = "/some/dummy/path.exe" },
                        [PSCustomObject]@{ Fullname = "/some/dummy/path1.exe" },
                        [PSCustomObject]@{ Fullname = "/some/dummy/path2.exe" },
                        [PSCustomObject]@{ Fullname = "/some/dummy/path3.exe" }
                    )
                }
                Mock Invoke-Native
    
                @(Get-MSBuildVersion).Count | Should Be 4
            }
        }

        Context "Results Data" {
            It 'Returns required Properties' {
                Mock Get-ChildItem -Verifiable -MockWith {
                    [PSCustomObject]@{ Fullname = "/some/dummy/path.exe" }
                }
                Mock Invoke-Native
                $actual = Get-MSBuildVersion
                $properties = ($actual | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name)
                $properties -contains "Path" | Should Be $true
                $properties -contains "Version" | Should Be $true
                $properties -contains "Architecture" | Should Be $true
            }

            It 'Correctly Uses Version Type' {
                Mock Get-ChildItem -Verifiable -MockWith {
                    [PSCustomObject]@{ Fullname = "/some/dummy/path.exe" }
                }
                Mock Invoke-Native -MockWith { "15.1.2.3" }
    
                $actual = @(Get-MSBuildVersion)
                $actual.Version | Should BeOfType [Version]
                $actual.Version | Should Be "15.1.2.3"
            } 

            It 'Correctly Sets Version' {
                Mock Get-ChildItem -Verifiable -MockWith {
                    [PSCustomObject]@{ Fullname = "/some/dummy/path.exe" }
                }
                Mock Invoke-Native -MockWith { "15.1.2.3" }
    
                $actual = @(Get-MSBuildVersion)
                $actual.Version | Should Be "15.1.2.3"
            } 

            It 'Correctly Sets Architecture x86 based on path' {
                Mock Get-ChildItem -Verifiable -MockWith {
                    [PSCustomObject]@{ Fullname = "/some/dummy/path.exe" }
                }
                Mock Invoke-Native -MockWith { "15.1.2.3" }
    
                $actual = @(Get-MSBuildVersion)
                $actual.Architecture | Should Be "x86"
            } 

            It 'Correctly Sets Architecture amd64 based on path' {
                Mock Get-ChildItem -Verifiable -MockWith {
                    [PSCustomObject]@{ Fullname = "/some/amd64/path.exe" }
                }
                Mock Invoke-Native -MockWith { "15.1.2.3" }
    
                $actual = @(Get-MSBuildVersion)
                $actual.Architecture | Should Be "amd64"
            }
        }
    }
}