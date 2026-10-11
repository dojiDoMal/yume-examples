#!/usr/bin/env bash
# Runs inside the devkitPro MSYS2 bash shell (invoked from build.bat).
#
# Why a separate script: cmd.exe does not treat single quotes as a string
# delimiter, so a bash one-liner with ';' or '&&' passed via `bash -lc '...'`
# gets chopped by cmd's own parser. Keeping the shell logic in a file avoids
# all cross-shell quoting problems.
#
# Unlike the engine repo, this example has NO CMakePresets.json, so we cannot
# `cmake --preset switch`. Instead we configure with explicit -D flags: the
# devkitPro toolchain file, the build config, the engine root, and the host
# shader tools. The toolchain sets CMAKE_SYSTEM_NAME=NintendoSwitch, which the
# engine/example CMake uses to pick the libnx backend and the .nxs shader
# flavor, and to pack the runnable .nro.
#
# Inputs (exported by build.bat as environment variables, Windows-style paths):
#   MSYS2_CMAKE_WIN      - path to the MSYS2 cmake.exe (required by devkitPro)
#   HOST_DXC_WIN         - host dxc.exe that generates the .nxs GLSL
#   HOST_SPIRV_CROSS_WIN - host spirv-cross.exe
#   PROJECT_DIR_WIN      - example project root (source dir)
#   YUME_ENGINE_DIR_WIN  - engine repo root (pulled in via add_subdirectory)
#   BUILD_DIR_WIN        - per-config build dir (e.g. ...\build\switch\debug)
#   BUILD_CONFIG         - Debug | Release
set -euo pipefail

# Everything here runs under the MSYS2-driven CMake/make, which resolves paths
# as Unix (/c/...), including the shader-tool commands it shells out to. So use
# the Unix form for all of them -- a mixed Windows path (C:/...) from
# `cygpath -m` is seen by make as a nonexistent file ("No such file or
# directory"). MSYS2 happily executes a Windows .exe given its Unix path.
CMAKE="$(cygpath -u "$MSYS2_CMAKE_WIN")"
HOST_DXC_U="$(cygpath -u "$HOST_DXC_WIN")"
HOST_SPIRV_CROSS_U="$(cygpath -u "$HOST_SPIRV_CROSS_WIN")"
PROJECT_DIR_U="$(cygpath -u "$PROJECT_DIR_WIN")"
BUILD_DIR_U="$(cygpath -u "$BUILD_DIR_WIN")"
YUME_ENGINE_DIR_U="$(cygpath -u "$YUME_ENGINE_DIR_WIN")"

# The devkitPro CMake toolchain lives inside the MSYS2 tree. $DEVKITPRO is set
# in the login shell (the `-l` on the bash invocation sources the profile that
# exports it); default to the conventional mount point if it is missing.
#
DEVKITPRO_U="${DEVKITPRO:-/opt/devkitpro}"
TOOLCHAIN="${DEVKITPRO_U}/cmake/Switch.cmake"

# CMake's FindPkgConfig invokes pkg-config with --define-prefix, which makes
# pkg-config IGNORE the hard-coded `prefix=/opt/devkitpro/...` in the .pc and
# recompute it from the .pc file's own location -- in native Windows form
# (C:/devkitPro/...). The MSYS2 CMake then rejects that "C:/..." include dir as
# a relative path ("contains relative path in its INTERFACE_INCLUDE_DIRECTORIES")
# and the generate step fails. PKG_CONFIG_DONT_DEFINE_PREFIX tells pkg-config to
# honor the .pc's own prefix (the Unix /opt/devkitpro form) instead of
# recomputing it, so SDL2's include dirs come out absolute and consistent.
export PKG_CONFIG_DONT_DEFINE_PREFIX=1

if [ ! -f "$TOOLCHAIN" ]; then
    echo "devkitPro Switch toolchain not found at '$TOOLCHAIN'." >&2
    echo "Is devkitPro installed and \$DEVKITPRO set? (expected .../cmake/Switch.cmake)" >&2
    exit 1
fi

cd "$PROJECT_DIR_U"

# The host shader tools come from vcpkg's x64-mingw-dynamic triplet, so
# spirv-cross.exe / dxc.exe are dynamically linked against the MinGW runtime
# (libstdc++-6.dll, libgcc_s_seh-1.dll, libwinpthread-1.dll). The devkitPro
# login shell doesn't have that runtime on PATH, so the tools fail to load
# ("error while loading shared libraries: libstdc++-6.dll"). Prepend whichever
# MinGW bin dirs exist so the Windows loader can find those DLLs. Harmless if a
# given dir is absent. Override by exporting MINGW_BIN before running build.bat.
for _mingw in "${MINGW_BIN:-}" /c/mingw-w64/bin /c/msys64/ucrt64/bin /c/msys64/mingw64/bin; do
    if [ -n "$_mingw" ] && [ -d "$_mingw" ]; then
        PATH="$_mingw:$PATH"
    fi
done
export PATH

"$CMAKE" -G "Unix Makefiles" \
    -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN" \
    -DCMAKE_BUILD_TYPE="${BUILD_CONFIG:-Debug}" \
    -DYUME_ENGINE_DIR="$YUME_ENGINE_DIR_U" \
    -DHOST_DXC="$HOST_DXC_U" \
    -DHOST_SPIRV_CROSS="$HOST_SPIRV_CROSS_U" \
    -B "$BUILD_DIR_U"

# Building main_nro packs the linked ELF + the romfs staging dir (shaders,
# scene.scnb, cube.obj, project.conf) into the runnable homebrew. It depends on
# the `main` executable and `main_assets`, so this one target drives everything.
"$CMAKE" --build "$BUILD_DIR_U" --target main_nro

echo "Build done. NRO: $BUILD_DIR_U/main.nro"
