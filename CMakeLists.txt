cmake_minimum_required(VERSION 3.10)
project(OptimizationBenchmarks LANGUAGES CXX)

set(CMAKE_EXPORT_COMPILE_COMMANDS 1)
set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake" ${CMAKE_MODULE_PATH})


find_package(GoogleBenchmark REQUIRED)
# FIRST EXECUTABLE
# find all the header files and source files
file(GLOB_RECURSE TENSOR_TRAVERSAL_SOURCE_FILES "include/tensor_traversal/*.hpp" "src/tensor_traversal/*.cpp")
# create the executable and tell cmake the source files that
# are associated with this target.
add_executable(TensorTraversal ${TENSOR_TRAVERSAL_SOURCE_FILES})
target_compile_features(TensorTraversal PRIVATE cxx_std_11)
# add the local include directory and the benchmark include directories to the project.
target_include_directories(TensorTraversal PRIVATE "${BENCHMARK_INCLUDE_DIR}")
target_include_directories(TensorTraversal PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/include/tensor_traversal/")
# add the benchmark static libraries
target_link_libraries(TensorTraversal PRIVATE ${BENCHMARK_LIBRARY})


find_package(CPLEX REQUIRED)

# SECOND EXECUTABLE
file(GLOB_RECURSE CPLEX_VARIABLES_SOURCE_FILES "include/cplex_variables/*.hpp" "src/cplex_variables/*.cpp")
add_executable(CplexVars ${CPLEX_VARIABLES_SOURCE_FILES})

target_compile_features(CplexVars PRIVATE cxx_std_11)

target_include_directories(CplexVars PRIVATE "${BENCHMARK_INCLUDE_DIR}")
target_include_directories(CplexVars PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/include/cplex_variables/")

target_link_libraries(CplexVars PRIVATE ${BENCHMARK_LIBRARY})
target_link_libraries(CplexVars PRIVATE ilocplex)
