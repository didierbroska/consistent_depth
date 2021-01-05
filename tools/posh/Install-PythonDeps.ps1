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

$cwd = Get-Location
# End Config and Variables ====================================================

# Main Section ================================================================
Say-Green "`n=== Python Deps Installation ==="

pip install -U numpy==1.19.3 matplotlib pip
pip install --isolated -t ${HOME}\Desktop\python_deps numpy==1.19.3 matplotlib

Say "Python Deps installation: Completed"
Set-Location $cwd
Start-Sleep 2
return
