cmake_minimum_required(VERSION 3.10)
project(pocket_creature LANGUAGES C CXX)

# -----------------------------------------------------------------------------
# Localiza a engine Yume.
#
# YUME_ENGINE_DIR aponta para a raiz do repositório da engine (a pasta com o
# CMakeLists.txt da engine). Passe na linha de configuração, ex.:
#   cmake -DYUME_ENGINE_DIR=../../yume-windows -B build/pc/debug
# Também cai na variável de ambiente YUME_ENGINE_DIR. O default assume o layout
# irmão Projetos/yume-examples/pocket-creature ao lado de Projetos/yume-windows,
# então "../../yume-windows" resolve para a raiz da engine.
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

# Todos os artefatos de runtime (executável + assets compilados) caem num único
# lugar, que o script de build também usa como working dir ao rodar.
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")

# Constrói a biblioteca da engine + ferramentas de host (define yume_core,
# scene_compiler e os helpers do YumeProject). Um subdiretório binário separado
# mantém os artefatos da engine fora da pasta de saída deste projeto.
add_subdirectory("${YUME_ENGINE_DIR}" "${CMAKE_BINARY_DIR}/yume_engine")

# O include() de YumeProject.cmake pela engine usa include_guard; puxamos aqui
# também (idempotente) para tornar a função yume_add_project() visível.
include("${YUME_ENGINE_DIR}/cmake/YumeProject.cmake")

# -----------------------------------------------------------------------------
# O projeto: um executável a partir de src/, mais seu pipeline de assets.
# Compilar `main` também compila os shaders/cena desta pasta e copia a sprite
# sheet (.png + .ssm), o script .ys e o project.conf ao lado do executável.
# -----------------------------------------------------------------------------
yume_add_project(main
    PROJECT_DIR "${CMAKE_CURRENT_SOURCE_DIR}"
    SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp"
)
