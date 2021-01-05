[CmdletBinding()]
param (
    [ValidateSet("x86", "amd64", "x64", IgnoreCase = $false)]
    [string]$Architecture = "<auto>",
    [switch]$DryRun,
    [string]$ProxyAddress,
    [switch]$ProxyUseDefaultCredentials,
    [int]$Version = 16
)

. "$PSScriptRoot\utils.ps1"

# Configuration and Variables =================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$MsBuildToolsFeed = "https://aka.ms/vs/${Version}/release/vs_buildtools.exe"
# End Config and Variables ====================================================

# Helpers =====================================================================
function Install-MsBuildTools ([string]$File) {
    Say-Invocation $MyInvocation

    Start-Process -NoNewWindow -Wait -FilePath "$File" `
        -ArgumentList "--quiet --wait --norestart --nocache", `
        "--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64", `
        "--add Microsoft.Component.MSBuild", `
        "--add Microsoft.VisualStudio.Component.VC.CoreBuildTools", `
        "--add Microsoft.VisualStudio.Component.VC.CoreIde", `
        "--add Microsoft.VisualStudio.Component.VC.Redist.14.Latest", `
        "--add Microsoft.VisualStudio.Component.Windows10SDK", `
        "--add Microsoft.VisualStudio.Component.Windows10SDK.18362", `
        "--add Microsoft.VisualStudio.Component.VC.CMake.Project"
}
# End Helpers =================================================================

# Main Section ================================================================
Say-Green "`n=== Ms BuildTools Installation ==="
# Testing if already installed
if ($msbuildtools = $(Test-CommandInSystem -Cmd "VsDevCmd.bat" `
            -path "C:\Program Files*\" -Silent)) {
    return $msbuildtools
}

$DownloadLink = $MsBuildToolsFeed
$FileInstaller = ($MsBuildToolsFeed -split "/" | Select-Object -Last 1)
Say-Verbose "FileInstaller: $FileInstaller"
$FileInstallerPath = "$env:TEMP\$FileInstaller"
Say-Verbose "FileInstallerPath: $FileInstallerPath"

$DownloadFailed = $false
Say "Downloading link: $DownloadLink"
try {
    DownloadFile -Source $DownloadLink -OutPath $FileInstallerPath
} catch {
    Say "Cannot download: $DownloadLink"
    $DownloadFailed = $true
}

if ($DownloadFailed) {
    throw "Could not find/download: `"$DownloadLink`" with version = $Version`n"
}

Install-MsBuildTools $FileInstallerPath

Say "MS BuildTools installation: $FileInstaller"
return
