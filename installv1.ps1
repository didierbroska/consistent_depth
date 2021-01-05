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

# Check or get git
& "$PSScriptRoot\tools\posh\Install-Git.ps1"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + `
    ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Get MS Buildtools
& "$PSScriptRoot\tools\posh\Install-MsBuildTools.ps1"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + `
    ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Get VCPKG for toolchain
& "$PSScriptRoot\tools\posh\Install-Vcpkg.ps1"
$env:Path = [System.Environment]::GetEnvironmentVariable(
    "Path", "Machine") + `
    ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Get Pyenv-Win
# & "$PSScriptRoot\tools\posh\Install-Pyenv.ps1"
# $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + `
#     ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Get Python
# & "$PSScriptRoot\tools\posh\Install-Python.ps1"
& "$PSScriptRoot\tools\posh\Install-PythonDeps.ps1"

# Get and build opencv
& "$PSScriptRoot\tools\posh\Build-OpenCV.ps1"
