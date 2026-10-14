@echo off
setlocal enabledelayedexpansion

REM =============================================================================
REM build.bat - build the pocket-creature example (desktop/native, OpenGL).
REM
REM The example is its own CMake project: it builds the engine (yume_core) via
REM add_subdirectory and produces main.exe plus the compiled assets
REM (scene.scnb, sprite shaders, character01-Sheet.png/.ssm, anim.ys,
REM project.conf) side by side in
REM   build\pc\<config>\
REM which is also the working directory used when running, so the engine
REM resolves every relative asset path directly.
REM
REM Usage:
REM   build.bat [-c|--clean] [-r|--run] [-d|--debug|--release]
REM
REM YUME_ENGINE_DIR: engine repo root. Defaults to ..\..\yume-windows (sibling
REM layout: Projetos\yume-examples\pocket-creature next to Projetos\yume-windows).
REM Override by setting the env var, e.g. set "YUME_ENGINE_DIR=C:\path\to\yume-windows".
REM =============================================================================

REM Defaults
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
shift
goto parse_args
:end_parse

REM -------------------------
REM Build dir: build\pc\<config lowercased>
REM -------------------------
set CFG_LOWER=debug
if /i "%CONFIG%"=="Release" set CFG_LOWER=release
set BUILD_DIR=build\pc\%CFG_LOWER%

REM -------------------------
REM Clean
REM -------------------------
if %CLEAN%==1 (
    echo Cleaning %BUILD_DIR%...
    if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
)

echo Building pocket-creature [native, %CONFIG%]...
echo Engine: %YUME_ENGINE_DIR%

if not exist "%BUILD_DIR%\CMakeCache.txt" (
    set CC=gcc
    set CXX=g++
    REM The vcpkg manifest (SDL2/GLEW/Vulkan/dxc/spirv-cross) belongs to the
    REM engine, so point VCPKG_MANIFEST_DIR at the engine root to reuse it.
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
