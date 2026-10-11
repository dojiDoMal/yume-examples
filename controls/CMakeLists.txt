cmake_minimum_required(VERSION 3.10)
project(rotating_cube LANGUAGES C CXX)

# -----------------------------------------------------------------------------
# Locate the Yume engine.
#
# YUME_ENGINE_DIR points at the engine repo root (the folder with the engine's
# CMakeLists.txt). Pass it on the configure line, e.g.
#   cmake -DYUME_ENGINE_DIR=../../yume-windows -B build/pc/debug
# It also falls back to the YUME_ENGINE_DIR environment variable. The default
# assumes the sibling layout Projetos/yume-examples/rotating-cube next to
# Projetos/yume-windows, so "../../yume-windows" resolves to the engine root.
# -----------------------------------------------------------------------------
if(NOT YUME_ENGINE_DIR AND DEFINED ENV{YUME_ENGINE_DIR})
    set(YUME_ENGINE_DIR "$ENV{YUME_ENGINE_DIR}")
endif()
if(NOT YUME_ENGINE_DIR)
    set(YUME_ENGINE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../yume-windows")
endif()
get_filename_component(YUME_ENGINE_DIR "${YUME_ENGINE_DIR}" ABSOLUTE)

if(NOT EXISTS "${YUME_ENGINE_DIR}/CMakeLists.txt")
    message(FATAL_ERROR
        "Yume engine not found at '${YUME_ENGINE_DIR}'. Pass -DYUME_ENGINE_DIR=<engine root> "
        "or set the YUME_ENGINE_DIR environment variable.")
endif()

# All runtime artifacts (the executable + compiled assets) land in one place,
# which the build script also uses as the working directory when running.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")

# Build the engine library + host tools (defines yume_core, scene_compiler, and
# the YumeProject helpers). A separate binary subdir keeps the engine's build
# artifacts out of this project's output dir.
add_subdirectory("${YUME_ENGINE_DIR}" "${CMAKE_BINARY_DIR}/yume_engine")

# The engine include() of YumeProject.cmake used an include_guard, so pull it in
# here too (idempotent) to make the yume_add_project() function visible.
include("${YUME_ENGINE_DIR}/cmake/YumeProject.cmake")

# -----------------------------------------------------------------------------
# The project: one executable from src/, plus its asset pipeline. Building
# `main` also compiles this folder's shaders/scene and copies cube.obj +
# project.conf next to the executable.
# -----------------------------------------------------------------------------
yume_add_project(main
    PROJECT_DIR "${CMAKE_CURRENT_SOURCE_DIR}"
    SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp"
)
