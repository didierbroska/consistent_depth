[CmdletBinding()]
param (
    [Parameter()]
    [version]$Version = "4.5.0",
    [string[]]$Modules,
    [string]$path = "$env:TEMP",
    [version]$PythonVersion = "3.8.6"
)

# Settings
$ErrorActionPreference = "Stop"
$cwd = Get-Location


# Variables URIs and Paths
$uri = "https://github.com/opencv/opencv.git"
$uri_contrib = "https://github.com/opencv/opencv_contrib.git"
$opencv = $path + "\opencv"
$opencv_contrib = $path + "\opencv-contrib"


# Dependencies
$git = "git.exe"
$cmake = "cmake.exe"
$vcpkg_toolchain = "vcpkg.cmake"
$cuda = "deviceQuery.exe"
$msbuild = "msbuild.exe"
$pyenv = "pyenv.bat"

# Helpers functions
function Get-Repo([version]$version, [string]$repo, [string]$output) {
    if (Test-Path $output) {
        Remove-Item $output -Force -Recurse
    }
    .$git clone $repo $output
    Set-Location $output
    . $git checkout $version
}

function Test-Command([string]$cmd, [string]$path, [switch]$Silent, [switch]$MultiVersion) {
    Write-Host "Verify if $cmd in path..."
    if ($exe = $(Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Host "$cmd founded in path!"
        return $exe
    } else {
        Write-Host "$cmd not founded in path ..."
        Write-Host "Searching in system ... $path"
    }
    if ($exe = $(Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue -Include $cmd)) {
        Write-Host "$cmd is founded !"
        if (-not $MultiVersion) {
            if ($exe -is [system.array]) {
                Write-Debug $exe[0]
                return $exe[0]
            }
        }
        Write-Debug $exe
        return $exe
    }
    if ($Silent) {
        return $false
    }
    throw "${cmd} not found ! Please install before !"
}

function Get-CudaInfo($cuda) {
    # $cudaVersion = @()
    if ($cuda -is [system.array]) {
        # $Versions = @()
        # TODO select versions
    } else {
        $cuda = $($cuda | Split-Path -Parent | Split-Path -Parent | Split-Path -Parent)
        $v = $cuda | Split-Path -Leaf
        Write-Host "Cuda $v is detected !"
        return $cuda
    }
}


# Main section
Clear-Host
Write-Host "Install - OpenCV v$version" -ForegroundColor Green

## Check dependencies
Write-Host "`n=== Check dependencies ===" -ForegroundColor Green
$git = Test-Command $git -path "C:\Program Files*\"
. $git --version

$cmake = Test-Command $cmake -path "C:\Program Files*\"
. $cmake --version

Test-Command $msbuild -path "C:\Program Files*\" >> $null

if (-not ($vcpkg = $(Test-Command $vcpkg_toolchain -path "C:\Program Files*\" -Silent))) {
    $vcpkg = $(Test-Command $vcpkg_toolchain -path "$env:HOME")
}

if ($cuda = Test-Command $cuda -Silent -MultiVersion) {
    $cuda = Get-CudaInfo $cuda
} else {
    Write-Host "Cuda not supported by host." -ForegroundColor Yellow
}

## Get opencv sources
Write-Host "`n=== Download OpenCV sources ===" -ForegroundColor Green
Get-Repo $version $uri $opencv
Get-Repo $version $uri_contrib $opencv_contrib

## Prepare to build
Write-Host "`n=== Prepare to build ===" -ForegroundColor Green
cd $opencv
mkdir "build"
cd "build"
. $cmake -DOPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules ..
. $cmake -LH >> "$cwd\opencv-cmake-build-options.txt"

Set-Location $cwd
