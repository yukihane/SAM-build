#requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$packageName = 'or-tools_x64_VisualStudio2022_cpp_v9.14.6206'
$archiveName = "$packageName.zip"
$downloadUrl = "https://github.com/google/or-tools/releases/download/v9.14/$archiveName"
# SHA-256 published in the official GitHub release asset metadata.
$expectedHash = 'f8d3309b4e39c31167e52ab78f506acc7b07d6917bdf4fc2f00db7166de2f3b2'
$downloadRoot = Join-Path $repoRoot 'downloads'
$dependencyRoot = Join-Path $repoRoot 'deps'
$archivePath = Join-Path $downloadRoot $archiveName
$installRoot = Join-Path $dependencyRoot $packageName
$markerName = '.sam-ortools.sha256'
$requiredFiles = @(
    'include/ortools/linear_solver/linear_solver.h'
    'include/eigen3/Eigen/Core'
    'lib/ortools.lib'
    'bin/ortools.dll'
    'lib/cmake/ortools/ortoolsConfig.cmake'
    'lib/cmake/absl/abslConfig.cmake'
)

function Test-PackageFiles {
    param([string] $Root)
    foreach ($relativePath in $requiredFiles) {
        $filePath = Join-Path $Root $relativePath
        if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) { return $false }
        if ((Get-Item -LiteralPath $filePath).Length -eq 0) { return $false }
    }
    return $true
}

function Test-ArchiveHash {
    if (-not (Test-Path -LiteralPath $archivePath -PathType Leaf)) { return $false }
    return (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash -eq $expectedHash
}

if (Test-Path -LiteralPath $installRoot) {
    $markerPath = Join-Path $installRoot $markerName
    if ((Test-Path -LiteralPath $markerPath -PathType Leaf) -and
        (Get-Content -LiteralPath $markerPath -Raw).Trim() -eq $expectedHash -and
        (Test-PackageFiles -Root $installRoot)) {
        Write-Host 'OR-Tools 9.14.6206 is already available; skipping download and extraction.'
        Write-Output $installRoot
        return
    }
    throw "Existing OR-Tools directory is incomplete or unrecognized: $installRoot. Move it aside before retrying."
}

New-Item -ItemType Directory -Path $downloadRoot, $dependencyRoot -Force | Out-Null

if (-not (Test-ArchiveHash)) {
    $partialPath = Join-Path $downloadRoot "$archiveName.$([guid]::NewGuid().ToString('N')).partial"
    try {
        Write-Host "Downloading $archiveName..."
        Invoke-WebRequest -Uri $downloadUrl -OutFile $partialPath -UseBasicParsing
        $actualHash = (Get-FileHash -LiteralPath $partialPath -Algorithm SHA256).Hash
        if ($actualHash -ne $expectedHash) {
            throw "OR-Tools archive SHA-256 mismatch. Expected $expectedHash; received $actualHash."
        }
        Move-Item -LiteralPath $partialPath -Destination $archivePath -Force
    }
    finally {
        if (Test-Path -LiteralPath $partialPath) {
            Remove-Item -LiteralPath $partialPath -Force
        }
    }
}
else {
    Write-Host 'Using the verified OR-Tools archive in downloads/.'
}

$stagingRoot = Join-Path $dependencyRoot ".$packageName.extract-$([guid]::NewGuid().ToString('N'))"
# Cleanup below is restricted to this invocation's staging directory in deps/.
$resolvedStagingRoot = [System.IO.Path]::GetFullPath($stagingRoot)
$expectedParent = [System.IO.Path]::GetFullPath($dependencyRoot)
if ([System.IO.Path]::GetDirectoryName($resolvedStagingRoot) -ne $expectedParent) {
    throw 'Extraction staging directory must be directly inside deps/.'
}

try {
    Write-Host 'Extracting OR-Tools...'
    Expand-Archive -LiteralPath $archivePath -DestinationPath $stagingRoot
    $packageRoot = Join-Path $stagingRoot $packageName
    if (-not (Test-Path -LiteralPath $packageRoot -PathType Container)) {
        $packageRoot = $stagingRoot
    }
    if (-not (Test-PackageFiles -Root $packageRoot)) {
        throw 'OR-Tools archive does not contain the expected Windows libraries, headers and CMake packages.'
    }
    Set-Content -LiteralPath (Join-Path $packageRoot $markerName) -Value $expectedHash -Encoding Ascii
    Move-Item -LiteralPath $packageRoot -Destination $installRoot
}
finally {
    if (Test-Path -LiteralPath $resolvedStagingRoot) {
        Remove-Item -LiteralPath $resolvedStagingRoot -Recurse -Force
    }
}

Write-Host 'OR-Tools 9.14.6206 is ready.'
Write-Output $installRoot
