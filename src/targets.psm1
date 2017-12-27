#Requires -Module PSGraph

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

function Get-MSBuildTargets {
    param(
        $path
        )

        $ns = @{ msb = "http://schemas.microsoft.com/developer/msbuild/2003" }
        Select-Xml -Path $path -XPath "//msb:Target" -Namespace $ns | 
            ForEach-Object { $_.Node  }
}

function Get-MSBuildTargets 
{
  param([Parameter(Mandatory)]$file)

  $proj = [xml](Get-Content $file) 
  $proj.Project.Target |
  Select-Object -ExpandProperty Name |
  Sort-Object
}

function Get-MSBuildProperty 
{
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory)]$file
    )

  $script:properties = @{}
  function Add-Prop($name) {
    if (-not $script:properties.ContainsKey($name)) {
      $script:properties[$name] = [pscustomobject]@{
        name = $name
        file = $file
        defined = 0
        useCount = 0
      }
    }
  }

  $proj = [xml](Get-Content $file) 
  $definedProps = @()
  foreach ($propGroup in $proj.Project.PropertyGroup) 
  {
    $definedProps += @($propGroup.PSObject.Properties | 
    Where-Object -FilterScript {
      $_.TypeNameOfValue -eq 'System.String' -and $_.MemberType -eq 'Property'  
    } | 
    Where-Object -FilterScript {
      @('Name', 'LocalName', 
        'NamespaceURI', 
        'Prefix', 
        'InnerXml', 
        'InnerText', 
        'Value', 
        'OuterXml', 
      'BaseURI') -cnotcontains $_.Name
    } | 
    Select-Object -ExpandProperty Name)
  }

  $definedProps | % { Add-Prop $_; $script:properties[$_].defined++ }

  $usedProps = Select-String -Pattern '\$\((\w+)\)' -Path $file -AllMatches | ForEach-Object -Process {
    $_.matches
  }

  $usedProps | % { $_.Groups[1].Value } | % {
    add-prop $_
    $script:properties[$_].useCount++
  }

  $script:properties.Values
}

function Get-MSBuildTargetRelationships 
{
  [CmdLetBinding()]
  param([Parameter(Mandatory)]$file)

    
  function Select-HasValue
  {
    process
    {
      if ( -not [string]::IsNullOrWhiteSpace($_) )
      {
        $_
      }
    }
  }

  $script:targets = @{
    _default = [PSCustomObject]@{
      name      = '_default'
      dependsOn = @()
      calls     = @()
      msbuild   = @()
      callCount = 1
      file      = $file
    }
  }

  $file = Resolve-Path $file

  Write-Verbose -Message "Loading $file"
  $proj = [xml](Get-Content $file)

  $script:targets._default.calls = @($proj.Project.DefaultTargets -split ';' | Where-Object -FilterScript {
      -not [string]::IsNullOrWhiteSpace($_) 
  })
    
  function add-target 
  {
    param
    (
      [Parameter(Mandatory = $true)]
      [string]$name
    )
    if (-not $script:targets.ContainsKey($name)) 
    {
      $script:targets[$name] = [PSCustomObject]@{
        name      = $name
        dependsOn = @()
        calls     = @()
        msbuild   = @()
        callCount = 1
        file      = 'unknown'
      }
    }
  }

  # First run - ensure all targets are recorded
  foreach ($target in $proj.Project.Target) 
  {
    Write-Verbose -Message ('Target: ' + $target.Name)
    if ($defaultTargets -contains $target.Name) 
    {
      Write-Verbose -Message '  Is Default Target'
    }

    add-target $target.Name
    $script:targets[$target.Name].file = $file

    if ($target.MSBuild) 
    {
      Write-Verbose -Message ('  Has MSBuild tasks')
      foreach ($build in $target.MSBuild) 
      {
        foreach ($dep in ($build.Targets -split ';'| Select-HasValue)) 
        {
          Write-Verbose -Message ('  MSBuild Dependency: {0} -> {1}' -f $target.Name, $dep)
          $script:targets[$target.Name].msbuild += $dep
          add-target $dep
          $script:targets[$dep].callCount += 1
          if ($build.Projects -ne '$(MSBuildProjectFile)')
          {
            $script:targets[$dep].file = $build.Projects
          }
        }
      }
    }

    if ($target.DependsOnTargets) 
    {
      Write-Verbose -Message ('  Has DependsOnTargets')
      foreach ($dep in ($target.DependsOnTargets -split ';')| Select-HasValue ) 
      {
        Write-Verbose -Message ('  DependsOnTargets Dependency: {0} -> {1}' -f $target.Name, $dep)
        $script:targets[$target.Name].dependsOn += $dep
        add-target $dep
        $script:targets[$dep].callCount += 1
      }
    }

    foreach ($callTarget in $target.CallTarget) 
    {
      Write-Verbose -Message ('  CallTarget Dependency: {0} -> {1}' -f $target.Name, $callTarget.Targets)
      foreach ($dep in ($callTarget.Targets -split ';')| Select-HasValue) 
      {
        $script:targets[$target.Name].calls += $dep
        add-target $dep
        $script:targets[$dep].callCount += 1
      }
    }
  }

  $targets.Values
}

function Get-MSBuildDependencyGraph 
{
  [CmdLetBinding()]
  param([Parameter(Mandatory)]$file)

  $targets = Get-MSBuildTargetRelationships -file $file

  $dot = @"
@startuml
left to right direction
skinparam componentstyle uml2

"@
    
  foreach ($target in $targets) 
  {
    if ($target.name -eq '_default') 
    {
      $dot += @"

() "$($target.name)" #orange

"@
    }
    else 
    {
      $dot += @"

frame "$($target.file -replace '\\', '/')" {
  [$($target.name)]
}

"@
    }
  }

  foreach ($target in $targets) 
  {
    $target.dependsOn | ForEach-Object -Process {
      $dot += "[$($target.name)] --> [$_] : depends`n"  
    }
    $target.calls | ForEach-Object -Process {
      $dot += "[$($target.name)] -[#blue]-> [$_] : calls`n"  
    }
    $target.msbuild | ForEach-Object -Process {
      $dot += "[$($target.name)] -[#green]-> [$_] : msbuild`n"  
    }
  }

  $dot += "@enduml`n"
  Write-Verbose -Message $dot
    
  Show-Graph -content $dot
}