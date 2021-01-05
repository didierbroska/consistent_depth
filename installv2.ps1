[CmdletBinding()]
param (
    [ValidateSet("x86", "amd64", "x64", IgnoreCase = $false)]
    [string]$Architecture = "<auto>",
    [ValidateSet("windows", "linux", "macOS")]
    [string]$Plateform = "windows",
    [switch]$DryRun,
    [string]$ProxyAddress,
    [switch]$ProxyUseDefaultCredentials
)

# Configuring script ==========================================================
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Import helpers===============================================================
. "$PSScriptRoot\tools\posh\utils.ps1"


# Main Section ================================================================

Say-Green "Welcome to Consistent Depth project !"
Say-Green "====================================="
Say ""
Say-Yellow "Install dependencies"
Say-Yellow "--------------------"


# Get MS Buildtools
& "$PSScriptRoot\tools\posh\Install-MsBuildTools.ps1"
# Get VCPKG for toolchain
# & "$PSScriptRoot\tools\posh\Install-Vcpkg.ps1"


# Python installation
& "$PSScriptRoot\tools\posh\Install-Python.bat"
# $env:Path = [System.Environment]::GetEnvironmentVariable(
#     "Path", "Machine") + `
#     ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
# & "$PSScriptRoot\tools\posh\Install-PythonDeps.ps1"

& "$PSScriptRoot\tools\posh\Install-oneAPI.bat"


# echo "finished"
# & "$PSScriptRoot\tools\build_opencv_CPU_MKL_TBB.bat"
