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

$GithubFeed = "https://github.com/pyenv-win/pyenv-win.git"
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

function Install-Pyenv {
    [System.Environment]::SetEnvironmentVariable(
        'PYENV',$env:USERPROFILE + "\.pyenv\pyenv-win\","User"
        )
    [System.Environment]::SetEnvironmentVariable(
        'PYENV_HOME',$env:USERPROFILE + "\.pyenv\pyenv-win\","User"
        )
    [System.Environment]::SetEnvironmentVariable('path', ${HOME} + "\.pyenv\pyenv-win\bin;" + ${HOME} + "\.pyenv\pyenv-win\shims;" + $env:Path,"User")
}

# End Helpers =================================================================

# Main Section ================================================================
Say-Green "`n=== Pyenv Installation ==="
if ($(Test-CommandInSystem -Cmd "pyenv.bat" -Path "${HOME}\" -Silent)) {
    return
}

Get-Repo -repo $GithubFeed -output "${HOME}\.pyenv"


Say "Pyenv var env setup"
Install-Pyenv

Say "Pyenv installation: Completed"
Set-Location $cwd
Start-Sleep 2
return
