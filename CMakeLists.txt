# Copyright 2024 Alişah Özcan
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
# Developer: Alişah Özcan

cmake_minimum_required(VERSION 3.26.4 FATAL_ERROR)
project(HEonGPU VERSION 1.1 LANGUAGES C CXX CUDA ASM)

set(BINARY_LOCATION ${CMAKE_CURRENT_BINARY_DIR}/bin)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_LIST_DIR}/cmake)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(CUDAToolkit REQUIRED)
find_package(Thrust REQUIRED)
find_package(OpenMP REQUIRED)

if(NOT DEFINED CMAKE_CUDA_ARCHITECTURES)
    set(CMAKE_CUDA_ARCHITECTURES 75)
endif()
message(STATUS "Setting CMAKE_CUDA_ARCHITECTURES to ${CMAKE_CUDA_ARCHITECTURES} for HEonGPU")

##################
# Export Library #
##################

set(RUNTIME_DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
set(LIBRARY_DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)
set(ARCHIVE_DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)
set(INCLUDES_DESTINATION ${CMAKE_INSTALL_PREFIX}/include)
set(INCLUDES_INSTALL_DIR ${INCLUDES_DESTINATION}/HEonGPU-${PROJECT_VERSION})

set(HEonGPU_GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated")
set(HEonGPU_VERSION_CONFIG "${HEonGPU_GENERATED_DIR}/${PROJECT_NAME}ConfigVersion.cmake")
set(HEonGPU_PROJECT_CONFIG "${HEonGPU_GENERATED_DIR}/${PROJECT_NAME}Config.cmake")
set(HEonGPU_TARGETS_EXPORT_NAME "${PROJECT_NAME}Targets")
set(HEonGPU_CONFIG_INSTALL_DIR "lib/cmake/${PROJECT_NAME}-${PROJECT_VERSION}")
set(HEonGPU_NAMESPACE "${PROJECT_NAME}::")
set(HEonGPU_VERSION 1.1)

include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    "${HEonGPU_VERSION_CONFIG}" VERSION ${HEonGPU_VERSION} COMPATIBILITY SameMajorVersion
)
configure_file("${HEonGPU_SOURCE_DIR}/cmake/Config.cmake.in" "${HEonGPU_PROJECT_CONFIG}" @ONLY)

install(
    FILES "${HEonGPU_PROJECT_CONFIG}" "${HEonGPU_VERSION_CONFIG}"
    DESTINATION "${HEonGPU_CONFIG_INSTALL_DIR}")

install(
    EXPORT "${HEonGPU_TARGETS_EXPORT_NAME}"
    NAMESPACE "${HEonGPU_NAMESPACE}"
    DESTINATION "${HEonGPU_CONFIG_INSTALL_DIR}")

set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -O3")

set(RNGonGPU_USE_INTERNAL_GPUNTT
    OFF CACHE BOOL
    "Force using global GPU-NTT (thirdparty/GPU-NTT) instead of RNGonGPU's internal" FORCE)

cmake_policy(SET CMP0077 NEW)
cmake_policy(SET CMP0079 NEW)

set(FETCHCONTENT_QUIET OFF)  # 显示下载进度
set(FETCHCONTENT_UPDATES_DISCONNECTED ON)  # 断点续传
set(FETCHCONTENT_TIMEOUT 6000)  # 全局设置超时时间为600秒

set(FETCHCONTENT_DOWNLOAD_EXTRACT_TIMESTAMP true)
# cmake_policy(SET CMP0135 NEW)

set(git_clone_shallow_options "--depth 1 --single-branch")

function(CustomFetch name)
    set(options)
    set(oneValueArgs GIT_REPOSITORY GIT_TAG GIT_DEPTH SOURCE_DIR)
    set(multiValueArgs)
    cmake_parse_arguments(FETCHCONTENT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # 准备声明参数
    set(declare_args
        ${name}
        GIT_REPOSITORY ${FETCHCONTENT_GIT_REPOSITORY}
        GIT_TAG ${FETCHCONTENT_GIT_TAG}
        GIT_PROGRESS TRUE
        GIT_SHALLOW 1
        GIT_DEPTH 1
    )
    
    # 如果提供了SOURCE_DIR，则添加到声明参数中
    if(DEFINED FETCHCONTENT_SOURCE_DIR)
        list(APPEND declare_args SOURCE_DIR ${FETCHCONTENT_SOURCE_DIR})
    endif()
    
    # 使用构建好的参数列表调用FetchContent_Declare
    FetchContent_Declare(${declare_args})
endfunction()
    
add_subdirectory(thirdparty)
add_subdirectory(src)

#########
# Tests #
#########

option(HEonGPU_BUILD_TESTS "Build HEonGPU Tests" OFF)
message(STATUS "HEonGPU_BUILD_TESTS: ${HEonGPU_BUILD_TESTS}")
if(HEonGPU_BUILD_TESTS)
    add_subdirectory(test)
endif()

############
# Examples #
############

option(HEonGPU_BUILD_EXAMPLES "Build HEonGPU Examples" OFF)
message(STATUS "HEonGPU_BUILD_EXAMPLES: ${HEonGPU_BUILD_EXAMPLES}")
if(HEonGPU_BUILD_EXAMPLES)
    add_subdirectory(example)
endif()

##############
# BENCHMARKS #
##############

option(HEonGPU_BUILD_BENCHMARKS "Build HEonGPU Benchmarks" OFF)
message(STATUS "HEonGPU_BUILD_BENCHMARKS: ${HEonGPU_BUILD_BENCHMARKS}")
if(HEonGPU_BUILD_BENCHMARKS)
    add_subdirectory(benchmark)
endif()
