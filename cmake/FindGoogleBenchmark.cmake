# Findbenchmark.cmake
# - Try to find benchmark
#  Once done this will define
#  BENCHMARK_FOUND - System has benchmark
#  BENCHMARK_INCLUDE_DIRS - The benchmark include directories
#  BENCHMARK_LIBRARIES - The libraries needed to use benchmark

set(BENCHMARK_ROOT_DIR CACHE PATH "Folder containing benchmark")

if(NOT BENCHMARK_ROOT_DIR)
    message(FATAL_ERROR "\nbenchmark library root directory not specified, use -DBENCHMARK_ROOT_DIR=path/to/lib to specify it.\n")
endif()

find_path (
    BENCHMARK_INCLUDE_DIR "benchmark/benchmark.h" 
    PATHS ${BENCHMARK_ROOT_DIR} 
    PATH_SUFFIXES benchmark/include
    NO_DEFAULT_PATH
)

if (NOT BENCHMARK_INCLUDE_DIR)
    message(STATUS "could not found include directory")
endif()


# try and find the global installation
find_library (
    BENCHMARK_LIBRARY 
    NAMES "benchmark" 
    PATHS ${BENCHMARK_ROOT_DIR} 
    PATH_SUFFIXES build/src 
    NO_DEFAULT_PATH
)

if (NOT BENCHMARK_LIBRARY)
    message(STATUS "could not find library")
endif()

include(FindPackageHandleStandardArgs)
# handle the QUIETLY and REQUIRED arguments and set benchmark_FOUND to TRUE
# if all listed variables are TRUE

find_package_handle_standard_args(
    BENCHMARK FOUND_VAR BENCHMARK_FOUND
    REQUIRED_VARS BENCHMARK_LIBRARY
    BENCHMARK_INCLUDE_DIR
)

mark_as_advanced(BENCHMARK_INCLUDE_DIR BENCHMARK_LIBRARY)
