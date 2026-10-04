@echo off
setlocal enabledelayedexpansion

REM =============================================================================
REM build.bat - build the rotating-cube example (Caminho 1 layout).
REM
REM The example is its own CMake project: it builds the engine (yume_core) via
REM add_subdirectory and produces main.exe plus the compiled assets
REM (scene.scnb, shaders, cube.obj, project.conf) side by side in
REM   build\<target>\<config>\
REM which is also the working directory used when running, so the engine
REM resolves every relative asset path directly.
REM
REM Usage:
REM   build.bat [-c|--clean] [-r|--run] [-t|--target native] [-d|--debug|--release]
REM
REM YUME_ENGINE_DIR: engine repo root. Defaults to ..\..\yume-windows (sibling
REM layout: Projetos\yume-examples\rotating-cube next to Projetos\yume-windows).
REM Override by setting the env var, e.g. set "YUME_ENGINE_DIR=C:\path\to\yume-windows".
REM =============================================================================

REM Defaults
set TARGET=native
set CLEAN=0
set RUN=0
set CONFIG=Debug

if not defined YUME_ENGINE_DIR set "YUME_ENGINE_DIR=%~dp0..\..\yume-windows"

REM -------------------------
REM Parse arguments
REM -------------------------
:parse_args
if "%~1"=="" goto end_parse
if /i "%~1"=="-c" set CLEAN=1
if /i "%~1"=="--clean" set CLEAN=1
if /i "%~1"=="-r" set RUN=1
if /i "%~1"=="--run" set RUN=1
if /i "%~1"=="-d" set CONFIG=Debug
if /i "%~1"=="--debug" set CONFIG=Debug
if /i "%~1"=="--release" set CONFIG=Release
if /i "%~1"=="-t" set TARGET=%~2& shift
if /i "%~1"=="--target" set TARGET=%~2& shift
shift
goto parse_args
:end_parse

REM -------------------------
REM Build dir: build\<target>\<config lowercased>
REM -------------------------
set CFG_LOWER=debug
if /i "%CONFIG%"=="Release" set CFG_LOWER=release

if /i "%TARGET%"=="native" set BUILD_DIR=build\pc\%CFG_LOWER%
if /i "%TARGET%"=="web"    set BUILD_DIR=build\web\%CFG_LOWER%
if /i "%TARGET%"=="switch" set BUILD_DIR=build\switch\%CFG_LOWER%

REM -------------------------
REM Clean
REM -------------------------
if %CLEAN%==1 (
    echo Cleaning %BUILD_DIR%...
    if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
)

REM -------------------------
REM Desktop build
REM -------------------------
if /i "%TARGET%"=="native" (
    echo Building rotating-cube [native, %CONFIG%]...
    echo Engine: %YUME_ENGINE_DIR%

    if not exist "%BUILD_DIR%\CMakeCache.txt" (
        set CC=gcc
        set CXX=g++
        REM The vcpkg manifest (vcpkg.json: SDL2/GLEW/Vulkan/dxc/spirv-cross)
        REM belongs to the engine, since those are the engine's dependencies.
        REM In manifest mode vcpkg reads it from the SOURCE dir, which is now
        REM this example, so point VCPKG_MANIFEST_DIR at the engine root to
        REM reuse the engine's manifest instead of duplicating it here.
        set "VCPKG_DEFAULT_TRIPLET=x64-mingw-dynamic"
        set "VCPKG_DEFAULT_HOST_TRIPLET=x64-mingw-dynamic"
        cmake -G "MinGW Makefiles" ^
            -DCMAKE_MAKE_PROGRAM=C:/msys64/ucrt64/bin/mingw32-make.exe ^
            -DCMAKE_C_COMPILER=C:/msys64/ucrt64/bin/gcc.exe ^
            -DCMAKE_CXX_COMPILER=C:/msys64/ucrt64/bin/g++.exe ^
            -DCMAKE_TOOLCHAIN_FILE=C:/Portable/vcpkg/scripts/buildsystems/vcpkg.cmake ^
            -DVCPKG_TARGET_TRIPLET=x64-mingw-dynamic ^
            -DVCPKG_HOST_TRIPLET=x64-mingw-dynamic ^
            -DVCPKG_MANIFEST_MODE=ON ^
            -DVCPKG_MANIFEST_DIR="%YUME_ENGINE_DIR%" ^
            -DCMAKE_BUILD_TYPE=%CONFIG% ^
            -B "%BUILD_DIR%"
        if errorlevel 1 (
            echo Build configuration failed!
            exit /b 1
        )
    )

    cmake --build "%BUILD_DIR%"
    if errorlevel 1 (
        echo Build failed!
        exit /b 1
    )

    if %RUN%==1 (
        echo Running...
        pushd "%BUILD_DIR%"
        main.exe
        popd
    ) else (
        echo Build completed. Executable + assets in %BUILD_DIR%
    )
    goto :eof
)

