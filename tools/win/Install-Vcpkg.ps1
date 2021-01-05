[CmdletBinding()]
param (
    # [ValidateSet("x86", "amd64", "x64", IgnoreCase = $false)]
    # [string]$Architecture = "<auto>",
    [switch]$DryRun,
    [string]$ProxyAddress,
    [switch]$ProxyUseDefaultCredentials
)

. "$PSScriptRoot\utils.ps1"

# Configuration and Variables =================================================
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$GithubFeed = "https://github.com/microsoft/vcpkg.git"
$cwd = Get-Location
# End Config and Variables ====================================================

# Helpers =====================================================================
function Get-Repo([version]$version, [string]$repo, [string]$output) {
    Say-Invocation $MyInvocation

    if (-not $(Test-Path $output)) {
        git.exe clone $repo $output
        Set-Location $output
        if ($version) {
            git.exe checkout $version
        }
    }
}

function Install-Vcpkg {
    . "${HOME}\.vcpkg\bootstrap-vcpkg.bat"
}

# End Helpers =================================================================

# Main Section ================================================================
Say-Green "`n=== Vcpkg Installation ==="
if ($vcpkg = $(Test-CommandInSystem -Cmd "vcpkg.cmake" `
            -Path "C:\Program Files*\" -Silent)) {
    return $vcpkg
}
if ($vcpkg = $(Test-CommandInSystem -Cmd "vcpkg.cmake" `
            -Path "${HOME}" -Silent)) {
    return $vcpkg
}

Get-Repo -repo $GithubFeed -output "${HOME}\.vcpkg"


Say "Vcpkg bootstrap"
Install-Vcpkg

Say "Vcpkg installation: Completed"
$env:Path += ";${HOME}\.vcpkg"
[System.Environment]::SetEnvironmentVariable('path', $env:Path, "User")
Set-Location $cwd
Start-Sleep 2
return
