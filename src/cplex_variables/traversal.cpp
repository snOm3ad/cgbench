#include <benchmark/benchmark.h>
#include "IloTensor.hpp"

static void multiarray_traversal(benchmark::State & state) {
    constexpr int V = 32;
    IloEnv env {};
    
    ilo::dvar4d w {env, V};
    
    for (int i = 0; i < V; ++i) {
        w[i] = ilo::dvar3d(env, V);
        for (int j = 0; j < V; ++j) {
            w[i][j] = ilo::dvar2d(env, V);
            for (int k = 0; k < V; ++k) {
                w[i][j][k] = IloNumVarArray(env, V, 0, IloInfinity);
            }
        }
    }

    for (auto _ : state) {
        for (int i = 0; i < V; ++i) {
            for (int j = 0; j < V; ++j) {
                for (int k = 0; k < V; ++k) {
                    for (int m = 0; m < V; ++m) {
                        benchmark::DoNotOptimize(w[i][j][k][m]);
                    }
                }
            }
        }
    }

    env.end();

}
BENCHMARK(multiarray_traversal);


static void singlearray_traversal(benchmark::State & state) {
   constexpr int V = 32;
   IloEnv env {};
   ilo::tensor<IloNumVarArray, 4> w {env, V, V, V, V};

   for (auto _ : state) {
       for (int i = 0; i < V; ++i) {
           for (int j = 0; j < V; ++j) {
               for (int k = 0; k < V; ++k) {
                   for (int m = 0; m < V; ++m) {
                        benchmark::DoNotOptimize(w(i,j,k,m));
                   }
               }
           }
       }
   }

   env.end();
}

BENCHMARK(singlearray_traversal);

BENCHMARK_MAIN();
