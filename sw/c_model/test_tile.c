#include "gemm.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

// 声明 tiled 函数
void gemm_tiled(const data_t *A, const data_t *B, acc_t *C, 
                int M, int K, int N);

typedef struct {
    int num_tiles;
    int compute_cycles;
    int memory_cycles;
    int total_cycles;
} tile_stats_t;

void estimate_cycles(int M, int K, int N, tile_stats_t *stats);

void gen_random(data_t *mat, int size) {
    for (int i = 0; i < size; i++) {
        mat[i] = (data_t)(rand() % 256 - 128);
    }
}

int compare_results(const acc_t *C1, const acc_t *C2, int size) {
    for (int i = 0; i < size; i++) {
        if (C1[i] != C2[i]) {
            return 0;
        }
    }
    return 1;
}

void test_size(int M, int K, int N) {
    printf("\n测试: (%d×%d) @ (%d×%d)\n", M, K, K, N);
    printf("─────────────────────────────────────\n");
    
    data_t *A = malloc(M * K * sizeof(data_t));
    data_t *B = malloc(K * N * sizeof(data_t));
    acc_t *C_ref = malloc(M * N * sizeof(acc_t));
    acc_t *C_tile = malloc(M * N * sizeof(acc_t));
    
    srand(42);
    gen_random(A, M * K);
    gen_random(B, K * N);
    
    // 基础 GEMM（参考）
    gemm_int8(A, B, C_ref, M, K, N);
    
    // Tiled GEMM
    gemm_tiled(A, B, C_tile, M, K, N);
    
    // 对比
    int match = compare_results(C_ref, C_tile, M * N);
    printf("结果匹配: %s\n", match ? "✓" : "✗");
    
    if (!match) {
        for (int i = 0; i < M * N; i++) {
            if (C_ref[i] != C_tile[i]) {
                printf("不匹配: C[%d] ref=%d, tile=%d\n", 
                       i, C_ref[i], C_tile[i]);
                break;
            }
        }
    }
    
    // 周期估算
    tile_stats_t stats;
    estimate_cycles(M, K, N, &stats);
    
    printf("Tile 数量: %d\n", stats.num_tiles);
    printf("估算周期: %d (计算=%d, 访存=%d)\n",
           stats.total_cycles, stats.compute_cycles, stats.memory_cycles);
    
    free(A); free(B); free(C_ref); free(C_tile);
}

int main() {
    printf("Tiled GEMM 测试\n");
    printf("硬件参数: 8×8 PE 阵列\n");
    printf("=====================================\n");
    
    test_size(8, 8, 8);       // 1 个 Tile
    test_size(16, 16, 16);    // 8 个 Tile
    test_size(32, 32, 32);    // 64 个 Tile
    test_size(64, 64, 64);    // 512 个 Tile
    
    printf("\n✅ 所有测试完成\n");
    return 0;
}

