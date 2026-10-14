#!/usr/bin/env bash
# Runs inside the devkitPro MSYS2 bash shell (invoked from build.bat 3ds target).
#
# Why a separate script: cmd.exe does not treat single quotes as a string
# delimiter, so a bash one-liner with ';' or '&&' passed via `bash -lc '...'`
# gets chopped by cmd's own parser. Keeping the shell logic in a file avoids all
# cross-shell quoting problems. Mirrors build_switch.sh.
#
# Unlike the Switch, the 3DS does NOT need the host shader tools (dxc /
# spirv-cross): PICA200 shaders are assembled from *.vxs.pica by `picasso`
# (devkitPro), driven by the engine's yume_compile_pica_shaders(). So there are
# no HOST_DXC / HOST_SPIRV_CROSS inputs here.
#
# Inputs (exported by build.bat as environment variables, Windows-style paths):
#   MSYS2_CMAKE_WIN      - path to the MSYS2 cmake.exe (required by devkitPro)
#   PROJECT_DIR_WIN      - example project root (source dir)
#   YUME_ENGINE_DIR_WIN  - engine repo root (pulled in via add_subdirectory)
#   BUILD_DIR_WIN        - per-config build dir (e.g. ...\build\3ds\debug)
#   BUILD_CONFIG         - Debug | Release
set -euo pipefail

CMAKE="$(cygpath -u "$MSYS2_CMAKE_WIN")"
PROJECT_DIR_U="$(cygpath -u "$PROJECT_DIR_WIN")"
BUILD_DIR_U="$(cygpath -u "$BUILD_DIR_WIN")"
YUME_ENGINE_DIR_U="$(cygpath -u "$YUME_ENGINE_DIR_WIN")"

# The devkitPro CMake toolchain lives inside the MSYS2 tree. $DEVKITPRO is set in
# the login shell (the `-l` on the bash invocation sources the profile that
# exports it); default to the conventional mount point if it is missing. The 3DS
# toolchain sets CMAKE_SYSTEM_NAME=Horizon, which the engine/example CMake uses
# to pick the Citro3D backend, the .shbin shader flavor, and the .3dsx packing.
DEVKITPRO_U="${DEVKITPRO:-/opt/devkitpro}"
TOOLCHAIN="${DEVKITPRO_U}/cmake/3DS.cmake"

# Same pkg-config caveat as the Switch build (honor the .pc's own Unix prefix
# instead of recomputing a C:/... one that MSYS2 CMake would reject).
export PKG_CONFIG_DONT_DEFINE_PREFIX=1

if [ ! -f "$TOOLCHAIN" ]; then
    echo "devkitPro 3DS toolchain not found at '$TOOLCHAIN'." >&2
    echo "Is devkitPro installed and \$DEVKITPRO set? (expected .../cmake/3DS.cmake)" >&2
    exit 1
fi

cd "$PROJECT_DIR_U"

# The host tool scene_compiler.exe is built with the MSYS2 UCRT64/MinGW gcc, so
# it is dynamically linked against the MinGW runtime (libstdc++-6.dll,
# libgcc_s_seh-1.dll, libwinpthread-1.dll). The devkitPro login shell does not
# have that runtime on PATH, so the tool fails to load ("error while loading
# shared libraries: libstdc++-6.dll") when the build invokes it to compile the
# scene. Prepend whichever MinGW bin dirs exist so the Windows loader finds
# those DLLs. Harmless if a dir is absent. Override via MINGW_BIN before build.
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
    -B "$BUILD_DIR_U"

# Building main_3dsx packs the linked ELF + the romfs staging dir (flat.vxs.shbin,
# scene.scnb, cube.obj, rotate.ys, project.conf) into the runnable homebrew. It
# depends on `main` and `main_assets`, so this one target drives everything.
"$CMAKE" --build "$BUILD_DIR_U" --target main_3dsx

echo "Build done. 3DSX: $BUILD_DIR_U/main.3dsx"
