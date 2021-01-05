[CmdletBinding()]
param (
    [ValidateSet("x86", "amd64", "x64", IgnoreCase = $false)]
    [string]$Architecture = "amd64",
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
Clear-Host
Say-Green "Welcome to Consistent Depth project !"
Say-Green "====================================="
Say ""
Say-Yellow "Install dependencies"
Say-Yellow "--------------------"

# Install MS Buildtools
& "$PSScriptRoot\tools\win\Install-MsBuildTools.ps1"

# Get VCPKG for toolchain
& "$PSScriptRoot\tools\win\Install-Git.ps1"
& "$PSScriptRoot\tools\posh\Install-Vcpkg.ps1"

# Install python and deps
& "$PSScriptRoot\tools\win\Install-Python.ps1" -Architecture $Architecture
& "$PSScriptRoot\tools\win\Install-PythonDeps.ps1"

# Install Intel oneAPI BaseKit
& "$PSScriptRoot\tools\win\Install-Intel-oneAPI.ps1"

# Build OpenCV
& "$PSScriptRoot\tools\win\Build-OpenCV.ps1" -TBB -MKL
