[CmdletBinding()]
param (
    [ValidateSet("x86", "amd64", "x64", IgnoreCase = $false)]
    [string]$Architecture = "<auto>",
    [switch]$DryRun,
    [string]$ProxyAddress,
    [switch]$ProxyUseDefaultCredentials
)

. "$PSScriptRoot\utils.ps1"

# Configuration and Variables =================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$GithubFeed = "https://github.com/git-for-windows/git"
# End Config and Variables ====================================================

# Helpers =====================================================================
function Get-Download-Link([string]$CLIArchitecture) {
    Say-Invocation $MyInvocation

    $base_uri = (GetHTTPResponse "${GithubFeed}/releases/latest").RequestMessage.RequestUri.OriginalString
    $Version = ($base_uri -split "/" | Select-Object -Last 1).Replace("v", "").Replace(".windows", "")
    return $base_uri.Replace("tag", "download") + "/Git-${Version}-${CLIArchitecture}.exe"
}

function Install-Git ([string]$File) {
    Say-Invocation $MyInvocation

    Start-Process -FilePath "$File" `
        -ArgumentList "/VERYSILENT /NORESTART /NOCANCEL /SP-", `
        "/CLOSEAPPLICATIONS /RESTARTAPPLICATIONS", `
        "/COMPONENTS='icons,ext\reg\shellhere,assoc,assoc_sh'"
}
# End Helpers =================================================================

# Main Section ================================================================
Say-Green "`n=== Git Installation ==="
# Testing if git already installed
if ($(Test-CommandInPath -Cmd "git.exe" -Silent)) {
    return
}

$CLIArchitecture = Get-CLIArchitecture-From-Architecture $Architecture
$DownloadLink = Get-Download-Link $CLIArchitecture
$ScriptName = $MyInvocation.MyCommand.Name

if ($DryRun) {
    Say "Payload URLs:"
    Say "Primary named payload URL: $DownloadLink"
    $RepeatableCommand = ".\$ScriptName -Architecture $CLIArchitecture"
    foreach ($key in $MyInvocation.BoundParameters.Keys) {
        if (-not (@("Architecture", "DryRun") -contains $key)) {
            $RepeatableCommand += " -$key `"$($MyInvocation.BoundParameters[$key])`""
        }
    }
    Say "Repeatable invocation: $RepeatableCommand"
    return
}

$installDrive = $((Get-Item $env:ProgramFiles).PSDrive.Name);
$diskInfo = Get-PSDrive -Name $installDrive
if ($diskInfo.Free / 1MB -le 800) {
    Say "There is not enough disk space on drive ${installDrive}:"
    return
}

$FileInstaller = ($DownloadLink -split "/" | Select-Object -Last 1)
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
    Say-Red "Could not find: `"$DownloadLink`"."
    Say-Red @"
Refer to: https://github.com/git-for-windows/git/releases for information on
Git-For-Windows support
"@
    throw
}

Say "Git installation: $FileInstaller"
Install-Git $FileInstallerPath

Say "Git installation: Completed"
$env:Path += ";$env:ProgramFiles\Git\cmd"
[System.Environment]::SetEnvironmentVariable('path', $env:Path, "User")
Start-Sleep 2
return
