# Commons utils helpers
function New-Line{
    Write-Host "`n"
}

function Say([string]$msg) {
    Write-Host "$msg"
}

function Say-Red([string]$msg) {
    Write-Host "$msg" -ForegroundColor Red
}

function Say-Green([string]$msg) {
    Write-Host "$msg" -ForegroundColor Green
}

function Say-Yellow([string]$msg) {
    Write-Host "$msg" -ForegroundColor Yellow
}

function Say-Verbose([string]$msg) {
    Write-Verbose "$msg"
}

function Say-Debug([string]$msg) {
    Write-Debug "$msg"
}

function Say-Invocation($Invocation) {
    $command = $Invocation.MyCommand;
    $args = (($Invocation.BoundParameters.Keys |
            foreach { "-$_ `"$($Invocation.BoundParameters[$_])`"" }) -join " ")
    Say-Verbose "$command $args"
}

function Invoke-With-Retry(
    [ScriptBlock]$ScriptBlock,
    [int]$MaxAttempts = 3,
    [int]$SecondsBetweenAttempts = 1
    ) {
    $Attempts = 0

    while ($true) {
        try {
            return $ScriptBlock.Invoke()
        } catch {
            $Attempts++
            if ($Attempts -lt $MaxAttempts) {
                Start-Sleep $SecondsBetweenAttempts
            } else {
                throw
            }
        }
    }
}

function Load-Assembly([string] $Assembly) {
    try {
        Add-Type -Assembly $Assembly | Out-Null
    } catch {
        # On Nano Server, Powershell Core Edition is used.  Add-Type is unable
        # to resolve base class assemblies because they are not GAC'd.
        # Loading the base class assemblies is not unnecessary as the types
        # will automatically get resolved.
    }
}

function Get-Machine-Architecture() {
    Say-Invocation $MyInvocation

    # On PS x86, PROCESSOR_ARCHITECTURE reports x86 even on x64 systems.
    # To get the correct architecture, we need to use PROCESSOR_ARCHITEW6432.
    # PS x64 doesn't define this, so we fall back to PROCESSOR_ARCHITECTURE.
    # Possible values: amd64, x64, x86, arm64, arm

    if ( $ENV:PROCESSOR_ARCHITEW6432 -ne $null ) {
        return $ENV:PROCESSOR_ARCHITEW6432
    }

    return $ENV:PROCESSOR_ARCHITECTURE
}


function Get-CLIArchitecture-From-Architecture([string]$Architecture) {
    Say-Invocation $MyInvocation

    switch ($Architecture.ToLower()) {
        { $_ -eq "<auto>" } { return Get-CLIArchitecture-From-Architecture $(Get-Machine-Architecture) }
        { ($_ -eq "amd64") -or ($_ -eq "x64") } { return "64-bit" }
        { $_ -eq "x86" } { return "32-bit" }
        default {
            throw "Architecture not supported. If you think this is a bug, report it at https://github.com/dotnet/sdk/issues"
        }
    }
}

function Test-Command([string]$cmd, [string]$path, [switch]$Silent, [switch]$MultiVersion) {
    Say "Verify if $cmd is installed..."
    if ($exe = $(Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Say "$cmd founded in path."
        return $exe
    } else {
        Say-Red "$cmd not founded in path." -ForegroundColor Yellow
    }
    if ($exe = $(Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue -Include $cmd)) {
        Say "$cmd is founded in system." -ForegroundColor Yellow
        if (-not $MultiVersion) {
            if ($exe -is [system.array]) {
                Write-Debug $exe[0]
                return $exe[0]
            }
        }
        Say-Debug $exe
        return $exe
    }
    Say-Red "$cmd not founded in system."
    if ($Silent) {
        return $false
    }
    throw "Please install before !"
}

function Test-CommandInPath{
    param (
        [Parameter(Mandatory=$true)]
        [string]$Cmd,
        [switch]$Silent
    )
    if ($(Get-Command $Cmd -ErrorAction SilentlyContinue)){
        Say "$Cmd found in path."
        return $true
    }
    Say-Red "$Cmd not founded in path."
    if ($Silent) {
        return $false
    }
    throw "Please install before !"
}

function Test-CommandInSystem{
    param (
        [Parameter(Mandatory=$true)]
        [string]$Cmd,
        [string]$Path = "C:\",
        [switch]$Silent
    )
    $exe = $(Get-ChildItem $Path -Recurse `
        -ErrorAction SilentlyContinue -Include $Cmd)
    if ($exe) {
        Say "$Cmd founded in system."
        return $exe
    }
    Say-Red "$Cmd not founded in system."
    if ($Silent) {
        return $false
    }
    throw "Please install before !"
}

function GetHTTPResponse([Uri] $Uri) {
    Invoke-With-Retry(
        {

            $HttpClient = $null

            try {
                # HttpClient is used vs Invoke-WebRequest in order to support Nano Server which doesn't support the Invoke-WebRequest cmdlet.
                Load-Assembly -Assembly System.Net.Http

                if (-not $ProxyAddress) {
                    try {
                        # Despite no proxy being explicitly specified, we may still be behind a default proxy
                        $DefaultProxy = [System.Net.WebRequest]::DefaultWebProxy;
                        if ($DefaultProxy -and (-not $DefaultProxy.IsBypassed($Uri))) {
                            $ProxyAddress = $DefaultProxy.GetProxy($Uri).OriginalString
                            $ProxyUseDefaultCredentials = $true
                        }
                    } catch {
                        # Eat the exception and move forward as the above code is an attempt
                        #    at resolving the DefaultProxy that may not have been a problem.
                        $ProxyAddress = $null
                        Say-Verbose("Exception ignored: $_.Exception.Message - moving forward...")
                    }
                }

                if ($ProxyAddress) {
                    $HttpClientHandler = New-Object System.Net.Http.HttpClientHandler
                    $HttpClientHandler.Proxy = New-Object System.Net.WebProxy -Property @{Address = $ProxyAddress; UseDefaultCredentials = $ProxyUseDefaultCredentials }
                    $HttpClient = New-Object System.Net.Http.HttpClient -ArgumentList $HttpClientHandler
                } else {

                    $HttpClient = New-Object System.Net.Http.HttpClient
                }
                # Default timeout for HttpClient is 100s.  For a 50 MB download this assumes 500 KB/s average, any less will time out
                # 20 minutes allows it to work over much slower connections.
                $HttpClient.Timeout = New-TimeSpan -Minutes 20
                $Response = $HttpClient.GetAsync("${Uri}").Result
                if (($Response -eq $null) -or (-not ($Response.IsSuccessStatusCode))) {
                    # The feed credential is potentially sensitive info. Do not log FeedCredential to console output.
                    $ErrorMsg = "Failed to download $Uri."
                    if ($Response -ne $null) {
                        $ErrorMsg += "  $Response"
                    }

                    throw $ErrorMsg
                }

                return $Response
            } finally {
                if ($HttpClient -ne $null) {
                    $HttpClient.Dispose()
                }
            }
        }
    )
}

function DownloadFile($Source, [string]$OutPath) {
    # TODO add write-progress
    if ($Source -notlike "http*") {
        #  Using System.IO.Path.GetFullPath to get the current directory
        #    does not work in this context - $pwd gives the current directory
        if (![System.IO.Path]::IsPathRooted($Source)) {
            $Source = $(Join-Path -Path $pwd -ChildPath $Source)
        }
        $Source = Get-Absolute-Path $Source
        Say "Copying file from $Source to $OutPath"
        Copy-Item $Source $OutPath
        return
    }

    $Stream = $null

    try {
        $Response = GetHTTPResponse -Uri $Source
        $Stream = $Response.Content.ReadAsStreamAsync().Result
        $File = [System.IO.File]::Create($OutPath)
        $Stream.CopyTo($File)
        $File.Close()
    } finally {
        if ($Stream -ne $null) {
            $Stream.Dispose()
        }
    }
}
