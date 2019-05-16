#include <cstdlib>
#include <cstdio>
#include <vector>
#include <benchmark/benchmark.h>
#include "MinTensor.hpp"

static void matrix_traversal_old(benchmark::State& state) {

    constexpr int I = 48;
    int **** tensor = (int ****) std::calloc(I, sizeof(int ***));

    for (int i = 0; i < I; ++i) {
        tensor[i] = (int***) std::calloc(I, sizeof(int **));
        for (int j = 0; j < I; ++j) {
            tensor[i][j] = (int **) std::calloc(I, sizeof(int *));
            for (int k = 0; k < I; ++k) {
                tensor[i][j][k] = (int *) std::calloc(I, sizeof(int));
            }
        }
    }
  
    for (auto _ : state) {
        for(int i = 0; i < I; ++i) {
            for (int j = 0; j < I; ++j) {
                for (int k = 0; k < I; ++k) {
                    for (int m = 0; m < I; ++m) {
                        benchmark::DoNotOptimize(tensor[j][i][k][m]);
                    }
                }
            }
        }
    }
  
    for (int i = 0; i < I; ++i) {
        for (int j = 0; j < I; ++j) {
            for (int k = 0; k < I; ++k) {
                std::free(tensor[i][j][k]);
            }
        std::free(tensor[i][j]);
        }
    std::free(tensor[i]);
  }
  std::free(tensor);
}
BENCHMARK(matrix_traversal_old);



static void matrix_traversal_new(benchmark::State& state) {
    constexpr int I = 48;
    auto const tensor = [I]() -> matrix<int, 4> {
        std::vector<int> v(I * I * I * I);
        return matrix<int, 4>(v.begin(), v.end(), I, I, I, I);
    }();
  
    for(auto _ : state) {
        for(int i = 0; i < I; ++i) {
            for (int j = 0; j < I; ++j) {
                for (int k = 0; k < I; ++k) {
                    for (int m = 0; m < I; ++m) {
                        benchmark::DoNotOptimize(tensor(j,i,k,m));
                    }
                }
            }
        }
    }
}

BENCHMARK(matrix_traversal_new);
BENCHMARK_MAIN();
