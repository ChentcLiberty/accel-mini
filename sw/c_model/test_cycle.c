#include "gemm.h"
#include <stdio.h>
#include <stdlib.h>

typedef struct {
    int load_cycles;
    int compute_cycles;
    int writeback_cycles;
    int stall_cycles;
    int total_cycles;
} cycle_stats_t;

void gemm_cycle_accurate(const data_t *A, const data_t *B, acc_t *C,
                         int M, int K, int N, cycle_stats_t *stats);
void print_performance(int M, int K, int N, cycle_stats_t *stats);

void gen_random(data_t *mat, int size) {
    for (int i = 0; i < size; i++) {
        mat[i] = (data_t)(rand() % 256 - 128);
    }
}

void test_size(int M, int K, int N) {
    printf("\n测试: (%d×%d) @ (%d×%d)\n", M, K, K, N);
    printf("═════════════════════════════════════\n");
    
    data_t *A = malloc(M * K * sizeof(data_t));
    data_t *B = malloc(K * N * sizeof(data_t));
    acc_t *C = malloc(M * N * sizeof(acc_t));
    
    srand(42);
    gen_random(A, M * K);
    gen_random(B, K * N);
    
    cycle_stats_t stats;
    gemm_cycle_accurate(A, B, C, M, K, N, &stats);
    
    print_performance(M, K, N, &stats);
    
    free(A); free(B); free(C);
}

int main() {
    printf("周期精确 GEMM 仿真\n");
    printf("硬件参数: 8×8 PE 阵列, 流水线 MAC\n");
    printf("═════════════════════════════════════\n");
    
    test_size(8, 8, 8);
    test_size(16, 16, 16);
    test_size(32, 32, 32);
    test_size(64, 64, 64);
    
    printf("\n✅ Level 1 完成！\n");
    printf("下一步: Level 2 - RTL 设计\n");
    return 0;
}

