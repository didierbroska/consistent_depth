[CmdletBinding()]
param (
    [switch]$DryRun,
    [string]$ProxyAddress,
    [switch]$ProxyUseDefaultCredentials,
    [string]$Version = "2011.1.0.2664"
)

. "$PSScriptRoot\utils.ps1"

# Configuration and Variables =================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$openAPIbootstrap = "${HOME}\Downloads\intel_oneapi_basekit_v${Version}\bootstrapper.exe"
# End Config and Variables ====================================================

# Helpers =====================================================================
function Install-oneAPI ([string]$File) {
    Say-Invocation $MyInvocation

    Start-Process -NoNewWindow -Wait -FilePath "$File" `
        -ArgumentList "--cli --eula=accept"
}
# End Helpers =================================================================

# Main Section ================================================================
Say-Green "`n=== Intel oneAPI Installation ==="
# FIXME Testing if already installed
# if ($msbuildtools = $(Test-CommandInSystem -Cmd "VsDevCmd.bat" `
#             -path "C:\Program Files*\" -Silent)) {
#     return $msbuildtools
# }


Say "Intel oneAPI installation: $openAPIbootstrap"
Install-oneAPI $openAPIbootstrap

Say "Intel oneAPI installation: Finished."
return
