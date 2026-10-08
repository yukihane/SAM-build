#requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet('Release', 'Debug')]
    [string[]] $Configuration = @('Release', 'Debug'),
    [ValidateRange(1, 64)]
    [int] $MaxCpuCount = 4
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$solutionPath = Join-Path $repoRoot 'wxWidgets/build/msw/wx_vc17.sln'
$logRoot = Join-Path $repoRoot 'logs'
$vswherePath = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'

if (-not (Test-Path -LiteralPath $solutionPath -PathType Leaf)) {
    throw 'wxWidgets sources are missing. Run git submodule update --init --recursive first.'
}
if (-not (Test-Path -LiteralPath $vswherePath -PathType Leaf)) {
    throw 'Visual Studio Installer (vswhere.exe) was not found.'
}
$msbuildPaths = @(& $vswherePath -latest -products '*' -version '[17.0,18.0)' `
    -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -find 'MSBuild\**\Bin\MSBuild.exe')
if ($LASTEXITCODE -ne 0 -or $msbuildPaths.Count -eq 0) {
    throw 'Visual Studio 2022 MSBuild with C++ tools was not found.'
}
$msbuildPath = $msbuildPaths[0]
New-Item -ItemType Directory -Path $logRoot -Force | Out-Null

foreach ($buildConfiguration in $Configuration) {
    $logPath = Join-Path $logRoot "wxWidgets-$buildConfiguration-x64.log"
    Write-Host "Building wxWidgets $buildConfiguration/x64..."
    & $msbuildPath $solutionPath /t:Build "/m:$MaxCpuCount" `
        "/p:Configuration=$buildConfiguration" /p:Platform=x64 /nologo /verbosity:minimal `
        /fl "/flp:logfile=$logPath;verbosity=normal"
    if ($LASTEXITCODE -ne 0) {
        throw "wxWidgets $buildConfiguration/x64 build failed. See $logPath."
    }
}

Write-Host "wxWidgets build completed. Libraries: $(Join-Path $repoRoot 'wxWidgets/lib/vc_x64_lib')"
