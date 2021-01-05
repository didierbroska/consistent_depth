[CmdletBinding()]
param (
    [ValidateSet("x86", "intel64", "x64", IgnoreCase = $false)]
    [string]$Architecture = "intel64",
    [switch]$DryRun,
    [string]$ProxyAddress,
    [switch]$ProxyUseDefaultCredentials,
    [Version]$Version = "4.5.0",
    [Version]$PythonVersion = "3.9.1",
    [switch]$Cuda,
    [switch]$TBB,
    [switch]$MKL
)

. "$PSScriptRoot\utils.ps1"

# Configuration and Variables =================================================
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$OpenCVFeed = "https://github.com/opencv/opencv/archive/${Version}.zip"
$OpenCVContribFeed = "https://github.com/opencv/opencv_contrib/archive/${Version}.zip"
# End Config and Variables ====================================================

# Helpers =====================================================================

function Build-Sources ([string]$Path) {
    Say-Invocation $MyInvocation
    New-Item -ItemType Directory -Path "$Path\build" `
        -ErrorAction SilentlyContinue

    $env:INCLUDE = ""
    $env:LIB = ""
    $env:PKG_CONFIG_PATH = ""
    $env:CPATH = ""
    $env:NLSPATH = ""

    if ($Cuda) {
        $Cuda = "ON"
    } else {
        $Cuda = "OFF"
    }

    $mkl_path = "${env:ProgramFiles(x86)}\Intel\oneAPI\mkl\latest"
    if ($MKL -and $(Test-Path -Path  $mkl_path)) {
        $MKL = "ON"
        $MKL_MULTITHREAD = "ON"
        Invoke-CmdScript -Path "$mkl_path\env\vars.bat" -ArgumentList $Architecture
    } else {
        $MKL = "OFF"
        $MKL_MULTITHREAD = "OFF"
    }

    $tbb_path = "${env:ProgramFiles(x86)}\Intel\oneAPI\tbb\latest"
    if ($TBB -and $(Test-Path -Path  $tbb_path)) {
        $TBB = "ON"
        Invoke-CmdScript -Path "$tbb_path\env\vars.bat" -ArgumentList $Architecture
    } else {
        $TBB = "OFF"
    }

    $Toolchain = $(Test-CommandInSystem -Cmd "vcpkg.cmake" `
        -Path "${HOME}\.vcpkg")

    $cmake = $(Test-CommandInSystem -Cmd "cmake.exe" -Path 'C:\Program Files*\')
    $ver = "${PythonVersion}".Split(".")[0] + "${PythonVersion}".Split(".")[1]
    $python_path = "${HOME}\AppData\Local\Programs\Python\Python${ver}"
    $python_exe = "${python_path}\python.exe"
    $python_lib = "${python_path}\libs\python${ver}.lib"
    $python_include = "${python_path}\include"
    $python_package = "${python_path}\Lib\site-packages"
    $python_numpy = "${python_package}\numpy\core\include"


    $arguments = `
        " -G `"Visual Studio 16 2019`"" + `
        " -DBUILD_SHARED_LIBS=OFF" + `
        " -DENABLE_SOLUTION_FOLDERS=ON" + `
        " -DBUILD_JAVA=OFF" + `
        " -DBUILD_opencv_java_bindings_generator=OFF" + `
        " -DBUILD_opencv_python_tests=OFF" + `
        " -DBUILD_opencv_python_bindings_generator=ON" + `
        " -DINSTALL_PYTHON_EXAMPLES=OFF" + `
        " -DBUILD_opencv_python3=yes" + `
        " -DBUILD_NEW_PYTHON_SUPPORT=ON" + `
        " -DOPENCV_PYTHON3_VERSION=ON" + `
        " -DPYTHON3_EXECUTABLE=`"${python_exe}`"" + `
        " -DPYTHON3_LIBRARY=`"${python_lib}`"" + `
        " -DPYTHON3_INCLUDE_DIR=`"${python_include}`"" + `
        " -DPYTHON3_PACKAGES_PATH=`"${python_package}`"" + `
        " -DPYTHON3_NUMPY_INCLUDE_DIRS=`"${python_numpy}`"" + `
        " -DWITH_MKL=${MKL}" + `
        " -DMKL_USE_MULTITHREAD=${MKL_MULTITHREAD}" + `
        " -DWITH_TBB=${TBB}" + `
        " -DBUILD_opencv_world=ON" + `
        " -DCMAKE_TOOLCHAIN_FILE=${Toolchain}" + `
        " -DOPENCV_EXTRA_MODULES_PATH=`"..\..\opencv_contrib-${Version}\modules`""

    $cwd = Get-Location
    Set-Location "$Path\build"
    # Say $arguments
    . $cmake $arguments $path
    # Start-Process -NoNewWindow -Wait -FilePath "$cmake" `
    #     -ArgumentList $arguments
    # Set-Location $cwd
}
# End Helpers =================================================================

# Main Section ================================================================
Say-Green "`n=== OpenCV Installation ==="
# Testing if OpenCV is already Downloaded and Archive Extract
if ( -not $(Test-CommandInSystem -Cmd "opencv-${Version}.zip" `
            -Path "${HOME}\Downloads" -Silent)) {
    Say "Download OpenCV ${Version}"
    $DownloadLink = $OpenCVFeed
    $DownloadFailed = $false
    Say "Downloading link: $DownloadLink"
    try {
        DownloadFile -Source $DownloadLink `
            -OutPath "${HOME}\Downloads\opencv-${Version}.zip"
    } catch {
        Say "Cannot download: $DownloadLink"
        $DownloadFailed = $true
    }
    if ($DownloadFailed) {
        throw "Error download: `"$DownloadLink`""
    }
} else {
    Say "OpenCV ${Version} is already downloaded."
}
if ( -not (Test-Path -Path "${HOME}\Downloads\opencv-${Version}" `
            -ErrorAction SilentlyContinue)) {
    Say "Extract archive OpenCV ${Version}"
    Expand-Archive -Path "${HOME}\Downloads\opencv-${Version}.zip" `
        -DestinationPath "${HOME}\Downloads"
} else {
    Say "OpenCV ${Version} is already extracted."
}

# Testing if OpenCV-contrib is already Downloaded and Archive Extract
if ( -not $(Test-CommandInSystem -Cmd "opencv_contrib-${Version}.zip" `
            -Path "${HOME}\Downloads" -Silent)) {
    Say "Download OpenCV Contrib ${Version}"
    $DownloadLink = $OpenCVContribFeed
    $DownloadFailed = $false
    Say "Downloading link: $DownloadLink"
    try {
        DownloadFile -Source $DownloadLink `
            -OutPath "${HOME}\Downloads\opencv_contrib-${Version}.zip"
    } catch {
        Say "Cannot download: $DownloadLink"
        $DownloadFailed = $true
    }
    if ($DownloadFailed) {
        throw "Error download: `"$DownloadLink`""
    }
} else {
    Say "OpenCV Contrib ${Version} is already downloaded."
}
if ( -not (Test-Path -Path "${HOME}\Downloads\opencv_contrib-${Version}" `
            -ErrorAction SilentlyContinue)) {
    Say "Extract archive OpenCV contrib ${Version}"
    Expand-Archive -Path "${HOME}\Downloads\opencv_contrib-${Version}.zip" `
        -DestinationPath "${HOME}\Downloads"
} else {
    Say "OpenCV Contrib ${Version} is already extracted."
}


Say "Build OpenCV ..."
Build-Sources "${HOME}\Downloads\opencv-${Version}"

Say "OpenCV Build: Finished."
return
