[CmdletBinding()]
param (
    # [ValidateSet("x86", "amd64", "x64", IgnoreCase = $false)]
    # [string]$Architecture = "<auto>",
    [switch]$DryRun,
    [string]$ProxyAddress,
    [switch]$ProxyUseDefaultCredentials,
    [version]$Version = "4.5.0",
    [switch]$CudaSupport
)

. "$PSScriptRoot\utils.ps1"

# Configuration and Variables =================================================
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$opencv_repo = "https://github.com/opencv/opencv.git"
$opencv_path = "$env:TEMP\opencv"
$opencvcontrib_repo = "https://github.com/opencv/opencv_contrib.git"
$opencvcontrib_path = "$env:TEMP\opencv_contrib"
$cwd = Get-Location
# End Config and Variables ====================================================

# Helpers =====================================================================
function Get-Repo([version]$version, [string]$repo, [string]$output) {
    Say-Invocation $MyInvocation

    if (-not $(Test-Path $output)) {
        git.exe clone --depth 1 --branch $version $repo $output
        Set-Location $output
    }
}

function Build-OpenCV {
    New-Item -ItemType Directory "$opencv_path\build" `
        -ErrorAction SilentlyContinue
    Set-Location "$opencv_path\build"
    # $python_exe = $(pyenv which python)
    # $python_lib_version = (pyenv whence python).split('.')[0] + `
    #     (pyenv whence python).split('.')[1]
    # $python_lib_path = $(pyenv which python | split-path -Parent) + `
    #     "\libs\python$python_lib_version.lib"
    # $python_include_path = $(pyenv which python | split-path -Parent) + `
    #     "\include"
    # if (-not (Test-Path $python_lib_path)) {
    #     throw "Python lib not found !"
    # }
    $Toolchain = $(Test-CommandInSystem -Cmd "vcpkg.cmake" `
        -Path "${HOME}\.vcpkg")
    $cmake = Test-CommandInSystem -Cmd cmake.exe -Path 'C:\Program Files*\'
    # build C
    # $listAttributes = `
    #     " --build '$opencv_path\build'" + `
    #     " -DOPENCV_EXTRA_MODULES_PATH='..\opencv_contrib\modules'"
    $listAttributes = `
        " --build $opencv_path\build" + `
        " --config Release" + `
        " -CCMAKE_CONFIGURATION_TYPE=Release" + `
        " -DENABLE_SOLUTION_FOLDERS=ON" + `
        " -DENABLE_CXX11=1" + `
        " -DINSTALL_C_EXAMPLES=OFF" + `
        " -DBUILD_NEW_PYTHON_SUPPORT=ON" + `
        " -DBUILD_JAVA=OFF" + `
        " -DBUILD_opencv_java_bindings_generator=OFF" + `
        " -DBUILD_PYTHON_SUPPORT=ON" + `
        " -DBUILD_SHARED_LIBS=OFF" + `
        " -DBUILD_opencv_python2=no" + `
        " -DBUILD_opencv_python3=yes" + `
        " -DOPENCV_PYTHON3_VERSION=ON " + `
        " -DPYTHON3_EXECUTABLE=C:\Users\WDAGUtilityAccount\AppData\Local\Programs\Python\Python39\python.exe" + `
        " -DPYTHON3_LIBRARY=C:\Users\WDAGUtilityAccount\AppData\Local\Programs\Python\Python39\libs\python39.lib" + `
        " -DPYTHON3_INCLUDE_DIR=C:\Users\WDAGUtilityAccount\AppData\Local\Programs\Python\Python39\include" + `
        " -DPYTHON3_PACKAGES_PATH=C:\Users\WDAGUtilityAccount\AppData\Local\Programs\Python\Python39\Lib\site-packages"
        " -DOPENCV_EXTRA_MODULES_PATH=..\opencv_contrib\modules" + `
        " -DPYTHON3_NUMPY_INCLUDE_DIRS=C:\Users\WDAGUtilityAccount\AppData\Roaming\Python\Python39\site-packages\numpy\core\include" + `
        " -DWITH_CUDA=OFF" + `
        " -DCMAKE_TOOLCHAIN_FILE=${Toolchain}"

#     Say "Build command :`n$cmake $listAttributes $opencv_path"
    # Start-Process -wait -NoNewWindow -FilePAth $cmake `
    #     -ArgumentList "-B'build\'", `
    #     # "-H'$opencv_path\'", `
    #     "-DCMAKE_BUILD_TYPE='Release'", `
    #     "-DBUILD_opencv_world=ON", `
    #     "-DOPENCV_EXTRA_MODULES_PATH='..\opencv_contrib\modules\'", `
    #     "$opencv_path"
    # configure
    # . $cmake $listAttributes $opencv_path
    . $cmake --build $opencv_path\build --target INSTALL --config Release
}

# End Helpers =================================================================

# Main Section ================================================================
Say-Green "`n=== OpenCV Installation ==="
# if ($vcpkg = $(Test-CommandInSystem -Cmd "vcpkg.cmake" `
#             -Path "C:\Program Files*\" -Silent)) {
#     return $vcpkg
# }
# if ($vcpkg = $(Test-CommandInSystem -Cmd "vcpkg.cmake" `
#             -Path "${HOME}" -Silent)) {
#     return $vcpkg
# }


Get-Repo -version $Version -repo $opencv_repo `
    -output $opencv_path
Get-Repo -version $Version -repo $opencvcontrib_repo `
    -output $opencvcontrib_path


Say "Building OpenCV"
Build-OpenCV

Say "OpenCV installation: Completed"
Set-Location $cwd
Start-Sleep 2
return
