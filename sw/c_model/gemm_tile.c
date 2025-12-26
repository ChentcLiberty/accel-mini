#include "gemm.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/**
 * 分块 GEMM - 模拟硬件 Tiling 策略
 * 
 * 硬件约束：8×8 PE 阵列
 * 
 * 算法：C[M,N] = A[M,K] @ B[K,N]
 * 1. 按 TILE_SIZE 分块
 * 2. 每次处理一个 8×8 Tile
 * 3. 累加部分结果
 */

#define TILE_SIZE 8  // PE 阵列大小

void gemm_tiled(
    const data_t *A, 
    const data_t *B,
    acc_t *C,
    int M, int K, int N
) {
    // 清零输出
    memset(C, 0, M * N * sizeof(acc_t));
    
    // 三层 Tile 循环（映射到硬件控制器）
    for (int m = 0; m < M; m += TILE_SIZE) {           // 行分块
        for (int n = 0; n < N; n += TILE_SIZE) {       // 列分块
            for (int k = 0; k < K; k += TILE_SIZE) {   // K 分块
                
                // 当前 Tile 的实际大小（处理边界）
                int tile_m = (m + TILE_SIZE <= M) ? TILE_SIZE : M - m;
                int tile_n = (n + TILE_SIZE <= N) ? TILE_SIZE : N - n;
                int tile_k = (k + TILE_SIZE <= K) ? TILE_SIZE : K - k;
                
                // Tile 内 GEMM（映射到 PE 阵列）
                for (int i = 0; i < tile_m; i++) {
                    for (int j = 0; j < tile_n; j++) {
                        acc_t acc = 0;
                        
                        for (int p = 0; p < tile_k; p++) {
                            data_t a_val = A[(m + i) * K + (k + p)];
                            data_t b_val = B[(k + p) * N + (n + j)];
                            acc += (acc_t)a_val * (acc_t)b_val;
                        }
                        
                        // 累加到输出
                        C[(m + i) * N + (n + j)] += acc;
                    }
                }
            }
        }
    }
}

/**
 * 周期估算（粗略模型）
 */
typedef struct {
    int num_tiles;
    int compute_cycles;
    int memory_cycles;
    int total_cycles;
} tile_stats_t;

void estimate_cycles(int M, int K, int N, tile_stats_t *stats) {
    int tiles_m = (M + TILE_SIZE - 1) / TILE_SIZE;
    int tiles_n = (N + TILE_SIZE - 1) / TILE_SIZE;
    int tiles_k = (K + TILE_SIZE - 1) / TILE_SIZE;
    
    stats->num_tiles = tiles_m * tiles_n * tiles_k;
    
    // 每个 Tile 的计算周期
    int ops_per_tile = TILE_SIZE * TILE_SIZE * TILE_SIZE;
    int cycles_per_tile = ops_per_tile / (TILE_SIZE * TILE_SIZE);
    
    stats->compute_cycles = stats->num_tiles * cycles_per_tile;
    
    // 内存访问周期
    int data_per_tile = 2 * TILE_SIZE * TILE_SIZE;
    stats->memory_cycles = stats->num_tiles * (data_per_tile / 8);
    
    stats->total_cycles = stats->compute_cycles + stats->memory_cycles;
}

