cmake_minimum_required(VERSION 3.12)

if(DEFINED CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE ${CMAKE_BUILD_TYPE} CACHE STRING "Choose the type of build, options are: None(CMAKE_CXX_FLAGS or CMAKE_C_FLAGS used) Debug Release RelWithDebInfo MinSizeRel.")
else()
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build, options are: None(CMAKE_CXX_FLAGS or CMAKE_C_FLAGS used) Debug Release RelWithDebInfo MinSizeRel.")
endif()

# set(CMAKE_CXX_STANDARD 11)
# set(CMAKE_CXX_STANDARD_REQUIRED ON)
# set(CMAKE_CXX_EXTENSIONS OFF)

project(MKLOpenBLAS64)

include("options.cmake")

if (NOT DEFINED MKL_INCLUDE_PATH)
    message(FATAL_ERROR "Define MKL_INCLUDE_PATH")
elseif (NOT DEFINED MKL_LIBRARIES)
    message(FATAL_ERROR "Define MKL_LIBRARIES")
# elseif (NOT DEFINED CLANG_LIBRARIES)
#     message(FATAL_ERROR "Set variable CLANG_LIBRARIES")
endif()

if (WIN32)
    add_compile_definitions("API_EXPORT=__declspec(dllexport)" "_CRT_SECURE_NO_WARNINGS")
else()
    add_compile_definitions("API_EXPORT=__attribute__((visibility (\"default\")))")
endif()

# ======= parsegen =======
# add_executable(parsegen
#   EXCLUDE_FROM_ALL
#   parsegen.cc)
# target_include_directories(parsegen PRIVATE "${CMAKE_SOURCE_DIR}/deps/fmt/include")
# if (NOT DEFINED CLANG_INCLUDE_PATH)
#     message(WARNING "Set variable CLANG_INCLUDE_PATH")
# else()
#     target_include_directories(parsegen PRIVATE ${CLANG_INCLUDE_PATH})
# endif()
# target_link_libraries(parsegen ${CLANG_LIBRARIES})

# ======= generate =======

# if (NOT EXISTS "${CMAKE_SOURCE_DIR}/mklopenblas64.c")
#     message(STATUS "Will generate ${CMAKE_SOURCE_DIR}/mklopenblas64.c")
#     file(TO_NATIVE_PATH "${CMAKE_SOURCE_DIR}/data/list_ilp64" _list_intel_ilp64)
#     file(TO_NATIVE_PATH "${CMAKE_SOURCE_DIR}/data/list_openblas64" _list_openblas64)
#     file(TO_NATIVE_PATH "${MKL_INCLUDE_PATH}/mkl_blas.h" _mkl_blas_header)
#     file(TO_NATIVE_PATH "${MKL_INCLUDE_PATH}/mkl_cblas.h" _mkl_cblas_header)
#     file(TO_NATIVE_PATH "${MKL_INCLUDE_PATH}/mkl_lapack.h" _mkl_lapack_header)
#     file(TO_NATIVE_PATH "${MKL_INCLUDE_PATH}/mkl_lapacke.h" _mkl_lapacke_header)
#     file(TO_NATIVE_PATH "${CMAKE_SOURCE_DIR}/mklopenblas64.c" _mklopenblas64_c)

#     file(TO_NATIVE_PATH "${CLANG_ROOT}/bin" clang_PATH)

#     add_custom_command(
#         OUTPUT
#             "${CMAKE_SOURCE_DIR}/mklopenblas64.c"
#         DEPENDS
#             parsegen
#         COMMAND
#             "${CMAKE_COMMAND}" -E env
#             "PATH=${CLANG_ROOT}/bin;$ENV{PATH}"
#             $<TARGET_FILE:parsegen>
#             "${_mklopenblas64_c}"
#             "${_list_intel_ilp64}"
#             "${_list_openblas64}"
#             "${_mkl_blas_header}"
#             "${_mkl_cblas_header}"
#             "${_mkl_lapack_header}"
#             "${_mkl_lapacke_header}"
#         COMMENT
#             "Generate mklopenblas64.c"
#         VERBATIM
#     )
# endif()


# ======= build =======
add_library(mklopenblas64_ SHARED "${CMAKE_SOURCE_DIR}/mklopenblas64.c" "${CMAKE_SOURCE_DIR}/mklopenblas64-util.c")
set_target_properties(mklopenblas64_ PROPERTIES PREFIX "lib")  # For Windows

target_include_directories(mklopenblas64_
    PRIVATE
        "${CMAKE_SOURCE_DIR}"
        ${MKL_INCLUDE_PATH}
)
target_link_libraries(mklopenblas64_
    PRIVATE
        ${MKL_LIBRARIES}
)
set_target_properties(
    mklopenblas64_
    PROPERTIES
        C_VISIBILITY_PRESET hidden
)

if(UNIX)
    target_link_options(mklopenblas64_ PUBLIC "LINKER:--exclude-libs,ALL")
elseif(WIN32)

elseif(APPLE)

endif()
