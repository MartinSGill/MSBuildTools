#Requires -Module PSGraph

function Get-MSBuildTargets {
    param(
        $path
        )

        $ns = @{ msb = "http://schemas.microsoft.com/developer/msbuild/2003" }
        Select-Xml -Path $path -XPath "//msb:Target" -Namespace $ns | 
            ForEach-Object { $_.Node  }
}

function Get-MSBuildIncludeFiles {
    $ns = @{ msb = "http://schemas.microsoft.com/developer/msbuild/2003" }
    Select-Xml -Path $path -XPath "//msb:Import" -Namespace $ns | 
        ForEach-Object { $_.Node  }
    
    
}

class MSBuildTargetInfo {
    [string]   $Name
    [string[]] $BeforeTargets;
    [string[]] $AfterTargets
    [string[]] $DependsOnTargets
    [string]   $Condition
}

function Get-MSBuildTargetInfo {
    param(
        $path
        )

    Get-MSBuildTargets $path | ForEach-Object {
            $seperator = ';'
            $info = [MSBuildTargetInfo]::new();
            $info.Name = $_.Name
            $info.BeforeTargets = if (-not [string]::IsNullOrWhiteSpace($_.BeforeTargets)) { $_.BeforeTargets -split $seperator }
            $info.AfterTargets = if (-not [string]::IsNullOrWhiteSpace($_.AfterTargets)) { $_.AfterTargets -split $seperator }
            $info.DependsOnTargets = if (-not [string]::IsNullOrWhiteSpace($_.DependsOnTargets)) { $_.DependsOnTargets -split $seperator }
            $info.Condition = $_.Condition
            $info
        }
}

function New-MSBuildTargetDependencyGraph {
    param(
        $path
        )

    $targets = Get-MSBuildTargetInfo $path

    digraph g -Attributes @{rankdir = "LR"; nodesep= 0.3; ranksep = 0.3} {
        # rank ($targets | Select-Object -ExpandProperty Name )
        $targets | ForEach-Object { 
            node $_.Name # -Attributes @{fontsize = 16; shape = "record"; height = 0.1; color = "lightblue2"}
            if ($_.DependsOnTargets.Count -gt 0) {
                edge -From $_.Name -To $_.DependsOnTargets -Attributes @{label="DependsOn"}
            }
        }
    } | Export-PSGraph -ShowGraph
}
