[CmdletBinding()]
param (
    [ValidateSet("x86", "amd64", "x64", IgnoreCase = $false)]
    [string]$Architecture = "amd64",
    [switch]$DryRun,
    [string]$ProxyAddress,
    [switch]$ProxyUseDefaultCredentials,
    [version]$Version = "3.9.1"
)

. "$PSScriptRoot\utils.ps1"

# Configuration and Variables =================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

if (($Architecture -eq "amd64") -or ($Architecture -eq "x64")) {
    $arch = "-amd64"
} else {
    $arch = ""
}

$Feed = "https://www.python.org/ftp/python/${Version}/python-${Version}${arch}.exe"
# End Config and Variables ====================================================

# Helpers =====================================================================
function Install-Python([string]$File) {
    Say-Invocation $MyInvocation

    Start-Process -NoNewWindow -Wait -FilePath "$File" `
        -ArgumentList "/quiet /passive", `
        "InstallAllUsers=0", `
        "PrependPath=1", `
        "Shortcuts=0", `
        "Include_doc=0", `
        "Include_launcher=0", `
        "Include_test=0", `
        "Include_tcltk"
}
# End Helpers =================================================================

# Main Section ================================================================
Say-Green "`n=== Python Installation ==="
# Testing if already installed
if ($(Test-CommandInSystem -Cmd "python.exe" `
            -path "${HOME}\AppData" -Silent)) {
    return
}

$DownloadLink = $Feed
$FileInstaller = ($Feed -split "/" | Select-Object -Last 1)
Say-Verbose "FileInstaller: $FileInstaller"
$FileInstallerPath = "${HOME}\Downloads\$FileInstaller"
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

Say "Python installation: $FileInstaller"
Install-Python $FileInstallerPath

Say "Python installation: Finished."
return
