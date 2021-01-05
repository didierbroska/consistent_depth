[CmdletBinding()]
param (
    [switch]$DryRun,
    [string]$ProxyAddress,
    [switch]$ProxyUseDefaultCredentials
)

. "$PSScriptRoot\utils.ps1"

# Configuration and Variables =================================================
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
# End Config and Variables ====================================================

# Main Section ================================================================
Say-Green "`n=== Python Deps Installation ==="
$pip = $(Test-CommandInSystem -Cmd "pip.exe" -path "${HOME}\AppData")

Start-Process -NoNewWindow -Wait -FilePath $pip -ArgumentList `
    "install --user -U numpy==1.19.3 matplotlib pip"
Start-Process -NoNewWindow -Wait -FilePath $pip -ArgumentList `
    "install --isolated -t ${HOME}\Desktop\python_deps", `
    "numpy==1.19.3 matplotlib"

Say "Python Deps installation: Completed"
return