REM -------------------------
REM Switch build
REM -------------------------
if /i "%TARGET%"=="switch" goto build_switch

echo Target "%TARGET%" is not supported by this script yet ^(native, switch^).
exit /b 1

:build_switch
echo Building rotating-cube [switch, %CONFIG%]...
echo Engine: %YUME_ENGINE_DIR%

REM The Switch toolchain (aarch64-none-elf-gcc, elf2nro, make, ...) lives in the
REM devkitPro MSYS2 environment, not in the Windows PATH. So the build runs
REM inside a devkitPro bash login shell. DEVKITPRO_BIN points at that MSYS2's
REM usr\bin (where bash.exe / cygpath.exe live).
if not defined DEVKITPRO_BIN (
    echo DEVKITPRO_BIN is not set. Point it at devkitPro's msys2\usr\bin ^(e.g. c:\devkitPro\msys2\usr\bin^).
    exit /b 1
)

REM Host shader tools (Windows .exe's) that generate the .nxs GLSL. They run on
REM the host during the build, not on the Switch. Override by setting HOST_DXC /
REM HOST_SPIRV_CROSS before running build.bat.
if not defined HOST_DXC set "HOST_DXC=C:\Portable\dxc\bin\x64\dxc.exe"
if not defined HOST_SPIRV_CROSS set "HOST_SPIRV_CROSS=C:\Portable\spirv-cross\bin\spirv-cross.exe"

REM The devkitPro toolchain (dkp-initialize-path.cmake) refuses to run unless it
REM is driven by the CMake installed inside MSYS2. The Windows CMake on PATH
REM (C:\Portable\...) trips that check, so invoke the MSYS2 cmake by absolute
REM path instead of relying on PATH order (the login .bashrc reorders it).
set "MSYS2_CMAKE_WIN=%DEVKITPRO_BIN%\cmake.exe"
if not exist "%MSYS2_CMAKE_WIN%" (
    echo MSYS2 cmake not found at "%MSYS2_CMAKE_WIN%". Install it with: pacman -S cmake
    exit /b 1
)

REM Pass everything to bash via the environment. The actual build logic lives
REM in build_switch.sh so the bash invocation carries no shell operators (; &&)
REM or nested quotes for cmd.exe to mangle -- cmd does NOT treat single quotes
REM as a string delimiter, so an inline one-liner would get chopped at && / ;.
REM Unlike the engine, this example has no CMakePresets.json, so the script
REM configures CMake with explicit -D flags; it needs the engine root, the
REM build config, and the per-config build dir on top of the shader tool paths.
set "HOST_DXC_WIN=%HOST_DXC%"
set "HOST_SPIRV_CROSS_WIN=%HOST_SPIRV_CROSS%"
set "PROJECT_DIR_WIN=%CD%"
set "YUME_ENGINE_DIR_WIN=%YUME_ENGINE_DIR%"
set "BUILD_DIR_WIN=%CD%\%BUILD_DIR%"
set "BUILD_CONFIG=%CONFIG%"

"%DEVKITPRO_BIN%\bash.exe" -l "%CD%\build_switch.sh"
if errorlevel 1 (
    echo Build failed!
    exit /b 1
)
echo Build completed. NRO in %BUILD_DIR%\main.nro
goto :eof
