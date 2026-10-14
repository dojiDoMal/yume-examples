cmake_minimum_required(VERSION 3.10)
project(physics_demo LANGUAGES C CXX)

# -----------------------------------------------------------------------------
# Localiza a engine Yume.
#
# YUME_ENGINE_DIR aponta para a raiz do repositório da engine (a pasta com o
# CMakeLists.txt da engine). Passe na linha de configuração, ex.:
#   cmake -DYUME_ENGINE_DIR=../../yume-windows -B build/pc/debug
# Também cai de volta para a variável de ambiente YUME_ENGINE_DIR. O default
# assume o layout irmão Projetos/yume-examples/physics-demo ao lado de
# Projetos/yume-windows, então "../../yume-windows" resolve para a raiz da engine.
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

# Todos os artefatos de runtime (executável + assets compilados) vão para um só
# lugar, que o script de build também usa como diretório de trabalho ao rodar.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")

# Constrói a biblioteca da engine + ferramentas de host (define yume_core,
# scene_compiler e os helpers do YumeProject). Um subdir de build separado mantém
# os artefatos da engine fora do diretório de saída deste projeto.
add_subdirectory("${YUME_ENGINE_DIR}" "${CMAKE_BINARY_DIR}/yume_engine")

# O include() da engine de YumeProject.cmake usou include_guard, então puxamos
# aqui também (idempotente) para tornar a função yume_add_project() visível.
include("${YUME_ENGINE_DIR}/cmake/YumeProject.cmake")

# -----------------------------------------------------------------------------
# O projeto: um executável a partir de src/, mais seu pipeline de assets.
# Construir `main` também compila os shaders/cena desta pasta e copia cube.obj +
# project.conf para ao lado do executável.
# -----------------------------------------------------------------------------
yume_add_project(main
    PROJECT_DIR "${CMAKE_CURRENT_SOURCE_DIR}"
    SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp"
)
