#include "gemm.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/**
 * 周期精确 GEMM 仿真
 * 
 * 硬件模型:
 * - 8×8 PE 阵列
 * - 每个 PE: 1 cycle MAC (流水线)
 * - 数据加载: 1 cycle/element
 * - 结果写回: 1 cycle/element
 */

#define PE_ROWS 8
#define PE_COLS 8

typedef struct {
    int load_cycles;      // 数据加载周期
    int compute_cycles;   // 计算周期
    int writeback_cycles; // 写回周期
    int stall_cycles;     // 停顿周期
    int total_cycles;     // 总周期
} cycle_stats_t;

/**
 * 模拟一个 Tile 的计算过程
 */
void simulate_tile_cycles(
    int tile_m, int tile_k, int tile_n,
    cycle_stats_t *stats
) {
    // 1. 加载阶段: 加载 A 和 B
    int load_a = tile_m * tile_k;  // A[tile_m, tile_k]
    int load_b = tile_k * tile_n;  // B[tile_k, tile_n]
    stats->load_cycles = load_a + load_b;
    
    // 2. 计算阶段: PE 阵列并行计算
    // 假设 PE 阵列流水线深度为 1
    int total_macs = tile_m * tile_k * tile_n;
    int pe_count = PE_ROWS * PE_COLS;
    
    // 实际使用的 PE 数量
    int active_pes = (tile_m < PE_ROWS ? tile_m : PE_ROWS) *
                     (tile_n < PE_COLS ? tile_n : PE_COLS);
    
    // 计算周期 = MACs / 并行度
    stats->compute_cycles = (total_macs + active_pes - 1) / active_pes;
    
    // 3. 写回阶段: 写回结果 C
    stats->writeback_cycles = tile_m * tile_n;
    
    // 4. 停顿周期 (简化模型: 忽略)
    stats->stall_cycles = 0;
    
    // 5. 总周期 (假设流水线 overlap)
    // 实际硬件可以重叠部分操作
    stats->total_cycles = stats->load_cycles + 
                          stats->compute_cycles + 
                          stats->writeback_cycles;
}

/**
 * 周期精确的 Tiled GEMM
 */
void gemm_cycle_accurate(
    const data_t *A,
    const data_t *B,
    acc_t *C,
    int M, int K, int N,
    cycle_stats_t *total_stats
) {
    memset(C, 0, M * N * sizeof(acc_t));
    memset(total_stats, 0, sizeof(cycle_stats_t));
    
    int current_cycle = 0;
    
    // Tiled GEMM with cycle tracking
    for (int m = 0; m < M; m += PE_ROWS) {
        for (int n = 0; n < N; n += PE_COLS) {
            for (int k = 0; k < K; k += PE_COLS) {
                
                int tile_m = (m + PE_ROWS <= M) ? PE_ROWS : M - m;
                int tile_n = (n + PE_COLS <= N) ? PE_COLS : N - n;
                int tile_k = (k + PE_COLS <= K) ? PE_COLS : K - k;
                
                // 模拟这个 Tile 的周期
                cycle_stats_t tile_stats;
                simulate_tile_cycles(tile_m, tile_k, tile_n, &tile_stats);
                
                // 累加统计
                total_stats->load_cycles += tile_stats.load_cycles;
                total_stats->compute_cycles += tile_stats.compute_cycles;
                total_stats->writeback_cycles += tile_stats.writeback_cycles;
                total_stats->stall_cycles += tile_stats.stall_cycles;
                
                current_cycle += tile_stats.total_cycles;
                
                // 实际计算 (功能验证)
                for (int i = 0; i < tile_m; i++) {
                    for (int j = 0; j < tile_n; j++) {
                        acc_t acc = 0;
                        for (int p = 0; p < tile_k; p++) {
                            data_t a_val = A[(m + i) * K + (k + p)];
                            data_t b_val = B[(k + p) * N + (n + j)];
                            acc += (acc_t)a_val * (acc_t)b_val;
                        }
                        C[(m + i) * N + (n + j)] += acc;
                    }
                }
            }
        }
    }
    
    total_stats->total_cycles = current_cycle;
}

/**
 * 性能分析
 */
void print_performance(int M, int K, int N, cycle_stats_t *stats) {
    long long total_ops = 2LL * M * N * K;  // MACs = 2 ops (mult + add)
    
    printf("\n性能分析:\n");
    printf("─────────────────────────────────────\n");
    printf("  加载周期:   %10d (%.1f%%)\n", 
           stats->load_cycles, 
           100.0 * stats->load_cycles / stats->total_cycles);
    printf("  计算周期:   %10d (%.1f%%)\n", 
           stats->compute_cycles,
           100.0 * stats->compute_cycles / stats->total_cycles);
    printf("  写回周期:   %10d (%.1f%%)\n", 
           stats->writeback_cycles,
           100.0 * stats->writeback_cycles / stats->total_cycles);
    printf("  总周期:     %10d\n", stats->total_cycles);
    printf("─────────────────────────────────────\n");
    printf("  总运算量:   %10lld ops\n", total_ops);
    printf("  吞吐率:     %10.2f ops/cycle\n", 
           (double)total_ops / stats->total_cycles);
    printf("  PE 利用率:  %10.2f%%\n",
           100.0 * total_ops / (stats->total_cycles * PE_ROWS * PE_COLS * 2));
}

